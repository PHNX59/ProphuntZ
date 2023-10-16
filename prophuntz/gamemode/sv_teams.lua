-- Inclure les bibliothèques nécessaires
include("shared.lua")

-- Définition de l'équipe des Props
local TEAM_PROPS = 1
local TEAM_HUNTERS = 2

function Print(message)
    print("[EQUIPE] " .. message)
end

-- Fonction de configuration de l'équipe Props
function ConfigurePropsTeam()
    -- Liste des modèles pour les Props
    local propModels = {
        "models/player/p2_chell.mdl",
        "models/player/alyx.mdl",
        "models/player/odessa.mdl",
        -- Ajoutez d'autres modèles ici
    }

    -- Définir les points de vie des Props
    local propHealth = 100  -- Par exemple, 100 points de vie

    -- Définir la vitesse de marche des Props
    local propWalkSpeed = 320  -- Par exemple, 150 units/seconde

    -- Sélection aléatoire d'un modèle parmi la liste des modèles
    local randomModelIndex = math.random(1, #propModels)
    local propModel = propModels[randomModelIndex]

    -- Appliquer les paramètres aux Props
    for _, player in pairs(team.GetPlayers(TEAM_PROPS)) do
        -- Définir les points de vie des Props
        player:SetHealth(propHealth)
        -- Définir la vitesse de marche des Props
        player:SetWalkSpeed(propWalkSpeed)
        -- Définir le modèle pour les Props
        player:SetModel(propModel)
        -- Vous pouvez ajouter d'autres configurations ici si nécessaire
    end
end

-- Fonction pour définir l'équipe des Props
function CreatePropsTeam(ply)
    if not team.GetAllTeams()[TEAM_PROPS] then
        -- Ne définissez pas le modèle de spawn ici
        -- Appel de la fonction de configuration des Props
		ply:SetTeam(TEAM_PROPS)
        ConfigurePropsTeam()
    end
end

-- Fonction de configuration de la team des chasseurs
function ConfigureHuntersTeam()
    -- Définir les armes à donner aux chasseurs
    local hunterWeapons = {
        "weapon_crowbar",
        "weapon_smg1",
        "weapon_shotgun",
        "weapon_pistol",
        -- Ajoutez d'autres armes ici
    }
		-- Liste des modèles de chasseurs
	local hunterModels = {
		"models/player/police_fem.mdl",
		"models/player/combine_super_soldier.mdl",
		"models/player/police.mdl",
	}
    
    -- Définir les points de vie des chasseurs
    local hunterHealth = 100  -- Par exemple, 100 points de vie
    
    -- Définir la vitesse de marche des chasseurs
    local hunterWalkSpeed = 270  -- Par exemple, 350 units/seconde
    
     -- Sélection aléatoire d'un modèle parmi les trois
    local randomModelIndex = math.random(1, #hunterModels)
    local hunterModel = hunterModels[randomModelIndex]
	
    -- Appliquer les paramètres aux chasseurs
    for _, player in pairs(team.GetPlayers(TEAM_HUNTERS)) do
        -- Donner les armes aux chasseurs
        for _, weapon in pairs(hunterWeapons) do
            player:Give(weapon)
        end
        
        -- Définir les points de vie des chasseurs
        player:SetHealth(hunterHealth)
        
        -- Définir la vitesse de marche des chasseurs
        player:SetWalkSpeed(hunterWalkSpeed)
        
		-- Définir le modèle pour les chasseurs
        player:SetModel(hunterModel)
        -- Vous pouvez ajouter d'autres configurations ici si nécessaire
    end
end

-- Fonction pour définir l'équipe des chasseurs
function CreateHuntersTeam(ply)
    if not team.GetAllTeams()[TEAM_HUNTERS] then
        -- Ne définissez pas le modèle de spawn ici
        -- Appel de la fonction de configuration des chasseurs
		ply:SetTeam(TEAM_HUNTERS)
        ConfigureHuntersTeam()
    end
end

-- Hook PlayerInitialSpawn pour affecter les joueurs à l'équipe des chasseurs ou Props dès leur spawn
hook.Add("PlayerInitialSpawn", "AssignToTeamsOnInitialSpawn", function(player)
    if IsValid(player) then
        if player:Team() != TEAM_HUNTERS and player:Team() != TEAM_PROPS then
            -- Vous pouvez utiliser une logique pour répartir les joueurs entre les équipes ici.
            -- Par exemple, vous pourriez les affecter de manière aléatoire.
            local randomTeam = math.random(1, 2)  -- 1 pour Chasseurs, 2 pour Props

            if randomTeam == 1 then
                player:SetTeam(TEAM_HUNTERS)
                ConfigureHuntersTeam()
            else
                player:SetTeam(TEAM_PROPS)
                ConfigurePropsTeam()  -- Assurez-vous d'ajouter cette fonction si elle n'existe pas encore
            end
        end
    end
end)

-- Commande pour rejoindre l'équipe Props
concommand.Add("join_props", function(ply, cmd, args)
		ply:Kill()
        ply:SetTeam(TEAM_PROPS)
		ply:Spawn()
        ConfigurePropsTeam()  -- Configurez l'équipe Props (si nécessaire)
end)

-- Commande pour rejoindre l'équipe Hunters
concommand.Add("join_hunters", function(ply, cmd, args)
		ply:Kill()
        ply:SetTeam(TEAM_HUNTERS)
		ply:Spawn()
        ConfigureHuntersTeam()  -- Configurez l'équipe Hunters (si nécessaire)
end)