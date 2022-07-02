/*
    Functions:
        `boolean` PLAYER:IsInitialized() - Returns `true` if player fully initialized on server
        game_ready.wait( `function` func, varang ) - Run function after game is begins ready
        game_ready.run( `function` func, varang ) - Run function after game is begins ready
        game_ready.ready() - Force game_ready launch

    Hooks:
        GM:PlayerInitialized( ply ) - Runs after player fully loaded on server
        GM:PreGameReady() - Starts earlier `GM:OnGameReady()`
        GM:OnGameReady() - Runs after game is ready

        Client:
            GM:PlayerDisconnected( ply ) - Runs on leave from server
*/
module( "game_ready", package.seeall )

local logger = GPM.Logger( "Game Ready" )

local Ready = false
function isReady()
    return Ready == true
end

do

    local waitingFuncs = {}

    do

        local isfunction = isfunction
        local unpack = unpack
        local pairs = pairs

        -- Don't touch!
        function ready()
            logger:info( "Startup..." )
            hook.Run( "PreGameReady" )
            Ready = true

            for num, tbl in pairs( waitingFuncs ) do
                local ok, err = pcall( tbl[1], unpack( tbl[2] ) )
                if (ok == false) then
                    logger:error( "On startup: {1}", err )
                end
            end

            hook.Run( "OnGameReady" )
            logger:info( "Game is ready!" )
        end

    end

    do

        function wait( func, ... )
            if (Ready) then
                return func( ... )
            else
                table.insert( waitingFuncs, { func, { ... } } )
            end
        end

        -- Alias for wait
        run = wait

    end

end

if (CLIENT) then

    local LocalPlayer = LocalPlayer
    local IsValid = IsValid

    -- PlayerInitialized Client Side
    hook.Add("RenderScene", "Game Ready:PlayerInitialized", function()
        local ply = LocalPlayer()
        if IsValid( ply ) then
            hook.Remove( "RenderScene", "Game Ready:PlayerInitialized" )
            ply.Initialized = true
            ready()

            logger:info( "{1} initialized", tostring( ply ) )
            hook.Run( "PlayerInitialized", ply )
        end
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
                logger:info( "{1} initialized", tostring( ply ) )
                hook.Run( "PlayerInitialized", self )
            end
        end)
    end)

    -- Server Side Final Init
    timer.Simple( 0, ready )

end

/*
    Functions:
        PLAYER:IsInitialized() - returns `true` if player is initialized
*/
do
    local PLAYER = FindMetaTable( "Player" )
    if (PLAYER ~= nil) then
        function PLAYER:IsInitialized()
            return self.Initialized or false
        end
    end
end