if CLIENT then
    surface.CreateFont("TrickorTreats", {
        font = "fonts/TrickorTreats.ttf",
        size = 32,
        weight = 500,
        antialias = true,
    })
end

net.Receive("ProphuntZ_ChatMessage", function(len)
    local tbl = net.ReadTable()
    chat.AddText(unpack(tbl))
end)

include("cl_hud.lua")
net.Receive("ShowRoundHUD", function()
    hook.Add("HUDPaint", "DrawRoundWaitingHUD", DrawHUD)
end)

net.Receive("HideRoundHUD", function()
    hook.Remove("HUDPaint", "DrawRoundWaitingHUD")
end)
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


