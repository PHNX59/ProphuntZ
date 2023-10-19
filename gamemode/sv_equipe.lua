include("shared.lua")

function ConfigurePropsTeam()
    local propModels = {
        "models/player/p2_chell.mdl",
        "models/player/alyx.mdl",
        "models/player/odessa.mdl",
    }

    local propHealth = 100  

    local propWalkSpeed = 280 

    local randomModelIndex = math.random(1, #propModels)
    local propModel = propModels[randomModelIndex]

    for _, player in pairs(team.GetPlayers(TEAM_PROPS)) do
        player:SetHealth(propHealth)
        player:SetWalkSpeed(propWalkSpeed)
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
		"models/player/police_fem.mdl",
		"models/player/combine_super_soldier.mdl",
		"models/player/police.mdl",
	}
    
    local hunterHealth = 100 
    
    local hunterWalkSpeed = 220
    
    local randomModelIndex = math.random(1, #hunterModels)
    local hunterModel = hunterModels[randomModelIndex]
	
    for _, player in pairs(team.GetPlayers(TEAM_HUNTERS)) do
        for _, weapon in pairs(hunterWeapons) do
            player:Give(weapon)
        end
        
        player:SetHealth(hunterHealth)
        player:SetWalkSpeed(hunterWalkSpeed)
        player:SetModel(hunterModel)
    end
end

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
