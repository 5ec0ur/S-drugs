RegisterNetEvent('S-drugs:client:showDealerActionMenu', function(dealerId)
    
    local dealerData = Config.DrugDealers[dealerId]
    local dealerName = dealerData.label

    lib.registerContext({
        id = "S-drugs-dealer-action-menu",
        title = _U('MENU__DEALER'):format(dealerName),
        onExit = function()
            TriggerEvent('S-drugs:client:syncRestLoop', false)
        end,
        options = {
            {
                title = _U('MENU__DEALER__ACTION'),
            },
            {
                title = _U('MENU__DEALER__BUY'),
                description = _U('MENU__DEALER__BUY__DESC'),
                icon = "shopping-cart",
                arrow = true,
                event = "S-drugs:client:showDealerMenu",
                args = {dealerId = dealerId, action = 'sell'}
            },
            {
                title = _U('MENU__DEALER_SELL'),
                description = _U('MENU__DEALER__SELL_DESC'),
                icon = "coins",
                arrow = true,
                event = "S-drugs:client:showDealerMenu",
                args = {dealerId = dealerId, action = 'buy'}
            }
        }
    })

    TriggerEvent('S-drugs:client:syncRestLoop', true)
    lib.showContext("S-drugs-dealer-action-menu")
end)

RegisterNetEvent("S-drugs:client:showDealerMenu", function(args)
    local options = {}

    local dealerId = args.dealerId
    local action = args.action

    local dealerData = Config.DrugDealers[dealerId]
    local dealerName = dealerData.label


    if action == 'buy' then
        local buyItems = lib.callback.await('S-drugs:server:getDealerBuyItems', false, dealerId)

        for k, v in pairs(buyItems) do
            table.insert(options, {
                title = it.getItemLabel(k),
                description = _U('MENU__DEALER_SELL_ITEM__DESC'):format(it.getItemLabel(k), v.price),
                icon = "coins",
                arrow = true,
                event = "S-drugs:client:handleDealerInteraction",
                args = {item = k, price = v.price, dealerId = dealerId, action = 'sell'}
            })
        end

    elseif action == 'sell' then

        local sellItems = lib.callback.await('S-drugs:server:getDealerSellItems', false, dealerId)

        for k, v in pairs(sellItems) do
            table.insert(options, {
                title = it.getItemLabel(k),
                description = _U('MENU__DEALER_BUY_ITEM__DESC'):format(it.getItemLabel(k), v.price),
                icon = "coins",
                arrow = true,
                event = "S-drugs:client:handleDealerInteraction",
                args = {item = k, price = v.price, dealerId = dealerId, action = 'buy'}
            })
        end

    else
        ShowNotification(nil, _U('NOTIFICATION__INVALID__ACTION'), 'error')
        return
    end

    lib.registerContext({
        id = "S-drugs-dealer-menu",
        title = _U('MENU__DEALER'):format(dealerName),
        menu = 'S-drugs-dealer-action-menu',
        onBack = function()
            TriggerEvent('S-drugs:client:showDealerActionMenu', dealerId)
        end,
        onExit = function()
            TriggerEvent('S-drugs:client:syncRestLoop', false)
        end,
        options = options
    })

    TriggerEvent('S-drugs:client:syncRestLoop', true)
    lib.showContext("S-drugs-dealer-menu")
end)

