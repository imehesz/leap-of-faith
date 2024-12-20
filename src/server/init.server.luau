local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local currentLevel = 1
local maxLevels = #workspace.Levels:GetChildren()
local debounce = false
local isReplaying = false

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

  local function spawnAtCurrentLevel(player)
      local character = player.Character or player.CharacterAdded:Wait()
      local levelFolder = workspace.Levels:FindFirstChild("Level" .. currentLevel)
      if levelFolder and levelFolder:FindFirstChild("StartPart") then
          task.wait(0.1) -- Give character physics time to settle
          character:PivotTo(levelFolder.StartPart.CFrame + Vector3.new(0, 3, 0))
          levelStartTime = os.time()
          currentTime = 0
          hideStepsInLevel(currentLevel)
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
    currentLevel += 1
    if currentLevel > maxLevels then
        currentLevel = 1
    end
    spawnAtCurrentLevel(player)
end)

-- Connect events
Players.PlayerAdded:Connect(function(player)
    -- Set initial GUI state to disabled
    local replayGui = player:WaitForChild("PlayerGui"):WaitForChild("ReplayOrNext")
    replayGui.Enabled = false
    
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
    part.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            part.Transparency = 0
        end
    end)
end

-- Start the time update loop

task.spawn(updateCurrentTime)