require("mysqloo")

local playerLevels = {}

-- Définissez les informations de connexion à votre base de données MySQL
local dbInfo = {
    host = "94.23.50.189",         -- L'adresse du serveur MySQL
    port = 3306,                -- Le port MySQL (par défaut : 3306)
    database = "prophuntz",  -- Le nom de votre base de données
    user = "prophuntz",          -- Votre nom d'utilisateur MySQL
    password = "qtY3SyphAunae41H"      -- Votre mot de passe MySQL
}

-- Créez une instance de connexion MySQL
local db = mysqloo.connect(dbInfo.host, dbInfo.user, dbInfo.password, dbInfo.database, dbInfo.port)

-- Exemple de requête SQL pour créer la table "props_config"
local createPropsTableQuery = [[
    CREATE TABLE IF NOT EXISTS props_config (
        steamid VARCHAR(255) NOT NULL PRIMARY KEY,
        level INT NOT NULL DEFAULT 1,
        maxHealth INT NOT NULL DEFAULT 100,
        walkSpeed INT NOT NULL DEFAULT 280,
        jumpPower INT NOT NULL DEFAULT 200,
        points INT NOT NULL DEFAULT 0
    );
]]

-- Fonction pour créer la table "props_config" dans la base de données
local function CreatePropsTable()
    local queryProps = db:query(createPropsTableQuery)
    queryProps:start()
end

-- Fonction de rappel pour la connexion réussie à la base de données MySQL
function db:onConnected()
    print("Connexion MySQL établie avec succès !")
    
    -- Appelez la fonction pour créer la table ici, une fois la connexion établie
    CreatePropsTable()
end

-- Définissez une fonction de rappel pour la connexion échouée
function db:onConnectionFailed(err)
    print("Erreur de connexion MySQL : " .. err)
end

-- Connectez-vous à la base de données
db:connect()

-- Fonction pour augmenter le niveau d'un joueur
function IncreasePlayerLevel(ply)
    if ply:Team() == TEAM_PROPS then
        local steamID = ply:SteamID()
        local currentLevel = playerLevels[steamID] and playerLevels[steamID].level or 1

        -- Niveau maximum souhaité
        local maxLevel = 100

        if currentLevel < maxLevel then
            local newLevel = currentLevel + 1
            playerLevels[steamID] = {
                level = newLevel,
                maxHealth = playerLevels[steamID].maxHealth + 1,
                walkSpeed = playerLevels[steamID].walkSpeed + 1,
                jumpPower = playerLevels[steamID].jumpPower + 1
            }

            -- Mettez à jour les données dans la base de données MySQL
            local query = db:query("UPDATE props_config SET level = " .. newLevel ..
                                   ", maxHealth = " .. playerLevels[steamID].maxHealth ..
                                   ", walkSpeed = " .. playerLevels[steamID].walkSpeed ..
                                   ", jumpPower = " .. playerLevels[steamID].jumpPower ..
                                   " WHERE steamid = '" .. steamID .. "'")
            query:start()

            -- Affichez un message au joueur pour indiquer qu'il a gagné un niveau
            ply:ChatPrint("Félicitations ! Vous avez atteint le niveau " .. newLevel)
        else
            -- Le joueur a atteint le niveau maximum
            ply:ChatPrint("Vous avez atteint le niveau maximum.")
        end
    end
end

-- Fonction pour charger les valeurs de maxHealth, walkSpeed et jumpPower lors du spawn
function LoadPlayerAttributesOnSpawn(ply)
    if ply:Team() == TEAM_PROPS then
        local steamID = ply:SteamID()
        local queryGetData = db:query("SELECT maxHealth, walkSpeed, jumpPower FROM props_config WHERE steamid = '" .. steamID .. "'")
        queryGetData.onSuccess = function(data)
            if data[1] then
                local maxHealth = tonumber(data[1].maxHealth) or 100
                local walkSpeed = tonumber(data[1].walkSpeed) or 280
                local jumpPower = tonumber(data[1].jumpPower) or 200

                -- Affichez les valeurs chargées depuis la base de données dans la console du serveur
                print("Max Health: " .. maxHealth)
                print("Walk Speed: " .. walkSpeed)
                print("Jump Power: " .. jumpPower)

                -- Appliquez les valeurs de maxHealth, walkSpeed et jumpPower au joueur lors du spawn
                ply:SetMaxHealth(maxHealth)
                ply:SetHealth(maxHealth)
                ply:SetWalkSpeed(walkSpeed)
                ply:SetJumpPower(jumpPower)
            else
                -- Aucune donnée trouvée dans la base de données pour ce joueur
                print("Aucune donnée trouvée dans la base de données pour le joueur avec SteamID " .. steamID)
            end
        end
        queryGetData:start()
    end
end

-- Attachez la fonction LoadPlayerAttributesOnSpawn à l'hook PlayerSpawn
hook.Add("PlayerSpawn", "LoadPlayerAttributesOnSpawn", LoadPlayerAttributesOnSpawn)

-- Fonction pour attribuer des points à un joueur lors de la connexion
function GivePointsOnInitialSpawn(ply)
    local steamID = ply:SteamID()
    local initialPoints = 30  -- Remplacez par le nombre de points que vous souhaitez donner à un joueur lorsqu'il se connecte

    -- Vérifiez si le joueur a déjà des données de niveau enregistrées
    if not playerLevels[steamID] then
        playerLevels[steamID] = {
            level = 1,
            points = initialPoints
        }

        -- Mettez à jour les données dans la base de données MySQL
        local query = db:query("INSERT INTO props_config (steamid, level, points) VALUES (" ..
                               "'" .. steamID .. "', 1, " .. initialPoints .. ")")
        query:start()

        -- Affichez un message au joueur pour indiquer qu'il a gagné des points lors de sa première connexion
        ply:ChatPrint("Bienvenue ! Vous avez gagné " .. initialPoints .. " points pour votre première connexion.")
    else
        -- Le joueur a déjà des données de niveau, vous pouvez choisir de ne pas lui donner de points ici
    end

    -- Récupérez les données de maxHealth, walkSpeed et jumpPower depuis la base de données MySQL
    local queryGetData = db:query("SELECT maxHealth, walkSpeed, jumpPower FROM props_config WHERE steamid = '" .. steamID .. "'")
    queryGetData.onSuccess = function(data)
        if data[1] then
            local maxHealth = tonumber(data[1].maxHealth) or 100
            local walkSpeed = tonumber(data[1].walkSpeed) or 280
            local jumpPower = tonumber(data[1].jumpPower) or 200

            -- Appliquez les valeurs de maxHealth, walkSpeed et jumpPower au joueur
            ply:SetMaxHealth(maxHealth)
            ply:SetHealth(maxHealth)
            ply:SetWalkSpeed(walkSpeed)
            ply:SetJumpPower(jumpPower)
        end
    end
    queryGetData:start()
end

-- Attachez la fonction à l'hook PlayerInitialSpawn
hook.Add("PlayerInitialSpawn", "GivePointsOnInitialSpawn", GivePointsOnInitialSpawn)