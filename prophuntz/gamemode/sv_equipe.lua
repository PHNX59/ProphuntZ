include("shared.lua")
include("sv_rounds.lua")

function ConfigureSpectatorsTeam(ply)
    if not IsValid(ply) or not ply:IsPlayer() then
        return -- Vérifiez si 'ply' est valide et un joueur, sinon ne faites rien
    end

    ply:SetModel("models/player/Group03m/female_05.mdl")
    ply:SetHealth(0)
    ply:SetWalkSpeed(250)
    ply:SetRunSpeed(250)

    local alpha = 150  -- Vous pouvez ajuster cette valeur selon vos préférences

    ply:SetRenderMode(RENDERMODE_TRANSCOLOR)

    local color = ply:GetColor()
    color.a = alpha
    ply:SetColor(color)

    -- Désactivez les collisions avec les props physiques
    ply:SetCollisionGroup(COLLISION_GROUP_NONE)

    -- Désactivez la gravité pour que le joueur ne tombe pas
    ply:SetGravity(0)

    -- Désactivez l'interpolation pour éviter les problèmes de mouvement
    ply:SetMoveType(MOVETYPE_NOCLIP)
end

function ConfigurePropsTeam()
    local propModels = {
        "models/player/stanmcg/blockhead_bot/blockhead_bot_playermodel.mdl",
    }

    for _, player in pairs(team.GetPlayers(TEAM_PROPS)) do
        -- Sélectionnez un modèle aléatoire dans la table propModels
        local randomModelIndex = math.random(1, #propModels)
        local propModel = propModels[randomModelIndex]

        -- Sélectionnez une couleur aléatoire en format RGB
        local propColor = Vector(math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255)

        -- Appliquez la couleur au modèle du joueur
        player:SetPlayerColor(propColor)

        -- Configurez d'autres propriétés
        player:SetHealth(100)
        player:SetWalkSpeed(220)
		player:SetRunSpeed(220)
		player:SetJumpPower(200)
        player:SetModel(propModel)
        player:StripWeapons()
		player:Spawn()
    end
end

function ConfigureHuntersTeam()
    local hunterWeapons = {
        "weapon_crowbar",
        "weapon_smg1",
        "weapon_shotgun",
        "weapon_pistol",
    }
	
	local hunterModels = {
		"models/yates/rangercombat.mdl",
		"models/yates/rangercombatf.mdl",
	}
    
    local hunterHealth = 150 
    
    local hunterWalkSpeed = 180
    
	for _, player in pairs(team.GetPlayers(TEAM_PROPS)) do
		local randomModelIndex = math.random(1, #hunterModels)
		local hunterModel = hunterModels[randomModelIndex]
		
		-- Sélectionnez une couleur aléatoire en format RGB
		local HunterColor = Vector(math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255)

		-- Appliquez la couleur au modèle du joueur
		player:SetPlayerColor(HunterColor)
		
		for _, player in pairs(team.GetPlayers(TEAM_HUNTERS)) do
			for _, weapon in pairs(hunterWeapons) do
				player:Give(weapon)
			end
			player:GiveAmmo(999, "SMG1") 
			player:GiveAmmo(999, "Pistol")
			player:GiveAmmo(999, "Buckshot")
			player:SetHealth(hunterHealth)
			player:SetWalkSpeed(hunterWalkSpeed)
			player:SetRunSpeed(hunterWalkSpeed)
			player:SetModel(hunterModel)
			player:Spawn()
		end
	end
end

-- Fonction pour supprimer les corps des joueurs après un délai
function RemovePlayerCorpsesWithEffect()
    -- Parcourir tous les joueurs
    for _, ply in pairs(player.GetAll()) do
        -- Vérifier si le joueur est mort et s'il a un corps
        if ply:Alive() == false and IsValid(ply:GetRagdollEntity()) then
            local ragdoll = ply:GetRagdollEntity()

            -- Créer un effet visuel (par exemple, une explosion)
            local effectData = EffectData()
            effectData:SetOrigin(ragdoll:GetPos())
            --util.Effect("Explosion", effectData, true, true)

            -- Planifier la suppression du corps après 5 secondes
            timer.Simple(5, function()
                if IsValid(ragdoll) then
                    ragdoll:Remove()
                end
            end)
        end
    end
end

timer.Create("RemovePlayerCorpsesTimer", 1, 0, RemovePlayerCorpsesWithEffect)

concommand.Add("join_props", function(ply, cmd, args)
		ply:Kill()
        ply:SetTeam(TEAM_PROPS)
        ConfigurePropsTeam() 
end)

concommand.Add("join_hunters", function(ply, cmd, args)
		ply:Kill()
        ply:SetTeam(TEAM_HUNTERS)
        ConfigureHuntersTeam()
end)
