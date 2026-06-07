local state = {}

function state.get()
  storage.quality_full_monty = storage.quality_full_monty or {}

  local current = storage.quality_full_monty
  current.entities = current.entities or {}
  current.entity_order = current.entity_order or {}
  current.next_entity_index = current.next_entity_index or 1

  return current
end

function state.remember_entity(entity)
  if not entity.unit_number then
    return
  end

  local current = state.get()
  if not current.entities[entity.unit_number] then
    table.insert(current.entity_order, entity.unit_number)
  end

  current.entities[entity.unit_number] = entity
end

function state.forget_entity(unit_number)
  if unit_number then
    state.get().entities[unit_number] = nil
  end
end

return state

