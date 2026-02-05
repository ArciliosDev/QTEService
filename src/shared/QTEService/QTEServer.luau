local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local QTE = {}
QTE.__index = QTE

type QTEObject = {
	Player1: Player,
	Player2: Player?,
	Type: string,
	Duration: number,
	EventId: string,
	Remote: RemoteEvent,
	finishedEvent: BindableEvent,
	ForcedButton: Enum.KeyCode,

	Start: (QTEObject) -> (),
	Resolve: (QTEObject) -> (),
	CleanUp: (QTEObject) -> (),
	_ResolveReflex: (QTEObject) -> Player | nil,
	_ResolveTiming: (QTEObject) -> (),
}

type PlayerEntry = {
	id: string,
	duration: number,
	result: number?,
}

type EventsTable = {
	[string]: {
		eventObject: QTEObject,
		startTime: number,
		finished: boolean,

		[Player]: PlayerEntry,
	},
}

type EventSettings = {
	PlayerOne: Player,
	PlayerTwo: Player?,
	Type: "Reflex" | "Timing",
	Duration: number,
	ForcedButton: Enum.KeyCode?,
}

local activeEvents: EventsTable = {}

function QTE.init()
	local QTERemote = Instance.new("RemoteEvent") :: RemoteEvent
	QTERemote.Name = "QTERemote"
	QTERemote.Parent = script.Parent.Parent

	QTERemote.OnServerEvent:Connect(function(player: Player, eventId: string)
		local event = activeEvents[eventId]
		if not event or event.finished then
			return
		end

		local entry = event[player]
		if not entry or entry.result then
			return
		end

		entry.result = os.clock() - event.startTime
		if entry.result <= 0.1 then
			return -- > fake results
		end

		event.eventObject:Resolve()
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		for _, activeEvent in pairs(activeEvents) do
			if activeEvent[player] then
				activeEvent[player] = nil
			end
		end
	end)

	warn("QTEService SERVER intialized successfully")
end

function QTE.new(settings: EventSettings): QTEObject
	local self = setmetatable({}, QTE)

	self.Player1 = settings.PlayerOne
	self.Player2 = settings.PlayerTwo
	self.Type = settings.Type
	self.Duration = settings.Duration
	self.EventId = HttpService:GenerateGUID(false)
	self.Remote = script.Parent.Parent:WaitForChild("QTERemote")
	self.ForcedButton = settings.ForcedButton

	self.Trove = Trove.new()
	self.finishedEvent = self.Trove:Add(Instance.new("BindableEvent"))

	self.Trove:Add(task.delay(self.Duration, function()
		self:Resolve()
	end))

	return self
end

function QTE:Start()
	if activeEvents[self.EventId] then
		warn("QTE is already in progress")
		return
	end

	activeEvents[self.EventId] = {
		eventObject = self,
		startTime = os.clock(),
		finished = false,
	}

	local eventTable = activeEvents[self.EventId]

	eventTable[self.Player1] = {
		id = self.EventId,
		duration = self.Duration,
		result = nil,
	}
	self.Remote:FireClient(self.Player1, self.Type, self.Duration, self.EventId, self.ForcedButton)

	if self.Player2 then
		eventTable[self.Player2] = {
			id = self.EventId,
			duration = self.Duration,
			result = nil,
		}
		self.Remote:FireClient(self.Player2, self.Type, self.Duration, self.EventId, self.ForcedButton)
	end

	self.Trove:Add(function()
		if activeEvents[self.EventId] then
			activeEvents[self.EventId] = nil
		end
	end)
end

function QTE:_ResolveReflex(): Player | nil
	print("Resolve reflex called")
	local eventTable = activeEvents[self.EventId]
	if not eventTable then
		return
	end

	local player1Entry: PlayerEntry = eventTable[self.Player1]

	if not self.Player2 then -->> single player
		if (player1Entry.result or math.huge) <= self.Duration then
			self:CleanUp()
			return self.Player1
		end

		self:CleanUp()
		return nil
	end

	local player2Entry: PlayerEntry = eventTable[self.Player2]

	local winner: Player
	if (player1Entry.result or math.huge) < (player2Entry.result or math.huge) then
		winner = self.Player1
	elseif (player2Entry.result or math.huge) < (player1Entry.result or math.huge) then
		winner = self.Player2
	end

	self:CleanUp()
	return winner
end

function QTE:_ResolveTiming() end

function QTE.Resolve(self: QTEObject)
	local eventTable = activeEvents[self.EventId]
	if not eventTable then
		return
	end

	local winner: Player | nil
	if self.Type == "Reflex" then
		winner = self:_ResolveReflex()
	elseif self.Type == "Timing" then
		winner = self:_ResolveTiming()
	end

	self.finishedEvent:Fire(winner)

	self.Remote:FireClient(self.Player1, "End", nil, self.EventId)
	if self.Player2 then
		self.Remote:FireClient(self.Player2, "End", nil, self.EventId)
	end
end

function QTE:Await()
	return self.finishedEvent.Event:Wait()
end

function QTE:CleanUp()
	local eventTable = activeEvents[self.EventId]
	if not eventTable then
		return
	end

	eventTable.finished = true

	task.defer(function()
		self.Trove:Destroy()
	end)
end

return QTE
