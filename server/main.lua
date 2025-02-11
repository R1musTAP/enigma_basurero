local QBCore = exports['qb-core']:GetCoreObject()

-- Variables para tracking de trabajadores activos
local activeWorkers = {}
local activeTrucks = {}

-- Función para registrar un nuevo trabajador
RegisterServerEvent('enigma_basurero:registerWorker')
AddEventHandler('enigma_basurero:registerWorker', function(truckNetId, solo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        activeWorkers[src] = {
            id = src,
            name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            truck = truckNetId,
            solo = solo,
            partner = nil,
            route = nil,
            progress = 0
        }
        
        -- Registrar el camión
        activeTrucks[truckNetId] = {
            driver = src,
            partners = {}
        }
        
        -- Notificar al cliente que se registró exitosamente
        TriggerClientEvent('enigma_basurero:workerRegistered', src, true)
    end
end)

-- Función para unirse a un compañero
RegisterServerEvent('enigma_basurero:joinPartner')
AddEventHandler('enigma_basurero:joinPartner', function(partnerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local PartnerPlayer = QBCore.Functions.GetPlayer(partnerId)
    
    if Player and PartnerPlayer and activeWorkers[partnerId] then
        -- Verificar si el compañero está trabajando solo
        if activeWorkers[partnerId].solo then
            TriggerClientEvent('QBCore:Notify', src, 'Este trabajador está en modo solitario', 'error')
            return
        end
        
        -- Verificar si hay espacio en el camión (máximo 3 trabajadores por camión)
        local truckNetId = activeWorkers[partnerId].truck
        if #activeTrucks[truckNetId].partners >= 2 then
            TriggerClientEvent('QBCore:Notify', src, 'El camión está lleno', 'error')
            return
        end
        
        -- Registrar al trabajador como compañero
        activeWorkers[src] = {
            id = src,
            name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            truck = truckNetId,
            solo = false,
            partner = partnerId,
            route = activeWorkers[partnerId].route,
            progress = 0
        }
        
        -- Añadir al trabajador a la lista de compañeros del camión
        table.insert(activeTrucks[truckNetId].partners, src)
        
        -- Notificar a todos los trabajadores del camión
        TriggerClientEvent('enigma_basurero:partnerJoined', partnerId, src)
        TriggerClientEvent('enigma_basurero:joinedSuccessfully', src, {
            truck = truckNetId,
            route = activeWorkers[partnerId].route,
            progress = activeWorkers[partnerId].progress
        })
        
        -- Notificar a los demás compañeros
        for _, partnerId in ipairs(activeTrucks[truckNetId].partners) do
            if partnerId ~= src then
                TriggerClientEvent('enigma_basurero:partnerJoined', partnerId, src)
            end
        end
    end
end)

-- Función para sincronizar el progreso
RegisterServerEvent('enigma_basurero:updateProgress')
AddEventHandler('enigma_basurero:updateProgress', function(progress, binIndex)
    local src = source
    if not activeWorkers[src] then return end
    
    local truckNetId = activeWorkers[src].truck
    activeWorkers[src].progress = progress
    
    -- Sincronizar el progreso con todos los compañeros
    if not activeWorkers[src].solo then
        for _, partnerId in ipairs(activeTrucks[truckNetId].partners) do
            TriggerClientEvent('enigma_basurero:syncProgress', partnerId, progress, binIndex)
        end
        TriggerClientEvent('enigma_basurero:syncProgress', activeTrucks[truckNetId].driver, progress, binIndex)
    end
end)

-- Función para terminar el trabajo
RegisterServerEvent('enigma_basurero:finishWork')
AddEventHandler('enigma_basurero:finishWork', function()
    local src = source
    if not activeWorkers[src] then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- Calcular pago base
        local basePay = 500 -- Pago base por ruta
        local bonusPay = math.random(100, 300) -- Bonus aleatorio
        local totalPay = basePay + bonusPay
        
        -- Añadir bonus si trabajó en equipo
        if not activeWorkers[src].solo then
            totalPay = totalPay * 1.2 -- 20% extra por trabajo en equipo
        end
        
        -- Pagar al jugador
        Player.Functions.AddMoney('bank', totalPay, 'trabajo-basurero')
        
        -- Notificar al jugador
        TriggerClientEvent('QBCore:Notify', src, 'Has ganado 
 .. totalPay .. ' por tu trabajo', 'success')
        
        -- Limpiar datos del trabajador
        local truckNetId = activeWorkers[src].truck
        if activeTrucks[truckNetId] then
            -- Remover al trabajador de la lista de compañeros
            for i, partnerId in ipairs(activeTrucks[truckNetId].partners) do
                if partnerId == src then
                    table.remove(activeTrucks[truckNetId].partners, i)
                    break
                end
            end
            
            -- Si era el conductor, notificar a todos los compañeros
            if activeTrucks[truckNetId].driver == src then
                for _, partnerId in ipairs(activeTrucks[truckNetId].partners) do
                    TriggerClientEvent('enigma_basurero:driverLeft', partnerId)
                end
                activeTrucks[truckNetId] = nil
            end
        end
        
        activeWorkers[src] = nil
    end
end)

-- Función para sincronizar la recolección de basura
RegisterServerEvent('enigma_basurero:syncGarbage')
AddEventHandler('enigma_basurero:syncGarbage', function(binId)
    local src = source
    if not activeWorkers[src] then return end
    
    local truckNetId = activeWorkers[src].truck
    if not activeWorkers[src].solo then
        for _, partnerId in ipairs(activeTrucks[truckNetId].partners) do
            TriggerClientEvent('enigma_basurero:garbageCollected', partnerId, binId)
        end
        TriggerClientEvent('enigma_basurero:garbageCollected', activeTrucks[truckNetId].driver, binId)
    end
end)

-- Evento para cuando un jugador se desconecta
AddEventHandler('playerDropped', function()
    local src = source
    if activeWorkers[src] then
        -- Limpiar datos del trabajador
        local truckNetId = activeWorkers[src].truck
        if activeTrucks[truckNetId] then
            -- Notificar a los compañeros si el conductor se desconectó
            if activeTrucks[truckNetId].driver == src then
                for _, partnerId in ipairs(activeTrucks[truckNetId].partners) do
                    TriggerClientEvent('enigma_basurero:driverLeft', partnerId)
                end
                activeTrucks[truckNetId] = nil
            else
                -- Remover al trabajador de la lista de compañeros
                for i, partnerId in ipairs(activeTrucks[truckNetId].partners) do
                    if partnerId == src then
                        table.remove(activeTrucks[truckNetId].partners, i)
                        break
                    end
                end
            end
        end
        activeWorkers[src] = nil
    end
end)

-- Comando para ver trabajadores activos (solo para admins)
QBCore.Commands.Add('verbasureros', 'Ver trabajadores de basura activos', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.permission == "admin" then
        local activeCount = 0
        local message = "Trabajadores activos:\\n"
        
        for id, worker in pairs(activeWorkers) do
            activeCount = activeCount + 1
            message = message .. string.format("ID: %s - Nombre: %s - Solo: %s\\n", 
                id, worker.name, worker.solo and "Sí" or "No")
        end
        
        if activeCount == 0 then
            message = "No hay trabajadores activos"
        end
        
        TriggerClientEvent('QBCore:Notify', source, message, 'primary')
    end
end)