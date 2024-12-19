local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local currentLevel = 1
local maxLevels = #workspace.Levels:GetChildren()
local debounce = false

local function hideStepsInLevel(levelNumber)
    local levelFolder = workspace.Levels:FindFirstChild("Level" .. levelNumber)
    if levelFolder then
        for _, part in CollectionService:GetTagged("goodStep") do
            if part:IsDescendantOf(levelFolder) then
                part.Transparency = 1
            end
        end
    end
end

local function spawnAtCurrentLevel(player)
    print("Spawning player at current level" .. currentLevel)
    local levelFolder = workspace.Levels:FindFirstChild("Level" .. currentLevel)
    if levelFolder and levelFolder:FindFirstChild("StartPart") then
        local character = player.Character
        if character then
            character:PivotTo(levelFolder.StartPart.CFrame + Vector3.new(0, 3, 0))
        end
    end
    hideStepsInLevel(currentLevel)
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait() -- Small wait to ensure character is fully loaded
        spawnAtCurrentLevel(player)
    end)
end

local function handleLevelComplete(hit)
    if debounce then return end
    
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    
    if player and hit.Parent:FindFirstChild("Humanoid") then
        debounce = true
        
        print("Level completed!" .. currentLevel)
        currentLevel += 1
        
        if currentLevel > maxLevels then
            currentLevel = 1
            print("Completed all levels! Starting over from Level 1")
        else
            print("Moving to next level..." .. currentLevel)
        end

        spawnAtCurrentLevel(player)
        task.wait(1) -- Prevent any new triggers for 1 second
        debounce = false
    end
end

-- Handle death and respawning
local function onDeathTouch(hit)
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    
    if player and character.Humanoid then
        character.Humanoid.Health = 0
        local newCharacter = player.CharacterAdded:Wait()
        spawnAtCurrentLevel(player)
    end
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
    spawnAtCurrentLevel(player)
end

for _, part in CollectionService:GetTagged("death") do
    part.Touched:Connect(onDeathTouch)
end

for _, part in CollectionService:GetTagged("levelDone") do
    part.Touched:Connect(handleLevelComplete)
end

for _, part in CollectionService:GetTagged("goodStep") do
    part.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            part.Transparency = 0
        end
    end)
end