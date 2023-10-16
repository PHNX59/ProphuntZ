local adressesIPAutorisees = {
    [""] = true,
}

local fichierBanRcon = "ban_rcon.txt"

local function bannirUtilisateur(ply)
    local steamID = ply:SteamID()
    local ipAddress = ply:IPAddress()
    local heureBan = os.date("%Y-%m-%d %H:%M:%S")

    local fichier = file.Open(fichierBanRcon, "a", "DATA")
    if fichier then
        fichier:Write("SteamID: " .. steamID .. ", IP: " .. ipAddress .. ", Date: " .. heureBan .. "\n")
        fichier:Close()
    end

    ply:Ban(0, "Accès non autorisé à RCON")

    ply:PrintMessage(HUD_PRINTTALK, "[Prophunt Z] Vous avez été banni pour accès non autorisé à RCON.")
end

hook.Add("Rcon_Password", "VerifierAccesRCON", function(ply, password, command)
    local ipAddress = ply:IPAddress()

    if adressesIPAutorisees[ipAddress] then
    else
        bannirUtilisateur(ply)
        return false
    end
end)
