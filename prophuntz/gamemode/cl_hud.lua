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

-- Fonction pour dessiner le HUD d'ammo
local function DrawAmmoHUD()
    -- Obtenez le joueur local
    local ply = LocalPlayer()

    -- Vérifiez si le joueur est valide et en vie
    if IsValid(ply) and ply:Alive() then
        -- Obtenez les informations sur l'arme actuelle du joueur
        local weapon = ply:GetActiveWeapon()

        if IsValid(weapon) then
            -- Obtenez le nombre de munitions dans le chargeur
            local ammoInClip = weapon:Clip1()
            -- Obtenez la taille totale du chargeur
            local maxAmmo = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())

            -- Paramètres du HUD d'ammo
            local rectWidth = 200 -- Largeur du rectangle
            local rectHeight = 50 -- Hauteur du rectangle
            local rectSpacing = 10 -- Espacement entre les deux rectangles
            local fontSize = 40 -- Taille de la police
            local font = "ChatFont" -- Police de caractères
            local bgColor = Color(80, 80, 80, 200) -- Couleur de fond (gris)
            local textColor = Color(255, 255, 255, 255) -- Couleur du texte (blanc)
            local borderColor = Color(255, 0, 0, 255) -- Couleur du contour (rouge)
            local borderSize = 7 -- Largeur du contour

            -- Calcul de la position X pour placer le HUD en bas à droite
            local xPos = ScrW() - rectWidth - 20

            -- Calcul de la position Y pour placer le HUD en bas
            local yPos = ScrH() - rectHeight - 20

            -- Dessinez le premier rectangle (munitions dans le chargeur) avec contour rouge
            surface.SetDrawColor(borderColor)
            surface.DrawOutlinedRect(xPos, yPos, rectWidth, rectHeight)
            draw.RoundedBox(0, xPos, yPos, rectWidth, rectHeight, bgColor)
            draw.SimpleText("Munitions: " .. ammoInClip, font, xPos + rectWidth / 2, yPos + rectHeight / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Dessinez le deuxième rectangle (taille totale du chargeur) avec contour rouge
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


-- Définir la fonction GM:DessinerHUD(ply)
function HudProphunt()
local ply = LocalPlayer()

-- Assurez-vous que le joueur est valide avant de poursuivre
if not IsValid(ply) then return end

local plyModel = ply:GetModel()	
local steamID = ply:SteamID64()

	-- Paramètres de position et de taille de l'avatar
	local x = 10
	local y = ScrH() - 110
	local w = 90
	local h = 90
	local avatarSize = 84 -- Taille de l'avatar que vous souhaitez

	-- Calculez la position X et Y de l'avatar pour le centrer dans le rectangle gris
	local avatarX = x + (w - avatarSize) / 2
	local avatarY = y + (h - avatarSize) / 2		

	-- Créez l'AvatarImage avec la nouvelle taille et la nouvelle position
	local avatar = vgui.Create("AvatarImage")
	avatar:SetSize(avatarSize, avatarSize)
	avatar:SetPos(avatarX, avatarY)
	avatar:SetPlayer(ply, avatarSize)

	-- Calculez la taille et la position du rectangle de fond pour l'avatar
	padding = padding or 0 -- si padding est nil, il sera défini à 0
    local w = avatarSize * 1.10
    local h = avatarSize * 1.10
    local avatarX = x + padding
    local avatarY = y + padding

    -- Calculer la largeur totale du HUD en fonction de tous les éléments
    local totalHUDWidth = w + padding*2 + 2 + 150 + 150 + 10
    local totalHUDHeight = h + padding*2

    -- Dessinez un grand rectangle gris autour de tous les éléments
    surface.SetDrawColor(50, 50, 50, 180)
    draw.NoTexture()
    surface.DrawRect(x, y, totalHUDWidth, totalHUDHeight)

    -- Dessinez un rectangle gris foncé comme fond derrière l'avatar.
    surface.SetDrawColor(70, 70, 70, 180)
    surface.DrawRect(avatarX, avatarY, w, h)

    -- Dessinez le trait vertical rouge à côté du rectangle gris foncé.
    local lineX = avatarX + w + padding
    local lineY = y + (totalHUDHeight - h) / 2
    local lineHeight = h
    surface.SetDrawColor(255, 0, 0, 255)
    surface.DrawRect(lineX, lineY, 2, lineHeight)

	-- Dessinez la barre de vie à droite du trait rouge
	local healthBarWidth = 20
	local healthBarHeight = h
	local healthBarX = lineX + 2 + 10
	local healthBarY = y + (totalHUDHeight - h) / 2
	local health = ply:Health()
	local maxhealth = ply:GetMaxHealth()
	local nh = math.Round(healthBarHeight * math.Clamp(health / maxhealth, 0, 1))
	surface.SetDrawColor(0, 255, 0, 255)
	surface.DrawRect(healthBarX, healthBarY + healthBarHeight - nh, healthBarWidth, nh)

	-- Afficher la valeur de la vie dans la barre de vie
	local healthText = tostring(health)
	local textSize = 8 -- Modifiez cette valeur pour la taille de police souhaitée
	local textWidth, textHeight = surface.GetTextSize(healthText)
	local textX = healthBarX + (healthBarWidth - textWidth) / 2
	local textY = healthBarY + (healthBarHeight - textHeight) / 2
	draw.SimpleTextOutlined(healthText, "Default", textX, textY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))


    -- Position et taille du rectangle du nom du joueur
    local playerNameWidth = 150
    local playerNameHeight = 30
    local playerNameX = healthBarX + healthBarWidth + 10
    local playerNameY = y + (totalHUDHeight - playerNameHeight) / 2
    surface.SetDrawColor(50, 50, 50, 180)
    surface.DrawRect(playerNameX, playerNameY, playerNameWidth, playerNameHeight)
    local playerName = ply:Nick()
    draw.SimpleTextOutlined(playerName, "Default", playerNameX + playerNameWidth / 2, playerNameY + playerNameHeight / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))

    -- Position et taille du rectangle de verrouillage de la rotation
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

-- Accrocher la fonction à l'événement HUDPaint
hook.Add("HUDPaint", "HudProphunt", HudProphunt)

hook.Add("HUDPaint", "DrawAmmoHUD", function()
    DrawAmmoHUD()
end)
