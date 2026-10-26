local ESX, QBCore

--get fw
local function getFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end

    if GetResourceState('qbx_core') == 'started' then
        return 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qbcore'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    end

    return 'standalone'
end

--get id from the owner of the veh
local function getOwnerIdentifier(src, framework)
    if framework == 'esx' then
        ESX = ESX or exports['es_extended']:getSharedObject()

        local player = ESX.GetPlayerFromId(src)
        return player and player.identifier
    end

    if framework == 'qbcore' then
        QBCore = QBCore or exports['qb-core']:GetCoreObject()

        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    end

    if framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid
    end

    return nil
end

local function normalizePlate(plate)
    return plate:upper():gsub('%s+', '')
end

local function isValidIdentifier(identifier)
    return type(identifier) == 'string'
        and identifier ~= ''
end

RegisterNetEvent('cdion_enginetoggle:server:request', function(netId)
    local src = source

    if type(netId) ~= 'number' or netId < 1 then
        return
    end

    local framework = getFramework()

    if framework == 'standalone' then
        TriggerClientEvent(
            'cdion_enginetoggle:client:result',
            src, false, 'standalone'
        )
        return
    end

    local ped = GetPlayerPed(src)

    if not ped or ped == 0 then
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if not vehicle or vehicle == 0
        or not DoesEntityExist(vehicle)
        or GetEntityType(vehicle) ~= 2 then
        return
    end

    -- check if player is driving
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        TriggerClientEvent(
            'cdion_enginetoggle:client:result',
            src, false, 'notDriver'
        )
        return
    end

    local identifier = getOwnerIdentifier(src, framework)

    if not isValidIdentifier(identifier) then
        return
    end

    local plate = normalizePlate(
        GetVehicleNumberPlateText(vehicle) or ''
    )

    if plate == '' then
        return
    end

    local schema

    if framework == 'esx' then
        schema = Config.Database.ESX
    elseif framework == 'qbcore' or framework == 'qbox' then
        schema = Config.Database.QB
    else
        return
    end

    -- names proceed from SQL tables
    --from server:_ the value of the player use SQL param
    local query = (
        'SELECT 1 FROM `%s` WHERE `%s` = ? ' ..
        "AND REPLACE(UPPER(`%s`), ' ', '') = ? LIMIT 1"
    ):format(
        schema.table,
        schema.ownerColumn,
        schema.plateColumn
    )

    local ok, result = pcall(function()
        return MySQL.scalar.await(query, {
            identifier,
            plate
        })
    end)

    if not ok then
        print(('[cdion_enginetoggle] Database error: %s')
            :format(tostring(result)))
        return
    end

    if not result then
        TriggerClientEvent(
            'cdion_enginetoggle:client:result',
            src, false, 'notOwner'
        )
        return
    end

    TriggerClientEvent(
        'cdion_enginetoggle:client:result',
        src, true, netId
    )
end)