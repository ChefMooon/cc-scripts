--[[============================================================================
  Bumper OS v1  --  bumperOSv1.lua
  ------------------------------------------------------------------------------
  Single-file prototype flight controller for a Create: Aeronautics hovercraft,
  driven by 8 CC: Tweaked "Redstone Relay" peripherals (4 around a gimbal
  sensor, 4 on the corner thrusters) with a Basalt 2.5 UI.

  Signal convention (fixed by hardware): 0 = max thrust / no error,
                                          15 = no thrust / max error.

  This file implements, in order:
    1. Constants & defaults
    2. Small utilities
    3. Config persistence (settings.cfg / calibration.cfg, with backup+restore)
    4. Relay discovery & low-level IO
    5. PID controller (position form, derivative-on-measurement, anti-windup)
    6. Thrust math (common-mode + differential, clamped)
    7. Failsafe / watchdog
    8. State machine (GROUND / TAKEOFF / HOVER / LANDING / FAILSAFE)
    9. Calibration (shared primitives, automatic flow, manual flow, validation)
   10. Basalt UI (Home / Settings / Info / Calibration modal / Failsafe overlay)
   11. Boot & main loop (parallel.waitForAny)

  NOTES ON ASSUMPTIONS (flagged inline with "ASSUMPTION:" as well):
    - Each Redstone Relay peripheral is addressed with a computer-style side
      name ("top","bottom","left","right","front","back") for its analog
      input/output methods (getAnalogInput(side) / setAnalogOutput(side, v)),
      mirroring the CC: Tweaked `redstone` API but namespaced per-peripheral.
      Gimbal relays are lock-on calibrated per side because it is unknown in
      advance which of a relay's faces carries the live signal; thruster
      relays use a single fixed side (DEFAULT_THRUSTER_SIDE) since they are
      wired point-to-point to one thruster.
    - Relay *role* (thruster vs. gimbal) is read from the peripheral's network
      name (expected to contain "thruster" or "gimbal", e.g. "thruster_1",
      "gimbal_1"), matching the naming used in the design doc's example
      tables. Corner/side/axis/sign within a role is solved by calibration.
    - The exact Basalt 2.5 widget API (addButton/addSlider/addLabel/etc. with
      a fluent :set*()/:on*() chain) is based on the published Basalt guides;
      minor method-name differences may need adjusting for the exact version
      installed on the target computer.
==============================================================================]]

--============================================================================
-- 1. CONSTANTS & DEFAULTS
--============================================================================

local BUMPER_OS_VERSION = "1.0.0"
local CALIBRATION_SCHEMA_VERSION = 1
local SETTINGS_SCHEMA_VERSION = 1

-- File paths
local SETTINGS_PATH       = "settings.cfg"
local CALIBRATION_PATH    = "calibration.cfg"
local CALIBRATION_BAK     = "calibration.cfg.bak"

-- Signal convention
local MIN_SIGNAL = 0   -- max thrust / no error
local MAX_SIGNAL = 15  -- no thrust / max error

-- Corners & axes
local CORNERS = { "FL", "FR", "BL", "BR" }
local AXES    = { "pitch", "roll" }

-- Relay sides we probe when lock-on calibrating a gimbal relay's live face.
local SIDE_CANDIDATES = { "top", "bottom", "left", "right", "front", "back" }

-- ASSUMPTION: thruster relays are wired point-to-point on a single fixed side.
local DEFAULT_THRUSTER_SIDE = "back"

-- Code-only constants (never user-facing; see README "Constants" table)
local THRUST_BUFFER            = 3     -- reserves differential headroom at low thrust
local SETTLE_TICKS             = 20    -- settle period after takeoff ramp before arming PID
local TOUCHDOWN_TICKS          = 20    -- timer after landing ramp before returning to GROUND
local SILENT_TICKS             = 40    -- silent-gimbal failsafe threshold (consecutive no-change cycles)
local STALE_TICKS              = 40    -- stale-gimbal failsafe threshold (no fresh read)
local WATCHDOG_TIMEOUT_TICKS   = 60    -- watchdog timeout, comfortably above the control period
local NOISE_FLOOR_FRACTION     = 0.15  -- validation noise floor, as a fraction of expected magnitude
local IMPULSE_TICKS            = 10    -- calibration test-fire impulse duration
local INTEGRAL_MAX             = 50    -- PID anti-windup clamp (signal units * seconds)
local CONTROL_PERIOD           = 0.1   -- seconds per control cycle ("tick")
local DERIV_FILTER_ALPHA       = 0.3   -- low-pass filter coefficient for D-on-measurement

-- Code default for the baseline common-mode signal used to hold the craft
-- airborne (or approximately weightless-feeling) during calibration test
-- fires, so tilt impulses aren't blocked by the ground. Tune per-vehicle.
local CALIBRATION_BASE_SIGNAL  = 7

-- Default persisted settings (used if settings.cfg is missing on first boot)
local DEFAULT_SETTINGS = {
  version = SETTINGS_SCHEMA_VERSION,
  gains = {
    pitch = { Kp = 1.2, Ki = 0.05, Kd = 0.3 },
    roll  = { Kp = 1.2, Ki = 0.05, Kd = 0.3 },
  },
  deadzone = { pitch = 1, roll = 1 },
  rampRate = 1,               -- signal levels per tick, shared by takeoff/landing/slider
  defaultThrustPercent = 100, -- 100% = max thrust
}

--============================================================================
-- 2. UTILITIES
--============================================================================

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function round(v)
  return math.floor(v + 0.5)
end

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = deepcopy(v) end
  return out
end

-- Sleeps for `n` control cycles by waiting on repeating timer events. Used
-- during calibration impulses. Yields to the event loop so Basalt/other
-- parallel branches keep running.
local function sleepTicks(n)
  for _ = 1, n do
    os.sleep(CONTROL_PERIOD)
  end
end

local function log(msg)
  print(("[BumperOS] %s"):format(tostring(msg)))
end

--============================================================================
-- 3. CONFIG PERSISTENCE (settings.cfg / calibration.cfg)
--============================================================================
-- Both files are serialized with textutils.serialize (CC: Tweaked's standard
-- Lua table serializer). Loads never silently default on a *later* boot with
-- a corrupt/unsupported file -- they fail closed and report the problem.

local function fileReadTable(path)
  if not fs.exists(path) then
    return nil, "missing"
  end
  local h = fs.open(path, "r")
  if not h then
    return nil, "open-failed"
  end
  local data = h.readAll()
  h.close()
  local ok, tbl = pcall(textutils.unserialize, data)
  if not ok or type(tbl) ~= "table" then
    return nil, "corrupt"
  end
  return tbl
end

local function fileWriteTable(path, tbl)
  local h = fs.open(path, "w")
  if not h then
    return false, "open-failed"
  end
  h.write(textutils.serialize(tbl))
  h.close()
  return true
end

-- ---- settings.cfg ---------------------------------------------------------

local function validateSettings(cfg)
  if type(cfg) ~= "table" then return false, "not a table" end
  if cfg.version ~= SETTINGS_SCHEMA_VERSION then return false, "unsupported version" end
  if type(cfg.gains) ~= "table" then return false, "missing gains" end
  for _, axis in ipairs(AXES) do
    local g = cfg.gains[axis]
    if type(g) ~= "table" or type(g.Kp) ~= "number" or type(g.Ki) ~= "number" or type(g.Kd) ~= "number" then
      return false, "invalid gains for axis " .. axis
    end
  end
  if type(cfg.deadzone) ~= "table" then return false, "missing deadzone" end
  for _, axis in ipairs(AXES) do
    if type(cfg.deadzone[axis]) ~= "number" then
      return false, "invalid deadzone for axis " .. axis
    end
  end
  if type(cfg.rampRate) ~= "number" or cfg.rampRate <= 0 then return false, "invalid rampRate" end
  if type(cfg.defaultThrustPercent) ~= "number" then return false, "invalid defaultThrustPercent" end
  return true
end

-- Loads settings.cfg. Returns (settingsTable, usedDefaults:boolean, err:string?)
local function loadSettings()
  local cfg, err = fileReadTable(SETTINGS_PATH)
  if cfg == nil then
    if err == "missing" then
      -- First boot: expected, silently fall back to code defaults.
      return deepcopy(DEFAULT_SETTINGS), true, nil
    end
    -- Later boot with unparseable file: fail closed, but still return
    -- defaults so the caller can show a clear warning rather than crash.
    return deepcopy(DEFAULT_SETTINGS), true, "settings.cfg " .. err .. " -- using code defaults"
  end
  local ok, verr = validateSettings(cfg)
  if not ok then
    return deepcopy(DEFAULT_SETTINGS), true, "settings.cfg invalid (" .. verr .. ") -- using code defaults"
  end
  return cfg, false, nil
end

local function saveSettings(cfg)
  cfg.version = SETTINGS_SCHEMA_VERSION
  return fileWriteTable(SETTINGS_PATH, cfg)
