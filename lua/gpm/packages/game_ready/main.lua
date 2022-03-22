module( "game_ready", package.seeall )

local Ready = false

function isReady()
    return Ready
end

do

    local waitingFuncs = {}

    do

        local unpack = unpack
        local ipairs = ipairs

        function runQueue()
            for num, tbl in ipairs( waitingFuncs ) do
                table.remove( waitingFuncs, num )
                pcall( tbl[1], unpack( tbl[2] ) )
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
                table_insert( waitingFuncs, { func, { ... } } )
            end
        end

    end

end

function run( func )
    if Ready then
        return func()
    else
        wait( func )
    end
end

function ready()
    Ready = true
    runQueue()

    timer.Create( "gpm_game_ready", 60, 0, runQueue )
end

if CLIENT then

    do

        local LocalPlayer = LocalPlayer
        hook.Add("ShutDown", "Game Ready:PlayerDisconnected", function()
            hook.Remove("ShutDown", "Game Ready:PlayerDisconnected")

            local ply = LocalPlayer()
            if IsValid( ply ) then
                hook.Run( "PlayerDisconnected", ply )
            end
        end)

        hook.Add("RenderScene", "Game Ready:PlayerInitialized", function()
            hook.Remove( "RenderScene", "Game Ready:PlayerInitialized" )

            local ply = LocalPlayer()
            ply["Initialized"] = true
            ready()

            hook.Run("PlayerInitialized", ply)
        end)

    end

else

    hook.Add("PlayerInitialSpawn", "Game Ready:PlayerInitialized", function( ply )
        hook.Add("SetupMove", ply, function( self, ply, mv, cmd )
            if (self == ply) and not cmd:IsForced() then
                hook.Remove( "SetupMove", self )
                self["Initialized"] = true

                hook.Run( "PlayerInitialized", self )
            end
        end)
    end)

    timer.Simple(0, ready)

end