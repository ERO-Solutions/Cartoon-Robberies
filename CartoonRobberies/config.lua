local isRobbing = false
local canRob = true
local robberyCoords = vector3(373.0461, 328.8553, 103.5665)
local lastRobbery = 0
local lastRobber = nil
local promptDisplayed = false
local robberyCancelled = false

-- Robbery animation
function PlayRobberyAnimation()
    local playerPed = PlayerPedId()
    robberyCancelled = false
    
    RequestAnimDict("oddjobs@shop_robbery@rob_till")
    while not HasAnimDictLoaded("oddjobs@shop_robbery@rob_till") do
        Citizen.Wait(0)
    end
    
    TaskPlayAnim(playerPed, "oddjobs@shop_robbery@rob_till", "loop", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Progress timer (40 seconds)
    local startTime = GetGameTimer()
    while GetGameTimer() - startTime < 40000 do
        Citizen.Wait(0)
        local progress = math.floor((GetGameTimer() - startTime) / 400)
        DrawText3D(robberyCoords.x, robberyCoords.y, robberyCoords.z + 0.5, "ROBBING... "..progress.."% [X to cancel]")
        
        -- Check for cancel input
        if IsControlJustPressed(0, 73) then -- X key
            robberyCancelled = true
            break
        end
    end
    
    ClearPedTasks(playerPed)
    RemoveAnimDict("oddjobs@shop_robbery@rob_till")
end

-- Fingerprint animation
function PlayFingerprintAnimation()
    local playerPed = PlayerPedId()
    
    RequestAnimDict("amb@prop_human_bum_bin@base")
    while not HasAnimDictLoaded("amb@prop_human_bum_bin@base") do
        Citizen.Wait(0)
    end
    
    TaskPlayAnim(playerPed, "amb@prop_human_bum_bin@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Progress timer
    local startTime = GetGameTimer()
    while GetGameTimer() - startTime < 3000 do -- 3 seconds
        Citizen.Wait(0)
        local progress = math.floor((GetGameTimer() - startTime) / 30)
        DrawText3D(robberyCoords.x, robberyCoords.y, robberyCoords.z + 0.5, "INSPECTING... "..progress.."%")
    end
    
    ClearPedTasks(playerPed)
    RemoveAnimDict("amb@prop_human_bum_bin@base")
end

-- Check distance to register
function IsNearCashRegister()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - robberyCoords)
    return distance < 2.0
end

-- Format time
function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%d minutes and %d seconds ago", minutes, remainingSeconds)
end

-- Main thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        
        if IsNearCashRegister() then
            -- Robbery prompt
            if canRob and not isRobbing then
                DrawText3D(robberyCoords.x, robberyCoords.y, robberyCoords.z + 0.5, "~g~[X]~w~ ROB CASH REGISTER")
                promptDisplayed = true
                
                if IsControlJustPressed(0, 73) then -- X key
                    isRobbing = true
                    canRob = false
                    
                    -- Send 911 alert immediately when robbery starts
                    TriggerServerEvent('911:serverCall', 'Robbery In Progress | Vinewood | Clinton Ave | Register!')
                    
                    PlayRobberyAnimation()
                    
                    if not robberyCancelled then
                        -- Record robbery only if not cancelled
                        lastRobbery = GetGameTimer()
                        lastRobber = GetPlayerServerId(PlayerId())
                        
                        -- Notification
                        BeginTextCommandThefeedPost('STRING')
                        AddTextComponentSubstringPlayerName('~g~You stole $500 from the cash register!')
                        EndTextCommandThefeedPostTicker(false, true)
                    else
                        -- Cancelled notification
                        BeginTextCommandThefeedPost('STRING')
                        AddTextComponentSubstringPlayerName('~r~You cancelled the robbery and got nothing!')
                        EndTextCommandThefeedPostTicker(false, true)
                    end
                    
                    isRobbing = false
                    Citizen.Wait(420000) -- 7 minute cooldown (420000ms)
                    canRob = true
                end
            elseif promptDisplayed and not IsNearCashRegister() then
                promptDisplayed = false
            end
        end
    end
end)

-- Fingerprint command (changed to /fingerprintregister)
RegisterCommand('fingerprintregister', function()
    if IsNearCashRegister() then
        PlayFingerprintAnimation()
        
        if lastRobbery > 0 then
            local timeSinceRobbery = math.floor((GetGameTimer() - lastRobbery) / 1000)
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName(('~y~Fingerprint Results:~w~\nRobbed %s\nSuspect ID: %s'):format(
                FormatTime(timeSinceRobbery),
                lastRobber or "Unknown"
            ))
            EndTextCommandThefeedPostTicker(false, true)
        else
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName('~y~Fingerprint Results:~w~\nNo recent robberies detected')
            EndTextCommandThefeedPostTicker(false, true)
        end
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('~r~You need to be near the cash register to check fingerprints')
        EndTextCommandThefeedPostTicker(false, true)
    end
end, false)

-- 3D Text Drawing
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end

-- Debug command
RegisterCommand('checkpos', function()
    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    print(('Current position: %.4f, %.4f, %.4f, %.4f'):format(coords.x, coords.y, coords.z, heading))
    print(('Distance to register: %.2f'):format(#(coords - robberyCoords)))
end, false)