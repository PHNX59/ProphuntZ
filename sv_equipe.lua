include("shared.lua")
include("sv_rounds.lua")
local hunterMovementState = {}
local MAX_VELOCITY = 200 -- Par exemple, 500 unités par seconde, ajustez selon vos besoins
local hunterAmmoLossAmount = 1 -- Define the amount of health loss per shot

local recentlyFiredHunters = {}
function ConfigurePropsTeam()
    local propModels = {
        "models/player/stanmcg/blockhead_bot/blockhead_bot_playermodel.mdl",
    }

    local propHealth = 100
    local propWalkSpeed = 280

    for _, player in pairs(team.GetPlayers(TEAM_PROPS)) do
        -- Sélectionnez un modèle aléatoire dans la table propModels
        local randomModelIndex = math.random(1, #propModels)
        local propModel = propModels[randomModelIndex]

        -- Sélectionnez une couleur aléatoire en format RGB
        local propColor = Vector(math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255)

        -- Appliquez la couleur au modèle du joueur
        player:SetPlayerColor(propColor)

        -- Configurez d'autres propriétés
        player:SetHealth(propHealth)
        player:SetWalkSpeed(propWalkSpeed)
		player:SetRunSpeed(280)
        player:SetModel(propModel)
        player:StripWeapons()
    end
end

function CreatePropsTeam()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() == TEAM_HUNTERS then
        ConfigurePropsTeam()
        end
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
		end
	end
end

function DrawFloatingHealthBar(target, healthPercentage)
    -- Code pour dessiner la barre de vie flottante
end

local interval = 2
local healthDecreaseAmount = 1

local function DecreaseHunterHealth()
	if currentRound == ROUND_ACTIVE and StartHuntersFreeze then
		for _, player in pairs(team.GetPlayers(TEAM_HUNTERS)) do
			if player:Alive() then
				local currentHealth = player:Health()
				local newHealth = math.max(currentHealth - healthDecreaseAmount, 0) 
				
				if newHealth <= 0 then
					player:Kill()
				else
					player:SetHealth(newHealth)
				end
			end
		end
	end
end

timer.Create("HunterHealthDecreaseTimer", interval, 0, DecreaseHunterHealth)

function CreateHuntersTeam()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() == TEAM_HUNTERS then
        ConfigureHuntersTeam()
        end
    end
end

local function RegenerateHealthForProps()
    for _, player in pairs(player.GetAll()) do
        if player:Team() == TEAM_PROPS then
            local currentHealth = player:Health()
            local maxHealth = player:GetMaxHealth()
            if currentHealth < maxHealth then
                player:SetHealth(math.min(currentHealth + 1, maxHealth))
            end
        end
    end
end

-- Hook to handle shots fired by hunters
hook.Add("EntityFireBullets", "HunterAmmoLoss", function(attacker, data)
    if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() == TEAM_HUNTERS then
        recentlyFiredHunters[attacker] = true

        -- Schedule a timer to remove the hunter from the list after a delay (adjust as needed)
        timer.Simple(1, function()
            recentlyFiredHunters[attacker] = nil
        end)
    end
end)

-- Timer to decrease hunter health for missed shots
timer.Create("HunterAmmoLossTimer", 1, 0, function()
    for hunter, _ in pairs(recentlyFiredHunters) do
        if IsValid(hunter) and hunter:Alive() then
            hunter:SetHealth(math.max(hunter:Health() - hunterAmmoLossAmount, 1)) -- Ensure health does not go below 1
        end
    end
end)

function ConfigureTeamSpectator()
		player:SetModel("models/player/p2_chell.mdl")
		player:SetHealth(hunterHealth)
		player:SetWalkSpeed(180)
		player:SetRunSpeed(180)
		player:SetModel(hunterModel)

end

function CreateTeamSpectator()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() == TEAM_SPECTATORS then
        ConfigureTeamSpectator()
        end
    end
end

hook.Add("HUDDrawNameplates", "DisableNameplates", function()
    return false  -- Cela désactivera l'affichage des noms des joueurs
end)

concommand.Add("join_props", function(ply, cmd, args)
		ply:Kill()
        ply:SetTeam(TEAM_PROPS)
		ply:Spawn()
        ConfigurePropsTeam() 
end)

concommand.Add("join_hunters", function(ply, cmd, args)
		ply:Kill()
        ply:SetTeam(TEAM_HUNTERS)
		ply:Spawn()
        ConfigureHuntersTeam()
end)
