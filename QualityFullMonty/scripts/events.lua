local constants = require("scripts.constants")
local entities = require("scripts.entities")
local players = require("scripts.players")
local reconcile = require("scripts.reconcile")
local state = require("scripts.state")
local surfaces = require("scripts.surfaces")

local events = {}

local function on_entity_event(event)
  entities.handle_entity(event.created_entity or event.entity or event.destination)
end

local function on_mined_entity(event)
  state.forget_entity(event.entity and event.entity.unit_number)
  players.scrub_all()
end

local function on_player_inventory_event(event)
  players.scrub_player(game.get_player(event.player_index))
end

local function on_dropped_item(event)
  players.remove_dropped_locked_item(event.entity)
end

local function on_reconcile_tick()
  reconcile.known_entities()
  players.scrub_all()
end

local function register_event(event_name, handler)
  local event_id = defines.events[event_name]
  if event_id then
    script.on_event(event_id, handler)
  end
end

local function register_entity_events()
  register_event("on_built_entity", on_entity_event)
  register_event("on_robot_built_entity", on_entity_event)
  register_event("script_raised_built", on_entity_event)
  register_event("script_raised_revive", on_entity_event)
  register_event("on_entity_cloned", on_entity_event)
end

local function register_inventory_events()
  register_event("on_player_cursor_stack_changed", on_player_inventory_event)
  register_event("on_player_main_inventory_changed", on_player_inventory_event)
  register_event("on_player_quickbar_inventory_changed", on_player_inventory_event)
  register_event("on_player_dropped_item", on_dropped_item)
end

local function register_mining_events()
  register_event("on_robot_mined_entity", on_mined_entity)
  register_event("on_player_mined_entity", on_mined_entity)
  register_event("script_raised_destroy", on_mined_entity)
end

function events.register()
  script.on_init(function()
    state.get()
    surfaces.scan_all()
  end)

  script.on_configuration_changed(function()
    state.get()
    surfaces.scan_all()
  end)

  script.on_nth_tick(constants.reconcile_interval, on_reconcile_tick)
  register_entity_events()
  register_inventory_events()
  register_mining_events()
end

return events

