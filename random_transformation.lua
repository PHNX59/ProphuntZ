local modelsWithAliases = {
    { model = "models/foodnhouseholditems/cabbage2.mdl", alias = "Chou" },
    { model = "models/foodnhouseholditems/cabbage1.mdl", alias = "Chou vert" },
    { model = "models/props_junk/garbage_plasticbottle003a.mdl", alias = "Bouteille en plastique" },
    { model = "models/props_idbs/go/toaster.mdl", alias = "Grille-pain" },
    { model = "models/props_interiors/pot01a.mdl", alias = "Casserole" },
    { model = "models/props_c17/chair_stool01a.mdl", alias = "Tabouret de chaise" },
    { model = "models/props_idbs/go/trashcan01.mdl", alias = "Poubelle" },
    { model = "models/props_junk/propanecanister001a.mdl", alias = "Bouteille de propane" },
    { model = "models/props_gmod_org/makka12/burgers/burger_box.mdl", alias = "Boîte de burger" },
    { model = "models/props/cs_italy/orange.mdl", alias = "Orange" },
    { model = "models/props_gmod_org/makka12/burgers/burger.mdl", alias = "Burger" },
    { model = "models/props_cs_italy/bananna_bunch.mdl", alias = "Bunch de bananes" },
    { model = "models/props_idbs/go/dish_soap.mdl", alias = "Liquide vaisselle" },
    { model = "models/props_interiors/pot01a.mdl", alias = "Casserole" },
    { model = "models/props_c17/chair02a.mdl", alias = "Chaise" },
    { model = "models/foodnhouseholditems/toiletpaper2.mdl", alias = "Papier toilette" },
    { model = "models/sims/gm_stove.mdl", alias = "Cuisinière" },
    { model = "models/props_cs_office/water_bottle.mdl", alias = "Bouteille d'eau" },
    { model = "models/props_junk/garbage_glassbottle003a.mdl", alias = "Bouteille en verre" },
    { model = "models/props_interiors/pot02a.mdl", alias = "Autre casserole" },
    { model = "models/props_idbs/foods/sosis.mdl", alias = "Saucisse" },
    { model = "models/foodnhouseholditems/fishbass.mdl", alias = "Poisson" },
    { model = "models/props_gmod_org/bubba/bubba_spam_comicsize/bubba_spam.mdl", alias = "Boîte de Spam" },
    { model = "models/foodnhouseholditems/bacon_2.mdl", alias = "Bacon" },
    { model = "models/foodnhouseholditems/champagneonplate.mdl", alias = "Champagne sur une assiette" },
    { model = "models/foodnhouseholditems/champagne.mdl", alias = "Champagne" },
    { model = "models/props_interiors/furniture_chair01a.mdl", alias = "Chaise" },
    { model = "models/props_idbs/go/water_cooler.mdl", alias = "Distributeur d'eau" },
    { model = "models/props/cs_office/plant01.mdl", alias = "Plante de bureau" },
    { model = "models/props/de_inferno/potted_plant2.mdl", alias = "Plante en pot" },
    { model = "models/props_idbs/go/styrofoam_cups.mdl", alias = "Tasses en polystyrène" },
    { model = "models/props/cs_office/computer.mdl", alias = "Ordinateur de bureau" },
    { model = "models/props/cs_office/computer_caseb.mdl", alias = "Boîtier d'ordinateur" },
    { model = "models/props_idbs/go/cash_register.mdl", alias = "Caisse enregistreuse" },
    { model = "models/props_gmod_org/makka/soda.mdl", alias = "Soda" },
    { model = "models/props_idbs/go_fol/plantairport01.mdl", alias = "Plante d'aéroport" },
    { model = "models/props/de_tides/patio_chair.mdl", alias = "Chaise de patio" },
    { model = "models/props_junk/trashbin01a.mdl", alias = "Poubelle" },
    { model = "models/props/cs_office/offpaintingd.mdl", alias = "Tableau" },
    { model = "models/props_downtown/booth_table.mdl", alias = "Table de kiosque" },
    { model = "models/foodnhouseholditems/pizzabox.mdl", alias = "Boîte de pizza" },
    { model = "models/props_gmod_org/neodement/bigsandwich.mdl", alias = "Gros sandwich" },
    { model = "models/props/cs_office/cardboard_box01.mdl", alias = "Boîte en carton" },
    { model = "models/props_idbs/go/styrofoam_cups_p1.mdl", alias = "Tasses en polystyrène" },
    { model = "models/props/cs_office/microwave.mdl", alias = "Micro-ondes" },
    { model = "models/props_c17/canister02a.mdl", alias = "Bidon métallique" },
    { model = "models/props_c17/canister01a.mdl", alias = "Bidon en plastique" },
    { model = "models/props_junk/plasticcrate01a.mdl", alias = "Caisse en plastique" },
    { model = "models/props/cs_office/trash_can.mdl", alias = "Poubelle de bureau" },
    { model = "models/props/cs_militia/caseofbeer01.mdl", alias = "Caisse de bière" },
    { model = "models/props_junk/popcan01a.mdl", alias = "Canette de soda" },
    { model = "models/props_junk/gascan001a.mdl", alias = "Bidon d'essence" },
    { model = "models/props_gmod_org/neodement/cerealbowl.mdl", alias = "Bol de céréales" },
    { model = "models/foodnhouseholditems/digestive.mdl", alias = "Biscuits digestifs" },
    { model = "models/foodnhouseholditems/chipstwisties.mdl", alias = "Chips Twisties" },
    { model = "models/props_junk/metalbucket01a.mdl", alias = "Seau en métal" },
    { model = "models/props/de_inferno/claypot03.mdl", alias = "Pot en argile" },
}

local function getRandomModel()
    local randomIndex = math.random(1, #modelsWithAliases)
    return modelsWithAliases[randomIndex].model
end

local function onKeyPress(ply, key)
    if ply:Team() == TEAM_PROPS and key == IN_FORWARD then
        local randomModel = getRandomModel()
        if util.IsValidModel(randomModel) then
            ply:SetModel(randomModel)
            ply:EmitSound("npc/turret_floor/active.wav")
        else
            print("Modèle invalide ou inexistant.")
        end
    end
end

hook.Add("KeyPress", "ChangeModelOnKeyPress", onKeyPress)