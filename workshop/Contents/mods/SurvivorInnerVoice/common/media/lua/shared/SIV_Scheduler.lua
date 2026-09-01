require "SIV_Catalog"

SIV.Scheduler = SIV.Scheduler or {}

local DEFAULTS = {
    startupDelay = 0,
    minimumInterval = 3,
    globalCooldown = 20,
    stateCooldown = 180,
    reminderInterval = 600,
    recentHistory = 8,
    jitterRatio = 0.3,
    queueEveryChange = false,
}

local function numberOr(value, fallback, minimum)
    value = tonumber(value)
    if not value then return fallback end
    return math.max(minimum or 0, value)
end

local function makeConfig(config)
    config = config or {}
    return {
        startupDelay = numberOr(config.startupDelay, DEFAULTS.startupDelay, 0),
        minimumInterval = numberOr(config.minimumInterval, DEFAULTS.minimumInterval, 1),
        globalCooldown = numberOr(config.globalCooldown, DEFAULTS.globalCooldown, 1),
        stateCooldown = numberOr(config.stateCooldown, DEFAULTS.stateCooldown, 1),
        reminderInterval = numberOr(config.reminderInterval, DEFAULTS.reminderInterval, 10),
        recentHistory = math.floor(numberOr(config.recentHistory, DEFAULTS.recentHistory, 1)),
        jitterRatio = math.min(0.9, numberOr(config.jitterRatio, DEFAULTS.jitterRatio, 0)),
        queueEveryChange = config.queueEveryChange == true,
    }
end

function SIV.Scheduler.new(config, randomIndex, randomUnit)
    return {
        config = makeConfig(config),
        randomIndex = randomIndex,
        randomUnit = randomUnit,
        initialized = false,
        levels = {},
        pending = {},
        nextSequence = 0,
        lastGlobal = -math.huge,
        lastByState = {},
        lastReminder = {},
        startupReadyAt = -math.huge,
        nextGlobalAt = -math.huge,
        nextByState = {},
        nextReminderAt = {},
        history = {},
        nextUseSequence = 0,
        lastUsedByKey = {},
    }
end

local function randomFraction(state)
    local value
    if state.randomUnit then
        value = tonumber(state.randomUnit())
    elseif ZombRand then
        value = ZombRand(10001) / 10000
    end
    return math.max(0, math.min(1, value or 0.5))
end

local function jitteredDelay(state, base, minimum)
    local ratio = state.config.jitterRatio
    local multiplier = 1 - ratio + randomFraction(state) * ratio * 2
    return math.max(minimum or 0, base * multiplier)
end

local function historyContains(history, key)
    for _, recent in ipairs(history) do
        if recent == key then return true end
    end
    return false
end

