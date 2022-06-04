MOD_NAME = "pet_bee"
PET_MENU_ID = nil
PET_BEE_HUNGER_TICK = 1
PET_BEE_GIFT_TICK = 0.75

function register()
  return {
    name = MOD_NAME,
    hooks = { "click", "ready", "pdraw", "step" }
  }
end

function increment_counter(id, counter, amount)
  amount = amount or 1
  api_sp(id, counter, api_gp(id, counter) + amount)
  return api_gp(id, counter)
end

function draw_pixel(x, y, colour)
  api_draw_rectangle(x, y, x, y, colour, false)
end

PET_BEE_GIFT_TABLE = {
  { "acorn1", "log", "planks1", "stone", "acorn2" },
  { "beeswax", "glue", "sticks1", "waterproof", "beepollen" },
  { "honeydew", "planks2", "bottle", "propolis", "cog" },
  { "bottle", "sticks2", "treetap1", "waxypearl", "stickypearl" },
  { "charredpearl", "money", "royaljelly", "spice1", "spice2", "spice3", "spice4", "spice5" }
}

function give_gift(menu_id)
  -- Choose a random gift from the current bee level's table
  local gift = api_choose(PET_BEE_GIFT_TABLE[api_gp(menu_id, "bee_level")])

  -- Output that item
  api_slot_set(api_get_slot(menu_id, 2)["id"], gift, 1)

  -- Tell the player they've got a gift
  api_set_notification("pet_bee_gift_ready", "pet_bee_pet_bee", "You've got a gift!", "Your pet found something")
end

function update_map_bee_position(menu_id)
  local bee_pos = api_gp(menu_id, "map_bee_pos")
  local player_pos = api_get_player_position()

  if bee_pos == nil then
    -- Initialize bee position to where the player is
    bee_pos = { x = player_pos["x"], y = player_pos["y"] }
    api_sp(menu_id, "map_bee_pos", bee_pos)
    api_sp(menu_id, "map_bee_pos_count", 0)
  else

    local x_diff = bee_pos["x"] - player_pos["x"]
    local y_diff = bee_pos["y"] - player_pos["y"]
    local count = api_gp(menu_id, "map_bee_pos_count")
    local far_from_player = math.abs(x_diff) > 10 or math.abs(y_diff) > 10

    -- We do a random move every 10 frames
    -- But if we're far from the player, we move every two frames
    if count > 10 or (count > 2 and far_from_player) then
      api_sp(menu_id, "map_bee_pos_count", 0)

      if far_from_player then
        -- Only get hungrier if we're following the player
        increment_counter(menu_id, "bee_hunger", PET_BEE_HUNGER_TICK)

        -- Only increase the gift counter if the bee isn't hungry
        if (api_gp(menu_id, "bee_hunger") < 100) then
          local gift_count = increment_counter(menu_id, "bee_gift_count", PET_BEE_GIFT_TICK)
          if gift_count >= 100 then
            api_sp(menu_id, "bee_gift_count", 0)
            give_gift(menu_id)
          end
        end
      end

      -- Either walk randomly, or towards the player
      if math.abs(x_diff) > 10 then
        bee_pos["x"] = bee_pos["x"] - (x_diff / math.abs(x_diff))
      else
        bee_pos["x"] = bee_pos["x"] + api_random(2) - 1
      end

      -- Same for the y coordinate
      if math.abs(y_diff) > 10 then
        bee_pos["y"] = bee_pos["y"] - (y_diff / math.abs(y_diff))
      else
        bee_pos["y"] = bee_pos["y"] + api_random(2) - 1
      end
    else
      increment_counter(menu_id, "map_bee_pos_count")
    end
  end

  api_sp(menu_id, "map_bee_pos", bee_pos)
end

-- Draw the overworld pet bee on the player layer
function pdraw()
  -- Only draw the pet bee if the item is in the player's inventory
  if PET_MENU_ID ~= nil and pet_bee_in_inventory() then
    local bee_pos = api_gp(PET_MENU_ID, "map_bee_pos")

    draw_pixel(bee_pos["x"] + 1, bee_pos["y"], "FONT_WHITE")
    draw_pixel(bee_pos["x"] + 1, bee_pos["y"] + 1, "FONT_YELLOW")
    draw_pixel(bee_pos["x"], bee_pos["y"] + 1, "BLACK")
    draw_pixel(bee_pos["x"] + 2, bee_pos["y"] + 1, "BLACK")
  end
