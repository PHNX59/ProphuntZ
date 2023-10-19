include("shared.lua")

util.AddNetworkString("PHZ_StartBlur")
util.AddNetworkString("PHZ_StopBlur")
util.AddNetworkString("PHZ_UpdateRoundState")

TEAM_PROPS = 1
TEAM_HUNTERS = 2

local ROUND_WAITING = 0
local ROUND_PREP = 1
local ROUND_ACTIVE = 2
local ROUND_END = 3

local ROUND_TIME = 300
local ROUND_START_DELAY = 5
local ROUND_START_PLAYERS = 2
local HUNTERS_FREEZE_TIME = 20
local HUNTERS_BLUR_AMOUNT = 100
local HUNTERS_VISION_ZOOM = 150

local currentRound = ROUND_PREP
local roundEndTime = 0
local playersInPrep = 0
local playersConnected = 0 
local playersAlive = 0
local deadPlayers = {}
local canRespawn = false
local roundInProgress = false

function HandlePlayerJoining(ply)
    playersConnected = playersConnected + 1

    if currentRound == ROUND_ACTIVE then
        ply:SetTeam(TEAM_SPECTATORS)
        ply:PrintMessage(HUD_PRINTCENTER, "Attendez la fin du round pour rejoindre le jeu.")
    elseif currentRound == ROUND_PREP then
        playersInPrep = playersInPrep + 1
    end

    if currentRound == ROUND_PREP and playersConnected >= ROUND_START_PLAYERS then
        PHZ:RoundStart()
    end
end

function table.shuffle(t)
    local n = #t
    while n > 1 do
        local k = math.random(n)
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end
    return t
end

function RespawnAllPlayers()
    for _, ply in ipairs(player.GetAll()) do
        ply:Spawn()
    end
end

function StartHuntersFreeze()
    local frozenPlayers = {}
    print("[DEBUG] Début du gel des chasseurs...")

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_HUNTERS and ply:Alive() then
            ply:ScreenFade(SCREENFADE.MODULATE, Color(0, 0, 0, 255), 20, 0)
            ply:Freeze(true)
            net.Start("PHZ_StartBlur")
            net.WriteFloat(HUNTERS_BLUR_AMOUNT)
            net.WriteFloat(HUNTERS_VISION_ZOOM)
            net.Send(ply)

            table.insert(frozenPlayers, ply)
        end
    end

    timer.Simple(HUNTERS_FREEZE_TIME, function()
        for _, ply in ipairs(frozenPlayers) do
            if IsValid(ply) and ply:Team() == TEAM_HUNTERS and ply:Alive() then
                ply:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 0), 0, 0)
                ply:Freeze(false)
                net.Start("PHZ_StopBlur")
                net.Send(ply)
            end
        end

        print("[DEBUG] Fin du gel des chasseurs.")
    end)
end

