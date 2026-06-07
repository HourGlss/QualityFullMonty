local constants = require("scripts.constants")

local inventories = {}

local storage_inventory_names = {
  "chest",
  "linked_container_main",
  "cargo_wagon",
  "car_trunk",
  "spider_trunk"
}

local storage_entity_types = {
  "container",
  "logistic-container",
  "linked-container",
  "infinity-container",
  "cargo-wagon",
  "infinity-cargo-wagon",
  "car",
  "spider-vehicle",
  "cargo-landing-pad",
  "space-platform-hub"
}

local function inventory_by_name(entity, inventory_name)
  local inventory_id = defines.inventory[inventory_name]
  if not inventory_id then
    return nil
  end

  return entity.get_inventory(inventory_id)
end

function inventories.remove_locked_from(inventory)
  if not inventory or not inventory.valid then
    return 0
  end

  local removed = 0
  for _, stack in pairs(inventory.get_contents()) do
    if stack.name == constants.locked_module_name then
      removed = removed + inventory.remove(stack)
    end
  end

  return removed
end

function inventories.remove_locked_stack(stack)
  if stack and stack.valid_for_read and stack.name == constants.locked_module_name then
    stack.clear()
  end
end

function inventories.remove_from_entity_storage(entity)
  local removed = 0

  for _, inventory_name in pairs(storage_inventory_names) do
    removed = removed + inventories.remove_locked_from(inventory_by_name(entity, inventory_name))
  end

  return removed
end

function inventories.storage_entity_types()
  return storage_entity_types
end

return inventories