end

function step()
  update_map_bee_position(PET_MENU_ID)
end

function init()
  api_define_notification("gift_ready", "toggle_pet_menu")
  api_define_sprite("pet_bee_display", "sprites/pet_bee_display.png", 44)

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

  define_pet_bee_quest()

  api_set_devmode(true)
  return "Success"
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

function initialise_hidden_pet_bee_menu_obj()
  local pet = api_get_menu_objects(nil, MOD_NAME .. "_pet_bee_menu_obj")
  if (#pet == 0) then
    api_create_obj(MOD_NAME .. "_pet_bee_menu_obj", -32, -32);
  end
end

function ready()
  initialise_hidden_pet_bee_menu_obj()

  api_unlock_quest("pet_bee_quest")
end

-- Offset a position relative to some object to a global position
function local_pos_to_global(id, local_pos)
  local menu_inst = api_get_inst(id)
  local cam = api_get_cam()
  local menu_x = menu_inst["x"] - cam["x"]
  local menu_y = menu_inst["y"] - cam["y"]

  return { x = local_pos["x"] + menu_x, y = local_pos["y"] + menu_y }
end

function draw_pet_bee_display(menu_id)
  local display = api_get_sprite("sp_pet_bee_display")
  local pos = local_pos_to_global(menu_id, { x = 49, y = 16 })
  api_draw_sprite(display, api_get_counter("pet_display_counter"), pos["x"], pos["y"])
end

function get_display_bee_position(menu_id)
  local bee_pos = api_gp(menu_id, "menu_bee_pos")

  -- Move the bee once every 10 frames
  if api_gp(menu_id, "menu_bee_pos_count") > 10 then
    api_sp(menu_id, "menu_bee_pos_count", 0)

    -- Move a random pixel in the x and y directions
    local x_change = api_random(2) - 1
    local y_change = api_random(2) - 1
    bee_pos = { x = bee_pos["x"] + x_change, y = bee_pos["y"] + y_change }

    -- Push the bee back into the display if it goes out
    if bee_pos["y"] < 20 then bee_pos["y"] = 21 end
    if bee_pos["y"] > 55 then bee_pos["y"] = 54 end
    if bee_pos["x"] < 55 then bee_pos["x"] = 56 end
    if bee_pos["x"] > 75 then bee_pos["x"] = 74 end

    api_sp(menu_id, "menu_bee_pos", bee_pos)
  else
    increment_counter(menu_id, "menu_bee_pos_count")
  end

  return local_pos_to_global(menu_id, bee_pos)
end

function draw_display_bee(menu_id)
  local bee_pos = get_display_bee_position(menu_id)

  api_draw_rectangle(bee_pos["x"] + 4, bee_pos["y"], bee_pos["x"] + 7, bee_pos["y"] + 3, "FONT_WHITE", false)
  api_draw_rectangle(bee_pos["x"] + 4, bee_pos["y"] + 4, bee_pos["x"] + 7, bee_pos["y"] + 7, "FONT_YELLOW", false)
  api_draw_rectangle(bee_pos["x"], bee_pos["y"] + 4, bee_pos["x"] + 3, bee_pos["y"] + 7, "BLACK", false)
  api_draw_rectangle(bee_pos["x"] + 8, bee_pos["y"] + 4, bee_pos["x"] + 11, bee_pos["y"] + 7, "BLACK", false)
end

function draw_menu_text(menu_id)
  local steps_pos = local_pos_to_global(menu_id, { x = 9, y = 17 })
  local hunger_string = math.floor(api_gp(menu_id, "bee_hunger"))
  hunger_string = hunger_string > 100 and "100" or tostring(hunger_string)
  local level_string = tostring(math.floor(api_gp(menu_id, "bee_level")))
  level_string = level_string == "5" and "max" or level_string

  api_draw_text(steps_pos["x"], steps_pos["y"], "Hungr:", false, "FONT_BROWN")
  api_draw_text(steps_pos["x"], steps_pos["y"] + 10, hunger_string, false, "FONT_BROWN")
  api_draw_text(steps_pos["x"], steps_pos["y"] + 22, "Level:", false, "FONT_BROWN")
  api_draw_text(steps_pos["x"], steps_pos["y"] + 32, level_string, false, "FONT_BROWN")
end

function draw_menu_error(menu_id)
  if api_gp(menu_id, "bee_hunger") < 100 then
    api_sp(menu_id, "error", "Cannot feed pet when hunger is under 100")
    local input_slot_pos = local_pos_to_global(menu_id, { x = 50, y = 88 })
    api_draw_rectangle(input_slot_pos["x"], input_slot_pos["y"], input_slot_pos["x"] + 15, input_slot_pos["y"] + 15, "FONT_RED", false, 0.5)
  else
    api_sp(menu_id, "error", "")
  end
end

function pet_menu_draw(menu_id)
  draw_pet_bee_display(menu_id)
  draw_display_bee(menu_id)
  draw_menu_text(menu_id)
  draw_menu_error(menu_id)
end

function pet_menu_define(menu_id)
  PET_MENU_ID = menu_id
  local menu_obj = api_gp(menu_id, "obj")

  api_set_immortal(menu_obj, true)
  api_library_add_book("pet_bee_icon", "pet_bee_icon_click", "sprites/pet_bee_icon.png")

  api_dp(menu_id, "menu_bee_pos", { x = 66, y = 45 })
  api_dp(menu_id, "menu_bee_pos_count", 0)

  api_dp(menu_id, "map_bee_pos", nil)
  api_dp(menu_id, "map_bee_pos_count", 0)

  api_dp(menu_id, "bee_hunger", 0)
  api_dp(menu_id, "bee_level", 1)
  api_dp(menu_id, "bee_gift_count", 0)
  api_dp(menu_id, "bee_fed_times", 0)

  api_slot_set_modded(api_get_slot(menu_id, 1)["id"], true)
end

function toggle_pet_menu()
  local open = api_gp(PET_MENU_ID, "open")
  if open then
    api_toggle_menu(PET_MENU_ID, false)
  else
    api_create_counter("pet_display_counter", 0.5, 0, 44, 1)
    api_toggle_menu(PET_MENU_ID, true)
  end
end

function feed_bee(menu_id)
  local mouse = api_get_mouse_inst()
  api_slot_decr(mouse["id"], 1)

  api_sp(menu_id, "bee_hunger", 0)
  local fed_times = increment_counter(menu_id, "bee_fed_times")

  if fed_times == 10 then
    api_sp(menu_id, "bee_fed_times", 0)
    increment_counter(menu_id, "bee_level")
  end
end

function click(button, click_type)
  local mouse = api_get_mouse_inst()
  local highlight_slot = api_get_highlighted("slot")
  local highlight_menu = api_get_highlighted("menu")

  if highlight_slot ~= nil and click_type == "PRESSED" then
    if highlight_menu ~= nil and button == "LEFT" and api_gp(highlight_menu, "oid") == MOD_NAME .. "_pet_bee_menu_obj" then
      if mouse["item"] == MOD_NAME .. "_pet_food" then
        if api_gp(PET_MENU_ID, "bee_hunger") > 100 then
          feed_bee(PET_MENU_ID)
        end
      end
    end
    if button == "RIGHT" and api_gp(highlight_slot, "item") == MOD_NAME .. "_pet_bee" then
      toggle_pet_menu()
    end
  end
end

function pet_bee_in_inventory()
  local player_id = api_get_player_instance()
  local first_slot = api_slot_match(player_id, { MOD_NAME .. "_pet_bee" }, true)

  return first_slot ~= nil
end

function pet_bee_icon_click()
  if pet_bee_in_inventory() then
    toggle_pet_menu()
  else
    api_set_notification("notice", MOD_NAME .. "_pet_bee", "Pet bee not equipped", "Please equip her")
  end
end

function make_pet_bee(menu_id)
  api_create_obj(MOD_NAME .. "_pet_bee_menu_obj", -32, -32)

  local pets = api_get_menu_objects(nil, MOD_NAME .. "_pet_bee_menu_obj", nil)
  for _, pet in ipairs(pets) do
    local link_id = api_gp(pet["menu_id"], "pet_link_id")
    if link_id == nil then
      local new_menu_id = pet["menu_id"]
      local pet_link_value = "pet" .. #pets

      api_sp(new_menu_id, "pet_link_id", pet_link_value)
      local stats = { pet_link_id = pet_link_value }
      local mouse = api_get_mouse_inst()["id"]
      api_sp(mouse, "item", MOD_NAME .. "_pet_bee")
      api_sp(mouse, "count", 0)
      api_sp(mouse, "stats", stats)
      return
    end
  end
end
