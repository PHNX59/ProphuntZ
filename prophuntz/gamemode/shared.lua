if CLIENT then
    include("sv_scoreboard.lua")
end

-- Utilisez simplement GM pour définir les propriétés du gamemode
PHZ.Name = "ProphuntZ"
PHZ.Author = "Florian RVD"
PHZ.Email = ""

-- Définition de l'équipe des Props
TEAM_PROPS = 1 team.SetUp(TEAM_PROPS, "Props", Color(0, 0, 180))
TEAM_HUNTERS = 2 team.SetUp(TEAM_HUNTERS, "Chasseurs ", Color(0, 0, 180))
TEAM_SPECTATORS = 3 team.SetUp(TEAM_SPECTATORS, "SPECTATEUR", Color(25, 25, 25))