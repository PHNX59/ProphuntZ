include("shared.lua")

util.AddNetworkString("PHZ_StartBlur")
util.AddNetworkString("PHZ_StopBlur")
util.AddNetworkString("PHZ_UpdateRoundState")

local ROUND_WAITING = 0
local ROUND_ACTIVE = 1
local ROUND_END = 2 

local ROUND_TIME = 300
local ROUND_START_PLAYERS = 0
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
local roundStartTime = 0

local deadPlayers = {}
local playerSpectatorModes = {}

local canRespawn = false
local roundInProgress = false

local SPECTATOR_TEAM = TEAM_SPECTATORS

local SPEC_MODES = {
    OBS_MODE_NONE = 0,
    OBS_MODE_DEATHCAM = 1,
    OBS_MODE_FREEZECAM = 2,
    OBS_MODE_FIXED = 3,
    OBS_MODE_IN_EYE = 4,
    OBS_MODE_CHASE = 5,
    OBS_MODE_ROAMING = 6,
}

-- Dans votre script
function ChangeSpectatorView(ply, mode)
    if not ply:IsSpectator() then
        return
    end

    local targetTeam = nil

    if ply:Team() == TEAM_PROPS then
        targetTeam = TEAM_HUNTERS
    elseif ply:Team() == TEAM_HUNTERS then
        targetTeam = TEAM_PROPS
    end

    if not targetTeam then
        return
    end

    local targetPlayer = nil

    for _, player in ipairs(player.GetAll()) do
        if player:Alive() and player:Team() == targetTeam then
            targetPlayer = player
            break
        end
    end

    if targetPlayer then
        ply:SpectateEntity(targetPlayer)
        ply:Spectate(OBS_MODE_IN_EYE)
    end
end

function FindEntityToChase(ply)
    local teamPlayers = team.GetPlayers(ply:Team())

    for _, player in pairs(teamPlayers) do
        if player:Alive() then
            return player
        end
    end

    return nil
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
        PHZ:RoundEnd()
        print("APPEL A LA FONCTION CheckTeamStatus | DeclareWinners(TEAM_HUNTERS)")
    elseif huntersAlive == 0 then
        DeclareWinners(TEAM_PROPS)
        PHZ:RoundEnd()
        print("APPEL A LA FONCTION CheckTeamStatus | DeclareWinners(TEAM_PROPS)")
    end

    if playersAlive == 0 then
        StartWaitingRound()
        print("APPEL A LA FONCTION CheckTeamStatus | StartWaitingRound()")
    end	
end

