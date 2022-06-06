function define_pet_food()
    api_define_item({
        id = "pet_food",
        name = "Pet Food",
        category = "Beekeeping",
        tooltip = "Food for your lil' frend",
        shop_key = false,
        shop_buy = 0,
        shop_sell = 0.1,
        singular = false
    }, "sprites/pet_food_item.png")

    local pet_food_recipe = {
        { item = "flower5", amount = 1 }
    }

    api_define_recipe("crafting", MOD_NAME .. "_pet_food", pet_food_recipe, 1)
end

function define_pet_bee_quest()
    local quest_def = {
        id = "pet_bee_quest",
        title = "Pet Bee",
        reqs = { "bee:domesticated@1" },
        icon = "pet_bee_pet_bee",
        reward = MOD_NAME .. "_pet_bee@1",
        unlock = {}
    }

    local quest_page1 = {
        { text = "Get a pet bee" },
        { text = "PET BEE", color = "FONT_BLUE" }
    }
    local quest_page2 = {
        { text = "Fuckin love bees" }
    }

    api_define_quest(quest_def, quest_page1, quest_page2)
end

function define_pet_bee()
    api_define_item({
        id = "pet_bee",
        name = "Pet Bee",
        category = "Beekeeping",
        tooltip = "Just a cute lil' frend",
        shop_key = true,
        shop_buy = 0,
        shop_sell = 0,
        singular = true
    }, "sprites/pet_bee_item.png")

    -- This menu object will be hidden offscreen and used
    -- only for its menu
    api_define_menu_object({
        id = "pet_bee_menu_obj",
        name = "Pet Bee",
        category = "Beekeeping",
        tooltip = "How did you get this?",
        shop_key = true,
        shop_buy = 0,
        shop_sell = 0,
        layout = {
            { 50, 88, "Input", { "pet_bee_pet_food" } },
            { 76, 88, "Output" }
        },
        buttons = { "Move", "Close" },
        info = {},
        tools = {},
        placeable = true,
        invisible = true,
        center = true
    }, "sprites/pet_bee_item.png", "sprites/pet_bee_menu.png", {
        define = "pet_menu_define",
        draw = "pet_menu_draw"
    })
end

function define_mod()
    api_define_notification("gift_ready", "toggle_pet_menu")
    api_define_sprite("pet_bee_display", "sprites/pet_bee_display.png", 44)
    define_pet_food()

    define_pet_bee()

    define_pet_bee_quest()
end
