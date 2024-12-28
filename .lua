getgenv().saverarity = { "Godly", "Exclusive", "Ultimate" }

repeat task.wait() until game:IsLoaded() and game.ReplicatedStorage and game.ReplicatedStorage:FindFirstChild("MultiboxFramework")
repeat task.wait() until require(game:GetService("ReplicatedStorage").MultiboxFramework).Loaded

local save = require(game:GetService("ReplicatedStorage"):WaitForChild("MultiboxFramework"))
local inventory = save.Inventory
local plr = game.Players.LocalPlayer

local function addCommas(value)
    local formatted = tostring(value)
    repeat
        formatted, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    until count == 0
    return formatted
end

local allItems = save.Inventory.GetAllCopies({ "Troops", "Crates" })

-- Function to handle item removal logic
spawn(function()
    while true do
        local itemsToRemove = {}
        for _, item in ipairs(allItems) do
            if item[1] ~= "Crates" then
                local itemConfig = inventory.GetItemConfig(item[1], item[2])
                if not table.find(getgenv().saverarity, itemConfig.Rarity) and itemConfig.DisplayName ~= "Speakerman" and not table.find(itemsToRemove, item[3]) then
                    table.insert(itemsToRemove, item[3])
                end
            end
        end

        if #itemsToRemove > 0 then
            local args = {
                [1] = {
                    [1] = {
                        [1] = tostring(game:GetService("ReplicatedStorage").IdentifiersContainer
                            .RE_a0e455bacc8e733fc688948302e8c887df8cb99f43a78b2d20c57fe549aec5fc.Value),
                        [2] = itemsToRemove
                    }
                }
            }

            game:GetService("ReplicatedStorage"):WaitForChild("NetworkingContainer"):WaitForChild("DataRemote")
                :FireServer(unpack(args))

            task.wait(1) -- Slight delay to prevent too many requests at once
        end
        itemsToRemove = {}
        task.wait(2) -- Short delay to prevent constant looping
    end
end)

-- Function to determine amount of items to be used
function getam(name)
    local unit = {}

    for i, v in pairs(allItems) do
        local v60 = inventory.GetItemConfig(v[1], v[2])

        if not unit[v60.DisplayName] then
            unit[v60.DisplayName] = { Amount = 1 }
        else
            unit[v60.DisplayName].Amount = unit[v60.DisplayName].Amount + 1
        end
    end
    if unit[name].Amount >= 8 then
        return 8
    elseif unit[name].Amount < 8 and unit[name].Amount >= 5 then
        return 5
    else
        return 1
    end
end

local plr = game.Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local oldCFrame = humanoidRootPart.CFrame

-- Separate the movement task to ensure it doesn't block crate opening
spawn(function()
    while true do
        local randomOffset = Vector3.new(
            math.random(-50, 50),
            0,
            math.random(-50, 50)
        )

        local newPosition = oldCFrame.Position + randomOffset
        humanoid:MoveTo(newPosition)

        humanoid.MoveToFinished:Wait()
        task.wait(0.5) -- Small wait to avoid overloading
    end
end)

-- Main loop for crate opening (optimized with control to avoid lag)
spawn(function()
    while true do
        local crateOpened = false
        -- Loop through all items to find crates and open them
        for _, v in pairs(allItems) do
            if v[1] == "Crates" then
                local v60 = inventory.GetItemConfig(v[1], v[2])

                local args = {
                    [1] = {
                        [1] = {
                            [1] = game.ReplicatedStorage.IdentifiersContainer
                                .RE_36c24ca0c15be2f6dafac27b984ad32fb18425eda49e23c153df96804dbbbfb9.Value,
                            [2] = v[3],
                            [3] = getam(v60.DisplayName)
                        }
                    }
                }

                -- Open crate
                game:GetService("ReplicatedStorage"):WaitForChild("NetworkingContainer"):WaitForChild("DataRemote")
                    :FireServer(unpack(args))
                
                crateOpened = true
                break -- Exit after opening one crate (for optimization)
            end
        end

        -- If a crate was opened, wait for 2 seconds, otherwise wait for the next frame
        if crateOpened then
            task.wait(2) -- Allow 2 seconds between crate openings
        else
            task.wait(0.1) -- No crates found, loop quickly to prevent lag
        end
    end
end)
