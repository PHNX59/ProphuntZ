local lastPlayedSound = {}

local soundPaths = {
	-- ZOMBIE
    "npc/zombie/claw_miss1.wav",
    "npc/zombie/claw_miss2.wav",
    "npc/zombie/claw_strike1.wav",
    "npc/zombie/claw_strike2.wav",
    "npc/zombie/claw_strike3.wav",
    "npc/zombie/foot1.wav",
    "npc/zombie/foot2.wav",
    "npc/zombie/foot3.wav",
    "npc/zombie/foot_slide1.wav",
    "npc/zombie/foot_slide2.wav",
    "npc/zombie/foot_slide3.wav",
    "npc/zombie/moan_loop1.wav",
    "npc/zombie/moan_loop2.wav",
    "npc/zombie/moan_loop3.wav",
    "npc/zombie/moan_loop4.wav",
    "npc/zombie/zombie_alert1.wav",
    "npc/zombie/zombie_alert2.wav",
    "npc/zombie/zombie_alert3.wav",
    "npc/zombie/zombie_die1.wav",
    "npc/zombie/zombie_die2.wav",
    "npc/zombie/zombie_die3.wav",
    "npc/zombie/zombie_hit.wav",
    "npc/zombie/zombie_pain1.wav",
    "npc/zombie/zombie_pain2.wav",
    "npc/zombie/zombie_pain3.wav",
    "npc/zombie/zombie_pain4.wav",
    "npc/zombie/zombie_pain5.wav",
    "npc/zombie/zombie_pain6.wav",
    "npc/zombie/zombie_pound_door.wav",
    "npc/zombie/zombie_voice_idle1.wav",
    "npc/zombie/zombie_voice_idle10.wav",
    "npc/zombie/zombie_voice_idle11.wav",
    "npc/zombie/zombie_voice_idle12.wav",
    "npc/zombie/zombie_voice_idle13.wav",
    "npc/zombie/zombie_voice_idle14.wav",
    "npc/zombie/zombie_voice_idle2.wav",
    "npc/zombie/zombie_voice_idle3.wav",
    "npc/zombie/zombie_voice_idle4.wav",
    "npc/zombie/zombie_voice_idle5.wav",
    "npc/zombie/zombie_voice_idle6.wav",
    "npc/zombie/zombie_voice_idle7.wav",
    "npc/zombie/zombie_voice_idle8.wav",
    "npc/zombie/zombie_voice_idle9.wav",
    "npc/zombie/zo_attack1.wav",
    "npc/zombie/zo_attack2.wav",
    "npc/zombie/zombie_pain1.wav",
    "npc/zombie/zombie_pain2.wav",
    "npc/zombie/zombie_pain3.wav",
    "npc/zombie/zombie_pain4.wav",
    "npc/zombie/zombie_pain5.wav",
	
	"vo/Streetwar/sniper/ba_cantmove.wav",
    "vo/Streetwar/sniper/ba_gateclearance.wav",
    "vo/Streetwar/sniper/ba_goodtohavehelp.wav",
    "vo/trainyard/male01/cit_pedestrian04.wav",
    "vo/trainyard/male01/cit_pedestrian05.wav",
    "vo/trainyard/male01/cit_term_ques02.wav",
    "vo/trainyard/male01/cit_tvbust05.wav",
    "vo/trainyard/male01/cit_window_use01.wav",
    "vo/trainyard/male01/cit_window_use02.wav",
    "vo/trainyard/male01/cit_window_use03.wav",
    "vo/trainyard/male01/cit_window_use04.wav",
    
    "npc/combine_soldier/vo/on2.wav",
    "npc/combine_soldier/vo/go2.wav",
    "npc/combine_soldier/vo/move.wav",
    "npc/combine_soldier/vo/ten.wav",
    "npc/combine_soldier/vo/prepare.wav",
    
    "npc/metropolice/vo/chuckle.wav",
    "npc/metropolice/vo/excellent.wav",
    "npc/metropolice/vo/firstwarningmove.wav",
    "npc/metropolice/vo/imputdown.wav",
    "npc/metropolice/vo/line.wav",
    
    "npc/antlion/angry1.wav",
    "npc/antlion/angry2.wav",
    "npc/antlion/angry3.wav",
    "npc/antlion/angry4.wav",
    "npc/antlion/distract1.wav",
    
    "npc/headcrab/pain1.wav",
    "npc/headcrab/pain2.wav",
    "npc/headcrab/pain3.wav",
    "npc/headcrab/pain4.wav",
    "npc/headcrab/idle1.wav",
    
    "npc/vort/vort_cover.wav",
    "npc/vort/vort_foot1.wav",
    "npc/vort/vort_foot2.wav",
    "npc/vort/vort_foot3.wav",
    "npc/vort/vort_foot4.wav",
    
    "npc/strider/striderx_alert2.wav",
    "npc/strider/striderx_alert4.wav",
    "npc/strider/striderx_alert5.wav",
    "npc/strider/striderx_alert6.wav",
    "npc/strider/striderx_alert7.wav",
    
    "npc/combine_gunship/engine_whine_loop1.wav",
    "npc/combine_gunship/engine_whine_loop2.wav",
    "npc/combine_gunship/engine_whine_loop3.wav",
    
    "npc/aliendrone/attack_start1.wav",
    "npc/aliendrone/attack_start2.wav",
    "npc/aliendrone/distract1.wav",
    "npc/aliendrone/distract2.wav",

    -- Ajoutez d'autres sons de NPC au besoin
}

