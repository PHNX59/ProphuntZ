local superadmins = {
    "STEAM_0:1:23433387",
    
}

local onlinePlayers = {}

hook.Add("PlayerConnect", "BlockSuperadminAnnouncements", function(name, ip)
    local steamID = util.SteamIDFrom64(name)
    
    if table.HasValue(superadmins, steamID) then
        print("[DEBUG] Superadmin connecté : " .. steamID) 
        print("[DEBUG] Superadmin " .. steamID .. " a été bloqué d'envoyer des annonces.") 
        return "Vous n'avez pas la permission d'envoyer des annonces."
    else
        local player = player.GetBySteamID(steamID)
        if player then
            table.insert(onlinePlayers, player)
            print("[DEBUG] Joueur connecté : " .. player:Nick()) 
        end
    end
end)

hook.Add("PlayerInitialSpawn", "UpdateOnlinePlayers", function(player)
    table.insert(onlinePlayers, player)
    print("[DEBUG] Joueur connecté : " .. player:Nick())
end)

hook.Add("PlayerDisconnected", "UpdateOnlinePlayers", function(player)
    for i, onlinePlayer in ipairs(onlinePlayers) do
        if onlinePlayer == player then
            table.remove(onlinePlayers, i)
            print("[DEBUG] Joueur déconnecté : " .. player:Nick())
            break
        end
    end
end)

local function GetOnlinePlayersExcludingSuperadmins()
    local playersToShow = {}

    for _, player in ipairs(onlinePlayers) do
        local steamID = player:SteamID()
        
        if not table.HasValue(superadmins, steamID) then
            table.insert(playersToShow, player)
        end
    end

    return playersToShow
end