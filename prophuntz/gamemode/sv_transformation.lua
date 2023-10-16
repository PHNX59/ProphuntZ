include("shared.lua")

-- Créez une table pour stocker les anciennes entités prop_physics des joueurs.
local playerProps = {}

-- Définissez un hook qui est déclenché lorsque le joueur regarde une entité.
hook.Add("Think", "CheckForTransformation", function()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() == TEAM_PROPS then
            local trace = ply:GetEyeTrace()
            local ent = trace.Entity

            -- Si le joueur appuie sur le bouton gauche de la souris (clic gauche) et regarde un prop_physics valide, effectuez la transformation.
            if IsValid(ent) and ent:GetClass() == "prop_physics" and ply:KeyDown(IN_ATTACK) then
                print(ply:Nick() .. " veut se transformer en " .. ent:GetModel()) -- Message de débogage.
                TransformPlayerToProp(ply, ent) -- Passer l'entité regardée à la fonction.
            end
        end
    end
end)

function TransformPlayerToProp(ply, ent)
    if not IsValid(ply) or ply:Team() ~= TEAM_PROPS then
        return -- Vérifie si le joueur est valide et s'il est dans l'équipe des props
    end

    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    -- Assurez-vous que l'entité regardée est valide et qu'elle est un prop_physics (ou le type d'entité que vous autorisez à être copié).
    if IsValid(ent) and ent:GetClass() == "prop_physics" then
        print(ply:Nick() .. " se transforme en " .. ent:GetModel()) -- Message de débogage.

        -- Si le joueur avait précédemment une entité prop_physics, réinitialisez-la.
        if playerProps[ply] and IsValid(playerProps[ply]) then
            local oldProp = playerProps[ply]
            print(ply:Nick() .. " réinitialise l'ancien prop_physics à la position " .. tostring(ply:GetPos())) -- Message de débogage.
            oldProp:SetPos(ply:GetPos())
            oldProp:SetAngles(ply:GetAngles())
            oldProp:Spawn()
        end

        -- Stockez l'entité actuelle dans la table playerProps.
        playerProps[ply] = ent

        -- Appliquez le modèle, la position et l'angle de l'entité regardée au joueur.
        ply:SetModel(ent:GetModel())
        ply:SetPos(ent:GetPos())
        ply:SetAngles(ent:GetAngles())

        -- Supprimez l'entité prop_physics utilisée pour la transformation.
        ent:Remove()
    end
end

-- Définissez un hook "CreateMove" pour obtenir les entrées du joueur.
hook.Add("CreateMove", "RotatePlayerOrProp", function(cmd)
    local ply = LocalPlayer()

    -- Vérifiez si le joueur est valide et s'il est dans l'équipe des props.
    if not IsValid(ply) or ply:Team() ~= TEAM_PROPS then
        return
    end

    -- Vérifiez si le joueur est actuellement transformé en prop_physics.
    local prop = ply:GetPropEntity()
    if IsValid(prop) and prop:GetClass() == "prop_physics" then
        -- Obtenez les angles de la caméra du joueur.
        local cameraAngles = cmd:GetViewAngles()

        local rotateSpeed = 9.0 -- Vitesse de rotation (ajustez selon vos préférences)

        -- Calculez la différence d'angles entre la caméra actuelle et la caméra précédente pour obtenir la rotation.
        local rotation = Angle(0, 0, 0)

        -- Pour une rotation fluide, vous pouvez utiliser LerpAngles pour lisser la transition.
        local targetRotation = Angle(0, cameraAngles.y, 0)
        rotation = LerpAngle(0.1, prop:GetAngles(), targetRotation)

        -- Appliquez la rotation à l'entité prop_physics du joueur.
        prop:SetAngles(rotation)

        -- Empêchez le mouvement du joueur pendant la rotation du prop.
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        cmd:SetUpMove(0)
    end
end)
