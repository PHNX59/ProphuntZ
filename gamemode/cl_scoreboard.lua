-- Vérifiez si le code s'exécute côté client
if CLIENT then
    local function CreatePropHuntScoreboard()
        -- Crée un panneau de scoreboard
        local Scoreboard = vgui.Create("DFrame")
        Scoreboard:SetSize(ScrW() * 0.75, ScrH() * 0.75)
        Scoreboard:SetPos(ScrW() * 0.125, ScrH() * 0.125)
        Scoreboard:SetTitle(" ")
        Scoreboard:SetVisible(false)
        Scoreboard:ShowCloseButton(false)
        Scoreboard:SetDraggable(false)

        local headerHeight = 0  -- Réduit la hauteur de la liste en haut de 25 pixels
        local footerHeight = 0  -- Réduit la hauteur de la liste en bas de 25 pixels

		local playerListHeight = ScrH() * 0.65 - headerHeight - footerHeight  -- Ajuste la hauteur des listes des joueurs
        local playerListWidth = (Scoreboard:GetWide() - 10) / 2 - 10  -- Déduit l'espacement de 50 pixels et 10 pixels pour chaque colonne
		
        Scoreboard.Paint = function(self, w, h)
            -- Dessine un fond gris foncé
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))

            -- Affiche le texte du header
            draw.SimpleText(GetHostName(), "DermaLarge", w / 2, headerHeight / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText("Gamemode by Florian_RVD", "DermaDefault", 10, headerHeight / 2, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)

            -- Affiche le texte du footer
            draw.SimpleText("Prophunt Z version 1.0", "DermaDefault", w / 2, h - footerHeight / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

            -- Dessine la ligne verticale de séparation entre les listes
            local separatorX = w / 2
            draw.RoundedBox(0, separatorX, headerHeight, 1, h - headerHeight - footerHeight, Color(0, 0, 0, 255))
	
        end

        local headerHeight = 0 -- Définissez headerHeight ici
        local footerHeight = 0 -- Définissez footerHeight ici

        local playerListHeight = (ScrH() * 0.75 - headerHeight - footerHeight) - 50  -- Réduit la hauteur de la liste des joueurs de 25 en haut et en bas

        -- Crée une liste pour afficher les joueurs de l'équipe "Hunters"
        local HuntersList = vgui.Create("DListView", Scoreboard)
        HuntersList:Dock(LEFT)
        HuntersList:SetWidth((Scoreboard:GetWide() - 5) / 2 - 10) -- Déduit l'espacement de 50 pixels et 10 pixels pour chaque colonne
        HuntersList:SetHeight(reducedPlayerListHeight) -- Ajuste la hauteur de la liste des joueurs
        HuntersList:AddColumn("Nom"):SetFixedWidth(HuntersList:GetWide() * 0.6)  -- Ajuste la largeur de la colonne des noms
        HuntersList:AddColumn("Score"):SetFixedWidth(HuntersList:GetWide() * 0.2)  -- Ajuste la largeur de la colonne des scores
        HuntersList:AddColumn("Ping"):SetFixedWidth(HuntersList:GetWide() * 0.2)  -- Ajuste la largeur de la colonne des pings

        -- Crée une liste pour afficher les joueurs de l'équipe "Props"
        local PropsList = vgui.Create("DListView", Scoreboard)
        PropsList:Dock(RIGHT)
        PropsList:SetWidth((Scoreboard:GetWide() - 5) / 2 - 10) -- Déduit l'espacement de 50 pixels et 10 pixels pour chaque colonne
        PropsList:SetHeight(reducedPlayerListHeight) -- Ajuste la hauteur de la liste des joueurs

        PropsList:AddColumn("Nom"):SetFixedWidth(PropsList:GetWide() * 0.6)  -- Ajuste la largeur de la colonne des noms
        PropsList:AddColumn("Score"):SetFixedWidth(PropsList:GetWide() * 0.2)  -- Ajuste la largeur de la colonne des scores
        PropsList:AddColumn("Ping"):SetFixedWidth(PropsList:GetWide() * 0.2)  -- Ajuste la largeur de la colonne des pings

        -- Ajustez l'espacement entre les colonnes
        local columnList = {HuntersList, PropsList}
        for _, list in pairs(columnList) do
            local columns = list.Columns
            for _, column in pairs(columns) do
                column:SetWide(column:GetWide() + 0) -- Augmente la largeur de chaque colonne de 10 pixels
            end
        end

        -- Cache le scoreboard par défaut
        Scoreboard:SetKeyboardInputEnabled(false)
        Scoreboard:SetMouseInputEnabled(false)

        -- Affiche le scoreboard lorsque la touche TAB est enfoncée
        hook.Add("ScoreboardShow", "ShowPropHuntScoreboard", function()
            Scoreboard:SetVisible(true)
            Scoreboard:MakePopup()
        end)

        -- Cache le scoreboard lorsque la touche TAB est relâchée
        hook.Add("ScoreboardHide", "HidePropHuntScoreboard", function()
            Scoreboard:SetVisible(false)
        end)

		-- Mettez à jour le contenu des listes des Hunters et des Props
		local function UpdatePlayerLists()
			if not IsValid(HuntersList) or not IsValid(PropsList) then return end
			
			HuntersList:Clear()
			PropsList:Clear()
			
			for _, ply in pairs(player.GetAll()) do
				local playerName = ply:Nick()
				local playerScore = ply:Frags()
				local playerPing = ply:Ping()
				local playerTeam = ply:Team()
				
				-- Ajoutez des conditions pour inclure les équipes TEAM_PROPS et TEAM_HUNTERS
				if playerTeam == TEAM_HUNTERS or playerTeam == TEAM_PROPS then
					local listItem = playerTeam == TEAM_HUNTERS and HuntersList:AddLine(playerName, playerScore, playerPing) or PropsList:AddLine(playerName, playerScore, playerPing)
				end
			end
		end
        
        -- Mettez à jour le scoreboard lorsque le joueur change d'équipe ou rejoint le serveur
        hook.Add("TTTBeginRound", "UpdatePropHuntScoreboard", function()
            timer.Simple(1, function()
                UpdatePlayerLists()
            end)
        end)
        
        hook.Add("PlayerInitialSpawn", "UpdatePropHuntScoreboard", function()
            timer.Simple(1, function()
                UpdatePlayerLists()
            end)
        end)
        
        hook.Add("PlayerChangedTeam", "UpdatePropHuntScoreboard", function()
            timer.Simple(1, function()
                UpdatePlayerLists()
            end)
        end)
    end

    -- Appelez la fonction pour créer le scoreboard Prop Hunt
    CreatePropHuntScoreboard()
end