end

-- ---- calibration.cfg (+ backup/restore) ------------------------------------

local function validateCalibration(cfg)
  if type(cfg) ~= "table" then return false, "not a table" end
  if cfg.version ~= CALIBRATION_SCHEMA_VERSION then return false, "unsupported version" end

  if type(cfg.thrusters) ~= "table" then return false, "missing thrusters" end
  for _, corner in ipairs(CORNERS) do
    local t = cfg.thrusters[corner]
    if type(t) ~= "table" or type(t.name) ~= "string" or type(t.side) ~= "string" then
      return false, "invalid thruster mapping for " .. corner
    end
  end

  if type(cfg.gimbals) ~= "table" then return false, "missing gimbals" end
  local seenRoles = {}
  for name, g in pairs(cfg.gimbals) do
    if type(g) ~= "table" or type(g.side) ~= "string"
      or (g.axis ~= "pitch" and g.axis ~= "roll")
      or (g.sign ~= 1 and g.sign ~= -1) then
      return false, "invalid gimbal mapping for " .. tostring(name)
    end
    seenRoles[g.axis .. tostring(g.sign)] = true
  end
  -- Expect exactly 4 distinct (axis,sign) roles: pitch+, pitch-, roll+, roll-
  local count = 0
  for _ in pairs(seenRoles) do count = count + 1 end
  if count ~= 4 then return false, "gimbal roles incomplete/duplicated" end

  if type(cfg.coupling) ~= "table" then return false, "missing coupling" end
  for _, corner in ipairs(CORNERS) do
    local c = cfg.coupling[corner]
    if type(c) ~= "table" or type(c.pitch) ~= "number" or type(c.roll) ~= "number" then
      return false, "invalid coupling for " .. corner
    end
  end

  if type(cfg.expected) ~= "table" or type(cfg.expected.pitch) ~= "number" or type(cfg.expected.roll) ~= "number" then
    return false, "missing/invalid expected response magnitudes"
  end

  return true
end

-- Returns (calibration, status, err) where status is one of:
--   "ok", "first-boot-missing", "corrupt-restored-backup", "corrupt-no-backup"
local function loadCalibration()
  local cfg, err = fileReadTable(CALIBRATION_PATH)
  if cfg ~= nil then
    local ok, verr = validateCalibration(cfg)
    if ok then
      return cfg, "ok", nil
    end
    err = "invalid (" .. verr .. ")"
  end

  if err == "missing" and not fs.exists(CALIBRATION_BAK) then
    -- First boot: a missing file (and no backup) is expected.
    return nil, "first-boot-missing", nil
  end

  -- Later boot with missing/corrupt file: unexpected. Try the backup.
  local bak = fileReadTable(CALIBRATION_BAK)
  if bak ~= nil then
    local ok, verr = validateCalibration(bak)
    if ok then
      return bak, "corrupt-restored-backup", "calibration.cfg " .. tostring(err) .. "; restored from .bak"
    end
  end

  return nil, "corrupt-no-backup", "calibration.cfg " .. tostring(err) .. " and no valid backup"
end

-- Backs up the existing calibration.cfg (if any) to .bak, then writes the
-- new calibration. This ordering guarantees .bak is never overwritten with
-- a bad file while main is still good.
local function saveCalibration(cfg)
  cfg.version = CALIBRATION_SCHEMA_VERSION
  if fs.exists(CALIBRATION_PATH) then
    fs.delete(CALIBRATION_BAK)
    fs.copy(CALIBRATION_PATH, CALIBRATION_BAK)
  end
  return fileWriteTable(CALIBRATION_PATH, cfg)
end

--============================================================================
-- 4. RELAY DISCOVERY & LOW-LEVEL IO
--============================================================================

-- name -> { name=..., obj=<wrapped peripheral> }
local Relays = {}

local function discoverRelays()
  local found = {}
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "redstone_relay" then
      table.insert(found, { name = name, obj = peripheral.wrap(name) })
    end
  end
  return found
end

-- Splits discovered relays into thruster / gimbal / unknown by name pattern.
-- See file header ASSUMPTION note on naming.
local function classifyRelays(found)
  local thrusters, gimbals, unknown = {}, {}, {}
  for _, r in ipairs(found) do
    local lname = r.name:lower()
    if lname:find("thruster") then
      table.insert(thrusters, r)
    elseif lname:find("gimbal") then
      table.insert(gimbals, r)
    else
      table.insert(unknown, r)
    end
  end
  return thrusters, gimbals, unknown
end

local function relaySetOutput(relayObj, side, value)
  relayObj.setAnalogOutput(side, clamp(round(value), MIN_SIGNAL, MAX_SIGNAL))
end

local function relayGetInput(relayObj, side)
  local ok, v = pcall(relayObj.getAnalogInput, side)
  if not ok or type(v) ~= "number" then return nil end
  return v
end

-- Sets a thruster corner's raw output signal directly via the resolved
-- calibration mapping. Used by both the control loop and calibration.
local function setCornerSignal(calibration, corner, value)
  local t = calibration.thrusters[corner]
  local relay = Relays[t.name]
  if not relay then return false end
  relaySetOutput(relay.obj, t.side, value)
  return true
end

-- Reads a single gimbal relay's raw (unsigned, 0..15) magnitude via its
-- locked-on side.
local function readGimbalRaw(calibration, name)
  local g = calibration.gimbals[name]
  local relay = Relays[name]
  if not (g and relay) then return nil end
  return relayGetInput(relay.obj, g.side)
end

-- Computes signed pitch_error / roll_error in signal units from the 4
-- gimbal relays, per the resolved (axis, sign) roles.
-- pitch_error = sign_f*front + sign_b*back ; roll_error = sign_l*left + sign_r*right
local function readAxisErrors(calibration)
  local pitch, roll = 0, 0
  local sawPitch, sawRoll = false, false
  local raws = {}
  for name, g in pairs(calibration.gimbals) do
    local v = readGimbalRaw(calibration, name)
    raws[name] = v
    if v == nil then
      return nil, nil, raws -- invalid reading -> caller treats as failsafe trigger
    end
    if v < 0 or v > 15 or v ~= v then -- v ~= v catches NaN
      return nil, nil, raws
    end
    if g.axis == "pitch" then
      pitch = pitch + g.sign * v
      sawPitch = true
    else
      roll = roll + g.sign * v
      sawRoll = true
    end
  end
  if not (sawPitch and sawRoll) then
    return nil, nil, raws
  end
  return pitch, roll, raws
end

--============================================================================
-- 5. PID CONTROLLER
--============================================================================
-- Position form, error in signal units, output in differential signal units.
--   u = Kp*e + Ki*integral(e dt) + Kd * d(measurement)/dt   [D-on-measurement]
-- Setpoint is fixed at 0 (level), so error == -measurement and D-on-measurement
-- is implemented as -Kd * d(error)/dt using a low-pass filtered derivative.

local function newPID(Kp, Ki, Kd, deadzone)
  return {
    Kp = Kp, Ki = Ki, Kd = Kd,
    deadzone = deadzone or 0,
    integral = 0,
    prevError = 0,
    filteredDeriv = 0,
    lastOutput = 0,
  }
end

local function pidSetGains(pid, Kp, Ki, Kd, deadzone)
  pid.Kp, pid.Ki, pid.Kd = Kp, Ki, Kd
  if deadzone ~= nil then pid.deadzone = deadzone end
end

local function pidResetIntegral(pid)
  pid.integral = 0
end

-- Advances the PID by one control cycle. `error` is in signal units
-- (setpoint 0 minus measurement). `dt` is the cycle period in seconds.
local function pidUpdate(pid, error, dt)
  if math.abs(error) < pid.deadzone then
    -- Inside the deadzone: hold the integral and derivative filter state
    -- steady (no bump when leaving the deadzone), apply no correction.
    pid.prevError = error
    pid.lastOutput = 0
    return 0
  end

  pid.integral = clamp(pid.integral + error * dt, -INTEGRAL_MAX, INTEGRAL_MAX)

  local rawDeriv = (error - pid.prevError) / dt
  pid.filteredDeriv = pid.filteredDeriv + DERIV_FILTER_ALPHA * (rawDeriv - pid.filteredDeriv)
  pid.prevError = error

  -- D-on-measurement: since error = -measurement, d(error)/dt = -d(measurement)/dt,
  -- so using +Kd*d(error)/dt here is equivalent to the usual -Kd*d(measurement)/dt.
  local output = pid.Kp * error + pid.Ki * pid.integral + pid.Kd * pid.filteredDeriv
  pid.lastOutput = output
  return output
end

