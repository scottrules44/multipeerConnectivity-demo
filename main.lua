--Note this demo was designed for two devices, you would need to make tweaks for more then two devices.
local multipeerConnectivity = require "plugin.multipeerConnectivity"
local json = require "json"
local otherDeviceName
local ackTimer

local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
bg:setFillColor( 0,0,1 )

local title = display.newText( {text = "Multipeer Connectivity", fontSize = 20, font=system.nativeFontBold} )
title.width, title.height = 300, 168
title.x, title.y = display.contentCenterX, 84
title:setFillColor(1,1,1)

local deviceName = display.newText( {text = "Device name:"..system.getInfo("name"), fontSize = 15, font=system.nativeFontBold} )

deviceName.x, deviceName.y = display.contentCenterX, 110
deviceName:setFillColor(1,1,1)

multipeerConnectivity.init(function(e)
    print(json.encode(e))
    if (e.status == "hostFound") then
        local hostDeviceName = e.deviceName
        native.showAlert( "Host Found", "Found Host:"..hostDeviceName, {"Cancel", "Join"}, function(ev)
            if(ev.index == 2) then
                multipeerConnectivity.sendInvite(hostDeviceName, 20)-- 20 second timeout
            end
        end )
    elseif (e.status == "deviceInviteSent") then
        local inviteDeviceName = e.deviceName
        native.showAlert( "Invite Received", "Invite From:"..inviteDeviceName, {"Cancel", "Accept"}, function(ev)
            if(ev.index == 2) then
                multipeerConnectivity.acceptInvite(inviteDeviceName)
            end
        end )
    elseif (e.status == "searcherInviteRecived") then
        local inviteDeviceName = e.deviceName
        native.showAlert( "Invite Received", "Invite From:"..inviteDeviceName, {"Cancel", "Accept"}, function(ev)
            if(ev.index == 2) then
                multipeerConnectivity.acceptInvite(inviteDeviceName)
            end
        end )
    elseif (e.status == "stateChanged" and e.state == "connected") then
        otherDeviceName = e.deviceName
        native.showAlert( "Connected", "Connected to device:"..e.deviceName, {"Ok"} )
        ackTimer = timer.performWithDelay( 15000, function()
            multipeerConnectivity.sendMessage("ack", otherDeviceName)
        end, -1 ) -- send acknowledgement everyone and awhile to keep connection going
    elseif (e.status == "stateChanged" and e.state == "notConnected") then
        if(ackTimer)then
            timer.cancel(ackTimer)
        end
        native.showAlert( "notConnected", "Lost connection to device:"..e.deviceName, {"Ok"} )
    elseif (e.status == "gotMessage" and e.message ~= "ack" ) then
        native.showAlert( "Got message from:"..e.deviceName, "Message:"..e.message, {"Ok"} )
    end
    
end)

local widget = require("widget")

print("------My Device Name----------")
print(system.getInfo("name"))



local myAppName = "testApp" --change in build.setting/plist as well


local startSearch
startSearch = widget.newButton( {
  x = display.contentCenterX,
  y = display.contentCenterY-80,
  id = "startSearch",
  labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
  label = "Start Search",
  onEvent = function ( e )
    if (e.phase == "ended") then
        
        multipeerConnectivity.startSearch(system.getInfo("name"), myAppName) -- You may not want to use system.getInfo("name"), since device names could be the same
        startSearch._view._label:setFillColor(0,1,0)
        timer.performWithDelay( 10000, function()
            startSearch._view._label:setFillColor(1,1,1)
            multipeerConnectivity.stopSearch()
        end )
    end
  end
} )




local startHost
startHost = widget.newButton( {
  x = display.contentCenterX,
  y = display.contentCenterY-40,
  id = "startHost",
  labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
  label = "Start Host",
  onEvent = function ( e )
    if (e.phase == "ended") then
        startHost._view._label:setFillColor(0,1,0)
        multipeerConnectivity.startHost(system.getInfo("name"), myAppName)
        --Note stopping this hosting stop connection between the user(s)
    end
  end
} )




local sendMessage
sendMessage = widget.newButton( {
  x = display.contentCenterX,
  y = display.contentCenterY,
  id = "sendMessage",
  labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
  label = "Send Message",
  onEvent = function ( e )
    if (e.phase == "ended") then
        if(otherDeviceName)then
            multipeerConnectivity.sendMessage("Hello There "..otherDeviceName, otherDeviceName)
        end
    end
  end
} )

local listUser
listUser = widget.newButton( {
  x = display.contentCenterX,
  y = display.contentCenterY+40,
  id = "listUsers",
  labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
  label = "List Users",
  onEvent = function ( e )
    if (e.phase == "ended") then
        if(multipeerConnectivity.listUsers()) then
            native.showAlert( "Users", json.encode(multipeerConnectivity.listUsers()), {"Ok"} )
        else
            native.showAlert( "Users", "no users", {"Ok"} )
        end
    end
  end
} )

local disconnect
disconnect = widget.newButton( {
  x = display.contentCenterX,
  y = display.contentCenterY+80,
  id = "disconnect",
  labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
  label = "Disconnect",
  onEvent = function ( e )
    if (e.phase == "ended") then
        multipeerConnectivity.disconnect()
        startHost._view._label:setFillColor(1,1,1)
        multipeerConnectivity.stopHost()--Note stopping this will stop connection between the user(s)
    end
  end
} )
