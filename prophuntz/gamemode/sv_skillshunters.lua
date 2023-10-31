include("shared.lua")
include("sv_rounds.lua")

local interval = 2
local healthDecreaseAmount = 1

local minRegainHealth = 3
local maxRegainHealth = 10

local config = {
    verificationInterval = 1, -- Adjust the interval as needed (in seconds)
    soundDelay = 60, -- Adjust the delay between playing sounds (in seconds)
    probability = 35, -- Probability of triggering the ability (in percentage)
}

local LaughBarneySounds = {
    "vo/npc/Barney/ba_laugh01.wav",
    "vo/npc/Barney/ba_laugh02.wav",
    "vo/npc/Barney/ba_laugh03.wav",
	"vo/npc/Barney/ba_laugh04.wav",
    -- Ajoutez d'autres chemins de fichiers audio au besoin
}

local lastCheckTime = 0
local lastSoundPlayed = {}

local function DecreaseHunterHealth()
    if currentRound == ROUND_ACTIVE then
        for _, player in pairs(team.GetPlayers(TEAM_HUNTERS)) do
            if player:Alive() then
                local currentHealth = player:Health()
                local newHealth = math.max(currentHealth - healthDecreaseAmount, 0)

                if newHealth <= 0 then
                    player:Kill()
                else
                    player:SetHealth(newHealth)
                end
            end
        end
    end
end
timer.Create("HunterHealthDecreaseTimer", interval, 0, DecreaseHunterHealth)

hook.Add("Think", "PlaySoundOnProximity", function()
    if CurTime() - lastCheckTime > config.verificationInterval then
        for _, hunter in pairs(player.GetAll()) do
            if hunter:Team() == TEAM_HUNTERS then
                for _, prop in pairs(player.GetAll()) do
                    if prop:Team() == TEAM_PROPS and prop:Alive() and hunter != prop then
                        local distance = hunter:GetPos():Distance(prop:GetPos())
                        if distance <= 50 then
                            local key = hunter:UserID() .. "-" .. prop:UserID()

                            -- Check the probability of triggering the ability
                            if not lastSoundPlayed[key] and math.random(1, 100) <= config.probability then
                                local randomSound = LaughBarneySounds[math.random(1, #LaughBarneySounds)]
                                local volume = 0.5 -- Adjust this volume value as needed (1.0 is full volume)

                                -- Emit the sound with volume control
                                prop:EmitSound(randomSound, 75, 100, volume)

                                hunter:ChatPrint("[Prophunt Z] " .. hunter:Nick() .. " est proche de " .. prop:Nick() .. "!")
                                prop:ChatPrint("[Prophunt Z] " .. hunter:Nick() .. " est proche de vous!")

                                -- Update the last sound played time
                                lastSoundPlayed[key] = CurTime()
                            end
                        end
                    end
                end
            end
        end
        lastCheckTime = CurTime()
    end
end)