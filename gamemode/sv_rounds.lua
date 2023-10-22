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

	local soundPath = "ambient/alarms/warningbell1.wav"
    local volume = 1 -- Ajustez le volume si nécessaire
    local pitch = 100 -- Ajustez la hauteur du son (pitch) si nécessaire
    sound.Play(soundPath, Vector(0, 0, 0), volume, pitch, 1, CHAN_AUTO)
	
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
            print("[DEBUG] " .. player:Nick() .. " est un Prop")
        end
    end

    for i = numProps + 1, numProps + numHunters do
        local player = players[i]
        if IsValid(player) then
            player:SetTeam(TEAM_HUNTERS)
            print("[DEBUG] " .. player:Nick() .. " est un Hunter")
        end
    end
	
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and ply:Team() == TEAM_PROPS then
			ply:Spawn()  -- Réapparition du joueur (assurez-vous d'avoir cette fonction définie)
			ConfigurePropsTeam()  -- Configuration de l'équipe "Props" (assurez-vous d'avoir cette fonction définie)
		end
	end
	
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and ply:Team() == TEAM_PROPS then
			ply:Spawn()  -- Réapparition du joueur (assurez-vous d'avoir cette fonction définie)
			ConfigureHuntersTeam()  -- Configuration de l'équipe "Props" (assurez-vous d'avoir cette fonction définie)
		end
	end

    playersAlive = #players
	
end

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

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            if ply:Team() == TEAM_PROPS then
                numProps = numProps + 1
            elseif ply:Team() == TEAM_HUNTERS then
                numHunters = numHunters + 1
            end
        end
    end

    -- Si chaque équipe a au moins un joueur, alors démarrer le round
    if numProps >= 1 and numHunters >= 1 then
        StartPrepRound()
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

hook.Add("PlayerSpawn", "PHZ_PlayerSpawn", function(ply)
    -- Compte combien de joueurs sont déjà dans chaque équipe.
    local numProps = team.NumPlayers(TEAM_PROPS)
    local numHunters = team.NumPlayers(TEAM_HUNTERS)

    -- Si une équipe a 0 joueurs, attribuez au joueur actuel la team qui en a moins.
    if numProps == 0 then
        ply:SetTeam(TEAM_PROPS)
    elseif numHunters == 0 then
        ply:SetTeam(TEAM_HUNTERS)
    else
        -- Si les deux équipes ont déjà un joueur, attribuez-le au hasard.
        if math.random(2) == 1 then
            ply:SetTeam(TEAM_PROPS)
        else
            ply:SetTeam(TEAM_HUNTERS)
        end
    end

    -- Appelez ConfigurePropsTeam() une seule fois après avoir attribué les équipes
    -- Assurez-vous que cette fonction gère la configuration de l'équipe des Props correctement.
    ConfigurePropsTeam()
	ConfigureHuntersTeam()
    -- Le reste de votre code de gestion du spawn des joueurs ici...
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
