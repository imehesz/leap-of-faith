
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local replayGui = player:WaitForChild("PlayerGui"):WaitForChild("ReplayOrNext")
local replayButton = replayGui:WaitForChild("ReplayButton")
local nextButton = replayGui:WaitForChild("NextButton")

local WelcomeLabelEl = playerGui:WaitForChild("Welcome"):WaitForChild("TextLabel")

replayGui.Enabled = false

replayButton.MouseButton1Click:Connect(function()
    -- Call server to replay level
    replayGui.Enabled = false
end)

nextButton.MouseButton1Click:Connect(function()
    -- Call server to go to next level
    replayGui.Enabled = false
end)

-- Welcome Label update
local textArray = {
    "A LEAP OF FAITH is when someone does something even though they are afraid or uncertain of the outcome. It can be a difficult decision, but it can also be very rewarding. (ChatGPT)",
    "As you start to walk on the way, the way appears. (Rumi)",
    "The key to growth is acknowledging your fear of the unknown and jumping in anyway. (Jen Sincero)",
    "Man can learn nothing except by going from the known to the unknown. (Claude Bernard)",
    "I am afraid. Not of life, or death, or nothingness, but of wasting it as if I had never been. (Daniel Keyes)",
}

local updateInterval = 10

local function updateText()
    for i = 1, #textArray do
        WelcomeLabelEl.Text = textArray[i]
        wait(updateInterval)
    end
end

-- Run the updateText function in a loop
while true do
    updateText()
end