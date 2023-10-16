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
    for _, ply in ipairs(player.GetAll()) do
		ply:KillSilent()
        ply:Respawn()  -- Respawn le joueur s'il est mort
			if ply:Team() == TEAM_PROPS then
				ConfigurePropsTeam()
			elseif ply:Team() == TEAM_HUNTERS then
				ConfigureHuntersTeam()
			end
		print("Les joueur ont eter respawn")
    end
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

-- Initialisation
function PHZ:Initialize()
    print("[DEBUG] Initialisation...")
    StartPrepRound()
end

-- Commence la préparation du round
function StartPrepRound()
    print("[DEBUG] Commencement du round de préparation...")
    currentRound = ROUND_PREP
    roundEndTime = CurTime() + 15

    -- Notifier les joueurs
    for _, v in ipairs(player.GetAll()) do
        v:ChatPrint("Round de préparation commence!")
    end
end

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
    StartPrepRound()
	 
    -- Respawn et notifier les joueurs
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then
            ply:Spawn()  -- Respawn le joueur s'il est mort
        end
        ply:ChatPrint("La chasse commence!")
    end

    -- Geler et obscurcir la vision des hunters
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == "TEAM_HUNTERS" then  -- Remplacez par votre méthode pour vérifier le rôle du joueur
            ply:Freeze(true)  -- Freeze le joueur
            net.Start("PHZ_StartBlur")
            net.Send(ply)  -- Demande au client d'activer le flou
        end
    end

    timer.Simple(20, function()  -- Après 20 secondes
        for _, ply in ipairs(player.GetAll()) do
            if ply:Team() == "TEAM_HUNTERS" then
                ply:Freeze(false)  -- Dégèle le joueur
                net.Start("PHZ_StopBlur")
                net.Send(ply)  -- Demande au client de désactiver le flou
            end
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
