local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local currentLevel = 1
local maxLevels = #workspace.Levels:GetChildren()
local debounce = false
local isReplaying = false
local nextLevelDebounce = false
local gameStarted = {}
local playerStates = {}

-- Scoring and timing variables
local score = 0
local currentTime = 0
local levelStartTime = 0
local recordTimes = {}


local function initializePlayerState(player)
    playerStates[player.UserId] = {
        currentLevel = 1,
        score = 0,
        recordTimes = {},
        levelStartTime = 0,
        currentTime = 0,
        debounce = false,
        isReplaying = false,
        nextLevelDebounce = false
    }
end

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

    local playerState = playerStates[player.UserId]
    if not playerState then return end

    local character = player.Character or player.CharacterAdded:Wait()
    local levelFolder = workspace.Levels:FindFirstChild("Level" .. playerState.currentLevel)
    if levelFolder and levelFolder:FindFirstChild("StartPart") then
        task.wait(0.1)
        character:PivotTo(levelFolder.StartPart.CFrame + Vector3.new(0, 3, 0))
        playerState.levelStartTime = os.time()
        playerState.currentTime = 0
        hideStepsInLevel(playerState.currentLevel)
        hideBlockersInLevel(playerState.currentLevel)
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
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    local playerState = player and playerStates[player.UserId]

    if playerState and not playerState.debounce and not playerState.isReplaying then
        playerState.debounce = true

        playerState.score += playerState.currentLevel * 10
        if not playerState.recordTimes[playerState.currentLevel] or playerState.currentTime < playerState.recordTimes[playerState.currentLevel] then
            playerState.recordTimes[playerState.currentLevel] = playerState.currentTime
        end

        local levelFolder = workspace.Levels:FindFirstChild("Level" .. playerState.currentLevel)
        for _, part in CollectionService:GetTagged("blocker") do
            if part:IsDescendantOf(levelFolder) then
                part.CanCollide = true
            end
        end

        ReplicatedStorage.Remotes.LevelCompleteEvent:FireClient(player, true)
        task.wait(1)
        playerState.debounce = false
    end
end

ReplicatedStorage.Remotes.ReplayLevelEvent.OnServerEvent:Connect(function(player)
    local playerState = playerStates[player.UserId]
    if not playerState then return end

    playerState.isReplaying = true
    playerState.debounce = true
    spawnAtCurrentLevel(player)
    task.wait(0.5)
    playerState.isReplaying = false
    playerState.debounce = false
end)

ReplicatedStorage.Remotes.NextLevelEvent.OnServerEvent:Connect(function(player)
    local playerState = playerStates[player.UserId]
    if not playerState or playerState.nextLevelDebounce then return end

    playerState.nextLevelDebounce = true

    playerState.currentLevel += 1
    if playerState.currentLevel > maxLevels then
        playerState.currentLevel = 1
    end
    spawnAtCurrentLevel(player)

    task.wait(0.5)
    playerState.nextLevelDebounce = false
end)

-- Connect events
Players.PlayerAdded:Connect(function(player)
    initializePlayerState(player)

    local replayGui = player:WaitForChild("PlayerGui"):WaitForChild("ReplayOrNext")
    replayGui.Enabled = false

    local welcomeGui = player:WaitForChild("PlayerGui"):WaitForChild("Welcome")
    welcomeGui.Enabled = true

    player.CharacterAdded:Connect(function()
        task.wait()
        spawnAtCurrentLevel(player)
    end)

    task.spawn(function()
        updateCurrentTime(player)
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
    playerStates[player.UserId] = nil
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