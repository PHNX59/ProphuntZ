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
local ROUND_START_DELAY = 9
local ROUND_END_DELAY = 9
local ROUND_START_PLAYERS = 9
local HUNTERS_FREEZE_TIME = 20
local HUNTERS_BLUR_AMOUNT = 100
local HUNTERS_VISION_ZOOM = 150

local currentRound = ROUND_WAITING
local roundEndTime = 0
local playersInPrep = 0
local playersConnected = 0 
local playersAlive = 0
local numProps = 0
local numHunters = 0
local deadPlayers = {}
local canRespawn = false
local roundInProgress = false


function HandlePlayerJoining(ply)
    playersConnected = playersConnected + 1

    if currentRound == ROUND_ACTIVE or RoundEnd then
        -- Si le round est actif, empêchez le joueur de rejoindre et considérez-le comme mort
        ply:SetTeam(TEAM_SPECTATORS)
        ply:PrintMessage(HUD_PRINTCENTER, "Vous ne pouvez pas rejoindre le jeu pendant le round actif.")
        ply:Kill() -- Tuez le joueur silencieusement (sans effet de mort)
        return
    elseif currentRound == ROUND_PREP or ROUND_WAITING then
        playersInPrep = playersInPrep + 1
    end

    if currentRound == ROUND_PREP or ROUND_WAITING and playersConnected >= ROUND_START_PLAYERS then
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
		print("Joueur gelé", ply:Nick())
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
				print("Joueur degelé", ply:Nick())
                ply:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 0), 0, 0)
                ply:Freeze(false)
                net.Start("PHZ_StopBlur")
                net.Send(ply)
            end
        end

        print("[DEBUG] Fin du gel des chasseurs.")
    end)
end

function AssignRoles(ply)
    if IsValid(ply) and ply:IsPlayer() then
        -- Vérifiez si le joueur n'a pas déjà un rôle
        if ply:Team() == TEAM_UNASSIGNED then
            local players = player.GetAll()
            table.shuffle(players)

            local numPlayers = #players
            local numProps = 0
            local numHunters = 0

            -- Calculez le nombre de "Hunters" en fonction du nombre de joueurs
            if numPlayers < 4 then
                -- Si moins de 4 joueurs, attribuez-les tous en tant que "Props" sauf un chasseur.
                numHunters = 1
                numProps = numPlayers - numHunters
            else
                -- S'il y a 4 joueurs ou plus, attribuez-les en respectant la règle de 1 chasseur pour 3 "Props".
                numHunters = math.floor(numPlayers / 4)
                numProps = numPlayers - numHunters
            end

            for _, player in pairs(players) do
                if numProps > 0 then
                    player:SetTeam(TEAM_PROPS)
                    ConfigurePropsTeam(player) -- Configurez l'équipe "Props" pour le joueur
                    player:Respawn()
                    print("[DEBUG] " .. player:Nick() .. " est un Prop")
                    numProps = numProps - 1
                else
                    player:SetTeam(TEAM_HUNTERS)
                    ConfigureHuntersTeam(player) -- Configurez l'équipe "Hunters" pour le joueur
                    player:Respawn()
                    print("[DEBUG] " .. player:Nick() .. " est un Hunter")
                end
            end

            -- Mettez à jour le nombre de joueurs en vie
            playersAlive = numPlayers
        end
    end
end

hook.Add("PlayerSpawn", "AssignRoles", AssignRoles)

function StartWaitingRound()
    currentRound = ROUND_WAITING
    roundEndTime = 0
    local message = "En attente de joueurs..."

    AssignRoles()

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    numProps = team.NumPlayers(TEAM_PROPS)
    numHunters = team.NumPlayers(TEAM_HUNTERS)

    if numProps >= 1 and numHunters >= 1 then
        local delayInSeconds = 3
        timer.Simple(delayInSeconds, function()
            PHZ:RoundStart()
        end)
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

    timer.Create("CheckPlayersInPrepTimer", 5, 0, function()
        if currentRound == ROUND_PREP then
            local playersInTeams = {} -- Un tableau pour compter les joueurs dans chaque équipe
            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) and ply:IsPlayer() then
                    local teamID = ply:Team()
                    if not playersInTeams[teamID] then
                        playersInTeams[teamID] = 0
                    end
                    playersInTeams[teamID] = playersInTeams[teamID] + 1
                end
            end
            
            local enoughPlayers = true
            for teamID, numPlayers in pairs(playersInTeams) do
                if numPlayers < 1 then
                    enoughPlayers = false
                    break
                end
            end

            if enoughPlayers then
                PHZ:RoundStart()
                timer.Remove("CheckPlayersInPrepTimer")
            end
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
			
			local delayInSeconds = 10
			timer.Simple(delayInSeconds, function()
				PHZ:RoundEnd()
			end)
        end
    end)
end

function PHZ:RoundEnd()
    currentRound = ROUND_END
    roundEndTime = CurTime() + ROUND_END_DELAY
    local message = "Round terminé!"

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    timer.Simple(5, function()
        if currentRound == ROUND_END then
            StartWaitingRound()
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
    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
        return false
    end
end)

hook.Add("PlayerDeath", "PHZ_PlayerDeath", function(ply)
    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
        table.insert(deadPlayers, ply)
    end
	return false
end)

hook.Add("PlayerInitialSpawn", "InitialSpawn", function(ply)
    playersConnected = playersConnected + 1
    playersInPrep = playersInPrep + 1

    -- Si le round est en cours, ne redémarrez pas le round immédiatement
    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
        ply:SetTeam(TEAM_SPECTATORS)
        ply:PrintMessage(HUD_PRINTCENTER, "Vous avez rejoint un round en cours en tant que spectateur.")
        return
    end

    StartWaitingRound()

    if playersConnected >= ROUND_START_PLAYERS then
        PHZ:RoundStart()
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

hook.Add("PlayerDeathThink", "PHZ_PlayerDeathThink", function(ply)
    if currentRound == ROUND_ACTIVE and not canRespawn then
        return false
    end
end)

hook.Add("PlayerDeath", "PlayDeathSound", function(player, inflictor, attacker)
    if player:Team() == TEAM_PROPS then
        -- Jouez le son ici
        player:EmitSound("vo/npc/Barney/ba_damnit.wav")
    end
end)