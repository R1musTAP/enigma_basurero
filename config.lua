Config = {}

Config.Blip = {
    coords = vector3(-354.26, -1545.89, 27.72), -- Ubicación del trabajo
    sprite = 318,
    color = 2,
    scale = 0.8,
    label = "Trabajo de Basurero"
}

Config.Ped = {
    model = "s_m_y_dockwork_01",
    coords = vector4(-354.26, -1545.89, 26.72, 270.0),
    scenario = "WORLD_HUMAN_CLIPBOARD"
}

Config.Vehicle = {
    model = "trash",
    spawnPoints = {
        vector4(-359.59, -1541.55, 27.72, 270.0),
        vector4(-362.59, -1541.55, 27.72, 270.0),
        vector4(-365.59, -1541.55, 27.72, 270.0),
    }
}

Config.Markers = {
    type = 1,
    size = vector3(1.5, 1.5, 1.0),
    color = vector4(0, 255, 0, 100)
}

Config.Routes = {
    [1] = {
        {coords = vector3(-364.39, -1864.71, 20.24)},
        {coords = vector3(-556.47, -1795.84, 22.54)},
        {coords = vector3(-675.98, -1750.64, 24.20)},
        -- Añadir más puntos según necesidad
    },
    [2] = {
        {coords = vector3(-978.28, -1580.02, 5.17)},
        {coords = vector3(-1040.95, -1473.63, 5.14)},
        {coords = vector3(-1207.54, -1309.25, 4.90)},
        -- Añadir más puntos según necesidad
    }
}

Config.Uniforms = {
    male = {
        ['tshirt_1'] = 59,
        ['tshirt_2'] = 0,
        ['torso_1'] = 56,
        ['torso_2'] = 0,
        ['arms'] = 30,
        ['pants_1'] = 31,
        ['pants_2'] = 0,
        ['shoes_1'] = 25,
        ['shoes_2'] = 0,
        ['helmet_1'] = -1,
        ['helmet_2'] = 0
    },
    female = {
        ['tshirt_1'] = 36,
        ['tshirt_2'] = 0,
        ['torso_1'] = 49,
        ['torso_2'] = 0,
        ['arms'] = 57,
        ['pants_1'] = 30,
        ['pants_2'] = 0,
        ['shoes_1'] = 25,
        ['shoes_2'] = 0,
        ['helmet_1'] = -1,
        ['helmet_2'] = 0
    }
}