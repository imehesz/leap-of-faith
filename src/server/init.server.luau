local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local currentLevel = 1
local maxLevels = #workspace.Levels:GetChildren()
local debounce = false

-- New variables for scoring and timing
local score = 0
local currentTime = 0
local levelStartTime = 0
local recordTimes = {}  -- Store best times for each level

local function updateCurrentTime()
    while true do
        currentTime = math.floor((os.time() - levelStartTime) * 100) / 100
        task.wait(0.1)  -- Update every 0.1 seconds for smooth display
    end
end

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
    local character = player.Character or player.CharacterAdded:Wait()
    local levelFolder = workspace.Levels:FindFirstChild("Level" .. currentLevel)
    if levelFolder and levelFolder:FindFirstChild("StartPart") then
        character:PivotTo(levelFolder.StartPart.CFrame + Vector3.new(0, 3, 0))
    end
    levelStartTime = os.time()
    currentTime = 0
    hideStepsInLevel(currentLevel)
end

local function showRecordTimes()
    for i = 1, maxLevels do
        print("Level " .. i .. " record: " .. (recordTimes[i] or "N/A"))
    end
end

local function handleLevelComplete(hit)
    if debounce then return end
    
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    
    if player and hit.Parent:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
        debounce = true
        
        -- Update score and record time
        score += currentLevel * 10
        
        -- Update record time if current time is better
        if not recordTimes[currentLevel] or currentTime < recordTimes[currentLevel] then
            recordTimes[currentLevel] = currentTime
        end
        
        showRecordTimes()
        
        currentLevel += 1
        if currentLevel > maxLevels then
            currentLevel = 1
        end
        
        spawnAtCurrentLevel(player)
        task.wait(1)
        debounce = false
    end
end

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
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait()
        spawnAtCurrentLevel(player)
    end)
end)

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
    part.Transparency = 1
    part.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            part.Transparency = 0
        end
    end)
end

-- Start the time update loop
task.spawn(updateCurrentTime)