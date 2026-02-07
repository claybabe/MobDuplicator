-- =========================================================================
-- Mob Duplicator : Default Config
--
-- Default configs contains very small chance of 99 spawns
-- 
-- =========================================================================

local defaultConfig = {
  logLevel = "DEBUG",
  cooldown = 259200,
  dist = {
    {outcome = 0, tickets = 15 }, 
    {outcome = 1, tickets = 40 }, 
    {outcome = 2, tickets = 30 },
    {outcome = 5, tickets = 14 },
    {outcome = 9, tickets = 1 },
    {outcome = 99, tickets = 0.01 },
  }
}

local config = mwse.loadConfig("MobDuplicator") or defaultConfig

return config
