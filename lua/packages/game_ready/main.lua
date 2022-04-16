module( "game_ready", package.seeall )

local Ready = false
function isReady()
    return Ready == true
end

do

    local waitingFuncs = {}

    do

        local unpack = unpack
        local ipairs = ipairs
        local pcall = pcall

        function ready()
            hook.Run( "PreGameReady" )
            Ready = true

            for num, tbl in ipairs( waitingFuncs ) do
                pcall( tbl[1], unpack( tbl[2] ) )
                table.remove( waitingFuncs, num )
            end

            timer.Remove( "gpm_game_ready" )
            hook.Run( "GameReady" )
        end

    end

    do

        function wait( func, ... )
            if (Ready) then
                return func( ... )
            else
                table.insert( waitingFuncs, { func, { ... } } )
                timer.Create( "gpm_game_ready", 1, 0, ready )
            end
        end

        run = wait

    end

end

if (CLIENT) then

    local LocalPlayer = LocalPlayer
    local IsValid = IsValid

    -- PlayerInitialized Client Side
    timer.Simple(0, function()
        hook.Add("RenderScene", "Game Ready:PlayerInitialized", function()
            local ply = LocalPlayer()
            if IsValid( ply ) then
                hook.Remove( "RenderScene", "Game Ready:PlayerInitialized" )
                ply.Initialized = true
                ready()

                hook.Run( "PlayerInitialized", ply )
            end
        end)
    end)

    -- PlayerDisconnected Client Side
    hook.Add("ShutDown", "Game Ready:PlayerDisconnected", function()
        hook.Remove("ShutDown", "Game Ready:PlayerDisconnected")

        local ply = LocalPlayer()
        if IsValid( ply ) then
            hook.Run( "PlayerDisconnected", ply )
        end
    end)

end

if (SERVER) then

    -- PlayerInitialized Server Side
    hook.Add("PlayerInitialSpawn", "Game Ready:PlayerInitialized", function( ply )
        hook.Add("SetupMove", ply, function( self, ply, mv, cmd )
            if (self == ply) and not cmd:IsForced() then
                hook.Remove( "SetupMove", self )
                self.Initialized = true
                hook.Run( "PlayerInitialized", self )
            end
        end)
    end)

    -- Server Side Final Init
    timer.Simple( 3, ready )

end