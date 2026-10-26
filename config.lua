Config = {}

-- 'auto', 'esx', 'qbcore', 'qbox', 'standalone'
Config.Framework = 'auto' -- leave in auto

Config.Key = 'G' -- key to toggle the engine/motor
Config.Command = 'toggle_engine'

Config.Messages = {
    notDriver = 'You must be driving.',
    notOwner = 'This vehicle is not yours.',
    standalone = 'No ownership system is configured.',
    success = 'Engine status changed.',
    notInVehicle = 'You must be inside a vehicle.',
    engineOff = 'You have turned off the engine. Press G to start it again.',
    engineOn = 'You have started the engine.'
}

-- SQL Cfg
Config.Database = {
    ESX = { -- default ESX querys
        table = 'owned_vehicles',
        ownerColumn = 'owner',
        plateColumn = 'plate'
    },

    QB = { -- Default QB querys
        table = 'player_vehicles',
        ownerColumn = 'citizenid',
        plateColumn = 'plate'
    }
}
