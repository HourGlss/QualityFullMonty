local prototypes_lib = {}

local function effect_is_quality(name, effect)
  if name == "quality" then
    return true
  end

  return effect == "quality"
end

function prototypes_lib.allows_quality(prototype)
  for name, effect in pairs(prototype.allowed_effects or {}) do
    if effect_is_quality(name, effect) then
      return true
    end
  end

  return false
end

local function candidate_entity_types()
  local types = {}

  for _, prototype in pairs(prototypes.entity) do
    if (prototype.module_inventory_size or 0) > 0 and prototypes_lib.allows_quality(prototype) then
      types[prototype.type] = true
    end
  end

  return types
end

function prototypes_lib.candidate_type_list()
  local list = {}

  for entity_type in pairs(candidate_entity_types()) do
    table.insert(list, entity_type)
  end

  return list
end

return prototypes_lib
