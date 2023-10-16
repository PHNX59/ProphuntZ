-- Configuration des constantes
local config = {
    intervalleVerification = 0.5, -- Intervalle de vérification pour l'aptitude Son de Proximité
    delaiSon = 30, -- Délai avant de pouvoir réentendre le son
    multiplicateurProbabilite = 50, -- Le multiplicateur de probabilité de déclenchement de l'aptitude Flash
    multiplicateurCompteurTirs = 30, -- Le multiplicateur du compteur de tirs des chasseurs
    nombreMaxDeLeurres = 5, -- Nombre maximum de leurres créés
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
    "Un déguisement dans les rangs des chasseurs ! Qui l'eût cru ?"
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

local dernierControle = CurTime()
local derniereLecture = {}
local propsUtilisesFlash = {}
local tirsChasseurs = {}
local propColors = {}

local function CreerLeurre(ply)
    local positionJoueur = ply:GetPos()

    for i = 1, config.nombreMaxDeLeurres do
        local positionLeurre = positionJoueur + VectorRand() * 100

        local trace = util.TraceHull{
            start = positionLeurre,
            endpos = positionLeurre,
            mins = Vector(-10, -10, 0),
            maxs = Vector(10, 10, 10),
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

                timer.Simple(3, function()
                    if IsValid(leurre) then
                        leurre:Remove()
                    end
                end)
            end
        end
    end

    ply.prochainUtilisationLeurre = CurTime() + 1
end


function FindNearestEnemy(currentPlayer)
    local currentPlayerPos = currentPlayer:GetPos()
    local nearestHunter = nil
    local nearestDistance = math.huge

    for _, hunter in pairs(player.GetAll()) do
        if hunter:Team() == TEAM_HUNTERS then
            local hunterPos = hunter:GetPos()
            local distance = currentPlayerPos:Distance(hunterPos)

            if distance < nearestDistance then
                nearestHunter = hunter
                nearestDistance = distance
            end
        end
    end

    return nearestHunter, nearestDistance
end


hook.Add("PlayerButtonDown", "AptitudeLeurre", function(ply, bouton)
    if bouton == KEY_PAD_2 then
        if ply:Team() == TEAM_PROPS then
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
                        if distance <= 150 then
                            local cle = chasseur:UserID() .. "-" .. prop:UserID()

                            if not derniereLecture[cle] or CurTime() - derniereLecture[cle] > config.delaiSon then
                                prop:EmitSound("vo/npc/Barney/ba_laugh01.wav")
                                chasseur:ChatPrint("[Prophunt] Un prop est à proximité !")
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

    if devraitDeclencher then
        local grenadeFlash = CreerGrenadeFlash(cible)

        timer.Simple(1, function()
            if IsValid(grenadeFlash) then
                for _, ply in pairs(player.GetAll()) do
                    if ply:Team() == TEAM_PROPS and ply:GetPos():Distance(grenadeFlash:GetPos()) <= 300 then
                        ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 1, 5)
                        ply:EmitSound("weapons/flashbang/flashbang_explode1.wav")
                    end
                end
                local phraseChoisie = flashPhrases[math.random(#flashPhrases)]
                for _, ply in pairs(player.GetAll()) do
                    ply:ChatPrint(cible:Nick() .. " " .. phraseChoisie)
                end

                grenadeFlash:Remove()
            end
        end)

        propsUtilisesFlash[cible:UserID()] = true
    end
end

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

timer.Create("RegeneratePropsHealth", 1, 0, RegenerateHealthForProps)

hook.Add("PlayerButtonDown", "CloneTeamAndAppearance", function(player, button)
    if button == KEY_PAD_4 then
        local currentPlayer = player
        local nearestEnemy = FindNearestEnemy(currentPlayer)

        if IsValid(nearestEnemy) then
            CloneTeamAndAppearance(nearestEnemy, currentPlayer)
            currentPlayer:ChatPrint("Vous avez cloné la team et l'apparence de " .. nearestEnemy:Name())

            timer.Simple(10, function()
                if IsValid(currentPlayer) then
                    currentPlayer:SetPlayerColor(propColors[currentPlayer] or Vector(1, 1, 1))
                    currentPlayer:SetWeaponColor(Vector(1, 1, 1))
                end
            end)
        else
            currentPlayer:ChatPrint("Aucun ennemi à proximité.")
        end
    end
end)

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