--============================================================================
-- 6. THRUST MATH
--============================================================================
-- common_mode = (15 - THRUST_BUFFER) * (1 - thrust% / 100)
--   100% (max thrust) -> common-mode 0 ; 0% (no thrust) -> common-mode 15-THRUST_BUFFER
-- corner_signal = clamp(common_mode + differential, 0, 15)
--
-- Correction convention (see README "Sign conventions"): a positive pitch
-- error (nose-up) is corrected by *cutting* (increasing signal on) the front
-- corners; a positive roll error (left-down) is corrected by cutting the
-- right corners. The axial-mode matrices below encode that directly:
--   pitch mode: FL:+1 FR:+1 BL:-1 BR:-1   (front corners cut for +pitch_cmd)
--   roll  mode: FL:-1 FR:+1 BL:-1 BR:+1   (right corners cut for +roll_cmd)
-- ASSUMPTION/TUNING NOTE: if the PID's sign convention doesn't match the
-- physical wiring once tested, flip the corresponding axis's Kp sign in
-- Settings rather than editing this matrix.

local PITCH_AXIAL_SIGN = { FL = 1, FR = 1, BL = -1, BR = -1 }
local ROLL_AXIAL_SIGN  = { FL = -1, FR = 1, BL = -1, BR = 1 }

local function commonModeSignal(thrustPercent)
  return (MAX_SIGNAL - THRUST_BUFFER) * (1 - thrustPercent / 100)
end

-- Given PID outputs (pitch_cmd, roll_cmd) in differential signal units,
-- returns a table corner -> differential (unclamped; clamping happens once
-- combined with the common-mode offset).
--
-- The axial modes are normalized by the measured coupling matrix so each
-- mode produces roughly unit real-world pitch/roll authority even with
-- uneven thruster authority (see README "Coupling matrix"). If calibration
-- is unavailable, falls back to unit scaling.
local function computeDifferentials(calibration, pitchCmd, rollCmd)
  local d = {}
  local pitchScale, rollScale = 1, 1
  if calibration and calibration.coupling then
    local pSum, rSum = 0, 0
    for _, corner in ipairs(CORNERS) do
      pSum = pSum + PITCH_AXIAL_SIGN[corner] * (calibration.coupling[corner].pitch or 0)
      rSum = rSum + ROLL_AXIAL_SIGN[corner] * (calibration.coupling[corner].roll or 0)
    end
    if math.abs(pSum) > 1e-6 then pitchScale = 1 / pSum end
    if math.abs(rSum) > 1e-6 then rollScale = 1 / rSum end
  end
  for _, corner in ipairs(CORNERS) do
    d[corner] = PITCH_AXIAL_SIGN[corner] * pitchCmd * pitchScale
              + ROLL_AXIAL_SIGN[corner] * rollCmd * rollScale
  end
  return d
end

local function combineCornerSignal(commonMode, differential)
  return clamp(round(commonMode + differential), MIN_SIGNAL, MAX_SIGNAL)
end

--============================================================================
-- 7. SHARED RUNTIME STATE
--============================================================================
-- Single shared table read/written by the control loop, watchdog, and UI.
-- The UI is read-only on `craft.state` -- it triggers transitions via
-- functions (requestTakeoff/requestLand/requestRearm) rather than mutating
-- craft.state directly.

local craft = {
  state = "GROUND",           -- GROUND | TAKEOFF | HOVER | LANDING | FAILSAFE
  failsafeReason = nil,       -- string describing the trigger, shown in the UI

  thrustPercent = DEFAULT_SETTINGS.defaultThrustPercent, -- user slider, 0-100
  targetCommonMode = commonModeSignal(DEFAULT_SETTINGS.defaultThrustPercent),
  currentCommonMode = MAX_SIGNAL, -- starts at "no thrust" (15) on the ground

  -- Last commanded differential (per axis), used by the silent-gimbal
  -- failsafe to distinguish "level, no correction needed" (constant reading
  -- is healthy) from "commanding a correction but seeing no response" (stuck).
  lastCommanded = { pitch = 0, roll = 0 },

  cornerSignal = { FL = MAX_SIGNAL, FR = MAX_SIGNAL, BL = MAX_SIGNAL, BR = MAX_SIGNAL },

  settings = nil,       -- populated at boot by loadSettings()
  calibration = nil,    -- populated at boot by loadCalibration() (or via calibration flow)

  pidPitch = nil,
  pidRoll = nil,

  heartbeat = 0,         -- incremented every control cycle; watched by the watchdog
  lastPitch = 0,
  lastRoll = 0,
  lastGimbalRaws = {},
  silentCount = 0,
  lastFreshRead = os.clock(),

  settleTimer = 0,
  touchdownTimer = 0,

  failsafeSuspended = false, -- true only during a calibration session
  calibrationActive = false,

  pendingTransition = nil, -- set by UI button handlers, consumed by control loop
}

local function applySettings(settings)
  craft.settings = settings
  craft.pidPitch = newPID(settings.gains.pitch.Kp, settings.gains.pitch.Ki, settings.gains.pitch.Kd, settings.deadzone.pitch)
  craft.pidRoll  = newPID(settings.gains.roll.Kp,  settings.gains.roll.Ki,  settings.gains.roll.Kd,  settings.deadzone.roll)
  -- NOTE: does NOT touch craft.thrustPercent / targetCommonMode here. Saving
  -- settings mid-flight must not snap the live thrust slider back to default;
  -- boot() sets the initial slider value from settings.defaultThrustPercent.
end

--============================================================================
-- 8. FAILSAFE / WATCHDOG
--============================================================================

-- Sets all 4 thruster relays to "no thrust" (15), per the signal convention.
-- Gimbal relays are inputs and are never commanded.
local function killThrust()
  if craft.calibration then
    for _, corner in ipairs(CORNERS) do
      setCornerSignal(craft.calibration, corner, MAX_SIGNAL)
      craft.cornerSignal[corner] = MAX_SIGNAL
    end
  end
end

local function enterFailsafe(reason)
  if craft.state == "FAILSAFE" then
    craft.failsafeReason = reason -- keep the most recent reason fresh
    return
  end
  craft.state = "FAILSAFE"
  craft.failsafeReason = reason
  killThrust()
  log("FAILSAFE: " .. tostring(reason))
end

-- Re-checks whether the condition that most recently tripped failsafe is
-- still present. Returns true if it is safe to re-arm.
local function failsafeConditionCleared()
  if craft.calibration == nil then
    return false, "no valid calibration"
  end
  -- Relay presence: every known relay must still report as redstone_relay.
  for name, _ in pairs(Relays) do
    if peripheral.getType(name) ~= "redstone_relay" then
      return false, "relay still missing: " .. name
    end
  end
  local pitch, roll = readAxisErrors(craft.calibration)
  if pitch == nil then
    return false, "gimbal reading still invalid/silent"
  end
  return true
end

-- Called once per control cycle (when not suspended for calibration) to
-- check all five failsafe triggers.
local function checkFailsafeTriggers(dt)
  if craft.failsafeSuspended then return end

  -- Relay loss: any previously known relay no longer reports as redstone_relay.
  for name, _ in pairs(Relays) do
    if peripheral.getType(name) ~= "redstone_relay" then
      enterFailsafe("relay lost: " .. name)
      return
    end
  end

  local pitch, roll = readAxisErrors(craft.calibration)
  if pitch == nil then
    enterFailsafe("invalid/silent gimbal reading")
    return
  end

  -- Silent/stale detection is only meaningful while the PID is armed AND a
  -- correction is actually being commanded. A level craft legitimately reads
  -- a constant 0,0 -- that is healthy, not a fault. We only treat a constant
  -- reading as "silent" when we are commanding a nonzero differential and the
  -- gimbal fails to respond (a stuck sensor). On the ground/takeoff, or when
  -- no correction is needed, constant readings are expected and never trip.
  local armed = (craft.state == "HOVER" or craft.state == "LANDING")
  local commanding = armed and
    (math.abs(craft.lastCommanded.pitch) > 0 or math.abs(craft.lastCommanded.roll) > 0)

  if commanding then
    if pitch == craft.lastPitch and roll == craft.lastRoll then
      craft.silentCount = craft.silentCount + 1
    else
      craft.silentCount = 0
      craft.lastFreshRead = os.clock()
    end
  else
    -- Not commanding (or not armed): constant readings are expected, so keep
    -- the freshness clock current and never accumulate a silent count.
    craft.silentCount = 0
    craft.lastFreshRead = os.clock()
  end
  craft.lastPitch, craft.lastRoll = pitch, roll

  if craft.silentCount >= SILENT_TICKS then
    enterFailsafe("silent gimbal (" .. SILENT_TICKS .. " cycles unchanged while commanding)")
    return
  end

  -- Stale gimbal: no fresh read within STALE_TICKS worth of time. Only
  -- meaningful while armed and commanding (see above); otherwise lastFreshRead
  -- is kept current so this never trips on a level/grounded craft.
  if armed and (os.clock() - craft.lastFreshRead) >= (STALE_TICKS * CONTROL_PERIOD) then
    enterFailsafe("stale gimbal (no fresh reading)")
    return
  end
end

