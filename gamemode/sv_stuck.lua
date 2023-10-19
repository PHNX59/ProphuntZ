-- Définissez une variable pour suivre le moment de la dernière téléportation en lieu sûr
local lastSafeTeleportTime = {}
-- Créez une fonction pour vérifier si un vecteur est à l'intérieur de la carte
local function IsVectorInsideMapBounds(vector)
    local mapBoundsMin = Vector(-16384, -16384, -16384) -- Les limites minimales de la carte
    local mapBoundsMax = Vector(16384, 16384, 16384) -- Les limites maximales de la carte

    -- Vérifiez si le vecteur est à l'intérieur des limites de la carte
    if vector.x >= mapBoundsMin.x and vector.y >= mapBoundsMin.y and vector.z >= mapBoundsMin.z and
       vector.x <= mapBoundsMax.x and vector.y <= mapBoundsMax.y and vector.z <= mapBoundsMax.z then
        return true -- Le vecteur est à l'intérieur de la carte
    else
        return false -- Le vecteur est en dehors de la carte
    end
end

-- Créez une fonction pour détecter si un joueur est hors de la carte
local function IsPlayerOutsideMap(player)
    local playerPos = player:GetPos()

    -- Définissez les limites minimales et maximales de la carte
    local mapBoundsMin = Vector(-16384, -16384, -16384)
    local mapBoundsMax = Vector(16384, 16384, 16384)

    -- Vérifiez si le joueur est hors de la carte en utilisant une trace
    local trace = util.TraceHull({
        start = playerPos,
        endpos = playerPos,
        mins = player:OBBMins(),
        maxs = player:OBBMaxs(),
        filter = player
    })

    if trace.Hit then
        -- Le joueur est hors de la carte
        return true
    else
        -- Le joueur est à l'intérieur de la carte
        return false
    end
end

hook.Add("Think", "CheckPlayerOutsideMap", function()
    for _, player in pairs(player.GetAll()) do
        if player:Alive() then
            if IsPlayerOutsideMap(player) then
                -- Le joueur est hors de la carte, prenez des mesures ici
                player:Kill() -- Par exemple, tuer le joueur s'il est hors de la carte
            end
        end
    end
end)

-- Fonction pour téléporter un joueur en lieu sûr avec une vérification de délai
local function TeleportPlayerToSafeLocation(player)
    local mapBoundsMin = Vector(-16384, -16384, -16384)
    local mapBoundsMax = Vector(16384, 16384, 16384)

    -- Générez une position aléatoire à l'intérieur des limites de la carte
    local safePos = Vector(
        math.random(mapBoundsMin.x, mapBoundsMax.x),
        math.random(mapBoundsMin.y, mapBoundsMax.y),
        math.random(mapBoundsMin.z, mapBoundsMax.z)
    )

    -- Vérifiez si la position générée est obstruée
    local trace = util.TraceHull({
        start = safePos,
        endpos = safePos,
        mins = player:OBBMins(),
        maxs = player:OBBMaxs(),
        filter = player
    })

    if not trace.Hit then
        -- Vérifiez si le joueur a été téléporté en lieu sûr récemment (par exemple, dans les 5 secondes précédentes)
        local currentTime = CurTime()
        local lastTeleportTime = lastSafeTeleportTime[player]

        if not lastTeleportTime or currentTime - lastTeleportTime >= 5 then
            -- La position est sûre, téléportez le joueur
            player:SetPos(safePos)
            player:ChatPrint("Vous avez été téléporté en lieu sûr.")
            
            -- Mettez à jour le moment de la dernière téléportation
            lastSafeTeleportTime[player] = currentTime
        end
    else
        player:ChatPrint("Impossible de vous téléporter en lieu sûr, l'emplacement est obstrué.")
    end
end

hook.Add("Think", "CheckPlayerOutsideMap", function()
    for _, player in pairs(player.GetAll()) do
        if player:Alive() then
            if IsPlayerOutsideMap(player) then
                -- Le joueur est hors de la carte, téléportez-le en lieu sûr
                TeleportPlayerToSafeLocation(player)
            end
        end
    end
end)

local function CheckPlayerBounds(player)
    local mapBoundsMin = Vector(-16384, -16384, -16384)
    local mapBoundsMax = Vector(16384, 16384, 16384)

    local playerPos = player:GetPos()

    if playerPos.x < mapBoundsMin.x or playerPos.y < mapBoundsMin.y or playerPos.z < mapBoundsMin.z or
        playerPos.x > mapBoundsMax.x or playerPos.y > mapBoundsMax.y or playerPos.z > mapBoundsMax.z then
        -- Le joueur est hors de la carte, téléportez-le en lieu sûr
        TeleportPlayerToSafeLocation(player)
    end
