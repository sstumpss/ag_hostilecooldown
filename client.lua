local cooldownActive = false
local cooldownEnd = 0
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

-- Handle player death / revival depending on config
-- Death event hook selection
-- Wasabi ambulance emits `wasabi_bridge:onPlayerDeath` when a player dies.
-- The previous implementation incorrectly listened to `wasabi_ambulance:revive`, which fires on revive not death.
local lastDeathSent = 0
local DEATH_DEBOUNCE_MS = 3000 -- avoid duplicate sends in quick succession

if Config.UseWasabiAmbulance then
    AddEventHandler('wasabi_bridge:onPlayerDeath', function(data)
        local now = GetGameTimer()
        if now - lastDeathSent < DEATH_DEBOUNCE_MS then
            if Config.Debug then
                print('^6[HostileCooldown]^7 Skipping duplicate death event (debounced)')
            end
            return
        end
        lastDeathSent = now
        if Config.Debug then
            local sid = GetPlayerServerId(PlayerId())
            local name = GetPlayerName(PlayerId())
            print(("^6[HostileCooldown]^7 Detected death via wasabi_bridge:onPlayerDeath, notifying server (id=%s, name=%s)"):format(sid, name))
        end
        TriggerServerEvent('hostile_cooldown:playerDied')
    end)
else
    RegisterNetEvent('baseevents:onPlayerDied', function()
        local now = GetGameTimer()
        if now - lastDeathSent < DEATH_DEBOUNCE_MS then
            if Config.Debug then
                print('^6[HostileCooldown]^7 Skipping duplicate baseevents death (debounced)')
            end
            return
        end
        lastDeathSent = now
        if Config.Debug then
            local sid = GetPlayerServerId(PlayerId())
            local name = GetPlayerName(PlayerId())
            print(("^6[HostileCooldown]^7 Detected local death (baseevents), notifying server (id=%s, name=%s)"):format(sid, name))
        end
        TriggerServerEvent('hostile_cooldown:playerDied')
    end)
end

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
    EndTextCommandDisplayText(0.5, 0.05)
end

-- Thread to manage cooldown restrictions & display
CreateThread(function()
    while true do
        Wait(0)
        if cooldownActive then
            local remaining = math.floor(cooldownEnd - GetGameTimer() / 1000)
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
                            position = "top-center",
                            icon = 'clock',
                            style = { borderRadius = 8, backgroundColor = '#990000', color = 'white', fontSize = 16, padding = 8 }
                        })
                        showingBanner = true
                    else
                        -- Update the banner every second
                        if GetGameTimer() % 1000 < 30 then
                            lib.hideTextUI()
                            lib.showTextUI(("🕒 Hostile Cooldown: %s seconds remaining"):format(remaining), {
                                position = "top-center",
                                icon = 'clock',
                                style = { borderRadius = 8, backgroundColor = '#990000', color = 'white', fontSize = 16, padding = 8 }
                            })
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
    end
end)

-- Start cooldown handler
RegisterNetEvent('hostile_cooldown:start', function(duration)
    cooldownActive = true
    cooldownEnd = GetGameTimer() / 1000 + duration
    lib.notify({
        title = 'Hostile Cooldown',
        description = ('You must wait %s minutes before engaging in combat.'):format(duration / 60),
        type = 'error'
    })
    if Config.Debug then
        local sid = GetPlayerServerId(PlayerId())
        print(("^6[HostileCooldown]^7 Cooldown started for player %s (duration=%s seconds, ends_at=%s)"):format(sid, tostring(duration), tostring(cooldownEnd)))
    end
end)
