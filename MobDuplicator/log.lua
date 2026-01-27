-- =========================================================================
-- Mob Duplicator : Logging
--
-- =========================================================================

local logger = require("logging.logger")
local config = require("MobDuplicator.config")

return logger.new({
  name = "MobDuplicator",
  logLevel = config.logLevel,
  logToConsole = false,
  includeTimestamp = false,
})
