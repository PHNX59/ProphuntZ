local function ShowScoreboard()
    local frame = vgui.Create("DFrame")
    frame:SetSize(700, 400)
    frame:Center()
    frame:SetTitle("Tableau des Scores")
    frame:MakePopup()

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("Pseudo")
    list:AddColumn("Rôle")
    list:AddColumn("STEAMID")
    list:AddColumn("Score")
    list:AddColumn("Vie")
    list:AddColumn("Info")

    for _, ply in pairs(player.GetAll()) do
        local role = "Inconnu"
        if ply:Team() == TEAM_PROPS then
            role = "Prophète"
        elseif ply:Team() == TEAM_HUNTERS then
            role = "Chasseur"
        end

        list:AddLine(ply:Nick(), role, ply:SteamID(), ply:Frags(), ply:Health(), "Info")
    end
end

hook.Add("ScoreboardShow", "CustomScoreboard", ShowScoreboard)
