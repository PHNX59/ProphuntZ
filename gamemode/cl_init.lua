include("cl_hud.lua")
include("cl_scoreboard.lua")

local function SetupThirdPersonView()
    hook.Add("CalcView", "PropHuntThirdPersonView", function(ply, pos, angles, fov)
        local view = {}
        view.origin = pos - angles:Forward() * 100 
        view.angles = angles
        view.fov = fov
        view.drawviewer = true
        return view
    end)
end
SetupThirdPersonView()

net.Receive("ProphuntZ_ChatMessage", function(len)
    local tbl = net.ReadTable()
    chat.AddText(unpack(tbl))
end)

net.Receive("ShowRoundHUD", function()
    hook.Add("HUDPaint", "DrawRoundWaitingHUD", DrawHUD)
end)

net.Receive("HideRoundHUD", function()
    hook.Remove("HUDPaint", "DrawRoundWaitingHUD")
end)

net.Receive("SendRandomMessage", function()
    local prefix = net.ReadString()
    local message = net.ReadString()

    local prefixColor = Color(180, 0, 0) -- Rouge
    local messageColor = Color(255, 255, 255) -- Vert

    chat.AddText(prefixColor, prefix, messageColor, message)
end)
