
local pending = false
local lastRequest = 0
local engineLockedOff = {}

local ESX, QBCore

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

local function notify(message, notifyType)
    local framework = getFramework()

    if framework == 'esx' then
        ESX = ESX or exports['es_extended']:getSharedObject()
        ESX.ShowNotification(message)
        return
    end

    if framework == 'qbcore' then
        QBCore = QBCore or exports['qb-core']:GetCoreObject()
        QBCore.Functions.Notify(message, notifyType or 'primary')
        return
    end

    if framework == 'qbox' then
        if lib and lib.notify then
            lib.notify({
                description = message,
                type = notifyType or 'inform'
            })
            return
        end

        if GetResourceState('qb-core') == 'started' then
            QBCore = QBCore or exports['qb-core']:GetCoreObject()
            QBCore.Functions.Notify(message, notifyType or 'primary')
            return
        end
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local netId = NetworkGetNetworkIdFromEntity(vehicle)

            if engineLockedOff[netId] then
                SetVehicleEngineOn(vehicle, false, true, true)
                SetVehicleUndriveable(vehicle, true)
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

RegisterCommand(Config.Command, function()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        notify(Config.Messages.notInVehicle, 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        notify(Config.Messages.notDriver, 'error')
        return
    end

    -- avoid repeated requests while waiting for the server.
    local now = GetGameTimer()

    if pending or now - lastRequest < 750 then
        return
    end

    pending = true
    lastRequest = now

    TriggerServerEvent(
        'cdion_enginetoggle:server:request',
        NetworkGetNetworkIdFromEntity(vehicle)
    )

    -- prevents a lost response from blocking the command.
    SetTimeout(5000, function()
        pending = false
    end)
end, false)

RegisterKeyMapping(
    Config.Command,
    'Toggle vehicle engine (owner only)',
    'keyboard',
    Config.Key
)

RegisterNetEvent('cdion_enginetoggle:client:result', function(success, result)
    pending = false

    if not success then
        local message = Config.Messages[result] or Config.Messages.notOwner
        notify(message, 'error')
        return
    end

    local netId = result
    local vehicle = NetToVeh(netId)
    local ped = PlayerPedId()

    -- re-validate the veh after response
    if vehicle == 0
        or not DoesEntityExist(vehicle)
        or GetVehiclePedIsIn(ped, false) ~= vehicle
        or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return
    end

    local engineOn = GetIsVehicleEngineRunning(vehicle)

    if engineOn then
        engineLockedOff[netId] = true

        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleUndriveable(vehicle, true)

        notify(Config.Messages.engineOff, 'success')
    else
        engineLockedOff[netId] = nil

        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, true)

        notify(Config.Messages.engineOn, 'success')
    end
end)
