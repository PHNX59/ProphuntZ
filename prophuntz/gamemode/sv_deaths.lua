local playerData = {}

util.AddNetworkString("ProphuntZ_ChatMessage")

function SendColoredMessage(plys, ...)
    net.Start("ProphuntZ_ChatMessage")
        net.WriteTable({...})
    net.Send(plys)
end

hook.Add("PlayerDeath", "Prophunt_PlayerDeath", function(victim, inflictor, attacker)

	local color_red = Color(255, 0, 0)
	local color_blue = Color(0, 127, 255)
	local color_white = Color(255, 255, 255)

    if victim == attacker then
        print("[Prophunt Z] "..victim:Nick().." s'est suicidé.")

        for _, ply in ipairs(player.GetAll()) do
			SendColoredMessage(player.GetAll(), colorProphuntZ, "[Prophunt Z] ", colorName, victim:Nick(), colorText, " s'est suicidé!")
        end

        return
    end

    if victim:Team() == TEAM_PROPS then
        print("[Prophunt Z] Un prop ("..victim:Nick()..") a été tué par "..attacker:Nick())

        for _, ply in ipairs(player.GetAll()) do
			SendColoredMessage(player.GetAll(), colorProphuntZ, "[Prophunt Z] ", colorText, "Le prop ", colorName, victim:Nick(), colorText, " a été tué par ", colorName, attacker:Nick(), colorText, "!")
        end

    elseif victim:Team() == TEAM_HUNTERS then
        print("[Prophunt Z] Un chasseur ("..victim:Nick()..") a été tué.")

        for _, ply in ipairs(player.GetAll()) do
			SendColoredMessage(player.GetAll(), colorProphuntZ, "[Prophunt Z] ", colorText, "Le chasseur ", colorName, victim:Nick(), colorText, " est mort!")
        end
    end

end)

