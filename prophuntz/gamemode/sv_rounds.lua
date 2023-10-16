include("shared.lua")

-- Assurez-vous d'avoir ces lignes en haut de votre fichier pour utiliser le système 'net'
util.AddNetworkString("PHZ_StartBlur")
util.AddNetworkString("PHZ_StopBlur")
util.AddNetworkString("PHZ_UpdateRoundState")


local PLAYER = FindMetaTable("Player")

function PLAYER:SetRole(role)
    self.Role = role -- Stocke le rôle comme variable membre du joueur
end

function PLAYER:GetRole()
    return self.Role
end

TEAM_PROPS = 1 
TEAM_HUNTERS = 2 

-- Variables
local ROUND_PREP = 1
local ROUND_ACTIVE = 2
local ROUND_END = 3
local ROUND_TIME = 300 -- 5 minutes par exemple

local currentRound = ROUND_PREP
local roundEndTime = 0

-- Fonction pour mélanger un tableau
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
        ply:KillSilent()
        ply:Respawn()
        print("[DEBUG] Respawn du joueur : " .. ply:Nick())
        if ply:Team() == TEAM_PROPS then
            ConfigurePropsTeam()
        elseif ply:Team() == TEAM_HUNTERS then
            ConfigureHuntersTeam()
        end
    end
    print("[DEBUG] Fin de RespawnAllPlayers()")
end

function StartHuntersFreeze()
	for _, ply in ipairs(player.GetAll()) do
		if ply:GetRole() == TEAM_HUNTERS then  -- Remplacez par votre méthode pour vérifier le rôle du joueur
			ply:Freeze(true)  -- Freeze le joueur
			net.Start("PHZ_StartBlur")
			net.Send(ply)  -- Demande au client d'activer le flou
		end
	end
	
	timer.Simple(20, function()  -- Après 20 secondes
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetRole() == TEAM_HUNTERS then
				ply:Freeze(false)  -- Dégèle le joueur
				net.Start("PHZ_StopBlur")
				net.Send(ply)  -- Demande au client de désactiver le flou
			end
		end
	end)
end

-- Attribue les rôles
function AssignRoles()
    print("[DEBUG] Attribution des rôles...")
    local players = player.GetAll()
    table.shuffle(players)

    local numProps = math.floor(#players / 2)

    for i=1, numProps do
        players[i]:SetTeam(TEAM_PROPS)  -- Notez que nous utilisons la constante directement, sans guillemets
        ConfigurePropsTeam(players[i])   -- Je suppose que vous voulez configurer chaque joueur individuellement
        print("[DEBUG] " .. players[i]:Nick() .. " est un Prop")
    end

    for i=numProps + 1, #players do
        players[i]:SetTeam(TEAM_HUNTERS)  -- De même ici, utilisez la constante sans guillemets
        ConfigureHuntersTeam(players[i])  -- Configuration individuelle du joueur
        print("[DEBUG] " .. players[i]:Nick() .. " est un Hunter")
    end
end

function PHZ:Initialize()
    print("[DEBUG] Initialisation de PHZ")
    StartPrepRound()
end

function StartPrepRound()
    print("[DEBUG] Début de StartPrepRound()")
    currentRound = ROUND_PREP
    roundEndTime = CurTime() + 15
    print("[DEBUG] Etat actuel : ROUND_PREP | Temps de fin : " .. roundEndTime)
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint("Round de préparation commence!")
    end
    print("[DEBUG] Fin de StartPrepRound()")
    
    -- Démarrer le round actif après le temps de préparation
    timer.Simple(15, function()
        if currentRound == ROUND_PREP then
            PHZ:RoundStart()
        end
    end)
end

-- Vérifie l'état des équipes pour déterminer si une équipe a gagné
function CheckTeamStatus()
    local propsAlive = 0
    local huntersAlive = 0

    -- Compte le nombre de joueurs vivants pour chaque équipe
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:Team() == TEAM_PROPS then
            propsAlive = propsAlive + 1
        elseif ply:Alive() and ply:Team() == TEAM_HUNTERS then
            huntersAlive = huntersAlive + 1
        end
    end

    -- Vérifie si une des équipes a gagné
    if propsAlive == 0 then
        DeclareWinners(TEAM_HUNTERS)
    elseif huntersAlive == 0 then
        DeclareWinners(TEAM_PROPS)
    end
end

-- Déclare l'équipe gagnante
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

-- Hook pour écouter le décès d'un joueur
hook.Add("PlayerDeath", "PHZ_PlayerDeath", function(victim, inflictor, attacker)
    timer.Simple(1, function() -- Utilise un délai pour permettre à toutes les fonctions de s'exécuter correctement avant de vérifier l'état des équipes
        CheckTeamStatus()
    end)
end)

-- Commence le round
function PHZ:RoundStart()
    print("[DEBUG] Commencement du round actif...")
    currentRound = ROUND_ACTIVE
    roundEndTime = CurTime() + ROUND_TIME
	
	net.Start("PHZ_UpdateRoundState")
	net.WriteInt(currentRound, 32)
	net.WriteFloat(roundEndTime)
	net.Broadcast()
	
	RespawnAllPlayers()
	AssignRoles()
	
    -- Respawn et notifier les joueurs
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then
            ply:Spawn()  -- Respawn le joueur s'il est mort
        end
        ply:ChatPrint("La chasse commence!")
    end
	
	-- Lorsque le timer du round actif est terminé, vérifiez si des props sont encore en vie. Si oui, ils gagnent.
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
	
-- Fin du round
function PHZ:RoundEnd()
    print("[DEBUG] Fin du round...")
    currentRound = ROUND_END
    roundEndTime = CurTime() + 10

    -- Notifier les joueurs
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint("Round terminé!")
    end
	
	-- Après un court délai, revenez à la phase de préparation.
    timer.Simple(5, function()  -- Par exemple, attendez 5 secondes avant de commencer un nouveau round
        if currentRound == ROUND_END then
            StartPrepRound()
        end
    end)
end

-- Gestionnaire de Think
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

-- Empêche le respawn pendant un round actif
hook.Add("PlayerDeathThink", "PHZ_PreventRespawnDuringRound", function(ply)
    if currentRound == ROUND_ACTIVE then
        return false  -- Empêche le respawn
    end
end)
