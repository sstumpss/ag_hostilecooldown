local systemEnabled = true

-- Helper: Check if a job is excluded
local function isJobExcluded(job)
    for _, j in ipairs(Config.ExcludedJobs) do
        if j == job then return true end
    end
    return false
end

-- Admin command to toggle the cooldown system
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

-- Player death handler (triggered from client)
RegisterNetEvent('hostile_cooldown:playerDied', function()
    local src = source
    if not systemEnabled then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local job = player.PlayerData.job.name
    if isJobExcluded(job) then return end

    -- Skip if in paintball or BR
    local inPaintball = GetResourceState("pug-paintball") == "started"
        and exports["pug-paintball"]:IsInPaintball(src)
    local inBattleRoyale = GetResourceState("pug-battleroyale") == "started"
        and exports["pug-battleroyale"]:IsInBattleRoyale(src)
    if inPaintball or inBattleRoyale then return end

    -- Start cooldown
    TriggerClientEvent('hostile_cooldown:start', src, Config.CooldownTime)
end)
