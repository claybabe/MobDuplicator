--begin player.lua
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local input = require('openmw.input')

local distribution = storage.playerSection("MobDuplicator_Distribution")
local playerSettings = storage.playerSection('Settings_MobDuplicator')

local function defaultOutcomes()
  return {
    {outcome = 0, tickets = 15 }, 
    {outcome = 1, tickets = 40 }, 
    {outcome = 2, tickets = 30 },
    {outcome = 5, tickets = 14 },
    {outcome = 9, tickets = 1 },
    {outcome = 99, tickets = 0.01 },
  }
end

local windowElement = nil
local createConfigWindow

-- STATE
local workingData

createConfigWindow = function()
  if windowElement then windowElement:destroy() end

  local rowsContent = {}
  
  -- Header labels for the table
  table.insert(rowsContent, {
    type = ui.TYPE.Flex,
    props = { horizontal = true },
    content = ui.content({
      -- Outcome Header
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.32, 0.32, 0.32), size = util.vector2(150, 30) },
        content = ui.content({{
          type = ui.TYPE.Text,
          props = { text = "Outcome", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(0, 0, 0)},
          
        }})
      },
      { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
      -- Tickets Header
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.32, 0.32, 0.32), size = util.vector2(150, 30) },
        content = ui.content({{
          type = ui.TYPE.Text,
          props = { text = "Tickets", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(0, 0, 0)},
        }})
      },
      { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
      -- Probability Header
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.32, 0.32, 0.32), size = util.vector2(150, 30) },
        content = ui.content({{
          type = ui.TYPE.Text,
          props = { text = "Probability", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(0, 0, 0)},
        }})
      },
      { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
      -- Remove Header
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.32, 0.32, 0.32), size = util.vector2(150, 30) },
        content = ui.content({{ 
          type = ui.TYPE.Text, 
          props = { text = "Remove", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(0, 0, 0)} 
        }})
      },
    })
  })
  table.insert(rowsContent, { type = ui.TYPE.Widget, props = { size = util.vector2(0, 10) } })

  local sumTickets = 0 
  for _, entry in pairs(workingData) do
    sumTickets =  sumTickets + entry.tickets
  end
  
  -- Rows of the table
  for index, entry in ipairs(workingData) do
    table.insert(rowsContent, {
      type = ui.TYPE.Flex,
      props = { 
        horizontal = true, -- The correct property from the docs!
      },
      content = ui.content({
        -- Outcome Box
        {
          type = ui.TYPE.Image,
          props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.2, 0.2, 0.5), size = util.vector2(150, 30) },
          content = ui.content({{
            type = ui.TYPE.TextEdit,
            props = { text = tostring(entry.outcome), size = util.vector2(80, 30), textSize = 27, textColor = util.color.rgb(1, 1, 1), size = util.vector2(150, 30)},
            events = { textChanged = async:callback(function(t) local val = tonumber(t) if val ~= nil then workingData[index].outcome = val end end) }
          }})
        },
        { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
        -- Tickets Box
        {
          type = ui.TYPE.Image,
          props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.3, 0.2, 0.5), size = util.vector2(150, 30) },
          content = ui.content({{
            type = ui.TYPE.TextEdit,
            props = { text = tostring(entry.tickets), size = util.vector2(80, 30), textSize = 27, textColor = util.color.rgb(1, 1, 1), size = util.vector2(150, 30)},
            events = { textChanged = async:callback(function(t) local val = tonumber(t) if val ~= nil then workingData[index].tickets = val end end) }
          }})
        },
        { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
        -- Probability Label
        {
          type = ui.TYPE.Image,
          props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.5, 0.5, 0.9), size = util.vector2(150, 30) },
          content = ui.content({{
            type = ui.TYPE.Text,
            props = { relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), text = string.format("%.2f%%", 100 * entry.tickets/sumTickets), size = util.vector2(80, 30), textSize = 27, textColor = util.color.rgb(1, 1, 1), size = util.vector2(150, 30)},
          }})
        },
        { type = ui.TYPE.Widget, props = { size = util.vector2(80, 0) } },
        -- Remove Button
        {
          type = ui.TYPE.Image,
          props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.5, 0.1, 0.1), size = util.vector2(30, 30) },
          events = { mouseClick = async:callback(function() 
            table.remove(workingData, index)
            if #workingData == 0 then
              table.insert(workingData, {outcome = 0, tickets = 1})
            end
            createConfigWindow() 
          end) },
          content = ui.content({{ 
            type = ui.TYPE.Text, 
            props = { text = "x", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(1, 1, 1)} 
          }})
        },
      })
    })
    table.insert(rowsContent, { type = ui.TYPE.Widget, props = { size = util.vector2(0, 10) } }) 
  end

  windowElement = ui.create({
    layer = 'Windows',
    type = ui.TYPE.Container,
    props = { relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), size = util.vector2(700, 600) },
    content = ui.content({
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.32, 0.32, 0.32), size = util.vector2(700, 600) },
        content = ui.content({
          {
            type = ui.TYPE.Flex,
            props = { 
              horizontal = true,
              size = util.vector2(700, 600) 
            },
            content = ui.content({
              { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
              {
                type = ui.TYPE.Flex,
                props = { 
                  horizontal = false,
                  size = util.vector2(685, 600) 
                },
                content = ui.content({
                  -- Top Buttons
                  {
                    type = ui.TYPE.Flex,
                    props = { horizontal = true, verticalAlignment = ui.ALIGNMENT.Center },
                    content = ui.content({
                      {
                        type = ui.TYPE.Image,
                        events = { mouseClick = async:callback(function() 
                          workingData = defaultOutcomes()
                          createConfigWindow() 
                        end) },
                        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.3, 0.3, 0.75), size = util.vector2(130, 30) },
                        content = ui.content({{
                          type = ui.TYPE.Text,
                          props = { text = "Defaults", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(1, 1, 1)},
                          
                        }})
                      },
                      { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
                      {
                        type = ui.TYPE.Image,
                        events = { mouseClick = async:callback(function() 
                          workingData = distribution:getCopy("dist")
                          createConfigWindow() 
                        end) },
                        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.3, 0.3, 0.75), size = util.vector2(130, 30) },
                        content = ui.content({{
                          type = ui.TYPE.Text,
                          props = { text = "Revert", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(1, 1, 1)},
                        }})
                      },
                      { type = ui.TYPE.Widget, props = { size = util.vector2(80, 0) } },
                      {
                        type = ui.TYPE.Image,
                        events = { mouseClick = async:callback(function() 
                          createConfigWindow()
                        end) },
                        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.5, 0.5, 0.9), size = util.vector2(100, 30) },
                        content = ui.content({{ 
                          type = ui.TYPE.Text, 
                          props = { text = "Update", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(1, 1, 1)} 
                        }})
                      },{ type = ui.TYPE.Widget, props = { size = util.vector2(40, 0) } },
                      {
                        type = ui.TYPE.Image,
                        events = { mouseClick = async:callback(function() 
                          distribution:set('dist', workingData)
                          core.sendGlobalEvent("updateMDsettings", {dist = workingData})
                          I.UI.setMode()
                        end) },
                        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.1, 0.5, 0.1), size = util.vector2(80, 30) },
                        content = ui.content({{ 
                          type = ui.TYPE.Text, 
                          props = { text = "Save", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(1, 1, 1)} 
                        }})
                      },{ type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
                      {
                        type = ui.TYPE.Image,
                        events = { mouseClick = async:callback(function() 
                          I.UI.setMode()
                        end) },
                        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.5, 0.1, 0.1), size = util.vector2(85, 30) },
                        content = ui.content({{ 
                          type = ui.TYPE.Text, 
                          props = { text = "Cancel", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(1, 1, 1)} 
                        }})
                      },
                    })
                  },
                  { type = ui.TYPE.Widget, props = { size = util.vector2(0, 20) } },
                  -- The List
                  { 
                    type = ui.TYPE.Flex, 
                    props = { horizontal = false }, 
                    content = ui.content(rowsContent) 
                  },
                  {
                    type = ui.TYPE.Image,
                    events = { mouseClick = async:callback(function() 
                      table.insert(workingData, {outcome = 0, tickets = 1}) 
                      createConfigWindow() 
                    end) },
                    props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.5, 0.5, 0.9), size = util.vector2(150, 30) },
                    content = ui.content({{ 
                      type = ui.TYPE.Text, 
                      props = { text = "+", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(1, 1, 1)} 
                    }})
                  },
                })
              }
            })
          }
        })
      }
    })
  })
