local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local QTE = {}
QTE.__index = QTE

local random = Random.new()
local localPlayer = Players.LocalPlayer
local activeTroves = {}

local possibleReflexOptions = {
	PC = {
		Enum.KeyCode.A,
		Enum.KeyCode.H,
		Enum.KeyCode.K,
		Enum.KeyCode.Z,
		Enum.KeyCode.X,
		Enum.KeyCode.C,
		Enum.KeyCode.V,
	},
	Console = {
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonB,
		Enum.KeyCode.ButtonX,
		Enum.KeyCode.ButtonY,
		Enum.KeyCode.ButtonR1,
		Enum.KeyCode.ButtonR2,
		Enum.KeyCode.ButtonL1,
		Enum.KeyCode.ButtonL2,
	},
}

type QTEObject = {
	Duration: number,
	EventId: string,
	Type: string,
	Button: Enum.KeyCode?,
	Trove: any,
	Remote: RemoteEvent,
	Platform: "PC" | "Console" | "Mobile",
	RenderTiming: (QTEObject) -> (),
	RenderReflex: (QTEObject) -> (),
}

local function vibrate(btnObject: Frame) end

local function createQTEButton(platform: "PC" | "Console" | "Mobile", button: Enum.KeyCode?)
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	local qteGui = playerGui:FindFirstChild("QTEGui")
	if not qteGui then
		return
	end -->> This should never really happen but just incase ill keep it

	local buttonObj = Instance.new("Frame")
	buttonObj.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	buttonObj.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonObj.Size = UDim2.fromScale(0.05, 0.1)
	buttonObj.Position = UDim2.fromScale(random:NextNumber(0.1, 0.9), random:NextNumber(0.1, 0.9))

	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.Parent = buttonObj

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = buttonObj

	local outLine = Instance.new("UIStroke")
	outLine.Thickness = 3
	outLine.Color = Color3.fromRGB(0, 255, 255)
	outLine.Parent = buttonObj

	local buttonText = Instance.new("TextLabel")
	buttonText.BackgroundTransparency = 1
	buttonText.TextScaled = true
	buttonText.Size = UDim2.fromScale(0.8, 0.8)
	buttonText.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonText.Position = UDim2.fromScale(0.5, 0.5)
	buttonText.TextColor3 = Color3.fromRGB(0, 255, 255)

	local text
	if platform == "PC" and button then
		text = button.Name
	elseif platform == "Console" and button then
		text = button.Name:gsub("Button", "")
	else
		text = "Touch"
	end

	buttonText.Text = text
	buttonText.Parent = buttonObj
	buttonObj.Parent = qteGui

	return buttonObj
end

function QTE.init()
	local QTERemote = script.Parent.Parent:WaitForChild("QTERemote")

	QTERemote.OnClientEvent:Connect(
		function(Type: string, Duration: number, EventId: string, buttonToPress: Enum.KeyCode?)
			if Type == "End" then
				warn("Fired with type: ", Type, " active troves: ", activeTroves)
				if activeTroves[EventId] then
					activeTroves[EventId]:Destroy()
				end
				return
			end

			local newQTE = QTE.new(Type, Duration, EventId, buttonToPress)
			newQTE:Render()
		end
	)

	warn("QTEService Client intialized successfully")
end

function QTE.new(eventType: string, duration: number, eventId: string, buttonToPress: Enum.KeyCode?): QTEObject
	local self = setmetatable({}, QTE)

	self.Duration = duration
	self.Type = eventType
	self.EventId = eventId
	self.Button = buttonToPress
	self.Trove = Trove.new()

	activeTroves[eventId] = self.Trove
	self.Trove:Add(function()
		activeTroves[eventId] = nil
	end)

	self.Platform = if UserInputService.TouchEnabled
		then "Mobile"
		elseif UserInputService.GamepadEnabled then "Console"
		else "PC"

	self.Remote = script.Parent.Parent:WaitForChild("QTERemote")

	task.delay(duration, function()
		self.Trove:Destroy()
	end)
	return self
end

function QTE.RenderReflex(self: QTEObject)
	local buttonSelected = self.Button
	if self.Platform ~= "Mobile" and not buttonSelected then
		local len = #possibleReflexOptions[self.Platform]
		buttonSelected = possibleReflexOptions[self.Platform][math.random(1, len)]
	end

	local buttonObject = createQTEButton(self.Platform, buttonSelected)
	self.Trove:Add(buttonObject)

	if self.Platform == "Mobile" then
		self.Trove:Add(buttonObject.Touch:Connect(function()
			self.Remote:FireServer(self.EventId)
			self.Trove:Destroy()
		end))
	else
		self.Trove:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
			if gpe then
				return
			end

			if input.KeyCode == buttonSelected then
				self.Remote:FireServer(self.EventId)
				self.Trove:Destroy()
			end
		end))
	end
end

function QTE:RenderTiming() end

function QTE.Render(self: QTEObject)
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	local QTEGui = playerGui:FindFirstChild("QTEGui")
	if not QTEGui then
		QTEGui = Instance.new("ScreenGui")
		QTEGui.IgnoreGuiInset = true
		QTEGui.Name = "QTEGui"

		QTEGui.Parent = playerGui
	end

	if self.Type == "Timing" then
		self:RenderTiming()
	elseif self.Type == "Reflex" then
		self:RenderReflex()
	end
end

return QTE