-- ┌───────────────────────────────────────────────────┐
-- │ ____  _             _     __  __                  │
-- │|  _ \| | __ _ _ __ | |_  |  \/  | ___ _ __  _   _ │
-- │| |_) | |/ _` | '_ \| __| | |\/| |/ _ \ '_ \| | | |│
-- │|  __/| | (_| | | | | |_  | |  | |  __/ | | | |_| |│
-- │|_|   |_|\__,_|_| |_|\__| |_|  |_|\___|_| |_|\__,_|│
-- └───────────────────────────────────────────────────┘
-- Plant Menu

--[[
Plant Data:
{
        id = self.id,
        entity = self.entity,
        netId = self.netId,
        coords = self.coords,
        owner = self.owner,
        plantType = self.plantType,
        fertilizer = self.fertilizer,
        water = self.water,
        health = self.health,
        growtime = self.growtime,
        stage = self.stage
    }
]]

RegisterNetEvent("S-drugs:client:showPlantMenu", function(plantData)
    local plantName = Config.Plants[plantData.seed].label

    --TODO: Update the metadata to show the correct values
    if plantData.health == 0 then
        lib.registerContext({
            id = "S-drugs-dead-plant-menu",
            title = _U('MENU__DEAD__PLANT'),
            onExit = function()
                TriggerEvent('S-drugs:client:syncRestLoop', false)
            end,
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        _U('MENU__PLANT__LIFE__META')
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                        _U('MENU__PLANT__STAGE__META')
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        _U('MENU__PLANT__FERTILIZER__META')
                    },
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange"
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        _U('MENU__PLANT__WATER__META')
                    },
                    progress = math.floor(plantData.water),
                    colorScheme = "blue"
                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    icon = "fire",
                    arrow = true,
                    event = "S-drugs:client:destroyPlant",
                    args = {plantData = plantData}
                }
            }
        })
        lib.showContext("S-drugs-dead-plant-menu")
        TriggerEvent('S-drugs:client:syncRestLoop', true)
        return
    elseif plantData.growth == 100 then
        lib.registerContext({
            id = "S-drugs-harvest-plant-menu",
            title = _U('MENU__PLANT'):format(plantName),
            onExit = function()
                TriggerEvent('S-drugs:client:syncRestLoop', false)
            end,
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        _U('MENU__PLANT__LIFE__META')
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                       _U('MENU__PLANT__STAGE__META')
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        _U('MENU__PLANT__FERTILIZER__META')
                    },
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange"
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        _U('MENU__PLANT__WATER__META')
                    },
                    progress = math.floor(plantData.water),
                    colorScheme = "blue"
                },
                {
                    title = _U('MENU__PLANT__HARVEST'),
                    icon = "scissors",
                    description = _U('MENU__PLANT__HARVEST__DESC'),
                    arrow = true,
                    event = "S-drugs:client:harvestPlant",
                    args = {plantData = plantData}

                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    icon = "fire",
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    arrow = true,
                    event = "S-drugs:client:destroyPlant",
                    args = {plantData = plantData}
                }
            }
        })
        lib.showContext("S-drugs-harvest-plant-menu")
        TriggerEvent('S-drugs:client:syncRestLoop', true)
    
    else
        lib.registerContext({
            id = "S-drugs-plant-menu",
            title = _U('MENU__PLANT'):format(plantName),
            onExit = function()
                TriggerEvent('S-drugs:client:syncRestLoop', false)
            end,
            options = {
                {
                    title = _U('MENU__PLANT__LIFE'),
                    icon = "notes-medical",
                    description = math.floor(plantData.health).. '%',
                    metadata = {
                        _U('MENU__PLANT__LIFE__META')
                    },
                    progress = math.floor(plantData.health),
                    colorScheme = "red",
                },
                {
                    title = _U('MENU__PLANT__STAGE'),
                    description = math.floor(plantData.growth).. '%',
                    icon = "seedling",
                    metadata = {
                        _U('MENU__PLANT__STAGE__META')
                    },
                    progress = math.floor(plantData.growth),
                    colorScheme = "green"
                },
                {
                    title = _U('MENU__PLANT__FERTILIZER'),
                    description = math.floor(plantData.fertilizer).. '%',
                    icon = "bucket",
                    metadata = {
                        _U('MENU__PLANT__FERTILIZER__META')
                    },
                    arrow = true,
                    progress = math.floor(plantData.fertilizer),
                    colorScheme = "orange",
                    event = "S-drugs:client:showItemMenu",
                    args = {plantData = plantData, eventType = "fertilizer"}
                },
                {
                    title = _U('MENU__PLANT__WATER'),
                    description = math.floor(plantData.water).. '%',
                    icon = "droplet",
                    metadata = {
                        _U('MENU__PLANT__WATER__META')
                    },
                    arrow = true,
                    progress = math.floor(plantData.water),
                    colorScheme = "blue",
                    event = "S-drugs:client:showItemMenu",
                    args = {plantData = plantData, eventType = "water"}
                },
                {
                    title = _U('MENU__PLANT__DESTROY'),
                    icon = "fire",
                    description = _U('MENU__PLANT__DESTROY__DESC'),
                    arrow = true,
                    event = "S-drugs:client:destroyPlant",
                    args = {plantData = plantData}
                }
            }
        })
        lib.showContext("S-drugs-plant-menu")
        TriggerEvent('S-drugs:client:syncRestLoop', true)
    end
end)

RegisterNetEvent('S-drugs:client:showItemMenu', function(data)
    local eventType = data.eventType

    local options = {}
    if eventType == 'water' then
        for item, itemData in pairs(Config.Items) do
            if it.hasItem(item, 1) and itemData.water ~= 0 then
                table.insert(options, {
                    title = it.getItemLabel(item),
                    description = _U('MENU__ITEM__DESC'),
                    metadata = {
                        {label = _U('MENU__PLANT__WATER'), value = itemData.water},
                        {label = _U('MENU__PLANT__FERTILIZER'), value = itemData.fertilizer}
                    },
                    arrow = true,
                    event = 'S-drugs:client:useItem',
                    args = {plantData = data.plantData, item = item}
                })
            end
        end
    elseif eventType == 'fertilizer' then
        for item, itemData in pairs(Config.Items) do
            if it.hasItem(item, 1) and itemData.fertilizer ~= 0 then
                table.insert(options, {
                    title = it.getItemLabel(item),
                    description = _U('MENU__ITEM__DESC'),
                    metadata = {
                        {label = _U('MENU__PLANT__WATER'), value = itemData.water},
                        {label = _U('MENU__PLANT__FERTILIZER'), value = itemData.fertilizer}
                    },
                    arrow = true,
                    event = 'S-drugs:client:useItem',
                    args = {plantData = data.plantData, item = item}
                })
            end
        end
    end
    if #options == 0 then
        ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), 'error')
        TriggerEvent('S-drugs:client:syncRestLoop', false)
        return
    end

    lib.registerContext({
        id = "S-drugs-item-menu",
        title = _U('MENU__ITEM'),
        onExit = function()
            TriggerEvent('S-drugs:client:syncRestLoop', false)
        end,
        options = options
    })

    lib.showContext("S-drugs-item-menu")
    TriggerEvent('S-drugs:client:syncRestLoop', true)
end)

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ ____                              _               __  __                  │
-- │|  _ \ _ __ ___   ___ ___  ___ ___(_)_ __   __ _  |  \/  | ___ _ __  _   _ │
-- │| |_) | '__/ _ \ / __/ _ \/ __/ __| | '_ \ / _` | | |\/| |/ _ \ '_ \| | | |│
-- │|  __/| | | (_) | (_|  __/\__ \__ \ | | | | (_| | | |  | |  __/ | | | |_| |│
-- │|_|   |_|  \___/ \___\___||___/___/_|_| |_|\__, | |_|  |_|\___|_| |_|\__,_|│
-- │                                           |___/                           │
-- └───────────────────────────────────────────────────────────────────────────┘
-- Processing Menu
RegisterNetEvent('S-drugs:client:showRecipesMenu', function(data)

    local tableId = data.tableId
    local recipes = lib.callback.await('S-drugs:server:getTableRecipes', false, tableId)

    if not recipes then
        ShowNotification(nil, _U('NOTIFICATION__NO__RECIPES'), 'error')
        return
    end

    local options = {}

    for recipeId, recipeData in pairs(recipes) do
        table.insert(options, {
            title = recipeData.label,
            description = _U('MENU__RECIPE__DESC'),
            icon = "flask",
            arrow = true,
            event = "S-drugs:client:showProcessingMenu",
            args = {tableId = tableId, recipeId = recipeId}
        })
    end

    table.insert(options, {
        title = _U('MENU__TABLE__REMOVE'),
        icon = "ban",
        description = _U('MENU__TABLE__REMOVE__DESC'),
        arrow = true,
        event = "S-drugs:client:removeTable",
        args = {tableId = tableId}
    })

    lib.registerContext({
        id = "S-drugs-recipes-menu",
        title = _U('MENU__PROCESSING'),
        onExit = function()
            TriggerEvent('S-drugs:client:syncRestLoop', false)
        end,
        options = options
    })

    TriggerEvent('S-drugs:client:syncRestLoop', true)
    lib.showContext("S-drugs-recipes-menu")

end)

RegisterNetEvent("S-drugs:client:showProcessingMenu", function(data)

    local recipe = lib.callback.await('S-drugs:server:getRecipeById', false, data.tableId, data.recipeId)

    local options = {}
    if not recipe.showIngrediants then
        for _, v in pairs(recipe.ingrediants) do
            -- Menu only shows the amount not the name of the item
            table.insert(options, {
                title = _U('MENU__UNKNOWN__INGREDIANT'),
                description = _U('MENU__INGREDIANT__DESC'):format(v.amount),
                icon = "flask",
            })
        end
    else
        for k, v in pairs(recipe.ingrediants) do
            table.insert(options, {
                title = it.getItemLabel(k),
                description = _U('MENU__INGREDIANT__DESC'):format(v.amount), --:replace("{amount}", v),
                icon = "flask",
            })
        end
    end

    table.insert(options, {
        title = _U('MENU__TABLE__PROCESS'),
        icon = "play",
        description = _U('MENU__TABLE__PROCESS__DESC'),
        arrow = true,
        event = "S-drugs:client:processDrugs",
        args = {tableId = data.tableId, recipeId = data.recipeId}
    })

    lib.registerContext({
        id = "S-drugs-processing-menu",
        title = recipe.label,
        options = options,
        menu = 'S-drugs-recipes-menu',
        onBack = function()
            TriggerEvent('S-drugs:client:showRecipesMenu', {tableId = data.tableId})
        end,
        onExit = function()
            TriggerEvent('S-drugs:client:syncRestLoop', false)
        end,
    })
    TriggerEvent('S-drugs:client:syncRestLoop', true)
    lib.showContext("S-drugs-processing-menu")
end)

-- ┌──────────────────────────────────────────┐
-- │ ____       _ _   __  __                  │
-- │/ ___|  ___| | | |  \/  | ___ _ __  _   _ │
-- │\___ \ / _ \ | | | |\/| |/ _ \ '_ \| | | |│
-- │ ___) |  __/ | | | |  | |  __/ | | | |_| |│
-- │|____/ \___|_|_| |_|  |_|\___|_| |_|\__,_|│
-- └──────────────────────────────────────────┘
-- Sell Menu

RegisterNetEvent("S-drugs:client:showSellMenu", function(data)
    local item = data.item
    local amount = data.amount
    local price = data.price
    local ped = data.entity

    local itemLabel = it.getItemLabel(item)

    lib.registerContext({
        id = "S-drugs-sell-menu",
        title = _U('MENU__SELL'),
        options = {
            {
                title = _U('MENU__SELL__DEAL'),
                description = _U('MENU__SELL__DESC'):format(itemLabel, amount, amount * price),
                icon = "coins",
            },
            {
                title = _U('MENU__SELL__ACCEPT'),
                icon = "circle-check",
                description = _U('MENU__SELL__ACCEPT__DESC'),
                arrow = true,
                event = "S-drugs:client:salesInitiate",
                args = {type = 'buy', item = item, price = price, amount = amount, tped = ped}
            },
            {
                title = _U('MENU__SELL__REJECT'),
                icon = "circle-xmark",
                description = _U('MENU__SELL__REJECT__DESC'),
                arrow = true,
                event = "S-drugs:client:salesInitiate",
                args = {type = 'close', tped = ped}
            }
        }
    })
    lib.showContext("S-drugs-sell-menu")
end)

-- ┌──────────────────────────────────────────────────────────┐
-- │    _       _           _         __  __                  │
-- │   / \   __| |_ __ ___ (_)_ __   |  \/  | ___ _ __  _   _ │
-- │  / _ \ / _` | '_ ` _ \| | '_ \  | |\/| |/ _ \ '_ \| | | |│
-- │ / ___ \ (_| | | | | | | | | | | | |  | |  __/ | | | |_| |│
-- │/_/   \_\__,_|_| |_| |_|_|_| |_| |_|  |_|\___|_| |_|\__,_|│
-- └──────────────────────────────────────────────────────────┘

local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

RegisterNetEvent('S-drugs:client:showMainAdminMenu', function(data)

    local menuType = data.menuType
    if menuType == 'plants' then
        local allPlants = lib.callback.await('S-drugs:server:getPlants', false)
        local plantCount = tablelength(allPlants)

        lib.registerContext({
            id = "S-drugs-admin-main-menu-plants",
            title = _U('MENU__ADMIN__PLANT__MAIN'),
            options = {
                {
                    title = _U('MENU__PLANT__COUNT'),
                    description = _U('MENU__PLANT__COUNT__DESC'):format(plantCount),
                    icon = "seedling",
                },
                {
                    title = _U('MENU__LIST__PLANTS'),
                    description = _U('MENU__LIST__PLANTS__DESC'),
                    icon = "list",
                    arrow = true,
                    event = "S-drugs:client:generatePlantListMenu",
                },
                {
                    title = _U('MENU__ADD__BLIPS'),
                    description = _U('MENU__ADD__PLANT__BLIPS__DESC'),
                    icon = "map-location-dot",
                    arrow = true,
                    event = "S-drugs:client:addAllAdminBlips",
                    args = {type = 'plants'}
                },
                {
                    title = _U('MENU__REMOVE__BLIPS'),
                    description = _U('MENU__REMOVE__PLANT__BLIPS__DESC'),
                    icon = "eraser",
                    arrow = true,
                    event = "S-drugs:client:removeAllAdminBlips",
                    args = {type = 'plants'}
                },
            }
        })
        lib.showContext("S-drugs-admin-main-menu-plants")
    elseif menuType == 'tables' then
        local allTables = lib.callback.await('S-drugs:server:getTables', false)
        local tableCount = tablelength(allTables)

        lib.registerContext({
            id = "S-drugs-admin-main-menu-tables",
            title = _U('MENU__ADMIN__TABLE__MAIN'),
            options = {
                {
                    title = _U('MENU__TABLE__COUNT'),
                    description = _U('MENU__TABLE__COUNT__DESC'):format(tableCount),
                    icon = "flask-vial",
                },
                {
                    title = _U('MENU__LIST__TABLES'),
                    description = _U('MENU__LIST__TABLES__DESC'),
                    icon = "list",
                    arrow = true,
                    event = "S-drugs:client:generateTableListMenu",
                },
                {
                    title = _U('MENU__ADD__BLIPS'),
                    description = _U('MENU__ADD_TABLE__BLIPS__DESC'),
                    icon = "map-location-dot",
                    arrow = true,
                    event = "S-drugs:client:addAllAdminBlips",
                    args = {type = 'tables'}
                },
                {
                    title = _U('MENU__REMOVE__BLIPS'),
                    description = _U('MENU__REMOVE__TABLE__BLIPS__DESC'),
                    icon = "eraser",
                    arrow = true,
                    event = "S-drugs:client:removeAllAdminBlips",
                    args = {type = 'tables'}
                },
            }
        })
        lib.showContext("S-drugs-admin-main-menu-tables")
    end
end)

RegisterNetEvent('S-drugs:client:showPlantListMenu', function(data)

    local plantList = data.plantList

    local options = {}
    for _, v in ipairs(plantList) do
        table.insert(options, {
            title = v.label,
            description = _U('MENU__DIST'):format(it.round(v.distance, 2)),
            icon = "seedling",
            arrow = true,
            event = "S-drugs:client:showPlantAdminMenu",
            args = {plantData = v}
        })
    end

    lib.registerContext({
        id = "S-drugs-plant-list-menu",
        title = _U('MENU__PLANT__LIST'),
        menu = 'S-drugs-placeholder',
        onBack = function()
            Wait(5)
            TriggerEvent('S-drugs:client:showMainAdminMenu', {menuType = 'plants'})
        end,
        options = options
    })
    lib.showContext("S-drugs-plant-list-menu")
end)

RegisterNetEvent('S-drugs:client:showTableListMenu', function(data)
    
    local tableList = data.tableList

    local options = {}
    for _, v in ipairs(tableList) do
        table.insert(options, {
            title = v.label,
            description = _U('MENU__DIST'):format(it.round(v.distance, 2)),
            icon = "flask-vial",
            arrow = true,
            event = "S-drugs:client:showTableAdminMenu",
            args = {tableData = v}
        })
    end

    lib.registerContext({
        id = "S-drugs-table-list-menu",
        title = _U('MENU__TABLE__LIST'),
        menu = 'S-drugs-placeholder',
        onBack = function()
            TriggerEvent('S-drugs:client:showMainAdminMenu', {menuType = 'tables'})
        end,
        options = options
    })
    lib.showContext("S-drugs-table-list-menu")
end)

RegisterNetEvent('S-drugs:client:showPlantAdminMenu', function(data)
    local plantData = data.plantData
    local streetNameHash, _ = GetStreetNameAtCoord(plantData.coords.x, plantData.coords.y, plantData.coords.z)
    local streetName = GetStreetNameFromHashKey(streetNameHash)

    lib.registerContext({
        id = "S-drugs-plant-admin-menu",
        title = _U('MENU__PLANT__ID'):format(plantData.id),
        menu = 'S-drugs-placeholder',
        onBack = function()
            TriggerEvent('S-drugs:client:generatePlantListMenu')
        end,
        options = {
            {
                title = _U('MENU__OWNER'),
                description = plantData.owner,
                icon = "user",
                metadata = {
                    _U('MENU__OWNER__META')
                },
                onSelect = function()
                    lib.setClipboard(plantData.owner)
                    ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format(plantData.owner), 'success')
                end
            },
            {
                title = _U('MENU__PLANT__LOCATION'),
                description = _U('MENU__LOCATION__DESC'):format(streetName, plantData.coords.x, plantData.coords.y, plantData.coords.z),
                metadata = {
                    _U('MENU__LOCATION__META')
                },
                icon = "map-marker",
                onSelect = function()
                    lib.setClipboard('('..plantData.coords.x..", "..plantData.coords.y..", "..plantData.coords.z..')')
                    ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format('('..plantData.coords.x..", "..plantData.coords.y..", "..plantData.coords.z..')'), 'success')
                end
            },
            {
                title = _U('MENU__PLANT__TELEPORT'),
                description = _U('MENU__PLANT__TELEPORT__DESC'),
                icon = "route",
                arrow = true,
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), plantData.coords.x, plantData.coords.y, plantData.coords.z)
                    ShowNotification(nil, _U('NOTIFICATION__TELEPORTED'), 'success')
                end
            },
            {
                title = _U('MENU__ADD__BLIP'),
                description = _U('MENU__ADD__PLANT__BLIP__DESC'),
                icon = "map-location-dot",
                arrow = true,
                event = "S-drugs:client:addAdminBlip",
                args = {id = plantData.id, coords = plantData.coords, entityType = plantData.type, type = 'plant'}
            },
            {
                title = _U('MENU__PLANT__DESTROY'),
                description = _U('MENU__PLANT__DESTROY__DESC'),
                icon = "fire",
                arrow = true,
                onSelect = function()
                    TriggerServerEvent('S-drugs:server:destroyPlant', {plantId = plantData.id, extra='admin'})
                    ShowNotification(nil, _U('NOTIFICATION__PLANT__DESTROYED'), 'success')
                end
            }
        }
    })
    lib.showContext("S-drugs-plant-admin-menu")
