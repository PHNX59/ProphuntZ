require("mysqloo")

local dbInfo = {
    host = "94.23.50.189",
    port = 3306,
    database = "prophuntz",
    user = "prophuntz",
    password = "qtY3SyphAunae41H"
}

local db = mysqloo.connect(dbInfo.host, dbInfo.user, dbInfo.password, dbInfo.database, dbInfo.port)

function CreateMessagesTable()
    if not db or not db:status() == mysqloo.DATABASE_CONNECTED then
        print("Erreur de connexion à la base de données MySQL.")
        return
    end

    local query = db:query([[
        CREATE TABLE IF NOT EXISTS messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            message TEXT
        )
    ]])

    query.onSuccess = function()
        print("Table de messages créée avec succès.")
    end

    query.onError = function(_, err)
        print("Erreur MySQL : " .. err)
    end

    query:start()
end

CreateMessagesTable()

function LoadAndSendRandomMessage()
    if not db or not db:status() == mysqloo.DATABASE_CONNECTED then
        print("Erreur de connexion à la base de données MySQL.")
        return
    end

    local query = db:query("SELECT message FROM messages ORDER BY RAND() LIMIT 1")

    query.onSuccess = function(_, data)
        if data and data[1] and data[1].message then
            local randomMessage = data[1].message
            local prefix = "[ProphuntZ] "

            local prefixColor = Color(255, 0, 0) -- Rouge
            local messageColor = Color(0, 255, 0) -- Vert

            net.Start("SendRandomMessage")
            net.WriteString(prefix)
            net.WriteString(randomMessage)
            net.Send(player.GetAll())
        end
    end

    query.onError = function(_, err)
        print("Erreur MySQL : " .. err)
    end

    query:start()
end

db:connect()

for i = 1, 5 do
    LoadAndSendRandomMessage(function(message)
        if message then
            print("Message aléatoire chargé : " .. message)
        else
            print("Aucun message chargé.")
        end
    end)
end

util.AddNetworkString("SendRandomMessage")
timer.Create("RandomMessageTimer", 60, 0, LoadAndSendRandomMessage)