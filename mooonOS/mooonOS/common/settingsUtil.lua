-- settingsUtil
-- Created by: ChefMooon

-- This program contains all functions related to program settings
--PROGRAM TODO--

local settingsUtil = {}

function settingsUtil.define(programName, settingID, defaultValue)
    local setting = programName .. "." .. settingID
    if type(defaultValue) == "string" then
        settings.define(setting, {
            description = programName .. " - " .. settingID,
            default = defaultValue
        })
    elseif type(defaultValue) == "number" then
        settings.define(setting, {
            description = programName .. " - " .. settingID,
            default = defaultValue,
            type = number
        })
    end
    return setting
end

-- todo: this is unused and wonky
function settingsUtil.defineAll(settingsList)
    local settingIDs = {}
    for _, setting in ipairs(settingsList) do
        local newSettingID = define(setting[1], setting[2], setting[3])
        table.insert(settingIDs, newSettingID)
    end
    return settingIDs
end

function settingsUtil.set(id, value)
    settings.set(id, value)
    settings.save()
end

function settingsUtil.get(id)
    return settings.get(id)
end

function settingsUtil.getNumBoolean(id)
    local value = settings.get(id)
    if type(value) == "number" then
        if value == 1 then
            return true
        elseif value == 0 then
            return false
        end
    end
    return nil
end

return settingsUtil