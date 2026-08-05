# Bumper OS

This program controls a hovercraft style vehicle using Create: Aeronautics and CC: Tweaked utilizing a PID style controller.
This PID system will only focus on keeping the vehicle level. A separate system will be used for horizontal thrust.

Goals
- Allow the craft to take off smoothly and hover
- Allow the user to control vertical thrust 0% - 100% (which sets the hover height)
  - Vertical thrust is controlled via a common-mode thrust offset (see "Thrust Control").
  - This should not worry about compensating for vehicle weight.

## General Information
- The PID will be controlled with 8 `Redstone Relays` from CC: Tweaked
  - 4 Surrounding a gimbal sensor that will input the pitch/roll
  - 4 One on each thruster
- The UI library will be Basalt 2.5 (https://basalt.madefor.cc/2.5/guides/)

- Thrust is always max. To reduce thrust, apply redstone signal:
  - 0: Max Thrust
  - 15: No Thrust

## Thrust Control

There is **no altitude sensor**. Vertical thrust is controlled **open-loop** via a **common-mode thrust offset** applied equally to all four thrusters. This is orthogonal to the leveling PID, which applies per-corner *differential* corrections on top.

- **Mechanism**: raising the common-mode signal reduces total thrust and lets the craft settle lower; lowering it increases thrust and lets it rise. The craft settles at the height where total thrust balances weight.
- **Signal convention**: `0 = max thrust`, `15 = no thrust`. Thrust control *raises* the common-mode signal to reduce thrust.
- **User control (UI slider is inverted)**: the UI exposes a **thrust percentage** slider — `100%` = max thrust (highest hover), `0%` = no thrust (lowest allowed). This is a UI element only: it keeps the mental model aligned with the signal convention (`0 = max thrust`, `15 = no thrust`). The default/starting value is `100%` (max thrust), so no buffer is engaged until the user reduces thrust.
- **Buffer (`THRUST_BUFFER`)**: a **code-only constant**, default `3`, **not user-facing**. It clamps the common-mode signal to `15 - THRUST_BUFFER`, reserving signal headroom for the leveling PID's differential corrections — so a corner can still be pushed toward full or no thrust to stabilize even at the lowest setting. It is a safety margin, not a control, so it is never exposed to the user (a user-settable buffer of `0` would let the craft reach a thrust where it cannot level).
- **Range (slider → signal)**: `common_mode = (15 - THRUST_BUFFER) × (1 − thrust% / 100)`. At `100%` (max thrust) → common-mode `0`; at `0%` (no thrust) → common-mode `15 - THRUST_BUFFER` (`12` with the default). The buffer only constrains the low end.
- **Extreme asymmetry (accepted)**: at `100%` (max thrust) corners can only be *reduced* (can't go below `0`); at `0%` (no thrust) corners can only be *increased* (up to `15`). The buffer guarantees some "increase" authority at the lowest setting but cannot make the extremes symmetric — the craft spends most time mid-range where authority is balanced.
- **Per-corner independence**: because thrust is common-mode and leveling is differential, uneven thruster authority (corners needing different signals to stay level) does not conflict with thrust control — the differential offset rides on top of the common-mode offset.
- **Composition**: `corner_signal = common_mode(thrust%) + differential_correction(corner)`, both clamped to `[0, 15]`.
- **Limitation (accepted for v1)**: this is open-loop — it sets a thrust level, not a measured height. The actual hover height depends on vehicle weight and thruster authority, so the same setting may hover at different heights under different loads.

## PID Control Law

Two decoupled PIDs (one per axis) drive the craft level. Each produces a signed command in signal units, which the coupling matrix maps to per-corner differential signals that ride on top of the common-mode thrust offset.

### Structure

```
pitch_error → [pitch PID] → pitch_cmd ─┐
                                       ├→ coupling matrix → dFL, dFR, dBL, dBR
roll_error  → [roll PID]  → roll_cmd ──┘
                                       ↓
        corner_signal = common_mode(thrust%) + differential   (clamped [0, 15])
```

- **Two PIDs, not four**: the gimbal gives global pitch/roll, not per-corner level. Four independent per-corner PIDs can't be formed without projecting the global error onto corners — which is exactly what the coupling matrix does. So two axis PIDs + a decoupling map is the clean form.
- **Why decouple**: corner thrusters are *coupled* (each affects both pitch and roll). The coupling matrix (solved in calibration) converts `(pitch_cmd, roll_cmd)` → 4 corner differentials so a pitch correction produces pure pitch and a roll correction produces pure roll, even with uneven thruster authority.

### Gimbal → angle mapping

The 4 gimbal relays provide **raw 0–15 signals** (`0` = no error, `15` = max error). Each relay is calibrated to an (axis, sign). For each axis, the signed error is the difference of its two opposite relays:

- `pitch_error = sign_f · front_relay + sign_b · back_relay` → range `[-15, +15]`
- `roll_error  = sign_l · left_relay  + sign_r · right_relay` → range `[-15, +15]`

With the finalized conventions (positive pitch = nose-up, positive roll = left-down), the resolved signs are `sign_f = +1`, `sign_b = −1`, `sign_l = +1`, `sign_r = −1`, so `pitch_error = front − back` and `roll_error = left − right`. At level, both relays on an axis read `0`, so the error is `0`. The PID works directly in these signal units (no degree conversion); gains are tuned in these units.

### PID form

Position form, error in signal units, output in differential signal units:

`u = Kp·e + Ki·∫e·dt + Kd·de/dt`

- **Separate gains per axis** (`Kp_pitch`, `Ki_pitch`, `Kd_pitch`, `Kp_roll`, ...) since pitch/roll authority can differ on a rectangular craft.
- **Gains are tunable** in the Settings screen and **persisted in a settings file**, with code defaults.
- **Derivative-on-measurement** (not on error) with a first-order low-pass filter to tame analog noise. Setpoint is fixed at `0` so derivative kick is minor, but D-on-measurement is the safer default.
- **Anti-windup**: clamp the integral accumulator to a max, and **reset it on takeoff handoff and on ground contact** (the craft can't respond on the ground, so the integral would otherwise wind up).

### Setpoint & deadzone

- Setpoint is fixed at `0` for both axes in v1.
- **Deadzone** (per-axis, in signal units): error magnitude below which no correction is applied. This tolerates the minor tilt caused by horizontal thrust.

### Coupling matrix → corner differentials

The 2-command → 4-thruster mapping is underdetermined. Use **axial-mode decomposition**:

- pitch mode: `[+a, +a, −a, −a]` (FL, FR, BL, BR)
- roll mode:  `[+b, −b, +b, −b]`

Scale `a`/`b` using the measured gains from calibration so each mode's real-world authority is normalized. (Alternative: least-squares pseudo-inverse of the 2×4 coupling matrix — automatic but less predictable than explicit axial modes. Axial modes chosen.)

### Sign conventions

**Coordinate conventions (finalized):**
- **Positive pitch = nose-up** (front higher). Read from the front gimbal sensor.
- **Positive roll = left side down** (right side up). Read from the left gimbal sensor.
- **Front = nose**; corners are FL, FR, BL, BR relative to the nose.

**Signal convention:** `0 = max thrust`, `15 = no thrust` — *increasing* corner thrust = *decreasing* signal.

**Correction direction:** the PID corrects by **cutting thrust on the high side** (the side that is too high). So:
- Positive pitch (nose-up, front high) → cut front corners (FL, FR) → signal increases.
- Positive roll (left-down, right high) → cut right corners (FR, BR) → signal increases.

| Axis | Positive error | High side | Corners cut (thrust reduced) | Signal delta |
|------|----------------|-----------|------------------------------|--------------|
| pitch | nose-up | front | FL, FR | + |
| roll | left-down | right | FR, BR | + |

**Derived from calibration (Option B):** this table is **documentation + validation only**, not a runtime lookup. The runtime uses the signed coupling matrix solved during calibration directly — it already encodes which corner does what and with what sign. The table documents the *expected* behavior so validation can cross-check that a relay isn't inverted (a relay whose measured sign disagrees with this table is flagged).

### Saturation & enforcement

- `corner_signal = common_mode(thrust%) + differential`, clamped to `[0, 15]`.
- **`THRUST_BUFFER`** caps the common-mode so differential always has headroom (see Thrust Control).
- **`MIN_VERTICAL_THRUST` removed**: users have full control of thrust power for easy tweaking. There is no code floor on the common-mode — the user's thrust% slider is the only common-mode limit, and the per-corner `[0, 15]` clamp is the only hard bound.

### Loop guards / failsafe hook

- Each cycle: verify gimbal readings are fresh and non-silent (reuse calibration fail-closed logic); if invalid, kill thrust rather than correct against garbage.
- The PID has an **armed state** — it does not run during takeoff.
- **Integrator reset** on the takeoff→PID handoff.

## State Machine

The craft runs a small state machine that governs when the PID is armed and how thrust is commanded. States: `GROUND`, `TAKEOFF`, `HOVER`, `LANDING`, `FAILSAFE`.

```
GROUND → TAKEOFF → HOVER → LANDING → GROUND
   ↑        │        │        │
   └────────┴────────┴────────┘   (FAILSAFE interrupts any state)
```

### States

- **`GROUND`**: idle. PID disarmed, thrust `0`. The craft is on the ground.
- **`TAKEOFF`**: smooth lift-off. PID disarmed (open-loop common-mode ramp). Thrust ramps from `0` up to the takeoff target at `RAMP_RATE`.
- **`HOVER`**: normal operation. PID armed. Thrust = `common_mode(thrust%) + differential`.
- **`LANDING`**: smooth descent. Thrust ramps down to `0` at `RAMP_RATE`. PID stays armed during descent to keep the craft level; disarms at touchdown.
- **`FAILSAFE`**: entered on any failsafe trigger. Thrust killed. Shows a UI indicator. Manual re-arm required to return to `GROUND`.

### Transitions

- **`GROUND → TAKEOFF`**: user presses the **Takeoff** button on the UI.
- **`TAKEOFF → HOVER`**: ramp completes → hold for a **settle period** (`SETTLE_TICKS`) → arm PID + reset integrator.
- **`HOVER → LANDING`**: user presses the **Land** button on the UI.
- **`LANDING → GROUND`**: thrust ramped to `0` + a **touchdown timer** (`TOUCHDOWN_TICKS`). No ground detection — landing completion is assumed from the ramp + timer.
- **Any → `FAILSAFE`**: any failsafe trigger (silent/stale gimbal, relay loss, watchdog). From `FAILSAFE`, a manual re-arm returns to `GROUND`.

### Takeoff target

- Takeoff targets the **current thrust% setting** (the slider value). Since the default thrust is `100%` (max), takeoff defaults to max thrust.
- If the user's thrust% is set lower, takeoff ramps to that value instead.
- If the user presses **Takeoff** while thrust% is `0`, show a **non-blocking warning** (the craft will not lift) but allow it — the user is free to do this.

### Ramp rate (shared)

- `RAMP_RATE` is a **user-facing setting** (in the Settings screen, persisted in the settings file) controlling the rate of thrust change in signal levels per tick.
- It is **shared** across takeoff, landing, and mid-flight slider changes, so all thrust changes are smoothed consistently with one knob to tune.
- *(Naming note: originally proposed as `TAKEOFF_RAMP_RATE`; since it is shared across takeoff/landing/slider, a single `RAMP_RATE` name is used.)*

### Slider changes

- Mid-flight thrust% slider changes are **rate-limited** using the same `RAMP_RATE`, so dragging the slider doesn't cause a thrust jump/bounce.

### Concurrency

- The control loop, state machine, and Basalt UI run together via `parallel.waitForAny()`.
- The state machine is shared state read each control cycle; the UI triggers transitions (button presses) and the control loop executes the per-state thrust logic.

### Failsafe

- On failsafe, transition to `FAILSAFE` (a distinct state with a UI indicator) rather than silently dropping to `GROUND`, so the operator sees there was a problem.
- Thrust is killed; the craft falls. Manual re-arm returns to `GROUND`.

## Failsafe & Watchdog

The failsafe system detects faults and kills thrust before the PID can correct against garbage. On any trigger, the craft transitions to the `FAILSAFE` state (see State Machine).

### Triggers

All five triggers trip the failsafe:

- **Silent gimbal**: a gimbal relay reads a constant value (e.g., `0`) across `SILENT_TICKS` consecutive cycles (no change). A silent input reads as constant `0`, and the PID would correct against garbage and could slam thrust.
- **Stale gimbal**: no fresh reading within `STALE_TICKS` (the sensor stopped updating). Tracked via a timestamp on the last valid read.
- **Relay loss**: `peripheral.getType(side)` no longer returns `redstone_relay`, or `peripheral.find` fails at runtime.
- **Invalid reading**: NaN or out-of-range value from a gimbal relay.
- **Watchdog timeout**: the control loop stalled (see Watchdog below).

### Watchdog

- A **watchdog is in scope**: a hung/crashed Lua script must not leave thrusters at max.
- The control loop increments a **heartbeat counter** each cycle. A separate watchdog task (one of the `parallel.waitForAny` branches) checks that the counter advances; if it hasn't within `WATCHDOG_TIMEOUT_TICKS`, it trips the failsafe.
- `WATCHDOG_TIMEOUT_TICKS` is a tunable constant, set comfortably above the control period.

### Failsafe action

- **Kill thrust** = set all 4 thruster relays to `15` (the defined "no thrust" state), consistent with the signal convention.
- Gimbal relays are inputs and are **not** commanded.

### Re-arm / recovery

- The operator re-arms via a **Re-arm** button in the `FAILSAFE` state → `GROUND`.
- **Re-arm re-validates the fault first**: if the triggering condition is still present (e.g., the gimbal is still silent), the craft stays in `FAILSAFE` and shows the reason rather than re-tripping immediately.
- **Manual only** — no auto-recover.

### Failsafe during calibration

- Failsafe is **suspended only for the calibration session** (calibration runs open-loop and must be able to command thrusters directly).
- It is **re-enabled on calibration exit — on both the happy path and the error/cleanup path** — so a crash during calibration never leaves failsafe permanently off. The Config Lifecycle cleanup path re-enables failsafe as part of its restore logic.

### Reporting

- The `FAILSAFE` state shows a UI indicator with the **specific fault reason** (which relay, which trigger), so the operator knows what to fix before re-arming.

### Constants

- `SILENT_TICKS`, `STALE_TICKS`, `WATCHDOG_TIMEOUT_TICKS` are tunable constants (values to be tuned during testing).

## UI Structure

Built with Basalt 2.5. The UI runs alongside the control loop and state machine via `parallel.waitForAny()`, reading/writing shared state. The UI is **read-only on the state machine** — it cannot change state directly, only trigger transitions via buttons.

### Display target

- Primary target: a **CC: Tweaked advanced computer screen**.
- The UI can **mirror to a connected monitor** and **adapt to the monitor size**. Keep the adaptation simple — a basic layout that scales to the available width/height rather than per-size layouts.

### Screens & navigation

Four top-level screens plus a failsafe overlay:

- **Home / Control** — main operating screen
- **Settings** — tunables
- **Info** — relay mapping, calibration version, config status
- **Calibration** — a modal wizard that takes over the screen

Navigation uses **tabs** at the top (Home / Settings / Info). Calibration is a **modal** entered from Home.

### Home / Control screen

Top to bottom:

1. **State indicator** — a text label with a corresponding color per state:
   - `GROUND` (gray), `TAKEOFF` (yellow), `HOVER` (green), `LANDING` (orange), `FAILSAFE` (red)
2. **Thrust slider** — 0–100%, rate-limited via `RAMP_RATE`.
3. **Takeoff / Land buttons** — gated by state: **Takeoff** enabled only in `GROUND`, **Land** enabled only in `HOVER`. A **Calibrate** button (a symbol, e.g. ⚙) is also on this screen.
4. **Per-corner thrust display** — labeled FL / FR / BL / BR, showing the **commanded** thrust % for each corner (the `corner_signal` mapped back to a percentage). There is no thruster feedback, so this is commanded, not measured.

### Settings screen

- **PID gains**: `Kp`, `Ki`, `Kd` per axis (pitch/roll).
- **`RAMP_RATE`**: shared ramp rate.
- **Deadzone**: per-axis.
- Edited via number inputs/sliders and **persisted to the settings file** on change.

### Calibration

- Entered via the **Calibrate** button (symbol) on the Home screen, or a `calibrate` command.
- It is a **modal** that **suspends the control loop** (open-loop, failsafe suspended) while active, then **restores both on exit** (happy path and error/cleanup path).

### FAILSAFE overlay

- Rendered as a **full-screen overlay** showing the state, the **fault reason**, and a **Re-arm** button.

### Info screen

- Relay → role mapping (from `calibration.cfg`).
- Calibration schema `version`.
- Config status (valid / restored from backup / missing).

### State sharing

- The UI and control loop share state (current state, thrust%, gains) via `parallel.waitForAny()`.
- The UI is **read-only** on the state machine — it triggers transitions (Takeoff/Land/Re-arm) via buttons but does not mutate state directly.

## Config & Persistence

Two files persist state, both serialized with `textutils.serialize` (CC: Tweaked's standard Lua table serialization — parseable and human-readable).

### `calibration.cfg`

Stores the relay mapping and solved coupling data. Contents:

- `version` — schema version (validated on load).
- `thrusters` — relay name → corner (FL/FR/BL/BR). No side is stored: thrusters are written on all six sides.
- `gimbals` — relay name → { side, axis, sign } (the resolved listening side per relay).
- `coupling` — the solved coupling matrix (each corner → pitch gain, roll gain).
- `expected` — measured peak response per axis (pitch, roll), used to seed the validation noise floor.

Backup/recovery lifecycle is specified in "Config Lifecycle" (backup to `calibration.cfg.bak`, restore on corruption, fail closed on invalid).

### `settings.cfg`

Stores user-facing tunables (separate from calibration so re-calibrating doesn't wipe settings):

- PID gains (`Kp`, `Ki`, `Kd` per axis).
- `RAMP_RATE`.
- Deadzone (per-axis).
- Default thrust%.

Also carries a `version`. Code defaults are the fallback; persisted values override them. On load, fail closed if unparseable or invalid (never silently default).

## Startup Sequence

On boot:

1. **Load `settings.cfg`** — apply persisted tunables (fall back to code defaults).
2. **Load `calibration.cfg`** and validate:
   - **First boot** (file missing): expected — prompt calibration.
   - **Later boot** (missing/corrupt): unexpected — fail closed and prompt re-calibration (offer restore from `.bak` if valid).
3. **If calibration is valid**: show the Home screen in `GROUND` state, ready for takeoff.
4. **If calibration is invalid/missing**: enter the Calibration modal; on successful completion, save and proceed to Home/`GROUND`.
5. The craft starts on the ground in `GROUND` state; the operator presses **Takeoff** to begin.

## Gaps

- **Steady-state vertical bobbing**: with no altitude sensor, the craft cannot actively damp vertical oscillation in hover — some bobbing is inherent to open-loop thrust control. The takeoff ramp prevents *ground-bounce at liftoff* but not steady-state bobbing.
- **Horizontal thrust**: a separate system, out of scope for this script.

## Process

**Initial Redstone Relay Calibration**
This will be used to identify the position of each Redstone Relay

### Calibration Entry
- On first boot (or via a calibrate command), before any control logic runs, prompt the user to choose the calibration type:
  - **Automatic** — see "Automatic Flow" below
  - **Manual** — see "Manual Flow" below
- Selection defaults to Automatic.
- **Relay count validation**: before any flow runs, enumerate relays via `peripheral.find("redstone_relay")` and require exactly 8. If the count differs, fail fast and report which sides are present/absent (roles aren't known yet, so don't guess thruster vs. gimbal). More than 8 is also a fault.
- **Role assignment is manual (pulse-and-watch)**: relay names are NOT used to decide thruster vs. gimbal. Each relay is pulsed on the ground and the operator reports which corner moved (a thruster) or that nothing moved (a gimbal). See "Role & Corner Mapping" below.
- Running during calibration enforces:
  - **Open loop**: PID disabled so thrusters are commanded directly and it cannot counteract the test impulses.
  - **Failsafe suspended**: only for the calibration session, and restored afterward.
- A re-calibration command (`calibrate --reset`) clears `calibration.cfg` and re-runs the entry prompt.

### Config Lifecycle
Handles `calibration.cfg` creation, backup, and recovery so a botched calibration is never permanent.

- **Validation (schema version)**: `calibration.cfg` carries a schema `version`. On load, fail if the file is missing, unparseable, contains an unsupported `version`, or contains invalid/missing values (e.g., a relay name that isn't a valid corner/side, a non-numeric gain, a missing listening side). Never silently default.
- **First boot**: a missing file is expected — prompt calibration.
- **Later boot**: a missing/corrupt file is unexpected — fail closed and prompt re-calibration.
- **Backup before save**: before overwriting `calibration.cfg`, write the current file to `calibration.cfg.bak`. If the main file is corrupt but `.bak` is valid, offer to restore from backup instead of forcing a full re-calibration.
- **Failsafe auto-restore on error/exit**: if calibration crashes mid-session, restore the previous settings via a cleanup path (not just the happy path):
  - If a previous valid `calibration.cfg` or `.bak` exists → restore it.
  - If none exists → prompt to restart calibration.

### Shared Calibration Primitives
Both flows build on the same two primitives, so automatic and manual stay on one code path.

- **Thruster Pulse** (the button): applies a short, gradual thrust pulse to a chosen thruster (corner) to create a tilt impulse. Calibration runs **on the ground**, so a pulse ramps the signal from `15` (no thrust) down to a thrust value (`CALIBRATION_PULSE_SIGNAL`), holds for ~N ticks, then ramps back to `15`. Because the live output face is unknown and each relay's faces are relative to its own orientation, the signal is written to **all six sides** of the relay (the wired face receives it; the others are harmless). This same primitive powers role/corner mapping, gimbal calibration, and the validation contact-check.
- **Role & Corner Mapping** (the human step, both flows): first prompts the operator to **turn the engine on**, then pulses each of the 8 relays on the ground and asks "which corner moved?" (FL/FR/BL/BR) or "None" (a gimbal). A relay that moves a corner is a thruster and is assigned that corner; a relay that moves nothing is a gimbal. The operator can **re-pulse** any relay before answering (e.g. if they missed the movement). The pass repeats until an even 4-thruster / 4-gimbal split with 4 distinct corners is achieved.
- **Gimbal Mapper** (shared routine): maps all gimbal relays from a series of tilt impulses. It takes a **tilt source** — the only thing that differs between flows — and runs the same steps:
  1. **Input side lock-on**: build the candidate side list from every side whose peripheral type is `redstone_relay` (include Up/Down as well as horizontal, so future design changes don't break calibration). As the tilts run, read `redstone.getAnalogInput(side)` on every candidate side; whichever side's signal changes is that relay's listening side. This side is stored, so runtime reads are always on the known side — no re-scanning.
  2. **Sample per corner**: for each corner (FL/FR/BL/BR), apply a bounded thrust impulse for N ticks and record the peak signed pitch/roll response from the gimbal sensor. Because each corner thruster sits on two axes, every fire produces a **coupled** (pitch, roll) response.
  3. **Solve**: least squares builds a **coupling matrix** — each corner maps to a (pitch gain, roll gain) pair. 4 corner fires × (pitch, roll) = 8 measurements → 8 unknowns, fully determined. The solver derives the gains and verifies signs.
  4. If an axis yields a negligible or inverted response, flag it for re-run or manual fallback rather than silently accepting it.
  5. **Automatic→manual gimbal fallback**: if the automatic gimbal solve flags a negligible/inverted axis, re-run the **entire Gimbal Mapper** in manual mode (button-driven tilt source) rather than re-running the whole flow or partially re-sampling. A suspect axis means the coupling matrix as a whole is unreliable, so re-solve from a fresh manual pass.
- **Mapping Review** (shared confirmation screen): shows the full mapping as two tables — one for the thruster→corner mapping, one for the gimbal relay mapping. Both flows end with this screen; only the interaction mode differs:
  - **Manual** — **confirm**: the user must review and confirm the assignments before saving.
  - **Automatic** — **review**: the tables are pre-filled with the solved mapping and auto-accepted; the user only edits to override a flagged relay.

  *(Relay names are arbitrary — roles are assigned by pulse-and-watch, not by name. The tables below are illustrative.)*

  **Thrusters**

  | Relay | Corner |
  |-------|--------|
  | thruster_1 | FL |
  | thruster_2 | FR |
  | thruster_3 | BL |
  | thruster_4 | BR |

  **Gimbal relays**

  | Relay | Side | Axis | Sign |
  |-------|------|------|------|
  | gimbal_1 | north | pitch | + |
  | gimbal_2 | east | roll | − |

### Automatic Flow
Thrusters are calibrated first, then the gimbal relays are mapped automatically from the observed tilt response.

1. Enumerate every connected relay via `peripheral.find("redstone_relay")`.
2. **Role & corner mapping** (the only human step): for each of the 8 relays, pulse it on the ground and ask the user "which corner moved?" (FL/FR/BL/BR) or "None" (a gimbal) via keybound options. Confirm the corner for all 4 thrusters; the 4 gimbals are the relays that moved nothing. The pass repeats until an even 4/4 split with 4 distinct corners is achieved.
3. **Gimbal auto-calibration** (no user input): run the shared **Gimbal Mapper** with an **automatic tilt source** — the program fires each corner's impulse in sequence via the Thruster Pulse primitive, with no user input. Disable PID and run the craft open-loop so it cannot counteract the test impulses.
4. **Mapping review** (auto-accepted): show the shared **Mapping Review** tables pre-filled with the solved mapping. Auto-accept unless the user edits to override a flagged relay.
5. Save the resulting name→role mapping to `calibration.cfg` (including sign convention, the resolved listening side per gimbal relay, and a schema `version`), so it only runs once per build.

### Manual Flow
For when you already know the layout or the automatic flow fails. This is the automatic flow with each tilt impulse triggered manually via the **Thruster Pulse** button instead of fired on a script — the two flows share one code path with a single input-mode switch, so the output format/`version` is identical.

1. Enumerate every connected relay via `peripheral.find("redstone_relay")`.
2. **Role & corner mapping** (the only truly manual step): for each of the 8 relays, pulse it on the ground and ask the user "which corner moved?" (FL/FR/BL/BR) or "None" (a gimbal) via keybound options. Confirm the corner for all 4 thrusters; the 4 gimbals are the relays that moved nothing. The pass repeats until an even 4/4 split with 4 distinct corners is achieved.
3. **Gimbal mapping** (guided, button-driven): run the shared **Gimbal Mapper** with a **manual tilt source** — the user drives each impulse via the **Thruster Pulse** button:
   - Select a corner (FL/FR/BL/BR) and press **Fire**; the program applies thrust to that corner for ~N ticks and records the peak signed response on every candidate side (`redstone_relay` peripheral type, including Up/Down).
   - Repeat for all 4 corners — a fixed 4 impulses regardless of relay count, since all gimbal relays read the same physical sensor and respond to every tilt simultaneously.
   - The mapper auto-detects each relay's listening side and solves axis/sign with the same least-squares solver.
4. **Mapping confirmation** (required): show the shared **Mapping Review** tables — one for the thruster→corner mapping, one for the gimbal relay mapping. The user must confirm or correct the assignments before saving.
5. Save the resulting name→role mapping to `calibration.cfg` (same format/`version` as automatic).

### Validation Step (Shared)
Both flows end with a common validation pass to confirm the mapping before control logic enables.

- **Startup contact-check**: pulse each thruster and confirm it responds, so a dead/stuck relay is detected (a stuck-off corner is recoverable; a stuck-on corner is not).
- **Expected response magnitude**: store the measured peak response per axis (pitch, roll) in `calibration.cfg`. Seed the validation noise floor and confirmed-signed checks from it as a **fraction of the stored magnitude** — recommend **15%** (a response must exceed 15% of the expected magnitude to count as real). Per-axis, since pitch and roll authority can differ on a rectangular craft. Make it a tunable constant (`NOISE_FLOOR_FRACTION`).
- **Confirmed-signed response**: for each gimbal axis, verify a nonzero, correctly-signed response above a noise floor. Re-prompt or warn if not verified.
- **Pair-fire validation**: after the coupling matrix is solved, fire thruster **pairs** to confirm clean single-axis tilts — FL+FR for pure pitch, FL+BL for pure roll. Verify the front-pair vs back-pair difference has pitch authority and the left-pair vs right-pair difference has roll authority, with correct signs. This confirms the solved coupling rather than trusting it blindly.
- **Silent-input diagnosis**: if a candidate side (or locked-on side) never changes across all controlled tilts, don't assume a wiring fault immediately — retry with stronger/more tilts first, since a craft unable to tilt freely (e.g. resting on the ground) can produce a false "no response." If still silent, distinguish **relay absent** (`peripheral.getType(side)` no longer returns `redstone_relay`) from **relay present but silent** (gimbal-to-relay wiring, stuck sensor, or it is actually a thruster relay misidentified as input). Fail closed on that relay, report exactly which side/relay failed and what was tried, and offer: re-run calibration, drop to manual flow for that relay, or fix wiring and re-check. No "mark-and-continue-with-warning" — a silent input reads as constant 0 and the PID would correct against garbage and could slam thrust.
- **Loss-of-signal check**: distinguish "relay present but 0 signal" from "relay disconnected"; on `peripheral.find` failure at runtime, fail closed (kill thrust). This shares the same fail-closed response as the silent-input diagnosis, so calibration and live operation respond identically.
- On passing validation, the mapping is enabled and control logic may hand off to the PID. On failure, calibration is re-run or the user is prompted to resolve the issue.

## Input

Pitch
- X angle
  - Positive: Nose-up (front higher) — read from the front gimbal sensor
  - Negative: Nose-down (rear higher) — read from the rear gimbal sensor

Roll
- Y angle
  - Positive: Left side down — read from the left gimbal sensor
  - Negative: Right side down — read from the right gimbal sensor

## Output

Thrusters in all 4 corners. Front Left, Front Right, Back Left, Back Right.
Vertical thrust only.

## Settings

- **Thrust %**: user-facing slider (0–100%) controlling the common-mode thrust offset (see Thrust Control). `100%` = max thrust, `0%` = no thrust.
- **PID gains**: `Kp`, `Ki`, `Kd` per axis (pitch/roll), tunable in the Settings screen and persisted in a settings file, with code defaults.
- **Deadzone**: per-axis error magnitude (in signal units) below which no correction is applied. Tolerates the minor tilt usually caused by horizontal thrust.

## Constants

Consolidated list of all named constants, grouped by whether they are user-facing (persisted in `settings.cfg`) or code-only. Values marked **TBD** are tuning values to be set during testing.

### User-facing (in `settings.cfg`)

| Constant | Purpose | Default |
|----------|---------|---------|
| `Kp` / `Ki` / `Kd` (per axis) | PID gains | code defaults |
| `RAMP_RATE` | shared ramp rate (signal levels per tick) | TBD |
| Deadzone (per axis) | error magnitude below which no correction is applied | TBD |
| Default thrust% | initial slider value | 100% |

### Code-only (not user-facing)

| Constant | Purpose | Default |
|----------|---------|---------|
| `THRUST_BUFFER` | reserves differential headroom at low thrust | 3 |
| `SETTLE_TICKS` | settle period after takeoff ramp before arming PID | TBD |
| `TOUCHDOWN_TICKS` | timer after landing ramp before returning to `GROUND` | TBD |
| `SILENT_TICKS` | silent-gimbal threshold (consecutive cycles of no change) | TBD |
| `STALE_TICKS` | stale-gimbal threshold (no fresh read) | TBD |
| `WATCHDOG_TIMEOUT_TICKS` | watchdog timeout | TBD |
| `NOISE_FLOOR_FRACTION` | validation noise floor as a fraction of expected magnitude | 0.15 |
| `IMPULSE_TICKS` | calibration thrust-pulse hold duration (the `N` ticks) | TBD |
| `CALIBRATION_PULSE_SIGNAL` | signal reached during a calibration thrust pulse (0 = max thrust) | 5 |
| `THRUSTER_SIDES` | sides written on every thruster relay (covers any relay orientation) | all six (top/bottom/front/back/left/right) |