function AssignRoles()
    print("[DEBUG] Attribution des rôles...")
    local players = player.GetAll()
    table.shuffle(players)

    local numProps = math.floor(#players / 2)
    local numHunters = #players - numProps

    -- Équilibrer les équipes si nécessaire
    if numProps > numHunters then
        numProps = numHunters
    elseif numHunters > numProps then
        numHunters = numProps
    end

    for i = 1, numProps do
        local player = players[i]
        if IsValid(player) then
            player:SetTeam(TEAM_PROPS)
            ConfigurePropsTeam()
            RespawnAllPlayers(player)
            print("[DEBUG] " .. player:Nick() .. " est un Prop")
        end
    end

    for i = numProps + 1, numProps + numHunters do
        local player = players[i]
        if IsValid(player) then
            player:SetTeam(TEAM_HUNTERS)
            ConfigureHuntersTeam()
            RespawnAllPlayers(player)
            print("[DEBUG] " .. player:Nick() .. " est un Hunter")
        end
    end
	RespawnAllPlayers()
    playersAlive = #players
end

function PHZ:Initialize()
    StartWaitingRound()
end

function StartWaitingRound()
    currentRound = ROUND_WAITING
    roundEndTime = 0 -- Vous pouvez définir une valeur appropriée si nécessaire
    local message = "En attente de joueurs..."
	AssignRoles()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end
end

function StartPrepRound()
    currentRound = ROUND_PREP
    roundEndTime = CurTime() + ROUND_START_DELAY
    local message = "Round de préparation commence!"

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    timer.Create("CheckPlayersInPrepTimer", 1, 0, function()
        if currentRound == ROUND_PREP and (playersInPrep >= ROUND_START_PLAYERS) then
            PHZ:RoundStart()
            timer.Remove("CheckPlayersInPrepTimer")
        end
    end)
end

function CheckTeamStatus()
    local propsAlive = 0
    local huntersAlive = 0

    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:Team() == TEAM_PROPS then
            propsAlive = propsAlive + 1
        elseif ply:Alive() and ply:Team() == TEAM_HUNTERS then
            huntersAlive = huntersAlive + 1
        end
    end

    playersAlive = propsAlive + huntersAlive

    if propsAlive == 0 then
        DeclareWinners(TEAM_HUNTERS)
    elseif huntersAlive == 0 then
        DeclareWinners(TEAM_PROPS)
    end

    if playersAlive == 0 then
        StartWaitingRound()
    end
end

function DeclareWinners(winningTeam)
    local message = ""

    if winningTeam == TEAM_HUNTERS then
        message = "Les Chasseurs ont gagné!"
    else
        message = "Les Props ont gagné!"
    end

    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v:IsPlayer() then
            v:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    PHZ:RoundEnd()
end

function PHZ:RoundStart()
    currentRound = ROUND_ACTIVE
    roundEndTime = CurTime() + ROUND_TIME
    roundInProgress = true

    AssignRoles()

    local message = "La chasse commence!"

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    StartHuntersFreeze()

    canRespawn = false

    timer.Simple(ROUND_TIME, function()
        if currentRound == ROUND_ACTIVE then
            local huntersAlive = 0
            local propsAlive = 0
			
            for _, ply in ipairs(player.GetAll()) do
                if ply:Alive() and ply:Team() == TEAM_PROPS then
                    propsAlive = propsAlive + 1
                elseif ply:Alive() and ply:Team() == TEAM_HUNTERS then
                    huntersAlive = huntersAlive + 1
                end
            end
			
            if propsAlive > 0 and huntersAlive == 0 then
                DeclareWinners(TEAM_PROPS)
            else
                DeclareWinners(TEAM_HUNTERS)
            end
			
            PHZ:RoundEnd()
        end
    end)
end

function PHZ:RoundEnd()
    currentRound = ROUND_END
    roundEndTime = CurTime() + 10
    local message = "Round terminé!"

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    timer.Simple(5, function()
        if currentRound == ROUND_END then
            StartPrepRound()
        end
        -- Réactiver la possibilité de réapparaître
        canRespawn = true
    end)
end

function PHZ:Think()
    if currentRound == ROUND_ACTIVE then
        local propsAlive = 0
        local huntersAlive = 0

        for _, ply in ipairs(player.GetAll()) do
            if ply:Alive() then
                if ply:Team() == TEAM_PROPS then
                    propsAlive = propsAlive + 1
                elseif ply:Team() == TEAM_HUNTERS then
                    huntersAlive = huntersAlive + 1
                end
            end
        end

        if propsAlive == 0 then
            DeclareWinners(TEAM_HUNTERS)
            PHZ:RoundEnd()
        elseif huntersAlive == 0 then
            DeclareWinners(TEAM_PROPS)
            PHZ:RoundEnd()
        end
    end

    net.Start("PHZ_UpdateRoundState")
    net.WriteInt(currentRound, 32)
    net.WriteFloat(math.max(0, roundEndTime - CurTime()))
    net.Broadcast()
end

hook.Add("CanPlayerSuicide", "PHZ_CanPlayerSuicide", function(ply)
    if currentRound == ROUND_ACTIVE then
        return false
    end
end)

hook.Add("PlayerDeath", "PHZ_PlayerDeath", function(ply)
    if currentRound == ROUND_ACTIVE then
        table.insert(deadPlayers, ply)
    end
end)

hook.Add("PlayerInitialSpawn", "MonHookInitialSpawn", function(ply)
    playersConnected = playersConnected + 1
    playersInPrep = playersInPrep + 1
	AssignRoles()
	StartWaitingRound()
    if playersConnected >= ROUND_START_PLAYERS then
        PHZ:RoundStart()
		AssignRoles()
    end
end)

hook.Add("PlayerDisconnected", "TrackPlayersInPrep", function(ply)
    playersConnected = math.max(playersConnected - 2, 0)

    if currentRound == ROUND_ACTIVE and playersInPrep < ROUND_START_PLAYERS then
        PHZ:RoundEnd()
    elseif currentRound == ROUND_WAITING and playersConnected < ROUND_START_PLAYERS then
        StartWaitingRound()
    end
end)

hook.Add("PlayerSpawn", "PHZ_PlayerSpawn", function(ply)
    if currentRound == ROUND_ACTIVE and table.HasValue(deadPlayers, ply) then
        ply:PrintMessage(HUD_PRINTCENTER, "Vous ne pouvez pas respawn tant que le round est en cours.")
        return false
    end
end)

hook.Add("PlayerDeathThink", "PHZ_PlayerDeathThink", function(ply)
    if currentRound == ROUND_ACTIVE and not canRespawn then
        return false
    end
end)