-- Runs as its own parallel branch. Trips failsafe if the control loop's
-- heartbeat counter stops advancing (hung/crashed control loop).
local function watchdogLoop()
  local lastSeen = craft.heartbeat
  while true do
    sleepTicks(WATCHDOG_TIMEOUT_TICKS)
    if craft.heartbeat == lastSeen and craft.state ~= "FAILSAFE" then
      enterFailsafe("watchdog timeout: control loop stalled")
    end
    lastSeen = craft.heartbeat
  end
end

--============================================================================
-- 9. STATE MACHINE & CONTROL LOOP
--============================================================================
-- GROUND -> TAKEOFF -> HOVER -> LANDING -> GROUND, with FAILSAFE interrupting
-- any state. Transitions are requested by the UI (via craft.pendingTransition)
-- and executed here, so the UI stays read-only on craft.state.

-- Public request functions, called by UI button handlers.
local function requestTakeoff()
  if craft.state == "GROUND" then craft.pendingTransition = "TAKEOFF" end
end
local function requestLand()
  if craft.state == "HOVER" then craft.pendingTransition = "LANDING" end
end
local function requestRearm()
  if craft.state == "FAILSAFE" then craft.pendingTransition = "REARM" end
end
-- Wired up in section 11e to open the calibration modal; only callable
-- from GROUND (mirrors the Calibrate button's enabled state).
local openCalibrationModal = function() end
local function requestCalibrate()
  if craft.state == "GROUND" then openCalibrationModal() end
end

-- Rate-limits a value's approach to a target by at most `rate` per cycle.
local function rampToward(current, target, rate)
  if current < target then
    return math.min(current + rate, target)
  elseif current > target then
    return math.max(current - rate, target)
  end
  return current
end

local function applyCommonModeOnly(commonMode)
  for _, corner in ipairs(CORNERS) do
    local sig = combineCornerSignal(commonMode, 0)
    craft.cornerSignal[corner] = sig
    setCornerSignal(craft.calibration, corner, sig)
  end
end

local function applyPIDCorrectedThrust(commonMode, dt)
  local pitchErr, rollErr = readAxisErrors(craft.calibration)
  if pitchErr == nil then
    enterFailsafe("invalid gimbal reading during HOVER/LANDING")
    return
  end
  local pitchCmd = pidUpdate(craft.pidPitch, pitchErr, dt)
  local rollCmd  = pidUpdate(craft.pidRoll, rollErr, dt)
  craft.lastCommanded.pitch = pitchCmd
  craft.lastCommanded.roll = rollCmd
  local diffs = computeDifferentials(craft.calibration, pitchCmd, rollCmd)
  for _, corner in ipairs(CORNERS) do
    local sig = combineCornerSignal(commonMode, diffs[corner])
    craft.cornerSignal[corner] = sig
    setCornerSignal(craft.calibration, corner, sig)
  end
end

-- One control cycle. Called every CONTROL_PERIOD seconds by controlLoop().
local function controlCycle(dt)
  craft.heartbeat = craft.heartbeat + 1

  if craft.calibrationActive then
    -- Calibration owns the relays directly (open-loop) while active; the
    -- control loop stands down entirely (failsafe is suspended too, see
    -- calibrationEnter/Exit) but keeps ticking the heartbeat so the
    -- watchdog doesn't fire on an intentionally-paused loop.
    return
  end

  -- Thrust% slider is rate-limited by RAMP_RATE at all times (see README
  -- "Slider changes"), independent of state, so dragging never jumps thrust.
  craft.targetCommonMode = commonModeSignal(craft.thrustPercent)

  if craft.state == "FAILSAFE" then
    killThrust() -- continually enforced; nothing else runs in FAILSAFE
    if craft.pendingTransition == "REARM" then
      craft.pendingTransition = nil
      local cleared, why = failsafeConditionCleared()
      if cleared then
        craft.state = "GROUND"
        craft.failsafeReason = nil
        craft.silentCount = 0
        craft.lastFreshRead = os.clock()
        log("Re-armed -> GROUND")
      else
        craft.failsafeReason = "re-arm blocked: " .. tostring(why)
        log("Re-arm blocked: " .. tostring(why))
      end
    end
    return
  end

  checkFailsafeTriggers(dt)
  if craft.state == "FAILSAFE" then return end -- may have just tripped above

  if craft.state == "GROUND" then
    craft.currentCommonMode = MAX_SIGNAL -- no thrust (15) while grounded
    applyCommonModeOnly(craft.currentCommonMode)
    pidResetIntegral(craft.pidPitch)
    pidResetIntegral(craft.pidRoll)
    if craft.pendingTransition == "TAKEOFF" then
      craft.pendingTransition = nil
      craft.state = "TAKEOFF"
      log("GROUND -> TAKEOFF")
    end

  elseif craft.state == "TAKEOFF" then
    -- Open-loop ramp toward the current thrust% target.
    craft.currentCommonMode = rampToward(craft.currentCommonMode, craft.targetCommonMode, craft.settings.rampRate)
    applyCommonModeOnly(craft.currentCommonMode)
    if craft.currentCommonMode == craft.targetCommonMode then
      craft.settleTimer = craft.settleTimer + 1
      if craft.settleTimer >= SETTLE_TICKS then
        craft.settleTimer = 0
        pidResetIntegral(craft.pidPitch)
        pidResetIntegral(craft.pidRoll)
        craft.state = "HOVER"
        log("TAKEOFF -> HOVER (PID armed)")
      end
    else
      craft.settleTimer = 0
    end

  elseif craft.state == "HOVER" then
    craft.currentCommonMode = rampToward(craft.currentCommonMode, craft.targetCommonMode, craft.settings.rampRate)
    applyPIDCorrectedThrust(craft.currentCommonMode, dt)
    if craft.pendingTransition == "LANDING" then
      craft.pendingTransition = nil
      craft.state = "LANDING"
      log("HOVER -> LANDING")
    end

  elseif craft.state == "LANDING" then
    -- Ramp thrust down to 0 (common-mode -> MAX_SIGNAL) while staying
    -- PID-armed to keep the craft level during descent.
    local groundTarget = MAX_SIGNAL
    craft.currentCommonMode = rampToward(craft.currentCommonMode, groundTarget, craft.settings.rampRate)
    applyPIDCorrectedThrust(craft.currentCommonMode, dt)
    if craft.currentCommonMode == groundTarget then
      craft.touchdownTimer = craft.touchdownTimer + 1
      if craft.touchdownTimer >= TOUCHDOWN_TICKS then
        craft.touchdownTimer = 0
        pidResetIntegral(craft.pidPitch)
        pidResetIntegral(craft.pidRoll)
        craft.state = "GROUND"
        log("LANDING -> GROUND (touchdown assumed)")
      end
    else
      craft.touchdownTimer = 0
    end
  end
end

-- Runs as its own parallel branch: a steady CONTROL_PERIOD heartbeat driving
-- controlCycle(). Stands down (but keeps ticking) while calibration owns
-- the relays directly -- see the craft.calibrationActive guard above.
local function controlLoop()
  while true do
    -- os.sleep yields to the event loop and lets Basalt's own timers run,
    -- rather than consuming every timer event from the shared queue.
    os.sleep(CONTROL_PERIOD)
    controlCycle(CONTROL_PERIOD)
  end
end

--============================================================================
-- 10. CALIBRATION
--============================================================================
-- Shared primitives (Thruster Test-Fire, Gimbal Mapper, Mapping Review) back
-- both the Automatic and Manual flows, which differ only in how tilt
-- impulses are triggered and how much the operator must confirm.
--
-- Expected corner -> (pitch, roll) contribution when a corner's thrust is
-- CUT (see README "Sign conventions" / correction table, derived from craft
-- geometry): cutting a corner sinks it, so:
--   FL cut -> nose-down-ish (pitch-) and left-down-ish (roll+)
--   FR cut -> nose-down-ish (pitch-) and right-down-ish (roll-)
--   BL cut -> nose-up-ish   (pitch+) and left-down-ish (roll+)
--   BR cut -> nose-up-ish   (pitch+) and right-down-ish (roll-)
-- This gives each of the 4 unsigned gimbal-relay "roles" (front/back/left/
-- right) a clean expected activation pattern across the 4 corner fires,
-- which is what the gimbal role-matching step below correlates against.

local GIMBAL_ROLES = {
  { axis = "pitch", sign =  1, label = "front", activatesOn = { FL = false, FR = false, BL = true,  BR = true  } },
  { axis = "pitch", sign = -1, label = "back",  activatesOn = { FL = true,  FR = true,  BL = false, BR = false } },
  { axis = "roll",  sign =  1, label = "left",  activatesOn = { FL = true,  FR = false, BL = true,  BR = false } },
  { axis = "roll",  sign = -1, label = "right", activatesOn = { FL = false, FR = true,  BL = false, BR = true  } },
}

-- ---- calibration session control (open-loop, failsafe suspended) ----------

local function calibrationEnter()
  craft.calibrationActive = true
  craft.failsafeSuspended = true
end

-- Restores failsafe on BOTH the happy path and any error/cleanup path.
local function calibrationExit()
  craft.calibrationActive = false
  craft.failsafeSuspended = false
end

-- ---- Thruster Test-Fire (shared primitive) ---------------------------------

-- Applies (or restores) a thruster's raw output directly, bypassing
-- calibration.thrusters (used before the mapping exists yet).
local function rawThrusterSet(relayInfo, value)
  relaySetOutput(relayInfo.obj, DEFAULT_THRUSTER_SIDE, value)
end

-- Fires a bounded impulse on a single thruster relay: cuts it to MAX_SIGNAL
-- (no thrust) for `ticks` cycles from a CALIBRATION_BASE_SIGNAL baseline.
-- NOTE: this does NOT restore the baseline -- the caller restores it via
-- restoreBaseline() after sampling the response while the corner is still cut.
local function testFireRelay(relayInfo, ticks)
  rawThrusterSet(relayInfo, MAX_SIGNAL)
  sleepTicks(ticks)
end

local function restoreBaseline(relayInfo)
  rawThrusterSet(relayInfo, CALIBRATION_BASE_SIGNAL)
end

-- ---- Step 1: enumerate + classify + count-validate -------------------------

-- Returns (thrusterRelays, gimbalRelays) or (nil, nil, errString).
local function calibrationEnumerate()
  local found = discoverRelays()
  if #found ~= 8 then
    local sides = {}
    for _, r in ipairs(found) do table.insert(sides, r.name) end
    return nil, nil, ("expected exactly 8 redstone_relay peripherals, found %d (%s)")
      :format(#found, table.concat(sides, ", "))
  end
  Relays = {}
  for _, r in ipairs(found) do Relays[r.name] = r end

  local thrusters, gimbals, unknown = classifyRelays(found)
  if #thrusters ~= 4 or #gimbals ~= 4 then
    return nil, nil, ("relay naming ambiguous: %d matched 'thruster', %d matched 'gimbal', %d unrecognized -- rename peripherals to include 'thruster' or 'gimbal'")
      :format(#thrusters, #gimbals, #unknown)
  end
  return thrusters, gimbals
end

-- ---- Step 2: thruster -> corner mapping (the human step, both flows) ------

-- `askCorner` is a UI callback: askCorner(promptText) -> "FL"|"FR"|"BL"|"BR"
-- (blocks until the operator answers). Returns calibration.thrusters table.
local function mapThrusters(thrusterRelays, askCorner)
  local mapping = {}
  local usedCorners = {}
  for _, relayInfo in ipairs(thrusterRelays) do
    rawThrusterSet(relayInfo, CALIBRATION_BASE_SIGNAL)
  end
  sleepTicks(IMPULSE_TICKS) -- let the craft settle at baseline first

  for _, relayInfo in ipairs(thrusterRelays) do
    testFireRelay(relayInfo, IMPULSE_TICKS)
    local corner = askCorner(("Which thruster just changed? (relay: %s)"):format(relayInfo.name))
    restoreBaseline(relayInfo)
    while usedCorners[corner] do
      corner = askCorner(("Corner %s was already assigned -- pick a different corner for %s"):format(corner, relayInfo.name))
    end
    usedCorners[corner] = true
    mapping[corner] = { name = relayInfo.name, side = DEFAULT_THRUSTER_SIDE }
  end
  return mapping
end

-- ---- Step 3: Gimbal Mapper (shared; tiltSource differs by flow) -----------

-- tiltSource(corner, thrusterMapping) performs one tilt impulse for `corner`
-- and returns once the craft has settled back down. Automatic and manual
-- flows each provide their own tiltSource (see below).

-- Side lock-on: for each gimbal relay, find which of its candidate sides
-- actually carries a live signal by looking for the side with the greatest
-- total deviation across all sampled impulses.
local function lockOnGimbalSides(gimbalRelays, samples)
  -- samples: { [relayName] = { [side] = { corner1=v, corner2=v, ... }, ... } }
  local locked = {}
  for _, relayInfo in ipairs(gimbalRelays) do
    local bestSide, bestScore = nil, -1
    for _, side in ipairs(SIDE_CANDIDATES) do
      local perCorner = samples[relayInfo.name] and samples[relayInfo.name][side]
      if perCorner then
        local score = 0
        for _, v in pairs(perCorner) do score = score + v end
        if score > bestScore then
          bestScore, bestSide = score, side
        end
      end
    end
    locked[relayInfo.name] = bestSide
  end
  return locked
end

-- Matches each gimbal relay to one of the 4 GIMBAL_ROLES by correlating its
-- measured per-corner response against each role's expected activation
-- pattern (see GIMBAL_ROLES above). Greedy best-match with a uniqueness
-- check; returns (roleAssignment, ok, err) where roleAssignment maps
-- relayName -> role table.
local function matchGimbalRoles(gimbalRelays, lockedSides, responses)
  -- responses: { [relayName] = { FL=v, FR=v, BL=v, BR=v } } on the locked side
  local scores = {} -- [relayName] = { [roleIndex] = score }
  for _, relayInfo in ipairs(gimbalRelays) do
    scores[relayInfo.name] = {}
    local r = responses[relayInfo.name] or {}
    for i, role in ipairs(GIMBAL_ROLES) do
      local score = 0
      for _, corner in ipairs(CORNERS) do
        local measured = r[corner] or 0
        if role.activatesOn[corner] then
          score = score + measured      -- reward expected activation
        else
          score = score - measured      -- penalize spurious activation
        end
      end
      scores[relayInfo.name][i] = score
    end
  end

  -- Greedy assignment: repeatedly take the best remaining (relay, role) pair.
  local assignment, usedRoles, usedRelays = {}, {}, {}
  for _ = 1, 4 do
    local bestRelay, bestRole, bestScore = nil, nil, -math.huge
    for _, relayInfo in ipairs(gimbalRelays) do
      if not usedRelays[relayInfo.name] then
        for i = 1, 4 do
          if not usedRoles[i] and scores[relayInfo.name][i] > bestScore then
            bestScore, bestRelay, bestRole = scores[relayInfo.name][i], relayInfo.name, i
          end
        end
      end
    end
    if not bestRelay then break end
    usedRelays[bestRelay] = true
    usedRoles[bestRole] = true
    assignment[bestRelay] = GIMBAL_ROLES[bestRole]
  end

  if not (usedRoles[1] and usedRoles[2] and usedRoles[3] and usedRoles[4]) then
    return nil, false, "could not uniquely resolve all 4 gimbal roles (negligible/ambiguous response)"
  end
  return assignment, true
end

-- Runs the full Gimbal Mapper: samples all 4 corner impulses via
-- tiltSource, locks on sides, solves roles, and derives the coupling
-- matrix (each corner's measured signed pitch/roll response IS its
-- coupling entry -- 4 corners x (pitch,roll) = 8 measurements for 8
-- unknowns, fully determined; see README "Coupling matrix").
-- `tiltSource(corner, thrusterMapping)` must FIRE AND HOLD the impulse
-- (not restore it) -- this function samples the peak response while the
-- corner is still cut, then restores it via thrusterRelaysByName.
-- Returns (gimbals, coupling, expected, ok, err)
local function runGimbalMapper(gimbalRelays, thrusterMapping, tiltSource, thrusterRelaysByName)
  local rawSamples = {}     -- [relayName][side][corner] = deviation from baseline
  local lockedResponses = {} -- [relayName][corner] = signed-ready raw value (post lock-on)

  for _, relayInfo in ipairs(gimbalRelays) do
    rawSamples[relayInfo.name] = {}
    for _, side in ipairs(SIDE_CANDIDATES) do
      rawSamples[relayInfo.name][side] = {}
    end
  end

  local pitchRollByCorner = {}

  for _, corner in ipairs(CORNERS) do
    -- Baseline read (all candidate sides, all relays) before the impulse.
    local baseline = {}
    for _, relayInfo in ipairs(gimbalRelays) do
      baseline[relayInfo.name] = {}
      for _, side in ipairs(SIDE_CANDIDATES) do
        baseline[relayInfo.name][side] = relayGetInput(relayInfo.obj, side) or 0
      end
    end

    tiltSource(corner, thrusterMapping) -- fires AND HOLDS the impulse

    -- Peak read while the impulse is still active.
    local peak = {}
    for _, relayInfo in ipairs(gimbalRelays) do
      peak[relayInfo.name] = {}
      for _, side in ipairs(SIDE_CANDIDATES) do
        peak[relayInfo.name][side] = relayGetInput(relayInfo.obj, side) or 0
      end
    end

    -- Now restore the corner and let the craft settle before the next fire.
    restoreBaseline(thrusterRelaysByName[thrusterMapping[corner].name])
    sleepTicks(IMPULSE_TICKS)

    for _, relayInfo in ipairs(gimbalRelays) do
      for _, side in ipairs(SIDE_CANDIDATES) do
        local delta = math.abs(peak[relayInfo.name][side] - baseline[relayInfo.name][side])
        rawSamples[relayInfo.name][side][corner] = delta
      end
    end
  end

  local locked = lockOnGimbalSides(gimbalRelays, rawSamples)
  for _, relayInfo in ipairs(gimbalRelays) do
    if not locked[relayInfo.name] then
      return nil, nil, nil, false, "no responsive side found for " .. relayInfo.name
    end
    lockedResponses[relayInfo.name] = {}
    for _, corner in ipairs(CORNERS) do
      lockedResponses[relayInfo.name][corner] = rawSamples[relayInfo.name][locked[relayInfo.name]][corner]
    end
  end

  local roles, ok, err = matchGimbalRoles(gimbalRelays, locked, lockedResponses)
  if not ok then
    return nil, nil, nil, false, err
  end

  -- Build gimbals mapping and, from it, signed per-corner pitch/roll
  -- responses (the coupling matrix) and expected peak magnitudes.
  local gimbals = {}
  for name, role in pairs(roles) do
    gimbals[name] = { side = locked[name], axis = role.axis, sign = role.sign }
  end

  local coupling = {}
  local expectedPitch, expectedRoll = 0, 0
  for _, corner in ipairs(CORNERS) do
    local pitch, roll = 0, 0
    for name, role in pairs(roles) do
      local v = lockedResponses[name][corner]
      if role.axis == "pitch" then pitch = pitch + role.sign * v
      else roll = roll + role.sign * v end
    end
    coupling[corner] = { pitch = pitch, roll = roll }
    expectedPitch = math.max(expectedPitch, math.abs(pitch))
    expectedRoll = math.max(expectedRoll, math.abs(roll))
  end

  -- Flag negligible or sign-inverted axes against the expected table (see
  -- README "Sign conventions" table) for automatic->manual fallback.
  local EXPECTED_SIGNS = {
    FL = { pitch = -1, roll =  1 }, FR = { pitch = -1, roll = -1 },
    BL = { pitch =  1, roll =  1 }, BR = { pitch =  1, roll = -1 },
  }
  for _, corner in ipairs(CORNERS) do
    local c = coupling[corner]
    if math.abs(c.pitch) < 0.5 and math.abs(c.roll) < 0.5 then
      return gimbals, coupling, { pitch = expectedPitch, roll = expectedRoll }, false,
        "negligible response on corner " .. corner .. " -- flagged for re-run"
    end
    if c.pitch ~= 0 and (c.pitch > 0) ~= (EXPECTED_SIGNS[corner].pitch > 0) then
      return gimbals, coupling, { pitch = expectedPitch, roll = expectedRoll }, false,
        "inverted pitch response on corner " .. corner .. " -- flagged for re-run"
    end
    if c.roll ~= 0 and (c.roll > 0) ~= (EXPECTED_SIGNS[corner].roll > 0) then
      return gimbals, coupling, { pitch = expectedPitch, roll = expectedRoll }, false,
        "inverted roll response on corner " .. corner .. " -- flagged for re-run"
    end
  end

  return gimbals, coupling, { pitch = expectedPitch, roll = expectedRoll }, true
end

-- Automatic tilt source: fires the Test-Fire primitive itself, no operator
-- input. Fires AND HOLDS -- runGimbalMapper samples before restoring.
local function makeAutoTiltSource(thrusterRelaysByName)
  return function(corner, thrusterMapping)
    local relayInfo = thrusterRelaysByName[thrusterMapping[corner].name]
    testFireRelay(relayInfo, IMPULSE_TICKS)
  end
end

-- Manual tilt source: waits for the operator to select a corner and press
-- Fire via the UI. `waitForFire` is a UI callback: waitForFire(corner) ->
-- blocks until the operator fires that corner, then returns. Fires AND
-- HOLDS -- runGimbalMapper samples before restoring.
local function makeManualTiltSource(thrusterRelaysByName, waitForFire)
  return function(corner, thrusterMapping)
    waitForFire(corner)
    local relayInfo = thrusterRelaysByName[thrusterMapping[corner].name]
    testFireRelay(relayInfo, IMPULSE_TICKS)
  end
end

-- ---- Step 4: Validation (shared) -------------------------------------------

-- Pair-fire validation: fires corner pairs to confirm clean single-axis
-- tilts and correct signs, per README "Pair-fire validation".
local function validatePairFire(thrusterRelaysByName, thrusterMapping, calibration)
  local function fireCorners(corners)
    for _, c in ipairs(corners) do
      rawThrusterSet(thrusterRelaysByName[thrusterMapping[c].name], MAX_SIGNAL)
    end
    sleepTicks(IMPULSE_TICKS)
    local pitch, roll = readAxisErrors(calibration)
    for _, c in ipairs(corners) do
      restoreBaseline(thrusterRelaysByName[thrusterMapping[c].name])
    end
    sleepTicks(IMPULSE_TICKS)
    return pitch, roll
  end

  local frontPitch = select(1, fireCorners({ "FL", "FR" }))
  local backPitch  = select(1, fireCorners({ "BL", "BR" }))
  local leftRoll   = select(2, fireCorners({ "FL", "BL" }))
  local rightRoll  = select(2, fireCorners({ "FR", "BR" }))

  local noiseFloorPitch = calibration.expected.pitch * NOISE_FLOOR_FRACTION
  local noiseFloorRoll  = calibration.expected.roll * NOISE_FLOOR_FRACTION

  if math.abs(frontPitch - backPitch) < noiseFloorPitch then
    return false, "pair-fire: front/back pitch authority below noise floor"
  end
  if math.abs(leftRoll - rightRoll) < noiseFloorRoll then
    return false, "pair-fire: left/right roll authority below noise floor"
  end
  -- front-pair cut should read pitch- relative to back-pair cut (pitch+)
  if not (frontPitch < backPitch) then
    return false, "pair-fire: pitch sign check failed"
  end
  if not (leftRoll > rightRoll) then
    return false, "pair-fire: roll sign check failed"
  end
  return true
end

-- Startup contact-check: pulse each thruster and confirm the relay responds
-- (a stuck-off corner is recoverable; a stuck-on corner is not, and cannot
-- be detected purely in software -- flagged for operator visual check).
local function validateContactCheck(thrusterRelaysByName, thrusterMapping)
  for _, corner in ipairs(CORNERS) do
    local relayInfo = thrusterRelaysByName[thrusterMapping[corner].name]
    if peripheral.getType(relayInfo.name) ~= "redstone_relay" then
      return false, "thruster relay for " .. corner .. " is not responding"
    end
    -- Pulse the relay to exercise it (cut to no-thrust briefly, then restore
    -- the baseline). A stuck-off corner is recoverable; a stuck-on corner
    -- cannot be detected purely in software -- flagged for operator visual
    -- check (see README "Startup contact-check").
    rawThrusterSet(relayInfo, MAX_SIGNAL)
    sleepTicks(1)
    restoreBaseline(relayInfo)
  end
  return true
end

-- Full validation pass, shared by both flows.
local function runValidation(thrusterRelaysByName, thrusterMapping, calibration)
  local ok, err = validateContactCheck(thrusterRelaysByName, thrusterMapping)
  if not ok then return false, err end

  local pitch, roll = readAxisErrors(calibration)
  if pitch == nil then return false, "gimbal reading invalid during validation" end
  -- Confirmed-signed response check happens implicitly via pair-fire below.

  ok, err = validatePairFire(thrusterRelaysByName, thrusterMapping, calibration)
  if not ok then return false, err end

  return true
end

-- ---- Top-level calibration orchestration (used by both flows) ------------

-- callbacks = {
--   askCorner(promptText) -> "FL"|"FR"|"BL"|"BR"                 (both flows)
--   waitForFire(corner)                                          (manual only)
--   reviewMapping(thrusterMapping, gimbals, autoAccept) -> finalThrusterMapping, finalGimbals
--   notify(text) / warn(text)
-- }
-- Returns (calibrationTable, ok, err)
local function runCalibrationFlow(mode, callbacks)
  calibrationEnter()

  local ok, result = pcall(function()
    local thrusterRelays, gimbalRelays, enumErr = calibrationEnumerate()
    if not thrusterRelays then error(enumErr, 0) end

    local thrusterRelaysByName = {}
    for _, r in ipairs(thrusterRelays) do thrusterRelaysByName[r.name] = r end

    callbacks.notify("Mapping thrusters...")
    local thrusterMapping = mapThrusters(thrusterRelays, callbacks.askCorner)

    local tiltSource
    if mode == "auto" then
      tiltSource = makeAutoTiltSource(thrusterRelaysByName)
    else
      tiltSource = makeManualTiltSource(thrusterRelaysByName, callbacks.waitForFire)
    end

    callbacks.notify("Mapping gimbal relays...")
    local gimbals, coupling, expected, mapOk, mapErr =
      runGimbalMapper(gimbalRelays, thrusterMapping, tiltSource, thrusterRelaysByName)

    if not mapOk and mode == "auto" then
      -- Automatic->manual gimbal fallback: re-run the ENTIRE Gimbal Mapper
      -- in manual mode rather than partially re-sampling.
      callbacks.warn("Automatic gimbal solve flagged an issue (" .. tostring(mapErr) .. "); falling back to manual gimbal mapping.")
      tiltSource = makeManualTiltSource(thrusterRelaysByName, callbacks.waitForFire)
      gimbals, coupling, expected, mapOk, mapErr =
        runGimbalMapper(gimbalRelays, thrusterMapping, tiltSource, thrusterRelaysByName)
    end

    if not mapOk then
      error("gimbal mapping failed: " .. tostring(mapErr), 0)
    end

    -- Mapping Review: automatic auto-accepts (pre-filled, edit to override);
    -- manual requires explicit confirmation. Both share one review screen.
    local autoAccept = (mode == "auto")
    local finalThrusters, finalGimbals = callbacks.reviewMapping(thrusterMapping, gimbals, autoAccept)

    local calibration = {
      version = CALIBRATION_SCHEMA_VERSION,
      thrusters = finalThrusters,
      gimbals = finalGimbals,
      coupling = coupling,
      expected = expected,
    }

    callbacks.notify("Validating...")
    -- Temporarily install the calibration so validation helpers (which read
    -- through calibration.thrusters/gimbals) work against the new mapping.
    local previous = craft.calibration
    craft.calibration = calibration
    local valid, verr = runValidation(thrusterRelaysByName, finalThrusters, calibration)
    if not valid then
      craft.calibration = previous
      error("validation failed: " .. tostring(verr), 0)
    end

    -- Kill thrust before leaving calibration; HOVER/TAKEOFF will re-ramp from GROUND.
    killThrust()

    local saved = saveCalibration(calibration)
    if not saved then
      error("failed to write calibration.cfg", 0)
    end

    return calibration
  end)

  -- Failsafe auto-restore on error/exit: happy path and error/cleanup path
  -- both re-enable failsafe here.
  calibrationExit()

  if not ok then
    log("Calibration error: " .. tostring(result))
    return nil, false, result
  end
  return result, true, nil
end

--============================================================================
-- 11. BASALT UI
--============================================================================
-- Home / Settings / Info tabs, a Calibration modal, and a full-screen
-- FAILSAFE overlay. The UI is read-only on craft.state: buttons call the
-- request* functions from section 9 rather than mutating state directly.

local basalt = require("basalt")

local ui = {}
local main, tabHome, tabSettings, tabInfo

local STATE_COLORS = {
  GROUND = colors.gray, TAKEOFF = colors.yellow, HOVER = colors.green,
  LANDING = colors.orange, FAILSAFE = colors.red,
}

-- Simple blocking-answer helper: creates buttons on `parent`, waits for one
-- to be clicked, removes them, and returns the chosen value. Runs inside a
-- basalt.schedule()'d coroutine (see calibration UI below) so it can safely
-- block without freezing rendering.
local function askButtons(parent, y, options)
  local btns = {}
  local x = 2
  for _, opt in ipairs(options) do
    local b = parent:addButton()
      :setText(opt.label)
      :setPosition(x, y)
      :setSize(#opt.label + 2, 3)
      :onClick(function() os.queueEvent("bumper_answer", opt.value) end)
    table.insert(btns, b)
    x = x + #opt.label + 3
  end
  local _, value = os.pullEvent("bumper_answer")
  for _, b in ipairs(btns) do b:remove() end
  return value
end

local function askCornerUI(parent, statusLabel, promptText)
  statusLabel:setText(promptText)
  return askButtons(parent, 10, {
    { label = "FL", value = "FL" }, { label = "FR", value = "FR" },
    { label = "BL", value = "BL" }, { label = "BR", value = "BR" },
  })
end

--============================================================================
-- 11a. HOME SCREEN
--============================================================================

local function buildHome(frame)
  local stateLabel = frame:addLabel()
    :setText("GROUND"):setPosition(2, 2):setForeground(STATE_COLORS.GROUND)

  local thrustLabel = frame:addLabel():setText("Thrust: 100%"):setPosition(2, 4)
  local thrustSlider = frame:addSlider()
    :setPosition(2, 5):setSize(30, 1):setMax(100)
    :setValue(craft.thrustPercent)
    :onChange(function(self, value)
      craft.thrustPercent = value
      thrustLabel:setText(("Thrust: %d%%"):format(value))
    end)

  local takeoffBtn = frame:addButton():setText("Takeoff")
    :setPosition(2, 7):setSize(10, 3)
    :onClick(function() requestTakeoff() end)

  local landBtn = frame:addButton():setText("Land")
    :setPosition(13, 7):setSize(10, 3)
    :onClick(function() requestLand() end)

  local calBtn = frame:addButton():setText("[gear] Calibrate")
    :setPosition(24, 7):setSize(16, 3)
    :onClick(function() requestCalibrate() end)

  local cornerLabels = {}
  local y = 11
  frame:addLabel():setText("Commanded corner thrust:"):setPosition(2, y)
  for i, corner in ipairs(CORNERS) do
    cornerLabels[corner] = frame:addLabel():setText(corner .. ": --")
      :setPosition(2 + ((i - 1) % 2) * 16, y + 1 + math.floor((i - 1) / 2))
  end

  ui.home = {
    stateLabel = stateLabel, thrustSlider = thrustSlider,
    takeoffBtn = takeoffBtn, landBtn = landBtn, cornerLabels = cornerLabels,
  }
end

local function refreshHome()
  local h = ui.home
  if not h then return end
  h.stateLabel:setText(craft.state):setForeground(STATE_COLORS[craft.state] or colors.white)
  h.takeoffBtn:setBackground(craft.state == "GROUND" and colors.gray or colors.black)
  h.landBtn:setBackground(craft.state == "HOVER" and colors.gray or colors.black)
  for _, corner in ipairs(CORNERS) do
    local sig = craft.cornerSignal[corner]
    local pct = round(100 * (MAX_SIGNAL - sig) / MAX_SIGNAL)
    h.cornerLabels[corner]:setText(("%s: %d%%"):format(corner, pct))
  end
end

--============================================================================
-- 11b. SETTINGS SCREEN
--============================================================================

local function buildSettings(frame)
  local inputs = {}
  local y = 2
  frame:addLabel():setText("PID gains (Kp / Ki / Kd) and deadzone, per axis:"):setPosition(2, y)
  y = y + 2
  for _, axis in ipairs(AXES) do
    frame:addLabel():setText(axis .. ":"):setPosition(2, y)
    local g = craft.settings.gains[axis]
    inputs[axis] = {}
    local labels = { "Kp", "Ki", "Kd" }
    local x = 10
    for _, field in ipairs(labels) do
      frame:addLabel():setText(field):setPosition(x, y)
      local inp = frame:addInput():setPosition(x, y + 1):setSize(6, 1)
        :setDefaultText(tostring(g[field]))
      inputs[axis][field] = inp
      x = x + 7
    end
    frame:addLabel():setText("deadzone"):setPosition(x, y)
    local dz = frame:addInput():setPosition(x, y + 1):setSize(6, 1)
      :setDefaultText(tostring(craft.settings.deadzone[axis]))
    inputs[axis].deadzone = dz
    y = y + 3
  end

  frame:addLabel():setText("Ramp rate (signal/tick):"):setPosition(2, y)
  local rampInput = frame:addInput():setPosition(26, y):setSize(6, 1)
    :setDefaultText(tostring(craft.settings.rampRate))
  y = y + 2

  local statusLabel = frame:addLabel():setText(""):setPosition(2, y + 2)

  frame:addButton():setText("Save Settings"):setPosition(2, y)
    :setSize(16, 3)
    :onClick(function()
      local function num(inp, fallback)
        local v = tonumber(inp:getValue())
        return v or fallback
      end
      local s = craft.settings
      for _, axis in ipairs(AXES) do
        s.gains[axis].Kp = num(inputs[axis].Kp, s.gains[axis].Kp)
        s.gains[axis].Ki = num(inputs[axis].Ki, s.gains[axis].Ki)
        s.gains[axis].Kd = num(inputs[axis].Kd, s.gains[axis].Kd)
        s.deadzone[axis] = num(inputs[axis].deadzone, s.deadzone[axis])
      end
      s.rampRate = num(rampInput, s.rampRate)
      applySettings(s)
      local ok = saveSettings(s)
      statusLabel:setText(ok and "Saved." or "Save FAILED (disk error)")
    end)
end

--============================================================================
-- 11c. INFO SCREEN
--============================================================================

local function buildInfo(frame)
  local body = frame:addLabel():setText(""):setPosition(2, 2):setSize(37, 15)
  ui.info = { body = body }
end

local function refreshInfo()
  if not ui.info then return end
  local lines = { "BumperOS v" .. BUMPER_OS_VERSION, "" }
  if craft.calibration then
    table.insert(lines, "Calibration: OK (schema v" .. craft.calibration.version .. ")")
    table.insert(lines, "")
    table.insert(lines, "Thrusters:")
    for _, corner in ipairs(CORNERS) do
      local t = craft.calibration.thrusters[corner]
      table.insert(lines, ("  %s -> %s [%s]"):format(corner, t.name, t.side))
    end
    table.insert(lines, "Gimbals:")
    for name, g in pairs(craft.calibration.gimbals) do
      table.insert(lines, ("  %s -> %s %s%d [%s]"):format(name, g.axis, g.sign > 0 and "+" or "-", 1, g.side))
    end
  else
    table.insert(lines, "Calibration: MISSING -- run Calibrate from Home")
  end
  ui.info.body:setText(table.concat(lines, "\n"))
end

--============================================================================
-- 11d. FAILSAFE OVERLAY
--============================================================================

local function buildFailsafeOverlay(parent)
  local overlay = parent:addFrame()
    :setPosition(1, 1):setSize("parent.w", "parent.h")
    :setBackground(colors.red)
  overlay:addLabel():setText("FAILSAFE"):setPosition(2, 2):setForeground(colors.white)
  local reasonLabel = overlay:addLabel():setText(""):setPosition(2, 4):setSize("parent.w - 4", 4)
  overlay:addButton():setText("Re-arm"):setPosition(2, 9):setSize(12, 3)
    :onClick(function() requestRearm() end)
  overlay:hide()
  ui.failsafe = { frame = overlay, reasonLabel = reasonLabel }
end

local function refreshFailsafeOverlay()
  local f = ui.failsafe
  if not f then return end
  if craft.state == "FAILSAFE" then
    f.reasonLabel:setText("Reason: " .. tostring(craft.failsafeReason))
    f.frame:show()
  else
    f.frame:hide()
  end
end

--============================================================================
-- 11e. CALIBRATION MODAL
--============================================================================

-- Builds the (initially hidden) calibration modal and returns callback
-- implementations wired to its widgets, for use with runCalibrationFlow().
local function buildCalibrationModal(parent)
  local modal = parent:addFrame()
    :setPosition(1, 1):setSize("parent.w", "parent.h")
    :setBackground(colors.black)
  modal:hide()

  local title = modal:addLabel():setText("Calibration"):setPosition(2, 2)
  local statusLabel = modal:addLabel():setText(""):setPosition(2, 4):setSize("parent.w - 4", 3)

  local reviewFrame = modal:addFrame():setPosition(2, 8):setSize("parent.w - 4", "parent.h - 10")
  reviewFrame:hide()

  local function close()
    modal:hide()
  end

  local callbacks = {
    notify = function(text) statusLabel:setText(text) end,
    warn = function(text) statusLabel:setText("[!] " .. text) end,
    askCorner = function(promptText)
      return askCornerUI(modal, statusLabel, promptText)
    end,
    waitForFire = function(corner)
      statusLabel:setText(("Select %s and press Fire"):format(corner))
      local fireBtn = modal:addButton():setText("Fire " .. corner)
        :setPosition(2, 10):setSize(14, 3)
        :onClick(function() os.queueEvent("bumper_answer", true) end)
      os.pullEvent("bumper_answer")
      fireBtn:remove()
    end,
    reviewMapping = function(thrusterMapping, gimbals, autoAccept)
      reviewFrame:show()
      -- Clear any widgets left over from a previous review pass (e.g. the
      -- automatic->manual gimbal fallback re-enters this screen).
      for _, c in ipairs(reviewFrame:getChildren() or {}) do c:remove() end
      local lines = { "Thruster mapping:" }
      for _, corner in ipairs(CORNERS) do
        table.insert(lines, ("  %s -> %s"):format(corner, thrusterMapping[corner].name))
      end
      table.insert(lines, "Gimbal mapping:")
      for name, g in pairs(gimbals) do
        table.insert(lines, ("  %s -> %s%s"):format(name, g.axis, g.sign > 0 and "+" or "-"))
      end
      local reviewLabel = reviewFrame:addLabel():setText(table.concat(lines, "\n")):setPosition(1, 1)

      local acceptLabel = autoAccept and "Accept (auto-filled)" or "Confirm"
      local proceed = false
      local btn = reviewFrame:addButton():setText(acceptLabel)
        :setPosition(1, #lines + 2):setSize(#acceptLabel + 2, 3)
        :onClick(function() os.queueEvent("bumper_answer", true) end)
      os.pullEvent("bumper_answer")
      btn:remove()
      reviewLabel:remove()
      reviewFrame:hide()
      -- Prototype note: manual per-field override editing is not wired up
      -- in this single-file prototype; operators who need to override a
      -- flagged relay can re-run calibration with corrected wiring/naming.
      return thrusterMapping, gimbals
    end,
  }

  local function runFlow(mode)
    modal:show()
    statusLabel:setText("Starting " .. mode .. " calibration...")
    basalt.thread(function()
      local calibration, ok, err = runCalibrationFlow(mode, callbacks)
      if ok then
        craft.calibration = calibration
        statusLabel:setText("Calibration complete.")
        refreshInfo()
      else
        statusLabel:setText("Calibration FAILED: " .. tostring(err))
      end
      sleepTicks(20)
      close()
    end)
  end

  local autoBtn = modal:addButton():setText("Automatic (default)")
    :setPosition(2, 16):setSize(22, 3)
    :onClick(function() runFlow("auto") end)
  local manualBtn = modal:addButton():setText("Manual")
    :setPosition(26, 16):setSize(14, 3)
    :onClick(function() runFlow("manual") end)

  ui.calibration = { frame = modal, statusLabel = statusLabel }

  openCalibrationModal = function()
    modal:show()
    statusLabel:setText("Choose calibration type (Automatic recommended):")
  end

  return modal
end

--============================================================================
-- 11f. TOP-LEVEL UI ASSEMBLY & REFRESH LOOP
--============================================================================

local function buildUI()
  main = basalt.getMainFrame()

  local tabs = main:addFrame():setPosition(1, 1):setSize("parent.w", 1)
  tabHome = main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1")
  tabSettings = main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1")
  tabInfo = main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1")
  tabSettings:hide()
  tabInfo:hide()

  local function showTab(which)
    tabHome:hide(); tabSettings:hide(); tabInfo:hide()
    which:show()
  end

  tabs:addButton():setText("Home"):setPosition(1, 1):setSize(8, 1)
    :onClick(function() showTab(tabHome) end)
  tabs:addButton():setText("Settings"):setPosition(9, 1):setSize(10, 1)
    :onClick(function() showTab(tabSettings) end)
  tabs:addButton():setText("Info"):setPosition(19, 1):setSize(8, 1)
    :onClick(function() showTab(tabInfo) end)

  buildHome(tabHome)
  buildSettings(tabSettings)
  buildInfo(tabInfo)
  buildCalibrationModal(main)
  buildFailsafeOverlay(main)

  -- Mirror to a connected monitor if present, adapting to its size.
  local monitor = peripheral.find("monitor")
  if monitor then
    local monFrame = basalt.createFrame():setTerm(monitor)
    monFrame:addLabel():setText("BumperOS mirrored -- see computer for controls")
      :setPosition(2, 2)
  end

  refreshInfo()
end

-- Periodically refreshes UI elements that reflect craft state (state
-- indicator, corner thrust %, failsafe overlay). Runs as its own parallel
-- branch alongside basalt.run().
local function uiRefreshLoop()
  while true do
    refreshHome()
    refreshFailsafeOverlay()
    os.sleep(0.25)
  end
end

--============================================================================
-- 12. BOOT SEQUENCE & MAIN
--============================================================================

local function boot()
  log("BumperOS v" .. BUMPER_OS_VERSION .. " booting...")

  local settings, usedDefaults, settingsErr = loadSettings()
  if settingsErr then log(settingsErr) end
  applySettings(settings)
  -- Seed the live slider from the persisted default (applySettings no longer
  -- does this, so saving settings mid-flight doesn't reset the slider).
  craft.thrustPercent = settings.defaultThrustPercent
  craft.targetCommonMode = commonModeSignal(craft.thrustPercent)

  local calibration, calStatus, calErr = loadCalibration()
  if calErr then log(calErr) end
  craft.calibration = calibration

  buildUI()

  if calStatus == "corrupt-restored-backup" and ui.calibration then
    ui.calibration.statusLabel:setText(tostring(calErr))
  end

  if craft.calibration == nil then
    -- First boot, or later boot with no recoverable calibration: prompt
    -- calibration before any control logic is allowed to arm.
    openCalibrationModal()
  end

  craft.state = "GROUND"
end

local function main_run()
  boot()
  parallel.waitForAny(controlLoop, watchdogLoop, uiRefreshLoop, function() basalt.run() end)
end

main_run()