local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local currentLevel = 1
local maxLevels = #workspace.Levels:GetChildren()
local debounce = false
local isReplaying = false
local nextLevelDebounce = false
local gameStarted = {}

-- Scoring and timing variables
local score = 0
local currentTime = 0
local levelStartTime = 0
local recordTimes = {}

local function updateCurrentTime()
    while true do
        currentTime = math.floor((os.time() - levelStartTime) * 100) / 100
        task.wait(0.1)
    end
end

local function hideStepsInLevel(levelNumber)
    local levelFolder = workspace.Levels:FindFirstChild("Level" .. currentLevel)
    if levelFolder then
        for _, part in CollectionService:GetTagged("goodStep") do
            if part:IsDescendantOf(levelFolder) then
                part.Transparency = 1
            end
        end
    end
end

local function hideBlockersInLevel(levelNumber)
    local levelFolder = workspace.Levels:FindFirstChild("Level" .. currentLevel)
    for _, part in CollectionService:GetTagged("blocker") do
        if part:IsDescendantOf(currentLevelFolder) then
            part.Transparency = 1
            part.CanCollide = false
        end
    end
end

local function spawnAtCurrentLevel(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local levelFolder = workspace.Levels:FindFirstChild("Level" .. currentLevel)
    if levelFolder and levelFolder:FindFirstChild("StartPart") then
        task.wait(0.1) -- Give character physics time to settle
        character:PivotTo(levelFolder.StartPart.CFrame + Vector3.new(0, 3, 0))
        levelStartTime = os.time()
        currentTime = 0
        hideStepsInLevel(currentLevel)
        hideBlockersInLevel(currentLevel)
    end
end

  local function onDeathTouch(hit)
      local character = hit.Parent
      local player = Players:GetPlayerFromCharacter(character)
    
      if player and character:FindFirstChild("Humanoid") then
          character.Humanoid.Health = 0
          local newCharacter = player.CharacterAdded:Wait()
          spawnAtCurrentLevel(player)
      end
  end

    local function handleLevelComplete(hit)
        if debounce or isReplaying then return end
    
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
    
        if player and hit.Parent:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            debounce = true
        
            score += currentLevel * 10
            if not recordTimes[currentLevel] or currentTime < recordTimes[currentLevel] then
                recordTimes[currentLevel] = currentTime
            end

            
            local levelFolder = workspace.Levels:FindFirstChild("Level" .. currentLevel)
            for _, part in CollectionService:GetTagged("blocker") do
                if part:IsDescendantOf(currentLevelFolder) then
                    part.CanCollide = true
                end
            end
        
            ReplicatedStorage.Remotes.LevelCompleteEvent:FireClient(player, true)
            task.wait(1)
            debounce = false
        end
    end

ReplicatedStorage.Remotes.ReplayLevelEvent.OnServerEvent:Connect(function(player)
    isReplaying = true
    debounce = true
    spawnAtCurrentLevel(player)
    task.wait(0.5)
    isReplaying = false
    debounce = false
end)

ReplicatedStorage.Remotes.NextLevelEvent.OnServerEvent:Connect(function(player)
    if nextLevelDebounce then return end
    
    nextLevelDebounce = true

    currentLevel += 1
    if currentLevel > maxLevels then
        currentLevel = 1
    end
    spawnAtCurrentLevel(player)
    
    -- Reset debounce after a short delay
    task.wait(0.5)
    nextLevelDebounce = false
end)

-- Connect events
Players.PlayerAdded:Connect(function(player)
    -- Set initial GUI states
    local replayGui = player:WaitForChild("PlayerGui"):WaitForChild("ReplayOrNext")
    replayGui.Enabled = false
    
    local welcomeGui = player:WaitForChild("PlayerGui"):WaitForChild("Welcome")
    welcomeGui.Enabled = true
    
    -- Track game state for each player
    gameStarted[player.UserId] = false
    
    player.CharacterAdded:Connect(function()
        task.wait()
        if gameStarted[player.UserId] then
            spawnAtCurrentLevel(player)
        end
    end)
end)

-- Add new remote event handler
ReplicatedStorage.Remotes.StartGameEvent.OnServerEvent:Connect(function(player)
    gameStarted[player.UserId] = true
    local welcomeGui = player:WaitForChild("PlayerGui"):WaitForChild("Welcome")
    welcomeGui.Enabled = false
    spawnAtCurrentLevel(player)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    gameStarted[player.UserId] = nil
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
    local lastTouchTime = 0
    
    part.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            part.Transparency = 0
            lastTouchTime = os.time()
            
            -- Create a new thread to handle the fade-out
            task.spawn(function()
                task.wait(5)
                -- Only hide if 5 seconds passed since last touch
                if os.time() - lastTouchTime >= 5 then
                    part.Transparency = 1
                end
            end)
        end
    end)
end

task.spawn(updateCurrentTime)