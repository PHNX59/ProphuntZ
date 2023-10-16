-- Liste des adresses IP autorisées
local adressesIPAutorisees = {
    [""] = true,
    -- Ajoutez d'autres adresses IP au besoin
}

-- Chemin du fichier de bannissement RCON
local fichierBanRcon = "ban_rcon.txt"

-- Fonction pour bannir un utilisateur et enregistrer les informations
local function bannirUtilisateur(ply)
    local steamID = ply:SteamID()
    local ipAddress = ply:IPAddress()
    local heureBan = os.date("%Y-%m-%d %H:%M:%S")

    -- Enregistrer les informations dans le fichier de bannissement
    local fichier = file.Open(fichierBanRcon, "a", "DATA")
    if fichier then
        fichier:Write("SteamID: " .. steamID .. ", IP: " .. ipAddress .. ", Date: " .. heureBan .. "\n")
        fichier:Close()
    end

    -- Bannir l'utilisateur
    ply:Ban(0, "Accès non autorisé à RCON")

    -- Afficher un message à l'utilisateur
    ply:PrintMessage(HUD_PRINTTALK, "[Prophunt Z] Vous avez été banni pour accès non autorisé à RCON.")
end

-- Hook pour vérifier l'accès RCON
hook.Add("Rcon_Password", "VerifierAccesRCON", function(ply, password, command)
    local ipAddress = ply:IPAddress()

    if adressesIPAutorisees[ipAddress] then
        -- L'utilisateur est autorisé, ne rien faire
    else
        -- L'utilisateur n'est pas autorisé, le bannir
        bannirUtilisateur(ply)
        return false
    end
end)