end

hook.Add("Think", "CheckPlayerBounds", function()
    for _, player in pairs(player.GetAll()) do
        if player:Alive() then
            if not player:IsAdmin() and player:GetMoveType() == MOVETYPE_NOCLIP then
                -- Si le joueur n'est pas un administrateur et est en mode noclip, vérifiez s'il est hors de la carte
                CheckPlayerBounds(player)
            end
        end
    end
end)

-- Fonction pour vérifier si un joueur est bloqué dans un prop ou un mur
local function CheckPlayerBlocked(player)
    if player:Alive() then
        -- Vérifiez si le joueur est coincé dans un prop
        local trace = util.TraceHull({
            start = player:GetPos(),
            endpos = player:GetPos(),
            mins = player:OBBMins(),
            maxs = player:OBBMaxs(),
            filter = function(ent)
                -- Ignorez le joueur lui-même lors de la vérification de la collision
                if ent == player then
                    return false
                end
            end
        })

        if trace.Hit then
            -- Le joueur est coincé, appelez la fonction de téléportation
            TeleportPlayerOutOfProp(player)
            player:ChatPrint("Vous avez été téléporté pour éviter d'être coincé dans un prop.")
        end
    end
end

-- Créez une fonction pour téléporter un joueur dans une zone aléatoire à l'intérieur de la carte
local function TeleportPlayerInsideMap(player)
    local mapBoundsMin = Vector(-16384, -16384, -16384) -- Les limites minimales de la carte
    local mapBoundsMax = Vector(16384, 16384, 16384) -- Les limites maximales de la carte

    -- Générez une nouvelle position aléatoire à l'intérieur des limites de la carte
    local newPos
    repeat
        newPos = Vector(
            math.random(mapBoundsMin.x, mapBoundsMax.x),
            math.random(mapBoundsMin.y, mapBoundsMax.y),
            math.random(mapBoundsMin.z, mapBoundsMax.z)
        )
        -- Vérifiez si la nouvelle position est obstruée
        local trace = util.TraceHull({
            start = newPos,
            endpos = newPos,
            mins = player:OBBMins(),
            maxs = player:OBBMaxs(),
            filter = function(ent)
                -- Ignorez le joueur lui-même lors de la vérification de la collision
                if ent == player then
                    return false
                end
            end
        })
    until not trace.Hit

    player:SetPos(newPos)
    player:ChatPrint("Vous avez été téléporté à un nouvel emplacement à l'intérieur de la carte.")
end


-- Fonction pour téléporter un joueur dans une zone aléatoire autour de sa position tout en restant à l'intérieur de la carte
local function TeleportPlayerOutOfProp(player)
    local playerPos = player:GetPos()
    local newPos = playerPos + Vector(math.random(-50, 50), math.random(-50, 50), 0)
    
    -- Vérifiez si la nouvelle position est à l'intérieur de la carte
    if IsVectorInsideMapBounds(newPos) then
        -- Assurez-vous que la nouvelle position n'est pas obstruée
        local trace = util.TraceHull({
            start = newPos,
            endpos = newPos,
            mins = player:OBBMins(),
            maxs = player:OBBMaxs(),
            filter = function(ent)
                -- Ignorez le joueur lui-même lors de la vérification de la collision
                if ent == player then
                    return false
                end
            end
        })

        if not trace.Hit then
            player:SetPos(newPos)
            player:ChatPrint("Vous avez été téléporté pour éviter d'être coincé dans un prop.")
        else
            player:ChatPrint("Impossible de vous téléporter, l'emplacement est toujours bloqué.")
        end
    else
        player:ChatPrint("Impossible de vous téléporter, vous seriez en dehors de la carte.")
    end
end

-- Créez un hook pour détecter quand un joueur est coincé dans un prop
hook.Add("Think", "CheckPlayerStuck", function()
    for _, player in pairs(player.GetAll()) do
        if player:Alive() then
            local trace = util.TraceHull({
                start = player:GetPos(),
                endpos = player:GetPos(),
                mins = player:OBBMins(),
                maxs = player:OBBMaxs(),
                filter = function(ent)
                    -- Ignorez le joueur lui-même lors de la vérification de la collision
                    if ent == player then
                        return false
                    end
                end
            })

            if trace.Hit then
                -- Le joueur est coincé, appelez la fonction de téléportation
                TeleportPlayerOutOfProp(player)
            end
        end
    end
end)

-- Créez une commande !stucks pour permettre aux joueurs de se débloquer manuellement
concommand.Add("stucks", function(player)
    TeleportPlayerOutOfProp(player)
end)