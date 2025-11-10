local systemEnabled = true

-- Quick startup debug - will print to the server console if Config.Debug is true
if Config and Config.Debug then
    print(("^6[HostileCooldown]^7 Startup: Config.Debug=%s | resource=%s"):format(tostring(Config.Debug), GetCurrentResourceName()))
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

RegisterNetEvent('hostile_cooldown:playerDied', function()
    local src = source
    if Config.Debug then
        print(("^6[HostileCooldown]^7 Received death notification from %s (%s)"):format(src, GetPlayerName(src)))
    end
    if not systemEnabled then
        if Config.Debug then
            print(("^6[HostileCooldown]^7 System disabled, ignoring death from %s"):format(src))
        end
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local job = player.PlayerData.job.name
    if isJobExcluded(job) then
        if Config.Debug then
            print(("^6[HostileCooldown]^7 Player %s has excluded job '%s' - skipping cooldown"):format(src, job))
        end
        return
    end

    local inPaintball = GetResourceState("pug-paintball") == "started"
        and exports["pug-paintball"]:IsInPaintball(src)
    local inBattleRoyale = GetResourceState("pug-battleroyale") == "started"
        and exports["pug-battleroyale"]:IsInBattleRoyale(src)
    if inPaintball or inBattleRoyale then
        if Config.Debug then
            print(("^6[HostileCooldown]^7 Player %s is in a minigame (paintball=%s, battleroyale=%s) - skipping cooldown"):format(src, tostring(inPaintball), tostring(inBattleRoyale)))
        end
        return
    end

    if Config.Debug then
        local durationSeconds = (Config.CooldownTime or 0) * 60
        local endsAt = os.time() + durationSeconds
        print(("^6[HostileCooldown]^7 Starting cooldown for %s (duration=%s minutes / %s seconds, ends_at=%s)"):format(src, tostring(Config.CooldownTime), tostring(durationSeconds), tostring(endsAt)))
    end

    -- Server stores cooldown in minutes; send seconds to clients
    TriggerClientEvent('hostile_cooldown:start', src, (Config.CooldownTime or 0) * 60)
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
