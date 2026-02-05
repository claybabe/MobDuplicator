--begin global.lua
local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')

local DDS = require('DDS')

-- initializing sampler to always zero incase there is a delay upon loading
local mobSampler = DDS:new({{outcome = 0, tickets = 1}}) 

local spawnerCooldown = {}
local globalSettings = storage.globalSection("MobDuplicator_Global")

local function onObjectActive(obj)
    
  if not types.LevelledCreature.objectIsInstance(obj) then return end

  local currentTime = core.getSimulationTime()
  if spawnerCooldown[obj.id] and currentTime < spawnerCooldown[obj.id] then
    print(string.format("%s COOLDOWN [%s]", spawnerCooldown[obj.id] - currentTime, obj.recordId))
    return false
  end
  spawnerCooldown[obj.id] = currentTime + (globalSettings:get("cooldown") or 0)

  local playerLvl = types.Actor.stats.level(world.players[1]).current
  local record = types.LevelledCreature.record(obj.recordId)
  
  local roll = mobSampler:roll()
  print(string.format("ROLL: %s [%s]", roll, obj.recordId))
  for i = 1, roll do

    local spawnId = record:getRandomId(playerLvl)
    if spawnId == "" then -- WHY dont you just be nil instead?!
      print(" PICK FAILED")
      goto continue
    end
    local spawnCreature = types.Creature.record(spawnId)
    local name = spawnCreature.name
    print(string.format(" %s", name))

    -- Random small offset
    local offset = util.vector3(
      (math.random() - 0.5) * 500, -- +/- 250 units XY
      (math.random() - 0.5) * 500, 
      (math.random() * 20) + 5     -- 15 +/- 10 units Z 
    )
    local randomAngle = math.random() * math.pi * 2
    local randomOrientation = util.transform.rotateZ(randomAngle)

    local newMob = world.createObject(spawnId)
    newMob:teleport(obj.cell, obj.position + offset, randomOrientation)
    
    ::continue:: --goto lable for if pick fails
  end
end

local function onSave()
  local currentTime = core.getSimulationTime()
  local cleaned = 0
  for id, cooldown in pairs(spawnerCooldown) do
    if cooldown < currentTime then
      spawnerCooldown[id] = nil
      cleaned = cleaned + 1
    end
  end
  print(string.format("CLEANED: %s", cleaned))

  return {
    spawnerCooldown = spawnerCooldown
  }
end

local function onLoad(data)
  print("LOADING")
  local cd = globalSettings:get("cooldown")
  if cd == nil then
    print("REQUESTING COOLDOWN")
    print(globalSettings:get("cooldown"))
    world.players[1]:sendEvent("requestCooldown")

  end
  if data and data.spawnerCooldown then
    spawnerCooldown = data.spawnerCooldown
  else
    spawnerCooldown = {}
  end
end

local function updateCooldown(cooldown)
  globalSettings:set("cooldown", cooldown)
  print(string.format("updated cooldown: %s", cooldown))
end

local function rebuildDDS(dist)
  print("rebuildingDDS")
  for k, v in pairs(dist) do
    print(string.format("outcome : %s  tickets : %s", v.outcome, v.tickets))
  end
  mobSampler = DDS:new(dist)
end

return {
  eventHandlers = {
    updateCooldown = updateCooldown,
    rebuildDDS = rebuildDDS,
  },
  engineHandlers = {
    onObjectActive = onObjectActive,
    onSave = onSave,
    onLoad = onLoad,
  }
}
--end global.lua