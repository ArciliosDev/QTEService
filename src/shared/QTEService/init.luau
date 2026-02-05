local Players = game:GetService("Players")

local QTEServer = require(script.QTEServer)
QTEServer.init()

local function injectClient(player: Player): ()
	local clientBootStrapper = script.ClientBootstrapper:Clone()
	clientBootStrapper.Enabled = false

	clientBootStrapper.Parent = player:WaitForChild("PlayerGui")
	clientBootStrapper.Enabled = true
end

Players.PlayerAdded:Connect(injectClient)

return QTEServer
