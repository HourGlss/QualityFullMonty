local constants = require("scripts.constants")
local entities = require("scripts.entities")

local players = {}

local function scrub_stack(stack)
  if stack and stack.valid_for_read and stack.name == constants.locked_module_name then
    stack.clear()
  end
end

local function scrub_inventory(inventory)
  if inventory and inventory.valid then
    inventory.remove({ name = constants.locked_module_name, count = 4294967295 })
  end
end

function players.scrub_player(player)
  if not player or not player.valid then
    return
  end

  scrub_stack(player.cursor_stack)
  scrub_inventory(player.get_main_inventory())
  scrub_inventory(player.get_inventory(defines.inventory.character_trash))
end

function players.scrub_all()
  for _, player in pairs(game.players) do
    players.scrub_player(player)
  end
end

function players.remove_dropped_locked_item(entity)
  if not entities.is_valid(entity) then
    return
  end

  local stack = entity.stack
  if stack and stack.valid_for_read and stack.name == constants.locked_module_name then
    entity.destroy()
  end
end

return players

