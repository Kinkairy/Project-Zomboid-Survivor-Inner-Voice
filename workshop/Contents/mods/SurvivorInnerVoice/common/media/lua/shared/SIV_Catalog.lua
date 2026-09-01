SIV = SIV or {}

SIV.VERSION = "0.3.0"
SIV.MODULE = "SurvivorInnerVoice"
SIV.PHRASES_PER_LEVEL = 8

local ALL_LEVELS = { 1, 2, 3, 4 }

-- This ordered table is the sole authority for scheduling and protocol validation.
-- Formal moodles resolve rise slots 1-2 from the game's own title/description keys.
SIV.STATES = {
    { id = "on_fire",       bodyFlag = "IsOnFire", specialVanillaKey = "IGUI_StatsAndBody_IsOnFire", levels = { 4 }, polarity = "negative", priority = 150 },
    { id = "bleeding",      moodle = "BLEEDING",       translationName = "Bleeding",      levels = ALL_LEVELS, polarity = "negative", priority = 140 },
    { id = "injured",       moodle = "INJURED",        translationName = "Injured",       levels = ALL_LEVELS, polarity = "negative", priority = 135 },
    { id = "pain",          moodle = "PAIN",           translationName = "Pain",          levels = ALL_LEVELS, polarity = "negative", priority = 130 },
    { id = "sick",          moodle = "SICK",           translationName = "Sick",          levels = ALL_LEVELS, polarity = "negative", priority = 120 },
    { id = "panic",         moodle = "PANIC",          translationName = "Panic",         levels = ALL_LEVELS, polarity = "negative", priority = 110 },
    { id = "cold",          moodle = "HYPOTHERMIA",    translationName = "Hypothermia",   levels = ALL_LEVELS, polarity = "negative", priority = 105 },
    { id = "hot",           moodle = "HYPERTHERMIA",   translationName = "Hyperthermia",  levels = ALL_LEVELS, polarity = "negative", priority = 105 },
    { id = "windchill",     moodle = "WINDCHILL",      translationName = "Windchill",     levels = ALL_LEVELS, polarity = "negative", priority = 100 },
    { id = "has_cold",      moodle = "HAS_A_COLD",     translationName = "HasACold",      levels = ALL_LEVELS, polarity = "negative", priority = 95 },
    { id = "tired",         moodle = "TIRED",          translationName = "Tired",         levels = ALL_LEVELS, polarity = "negative", priority = 90 },
    { id = "cant_sprint",   moodle = "CANT_SPRINT",    translationName = "CantSprint",    levels = { 1 },      polarity = "negative", priority = 88 },
    { id = "endurance",     moodle = "ENDURANCE",      translationName = "Endurance",     levels = ALL_LEVELS, polarity = "negative", priority = 85 },
    { id = "thirst",        moodle = "THIRST",         translationName = "Thirst",        levels = ALL_LEVELS, polarity = "negative", priority = 80 },
    { id = "hungry",        moodle = "HUNGRY",         translationName = "Hungry",        levels = ALL_LEVELS, polarity = "negative", priority = 75 },
    { id = "heavy_load",    moodle = "HEAVY_LOAD",     translationName = "HeavyLoad",     levels = ALL_LEVELS, polarity = "negative", priority = 70 },
    { id = "food_eaten",    moodle = "FOOD_EATEN",     translationName = "FoodEaten",     levels = ALL_LEVELS, polarity = "positive", priority = 65 },
    { id = "wet",           moodle = "WET",            translationName = "Wet",           levels = ALL_LEVELS, polarity = "negative", priority = 60 },
    { id = "noxious_smell", moodle = "NOXIOUS_SMELL",  translationName = "NoxiousSmell",  levels = ALL_LEVELS, polarity = "negative", priority = 55 },
    { id = "drunk",         moodle = "DRUNK",          translationName = "Drunk",         levels = ALL_LEVELS, polarity = "negative", priority = 54 },
    { id = "stress",        moodle = "STRESS",         translationName = "Stress",        levels = ALL_LEVELS, polarity = "negative", priority = 50 },
    { id = "angry",         moodle = "ANGRY",          translationName = "Angry",         levels = ALL_LEVELS, polarity = "negative", priority = 47 },
    { id = "nicotine",      stat = "NICOTINE_WITHDRAWAL", specialVanillaKey = "IGUI_StatsAndBody_NicotineWithdrawal", levels = ALL_LEVELS, polarity = "negative", priority = 45 },
    { id = "uncomfortable", moodle = "UNCOMFORTABLE",  translationName = "Uncomfortable", levels = ALL_LEVELS, polarity = "negative", priority = 43 },
    { id = "unhappy",       moodle = "UNHAPPY",        translationName = "Unhappy",       levels = ALL_LEVELS, polarity = "negative", priority = 40 },
    { id = "bored",         moodle = "BORED",          translationName = "Bored",         levels = ALL_LEVELS, polarity = "negative", priority = 35 },
}

