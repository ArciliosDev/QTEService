local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QTEService = require(ReplicatedStorage.Shared.QTEService)

Players.PlayerAdded:Connect(function()
	local totalPlayers = #Players:GetPlayers()
	if totalPlayers >= 2 then
		warn("Starting QTE 2 players are in game")
		task.wait(6)

		local test = QTEService.new({
			PlayerOne = Players:GetPlayers()[1],
			PlayerTwo = Players:GetPlayers()[2],
			Type = "Reflex",
			Duration = 10,
		})

		test:Start()
		local winner = test:Await()
		warn("QTE finished with winner: ", winner)
	end
end)
