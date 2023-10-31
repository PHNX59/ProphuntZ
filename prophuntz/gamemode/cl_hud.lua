local ROUND_WAITING = 0
local ROUND_ACTIVE = 1
local ROUND_END = 2

net.Receive("PHZ_UpdateRoundState", function()
    currentRound = net.ReadInt(32)
    roundEndTime = CurTime() + net.ReadFloat()
end)

-- Variable pour l'état actuel du round
local currentRound = ROUND_WAITING

-- Variable pour le statut du round
local roundStatus = "Round en cours"

function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

local hide = {
    ["CHudHealth"] = false,
    ["CHudBattery"] = false,
    ["CHudAmmo"] = false,
    ["CHudSecondaryAmmo"] = false
}

function HudProphuntHealth(ply)

end
hook.Add("HUDPaint", "HudProphuntHealth", HudProphuntHealth)



local circleMaterial = Material("vgui/circle")
local circleColor = Color(255, 255, 255, 150) -- Couleur verte transparente

function DrawPlayerCircle()
    for _, ply in pairs(player.GetAll()) do
        if ply:Team() == TEAM_PROPS and ply:Alive() and LocalPlayer():Team() == TEAM_PROPS then
            local pos = ply:GetPos() + Vector(0, 0, 25) -- Ajustez la hauteur du cercle
            local mins, maxs = ply:GetRenderBounds()
            local center = (mins + maxs) / 2
            local radius = mins:Distance(maxs) / 2

            -- Transformation de la position 3D en 2D
            local pos2D = pos:ToScreen()

            if pos2D.visible then
                surface.SetMaterial(circleMaterial)
                surface.SetDrawColor(circleColor)

                -- Dessin du cercle
                surface.DrawTexturedRect(pos2D.x - radius, pos2D.y - radius, radius * 2, radius * 2)
            end
        end
    end
end

hook.Add("HUDPaint", "DrawPlayerCircle", DrawPlayerCircle)










function HudProphuntTimer()

    local timeLeft = math.max(0, roundEndTime - CurTime())

    -- Définissez la couleur du texte avant d'utiliser surface.DrawText
    surface.SetTextColor(255, 255, 255, 255)

	if currentRound == ROUND_WAITING then
		roundStatus = "En attente de joueur(s)"
	elseif currentRound == ROUND_PREP then
		roundStatus = "Round de préparation"
	elseif currentRound == ROUND_ACTIVE then
		roundStatus = "Round en cours"
	elseif currentRound == ROUND_END then
		roundStatus = "Round terminé"
	end

    surface.SetTextPos(10, 10)
    surface.DrawText("État du round : " .. roundStatus)

    surface.SetTextPos(10, 30)
    surface.DrawText("Temps restant : " .. FormatTime(timeLeft))
end
hook.Add("HUDPaint", "HudProphuntTimer", HudProphuntTimer)

hook.Add("HUDShouldDraw", "HideDefaultHUD", function(name)
    -- Masquer le HUD de base
    --if (name == "CHudHealth" or name == "CHudBattery" or name == "CHudAmmo" or name == "CHudSecondaryAmmo") then
       -- return false
    --end
end)

hook.Add("HUDDrawTargetID", "DisablePlayerNameHover", function()
    return false
end)