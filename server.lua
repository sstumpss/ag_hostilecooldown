local systemEnabled = true

-- Quick startup debug - will print to the server console if Config.Debug is true
if Config and Config.Debug then
    print(("^6[HostileCooldown]^7 Startup: Config.Debug=%s | resource=%s"):format(tostring(Config.Debug), GetCurrentResourceName()))
    print(("^6[HostileCooldown]^7 Server event 'hostile_cooldown:playerDied' is being registered"))
end

local function isJobExcluded(job)
    for _, j in ipairs(Config.ExcludedJobs) do
        if j == job then return true end
    end
    return false
end

lib.addCommand('togglecooldown', {
    help = 'Toggle hostile cooldown system on/off',
    restricted = Config.AdminPermission
}, function(source)
    systemEnabled = not systemEnabled
    local state = systemEnabled and 'enabled' or 'disabled'
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Cooldown System',
        description = 'Cooldown ' .. state,
        type = 'inform'
    })
    print(('[HostileCooldown] System %s by %s'):format(state, GetPlayerName(source)))
end)

lib.addCommand('removecooldown', {
    help = 'Remove hostile cooldown for a player by ID',
    restricted = Config.AdminPermission
}, function(source, args)
    local target = tonumber(args[1])
    if not target then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Cooldown System',
            description = 'Usage: /removecooldown {playerId}',
            type = 'error'
        })
        return
    end
    TriggerClientEvent('hostile_cooldown:start', target, 0)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Cooldown System',
        description = ('Cooldown removed for player %s'):format(target),
        type = 'success'
    })
    if Config.Debug then
        print(("^6[HostileCooldown]^7 /removecooldown used by %s for target %s"):format(source, target))
    end
end)

RegisterNetEvent('hostile_cooldown:playerDied', function()
    local src = source
    
    -- Always print this regardless of Config.Debug to verify event reception
    print(("^1[HostileCooldown]^7 ========== EVENT RECEIVED FROM PLAYER %s =========="):format(src))
    
    if Config.Debug then
        print(("^6[HostileCooldown]^7 Player name: %s"):format(GetPlayerName(src)))
        print(("^6[HostileCooldown]^7 System enabled: %s"):format(tostring(systemEnabled)))
    end
    
    if not systemEnabled then
        if Config.Debug then
            print(("^6[HostileCooldown]^7 System disabled, ignoring death from %s"):format(src))
        end
        return
    end

    if Config.Debug then
        print(("^6[HostileCooldown]^7 Attempting to get QBX player data..."))
    end

    local player = exports.qbx_core:GetPlayer(src)
    
    if Config.Debug then
        print(("^6[HostileCooldown]^7 QBX Player retrieved: %s"):format(player and "SUCCESS" or "FAILED"))
    end
    
    if not player then 
        if Config.Debug then
            print(("^1[HostileCooldown]^7 Could not get player data for %s - skipping cooldown"):format(src))
        end
        return 
    end

    local job = player.PlayerData.job.name
    
    if Config.Debug then
        print(("^6[HostileCooldown]^7 Player %s job: %s"):format(src, job))
    end
    
    if isJobExcluded(job) then
        if Config.Debug then
            print(("^6[HostileCooldown]^7 Player %s has excluded job '%s' - skipping cooldown"):format(src, job))
        end
        return
    end

    local durationSeconds = (Config.CooldownTime or 0) * 60
    
    if Config.Debug then
        local endsAt = os.time() + durationSeconds
        print(("^6[HostileCooldown]^7 Starting cooldown for %s (duration=%s minutes / %s seconds, ends_at=%s)"):format(src, tostring(Config.CooldownTime), tostring(durationSeconds), tostring(endsAt)))
    end

    -- Server stores cooldown in minutes; send seconds to clients
    TriggerClientEvent('hostile_cooldown:start', src, durationSeconds)
    
    print(("^2[HostileCooldown]^7 ========== COOLDOWN TRIGGERED FOR PLAYER %s =========="):format(src))
end)

-- Server console command to trigger a cooldown for a player (usage: hc_trigger <playerId>)
RegisterCommand('hc_trigger', function(source, args)
    local target = tonumber(args[1])
    if not target then
        if source == 0 then
            print('Usage: hc_trigger <playerServerId>')
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '^1HC', 'Usage: /hc_trigger <playerServerId>' } })
        end
        return
    end

    if Config and Config.Debug then
        print(("^6[HostileCooldown]^7 hc_trigger invoked by %s for target %s"):format(tostring(source), tostring(target)))
    end

    -- Send seconds to the client
    TriggerClientEvent('hostile_cooldown:start', target, (Config.CooldownTime or 0) * 60)
end, true)

-- Export: Remove cooldown for a player (usage: exports['ag_hostilecooldown']:RemoveCooldown(playerId))
exports('RemoveCooldown', function(playerId)
    if not playerId or type(playerId) ~= 'number' then
        if Config.Debug then
            print("^3[HostileCooldown]^7 RemoveCooldown export called with invalid playerId")
        end
        return false
    end
    
    TriggerClientEvent('hostile_cooldown:start', playerId, 0)
    
    if Config.Debug then
        print(("^6[HostileCooldown]^7 RemoveCooldown export called for player %s"):format(playerId))
    end
    
    return true
end)