local soundPhrases = {
    ["npc/zombie/claw_miss1.wav"] = "Wow, quelqu'un a manqué sa manucure !",
    ["npc/zombie/claw_miss2.wav"] = "Oops, encore raté !",
    ["npc/zombie/claw_strike1.wav"] = "Un de plus pour le zombie !",
    ["npc/zombie/foot1.wav"] = "Marche de zombie, attention à vos orteils!",
    ["vo/Streetwar/sniper/ba_cantmove.wav"] = "Je reste coincé ici!",
    ["vo/trainyard/male01/cit_pedestrian04.wav"] = "Juste une autre journée en ville.",
    ["npc/combine_soldier/vo/on2.wav"] = "Allumez les lumières!",
    ["npc/combine_soldier/vo/go2.wav"] = "On y va, soldats !",
    ["npc/metropolice/vo/chuckle.wav"] = "Rires derrière le masque.",
    ["npc/antlion/angry1.wav"] = "Oh, quelqu'un a réveillé l'antlion!",
    ["npc/headcrab/pain1.wav"] = "Ce n'est vraiment pas le jour du headcrab...",
    ["npc/vort/vort_cover.wav"] = "Cache-cache avec un Vortigaunt?",
    ["npc/strider/striderx_alert2.wav"] = "Strider en mode alerte maximale!",
    ["npc/combine_gunship/engine_whine_loop1.wav"] = "Ça plane pour moi !",
    ["npc/aliendrone/attack_start1.wav"] = "Voilà l'attaque de l'aliendrone !",
	["npc/zombie/claw_strike2.wav"] = "Zombie, ce n'était pas gentil!",
	["npc/zombie/claw_strike3.wav"] = "Encore toi, zombie? Sécurisez vos ongles!",
	["npc/zombie/foot2.wav"] = "Ça sonne comme... un pas de zombie !",
	["npc/zombie/foot3.wav"] = "Un autre pas assuré du zombie.",
	["npc/zombie/foot_slide1.wav"] = "Qui glisse là?",
	["npc/zombie/foot_slide2.wav"] = "Ce sol doit être vraiment glissant !",
	["npc/zombie/moan_loop1.wav"] = "Quelqu'un a l'air d'avoir faim...",
	["npc/zombie/moan_loop2.wav"] = "Zombie mélodieux en approche!",
	["npc/zombie/zombie_alert1.wav"] = "Il sait que nous sommes ici!",
	["npc/zombie/zombie_alert2.wav"] = "Soyez silencieux, il est alerte.",
	["vo/Streetwar/sniper/ba_gateclearance.wav"] = "Quelqu'un ouvre ce portail !",
	["vo/Streetwar/sniper/ba_goodtohavehelp.wav"] = "C'est toujours bon d'avoir de l'aide.",
	["vo/trainyard/male01/cit_pedestrian05.wav"] = "Juste un citoyen ordinaire.",
	["vo/trainyard/male01/cit_term_ques02.wav"] = "Des questions en suspens.",
	["vo/trainyard/male01/cit_tvbust05.wav"] = "La télé est encore cassée.",
	["npc/combine_soldier/vo/move.wav"] = "Déplacement en cours!",
	["npc/combine_soldier/vo/ten.wav"] = "Compte à rebours!",
	["npc/combine_soldier/vo/prepare.wav"] = "Tout le monde se prépare!",
	["npc/metropolice/vo/excellent.wav"] = "Un travail bien fait!",
	["npc/metropolice/vo/firstwarningmove.wav"] = "C'était votre premier avertissement!",
	["npc/antlion/angry2.wav"] = "Cet antlion n'est vraiment pas content.",
	["npc/antlion/angry3.wav"] = "Je crois qu'il veut dire affaire sérieuse.",
	["npc/antlion/distract1.wav"] = "Regardez par ici, antlion!",
	["npc/headcrab/pain2.wav"] = "Oh non, pas le petit headcrab!",
	["npc/headcrab/pain3.wav"] = "Cela devait faire mal.",
	["npc/vort/vort_foot1.wav"] = "Ces pas ne sont pas humains...",
	["npc/vort/vort_foot2.wav"] = "C'est flippant et ça approche.",
	["npc/strider/striderx_alert3.wav"] = "Gros problème en approche!",
	["npc/strider/striderx_alert4.wav"] = "Ce strider est vraiment en colère.",
	["npc/combine_gunship/engine_whine_loop2.wav"] = "Vol de reconnaissance en cours.",
	["npc/aliendrone/attack_start2.wav"] = "Attaque imminente, attention!",
	["npc/zombie/zombie_alert3.wav"] = "Je pense que le zombie nous a repérés!",
	["npc/zombie/zombie_die1.wav"] = "Un de moins, bien joué!",
	["npc/zombie/zombie_die2.wav"] = "Zombie au tapis!",
	["npc/zombie/zombie_die3.wav"] = "Il ne reviendra pas de sitôt.",
	["npc/zombie/zombie_hit.wav"] = "Ça, c'est ce que j'appelle un coup!",
	["npc/zombie/zombie_pain1.wav"] = "Il n'a pas l'air de bien le prendre.",
	["npc/zombie/zombie_pain4.wav"] = "Continuez, il est presque fini!",
	["npc/zombie/zombie_pound_door.wav"] = "Quelqu'un veut entrer...",
	["npc/zombie/zombie_voice_idle1.wav"] = "J'entends du bruit...",
	["npc/zombie/zombie_voice_idle10.wav"] = "Il marmonne encore quelque chose.",
	["npc/zombie/zombie_voice_idle12.wav"] = "On dirait qu'il chante...",
	["npc/zombie/zombie_voice_idle14.wav"] = "De la poésie zombie, magnifique!",
	["npc/zombie/zombie_voice_idle3.wav"] = "Il a l'air un peu perdu.",
	["npc/zombie/zombie_voice_idle5.wav"] = "Il essaie de communiquer?",
	["npc/zombie/zombie_voice_idle8.wav"] = "Je pense qu'il a perdu quelque chose.",
	["npc/zombie/zombie_voice_idle9.wav"] = "Qu'est-ce qu'il veut dire?",
	["npc/zombie/zo_attack1.wav"] = "Attaque à vue!",
	["npc/zombie/zo_attack2.wav"] = "Il veut se battre!",
	["npc/combine_soldier/vo/on2.wav"] = "Ils passent à l'action!",
	["npc/combine_soldier/vo/go2.wav"] = "Ils se déplacent!",
	["npc/metropolice/vo/chuckle.wav"] = "Il trouve ça drôle?",
	["npc/metropolice/vo/imputdown.wav"] = "Pas de résistance!",
	["npc/metropolice/vo/line.wav"] = "Ils veulent mettre de l'ordre.",
	["npc/antlion/angry4.wav"] = "L'antlion s'énerve!",
	["npc/antlion/distract1.wav"] = "Distraction en cours!",
	["npc/headcrab/idle1.wav"] = "Un petit headcrab tranquille.",
	["npc/vort/vort_cover.wav"] = "Se mettre à l'abri!",
	["npc/vort/vort_foot4.wav"] = "Ces pas ne sont définitivement pas normaux.",
	["npc/strider/striderx_alert5.wav"] = "Alerte maximale pour le strider!",
	["npc/strider/striderx_alert7.wav"] = "On dirait que le strider a repéré quelque chose.",
	["npc/combine_gunship/engine_whine_loop3.wav"] = "Ces moteurs font un bruit étrange.",
	["npc/aliendrone/attack_start1.wav"] = "L'attaque commence!",
	["npc/aliendrone/distract2.wav"] = "Essayez de le distraire!",
}

