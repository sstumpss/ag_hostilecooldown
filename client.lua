local cooldownActive = false
local cooldownEnd = 0
local systemEnabled = true
local excludedJobs = { 'police', 'ambulance' } -- jobs immune to cooldown

-- Qbox uses this event when player dies
RegisterNetEvent('baseevents:onPlayerDied', function()
    TriggerServerEvent('hostile_cooldown:playerDied')
end)

-- Draws timer text on screen
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

-- Main cooldown handler
CreateThread(function()
    while true do
        Wait(0)
        if cooldownActive then
            local remaining = math.floor(cooldownEnd - GetGameTimer() / 1000)
            if remaining <= 0 then
                cooldownActive = false
                lib.notify({ title = 'Cooldown Ended', description = 'You may now engage in combat.', type = 'success' })
            else
                DrawTextTopCenter(("🕒 Hostile Cooldown: %s seconds remaining"):format(remaining))
                DisableControlAction(0, 24, true) -- attack
                DisableControlAction(0, 25, true) -- aim
                DisableControlAction(0, 140, true) -- melee light
                DisableControlAction(0, 141, true) -- melee heavy
                DisableControlAction(0, 142, true) -- melee alternate
                DisableControlAction(0, 257, true) -- input attack2
                DisablePlayerFiring(PlayerId(), true)
            end
        end
    end
end)

-- Start cooldown from server
RegisterNetEvent('hostile_cooldown:start', function(duration)
    cooldownActive = true
    cooldownEnd = GetGameTimer() / 1000 + duration
    lib.notify({ title = 'Hostile Cooldown', description = ('You must wait %s minutes before fighting again.'):format(duration/60), type = 'error' })
end)
