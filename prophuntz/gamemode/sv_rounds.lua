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

local currentRound = ROUND_PREP
local roundEndTime = 0
local playersInPrep = 0
local playersConnected = 0

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
    print("[DEBUG] Début de RespawnAllPlayers()")
    for _, ply in ipairs(player.GetAll()) do
        ply:Spawn()
        print("[DEBUG] Respawn du joueur : " .. ply:Nick())
    end
    print("[DEBUG] Fin de RespawnAllPlayers()")
end

function StartHuntersFreeze()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_HUNTERS then
            ply:Freeze(true)
            net.Start("PHZ_StartBlur")
            net.Send(ply)
        end
    end

    timer.Simple(20, function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_HUNTERS then
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
end

function PHZ:Initialize()
    print("[DEBUG] Initialisation de PHZ")
    StartPrepRound()
end

function StartPrepRound()
    print("[DEBUG] Début de StartPrepRound()")
    currentRound = ROUND_PREP
    roundEndTime = 0
    print("[DEBUG] Etat actuel : ROUND_PREP | Temps de fin : " .. roundEndTime)
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint("Round de préparation commence!")
    end
    print("[DEBUG] Fin de StartPrepRound()")

    if currentRound == ROUND_PREP and (playersInPrep > 1) then
        print("[DEBUG] Démarrage du round actif")
        PHZ:RoundStart()
    end
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

    if propsAlive == 0 then
        DeclareWinners(TEAM_HUNTERS)
    elseif huntersAlive == 0 then
        DeclareWinners(TEAM_PROPS)
    end
end

function DeclareWinners(winningTeam)
    if winningTeam == TEAM_HUNTERS then
        for _, v in ipairs(player.GetAll()) do
            v:ChatPrint("Les Chasseurs ont gagné!")
        end
    else
        for _, v in ipairs(player.GetAll()) do
            v:ChatPrint("Les Props ont gagné!")
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
    print("[DEBUG] Début du round actif...")
    currentRound = ROUND_ACTIVE
    roundEndTime = CurTime() + ROUND_TIME

    AssignRoles()

    net.Start("PHZ_UpdateRoundState")
    net.WriteInt(currentRound, 32)
    net.WriteFloat(roundEndTime)
    net.Broadcast()

    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("La chasse commence!")
    end

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
    print("[DEBUG] Fin du round...")
    currentRound = ROUND_END
    roundEndTime = CurTime() + 10

    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint("Round terminé!")
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
    if playersConnected >= 2 then
        PHZ:RoundStart()
    end
end)

hook.Add("PlayerDeathThink", "PHZ_PreventRespawnDuringRound", function(ply)
    if currentRound == ROUND_ACTIVE then
        return false
    end
end)

hook.Add("PlayerDisconnected", "TrackPlayersInPrep", function(ply)
    playersInPrep = math.max(playersInPrep - 1, 0)
    if currentRound == ROUND_PREP and playersInPrep < 2 then
        print("[DEBUG] Le round est réinitialisé en raison de la déconnexion d'un joueur.")
        PHZ:RoundEnd()
    end
end)

hook.Add("PlayerDisconnected", "TrackPlayersInPrep", function(ply)
    playersInPrep = math.max(playersInPrep - 1, 0)
end)