end

local function storageUpdateSubscription(section, key)
  if section == "Settings_MobDuplicator" then
    if key == 'cooldown' then 
      core.sendGlobalEvent("updateMDsettings", {cooldown = playerSettings:get("cooldown")})
    end 
  end
end

input.registerTrigger {
    key = 'OpenDistEdit',
    l10n = 'MobDuplicator',
    name = ' ',
    description = ' ',
}

input.registerTriggerHandler('OpenDistEdit', async:callback(function()
  I.UI.setMode('Interface', { windows = {} })

  if windowElement then
    windowElement:destroy()
    windowElement = nil
    I.UI.setMode()
  else
      workingData =distribution:getCopy("dist")
      createConfigWindow()
  end
end))

I.Settings.registerPage({
  key = 'MobDuplicator',
  l10n = 'MobDuplicator',
  name = 'MobDuplicator',
  description = 'WIP',
})

I.Settings.registerGroup({
  key = 'Settings_MobDuplicator',
  page = 'MobDuplicator',
  l10n = 'MobDuplicator',
  name = 'Cooldown',
  permanentStorage = true,
  settings = {
    {
      key = "cooldown",
      name = "Wait before respawning this many Seconds  ",
      renderer = "number",
      argument = {
        integer = true,
      },
      default = "259200",
    },
  },
})

I.Settings.registerGroup({
  key = 'Settings_Hotkey_MobDuplicator',
  page = 'MobDuplicator',
  l10n = 'MobDuplicator',
  name = 'Hotkey',
  permanentStorage = true,
  settings = {
    {
      key = 'OpenMenuKey',
      renderer = 'inputBinding',
      argument = {
        key = 'OpenDistEdit', -- Must match your registerTrigger key
        type = 'trigger'      -- Must match registerTrigger type
      },
      name = 'Open Config Menu',
      description = 'Custom UI to Edit Distribution',
      default = "MobDuplicatorHotkey",
    },
  },
})

--Init
workingData = distribution:getCopy("dist")
if workingData == nil then
  workingData = defaultOutcomes()
  distribution:set("dist", workingData)
end
core.sendGlobalEvent("updateMDsettings", {cooldown = playerSettings:get("cooldown"), dist = workingData})
playerSettings:subscribe(async:callback(storageUpdateSubscription))

return {
  eventHandlers = {
    UiModeChanged = function(data)
      if data.newMode == nil and windowElement then
        windowElement:destroy()
        windowElement = nil
      end
    end,
  }
}
--end player.lua
