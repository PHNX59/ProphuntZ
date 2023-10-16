require("mysqloo")

local dbInfo = {
    host = "",
    user = "",
    password = "",
    database = "",
    port = 3306,
}

db = mysqloo.connect(dbInfo.host, dbInfo.user, dbInfo.password, dbInfo.database, dbInfo.port)

db.onConnected = function()
    print("[Prophunt Z] Connexion à la base de données MySQL réussie!")
end

db.onConnectionFailed = function(err)
    print("[Prophunt Z] Échec de la connexion à la base de données MySQL : " .. err)
end

db:connect()

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
                game.KickID(steamID, "[Prophunt Z] Ce SteamID n'est pas autorisé à rejoindre le serveur ! GameMode By Florian_RVD")
                return false, "[Prophunt Z] Ce SteamID n'est pas autorisé à rejoindre le serveur ! GameMode By Florian_RVD"
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
