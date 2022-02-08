local assert = assert
local type = type

module( "game_ready", package.seeall )

local Ready = false
local waitingFuncs = {}

function ready()
    return Ready
end

function isReady()
    return Ready
end

do
    local unpack = unpack
    local ipairs = ipairs

    local function runQueue()
        for num, tbl in ipairs( waitingFuncs ) do
            table.remove( waitingFuncs, num )
            tbl[1]( unpack( tbl[2] ) )
        end
    end
end

do
    local table_insert = table.insert
    function wait( func, ... )
        if Ready then
            func( ... )
            runQueue()
        else
            assert( type( func ) == "function", "bad argument #1 (function expected)")
            table_insert( waitingFuncs, { func, { ... } } )
        end
    end
end

function run( func )
    assert( type( func ) == "function", "bad argument #1 (function expected)")
    if Ready then
        return func()
    else
        wait( func )
    end
end

local function nowReady()
    Ready = true
    runQueue()

    timer.Create( "gpm_game_ready", 60, 0, runQueue )
end

if CLIENT then
    hook.Add("RenderScene", "gpm_game_ready", function()
        hook.Remove("RenderScene", "gpm_game_ready")
        nowReady()
    end)
else
    timer.Simple(0, nowReady)
end