-- Configuration
local roundDuration = 360 -- Durée du round en secondes
local minPlayersToStart = 2
local roundStartTime = 0 -- Ajoutez une variable pour suivre le temps écoulé depuis le début du round

-- États du round
local gameState = "waiting"
local deadPlayers = {} -- Ajoutez une table pour suivre les joueurs morts

-- Équipes
TEAM_PROPS = 1 
TEAM_HUNTERS = 2 

-- Fonction pour vérifier si un joueur est un bot
function IsBot(ply)
    return ply:IsBot()
end

-- Fonction pour vérifier si un joueur peut respawn
function CanPlayerRespawn(ply)
    -- Ajoutez ici des conditions pour décider si le joueur peut respawn ou non
    -- Par exemple, vous pouvez vérifier s'il est mort et si le round est toujours en cours
    if table.HasValue(deadPlayers, ply) and gameState == "round_in_progress" then
        return false -- Le joueur ne peut pas respawn
    end
    return true -- Le joueur peut respawn
end

-- Fonction pour gérer la mort d'un joueur
function PlayerDeath(ply)
    if not IsBot(ply) then
        table.insert(deadPlayers, ply)

        -- Changez le mode spectateur en mode spectateur d'équipe
        ply:Spectate(OBS_MODE_TEAM)
        ply:SpectateEntity(nil) -- Assurez-vous qu'ils ne suivent aucun joueur en particulier

        -- Réglez l'équipe que le joueur peut regarder
        ply:SpectateTeam(ply:Team())

        ply:StripWeapons() -- Vous pouvez supprimer les armes du joueur s'il en avait

        -- Vérifiez si tous les joueurs Props sont morts
        if CheckPropsSurvival() == false then
            EndRound()
        end
    end
end

-- Gestionnaire de l'hook PlayerSpawn pour empêcher les joueurs de respawn
hook.Add("PlayerSpawn", "PreventRespawn", function(ply)
    if not CanPlayerRespawn(ply) then
        ply:KillSilent()
    end
end)

-- Fonction pour geler les Hunters au début du round avec un écran noir simulé
function FreezeHunters()
    for _, ply in pairs(player.GetAll()) do
        if ply:Team() == TEAM_HUNTERS and not IsBot(ply) then
            ply:Freeze(true)
            -- Assombrir l'écran en utilisant un fondu en noir
            ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 2, 0)
        end
    end
end

-- Fonction pour dégeler les Hunters à la fin de la période de gel
function UnfreezeHunters()
    for _, ply in pairs(player.GetAll()) do
        if ply:Team() == TEAM_HUNTERS and not IsBot(ply) then
            ply:Freeze(false)
            -- Réinitialisez l'écran de fondu
            ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 2, 0)
        end
    end
end

-- Gestionnaire de l'hook PlayerInitialSpawn pour geler les Hunters au début du round
hook.Add("PlayerInitialSpawn", "FreezeHunters", function(ply)
    if gameState == "round_in_progress" and ply:Team() == TEAM_HUNTERS then
        if CurTime() - roundStartTime <= 20 then
            -- Geler les Hunters au début du round
            FreezeHunters()
            -- Définir un timer pour les dégeler
            timer.Simple(20, UnfreezeHunters)
        end
    end
end)

-- Fonction pour démarrer un round
function StartRound()
    gameState = "round_in_progress"
    
    -- Réinitialisez le temps de début du round
    roundStartTime = CurTime()

    -- Distribuez les joueurs dans les équipes
    AssignTeams()

    -- Distribuez les armes et les modèles
    GiveWeaponsAndModels()

    -- Configurez un timer pour la durée du round
    timer.Create("RoundTimer", roundDuration, 1, EndRound)
end

-- Fonction pour vérifier la condition de victoire des Props
function CheckWinCondition()
    local propsAlive = team.NumPlayers(TEAM_PROPS)

    -- Si tous les Props sont morts, les Hunters gagnent
    if propsAlive == 0 then
        BroadcastMessage("Hunters win the round!")
        EndRound()
    end
end

-- Fonction pour vérifier la condition de victoire des Props en tenant compte des bots
function CheckPropsSurvival()
    local propsAlive = 0

    for _, ply in pairs(player.GetAll()) do
        if ply:Team() == TEAM_PROPS and ply:Alive() then
            propsAlive = propsAlive + 1
        end
    end

    -- Si tous les Props (y compris les bots) sont morts, les Hunters gagnent
    if propsAlive == 0 then
        BroadcastMessage("Hunters win the round!")
        EndRound()
        return false
    end

    return true
end

-- Fonction pour terminer un round
function EndRound()
    gameState = "round_ended"
    
    local propsSurvived = CheckPropsSurvival()
    local roundTimerExpired = false

    -- Vérifiez si le timer du round a expiré
    if not timer.Exists("RoundTimer") then
        roundTimerExpired = true
    end

    -- Vérifiez la condition de victoire
    if propsSurvived and not roundTimerExpired then
        BroadcastMessage("Props win!")
    elseif not propsSurvived then
        BroadcastMessage("Hunters win!")
    else
        BroadcastMessage("Round ended in a draw.")
    end

    -- Configurez un compte à rebours pour le prochain round
    timer.Create("NextRoundTimer", 10, 1, StartNextRound)
end

-- Fonction pour vérifier la condition de victoire des Props
function CheckPropsSurvival()
    local propsAlive = team.NumPlayers(TEAM_PROPS)
    local huntersAlive = team.NumPlayers(TEAM_HUNTERS)

    -- Si tous les Props sont morts, les Hunters gagnent
    if propsAlive == 0 then
        return false
    end

    -- Si tous les Hunters sont morts, les Props gagnent
    if huntersAlive == 0 then
        return true
    end

    return false
end

-- Fonction pour annoncer le prochain round
function StartNextRound()
    gameState = "waiting"
    BroadcastMessage("Next round in 10 seconds.")
end

-- Fonction pour attribuer les équipes
function AssignTeams()
    local players = player.GetAll()
    local numPlayers = #players

    for _, ply in pairs(players) do
        if math.random(1, 2) == 1 then
            ply:SetTeam(1) -- Team Props
        else
            ply:SetTeam(2) -- Team Hunters
        end
    end
end

-- Fonction pour donner des armes et des modèles aux joueurs
function GiveWeaponsAndModels()
    for _, ply in pairs(player.GetAll()) do
        if ply:Team() == 1 then
            -- Assignez les armes et modèles aux Props
			ConfigurePropsTeam()
        elseif ply:Team() == 2 then
            -- Assignez les armes et modèles aux Hunters
            ConfigureHuntersTeam()
        end
    end
end

-- Gestionnaire de l'hook PlayerInitialSpawn pour vérifier le début du round
hook.Add("PlayerInitialSpawn", "CheckStartRound", function(ply)
    if gameState == "waiting" then
        local numPlayers = #player.GetAll()
        if numPlayers >= minPlayersToStart then
            StartRound()
        end
    end
end)

-- Gestionnaire de l'hook PlayerDeath pour vérifier la condition de victoire
hook.Add("PlayerDeath", "CheckWinCondition", function(victim, inflictor, attacker)
    if gameState == "round_in_progress" and victim:Team() == TEAM_PROPS then
        -- Si un joueur Props meurt pendant le round, vérifiez la condition de victoire
        CheckWinCondition()
    end
end)