local cooldownActive = false
local cooldownEndSec = 0 -- integer seconds timestamp (GameTimer/1000)
local showingBanner = false

-- Quick startup debug - will print to the client's F8 console if Config.Debug is true
CreateThread(function()
    Wait(1000)
    if Config and Config.Debug then
        local sid = GetPlayerServerId(PlayerId())
        print(("^6[HostileCooldown]^7 Client startup: Config.Debug=%s | player_server_id=%s | resource=%s"):format(tostring(Config.Debug), tostring(sid), GetCurrentResourceName()))
    end
end)

-- Debug command: force-send a death notification to the server (use in F8)
RegisterCommand('hc_testdie', function()
    if Config and Config.Debug then
        local sid = GetPlayerServerId(PlayerId())
        print(("^6[HostileCooldown]^7 hc_testdie invoked locally (player_server_id=%s), sending server event"):format(tostring(sid)))
    end
    TriggerServerEvent('hostile_cooldown:playerDied')
end, false)

-- Debug command: force-start the cooldown locally (use in F8)
RegisterCommand('hc_teststart', function()
    if Config and Config.Debug then
        local sid = GetPlayerServerId(PlayerId())
        print(("^6[HostileCooldown]^7 hc_teststart invoked locally (player_server_id=%s), starting local cooldown"):format(tostring(sid)))
    end
    -- Config.CooldownTime is minutes; pass seconds to the event handler
    TriggerEvent('hostile_cooldown:start', (Config.CooldownTime or 0) * 60)
end, false)

-- Lightweight paintball detection function (from sasha's script)
local function IsInPaintballMatch()
    -- Check all configured paintball resources
    for _, resourceName in ipairs(Config.PaintballResources) do
        if GetResourceState(resourceName) == 'started' then
            -- Try different export methods for different paintball scripts
            if resourceName == 'pug-paintball' then
                local success, result = pcall(function()
                    return exports['pug-paintball']:IsInPaintball()
                end)
                if success and result then
                    return true
                end
            elseif resourceName == 'nass_paintball' then
                local success, result = pcall(function()
                    return exports['nass_paintball']:inGame()
                end)
                if success and result then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle player death using fallback native death detection (from sasha's script)
local wasDead = false
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local isDead = IsEntityDead(playerPed)
        
        if isDead and not wasDead then
            -- Check paintball status before notifying server
            if IsInPaintballMatch() then
                if Config.Debug then
                    local sid = GetPlayerServerId(PlayerId())
                    print(("^6[HostileCooldown]^7 Player %s died in paintball match - skipping cooldown"):format(sid))
                end
            else
                if Config.Debug then
                    local sid = GetPlayerServerId(PlayerId())
                    local name = GetPlayerName(PlayerId())
                    print(("^6[HostileCooldown]^7 Detected local death via native detection, notifying server (id=%s, name=%s)"):format(sid, name))
                end
                TriggerServerEvent('hostile_cooldown:playerDied')
            end
        end
        
        wasDead = isDead
        Wait(1000) -- Check every second
    end
end)

-- Draw fallback text at top of screen
local function DrawTextTopCenter(text)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(0.45, 0.45)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.15) -- Moved down to avoid HUD conflict
end

-- Thread to manage cooldown restrictions & display
CreateThread(function()
    local lastRemaining = -1
    while true do
        local sleep = 500 -- sleep more when idle
        if cooldownActive then
            sleep = 0 -- per-frame while restricting controls/drawing text
            local nowSec = math.floor(GetGameTimer() / 1000)
            local remaining = math.max(0, cooldownEndSec - nowSec)
            if remaining <= 0 then
                cooldownActive = false
                if Config.UseTopBanner and showingBanner then
                    lib.hideTextUI()
                    showingBanner = false
                end
                lib.notify({
                    title = 'Cooldown Ended',
                    description = 'You may now engage in combat.',
                    type = 'success'
                })
                    if Config.Debug then
                        local sid = GetPlayerServerId(PlayerId())
                        print(("^6[HostileCooldown]^7 Cooldown ended for player %s"):format(sid))
                    end
            else
                if Config.UseTopBanner then
                    if not showingBanner then
                        lib.showTextUI(("🕒 Hostile Cooldown: %s seconds remaining"):format(remaining), {
                            position = "right-center", -- Changed from top-center to avoid HUD conflict
                            icon = 'clock',
                            style = { borderRadius = 8, backgroundColor = '#990000', color = 'white', fontSize = 16, padding = 8 }
                        })
                        showingBanner = true
                        lastRemaining = remaining
                    else
                        -- Only refresh text when the second value changes
                        if remaining ~= lastRemaining then
                            lib.hideTextUI()
                            lib.showTextUI(("🕒 Hostile Cooldown: %s seconds remaining"):format(remaining), {
                                position = "right-center",
                                icon = 'clock',
                                style = { borderRadius = 8, backgroundColor = '#990000', color = 'white', fontSize = 16, padding = 8 }
                            })
                            lastRemaining = remaining
                        end
                    end
                else
                    DrawTextTopCenter(("🕒 Hostile Cooldown: %s seconds remaining"):format(remaining))
                end

                -- Disable combat controls
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 257, true)
                DisablePlayerFiring(PlayerId(), true)
            end
        end
        Wait(sleep)
    end
end)

-- Start cooldown handler
RegisterNetEvent('hostile_cooldown:start', function(duration)
    -- Treat zero/negative duration as a request to clear the cooldown cleanly
    if duration == nil or duration <= 0 then
        cooldownActive = false
        cooldownEndSec = 0
        if Config.UseTopBanner and showingBanner then
            lib.hideTextUI()
            showingBanner = false
        end
        lib.notify({
            title = 'Cooldown Removed',
            description = 'Your hostile cooldown has been cleared.',
            type = 'inform'
        })
        if Config.Debug then
            local sid = GetPlayerServerId(PlayerId())
            print(("^6[HostileCooldown]^7 Cooldown cleared for player %s"):format(sid))
        end
        return
    end

    cooldownActive = true
    cooldownEndSec = math.floor(GetGameTimer() / 1000) + duration
    lib.notify({
        title = 'Hostile Cooldown',
        description = ('You must wait %s minutes before engaging in combat.'):format(math.ceil(duration / 60)),
        type = 'error'
    })
    if Config.Debug then
        local sid = GetPlayerServerId(PlayerId())
        print(("^6[HostileCooldown]^7 Cooldown started for player %s (duration=%s seconds, ends_at=%s)"):format(sid, tostring(duration), tostring(cooldownEndSec)))
    end
end)