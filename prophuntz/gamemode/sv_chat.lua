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
    
    -- Vérifiez si la table chat_log existe, sinon créez-la avec les nouveaux champs
    local query = db:query([[
        CREATE TABLE IF NOT EXISTS chat_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_name VARCHAR(255) NOT NULL,
            steam_id VARCHAR(255) NOT NULL,
            ip_address VARCHAR(255) NOT NULL,
            chat_text TEXT NOT NULL,
            message_time DATETIME NOT NULL
        )
    ]])
    query:start()
end

db:connect()

function SaveChatToDatabase(ply, text)
    text = db:escape(text)
    
    local steamID = ply:SteamID()
    local ipAddress = ply:IPAddress()
    local messageTime = os.date("%Y-%m-%d %H:%M:%S") -- Capture the current date and time
    
    local query = db:query("INSERT INTO chat_log (player_name, steam_id, ip_address, chat_text, message_time) VALUES ('" .. ply:Nick() .. "', '" .. steamID .. "', '" .. ipAddress .. "', '" .. text .. "', '" .. messageTime .. "')")
    query:start()
end

hook.Add("PlayerSay", "SaveChatToDatabase", SaveChatToDatabase)
