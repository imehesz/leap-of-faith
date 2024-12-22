local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get fresh references each time we need them
local function getReplayGui()
    local player = Players.LocalPlayer
    return player:WaitForChild("PlayerGui"):WaitForChild("ReplayOrNext")
end

local function getWelcomeGui()
    local player = Players.LocalPlayer
    return player:WaitForChild("PlayerGui"):WaitForChild("Welcome")
end

-- Button handlers
local function setupButtons()
    local replayGui = getReplayGui()
    local replayButton = replayGui:WaitForChild("ReplayButton")
    local nextButton = replayGui:WaitForChild("NextButton")

    replayButton.MouseButton1Click:Connect(function()
        replayGui.Enabled = false
        ReplicatedStorage.Remotes.ReplayLevelEvent:FireServer()
    end)

    nextButton.MouseButton1Click:Connect(function()
        replayGui.Enabled = false
        ReplicatedStorage.Remotes.NextLevelEvent:FireServer()
    end)
end

ReplicatedStorage.Remotes.LevelCompleteEvent.OnClientEvent:Connect(function(shouldShow)
    local replayGui = getReplayGui()
    replayGui.Enabled = shouldShow
    if shouldShow then
        setupButtons()
    end
end)

setupButtons()

local welcomeGui = getWelcomeGui()
local startButton = welcomeGui:WaitForChild("StartGameButton")

startButton.MouseButton1Click:Connect(function()
    ReplicatedStorage.Remotes.StartGameEvent:FireServer()
end)