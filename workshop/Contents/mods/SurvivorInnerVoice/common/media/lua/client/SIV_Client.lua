if isServer() then return end

require "SIV_Catalog"
require "SIV_Scheduler"

local runtimeByPlayer = setmetatable({}, { __mode = "k" })
local moodleByName

local INTERVAL_BY_FREQUENCY = {
    [1] = 60,
    [2] = 35,
    [3] = 20,
    [4] = 12,
    [5] = 6,
}

local function sandboxNumber(name, fallback)
    local page = SandboxVars and SandboxVars.SurvivorInnerVoice
    return tonumber(page and page[name]) or fallback
end

local function schedulerConfig()
    local frequency = math.floor(sandboxNumber("Frequency", 3))
    local interval = INTERVAL_BY_FREQUENCY[frequency] or INTERVAL_BY_FREQUENCY[3]
    return {
        startupDelay = interval,
        minimumInterval = 3,
        globalCooldown = interval,
        stateCooldown = interval * 9,
        reminderInterval = interval * 30,
        recentHistory = 8,
        jitterRatio = 0.3,
        queueEveryChange = frequency == 5,
    }
end

local function getRuntime(player)
    local runtime = runtimeByPlayer[player]
    if not runtime then
        runtime = { lastScan = 0, scheduler = SIV.Scheduler.new(schedulerConfig()) }
        runtimeByPlayer[player] = runtime
    end
    return runtime
end

local function buildMoodleLookup()
    local lookup = {}
    if not MoodleType then return lookup end
    for _, definition in ipairs(SIV.STATES) do
        if definition.moodle then
            lookup[definition.moodle] = MoodleType[definition.moodle]
        end
    end
    return lookup
end

local function statSeverity(player, statName)
    local stat = CharacterStat and CharacterStat[statName]
    local stats = player and player:getStats()
    if not stat or not stats then return 0 end
    local value = stats:get(stat)
    local minimum = stat:getMinimumValue()
    local maximum = stat:getMaximumValue()
    return SIV.severityFromRange(value, minimum, maximum, false)
end

local function bodyFlagSeverity(player, flagName)
    local body = player and player:getBodyDamage()
    local getter = body and body[flagName]
    return getter and getter(body) and 4 or 0
end

local function snapshotFor(player)
    moodleByName = moodleByName or buildMoodleLookup()
    local snapshot = {}
    local moodles = player and player:getMoodles()
    if not moodles then return snapshot end
    for _, definition in ipairs(SIV.STATES) do
        if definition.moodle then
            local moodle = moodleByName[definition.moodle]
            snapshot[definition.id] = moodle and moodles:getMoodleLevel(moodle) or 0
        elseif definition.stat then
            snapshot[definition.id] = statSeverity(player, definition.stat)
        elseif definition.bodyFlag then
            snapshot[definition.id] = bodyFlagSeverity(player, definition.bodyFlag)
        else
            snapshot[definition.id] = 0
        end
    end
    return snapshot
end

local function colorComponent(color, field, getter, fallback)
    local value = color and tonumber(color[field])
    if value then return value end
    if color and color[getter] then
        local ok, result = pcall(color[getter], color)
        if ok and tonumber(result) then return tonumber(result) end
    end
    return fallback
end

local function vanillaHighlight(positive)
    local core = getCore and getCore() or nil
    local color
    if core then
        color = positive and core:getGoodHighlitedColor() or core:getBadHighlitedColor()
    end
    return {
        r = colorComponent(color, "r", "getR", positive and 0 or 1),
        g = colorComponent(color, "g", "getG", positive and 1 or 0),
        b = colorComponent(color, "b", "getB", 0),
    }
end

local function eventColor(stateId, direction, toLevel)
    local positive = SIV.eventUsesPositiveColor(stateId, direction, toLevel)
    local colorLevel = math.max(1, tonumber(toLevel) or 1)
    return SIV.interpolateVanillaColor(colorLevel, vanillaHighlight(positive))
end

local function showThought(player, event)
    local text = getText(event.key)
    if not text or text == event.key then return end
    local red, green, blue = eventColor(event.stateId, event.direction, event.toLevel)
    player:addLineChatElement("（" .. text .. "）", red, green, blue,
        UIFont.Medium, 1.5, "default", true, true, true, true, true, true)
end

local function showSpoken(player, key, stateId, direction, toLevel)
    local text = getText(key)
    if not text or text == key then return end
    local red, green, blue = eventColor(stateId, direction, toLevel)
    player:addLineChatElement(text, red, green, blue,
        UIFont.Medium, 1.5, "default", true, true, true, true, true, true)
end

local function onPlayerUpdate(player)
    if not player or (player.isDead and player:isDead()) then return end
    local runtime = getRuntime(player)
    local now = getTimestamp()
    if now - runtime.lastScan < 1 then return end
    runtime.lastScan = now

    local event = SIV.Scheduler.scan(runtime.scheduler, snapshotFor(player), now)
    if event then showThought(player, event) end
end

local function onServerCommand(module, command, args)
    if module ~= SIV.MODULE or command ~= "spoken" or not SIV.validSemanticEvent(args) then return end
    local onlineId = tonumber(args.onlineId)
    local speaker = onlineId and getPlayerByOnlineID(onlineId) or nil
    local key = SIV.phraseKey(args.stateId, args.direction, args.phraseLevel, args.phraseIndex)
    if speaker and key then showSpoken(speaker, key, args.stateId, args.direction, args.toLevel) end
end

local function onCreatePlayer(_, player)
    if player then runtimeByPlayer[player] = nil end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnServerCommand.Add(onServerCommand)

print("[SurvivorInnerVoice] Client " .. SIV.VERSION)