end)

RegisterNetEvent('S-drugs:client:showTableAdminMenu', function(data)
    local tableData = data.tableData
    local streetNameHash, _ = GetStreetNameAtCoord(tableData.coords.x, tableData.coords.y, tableData.coords.z)
    local streetName = GetStreetNameFromHashKey(streetNameHash)

    lib.registerContext({
        id = "S-drugs-table-admin-menu",
        title = _U('MENU__TABLE__ID'):format(tableData.id),
        menu = 'S-drugs-placeholder',
        onBack = function()
            TriggerEvent('S-drugs:client:generateTableListMenu')
        end,
        options = {
            {
                title = _U('MENU__PLANT__LOCATION'),
                description = _U('MENU__LOCATION__DESC'):format(streetName, tableData.coords.x, tableData.coords.y, tableData.coords.z),
                metadata = {
                    _U('MENU__LOCATION__META')
                },
                icon = "map-marker",
                onSelect = function()
                    lib.setClipboard('('..tableData.coords.x..", "..tableData.coords.y..", "..tableData.coords.z..')')
                    ShowNotification(nil, _U('NOTIFICATION__COPY__CLIPBOARD'):format('('..tableData.coords.x..", "..tableData.coords.y..", "..tableData.coords.z..')'), 'success')
                end
            },
            {
                title = _U('MENU__TABLE__TELEPORT'),
                description = _U('MENU__TABLE__TELEPORT__DESC'),
                icon = "route",
                arrow = true,
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), tableData.coords.x, tableData.coords.y, tableData.coords.z)
                    ShowNotification(nil, _U('NOTIFICATION__TELEPORTED'), 'success')
                end
            },
            {
                title = _U('MENU__ADD__BLIP'),
                description = _U('MENU__ADD__TABLE__BLIP__DESC'),
                icon = "map-location-dot",
                arrow = true,
                event = "S-drugs:client:addAdminBlip",
                args = {id = tableData.id, coords = tableData.coords, entityType = tableData.type, type = 'table'}
            },
            {
                title = _U('MENU__TABLE__DESTROY'),
                description = _U('MENU__TABLE__DESTROY__DESC'),
                icon = "trash",
                arrow = true,
                onSelect = function()
                    TriggerServerEvent('S-drugs:server:removeTable', {tableId = tableData.id, extra='admin'})
                    ShowNotification(nil, _U('NOTIFICATION__TABLE__DESTROYED'), 'success')
                end,
                
            }
        }
    })
    lib.showContext("S-drugs-table-admin-menu")
end)