function HandlePlayerJoining(ply)
	
    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
		ply:Kill()
        ply:SetTeam(TEAM_SPECTATORS)
        ply:PrintMessage(HUD_PRINTCENTER, "Attendez la fin du round pour rejoindre le jeu.")
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

    timer.Create("HUNTERS_FREEZE_TIME", 20, 0, function()
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

    -- Ajustez le nombre de Prop et de Hunter en fonction du nombre de joueurs
    local numPlayers = #players
    local numProps
    local numHunters

    if numPlayers == 2 then
        numProps = 1
        numHunters = 1
    elseif numPlayers == 3 then
		numProps = 2
        numHunters = 1
	else
		numProps = math.ceil(numPlayers / 2) -- Utilisation de "ceil" pour s'assurer que les Props sont plus nombreux si nécessaire
		numHunters = numPlayers - numProps
    end

    -- Équilibrez les équipes en maintenant une différence de +3 pour l'équipe Props
    local maxDifference = 3
    if numProps > numHunters + maxDifference then
        numProps = numHunters + maxDifference
    elseif numHunters > numProps then
        numHunters = numProps
    end

    local assignedProps = 0
    local assignedHunters = 0

    for i = 1, numProps do
        local player = players[i]
        if IsValid(player) then
            player:SetTeam(TEAM_PROPS)
            -- print("[DEBUG] " .. player:Nick() .. " est un Prop")
            assignedProps = assignedProps + 1
            -- player:ChatPrint("Vous êtes un Prop.")
        end
    end

    for i = numProps + 1, numProps + numHunters do
        local player = players[i]
        if IsValid(player) then
            player:SetTeam(TEAM_HUNTERS)
            print("[DEBUG] " .. player:Nick() .. " est un Hunter")
            assignedHunters = assignedHunters + 1
            -- player:ChatPrint("Vous êtes un Hunter.")
            lastHunter = player -- Enregistrez le dernier chasseur
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and ply:Team() == TEAM_PROPS then
            ply:Spawn()
            ConfigurePropsTeam()
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and ply:Team() == TEAM_HUNTERS then
            ply:Spawn()
            ConfigureHuntersTeam()
        end
    end

    playersAlive = #players

    -- Équilibrer les équipes en évitant que le même joueur ne soit un chasseur plus de deux fois à la suite
    if lastHunter then
        local numConsecutiveHunters = 0
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:IsPlayer() and ply:Team() == TEAM_HUNTERS and ply ~= lastHunter then
                numConsecutiveHunters = 0
                break
            elseif IsValid(ply) and ply:IsPlayer() and ply:Team() == TEAM_HUNTERS and ply == lastHunter then
                numConsecutiveHunters = numConsecutiveHunters + 1
            end
        end

        if numConsecutiveHunters >= 2 then
            -- Le dernier chasseur a été chasseur deux fois consécutivement, équilibrez les équipes
            lastHunter:SetTeam(TEAM_PROPS)
            lastHunter:ChatPrint("[Prophunt Z] Vous avez été rééquilibré en tant que Prop.")
            lastHunter = nil
        end
    end

    -- Informez les joueurs du rééquilibrage des équipes
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            if ply:Team() == TEAM_PROPS then
                ply:ChatPrint("[Prophunt Z] Les équipes ont été équilibrées, vous êtes un Prop.")
            elseif ply:Team() == TEAM_HUNTERS then
                ply:ChatPrint("[Prophunt Z] Les équipes ont été équilibrées, vous êtes un Hunter.")
            end
        end
    end
end

function StartWaitingRound()
    currentRound = ROUND_WAITING
    print("État du round :", currentRound)
    roundEndTime = 0
    local message = "En attente de joueurs..."
	
	AssignRoles() 
	
    -- Utilisez un timer qui vérifie régulièrement les conditions pour démarrer le round
    local timerName = "CheckTeamsAndStartRound"
    local timerInterval = 5 -- Interval de vérification en secondes

    local function CheckAndStartRound()
        local numProps = 0
        local numHunters = 0

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:IsPlayer() then
                if ply:Team() == TEAM_PROPS then
                    numProps = numProps + 1
                    -- print("Nombre de Props", numProps)
                elseif ply:Team() == TEAM_HUNTERS then
                    numHunters = numHunters + 1
                    -- print("Nombre de HUNTERS", numHunters)
                end
            end
        end

		print("Hunters: ", numHunters, "Props :", numProps)
        if numProps >= 1 and numHunters >= 1 then
            AssignRoles()
            PHZ:RoundStart()
            print("APPEL À LA FONCTION StartWaitingRound | RoundStart()")
            timer.Remove("CheckTeamsAndStartRound")  -- Arrêtez la vérification une fois que le round a démarré.
        end
    end

    -- Créez le timer
    timer.Create(timerName, timerInterval, 0, CheckAndStartRound)

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end
end

function PHZ:RoundStart()
    currentRound = ROUND_ACTIVE
    print("État du round :", currentRound)
    roundStartTime = CurTime() -- Enregistrez le temps de début du round
    roundEndTime = roundStartTime + ROUND_TIME
    roundInProgress = true
 	
    local message = "La chasse commence!"

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    StartHuntersFreeze()

    timer.Create("ROUND_TIME", ROUND_TIME, 0, function()
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
				print("APPEL A LA FONCTION RoundStart | DeclareWinners(TEAM_PROPS)")
            else
                DeclareWinners(TEAM_HUNTERS)
				print("APPEL A LA FONCTION RoundStart | DeclareWinners(TEAM_HUNTERS)")
            end
			
            PHZ:RoundEnd()
			print("APPEL A LA FONCTION RoundStart | RoundEnd()")
			timer.Remove(ROUND_TIME)
        end
    end)
end

function PHZ:RoundEnd()
    currentRound = ROUND_END
    print("État du round :", currentRound)
    roundEndTime = CurTime() + 10
    local message = "Round terminé!"

    local huntersAlive = 0
    local propsAlive = 0

    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:Team() == TEAM_PROPS then
            propsAlive = propsAlive + 1
        elseif ply:Alive() and ply:Team() == TEAM_HUNTERS then
            huntersAlive = huntersAlive + 1
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
        end
    end

    local roundendtimer = "Roundendtimer" -- Nom du minuteur pour pouvoir le supprimer ultérieurement si nécessaire

    timer.Create(roundendtimer, 8, 0, function()
        if currentRound == ROUND_END then
            StartWaitingRound()
            print("APPEL À LA FONCTION PHZ:RoundEnd | StartWaitingRound()")
			
			-- Nettoyez les débris ici
			game.CleanUpMap()
			
		else
            timer.Remove(roundendtimer) -- Supprime le minuteur lorsque currentRound n'est plus égal à ROUND_END
        end
        -- Réactiver la possibilité de réapparaître
		roundInProgress = false
        canRespawn = false
    end)
end

function DeclareWinners(winningTeam)
    local message = ""
    local winnerNames = ""

    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v:IsPlayer() and v:Team() == winningTeam then
            winnerNames = winnerNames .. v:Nick() .. ", "
        end
    end

    if winningTeam == TEAM_HUNTERS then
        message = "[Prophunt Z] Les Chasseurs ont gagné!"
    else
        message = "[Prophunt Z] Les Props ont gagné!"
    end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() then
            ply:PrintMessage(HUD_PRINTCENTER, message)
            ply:ChatPrint(message)
            ply:ChatPrint("Gagnants : " .. winnerNames)
        end
    end

    PHZ:RoundEnd()
	print("APPEL A LA FONCTION DeclareWinners | RoundEnd()")
end

function CheckForDraw()
    local allPlayers = player.GetAll()
    local allPlayersDead = true

    for _, ply in ipairs(allPlayers) do
        if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
            allPlayersDead = false
            break
        end
    end

    if allPlayersDead then
        -- Annoncez un match nul et redémarrez le round
        for _, ply in ipairs(allPlayers) do
            if IsValid(ply) and ply:IsPlayer() then
                ply:PrintMessage(HUD_PRINTCENTER, "Match nul - Tout le monde est mort.")
                ply:ChatPrint("Match nul - Tout le monde est mort.")
            end
        end
        PHZ:RoundEnd() -- Redémarrez le round
    end
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
			print("APPEL A LA FONCTION Think | DeclareWinners(TEAM_HUNTERS)")
        elseif huntersAlive == 0 then
            DeclareWinners(TEAM_PROPS)
            PHZ:RoundEnd()
			print("APPEL A LA FONCTION Think | DeclareWinners(TEAM_PROPS)")
        end
		CheckForDraw() -- Vérifiez s'il y a un match nul
    end
	
    net.Start("PHZ_UpdateRoundState")
    net.WriteInt(currentRound, 32)
    net.WriteFloat(math.max(0, roundEndTime - CurTime()))
    net.Broadcast()
end

hook.Add("PlayerSpawn", "InitialSpawn", function(ply)

	if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
		ply:Kill()
		ply:SetTeam(TEAM_SPECTATORS)
		canRespawn = false
	end
end)

hook.Add("PlayerInitialSpawn", "InitialSpawn", function(ply)
    playersConnected = playersConnected + 1
    playersInPrep = playersInPrep + 1

    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
        -- Si le round est déjà actif ou terminé, mettez le joueur en mode spectateur
        ply:Kill()
        ply:SetTeam(TEAM_SPECTATORS)
        canRespawn = false
        ply:ChatPrint("Vous devez attendre la fin du round pour rejoindre une équipe.")
    elseif currentRound == ROUND_WAITING then
        -- Si le round est en attente, attribuez-lui un rôle
        AssignRoles()
        -- Notez qu'il n'y a plus d'appel à PHZ:RoundStart() ici
        ply:Spawn()
    end

    local numProps = 0
    local numHunters = 0

    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:IsPlayer() then
            if p:Team() == TEAM_PROPS then
                numProps = numProps + 1
            elseif p:Team() == TEAM_HUNTERS then
                numHunters = numHunters + 1
            end
        end
    end

    if numProps >= 1 and numHunters >= 1 then
        -- Assurez-vous que le round n'est pas redémarré lorsque le joueur rejoint
        if currentRound ~= ROUND_ACTIVE then
            PHZ:RoundStart()
        end
    end
end)

hook.Add("CanPlayerSuicide", "PHZ_CanPlayerSuicide", function(ply)
    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
        return false
    end
end)

hook.Add("PlayerDeath", "PHZ_PlayerDeath", function(ply)
    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
        table.insert(deadPlayers, ply)
        ply:SetTeam(SPECTATOR_TEAM) -- Mettez le joueur en mode spectateur lorsqu'il meurt
        ply:StripWeapons() -- Retirez les armes du joueur
        ply:UnSpectate() -- Assurez-vous qu'il n'est pas en mode spectateur avant de le mettre en spectateur
        ply:Spectate(SPEC_MODES.OBS_MODE_ROAMING) -- Définissez le mode spectateur par défaut
        ply:SpectateEntity(nil) -- Réinitialisez l'entité à suivre
        playerSpectatorModes[ply] = SPEC_MODES.OBS_MODE_ROAMING -- Réinitialisez le mode spectateur
        -- Vous pouvez ajouter d'autres actions ici, comme le changement de vue immédiat en mode chase si vous le souhaitez.
    end
    return false
end)

hook.Add("PlayerDisconnected", "TrackPlayersInPrep", function(ply)
    if currentRound == ROUND_ACTIVE and numProps >= 1 and numHunters >= 1 then
        PHZ:RoundEnd()
		print("APPEL A LA FONCTION PlayerDisconnected | RoundEnd()")
    elseif currentRound == ROUND_WAITING and numProps >= 1 and numHunters >= 1 then
        StartWaitingRound()
		print("APPEL A LA FONCTION PlayerDisconnected | StartWaitingRound()")
    end
end)

local function PlayerConnect(name, ip)
    return "", true
end
hook.Add("PlayerConnect", "HidePlayerInfo", PlayerConnect)

hook.Add("PlayerDeathThink", "PHZ_PlayerDeathThink", function(ply)
    if currentRound == ROUND_ACTIVE or currentRound == ROUND_END then
        return false  -- Empêche le respawn des joueurs pendant le round actif ou le round end
    end
end)

hook.Add("PlayerDeath", "PlayDeathSound", function(player, inflictor, attacker)
    if player:Team() == TEAM_PROPS then
        player:EmitSound("vo/npc/Barney/ba_damnit.wav")
    end
end)

hook.Add("PlayerBindPress", "ChangeSpectatorView", function(ply, bind, pressed)
    if pressed then
        if bind == "+attack2" then
            ChangeSpectatorView(ply, "spectate_next")
        elseif bind == "+attack" then
            ChangeSpectatorView(ply, "spectate_prev")
        end
    end
end)
