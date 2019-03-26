--------------------------------------------------------------------
--
-- nodes@home/luaNodes/startup
-- author: andreas at jungierek dot de
-- LICENSE http://opensource.org/licenses/MIT
--
--------------------------------------------------------------------
-- junand 22.09.2016
-- 27.09.2016 integrated some code from https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/

local moduleName = ...;
local M = {};
_G [moduleName] = M;

--------------------------------------------------------------------
-- vars

local startupTimer = tmr.create ();

--------------------------------------------------------------------
-- application global

function unrequire ( module )

    local m = package.loaded [module];
    if ( m and m.subunrequire ) then m.subunrequire (); end 

    package.loaded [module] = nil
    _G [module] = nil
    
end

function tohex ( byte, len )

    return "0x" .. string.format( "%0" .. (len or 2) .. "X", byte );
    
end

--------------------------------------------------------------------
-- private

local function startApp ()

    print ( "[STARTUP] startApp: " .. nodeConfig.app .. " is starting" );
    
    if ( file.exists ( "update.url" ) ) then
        print ( "[STARTUP] startApp: update file found" );
        require ( "update" ).update ();
    else
        if ( nodeConfig.appCfg.disablePrint ) then
            print ( "[STARTUP] startApp: DISABLE PRINT" );
            oldprint = print;
            print = function ( ... ) end
        end
        print ( "[STARTUP] startApp: starting mqttWifi heap=" .. node.heap () );
        require ( "mqttWifi" ).start ();
    end

end

local function startup ()

    print ( "[STARTUP] press ENTER to abort" );
    
    -- if <CR> is pressed, abort startup
    uart.on ( "data", "\r", 
        function ()
            startupTimer:unregister ();   -- disable the start up timer
            uart.on ( "data" );                 -- stop capturing the uart
            print ( "[STARTUP] aborted" );
        end, 
        0 );

    -- startup timer to execute startup function in 5 seconds
    startupTimer:alarm ( nodeConfig.timer.startupDelay2, tmr.ALARM_SINGLE, 
    
        function () 
            -- stop capturing the uart
            uart.on ( "data" );
            startApp ();
        end 

    );

end
    
--------------------------------------------------------------------
-- public

function M.init ( startTelnet)

    print ( "[STARTUP] init: telnet=" .. tostring ( startTelnet ) );

    require ( "espConfig" );
    nodeConfig = espConfig.init ();
    
    if ( nodeConfig == nil ) then
        print ( "[STARTUP] #########" );
        print ( "[STARTUP] NO CONFIG" );
        print ( "[STARTUP] #########" );
        return;
    end
    
    require ( "credential" ); -- is called  from lc file
    wifiCredential = credential.init ( nodeConfig.mode );
    unrequire ( "credential" );
    collectgarbage ();
    
    print ( "[STARTUP] init: version=" .. nodeConfig.version );
    print ( "[STARTUP] init: waiting for application start" );

    if ( startTelnet ) then    
        require ( "telnet" ):open ( wifiCredential.ssid, wifiCredential.password );
    else
        print ( "[STARTUP] classic start" );
        startupTimer:alarm ( nodeConfig.timer.startupDelay1, tmr.ALARM_SINGLE, startup )
    end
    
end

--------------------------------------------------------------------
-- main

print ( "[MODULE] loaded: " .. moduleName )

return M;

--------------------------------------------------------------------
