local QBCore = exports['qb-core']:GetCoreObject()
local isOnDuty = false
local currentTruck = nil
local currentRoute = nil
local currentBin = nil
local partnerMode = false
local partner = nil
local jobPed = nil
local jobBlip = nil

-- UI Functions
function ShowUI(type, data)
    SendNUIMessage({
        action = type,
        data = data
    })
    SetNuiFocus(true, true)
end

-- Event handler for resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        InitializeJob()
    end
end)

-- Event handler for player loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    InitializeJob()
end)

-- Initialize job function
function InitializeJob()
    Citizen.CreateThread(function()
        Citizen.Wait(1000) -- Esperar a que todo esté listo
        CreateBlip()
        CreateJobPed()
        CreateZones()
        print("[enigma_basurero] Inicializado correctamente")
    end)
end

-- Create job blip
function CreateBlip()
    if jobBlip ~= nil then
        RemoveBlip(jobBlip)
    end
    
    jobBlip = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
    SetBlipSprite(jobBlip, Config.Blip.sprite)
    SetBlipDisplay(jobBlip, 4)
    SetBlipColour(jobBlip, Config.Blip.color)
    SetBlipScale(jobBlip, Config.Blip.scale)
    SetBlipAsShortRange(jobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(jobBlip)
    print("[enigma_basurero] Blip creado en: ", Config.Blip.coords)
end

-- Create job NPC
function CreateJobPed()
    Citizen.CreateThread(function()
        if jobPed ~= nil then
            DeletePed(jobPed)
        end

        local model = Config.Ped.model
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
        print("[enigma_basurero] Modelo de NPC cargado")
        
        jobPed = CreatePed(4, model, Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z, Config.Ped.coords.w, false, true)
        
        if DoesEntityExist(jobPed) then
            print("[enigma_basurero] NPC creado correctamente")
            FreezeEntityPosition(jobPed, true)
            SetEntityInvincible(jobPed, true)
            SetBlockingOfNonTemporaryEvents(jobPed, true)
            TaskStartScenarioInPlace(jobPed, Config.Ped.scenario, 0, true)
            
            -- Add target interaction
            exports['qb-target']:AddTargetEntity(jobPed, {
                options = {
                    {
                        type = "client",
                        event = "enigma_basurero:openMenu",
                        icon = "fas fa-trash",
                        label = "Hablar con el encargado",
                    }
                },
                distance = 2.0
            })
        else
            print("[enigma_basurero] Error al crear el NPC")
        end
        
        SetModelAsNoLongerNeeded(model)
    end)
end

-- Create zones for truck spawns
function CreateZones()
    exports['qb-target']:AddBoxZone("trash_duty", Config.Blip.coords, 2.0, 2.0, {
        name = "trash_duty",
        heading = 0,
        debugPoly = false,
    }, {
        options = {
            {
                type = "client",
                event = "enigma_basurero:openMenu",
                icon = "fas fa-trash",
                label = "Iniciar Trabajo",
                job = "all"
            },
        },
        distance = 2.0
    })
end

-- Open menu event handler
RegisterNetEvent('enigma_basurero:openMenu')
AddEventHandler('enigma_basurero:openMenu', function()
    if isOnDuty then
        QBCore.Functions.Notify('Ya estás en servicio!', 'error')
        return
    end
    
    ShowUI('show', {})
end)

-- NUI Callbacks
RegisterNUICallback('startSolo', function(data, cb)
    StartWork(false)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startPartner', function(data, cb)
    StartWork(true)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Start work function
function StartWork(withPartner)
    if isOnDuty then return end
    
    isOnDuty = true
    partnerMode = withPartner
    
    -- Spawn truck
    local model = GetHashKey(Config.Vehicle.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    currentTruck = CreateVehicle(model, Config.Vehicle.spawnPoint.x, Config.Vehicle.spawnPoint.y, Config.Vehicle.spawnPoint.z, Config.Vehicle.spawnPoint.w, true, false)
    SetEntityAsMissionEntity(currentTruck, true, true)
    
    -- Give vehicle keys
    TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(currentTruck))
    
    -- Select random route
    currentRoute = Config.Routes[math.random(#Config.Routes)]
    
    -- Change clothes
    ChangeUniform()
    
    -- Register as worker
    TriggerServerEvent('enigma_basurero:registerWorker', NetworkGetNetworkIdFromEntity(currentTruck), not withPartner)
    
    -- Start route UI
    ShowUI('startRoute', {
        route = currentRoute,
        partnerMode = partnerMode
    })
    
    -- Create route blips
    CreateRouteBlips()
end

-- Create route blips
function CreateRouteBlips()
    if currentRoute then
        for i, point in ipairs(currentRoute) do
            local blip = AddBlipForCoord(point.coords)
            SetBlipSprite(blip, 1)
            SetBlipColour(blip, 5)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Punto de recogida " .. i)
            EndTextCommandSetBlipName(blip)
            
            -- Add target for garbage collection
            exports['qb-target']:AddBoxZone("garbage_" .. i, point.coords, 2.0, 2.0, {
                name = "garbage_" .. i,
                heading = 0,
                debugPoly = false,
            }, {
                options = {
                    {
                        type = "client",
                        event = "enigma_basurero:collectGarbage",
                        icon = "fas fa-trash",
                        label = "Recoger basura",
                        binId = i
                    },
                },
                distance = 2.0
            })
        end
    end
end

-- Initialize job
function InitializeJob()
    CreateBlip()
    CreateJobPed()
end

-- Create job blip
function CreateBlip()
    local blip = AddBlipForCoord(Config.Blip.coords)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blip)
end

-- Create job NPC
function CreateJobPed()
    RequestModel(GetHashKey(Config.Ped.model))
    while not HasModelLoaded(GetHashKey(Config.Ped.model)) do
        Wait(1)
    end
    
    local ped = CreatePed(4, GetHashKey(Config.Ped.model), Config.Ped.coords.x, Config.Ped.coords.y, Config.Ped.coords.z, Config.Ped.coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
end

-- Start work function
function StartWork(withPartner)
    if isOnDuty then return end
    
    partnerMode = withPartner
    isOnDuty = true
    
    -- Spawn truck
    local model = GetHashKey(Config.Vehicle.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    currentTruck = CreateVehicle(model, Config.Vehicle.spawnPoint.x, Config.Vehicle.spawnPoint.y, Config.Vehicle.spawnPoint.z, Config.Vehicle.spawnPoint.w, true, false)
    SetEntityAsMissionEntity(currentTruck, true, true)
    
    -- Select random route
    currentRoute = Config.Routes[math.random(#Config.Routes)]
    
    -- Change clothes
    ChangeUniform()
    
    -- Start route UI
    ShowUI('startRoute', {
        route = currentRoute,
        partnerMode = partnerMode
    })
end

-- Change player uniform
function ChangeUniform()
    local playerPed = PlayerPedId()
    local gender = IsPedMale(playerPed) and 'male' or 'female'
    
    for k,v in pairs(Config.Uniforms[gender]) do
        SetPedComponentVariation(playerPed, k, v, 0, 0)
    end
end

-- Partner system
RegisterNetEvent('enigma_basurero:joinPartner')
AddEventHandler('enigma_basurero:joinPartner', function(partnerId)
    if not isOnDuty then
        partner = partnerId
        ChangeUniform()
        -- Sync with partner's route
        TriggerServerEvent('enigma_basurero:syncRoute', partnerId)
    end
end)