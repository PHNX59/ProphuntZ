if CLIENT then
TEAM_PROPS = 1 team.SetUp(TEAM_PROPS, "Props", Color(0, 0, 180))
TEAM_PROPS_DEAD =3 team.SetUp(TEAM_PROPS_DEAD, "Props (Mort)", Color(0, 0, 180))
TEAM_HUNTERS = 2 team.SetUp(TEAM_HUNTERS, "Chasseurs ", Color(0, 0, 180))
TEAM_HUNTERS_DEAD = 4 team.SetUp(TEAM_HUNTERS_DEAD, "Chasseurs (Mort) ", Color(0, 0, 180))

TEAM_SPECTATORS = 5 team.SetUp(TEAM_SPECTATORS, "SPECTATEUR", Color(25, 25, 25))

-- Fonction pour afficher le tableau de bord
function GM:ScoreboardShow()
local propList
    -- Créez un cadre principal pour le tableau de bord
    local scoreboard = vgui.Create("DFrame")
    scoreboard:SetSize(800, 600)
    scoreboard:SetTitle("")
    scoreboard:Center()
    scoreboard:MakePopup()

    -- Nom du serveur en haut du tableau de bord
    local serverName = vgui.Create("DLabel", scoreboard)
    serverName:SetPos(10, 10)
    serverName:SetSize(780, 30)
    serverName:SetText("Nom du Serveur")
    serverName:SetFont("DermaLarge")
    serverName:SetContentAlignment(5) -- Centre le texte
    serverName:SetTextColor(Color(255, 255, 255, 255)) -- Couleur du texte

    -- Créez un panneau pour l'équipe Prop
    local propPanel = vgui.Create("DPanel", scoreboard)
    propPanel:SetSize(390, 470)
    propPanel:SetPos(10, 50)
    propPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 255, 100)) -- Couleur de l'équipe Prop
    end

    -- Créez un panneau pour l'équipe Hunter
    local hunterPanel = vgui.Create("DPanel", scoreboard)
    hunterPanel:SetSize(390, 470)
    hunterPanel:SetPos(400, 50)
    hunterPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(255, 0, 0, 100)) -- Couleur de l'équipe Hunter
    end

    -- Liste des joueurs Prop
    local propList = vgui.Create("DListView", propPanel)
    propList:SetPos(10, 10)
    propList:SetSize(370, 450)
    propList:SetMultiSelect(false)
    propList:AddColumn("Joueur")
    propList:AddColumn("Ping")

    -- Liste des joueurs Hunter
    local hunterList = vgui.Create("DListView", hunterPanel)
    hunterList:SetPos(10, 10)
    hunterList:SetSize(370, 450)
    hunterList:SetMultiSelect(false)
    hunterList:AddColumn("Joueur")
    hunterList:AddColumn("Ping")

    -- Fonction pour ajouter un joueur à une équipe
    local function AddPlayerToScoreboard(ply)
        local playerName = ply:Nick()
        local ping = ply:Ping()

        local listItem

        if ply:Team() == TEAM_PROPS then
            listItem = propList:AddLine(playerName, ping)
        elseif ply:Team() == TEAM_HUNTERS then
            listItem = hunterList:AddLine(playerName, ping)
        end

        if IsValid(listItem) then
            -- Photo de profil (avatar)
            local avatar = vgui.Create("AvatarImage", listItem)
            avatar:SetSize(32, 32)
            avatar:SetPos(5, 5)
            avatar:SetPlayer(ply, 32)

            -- Personnalisation de la ligne
            listItem:SetHeight(32)
            listItem.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 200)) -- Couleur de fond de la ligne
            end
        end
    end

    -- Remplissez les listes des joueurs
    for _, ply in pairs(player.GetAll()) do
        AddPlayerToScoreboard(ply)
    end

    -- Pied de page avec le nom du gamemode
    local footer = vgui.Create("DLabel", scoreboard)
    footer:SetPos(10, 530)
    footer:SetSize(780, 30)
    footer:SetText("Gamemode by Florian_RVD")
    footer:SetFont("DermaDefault")
    footer:SetContentAlignment(5) -- Centre le texte
    footer:SetTextColor(Color(255, 255, 255, 255)) -- Couleur du texte
end

-- Définissez la fonction AddPlayerToScoreboard
local function AddPlayerToScoreboard(ply)
    local playerName = ply:Nick()
    local ping = ply:Ping()

    local listItem

    if ply:Team() == TEAM_PROPS then
        listItem = propList:AddLine(playerName, ping)
    elseif ply:Team() == TEAM_HUNTERS then
        listItem = hunterList:AddLine(playerName, ping)
    end

    if IsValid(listItem) then
        -- Photo de profil (avatar)
        local avatar = vgui.Create("AvatarImage", listItem)
        avatar:SetSize(32, 32)
        avatar:SetPos(5, 5)
        avatar:SetPlayer(ply, 32)

        -- Personnalisation de la ligne
        listItem:SetHeight(32)
        listItem.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 200)) -- Couleur de fond de la ligne
        end
    end
end

-- Fonction pour mettre à jour le tableau de bord
local function UpdateScoreboardData()
    -- Nettoyez les listes existantes pour éviter les doublons
	if IsValid(propList) then
    propList:Clear()
    hunterList:Clear()
	end

    -- Parcourez tous les joueurs pour les ajouter à leurs équipes respectives
    for _, ply in pairs(player.GetAll()) do
        AddPlayerToScoreboard(ply)
    end
end

-- Utilisez le hook "HUDPaint" pour mettre à jour le tableau de bord
hook.Add("HUDPaint", "UpdateScoreboard", function()
    UpdateScoreboardData()
end)
end
