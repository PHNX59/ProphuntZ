include("shared.lua")

local playerProps = {}

hook.Add("Think", "CheckForTransformation", function()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() == TEAM_PROPS then
            local trace = ply:GetEyeTrace()
            local ent = trace.Entity
            if IsValid(ent) and ent:GetClass() == "prop_physics" and ply:KeyDown(IN_ATTACK) then
                print(ply:Nick() .. " veut se transformer en " .. ent:GetModel()) -- Message de débogage.
                TransformPlayerToProp(ply, ent) 
            end
        end
    end
end)

function TransformPlayerToProp(ply, ent)
    if not IsValid(ply) or ply:Team() ~= TEAM_PROPS then
        return
    end

    if not IsValid(ent) then
        local trace = ply:GetEyeTrace()
        ent = trace.Entity
    end

    if IsValid(ent) and ent:GetClass() == "prop_physics" then
        print(ply:Nick() .. " se transforme en " .. ent:GetModel())

        if playerProps[ply] and IsValid(playerProps[ply]) then
            local oldProp = playerProps[ply]
            print(ply:Nick() .. " réinitialise l'ancien prop_physics à la position " .. tostring(ply:GetPos()))
            oldProp:SetPos(ply:GetPos())
            oldProp:SetAngles(ply:GetAngles())
            oldProp:Spawn()
        end

        playerProps[ply] = ent
        ply:SetModel(ent:GetModel())
        ply:SetPos(ent:GetPos())
        ply:SetAngles(ent:GetAngles())
        ent:Remove()
    end
end


hook.Add("CreateMove", "RotatePlayerOrProp", function(cmd)
    local ply = LocalPlayer()

    if not IsValid(ply) or ply:Team() ~= TEAM_PROPS then
        return
    end

    local prop = ply:GetPropEntity()
    if IsValid(prop) and prop:GetClass() == "prop_physics" then
        local cameraAngles = cmd:GetViewAngles()
        local rotateSpeed = 9.0 
        local rotation = Angle(0, 0, 0)
        local targetRotation = Angle(0, cameraAngles.y, 0)
        rotation = LerpAngle(0.1, prop:GetAngles(), targetRotation)
        prop:SetAngles(rotation)
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        cmd:SetUpMove(0)
    end
end)