local function PlayRandomTaunt(player)
    if player:Team() == TEAM_PROPS then
        local randomSoundPath
        repeat
            randomSoundPath = table.Random(soundPaths)
        until randomSoundPath != lastPlayedSound[player]

        lastPlayedSound[player] = randomSoundPath

        local sound = CreateSound(player, randomSoundPath)

        local success, errorMsg = pcall(function()
            sound:Play()
        end)

        if not success then
            print("Erreur lors de la lecture du son :", errorMsg)
        else
            local soundDuration = SoundDuration(randomSoundPath)
            local funnyPhrase = soundPhrases[randomSoundPath] or "Taunt mystérieux joué!"

			local chatMessage = "[PROPHUNT] " .. player:Name() .. " a dit : " .. funnyPhrase
			player:ChatPrint(chatMessage)


            timer.Simple(5, function() -- Arrête le son après 5 secondes
                if IsValid(sound) then
                    sound:Stop()
                end
            end)
        end
    end
end

-- Lorsqu'un joueur appuie sur F3, jouer un taunt aléatoire
hook.Add("PlayerButtonDown", "PlayRandomTauntOnF3", function(player, button)
	if player:Team() == TEAM_PROPS then
		if button == KEY_F3 then
			PlayRandomTaunt(player)
		end
    end
end)

-- Démarre le premier taunt aléatoire après un délai initial entre 10 et 60 secondes
timer.Simple(math.random(20, 60), function()
    for _, ply in pairs(player.GetAll()) do
        if ply:Team() == TEAM_PROPS then
            PlayRandomTaunt(ply)
        end
    end
end)