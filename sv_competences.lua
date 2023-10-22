local MODELE_CAILLOU = "models/props_junk/rock001a.mdl"
local SON_CAILLOU = "vo/ravenholm/engage01.wav"
local SON_DOULEUR = "npc/metropolice/pain1.wav"
local TEMPS_RECHARGE = 10
local DISTANCE_MAX_SON = 200

local config = {
    intervalleVerification = 0.5, 
    delaiSon = 30, 
    multiplicateurProbabilite = 50, 
    multiplicateurCompteurTirs = 30,
    nombreMaxDeLeurres = 5, 
}

-- Liste de sons que vous souhaitez jouer aléatoirement
local Laughbarney = {
    "vo/npc/Barney/ba_laugh01.wav",
    "vo/npc/Barney/ba_laugh02.wav",
    "vo/npc/Barney/ba_laugh03.wav",
	"vo/npc/Barney/ba_laugh04.wav",
    -- Ajoutez d'autres chemins de fichiers audio au besoin
}

local phrasesAleatoires = {
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

local phrasesEclair = {
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

local dernierControle = CurTime()
local derniereLecture = {}
local propsUtilisesFlash = {}
local tirsChasseurs = {}
local propColors = {}

local function CreerLeurre(ply)
	if ply:Team() == TEAM_PROPS and ply:Alive() then
		local positionJoueur = ply:GetPos()

		for i = 1, config.nombreMaxDeLeurres do
			local positionLeurre = positionJoueur + VectorRand() * 75

			local trace = util.TraceHull{
				start = positionLeurre,
				endpos = positionLeurre,
				mins = Vector(-10, -10, 0),
				maxs = Vector(20, 20, 20),
				filter = ply,
			}

			if not trace.Hit then
				local leurre = ents.Create("prop_physics")
				if IsValid(leurre) then
					if i == 1 then
						ply:SetPos(positionLeurre)
					end

					leurre:SetModel(ply:GetModel())
					leurre:PhysicsInitStatic(SOLID_NONE)
					leurre:SetMoveType(MOVETYPE_NONE)
					leurre:SetPos(positionLeurre)
					leurre:Spawn()

					util.Effect("Explosion", EffectData{
						origin = positionLeurre,
						magnitude = 2,
						scale = 1,
					})

					timer.Simple(5, function()
						if IsValid(leurre) then
							leurre:Remove()
						end
					end)
				end
			end
		end
	end
    ply.prochainUtilisationLeurre = CurTime() + 1
end

local function JoueurPossedeCaillouActif(ply)
	if ply:Team() == TEAM_PROPS and ply:Alive() then
		for _, ent in pairs(ents.FindByClass("prop_physics")) do
			if ent:GetModel() == MODELE_CAILLOU and ent.thrower == ply then
				return true
			end
		end
		return false
	end
end

local function LancerCaillou(ply)
    if ply:Team() == TEAM_PROPS and ply:Alive() and (not ply.nextStoneTime or CurTime() >= ply.nextStoneTime or ply:IsAdmin()) then
        local caillou = ents.Create("prop_physics")
        caillou:SetModel(MODELE_CAILLOU)
        caillou:SetModelScale(0.3, 0)
        caillou:SetPos(ply:EyePos() + (ply:EyeAngles():Forward() * 50))
        caillou:Spawn()

        caillou.thrower = ply

        local physique = caillou:GetPhysicsObject()
        if IsValid(physique) then
            physique:SetVelocity(ply:EyeAngles():Forward() * 1000)
        end

        ply:EmitSound(SON_CAILLOU, 55, 100, VOLUME_CAILLOU_LANCEMENT)
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
                tr.Entity:EmitSound(SON_DOULEUR, 75, 100, VOLUME_SON)
                for _, player in ipairs(player.GetAll()) do
                    player:ChatPrint(ply:Nick() .. " a lancé un caillou sur " .. tr.Entity:Nick() .. " !")
                end

                tr.Entity:SetNWBool("BlurredVision", true)
                timer.Simple(3, function()
                    if IsValid(tr.Entity) then
                        tr.Entity:SetNWBool("BlurredVision", false)
                    end
                end)
            else
                for _, player in ipairs(player.GetAll()) do
                    player:ChatPrint(ply:Nick() .. " a lancé un caillou mais n'a touché personne !")
                end
            end
        end)

        if not ply:IsAdmin() then
            ply.nextStoneTime = CurTime() + TEMPS_RECHARGE
        end
    end
end

hook.Add("EntityTakeDamage", "PreventStoneDamage", function(target, dmginfo)
    if dmginfo:GetInflictor():GetClass() == "prop_physics" and dmginfo:GetInflictor():GetModel() == MODELE_CAILLOU then
        dmginfo:SetDamage(0)
    end
end)

hook.Add("PlayerButtonDown", "ThrowStoneOnF1", function(ply, button)
    if button == MOUSE_RIGHT then
		if ply:Team() == TEAM_PROPS and ply:Alive() then
			LancerCaillou(ply)
		end
    end
end)

hook.Add("PlayerButtonDown", "AptitudeLeurre", function(ply, bouton)
    if bouton == KEY_PAD_2 then
        if ply:Team() == TEAM_PROPS and ply:Alive() then
            if not ply.prochainUtilisationLeurre or CurTime() > ply.prochainUtilisationLeurre then
                CreerLeurre(ply)
            else
                local tempsRestant = math.ceil(ply.prochainUtilisationLeurre - CurTime())
                ply:ChatPrint("Temps de recharge restant : " .. tempsRestant .. " secondes.")
            end
        else
            ply:ChatPrint("Vous ne pouvez utiliser cette aptitude que lorsque vous êtes transformé en prop.")
        end
    end
end)

hook.Add("Think", "SonProximiteAptitude", function()
    if CurTime() - dernierControle > config.intervalleVerification then
        for _, chasseur in pairs(player.GetAll()) do
            if chasseur:Team() == TEAM_HUNTERS then
                for _, prop in pairs(player.GetAll()) do
                    if prop:Team() == TEAM_PROPS and prop:Alive() then
                        local distance = chasseur:GetPos():Distance(prop:GetPos())
                        if distance <= 75 then
                            local cle = chasseur:UserID() .. "-" .. prop:UserID()

                            if not derniereLecture[cle] or CurTime() - derniereLecture[cle] > config.delaiSon then
                                local randomSound = Laughbarney[math.random(1, #Laughbarney)]
                                local volume = 0.8 -- Adjust this volume value as needed (1.0 is full volume)

                                -- Emit the sound with volume control
                                prop:EmitSound(randomSound, 75, 100, volume)
                                
                                chasseur:ChatPrint("[Prophunt Z] " .. chasseur:Nick() .. " est près de " .. prop:Nick() .. " !")
								prop:ChatPrint("[Prophunt Z] " .. chasseur:Nick() .. " est près de " .. prop:Nick() .. " !")
                                derniereLecture[cle] = CurTime()
                            end
                        end
                    end
                end
            end
        end
        dernierControle = CurTime()
    end
end)


local function CreerGrenadeFlash(cible)
    local grenadeFlash = ents.Create("npc_grenade_frag")
    if not IsValid(grenadeFlash) then return end

    grenadeFlash:SetPos(cible:GetPos() + Vector(0, 0, 25))
    grenadeFlash:SetOwner(cible)
    grenadeFlash:Spawn()
    grenadeFlash:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local physiqueGrenade = grenadeFlash:GetPhysicsObject()
    if IsValid(physiqueGrenade) then
        physiqueGrenade:ApplyForceCenter(Vector(0, 0, 150))
    end

    return grenadeFlash
end

local function ReglerProbabilite(multiplicateur)
    config.multiplicateurProbabilite = multiplicateur
end

local function ReglerMultiplicateurCompteurTirs(multiplicateur)
    config.multiplicateurCompteurTirs = multiplicateur
end

local function AjouterTirChasseur(ply)
    local steamID = ply:SteamID()
    tirsChasseurs[steamID] = (tirsChasseurs[steamID] or 0) + 1
end

local function EssayerDeclencherAptitudeFlash(attaquant, cible)
    local devraitDeclencher = math.random(1, config.multiplicateurProbabilite) == 1

    if devraitDeclencher and attaquant:Team() == TEAM_HUNTERS then
        local grenadeFlash = CreerGrenadeFlash(attaquant, cible)

        timer.Simple(1, function()
            if IsValid(grenadeFlash) then
                for _, ply in pairs(player.GetAll()) do
                    if ply:Team() == TEAM_PROPS and ply:GetPos():Distance(grenadeFlash:GetPos()) <= 300 then
                        ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 1, 5)
                        ply:EmitSound("weapons/flashbang/flashbang_explode1.wav")
                    end
                end
                local phraseChoisie = phrasesEclair[math.random(#phrasesEclair)]
                for _, ply in pairs(player.GetAll()) do
                    ply:ChatPrint(cible:Nick() .. " " .. phraseChoisie)
                end

                grenadeFlash:Remove()
            end
        end)

        propsUtilisesFlash[cible:UserID()] = true
    end
end

hook.Add("EntityTakeDamage", "TirsChasseurs", function(cible, infoDegats)
    local attaquant = infoDegats:GetAttacker()
    if cible:IsPlayer() and cible:Team() == TEAM_PROPS and attaquant:IsPlayer() and attaquant:Team() == HUNTERS then
        AjouterTirChasseur(attaquant)
    end
end)

hook.Add("EntityTakeDamage", "AptitudeFlashProps", function(cible, infoDegats)
    if cible:IsPlayer() and cible:Team() == TEAM_PROPS and not propsUtilisesFlash[cible:UserID()] then
        local attaquant = infoDegats:GetAttacker()
        if attaquant:IsPlayer() and attaquant:Team() == TEAM_HUNTERS then
            EssayerDeclencherAptitudeFlash(attaquant, cible)
        end
    end
end)