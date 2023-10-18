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

local currentRound = ROUND_WAITING  -- Démarrez dans l'état d'attente
local roundEndTime = 0
local playersConnected = 0
local playersAlive = 0
local roundStarted = false  
local roundInProgress = false

function table.shuffle(t)
    local n = #t
    while n > 1 do
        local k = math.random(n)
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end
    return t
end

function AssignRoles()
    local players = player.GetAll()
    local totalPlayers = #players
    local numProps = math.max(math.floor(totalPlayers / 2), 1) -- Au moins 1 Prop
    local numHunters = totalPlayers - numProps

    local propsAssigned = 0
    local huntersAssigned = 0

    -- Créez les équipes des Props et des Hunters une seule fois
    CreatePropsTeam()
    CreateHuntersTeam()

    for _, ply in ipairs(players) do
        if propsAssigned < numProps then
            ply:SetTeam(TEAM_PROPS)
            ply:StripWeapons()
            propsAssigned = propsAssigned + 1
        elseif huntersAssigned < numHunters then
            ply:SetTeam(TEAM_HUNTERS)
            huntersAssigned = huntersAssigned + 1
        end

        RespawnAllPlayers()

        print("[DEBUG] " .. ply:Nick() .. " est un " .. (ply:Team() == TEAM_PROPS and "Prop" or "Hunter"))
    end

    playersAlive = totalPlayers
end

function RespawnAllPlayers()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:Spawn()
        end
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

-- Ajoutez également des messages de débogage dans d'autres fonctions au besoin.

function StartPrepRound()
    currentRound = ROUND_WAITING
    local message = "Attente de joueurs dans chaque équipe..."
    print("[DEBUG] Round en préparation. État actuel : ROUND_WAITING")

    -- Afficher un message de préparation à tous les joueurs
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    -- Réinitialiser les équipes et faire réapparaître les joueurs
    for _, ply in ipairs(player.GetAll()) do
        ply:SetTeam(TEAM_SPECTATOR)
    end

    -- Réinitialiser d'autres variables d'état si nécessaire
    roundEndTime = 0
    roundInProgress = false

    -- Attribution des rôles aux joueurs
    AssignRoles()

    -- Utilisation d'un minuteur pour vérifier si les deux équipes sont prêtes
    timer.Create("CheckPlayersInTeamsTimer", 1, 0, CheckPlayersInTeams)
end

function PHZ:Initialize()
    StartPrepRound()
end

function CheckPlayersInTeams()
    local propsReady = false
    local huntersReady = false

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_PROPS then
            propsReady = true
        elseif ply:Team() == TEAM_HUNTERS then
            huntersReady = true
        end
    end

    -- Si les deux équipes sont prêtes et que le round n'a pas encore commencé, démarrez le round
    if propsReady and huntersReady and not roundStarted then
        PHZ:RoundStart()
        roundStarted = true -- Marquez le round comme démarré pour éviter les appels répétés
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

function PHZ:RoundStart()
    currentRound = ROUND_ACTIVE
    roundEndTime = CurTime() + ROUND_TIME
    roundInProgress = true
    local message = "La chasse commence!"
    print("[DEBUG] Début du round actif. État actuel : ROUND_ACTIVE")

    -- Réinitialisez la liste des joueurs morts
    deadPlayers = {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    timer.Simple(ROUND_TIME, function()
        if currentRound == ROUND_ACTIVE then
            PHZ:RoundEnd()
        end

        -- Comptez les "Props" morts pendant le round
        local propsAlive = 0
        for _, ply in ipairs(player.GetAll()) do
            if ply:Alive() and ply:Team() == TEAM_PROPS then
                propsAlive = propsAlive + 1
            elseif not ply:Alive() and ply:Team() == TEAM_PROPS then
                table.insert(deadPlayers, ply) -- Ajoutez le joueur mort à la liste
            end
        end

        if propsAlive > 0 then
            DeclareWinners(TEAM_HUNTERS)
        else
            DeclareWinners(TEAM_PROPS)
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

    timer.Simple(10, function()
        if currentRound == ROUND_END then
            StartPrepRound()
        end

        -- Réinitialisez simplement la liste des joueurs morts sans effectuer de respawn
        deadPlayers = {}
    end)
end

function PHZ_Think()
    if roundEndTime <= CurTime() then
        if currentRound == ROUND_PREP then
            PHZ_RoundStart()
        elseif currentRound == ROUND_ACTIVE then
            PHZ_RoundEnd()
        elseif currentRound == ROUND_END then
            StartPrepRound()
        end
    end
end

-- Surveillez la mort des joueurs et ajoutez-les à la liste des joueurs morts
hook.Add("PlayerDeath", "PHZ_PlayerDeath", function(victim, inflictor, attacker)
    if currentRound == ROUND_ACTIVE then
        table.insert(deadPlayers, victim)
        victim:Remove() -- Supprimez le joueur pour l'empêcher de respawn
    end
end)

-- Assurez-vous que cette fonction est correctement appelée à chaque itération du Think.
hook.Add("Think", "PHZ_ThinkHook", PHZ_Think)

hook.Add("PlayerInitialSpawn", "MonHookInitialSpawn", function(ply)
    playersConnected = playersConnected + 1
    playersAlive = playersAlive + 1

    if playersConnected >= ROUND_START_PLAYERS then
        StartPrepRound()
    end
end)

hook.Add("PlayerDisconnected", "TrackPlayersInPrep", function(ply)
    playersConnected = math.max(playersConnected - 1, 0)

    if currentRound == ROUND_ACTIVE and playersAlive < ROUND_START_PLAYERS then
        PHZ:RoundEnd()
    end
end)
