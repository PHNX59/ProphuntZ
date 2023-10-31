local discord = require('discordia')
local client = discord.Client()

client:on('ready', function()
    print('Bot connecté en tant que ' .. client.user.username)
end)

client:on('messageCreate', function(message)
    local content = message.content:lower()
    local author = message.author

    if content == '!bug' then
        local playerName = author.username
        local response = "Joueur " .. playerName .. " signale un bug."
        message:reply(response)
    end
end)

client:run('MTE2NDIxMzA2NzU5MzMwMjA0OA.G6rLk6.-D5I591cp9AnmZubOIlVaYhFx6PSdAnsLCq00U')
