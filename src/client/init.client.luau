
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local replayGui = player:WaitForChild("PlayerGui"):WaitForChild("ReplayOrNext")
local replayButton = replayGui:WaitForChild("ReplayButton")
local nextButton = replayGui:WaitForChild("NextButton")

replayGui.Enabled = false

replayButton.MouseButton1Click:Connect(function()
    -- Call server to replay level
    replayGui.Enabled = false
end)

nextButton.MouseButton1Click:Connect(function()
    -- Call server to go to next level
    replayGui.Enabled = false
end)
print("Hello world, from client! mooo")