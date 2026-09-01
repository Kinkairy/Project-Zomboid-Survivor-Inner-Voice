if isClient() then return end

require "SIV_Catalog"

local lastAcceptedByPlayer = {}
local RATE_LIMIT_SECONDS = 3

local function playerKey(player)
    if not player then return nil end
    local onlineId = player.getOnlineID and player:getOnlineID() or nil
    if onlineId ~= nil then return tostring(onlineId) end
    return player.getUsername and player:getUsername() or nil
end

local function onClientCommand(module, command, player, args)
    if module ~= SIV.MODULE or command ~= "spoken" then return end
    if not player or not SIV.validSemanticEvent(args) then return end

    local key = playerKey(player)
    if not key then return end
    local now = getTimestamp()
    if now - (lastAcceptedByPlayer[key] or -math.huge) < RATE_LIMIT_SECONDS then return end
    lastAcceptedByPlayer[key] = now

    sendServerCommand(SIV.MODULE, "spoken", {
        stateId = args.stateId,
        direction = args.direction,
        phraseLevel = math.floor(tonumber(args.phraseLevel)),
        toLevel = math.floor(tonumber(args.toLevel)),
        phraseIndex = math.floor(tonumber(args.phraseIndex)),
        onlineId = player:getOnlineID(),
    })
end

Events.OnClientCommand.Add(onClientCommand)

print("[SurvivorInnerVoice] Server " .. SIV.VERSION)
