-- Masquer l'HUD par défaut
local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true
}
hook.Add("HUDShouldDraw", "HideDefaultHUD", function(name)
    if hide[name] then return false end
end)

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
local ply = LocalPlayer()
	
if not IsValid(ply) then return end
	
	local plyModel = ply:GetModel()	
	local steamID = ply:SteamID64()
	
	local x = 10
	local y = ScrH() - 110
	local w = 90
	local h = 90
	local avatarSize = 84

	local avatarX = x + (w - avatarSize) / 2
	local avatarY = y + (h - avatarSize) / 2		

	local avatar = vgui.Create("AvatarImage")
	avatar:SetSize(avatarSize, avatarSize)
	avatar:SetPos(avatarX, avatarY)
	avatar:SetPlayer(ply, avatarSize)

	padding = padding or 0 
    local w = avatarSize * 1.10
    local h = avatarSize * 1.10
    local avatarX = x + padding
    local avatarY = y + padding

    local totalHUDWidth = w + padding*2 + 2 + 150 + 150 + 10
    local totalHUDHeight = h + padding*2

    surface.SetDrawColor(50, 50, 50, 180)
    draw.NoTexture()
    surface.DrawRect(x, y, totalHUDWidth, totalHUDHeight)

    surface.SetDrawColor(70, 70, 70, 180)
    surface.DrawRect(avatarX, avatarY, w, h)

    local lineX = avatarX + w + padding
    local lineY = y + (totalHUDHeight - h) / 2
    local lineHeight = h
    surface.SetDrawColor(255, 0, 0, 255)
    surface.DrawRect(lineX, lineY, 2, lineHeight)

	local healthBarWidth = 20
	local healthBarHeight = h
	local healthBarX = lineX + 2 + 10
	local healthBarY = y + (totalHUDHeight - h) / 2
	local health = ply:Health()
	local maxhealth = ply:GetMaxHealth()
	local nh = math.Round(healthBarHeight * math.Clamp(health / maxhealth, 0, 1))
	surface.SetDrawColor(0, 255, 0, 255)
	surface.DrawRect(healthBarX, healthBarY + healthBarHeight - nh, healthBarWidth, nh)

	local healthText = tostring(health)
	local textSize = 8 
	local textWidth, textHeight = surface.GetTextSize(healthText)
	local textX = healthBarX + (healthBarWidth - textWidth) / 2
	local textY = healthBarY + (healthBarHeight - textHeight) / 2
	draw.SimpleTextOutlined(healthText, "Default", textX, textY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))

    local playerNameWidth = 150
    local playerNameHeight = 30
    local playerNameX = healthBarX + healthBarWidth + 10
    local playerNameY = y + (totalHUDHeight - playerNameHeight) / 2
    surface.SetDrawColor(50, 50, 50, 180)
    surface.DrawRect(playerNameX, playerNameY, playerNameWidth, playerNameHeight)
    local playerName = ply:Nick()
    draw.SimpleTextOutlined(playerName, "Default", playerNameX + playerNameWidth / 2, playerNameY + playerNameHeight / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))

    local rotationLockWidth = 150
    local rotationLockHeight = 30
    local rotationLockX = playerNameX
    local rotationLockY = playerNameY + playerNameHeight + 10
    surface.SetDrawColor(50, 50, 50, 180)
    surface.DrawRect(rotationLockX, rotationLockY, rotationLockWidth, rotationLockHeight)
    local isRotationLocked = ply:Team() == 1
    local lockText = isRotationLocked and "Verrouillé" or "Non Verrouillé"
    draw.SimpleTextOutlined(lockText, "Default", rotationLockX + rotationLockWidth / 2, rotationLockY + rotationLockHeight / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
end

hook.Add("HUDPaint", "HudProphunt", HudProphunt)
hook.Add("HUDPaint", "DrawAmmoHUD", function()
    DrawAmmoHUD()
end)
