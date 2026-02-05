local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QTEClient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QTEService"):WaitForChild("QTEClient"))
QTEClient.init()
