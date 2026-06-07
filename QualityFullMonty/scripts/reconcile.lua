local constants = require("scripts.constants")
local entities = require("scripts.entities")
local state = require("scripts.state")

local reconcile = {}

local function reset_index(current)
  if current.next_entity_index > #current.entity_order then
    current.next_entity_index = 1
  end
end

local function reconcile_one(current)
  reset_index(current)

  local unit_number = current.entity_order[current.next_entity_index]
  local entity = current.entities[unit_number]

  if entities.is_valid(entity) then
    entities.fill_modules(entity)
    current.next_entity_index = current.next_entity_index + 1
    return
  end

  table.remove(current.entity_order, current.next_entity_index)
  state.forget_entity(unit_number)
end

function reconcile.known_entities()
  local current = state.get()
  local checked = 0

  while checked < constants.reconcile_batch_size and #current.entity_order > 0 do
    reconcile_one(current)
    checked = checked + 1
  end
end

return reconcile

