    require("mysqloo") -- Chargez la bibliothèque MySQL
    local db = mysqloo.connect("94.23.50.189", "prophuntz", "qtY3SyphAunae41H", "prophuntz") -- Remplacez ces valeurs par vos informations de connexion MySQL

    function db:onConnected()
        print("Connexion à la base de données MySQL réussie!")
    end

        -- Créez la table 'bannis' si elle n'existe pas
        local createTableQuery = db:query("CREATE TABLE IF NOT EXISTS bannis (steamid VARCHAR(255) PRIMARY KEY, nom VARCHAR(255), raison TEXT, expiration INT, param1 VARCHAR(255), param2 VARCHAR(255), param3 VARCHAR(255), param4 VARCHAR(255), param5 VARCHAR(255), param6 VARCHAR(255), param7 VARCHAR(255), param8 VARCHAR(255), param9 VARCHAR(255), param10 VARCHAR(255))")
        createTableQuery:start()
		
    function db:onConnectionFailed(err)
        print("Erreur lors de la connexion à la base de données MySQL: " .. err)
    end

    db:connect()

	function ulx.banpersonnalise(calling_ply, target_ply, minutes, reason)
		if not IsValid(target_ply) then
			ULib.tsayError(calling_ply, "Joueur invalide.", true)
			return
		end

		local targetSteamID = target_ply:SteamID()
		local targetName = target_ply:Nick()
		local expiration = os.time() + (minutes * 60)

		-- Appel à la vérification des joueurs bannis
		ulx.checkBannedPlayer(target_ply)

		-- Ajoutez le joueur banni à la table MySQL
		local query = db:query("INSERT INTO bannis (steamid, nom, raison, expiration) VALUES ('" .. targetSteamID .. "', '" .. targetName .. "', '" .. reason .. "', " .. expiration .. ")")
		query.onSuccess = function(q, result)
			-- Utilisez la commande ulx.ban pour bannir le joueur
			ulx.ban(calling_ply, target_ply, minutes, reason)
			
			-- Générez un message de bannissement en remplaçant les motifs par les informations appropriées
			local banMessage = "Le joueur #target a été banni par #admin pour la raison : #reason pour #time minutes."
			banMessage = string.gsub(banMessage, "#target", targetName)
			banMessage = string.gsub(banMessage, "#admin", calling_ply:Nick())
			banMessage = string.gsub(banMessage, "#reason", reason)
			banMessage = string.gsub(banMessage, "#time", tostring(minutes))

			-- Affichez le message de bannissement dans le tchat
			ULib.tsay(nil, banMessage, true)

			ulx.fancyLogAdmin(calling_ply, "#A a banni #T pour #i minutes (#s) avec des paramètres personnalisés.", target_ply, minutes, reason)
		end
		query:start()
	end

    local banpersonnalise = ulx.command("Prophuntz Commande", "ulx banpersonnalise", ulx.banpersonnalise, "!banpersonnalise")
    banpersonnalise:addParam{type=ULib.cmds.PlayerArg}
    banpersonnalise:addParam{type=ULib.cmds.NumArg, min=0, default=60, hint="Durée en minutes", ULib.cmds.optional, ULib.cmds.round}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Raison", ULib.cmds.optional, ULib.cmds.takeRestOfLine}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Parce que j'avais envie", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Insultes ", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Triche ", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Abus de tchat", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Comportement toxique", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Nom inapproprié", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Non-respect des règles", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="AFK prolongé", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Troll", ULib.cmds.optional}
    banpersonnalise:addParam{type=ULib.cmds.StringArg, hint="Autres", ULib.cmds.optional}
	banpersonnalise:setCategory("Prophuntz Commande") -- Définit la catégorie

    banpersonnalise:defaultAccess(ULib.ACCESS_ADMIN)
    banpersonnalise:help("Ban un joueur avec des paramètres personnalisés.")

function ulx.checkBannedPlayer(ply)
	local steamid = ply:SteamID()
	local query = db:query("SELECT * FROM bannis WHERE steamid = '" .. steamid .. "' AND expiration > " .. os.time())
	query.onSuccess = function(q, result)
		if result and #result > 0 then
			local row = result[1]
			local expiration = tonumber(row.expiration)
			local reason = row.raison
			local timeLeft = math.floor((expiration - os.time()) / 60)

			ply:Kick("Vous êtes banni du serveur pour la raison suivante: " .. reason .. " (Temps restant: " .. timeLeft .. " minutes)")
		end
	end
	query:start()
end
    hook.Add("PlayerAuthed", "ULXCheckBannedPlayer", ulx.checkBannedPlayer)

hook.Add("PlayerConnect", "ULXCheckBannedOnConnect", function(name, address)
	local steamid = util.SteamIDFrom64(util.CommunityID(address))
	local query = db:query("SELECT * FROM bannis WHERE steamid = '" .. steamid .. "' AND expiration > " .. os.time())
	query.onSuccess = function(q, result)
		if result and #result > 0 then
			local row = result[1]
			local expiration = tonumber(row.expiration)
			local reason = row.raison
			local timeLeft = math.floor((expiration - os.time()) / 60)

			ULib.tsayError(nil, name .. " (" .. steamid .. ") est banni du serveur pour la raison suivante: " .. reason .. " (Temps restant: " .. timeLeft .. " minutes)", true)
		end
	end
	query:start()
end)

