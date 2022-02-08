local table_insert = table.insert
local unpack = unpack
local assert = assert
local ipairs = ipairs
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

function wait( func, ... )
    assert( type( func ) == "function", "bad argument #1 (function expected)")
    table_insert( waitingFuncs, { func, { ... } } )
end

local function ready()
    Ready = true

    for num, tbl in ipairs( waitingFuncs ) do
        tbl[1]( unpack( tbl[2] ) )
    end
end

if CLIENT then
    hook.Add("RenderScene", "gpm_game_ready", function()
        hook.Remove("RenderScene", "gpm_game_ready")
        ready()
    end)
else
    timer.Simple(0, ready)
end