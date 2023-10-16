DEFINE_BASECLASS("base")
PHZ = {}
PHZ.Name = "Prophunt Z"
PHZ = GM

if PHZ == GM then
    GM = GAMEMODE
    print("[PROPHUNTZ] Réussite : PHZ a été défini à GAMEMODE.")
else
    print("[PROPHUNTZ]Erreur : PHZ n'est pas égal à GM, aucune modification n'a été apportée.")
end


AddCSLuaFile("cl_hud.lua")
include("sv_scorboard.lua") 
include("rcon_lock.lua") 
include("sv_teams.lua")
include("sv_rounds.lua")
include("sv_devmode.lua")
include("sv_deaths.lua")
include("sv_competences.lua")
include("sv_cailloux.lua")
include("sv_transformation.lua")
include("sv_equilibrage.lua")

local function EnableThirdPerson(ply)
    local view = {}
    view.origin = ply:GetPos() - ply:GetForward() * 100 
    view.angles = ply:EyeAngles()
    view.fov = ply:GetFOV()
    view.drawviewer = true

    ply:SetViewEntity(ply)
    ply:SendLua([[
        local view = {}
        view.origin = Vector(]] .. view.origin.x .. "," .. view.origin.y .. "," .. view.origin.z .. [[)
        view.angles = Angle(]] .. view.angles.p .. "," .. view.angles.y .. "," .. view.angles.r .. [[)
        view.fov = ]] .. view.fov .. [[
        view.drawviewer = true
        return view
    ]])

    ply:SetNWBool("IsInThirdPerson", true)
end

hook.Add("PlayerInitialSpawn", "EnableThirdPersonOnJoin", function(ply)
    EnableThirdPerson(ply)
end)

function PHZ:Initialize()
	print([[
	print([[
	ooooooooo.   ooooooooo.     .oooooo.   ooooooooo.   ooooo   ooooo ooooo     ooo ooooo      ooo ooooooooooooo     oooooooooooo
	`888   `Y88. `888   `Y88.  d8P'  `Y8b  `888   `Y88. `888'   `888' `888'     `8' `888b.     `8' 8'   888   `8    d'""""""d888'
	 888   .d88'  888   .d88' 888      888  888   .d88'  888     888   888       8   8 `88b.    8       888               .888P
	 888ooo88P'   888ooo88P'  888      888  888ooo88P'   888ooooo888   888       8   8   `88b.  8       888              d888'
	 888          888`88b.    888      888  888          888     888   888       8   8     `88b.8       888            .888P
	 888          888  `88b.  `88b    d88'  888          888     888   `88.    .8'   8       `888       888           d888'    .P
	o888o        o888o  o888o  `Y8bood8P'  o888o        o888o   o888o    `YbodP'    o8o        `8      o888o        .8888888888P
	]])
	print([[[PROPHUNTZ] GameMode By Florian_RVD version 0.1]])
end

function PHZ:StartWaitingRound()
end

function PHZ:OnStartRound()
	print("[PROPHUNTZ] Le round a correctement été demarrer.")
end

function PHZ:OnReloaded()
	print("[PROPHUNTZ] Le code du gamemode a été rechargé.")
end

function PHZ:OnEndRound()
	print("[PROPHUNTZ] Le round a correctement été terminer.")
end
