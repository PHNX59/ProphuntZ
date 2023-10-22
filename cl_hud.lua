local ROUND_WAITING = 0
local ROUND_PREP = 1
local ROUND_ACTIVE = 2
local ROUND_END = 3

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
    ["CHudBattery"] = true,
    ["CHudAmmo"] = false,
    ["CHudSecondaryAmmo"] = false
}

local function DrawAmmoHUD()
    local ply = LocalPlayer()
    if IsValid(ply) and ply:Alive() then
        local weapon = ply:GetActiveWeapon()
        if IsValid(weapon) then
            local ammoInClip = weapon:Clip1()
            local maxAmmo = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())
            local rectWidth = 200 
            local rectHeight = 50
            local rectSpacing = 10 
            local fontSize = 40
            local font = "ChatFont"
            local bgColor = Color(80, 80, 80, 200)
            local textColor = Color(255, 255, 255, 255) 
            local borderColor = Color(255, 0, 0, 255)
            local borderSize = 7 
            local xPos = ScrW() - rectWidth - 20
            local yPos = ScrH() - rectHeight - 20
            surface.SetDrawColor(borderColor)
            surface.DrawOutlinedRect(xPos, yPos, rectWidth, rectHeight)
            draw.RoundedBox(0, xPos, yPos, rectWidth, rectHeight, bgColor)
            draw.SimpleText("Munitions: " .. ammoInClip, font, xPos + rectWidth / 2, yPos + rectHeight / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(borderColor)
            surface.DrawOutlinedRect(xPos - rectWidth - rectSpacing, yPos, rectWidth, rectHeight)
            draw.RoundedBox(0, xPos - rectWidth - rectSpacing, yPos, rectWidth, rectHeight, bgColor)
            draw.SimpleText("Chargeur: " .. maxAmmo, font, xPos - rectWidth - rectSpacing + rectWidth / 2, yPos + rectHeight / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

hook.Add("HUDPaint", "DrawAmmoHUD", function()
    DrawAmmoHUD()
end)

function HudProphunt()
	
end

hook.Add("HUDPaint", "HudProphunt", HudProphunt)

-- Ajoutez la fonction pour recevoir les données réseau en dehors de la fonction HudProphuntTimer
net.Receive("PHZ_UpdateRoundState", function()
    currentRound = net.ReadInt(32) -- Recevez le numéro d'état du round
    roundEndTime = CurTime() + net.ReadFloat() -- Recevez le temps restant
end)

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