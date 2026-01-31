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

local windowElement = nil
local currentEditString = ""

local NUM = 0

local function parseDistString()
  local dist = {}
  local raw = distribution:get('distString') or "0,15 ; 1,40 ; 2,30 ; 5,14 ; 9,1 ; 99,0.01"
  
  print("[MobDuplicator] Parsing: " .. raw)
  local newString = ""
  for pair in raw:gmatch("([^;]+)") do
    local outcome, tickets = pair:match("([^,]+),([^,]+)")
    outcome, tickets = tonumber(outcome), tonumber(tickets)
    if outcome and tickets then
      table.insert(dist, {outcome = outcome, tickets = tickets})
      newString = newString .. string.format("%s, %s ; ", outcome, tickets)
    end
  end

  print(string.format("[MobDuplicator] Parsing finished. [[%s]]", newString))
  
  if #dist > 0 then
    distribution:set("distString", newString)
    for _, entry in pairs(dist) do
      print("outcome: " .. entry.outcome .. "  tickets: " .. entry.tickets)
    end
    distribution:set('dist', dist)
    core.sendGlobalEvent("rebuildDDS", dist)
  else
    distribution:set("distString", "0,1 ;")
    print("[MobDuplicator] Empty distribution! sending {{outcome = 0, tickets = 1}}")
    core.sendGlobalEvent("rebuildDDS", {{outcome = 0, tickets = 1}})
  end
end

local toggleDistEdit
local function CONTENT()
  local temp = {}
  local ele = {
                type = ui.TYPE.Text,
                props = {
                  text = "MobDuplicator",
                  textSize = 24,
                  textColor = util.color.rgb(202/255, 165/255, 96/255),
                }
              }
  for i = 1, NUM do
    table.insert(temp, ele)
  end
  return {
    {
      type = ui.TYPE.Text,
      props = { text = " [ SAVE & APPLY ] ", textSize = 18 },
      events = {
        mouseClick = async:callback(function()
          distribution:set('distString', currentEditString)
          parseDistString()
          print("[MobDuplicator] Settings Saved via UI.")
          toggleDistEdit()
        end)
      }
    },
    table.unpack(temp)    
  }
end

local function createConfigWindow()
  if NUM < 10 then NUM = NUM + 1 end
  if windowElement then windowElement:destroy() end

  -- Pre-fill with current settings
  currentEditString = distribution:get('distString')

  windowElement = ui.create({
    layer = 'Windows',
    type = ui.TYPE.Container,
    props = {
      relativePosition = util.vector2(0.5, 0.5),
      anchor = util.vector2(0.5, 0.5),
      size = util.vector2(888, 350),
    },
    content = ui.content({
      -- Background 
      {
        type = ui.TYPE.Image,
        props = {
          resource = ui.texture({path = 'white'}),
          color = util.color.rgb(0.3, 0.3, 0.3),
          size = util.vector2(888, 350),
        },
        content = ui.content({
          -- Vertical Layout Container
          {
            type = ui.TYPE.Flex,
            props = {
              horizontalAlignment = ui.ALIGNMENT.Center,
              column = true,
              size = util.vector2(800, 300),
              relativePosition = util.vector2(0.5, 0.5),
              anchor = util.vector2(0.5, 0.5),
            },
            content = ui.content({
              -- Title
              {
                type = ui.TYPE.Text,
                props = {
                  text = "MobDuplicator",
                  textSize = 24,
                  textColor = util.color.rgb(202/255, 165/255, 96/255),
                }
              },
              -- Spacer
              { type = ui.TYPE.Container, props = { size = util.vector2(0, 200) } },
              -- Label

              -- THE TEXT INPUT
              {
                type = ui.TYPE.TextEdit,
                props = {
                  text = currentEditString,
                  textSize = 42,
                  size = util.vector2(800, 48),
                  textColor = util.color.rgb(1,1,1),
                },
                events = {
                  textChanged = async:callback(function(newText)
                    currentEditString = newText
                  end)
                }
              },
              -- Spacer
              { type = ui.TYPE.Container, props = { size = util.vector2(0, 40) } },
              -- BUTTONS ROW
              {
                type = ui.TYPE.Flex,
                --props = { column = false },
                content = ui.content({
                  table.unpack(CONTENT())
                })
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


parseDistString()

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

return {
    
    eventHandlers = {
        -- This catch-all ensures that if the user forces the menu closed, 
        -- we clean up our variables.
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
