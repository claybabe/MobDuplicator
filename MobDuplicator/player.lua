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
local hotkey = storage.playerSection('Settings_Hotkey_MobDuplicator')

local defaultOutcomes = {
  {outcome = 0, tickets = 15 }, 
  {outcome = 1, tickets = 40 }, 
  {outcome = 2, tickets = 30 },
  {outcome = 5, tickets = 14 },
  {outcome = 9, tickets = 1 },
  {outcome = 99, tickets = 0.01 },
}

local windowElement = nil

local toggleDistEdit
local createConfigWindow

local function deepCopy(t)
  if type(t) ~= 'table' and type(t) ~= 'userdata' then return t end
  local res = {}
  for k, v in pairs(t) do
    res[k] = deepCopy(v)
  end
  return res
end

-- STATE
local workingData

-- UI COMPONENTS
local function ROW(index, entry)
  return {
    type = ui.TYPE.Flex,
    props = { 
      horizontal = true, -- The correct property from the docs!
    },
    content = ui.content({
      -- Outcome Box
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.2, 0.5, 0.1), size = util.vector2(80, 30) },
        content = ui.content({{
          type = ui.TYPE.TextEdit,
          props = { text = tostring(entry.outcome), size = util.vector2(80, 30), textSize = 27, textColor = util.color.rgb(1, 1, 1)},
          events = { textChanged = async:callback(function(t) workingData[index].outcome = tonumber(t) or 0 end) }
        }})
      },
      { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
      -- Tickets Box
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.2, 0.1, 0.3), size = util.vector2(80, 30) },
        content = ui.content({{
          type = ui.TYPE.TextEdit,
          props = { text = tostring(entry.tickets), size = util.vector2(80, 30), textSize = 27, textColor = util.color.rgb(1, 1, 1)},
          events = { textChanged = async:callback(function(t) workingData[index].tickets = tonumber(t) or 0 end) }
        }})
      },
      { type = ui.TYPE.Widget, props = { size = util.vector2(15, 0) } },
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
          props = { text = "X", relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), textSize = 20, textColor = util.color.rgb(0, 0, 0)} 
        }})
      },
    })
  }
end

createConfigWindow = function()
  if windowElement then windowElement:destroy() end

  local rowsContent = {}
  
  -- Header labels for the table
  table.insert(rowsContent, {
    type = ui.TYPE.Flex,
    props = { horizontal = true },
    content = ui.content({
      { type = ui.TYPE.Text, props = { text = "Outcome", textSize = 14, size = util.vector2(80, 20) } },
      { type = ui.TYPE.Widget, props = { size = util.vector2(45, 0) } },
      { type = ui.TYPE.Text, props = { text = "Tickets", textSize = 14, size = util.vector2(80, 20) } },
      { type = ui.TYPE.Widget, props = { size = util.vector2(45, 0) } },
    })
  })

  for i, entry in ipairs(workingData) do
    table.insert(rowsContent, ROW(i, entry))
    table.insert(rowsContent, { type = ui.TYPE.Widget, props = { size = util.vector2(0, 10) } }) 
  end

  windowElement = ui.create({
    layer = 'Windows',
    type = ui.TYPE.Container,
    props = { relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5), size = util.vector2(500, 600) },
    content = ui.content({
      {
        type = ui.TYPE.Image,
        props = { resource = ui.texture({path = 'white'}), color = util.color.rgb(0.2, 0.2, 0.2), size = util.vector2(500, 600) },
        content = ui.content({
          {
            type = ui.TYPE.Flex,
            props = { 
              horizontal = false,
              size = util.vector2(500, 600) 
            },
            content = ui.content({
              -- Top Buttons
              {
                type = ui.TYPE.Flex,
                props = { horizontal = true, verticalAlignment = ui.ALIGNMENT.Center },
                content = ui.content({
                  {
                    type = ui.TYPE.Text, props = { text = "[ DEFAULT ]", textSize = 20 },
                    events = { mouseClick = async:callback(function() 
                      workingData = deepCopy(defaultOutcomes)
                      createConfigWindow() 
                    end) }
                  },
                  {
                    type = ui.TYPE.Text, props = { text = "[ REVERT ]", textSize = 20 },
                    events = { mouseClick = async:callback(function() 
                      workingData = deepCopy(distribution:get("dist"))
                      createConfigWindow() 
                    end) }
                  },                  
                  { type = ui.TYPE.Widget, props = { size = util.vector2(50, 40) } },
                  {
                    type = ui.TYPE.Text, props = { text = "[ SAVE ]", textSize = 20, textColor = util.color.rgb(0.5, 1, 0.5) },
                    events = { mouseClick = async:callback(function() 
                      distribution:set('dist', workingData)
                      core.sendGlobalEvent("rebuildDDS", workingData)
                      I.UI.setMode()
                    end) }
                  }
                })
              },
              { type = ui.TYPE.Widget, props = { size = util.vector2(0, 20) } },
              -- The List
              { 
                type = ui.TYPE.Flex, 
                props = { horizontal = false }, 
                content = ui.content(rowsContent) 
              },
              { type = ui.TYPE.Widget, props = { size = util.vector2(0, 20) } },
              -- Add Button
              {
                type = ui.TYPE.Text, props = { text = "(+) ADD NEW ROW", textSize = 18, textColor = util.color.rgb(0.8, 0.8, 1) },
                events = { mouseClick = async:callback(function() 
                  table.insert(workingData, {outcome = 0, tickets = 1}) 
                  createConfigWindow() 
                end) }
              }
            })
          }
        })
      }
    })
  })
end

toggleDistEdit = function()
  I.UI.setMode('Interface', { windows = {} })

  if windowElement then
    windowElement:destroy()
    windowElement = nil
    I.UI.setMode()
  else
      workingData = deepCopy(distribution:get("dist"))
      createConfigWindow()
  end
end

local function storageUpdateSubscription(section, key)
  if section == "Settings_MobDuplicator" then
    if key == 'cooldown' then 
      core.sendGlobalEvent("updateCooldown", playerSettings:get("cooldown"))
    end 
  end
end

playerSettings:subscribe(async:callback(storageUpdateSubscription))

local function onRequestCooldown()
  print("SENDING COOLDOWN")
  core.sendGlobalEvent("updateCooldown", playerSettings:get("cooldown"))
end

input.registerTrigger {
    key = 'OpenDistEdit',
    l10n = 'MobDuplicator',
    name = ' ',
    description = ' ',
}

input.registerTriggerHandler('OpenDistEdit', async:callback(toggleDistEdit))

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
      default = "M",
      action = "OpenDistEdit",
    },
  },
})

--Init
workingData = distribution:get("dist")
if workingData == nil then
  workingData = deepCopy(defaultOutcomes)
  distribution:set("dist", workingData)
else
  workingData = deepCopy(workingData)
end
core.sendGlobalEvent("rebuildDDS", workingData)

return {
  eventHandlers = {
    UiModeChanged = function(data)
      if data.newMode == nil and windowElement then
        windowElement:destroy()
        windowElement = nil
      end
    end,
    requestCooldown = onRequestCooldown,
  }
}
--end player.lua
