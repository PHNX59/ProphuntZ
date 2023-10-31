include("shared.lua")
include("sv_rounds.lua")

local PROP_MODEL = "models/props_junk/rock001a.mdl"
local PAIN_SOUND = "vo/npc/male01/goodgod.wav"
local VICTORY_SOUND = "vo/coast/barn/male01/youmadeit.wav"
local TEMPS_RECHARGE = 10
local MAX_SOUND_DISTANCE = 200

local config = {
    verificationInterval = 0.5, 
    soundDelay = 30, 
    probabilityMultiplier = 50, 
    shotCounterMultiplier = 30,
    maxDecoyCount = 5, 
}

local ROCK_SOUND = {
    "physics/concrete/rock_impact_hard1.wav",
    "physics/concrete/rock_impact_hard2.wav",
    "physics/concrete/rock_impact_hard3.wav",
    "physics/concrete/rock_impact_hard4.wav",
    "physics/concrete/rock_impact_hard5.wav",
    "physics/concrete/rock_impact_hard6.wav",
    "physics/concrete/rock_impact_soft1.wav",
    "physics/concrete/rock_impact_soft2.wav",
	"physics/concrete/rock_impact_soft3.wav",
}

local randomPhrases = {
    "Alerte sosie ! Préparez-vous à des moments hilarants !",
    "Un imposteur chez les chasseurs ? Ça va être drôle !",
    "Nouveau chasseur : Sosie détecté !",
    "Chasseurs, vous avez un ami… ou peut-être pas !",
    "Le mystère s'épaissit : Un prop parmi les chasseurs !",
    "Un intrus chez les chasseurs ? Lequel d'entre vous est le sosie ?",
    "Bienvenue au nouveau chasseur ! Ou pas ?",
    "Chasseurs, vous avez un camarade secret !",
    "C'est le moment du grand dévoilement : Qui est le sosie ?",
    "Un déguisement dans les rangs des chasseurs ! Qui l'eût cru ?",
}

local flashPhrases = {
    "a dit : 'Surprise !' en lançant une grenade flash. Qui a oublié ses lunettes de soleil ?",
    "a pensé que c'était le bon moment pour un éclairage supplémentaire. Vous devriez le remercier !",
    "a décidé de tester si vous aviez peur du noir après une grande lumière. Résultat ?",
    "se demande : 'Est-ce que ça vous a ébloui ou est-ce juste mon charme ?'",
    "voulait simplement égayer votre journée avec une petite explosion lumineuse.",
    "a toujours voulu être photographe. Dites 'fromage' !",
    "a pensé que vous aimeriez une petite pause lumineuse. Profitez-en !",
    "se demande si cette lumière était aussi brillante que son avenir.",
    "pense que vous devriez essayer de voir les choses sous un autre angle. Comme... super lumineux ?",
    "a entendu dire que vous cherchiez une source de lumière. Voilà qui est fait !",
    "espère que cela illuminera votre journée... ou au moins quelques secondes.",
    "a toujours voulu être le centre d'attention. Voilà sa façon de briller !",
    "voulait partager un peu de sa lumière intérieure. C'était peut-être un peu trop littéral...",
    "vous rappelle de toujours chercher la lumière au bout du tunnel. Ou, dans ce cas, juste devant vous.",
    "vous suggère de prendre cette lumière comme un signe. Mais quel signe exactement, c'est à vous de décider.",
    "croit que la vie est pleine de moments lumineux. En voilà un autre !",
    "a toujours voulu être le centre d'attention. Voilà sa façon de briller !",
    "voulait partager un peu de sa lumière intérieure. C'était peut-être un peu trop littéral...",
}

local propkillhunter = {
    "Vous pensiez avoir trouvé un prop, mais c'était moi, le chasseur ! Oh, attendez...",
    "J'ai transformé un chasseur en un tas de confusion. Qui est la proie maintenant ?",
    "Chasseur, chasseur, dans ma ligne de mire, qui est le plus chassé maintenant ?",
    "Le chasseur est devenu la proie ! Je suis tellement bon que même les chasseurs veulent être comme moi.",
    "Chasseur transformé en décoration de salon. Je suis un véritable artiste."
}

