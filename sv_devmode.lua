require("mysqloo")

local joueursAjoutes = {} 

local dbInfo = {
    host = "94.23.50.189",
    user = "prophuntz",
    password = "qtY3SyphAunae41H",
    database = "prophuntz",
    port = 3306,
}

db = mysqloo.connect(dbInfo.host, dbInfo.user, dbInfo.password, dbInfo.database, dbInfo.port)

db.onConnected = function()
    local createSteamIDsTableQuery = [[
        CREATE TABLE IF NOT EXISTS steamids_autoriser (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steamid VARCHAR(20) NOT NULL
        )
    ]]
    
	local createPlayersTableQuery = [[
		CREATE TABLE IF NOT EXISTS players (
			id INT AUTO_INCREMENT PRIMARY KEY,
			steamid VARCHAR(20) NOT NULL,
			username VARCHAR(255) NOT NULL,
			ip VARCHAR(45) NOT NULL
		)
	]]
    
    local combinedQuery = createSteamIDsTableQuery .. "; " .. createPlayersTableQuery
    
    local query = db:query(combinedQuery)
    query:start()
end

db.onConnected = function()
    print("[Prophunt Z] Connexion à la base de données MySQL réussie!")
end

db.onConnectionFailed = function(err)
    print("[Prophunt Z] Échec de la connexion à la base de données MySQL : " .. err)
end

db:connect()
--[[
function VerifierSteamID(steamID64, callback)
    local steamID = util.SteamIDFrom64(steamID64)
    local query = db:query("SELECT steamid FROM steamids_autoriser WHERE steamid = '" .. steamID .. "'")

    function query:onSuccess(data)
        if data and data[1] and data[1].steamid == steamID then
            print("[Prophunt Z] SteamID autorisé : " .. steamID)
            callback(true) 
        else
            print("[Prophunt Z] SteamID non autorisé : " .. steamID)
            callback(false) 
        end
    end

    function query:onError(err)
        print("[Prophunt Z] Erreur lors de la requête SQL : " .. err)
        callback(false)
    end

    query:start()
end

function AjouterSteamIDAutorise(steamID)
    local query = db:query("INSERT INTO steamids_autoriser (steamid) VALUES ('" .. steamID .. "')")
    
    function query:onSuccess()
        print("[Prophunt Z] SteamID ajouté à la liste des autorisés : " .. steamID)
    end
    
    function query:onError(err)
        print("[Prophunt Z] Erreur lors de l'ajout du SteamID à la liste des autorisés : " .. err)
    end
    
    query:start()
end

function EstSteamIDAutorise(steamID, callback)
    local query = db:query("SELECT steamid FROM steamids_autoriser WHERE steamid = '" .. steamID .. "'")

    function query:onSuccess(data)
        if data and data[1] and data[1].steamid == steamID then
            print("[Prophunt Z] SteamID autorisé : " .. steamID)
            callback(true) 
        else
            print("[Prophunt Z] SteamID non autorisé : " .. steamID)
            callback(false) 
        end
    end

    function query:onError(err)
        print("[Prophunt Z] Erreur lors de la requête SQL : " .. err)
        callback(false)
    end

    query:start()
end

hook.Add("CheckPassword", "VerificationSteamIDAutorise", function(steamID64)
    local steamID = util.SteamIDFrom64(steamID64)
    local estAdmin = false
    for _, ply in ipairs(player.GetAll()) do
        local plySteamID64 = ply:SteamID64()
        if plySteamID64 == steamID64 and (ply:IsSuperAdmin() or ply:IsAdmin()) then
            estAdmin = true
            break
        end
    end

    if estAdmin then
        return true
    else
        VerifierSteamID(steamID64, function(estAutorise)
            if estAutorise then
                return true
            else
                game.KickID(steamID, "[Prophunt Z] Contactez-moi pour que je vous ajoute à la liste blanche ! Discord florian_rvd")
                return true, "[Prophunt Z] Contactez-moi pour que je vous ajoute à la liste blanche ! Discord :florian_rvd"
            end
        end)
    end
end)

concommand.Add("addsteamid", function(ply, cmd, args)
    if not IsValid(ply) or ply:IsSuperAdmin() then
        local steamID = args[1]

        if steamID then
            AjouterSteamIDAutorise(steamID)
            print("[Prophunt Z] SteamID ajouté aux autorisés : " .. steamID)
            if IsValid(ply) then
                ply:ChatPrint("[Prophunt Z] SteamID ajouté aux autorisés : " .. steamID)
            end
        else
            if IsValid(ply) then
                ply:ChatPrint("[Prophunt Z] Utilisation : addsteamid <SteamID>")
            end
        end
    end
end)

hook.Add("PlayerSay", "AddSteamIDCommand", function(ply, text, public)
    if ply:IsSuperAdmin() then
        if string.lower(text) == "!addsteamid" then
            ply:ChatPrint("[Prophunt Z] Utilisation : !addsteamid <SteamID>")
            return ""
        elseif string.sub(text, 1, 12) == "!addsteamid " then
            local steamID = string.sub(text, 13)
            AjouterSteamIDAutorise(steamID)
            print("[Prophunt Z] SteamID ajouté aux autorisés : " .. steamID)
            ply:ChatPrint("[Prophunt Z] SteamID ajouté aux autorisés : " .. steamID)
            return ""
        end
    end
end)
--]]
function JoueurExiste(steamID, callback)
    local query = db:query("SELECT steamid FROM players WHERE steamid = '" .. steamID .. "'")

    function query:onSuccess(data)
        if data and data[1] and data[1].steamid == steamID then
            callback(true)
        else
            callback(false)
        end
    end

    function query:onError(err)
        print("[Prophunt Z] Erreur lors de la requête SQL : " .. err)
        callback(false)
    end

    query:start()
end

function AjouterJoueur(steamID, username, ip)
    local query = db:prepare("INSERT INTO players (steamid, username, ip) VALUES (?, ?, ?)")
    query:setString(1, steamID)
    query:setString(2, username)
    query:setString(3, ip)
    
    function query:onSuccess()
        print("[Prophunt Z] Joueur ajouté à la table 'players': SteamID = " .. steamID .. ", Username = " .. username .. ", IP = " .. ip)
    end
    
    function query:onError(err)
        print("[Prophunt Z] Erreur lors de l'ajout du joueur à la table 'players': " .. err)
    end
    
    query:start()
end

hook.Add("PlayerInitialSpawn", "AjouterJoueurDansTable", function(ply)
    local steamID = ply:SteamID()
    local username = ply:Nick()
    local ip = ply:IPAddress()
    JoueurExiste(steamID, function(existe)
        if not existe then
            AjouterJoueur(steamID, username, ip)
        end
    end)
end)
