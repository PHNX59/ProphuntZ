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


if SERVER then
    AddCSLuaFile()
end