local lastCheckTime = CurTime()
local lastSoundPlayed = {}
local decoyPropsUsedFlash = {}
local hunterShots = {}
local propColors = {}

local function RegenerateHealthForProps()
    for _, player in pairs(player.GetAll()) do
        if player:Team() == TEAM_PROPS then
            local currentHealth = player:Health()
            local maxHealth = player:GetMaxHealth()
            if currentHealth < maxHealth then
                player:SetHealth(math.min(currentHealth + 1, maxHealth))
            end
        end
    end
end

-- Function to create decoy props
local function CreateDecoy(ply)
    if ply:Team() == TEAM_PROPS and ply:Alive() then
        local playerPosition = ply:GetPos()

        for i = 1, config.maxDecoyCount do
            local decoyPosition = playerPosition + VectorRand() * 75

            local trace = util.TraceHull{
                start = decoyPosition,
                endpos = decoyPosition,
                mins = Vector(-10, -10, 0),
                maxs = Vector(20, 20, 20),
                filter = ply,
            }

            if not trace.Hit then
                local decoy = ents.Create("prop_physics")
                if IsValid(decoy) then
                    if i == 1 then
                        ply:SetPos(decoyPosition)
                    end

                    decoy:SetModel(ply:GetModel())
                    decoy:PhysicsInitStatic(SOLID_NONE)
                    decoy:SetMoveType(MOVETYPE_NONE)
                    decoy:SetPos(decoyPosition)
                    decoy:Spawn()

                    util.Effect("Explosion", EffectData{
                        origin = decoyPosition,
                        magnitude = 2,
                        scale = 1,
                    })

                    timer.Simple(5, function()
                        if IsValid(decoy) then
                            decoy:Remove()
                        end
                    end)
                end
            end
        end
    end
    ply.nextDecoyUseTime = CurTime() + 1
end

