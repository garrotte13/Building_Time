local shared = require("shared")

local script_data =
{
  building_finished = {},
  entity_smoke = {}
}


local insert = table.insert

local add_building_finished = function(tick, entity, unit_number)

  local buildings = script_data.building_finished[tick]
  if not buildings then
    buildings = {}
    script_data.building_finished[tick] = buildings
  end

  buildings[unit_number] = entity

end

local ceil = math.ceil
local max = math.max
local min = math.min

local on_built_entity = function(event)

  local entity = event.created_entity or event.entity
  if not (entity and entity.valid) then return end

  local unit_number = entity.unit_number
  if not unit_number then return end

  local health = entity.prototype.max_health
  if not (health and health > 0) then return end

  entity.health = 0
  local duration = ceil(1 + (health / shared.repair_rate)) * 60
  add_building_finished(event.tick + duration, entity, unit_number)
  entity.active = false

  local size = min(ceil((max(entity.get_radius() - 0.1, 0.25)) * 2), 10)
  local smoke = entity.surface.create_entity{name = "building-smoke-"..size, position = entity.position, force = entity.force}
  script_data.entity_smoke[unit_number] = smoke

end

local on_tick = function(event)
  local buildings = script_data.building_finished[event.tick]
  if not buildings then return end

  local entity_smoke = script_data.entity_smoke

  for unit_number, entity in pairs (buildings) do
    if entity and entity.valid then
      entity.active = true
      local smoke = entity_smoke[unit_number]
      if smoke and smoke.valid then
        smoke.destroy()
      end
      entity_smoke[unit_number] = nil
    end
  end

  script_data.building_finished[event.tick] = nil

end

local on_entity_removed = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end

  local unit_number = entity.unit_number
  if not unit_number then return end

  local smoke = script_data.entity_smoke[unit_number]
  if not smoke then return end

  script_data.entity_smoke[unit_number] = nil

  if smoke.valid then
    smoke.destroy()
  end

end

local lib = {}

lib.events =
{
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_robot_built_entity] = on_built_entity,
  [defines.events.script_raised_revive] = on_built_entity,
  [defines.events.script_raised_built] = on_built_entity,

  [defines.events.on_entity_died] = on_entity_removed,
  [defines.events.on_player_mined_entity] = on_entity_removed,
  [defines.events.on_robot_mined_entity] = on_entity_removed,
  [defines.events.script_raised_destroy] = on_entity_removed,

  [defines.events.on_tick] = on_tick,
}

lib.on_load = function()
  script_data = global.building_time or script_data
end

lib.on_init = function()
  global.building_time = global.building_time or script_data
end

return lib