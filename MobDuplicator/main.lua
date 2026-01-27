-- =========================================================================
-- Mob Duplicator : Main
--
-- This mod uses the Discrete Distribution Sampler (DDS, Vose's Alias Method)
-- to randomly spawn additional copies from spawners when they are loaded.
--
-- =========================================================================

local config = require("MobDuplicator.config")
local log = require("MobDuplicator.log")

local mobSampler
-- =========================================================================
-- 1. Discrete Distribution Sampler (DDS) Class
-- =========================================================================
local DDS = {}
DDS.__index = DDS

function DDS:new(dist)
  local self = setmetatable({}, DDS)
  local n = 0
  local sum_tickets = 0
  for _, entry in pairs(dist) do
    n = n + 1
    sum_tickets = sum_tickets + entry.tickets
  end
  self.n = n

  local small = {}
  local large = {}

  for _, entry in pairs(dist) do
    local p = (entry.tickets / sum_tickets) * n
    if p < 1 then
      table.insert(small, {entry.outcome, p})
    else
      table.insert(large, {entry.outcome, p})
    end
  end

  local table_data = {}

  while #small > 0 and #large > 0 do
    local less = table.remove(small)
    local more = table.remove(large)
    table.insert(table_data, {less[2], less[1], more[1]})
    local remain = (more[2] + less[2]) - 1

    if remain < 1 then
      table.insert(small, {more[1], remain})
    else
      table.insert(large, {more[1], remain})
    end
  end

  while #large > 0 do
    local i = table.remove(large)
    table.insert(table_data, {1, i[1], i[1]})
  end
  while #small > 0 do
    local i = table.remove(small)
    table.insert(table_data, {1, i[1], i[1]})
  end

  self.table = table_data
  return self
end

function DDS:sample(r1, r2)
  if self.n == 0 then
    log:warn("Distribution is empty, returning 0 as outcome.")
    return 0
  end 

  local b_index = math.floor(r1 * self.n) + 1
  local bucket = self.table[b_index]

  if r2 > bucket[1] then
    return bucket[3]
  else
    return bucket[2]
  end
end

function DDS:roll()
  local r1 = math.random()
  local r2 = math.random()

  return tonumber(self:sample(r1, r2))
end

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

  local spawn = spawner.object:pickFrom()
  if (spawn == nil) then
    log:debug("No spawn, pick failed. [%s @ %s]", spawner, spawner.position)
    return
  end

  local roll = mobSampler:roll()
  if (roll <= 0) then
    log:debug("Rolled 0, no dupe. [%s @ %s]", spawner, spawner.position)
  end
  for i = 1, roll do
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
