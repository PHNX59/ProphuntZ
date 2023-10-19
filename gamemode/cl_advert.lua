net.Receive("SendRandomMessage", function()
    local prefix = net.ReadString()
    local message = net.ReadString()

    local prefixColor = Color(255, 0, 0) -- Rouge
    local messageColor = Color(0, 0, 0) -- Vert

    chat.AddText(prefixColor, prefix, messageColor, message)
end)
