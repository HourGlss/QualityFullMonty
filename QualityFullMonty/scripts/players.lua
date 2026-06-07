local constants = require("scripts.constants")
local entities = require("scripts.entities")
local inventories = require("scripts.inventories")

local players = {}

local function scrub_stack(stack)
  inventories.remove_locked_stack(stack)
end

local function scrub_inventory(inventory)
  inventories.remove_locked_from(inventory)
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
