local constants = require("scripts.constants")
local prototypes_lib = require("scripts.prototypes")
local state = require("scripts.state")

local entities = {}

function entities.is_valid(entity)
  return entity and entity.valid
end

local function module_inventory(entity)
  if not entities.is_valid(entity) then
    return nil
  end

  return entity.get_module_inventory()
end

function entities.should_manage(entity)
  local inventory = module_inventory(entity)
  return inventory and inventory.valid and #inventory > 0 and prototypes_lib.allows_quality(entity.prototype)
end

function entities.fill_modules(entity)
  if not entities.should_manage(entity) then
    return false
  end

  local inventory = module_inventory(entity)
  inventory.clear()

  for index = 1, #inventory do
    inventory[index].set_stack(constants.locked_module_stack)
  end

  state.remember_entity(entity)
  entities.clear_item_request_proxy(entity)
  return true
end

function entities.clear_modules(entity)
  if not entities.should_manage(entity) then
    return false
  end

  module_inventory(entity).clear()
  return true
end

function entities.clear_item_request_proxy(entity)
  if not entities.is_valid(entity) then
    return false
  end

  local proxy = entity.item_request_proxy
  if proxy and proxy.valid then
    proxy.destroy()
    return true
  end

  return false
end

function entities.clear_target_request_proxy(proxy)
  if not entities.is_valid(proxy) or proxy.type ~= "item-request-proxy" then
    return false
  end

  local target = proxy.proxy_target
  if entities.should_manage(target) then
    proxy.destroy()
    return true
  end

  return false
end

function entities.remove_beacon(entity)
  if entities.is_valid(entity) and entity.type == "beacon" then
    entity.destroy({ raise_destroy = true })
    return true
  end

  return false
end

function entities.handle_entity(entity)
  if not entities.is_valid(entity) then
    return
  end

  if entities.clear_target_request_proxy(entity) then
    return
  end

  if entities.remove_beacon(entity) then
    return
  end

  entities.fill_modules(entity)
end

return entities
