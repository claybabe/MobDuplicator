-- =========================================================================
-- Mob Duplicator : Menu
--
-- Dynamically build UI based on number of Outcomes
-- Add/Remove Outcomes
-- Edit Outcome/Tickets
-- Change Cooldown
--
-- =========================================================================

local config = require("MobDuplicator.config")
local log = require("MobDuplicator.log")

local function onModConfigReady()
  local template = mwse.mcm.createTemplate({name = "MobDuplicator"})
  template:saveOnClose("MobDuplicator", config)
  template:register()

  local page = template:createSideBarPage({label = "Settings"})
  page.sidebar:createCategory("MobDuplicator")
  page.sidebar:createInfo({text = "Allows a leveled creature spawner to potentially spawn more than one creature.\n\n"})

  page.sidebar:createCategory("Cooldown")
  page.sidebar:createInfo({text = "Hours of in-game time. Spawners that reload before the cooldown will not roll for dupes.\n\n"})

  page.sidebar:createCategory("Outcomes and Tickets")
  page.sidebar:createInfo({text = "The Outcome chosen will have that many additional spawns created.\nMore tickets increase chance to be chosen.\n\n\n\n"})

  page.sidebar:createCategory("Shoutout")
  page.sidebar:createInfo({text = "nullcascade\nmerlord\ntwitch.tv/mojorising\ntwitch.tv/literallygambling"})

  local function update()
    event.trigger("MobDuplicator:Rebuild")
    template:clickTab(page)
    template:clickTab(page) -- seems like a bug, but we have to do this twice.
  end

  local function drawItems()
    local block = page:createSideBySideBlock()
    block:createInfo({text = " "})
    block:createTextField({
      label = "Cooldown",
      numbersOnly = true,
      variable = mwse.mcm.createTableVariable{id = "cooldown", table = config, converter = tonumber},
      callback = update,
    })
    block:createInfo({text = " "})
    block:createInfo({text = " "}) -- empty info for alignment.

    local block = page:createSideBySideBlock()
    block:createInfo({text = "Outcome"})
    block:createInfo({text = "Tickets"})
    block:createInfo({text = "Remove"})

    for i, entry in ipairs(config.dist) do
      local block = page:createSideBySideBlock()
      
      block:createTextField({
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable{id = "outcome", table = entry , converter = tonumber},
        callback = update,
      })

      block:createTextField({
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable{id = "tickets", table = entry, converter = tonumber},
        callback = update,
      })

      block:createButton({
        buttonText = "X",
        callback = function()
          table.remove(config.dist, i)
          if next(config.dist) == nil then
            table.insert(config.dist, {outcome = 0, tickets = 1})
          end
          update()
        end
      })
    end

    page:createButton({
      buttonText = "Add new Outcome",
      callback = function()
        table.insert(config.dist, {outcome = 0, tickets = 1})
        update()
      end
    })

  end

  page.postCreate = function(self)
    self.components = {}
    drawItems()
  end

  drawItems()
end

event.register(tes3.event.modConfigReady, onModConfigReady)
