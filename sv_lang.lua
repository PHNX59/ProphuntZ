local languageSteamCodes = {
    ["en"] = "english",
    ["fr"] = "french",
}

-- Fonction pour déterminer la langue du joueur en fonction de ses paramètres de client
function SetPlayerLanguage(ply)
    local steamLang = ply:GetInfo("cl_language")

    -- Essayez de correspondre au code de langue Steam avec votre tableau de correspondance
    local gamemodeLang = languageSteamCodes[steamLang]

    -- Si la correspondance est trouvée, utilisez cette langue, sinon utilisez la langue par défaut ("english" dans cet exemple)
    if gamemodeLang then
        ply:SetNWString("PlayerLanguage", gamemodeLang)
    else
        ply:SetNWString("PlayerLanguage", "french")
    end
end

-- sv_lang.lua

-- Fonction pour charger le fichier de langue du joueur
function LoadPlayerLanguage(ply)
    local languageCode = "fr"  -- Par défaut, vous pouvez personnaliser cela en fonction des préférences du joueur

    -- Ici, vous pouvez ajouter une logique pour déterminer la langue du joueur.
    -- Par exemple, en fonction de ses paramètres ou de son choix dans le menu.

    -- Chargez le fichier de langue approprié
    if file.Exists("prophuntz/gamemode/lang/" .. languageCode .. ".lua", "LUA") then
        include("prophuntz/gamemode/lang/" .. languageCode .. ".lua")
    else
        print("Fichier de langue introuvable pour la langue " .. languageCode)
    end
end

-- Appelez cette fonction pour charger la langue d'un joueur spécifique (par exemple, au moment de la connexion du joueur)
hook.Add("PlayerAuthed", "LoadPlayerLanguage", function(ply, steamID, uniqueID)
    LoadPlayerLanguage(ply)
end)

-- Utilisez un hook pour définir la langue du joueur lorsqu'il rejoint le serveur
hook.Add("PlayerInitialSpawn", "SetPlayerLanguage", function(ply)
   SetPlayerLanguage(ply)
end)
