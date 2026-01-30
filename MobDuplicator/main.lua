-- =========================================================================
-- Mob Duplicator : Main
--
-- This mod uses the Discrete Distribution Sampler (DDS, Vose's Alias Method)
-- to randomly spawn additional copies from spawners when they are loaded.
--
-- =========================================================================

local config = require("MobDuplicator.config")
local log = require("MobDuplicator.log")

local DDS = require("MobDuplicator.DDS")
local mobSampler

-- =========================================================================
-- 2. Reference Activated
-- =========================================================================
local function onReferenceActivated(e)
  local spawner = e.reference.leveledBaseReference
  if (spawner == nil or spawner.object.objectType ~= tes3.objectType.leveledCreature) then
    return
  end

  local currentHour = tes3.getGlobal('DaysPassed') * 24 + tes3.getGlobal('GameHour')
  local lastSpawn = spawner.data.lastSpawnTime
  if (lastSpawn ~= nil) then
    if (config.cooldown > (currentHour - lastSpawn)) then
      log:debug("Spawner cooling down. Time remaining: %s [%s @ %s]", config.cooldown - (currentHour - lastSpawn), spawner, spawner.position)
      return
    else
      log:debug("Cooldown complete, re-rolling.")
    end
  end
  spawner.data.lastSpawnTime = currentHour

  local roll = mobSampler:roll()
  if (roll <= 0) then
    log:debug("Rolled 0, no dupe. [%s @ %s]", spawner, spawner.position)
  end
  for i = 1, roll do

    local spawn = spawner.object:pickFrom()
    if (spawn == nil) then
      log:debug("No spawn, pick failed. [%s @ %s]", spawner, spawner.position)
      goto continue
    end

    local randomX = spawner.position.x + math.random(-128, 128)
    local randomY = spawner.position.y + math.random(-128, 128)
    local pos = tes3vector3.new(randomX, randomY, spawner.position.z + 10)
    local randomYaw = math.random() * math.pi * 2
    local ori = tes3vector3.new(spawner.orientation.x, spawner.orientation.y, randomYaw)

    local reference = tes3.createReference({
      object = spawn,
      cell = spawner.cell,
      position = pos,
      orientation = ori,
    })

    log:debug("Spawned (%s of %s) %s [%s @ %s]", i, roll, reference.baseObject, spawner.object, pos)

    ::continue:: -- goto lable for pick fail
  end
end

-- =========================================================================
-- 3. Rebuild
-- =========================================================================
local function onRebuild(e)
  mobSampler = DDS:new(config.dist)
end

-- =========================================================================
-- 4. Init
-- =========================================================================
mobSampler = DDS:new(config.dist)

event.register(tes3.event.referenceActivated, onReferenceActivated)
event.register("MobDuplicator:Rebuild", onRebuild)

dofile("MobDuplicator.mcm")
