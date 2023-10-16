-- Table pour stocker les données des joueurs à leur mort
local playerData = {}

util.AddNetworkString("ProphuntZ_ChatMessage")

function SendColoredMessage(plys, ...)
    net.Start("ProphuntZ_ChatMessage")
        net.WriteTable({...})
    net.Send(plys)
end

-- Écoutez l'événement de mort du joueur
hook.Add("PlayerDeath", "Prophunt_PlayerDeath", function(victim, inflictor, attacker)

	local color_red = Color(255, 0, 0)
	local color_blue = Color(0, 127, 255)
	local color_white = Color(255, 255, 255)

    -- Si la victime s'est suicidée
    if victim == attacker then
        print("[Prophunt Z] "..victim:Nick().." s'est suicidé.")

        -- Envoyez un message coloré à tous les joueurs
        for _, ply in ipairs(player.GetAll()) do
			SendColoredMessage(player.GetAll(), colorProphuntZ, "[Prophunt Z] ", colorName, victim:Nick(), colorText, " s'est suicidé!")
        end

        return
    end

    -- Si la victime est un prop
    if victim:Team() == TEAM_PROPS then
        print("[Prophunt Z] Un prop ("..victim:Nick()..") a été tué par "..attacker:Nick())

        -- Envoyez un message coloré à tous les joueurs
        for _, ply in ipairs(player.GetAll()) do
			SendColoredMessage(player.GetAll(), colorProphuntZ, "[Prophunt Z] ", colorText, "Le prop ", colorName, victim:Nick(), colorText, " a été tué par ", colorName, attacker:Nick(), colorText, "!")
        end

    -- Si la victime est un chasseur
    elseif victim:Team() == TEAM_HUNTERS then
        print("[Prophunt Z] Un chasseur ("..victim:Nick()..") a été tué.")

        -- Envoyez un message coloré à tous les joueurs
        for _, ply in ipairs(player.GetAll()) do
			SendColoredMessage(player.GetAll(), colorProphuntZ, "[Prophunt Z] ", colorText, "Le chasseur ", colorName, victim:Nick(), colorText, " est mort!")
        end
    end

end)

