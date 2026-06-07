local locked_module_name = "qfm-locked-quality-module-3"

local function clone_locked_module()
  local source = data.raw.module["quality-module-3"]
  if not source then
    return
  end

  local locked = table.deepcopy(source)
  locked.name = locked_module_name
  locked.localised_name = { "item-name.quality-module-3" }
  locked.localised_description = { "item-description.quality-module" }
  locked.hidden = true
  locked.order = "z[quality-full-monty]-a[locked-quality-module-3]"

  data:extend({ locked })
end

local function collect_beacon_names()
  local names = {}
  for name, beacon in pairs(data.raw.beacon or {}) do
    names[name] = true
    beacon.hidden = true
    beacon.hidden_in_factoriopedia = true
  end
  return names
end

local function item_places_beacon(prototype, beacon_names)
  local place_result = prototype.place_result
  if not place_result then
    return false
  end

  return beacon_names[place_result]
end

local function hide_beacon_items(beacon_names)
  local items = {}
  for _, item_group in pairs(data.raw) do
    for name, prototype in pairs(item_group) do
      if item_places_beacon(prototype, beacon_names) then
        prototype.hidden = true
        prototype.place_result = nil
        items[name] = true
      end
    end
  end
  return items
end

local function product_name(product)
  if product.name then
    return product.name
  end
  return product[1]
end

local function recipe_result_is_beacon(recipe, item_names)
  if recipe.result and item_names[recipe.result] then
    return true
  end

  return false
end

local function recipe_products_include_beacon(recipe, item_names)
  for _, product in pairs(recipe.results or {}) do
    if item_names[product_name(product)] then
      return true
    end
  end

  return false
end

local function recipe_outputs_item(recipe, item_names)
  if recipe_result_is_beacon(recipe, item_names) then
    return true
  end

  return recipe_products_include_beacon(recipe, item_names)
end

local function disable_beacon_recipes(beacon_item_names)
  local recipes = {}
  for name, recipe in pairs(data.raw.recipe or {}) do
    if recipe_outputs_item(recipe, beacon_item_names) then
      recipe.enabled = false
      recipe.hidden = true
      recipes[name] = true
    end
  end
  return recipes
end

local function keep_non_beacon_unlocks(effects, beacon_recipe_names)
  local kept = {}
  for _, effect in pairs(effects or {}) do
    if effect.type ~= "unlock-recipe" or not beacon_recipe_names[effect.recipe] then
      table.insert(kept, effect)
    end
  end
  return kept
end

local function remove_beacon_unlocks(beacon_recipe_names)
  for _, technology in pairs(data.raw.technology or {}) do
    technology.effects = keep_non_beacon_unlocks(technology.effects, beacon_recipe_names)
  end
end

clone_locked_module()

local beacon_names = collect_beacon_names()
local beacon_item_names = hide_beacon_items(beacon_names)
local beacon_recipe_names = disable_beacon_recipes(beacon_item_names)

remove_beacon_unlocks(beacon_recipe_names)
