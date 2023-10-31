require("mysqloo")

local dbHostname = "94.23.50.189"
local dbPort = 3306
local dbName = "prophuntz"
local dbUser = "prophuntz"
local dbPass = "qtY3SyphAunae41H"

local db = mysqloo.connect(dbHostname, dbUser, dbPass, dbName)

function db:onConnectionFailed(err)
    print("La connexion à la base de données a échoué : " .. err)
end

function db:onConnected()
    print("Connexion à la base de données réussie.")
    
    -- Vérifiez si la table player_notes existe, sinon créez-la avec les nouveaux champs
    local query = db:query([[
        CREATE TABLE IF NOT EXISTS player_notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steam_id VARCHAR(255) NOT NULL,
            note FLOAT NOT NULL,
            message TEXT,
            note_datetime DATETIME NOT NULL
        )
    ]])
    query:start()
end

db:connect()

function SavePlayerNote(ply, note, message)
    note = tonumber(note)
    if note and note >= 0 and note <= 5 then
        local currentDateTime = os.date("%Y-%m-%d %H:%M:%S")
        
        local query = db:query("INSERT INTO player_notes (steam_id, note, message, note_datetime) VALUES ('" .. ply:SteamID() .. "', " .. note .. ", '" .. db:escape(message) .. "', '" .. currentDateTime .. "')")
        query:start()
        return true
    else
        print(ply:Nick() .. " a tenté d'enregistrer une note invalide : " .. note)
        return false
    end
end

-- Utilisez ulx pour définir la commande !rate
if SERVER then
    function ulx.rate(calling_ply, target_ply, note, message)
        local result = SavePlayerNote(target_ply, note, message)
        if result then
            ulx.fancyLogAdmin(calling_ply, "#A a enregistré une note de #s pour #T avec le message : #s", note, target_ply, message)
        else
            ulx.fancyLogAdmin(calling_ply, "#A a tenté d'enregistrer une note invalide pour #T : #s", target_ply, note)
        end
    end

    local rate = ulx.command("Fun", "ulx rate", ulx.rate, "!rate")
    rate:addParam({ type = ULib.cmds.PlayerArg })
    rate:addParam({ type = ULib.cmds.NumArg, hint = "Note", min = 0, max = 5 })
    rate:addParam({ type = ULib.cmds.StringArg, hint = "Message", ULib.cmds.optional })
    rate:defaultAccess(ULib.ACCESS_ADMIN)
    rate:help("Enregistre une note pour un joueur.")
end
