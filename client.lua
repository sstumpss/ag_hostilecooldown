local cooldownActive = false
local cooldownEnd = 0
local showingBanner = false

-- Handle player death / revival depending on config
if Config.UseWasabiAmbulance then
    RegisterNetEvent('wasabi_ambulance:revive', function(adminRevive)
        if not adminRevive then
            TriggerServerEvent('hostile_cooldown:playerDied')
        end
    end)
else
    RegisterNetEvent('baseevents:onPlayerDied', function()
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
end)
