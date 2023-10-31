-- Commande pour démarrer un nouveau round
function ulx.startround(calling_ply)
    -- Insérez ici la logique pour démarrer un nouveau round
    -- Par exemple, vous pouvez appeler votre fonction PHZ:RoundStart()
    PHZ:RoundStart()
    ulx.fancyLogAdmin(calling_ply, "#A a démarré un nouveau round.")
end
local startround = ulx.command("Prophunt Z Commandes", "ulx startround", ulx.startround, "!startround")
startround:defaultAccess(ULib.ACCESS_ADMIN)
startround:help("Démarre un nouveau round.")

-- Commande pour arrêter le round en cours
function ulx.stopround(calling_ply)
    -- Insérez ici la logique pour arrêter le round en cours
    -- Par exemple, vous pouvez appeler votre fonction PHZ:RoundEnd()
    PHZ:RoundEnd()
    ulx.fancyLogAdmin(calling_ply, "#A a arrêté le round en cours.")
end
local stopround = ulx.command("Prophunt Z Commandes", "ulx stopround", ulx.stopround, "!stopround")
stopround:defaultAccess(ULib.ACCESS_ADMIN)
stopround:help("Arrête le round en cours.")

-- Fonction pour basculer un joueur entre TEAM_HUNTERS et TEAM_PROPS
function ulx.switchteam(calling_ply, target_ply)
    if not IsValid(target_ply) then
        ULib.tsayError(calling_ply, "Le joueur cible est invalide.")
        return
    end

    -- Vérifiez si le joueur est actuellement dans TEAM_HUNTERS ou TEAM_PROPS
    if target_ply:Team() == TEAM_HUNTERS then
        target_ply:SetTeam(TEAM_PROPS)
    elseif target_ply:Team() == TEAM_PROPS then
        target_ply:SetTeam(TEAM_HUNTERS)
    else
        ULib.tsayError(calling_ply, "Le joueur n'est ni dans l'équipe TEAM_HUNTERS ni dans l'équipe TEAM_PROPS.")
        return
    end

    ulx.fancyLogAdmin(calling_ply, "#A a basculé #T dans une équipe différente.", target_ply)
end

-- Créer la commande ULX pour basculer un joueur d'équipe
local switchteam = ulx.command("Prophunt Z Commandes", "ulx switchteam", ulx.switchteam, "!switchteam")
switchteam:addParam{type=ULib.cmds.PlayerArg}
switchteam:defaultAccess(ULib.ACCESS_ADMIN)
switchteam:help("Basculer un joueur entre TEAM_HUNTERS et TEAM_PROPS.")

if SERVER then
    AddCSLuaFile()
end
