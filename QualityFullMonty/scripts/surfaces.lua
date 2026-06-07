local entities = require("scripts.entities")
local inventories = require("scripts.inventories")
local players = require("scripts.players")
local prototypes_lib = require("scripts.prototypes")

local surfaces = {}

local function remove_surface_beacons(surface)
  for _, beacon in pairs(surface.find_entities_filtered({ type = "beacon" })) do
    entities.remove_beacon(beacon)
  end
end

local function fill_surface_modules(surface)
  local types = prototypes_lib.candidate_type_list()
  if #types == 0 then
    return
  end

  for _, entity in pairs(surface.find_entities_filtered({ type = types })) do
    entities.fill_modules(entity)
  end
end

local function scrub_surface_storage(surface)
  for _, entity in pairs(surface.find_entities_filtered({ type = inventories.storage_entity_types() })) do
    inventories.remove_from_entity_storage(entity)
  end
end

function surfaces.scan_surface(surface)
  remove_surface_beacons(surface)
  fill_surface_modules(surface)
  scrub_surface_storage(surface)
end

function surfaces.scrub_storage_all()
  for _, surface in pairs(game.surfaces) do
    scrub_surface_storage(surface)
  end
end

function surfaces.scan_all()
  for _, surface in pairs(game.surfaces) do
    surfaces.scan_surface(surface)
  end

  players.scrub_all()
end

return surfaces
