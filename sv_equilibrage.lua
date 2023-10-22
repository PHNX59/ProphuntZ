-- Configuration
local hunterWinStreak = 0
local propWinStreak = 0

local maxWinStreak = 3 -- Après combien de victoires consécutives un ajustement doit-il être fait?

local hunterSpeedReduction = 0.05 -- Réduction de 5% par victoire consécutive.
local propCamouflageTimeIncrease = 1 -- Augmentation d'une seconde par victoire consécutive.

-- Appelée quand les hunters gagnent
function HuntersWin()
    hunterWinStreak = hunterWinStreak + 1
    propWinStreak = 0

    if hunterWinStreak >= maxWinStreak then
        AdjustForHunterWinStreak()
    end
end

-- Appelée quand les props gagnent
function PropsWin()
    propWinStreak = propWinStreak + 1
    hunterWinStreak = 0

    if propWinStreak >= maxWinStreak then
        AdjustForPropWinStreak()
    end
end

-- Ajuste les paramètres si les hunters gagnent trop souvent
function AdjustForHunterWinStreak()
    local newHunterSpeed = 1 - (hunterWinStreak * hunterSpeedReduction)
    for _, hunter in pairs(team.GetPlayers(TEAM_HUNTERS)) do
        hunter:SetWalkSpeed(hunter:GetWalkSpeed() * newHunterSpeed)
        hunter:SetRunSpeed(hunter:GetRunSpeed() * newHunterSpeed)
    end

    -- Réinitialisez le win streak pour éviter des ajustements constants
    hunterWinStreak = 0
end

-- Ajuste les paramètres si les props gagnent trop souvent
function AdjustForPropWinStreak()
    -- À titre d'exemple, nous augmentons simplement le temps de camouflage des props.
    -- Vous pouvez ajouter d'autres mécaniques, comme une lueur, des sons, etc.
    local newCamouflageTime = propCamouflageTimeIncrease * propWinStreak
    -- Vous devrez avoir une fonction pour régler le temps de camouflage des props.

    -- Réinitialisez le win streak pour éviter des ajustements constants
    propWinStreak = 0
end

-- Attachez ces fonctions à la logique de fin de round de votre jeu.
hook.Add("RoundEnd", "DynamicBalance", function(winningTeam)
    if winningTeam == TEAM_HUNTERS then
        HuntersWin()
    else
        PropsWin()
    end
end)
