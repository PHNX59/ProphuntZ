-- Configuration
local CAILLOU_MODEL = "models/props_junk/rock001a.mdl"
local CAILLOU_SOUND = "physics/body/body_medium_impact_soft1.wav"
local PAIN_SOUND = "npc/metropolice/pain1.wav" 
local RECHARGE_TIME = 1
local MAX_SOUND_DISTANCE = 1000

local function PlayerHasActiveStone(ply)
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if ent:GetModel() == CAILLOU_MODEL and ent.thrower == ply then
            return true
        end
    end
    return false
end

local function ThrowStone(ply)
    if ply:Team() == TEAM_PROPS and (not ply.nextStoneTime or CurTime() >= ply.nextStoneTime or ply:IsAdmin()) then
        local caillou = ents.Create("prop_physics")
        caillou:SetModel(CAILLOU_MODEL)
        caillou:SetModelScale(0.5, 0) 
        caillou:SetPos(ply:EyePos() + (ply:EyeAngles():Forward() * 50))
        caillou:Spawn()
		
		caillou.thrower = ply  

        local phys = caillou:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(ply:EyeAngles():Forward() * 1000)
        end

         ply:EmitSound(CAILLOU_SOUND, 75, 100, CAILLOU_THROW_VOLUME) 
        timer.Simple(3, function()
            if IsValid(caillou) then 
                caillou:Remove()
            end
        end)

		timer.Simple(0.1, function()
			local trace = {}
			trace.start = ply:EyePos()
			trace.endpos = trace.start + ply:EyeAngles():Forward() * 1000
			trace.filter = ply

			local tr = util.TraceLine(trace)

			if tr.HitNonWorld and tr.Entity:IsPlayer() and (tr.Entity:Team() == TEAM_HUNTERS or tr.Entity:IsBot()) then
				tr.Entity:EmitSound(PAIN_SOUND, 75, 100, volume) 

				for _, player in ipairs(player.GetAll()) do
					player:ChatPrint(ply:Nick() .. " a lancé un caillou sur " .. tr.Entity:Nick() .. "!")
				end

				tr.Entity:SetNWBool("BlurredVision", true)
				timer.Simple(3, function()
					if IsValid(tr.Entity) then
						tr.Entity:SetNWBool("BlurredVision", false)
					end
				end)
			else
				for _, player in ipairs(player.GetAll()) do
					player:ChatPrint(ply:Nick() .. " a lancé un caillou mais n'a touché personne!")
				end
			end
		end)

        if not ply:IsAdmin() then
            ply.nextStoneTime = CurTime() + RECHARGE_TIME
        end
    end
end

hook.Add("EntityTakeDamage", "PreventStoneDamage", function(target, dmginfo)
    if dmginfo:GetInflictor():GetClass() == "prop_physics" and dmginfo:GetInflictor():GetModel() == CAILLOU_MODEL then
        dmginfo:SetDamage(0)
    end
end)

hook.Add("PlayerButtonDown", "ThrowStoneOnF1", function(ply, button)
    if button == KEY_F1 then
        ThrowStone(ply)
    end
end)
