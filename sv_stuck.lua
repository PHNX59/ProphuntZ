local function CheckPlayerBlocked(player)
    if player:Alive() then
        local trace = util.TraceHull({
            start = player:GetPos(),
            endpos = player:GetPos(),
            mins = player:OBBMins(),
            maxs = player:OBBMaxs(),
            filter = function(ent)
                if ent == player then
                    return false
                end
            end
        })

        if trace.Hit then
            TeleportPlayerOutOfProp(player)
            player:ChatPrint("Vous avez été téléporté pour éviter d'être coincé dans un prop.")
        end
    end
end

local function TeleportPlayerInsideMap(player)
    local playerPos = player:GetPos()

    local newPos = playerPos + Vector(math.random(-50, 50), math.random(-50, 50), 0)

    if IsVectorInsideMapBounds(newPos) then
        local trace = util.TraceHull({
            start = newPos,
            endpos = newPos,
            mins = player:OBBMins(),
            maxs = player:OBBMaxs(),
            filter = function(ent)
                if ent == player then
                    return false
                end
            end
        })

        if not trace.Hit then
            player:SetPos(newPos)
            player:ChatPrint("Vous avez été téléporté à un nouvel emplacement à l'intérieur de la carte.")
        else
            player:ChatPrint("Impossible de vous téléporter, l'emplacement est toujours bloqué.")
        end
    else
        player:ChatPrint("Impossible de vous téléporter, vous seriez en dehors de la carte.")
    end
end

concommand.Add("stucks", function(player)
    TeleportPlayerOutOfProp(player)
end)