local function choosePhrase(state, stateId, direction, phraseLevel)
    local available = {}
    local oldestUse = math.huge
    for phraseIndex = 1, SIV.PHRASES_PER_LEVEL do
        local key = SIV.phraseKey(stateId, direction, phraseLevel, phraseIndex)
        if not historyContains(state.history, key) then
            local usedAt = state.lastUsedByKey[key] or 0
            if usedAt < oldestUse then
                available = { phraseIndex }
                oldestUse = usedAt
            elseif usedAt == oldestUse then
                available[#available + 1] = phraseIndex
            end
        end
    end

    local phraseIndex
    if #available > 0 then
        local selected = 1
        if state.randomIndex then
            selected = math.floor(tonumber(state.randomIndex(#available)) or 1)
            selected = math.max(1, math.min(#available, selected))
        elseif ZombRand then
            selected = ZombRand(#available) + 1
        end
        phraseIndex = available[selected]
    else
        local oldestCandidate = math.huge
        for candidate = 1, SIV.PHRASES_PER_LEVEL do
            local key = SIV.phraseKey(stateId, direction, phraseLevel, candidate)
            local usedAt = state.lastUsedByKey[key] or 0
            if usedAt < oldestCandidate then
                oldestCandidate = usedAt
                phraseIndex = candidate
            end
        end
    end
    return phraseIndex
end

local function remember(state, key)
    state.nextUseSequence = state.nextUseSequence + 1
    state.lastUsedByKey[key] = state.nextUseSequence
    state.history[#state.history + 1] = key
    while #state.history > state.config.recentHistory do
        table.remove(state.history, 1)
    end
end

local function removePendingForState(state, stateId)
    for index = #state.pending, 1, -1 do
        if state.pending[index].stateId == stateId then
            table.remove(state.pending, index)
        end
    end
end

local function enqueue(state, definition, direction, fromLevel, toLevel, now, replace)
    if replace then removePendingForState(state, definition.id) end
    state.nextSequence = state.nextSequence + 1
    state.pending[#state.pending + 1] = {
        stateId = definition.id,
        direction = direction,
        reason = direction,
        fromLevel = fromLevel,
        toLevel = toLevel,
        level = toLevel,
        phraseLevel = direction == "fall" and fromLevel or toLevel,
        priority = definition.priority,
        createdAt = now,
        sequence = state.nextSequence,
    }
end

local function sortCandidates(candidates)
    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        if a.createdAt ~= b.createdAt then return a.createdAt < b.createdAt end
        return (a.sequence or math.huge) < (b.sequence or math.huge)
    end)
end

local function allowed(state, candidate, now)
    if now < state.startupReadyAt then return false end
    local sinceGlobal = now - state.lastGlobal
    if sinceGlobal < state.config.minimumInterval then return false end
    if candidate.reason == "rise" and candidate.toLevel == 4 then return true end
    if now < state.nextGlobalAt then return false end
    if candidate.reason == "rise" or candidate.reason == "fall" then return true end
    return now >= (state.nextByState[candidate.stateId] or -math.huge)
end

local function initialize(state, snapshot, now)
    local useStartupDelay = state.config.startupDelay > 0
    if useStartupDelay then
        state.startupReadyAt = now
            + jitteredDelay(state, state.config.startupDelay, state.config.minimumInterval)
        state.nextGlobalAt = state.startupReadyAt
    end

    for _, definition in ipairs(SIV.STATES) do
        local level = SIV.normalizeSeverity(definition.id, snapshot[definition.id])
        state.levels[definition.id] = level
        if useStartupDelay and level > 0 then
            enqueue(state, definition, "rise", 0, level, now, true)
        end
        if level >= 3 then
            state.lastReminder[definition.id] = now
            state.nextReminderAt[definition.id] = now
                + jitteredDelay(state, state.config.reminderInterval, 10)
        end
    end
    state.initialized = true
end

local function refreshDuringStartup(state, snapshot, now)
    for _, definition in ipairs(SIV.STATES) do
        local level = SIV.normalizeSeverity(definition.id, snapshot[definition.id])
        state.levels[definition.id] = level
        removePendingForState(state, definition.id)
        if level > 0 then enqueue(state, definition, "rise", 0, level, now, false) end
    end
end

function SIV.Scheduler.scan(state, snapshot, now)
    if type(state) ~= "table" or type(snapshot) ~= "table" then return nil end
    now = tonumber(now) or 0
    if not state.initialized then
        initialize(state, snapshot, now)
        return nil
    end

    if now < state.startupReadyAt then
        refreshDuringStartup(state, snapshot, now)
        return nil
    end

    local reminders = {}
    for _, definition in ipairs(SIV.STATES) do
        local stateId = definition.id
        local previous = state.levels[stateId] or 0
        local current = SIV.normalizeSeverity(stateId, snapshot[stateId])
        state.levels[stateId] = current

        if current ~= previous then
            local direction = current > previous and "rise" or "fall"
            enqueue(state, definition, direction, previous, current, now,
                not state.config.queueEveryChange)
        elseif current >= 3 and now >= (state.nextReminderAt[stateId] or math.huge) then
            reminders[#reminders + 1] = {
                stateId = stateId,
                direction = "rise",
                reason = "reminder",
                fromLevel = current,
                toLevel = current,
                level = current,
                phraseLevel = current,
                priority = definition.priority,
                createdAt = now,
            }
        end
    end

    local candidates = {}
    for _, candidate in ipairs(state.pending) do candidates[#candidates + 1] = candidate end
    for _, candidate in ipairs(reminders) do candidates[#candidates + 1] = candidate end
    if #candidates == 0 then return nil end
    sortCandidates(candidates)

    local selected
    for _, candidate in ipairs(candidates) do
        if allowed(state, candidate, now) then
            selected = candidate
            break
        end
    end
    if not selected then return nil end

    local phraseIndex = choosePhrase(state, selected.stateId, selected.direction, selected.phraseLevel)
    local key = SIV.phraseKey(selected.stateId, selected.direction, selected.phraseLevel, phraseIndex)
    if selected.sequence then
        for index = #state.pending, 1, -1 do
            if state.pending[index].sequence == selected.sequence then
                table.remove(state.pending, index)
                break
            end
        end
    end
    state.lastGlobal = now
    state.lastByState[selected.stateId] = now
    state.lastReminder[selected.stateId] = now
    state.nextGlobalAt = now + jitteredDelay(state, state.config.globalCooldown, state.config.minimumInterval)
    state.nextByState[selected.stateId] = now + jitteredDelay(state, state.config.stateCooldown, 1)
    state.nextReminderAt[selected.stateId] = now + jitteredDelay(state, state.config.reminderInterval, 10)
    remember(state, key)

    selected.phraseIndex = phraseIndex
    selected.key = key
    return selected
end
