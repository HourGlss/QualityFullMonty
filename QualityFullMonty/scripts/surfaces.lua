local entities = require("scripts.entities")
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

function surfaces.scan_surface(surface)
  remove_surface_beacons(surface)
  fill_surface_modules(surface)
end

function surfaces.scan_all()
  for _, surface in pairs(game.surfaces) do
    surfaces.scan_surface(surface)
  end

  players.scrub_all()
end

return surfaces