local stateById = {}
for _, definition in ipairs(SIV.STATES) do
    stateById[definition.id] = definition
end

function SIV.getState(stateId)
    return type(stateId) == "string" and stateById[stateId] or nil
end

local function containsLevel(definition, level)
    if not definition then return false end
    for _, reachable in ipairs(definition.levels or ALL_LEVELS) do
        if reachable == level then return true end
    end
    return false
end

function SIV.normalizeSeverity(stateId, value)
    local definition = SIV.getState(stateId)
    value = math.floor(tonumber(value) or 0)
    value = math.max(0, math.min(4, value))
    if value == 0 or not definition then return 0 end
    if containsLevel(definition, value) then return value end
    if definition.id == "on_fire" then return 4 end
    return 0
end

function SIV.severityFromRange(value, minimum, maximum, inverted)
    value = tonumber(value)
    minimum = tonumber(minimum)
    maximum = tonumber(maximum)
    if not value or not minimum or not maximum or maximum <= minimum then return 0 end
    local normalized = (value - minimum) / (maximum - minimum)
    normalized = math.max(0, math.min(1, normalized))
    if inverted then normalized = 1 - normalized end
    if normalized <= 0.01 then return 0 end
    return math.max(1, math.min(4, math.ceil(normalized * 4)))
end

local function normalizeDirection(direction)
    if direction == "reminder" then return "rise" end
    if direction == "rise" or direction == "fall" then return direction end
    return nil
end

function SIV.phraseKey(stateId, direction, phraseLevel, phraseIndex)
    local definition = SIV.getState(stateId)
    direction = normalizeDirection(direction)
    phraseLevel = tonumber(phraseLevel)
    phraseIndex = tonumber(phraseIndex)
    if not definition or not direction or not phraseLevel or not phraseIndex then return nil end
    phraseLevel = math.floor(phraseLevel)
    phraseIndex = math.floor(phraseIndex)
    if not containsLevel(definition, phraseLevel) then return nil end
    if phraseIndex < 1 or phraseIndex > SIV.PHRASES_PER_LEVEL then return nil end

    if direction == "rise" then
        if definition.translationName and phraseIndex <= 2 then
            local suffix = phraseIndex == 1 and "lvl" or "desc_lvl"
            return string.format("Moodles_%s_%s%d", definition.translationName, suffix, phraseLevel)
        end
        if definition.specialVanillaKey and phraseIndex == 1 then
            return definition.specialVanillaKey
        end
    end

    return string.format("IGUI_SIV_%s_%s_L%d_%02d",
        definition.id, string.upper(direction), phraseLevel, phraseIndex)
end

function SIV.validSemanticEvent(args)
    if type(args) ~= "table" then return false end
    local phraseLevel = tonumber(args.phraseLevel)
    local phraseIndex = tonumber(args.phraseIndex)
    local toLevel = tonumber(args.toLevel)
    if not phraseLevel or not phraseIndex or not toLevel then return false end
    if phraseLevel ~= math.floor(phraseLevel) or phraseIndex ~= math.floor(phraseIndex)
        or toLevel ~= math.floor(toLevel) then return false end
    if toLevel < 0 or toLevel > 4 then return false end
    if args.direction == "rise" and toLevel ~= phraseLevel then return false end
    if args.direction == "fall" and toLevel >= phraseLevel then return false end
    return SIV.phraseKey(args.stateId, args.direction, phraseLevel, phraseIndex) ~= nil
end

function SIV.interpolateVanillaColor(level, highlight)
    level = math.max(1, math.min(4, math.floor(tonumber(level) or 1)))
    local factor = level / 4
    local red = tonumber(highlight and highlight.r) or 1
    local green = tonumber(highlight and highlight.g) or 0
    local blue = tonumber(highlight and highlight.b) or 0
    return 0.5 + (red - 0.5) * factor,
        0.5 + (green - 0.5) * factor,
        0.5 + (blue - 0.5) * factor
end

function SIV.eventUsesPositiveColor(stateId, direction, toLevel)
    local definition = SIV.getState(stateId)
    if not definition then return false end
    if definition.polarity == "positive" then return true end
    return direction == "fall" and tonumber(toLevel) == 0
end