-- Fonction pour lancer un caillou avec 5 sons aléatoires
local function LancerCaillou(ply)
    if ply:Team() == TEAM_PROPS and ply:Alive() and (not ply.prochainUtilisationCaillou or CurTime() >= ply.prochainUtilisationCaillou or ply:IsAdmin()) then
        local randomRockSounds = {}
        for i = 1, 5 do
            table.insert(randomRockSounds, ROCK_SOUND[math.random(1, #ROCK_SOUND)])
        end

        -- Créer une entité caillou
        local caillou = ents.Create("prop_physics")
        caillou:SetModel(PROP_MODEL)
        caillou:SetModelScale(0.3, 0)
        caillou:SetPos(ply:EyePos() + (ply:EyeAngles():Forward() * 50))
        caillou:Spawn()
        caillou.thrower = ply

        -- Appliquer une vélocité au caillou
        local physiqueCaillou = caillou:GetPhysicsObject()
        if IsValid(physiqueCaillou) then
            physiqueCaillou:SetVelocity(ply:EyeAngles():Forward() * 1000)
        end

        -- Utilisez la table de sons aléatoires
        for _, sonCaillou in ipairs(randomRockSounds) do
            ply:EmitSound(sonCaillou, 55, 100, VOLUME_CAILLOU_LANCEMENT)
        end

        -- Supprimer le caillou après 3 secondes
        timer.Simple(3, function()
            if IsValid(caillou) then
                caillou:Remove()
            end
        end)

        -- Vérifier si le caillou a touché un joueur
        timer.Simple(0.1, function()
            local trace = {}
            trace.start = ply:EyePos()
            trace.endpos = trace.start + ply:EyeAngles():Forward() * 1000
            trace.filter = ply

            local tr = util.TraceLine(trace)

            if tr.HitNonWorld and tr.Entity:IsPlayer() and (tr.Entity:Team() == TEAM_HUNTERS or tr.Entity:IsBot()) then
                -- Émettre le son de douleur pour le joueur touché
                tr.Entity:EmitSound(PAIN_SOUND, 75, 100, VOLUME_SON)

                -- Notifier tous les joueurs que le caillou a touché un joueur
                for _, joueur in ipairs(player.GetAll()) do
                    joueur:ChatPrint(ply:Nick() .. " a lancé un caillou sur " .. tr.Entity:Nick() .. " !")
                end

                -- Appliquer une vision floue au joueur touché temporairement
                tr.Entity:SetNWBool("BlurredVision", true)
                timer.Simple(3, function()
                    if IsValid(tr.Entity) then
                        tr.Entity:SetNWBool("BlurredVision", false)
                    end
                end)
            else
                -- Notifier tous les joueurs que le caillou a manqué sa cible
                for _, joueur in ipairs(player.GetAll()) do
                    joueur:ChatPrint(ply:Nick() .. " a lancé un caillou mais n'a touché personne !")
                end
            end
        end)

        -- Définir le temps de recharge pour le joueur
        if not ply:IsAdmin() then
            ply.prochainUtilisationCaillou = CurTime() + TEMPS_RECHARGE
        end
    end
end

-- Function to check if a player has an active rock (caillou)
local function PlayerHasActiveRock(ply)
    if ply:Team() == TEAM_PROPS and ply:Alive() then
        for _, ent in pairs(ents.FindByClass("prop_physics")) do
            if ent:GetModel() == PROP_MODEL and ent.thrower == ply then
                return true
            end
        end
        return false
    end
end

hook.Add("EntityTakeDamage", "PreventRockDamage", function(target, dmginfo)
    if dmginfo:GetInflictor():GetClass() == "prop_physics" and dmginfo:GetInflictor():GetModel() == PROP_MODEL then
        dmginfo:SetDamage(1)
    end
end)

hook.Add("PlayerButtonDown", "ThrowRockOnRightClick", function(ply, button)
    if button == MOUSE_RIGHT then
        if ply:Team() == TEAM_PROPS and ply:Alive() then
            LancerCaillou(ply)
        end
    end
end)

hook.Add("PlayerDeath", "PlayerKilledHunter", function(victim, inflictor, attacker)
    if victim:Team() == TEAM_HUNTERS and attacker:IsPlayer() and attacker:Team() == TEAM_PROPS then
        attacker:EmitSound(VICTORY_SOUND, 75, 100, VOLUME_SOUND)

        local randomPhrase = propkillhunter[math.random(#propkillhunter)]

        local funnyMessage = "Prop " .. attacker:Nick() .. " vient de transformer " .. victim:Nick() .. " en chasseur : " .. randomPhrase
        for _, player in ipairs(player.GetAll()) do
            player:ChatPrint(funnyMessage)
        end
    end
end)

-- Hook for using the Create Decoy ability on numpad 2
hook.Add("PlayerButtonDown", "UseDecoyAbility", function(ply, button)
    if button == KEY_PAD_2 then
        if ply:Team() == TEAM_PROPS and IsValid(decoy) and ply:Alive() then
            if not ply.nextDecoyUseTime or CurTime() > ply.nextDecoyUseTime then
                CreateDecoy(ply)
            else
                local remainingTime = math.ceil(ply.nextDecoyUseTime - CurTime())
                ply:ChatPrint("[Prophunt Z] Temps de recharge restant: " .. remainingTime .. " secondes.")
            end
        else
            ply:ChatPrint("[Prophunt Z] Vous ne pouvez utiliser cette capacité que lorsque vous êtes transformé en un prop.")
        end
    end
end)

-- Function to create a flash grenade
local function CreateFlashGrenade(target)
    local flashGrenade = ents.Create("npc_grenade_frag")
    if not IsValid(flashGrenade) then return end

    flashGrenade:SetPos(target:GetPos() + Vector(0, 0, 25))
    flashGrenade:SetOwner(target)
    flashGrenade:Spawn()
    flashGrenade:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local physFlashGrenade = flashGrenade:GetPhysicsObject()
    if IsValid(physFlashGrenade) then
        physFlashGrenade:ApplyForceCenter(Vector(0, 0, 150))
    end

    return flashGrenade
end

-- Function to adjust probability multiplier
local function SetProbabilityMultiplier(multiplier)
    config.probabilityMultiplier = multiplier
end

-- Function to adjust shot counter multiplier
local function SetShotCounterMultiplier(multiplier)
    config.shotCounterMultiplier = multiplier
end

-- Function to add a hunter's shot count
local function AddHunterShotCount(ply)
    local steamID = ply:SteamID()
    hunterShots[steamID] = (hunterShots[steamID] or 0) + 1
end

-- Function to attempt triggering the flash ability
local function TryTriggerFlashAbility(attacker, target)
    local shouldTrigger = math.random(1, config.probabilityMultiplier) == 1

    if shouldTrigger and attacker:Team() == TEAM_HUNTERS then
        local flashGrenade = CreateFlashGrenade(attacker, target)

        timer.Simple(2, function()
            if IsValid(flashGrenade) then
                for _, ply in pairs(player.GetAll()) do
                    if ply:Team() == TEAM_HUNTERS and ply:GetPos():Distance(flashGrenade:GetPos()) <= 300 then
                        ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 1, 5)
                        ply:EmitSound("weapons/flashbang/flashbang_explode1.wav")
                    end
                end
                local chosenPhrase = flashPhrases[math.random(#flashPhrases)]
                for _, ply in pairs(player.GetAll()) do
                    ply:ChatPrint(target:Nick() .. " " .. chosenPhrase)
                end

                flashGrenade:Remove()
            end
        end)

        decoyPropsUsedFlash[target:UserID()] = true
    end
end

-- Hook for counting shots by hunters
hook.Add("EntityTakeDamage", "HunterShotsCounter", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if target:IsPlayer() and target:Team() == TEAM_PROPS and attacker:IsPlayer() and attacker:Team() == TEAM_HUNTERS then
        AddHunterShotCount(attacker)
    end
end)

-- Hook for triggering the flash ability on props
hook.Add("EntityTakeDamage", "FlashAbilityOnProps", function(target, dmginfo)
    if target:IsPlayer() and target:Team() == TEAM_PROPS and not decoyPropsUsedFlash[target:UserID()] then
        local attacker = dmginfo:GetAttacker()
        if attacker:IsPlayer() and attacker:Team() == TEAM_HUNTERS then
            TryTriggerFlashAbility(attacker, target)
        end
    end
end)

-- Hook for checking proximity and playing sounds
hook.Add("Think", "PlaySoundOnProximity", function()
    if CurTime() - lastCheckTime > config.verificationInterval then
        for _, hunter in pairs(player.GetAll()) do
            if hunter:Team() == TEAM_HUNTERS then
                for _, prop in pairs(player.GetAll()) do
                    if prop:Team() == TEAM_PROPS and prop:Alive() then
                        local distance = hunter:GetPos():Distance(prop:GetPos())
                        if distance <= 50 then
                            local key = hunter:UserID() .. "-" .. prop:UserID()

                            if not lastSoundPlayed[key] or CurTime() - lastSoundPlayed[key] > config.soundDelay then
                                local randomSound = LaughBarneySounds[math.random(1, #LaughBarneySounds)]
                                local volume = 0.7 -- Adjust this volume value as needed (1.0 is full volume)

                                -- Emit the sound with volume control
                                prop:EmitSound(randomSound, 75, 100, volume)

                                hunter:ChatPrint("[Prophunt Z] " .. hunter:Nick() .. " est proche de " .. prop:Nick() .. "!")
                                prop:ChatPrint("[Prophunt Z] " .. hunter:Nick() .. " est proche de " .. prop:Nick() .. "!")
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