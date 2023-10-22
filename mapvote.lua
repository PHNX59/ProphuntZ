local function GetMapList()
    local mapFiles = file.Find("maps/*.bsp", "GAME")
    local maps = {}

    for _, mapFile in pairs(mapFiles) do
        local mapName = string.gsub(mapFile, "%.bsp$", "")
        table.insert(maps, mapName)
    end

    return maps
end

local maps = GetMapList()

local function InitMapVote()
    local mapVotes = {}
    local playerVotes = {} 

    for _, ply in pairs(player.GetAll()) do
        ply:ChatPrint("Votez pour la prochaine carte en tapant !vote <numéro de carte>")
        for i, map in ipairs(maps) do
            ply:ChatPrint(i .. ". " .. map)
        end
    end

    timer.Simple(30, function()
        for _, ply in pairs(player.GetAll()) do
            local vote = ply:GetNWInt("MapVote", 0)
            if vote > 0 and vote <= #maps then
                mapVotes[vote] = (mapVotes[vote] or 0) + 1
                playerVotes[ply:Nick()] = maps[vote]
            end
        end

        for _, ply in pairs(player.GetAll()) do
            ply:ChatPrint("Résultats du vote de carte :")
            for playerName, mapChoice in pairs(playerVotes) do
                ply:ChatPrint("[Prophunt Z] " .. playerName .. " a voté pour " .. mapChoice)
            end
        end

        local winningMap = 1
        local maxVotes = 0
        for k, v in pairs(mapVotes) do
            if v > maxVotes then
                winningMap = k
                maxVotes = v
            end
        end

        if maps[winningMap] then
            game.ConsoleCommand("changelevel " .. maps[winningMap] .. "\n")
        end
    end)
end

local function MapVote(ply, cmd, args)
    if not args[1] then
        ply:ChatPrint("[Prophunt Z] Utilisez !vote <numéro de carte> pour voter.")
        return
    end

    local vote = tonumber(args[1])
    if vote and vote > 0 and vote <= #maps then
        ply:SetNWInt("MapVote", vote)
        ply:ChatPrint("Vous avez voté pour " .. maps[vote] .. ".")
    else
        ply:ChatPrint("[Prophunt Z] Vote invalide. Utilisez !vote <numéro de carte>.")
    end
end

concommand.Add("vote", MapVote)

local function StartMapVoteTimer()
    timer.Create("MapVoteTimer", 900, 0, InitMapVote) -- 900 secondes (15 minutes)
end

-- StartMapVoteTimer()
