include("shared.lua")

util.AddNetworkString("PHZ_StartBlur")
util.AddNetworkString("PHZ_StopBlur")
util.AddNetworkString("PHZ_UpdateRoundState")

TEAM_PROPS = 1
TEAM_HUNTERS = 2

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

local roundInProgress = false

net.Receive("PHZ_UpdateHUDData", function()
    currentRound = net.ReadInt(32)
    timeRemaining = net.ReadFloat()
    playersAlive = net.ReadInt(32) 
end)

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
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_HUNTERS then
            ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 20, 0)
            ply:Freeze(true)
            net.Start("PHZ_StartBlur")
            net.WriteFloat(HUNTERS_BLUR_AMOUNT)
            net.WriteFloat(HUNTERS_VISION_ZOOM)
            net.Send(ply)
        end
    end

    timer.Simple(HUNTERS_FREEZE_TIME, function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_HUNTERS then
                ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 0), 5, 0)
                ply:Freeze(false)
                net.Start("PHZ_StopBlur")
                net.Send(ply)
            end
        end
    end)
end

function AssignRoles()
    print("[DEBUG] Attribution des rôles...")
    local players = player.GetAll()
    table.shuffle(players)

    local numProps = math.floor(#players / 2)

    for i = 1, numProps do
        local player = players[i]
        player:SetTeam(TEAM_PROPS)
        ConfigurePropsTeam(player)
        RespawnAllPlayers(player)
        print("[DEBUG] " .. player:Nick() .. " est un Prop")
    end

    for i = numProps + 1, #players do
        local player = players[i]
        player:SetTeam(TEAM_HUNTERS)
        ConfigureHuntersTeam(player)
        RespawnAllPlayers(player)
        print("[DEBUG] " .. player:Nick() .. " est un Hunter")
    end

    playersAlive = #players
end

function PHZ:Initialize()
    StartPrepRound()
end

function StartPrepRound()
    currentRound = ROUND_PREP
    roundEndTime = CurTime() + ROUND_START_DELAY
	local message = ""
    message = "Round de préparation commence!"
	
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
        StartPrepRound()
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

hook.Add("PlayerDeath", "PHZ_PlayerDeath", function(victim, inflictor, attacker)
    timer.Simple(1, function()
        CheckTeamStatus()
    end)
end)

function PHZ:RoundStart()
    currentRound = ROUND_ACTIVE
    roundEndTime = CurTime() + ROUND_TIME
    roundInProgress = true

    AssignRoles()

	local message = ""
    message = "La chasse commence!"
	
	for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end
	
    StartHuntersFreeze()

    timer.Simple(ROUND_TIME, function()
        if currentRound == ROUND_ACTIVE then
            PHZ:RoundEnd()
        end
        local propsAlive = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply:Alive() and ply:Team() == TEAM_PROPS then
                propsAlive = propsAlive + 1
            end
        end
        if propsAlive > 0 then
            DeclareWinners(TEAM_PROPS)
        else
            DeclareWinners(TEAM_HUNTERS)
        end
    end)
end

function PHZ:RoundEnd()
    currentRound = ROUND_END
    roundEndTime = CurTime() + 10
	local message = ""
    message = "Round terminé!"

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end
	
    timer.Simple(5, function()
        if currentRound == ROUND_END then
            StartPrepRound()
        end
    end)
end

function PHZ:Think()
    if roundEndTime <= CurTime() then
        if currentRound == ROUND_PREP then
            PHZ:RoundStart()
        elseif currentRound == ROUND_ACTIVE then
            PHZ:RoundEnd()
        elseif currentRound == ROUND_END then
            StartPrepRound()
        end
    end
end

hook.Add("PlayerInitialSpawn", "MonHookInitialSpawn", function(ply)
    playersConnected = playersConnected + 1
    playersInPrep = playersInPrep + 1

    if playersConnected >= ROUND_START_PLAYERS then
        PHZ:RoundStart()
    end
end)

hook.Add("PlayerDisconnected", "TrackPlayersInPrep", function(ply)
    playersConnected = math.max(playersConnected - 2, 0)

    if currentRound == ROUND_ACTIVE and playersInPrep < ROUND_START_PLAYERS then
        PHZ:RoundEnd()
    end
end)

hook.Add("PlayerSpawn", "PHZ_PlayerSpawn", function(ply)
    if currentRound == ROUND_ACTIVE then
        ply:PrintMessage(HUD_PRINTCENTER, "Vous ne pouvez pas respawn tant que le round est en cours.")
        return false
    end
end)
