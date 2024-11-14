local emptyVector, yVector, xzVector, stud, halfStud, abs = Vector3.new(), Vector3.new(1,0,1), Vector3.new(0, 1, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0.5, 0), math.abs
local players = game:GetService("Players")

local siteSpawnLocations = workspace.SiteSpawnLocations

local defenders = {

}

local function getRightGrips(hand)
	local grips = 0
	for i,v in pairs(hand:GetChildren()) do
		if v.Name == "RightGrip" then
			grips += 1
		end
	end
	return grips
end

local defaultXTolerance, defaultYTolerance = 35, 75

local mPlayer = {}
mPlayer.__index = mPlayer 
mPlayer.Exploits = nil

function mPlayer.new(player)
	local self = setmetatable({}, mPlayer)

	self.Player = player
	self.Connections = {}
	self.Character = nil
	self.RootPart = nil
	self.Humanoid = nil
	self.Id = player.UserId

	self.LastPosition = Vector3.new()
	self.LastDistance = 0
	self.LastYDistance = 0

	self.ExpectedTeleportDestination = CFrame.new()
	self.LastTPPosition = CFrame.new()
	self.Teleporting = false
	self.YTolerance = mPlayer.Exploits.DefaultYTolerance
	self.XTolerance = mPlayer.Exploits.DefaultXTolerance
	self.NoclipBypass = false

	self.Strikes = 0

	self.MousePosition = Vector2.new()
	self.CameraPosition = CFrame.new()
	self.MouseTarget = nil

	self.GettingViewed = false
	self.PlayerViewing = nil
	self.Viewing = nil

	self.Spawning = false

	self.Connections["CharacterAdded"] = self.Player.CharacterAdded:Connect(function(character)
		local rootPart, humanoid = character:WaitForChild("HumanoidRootPart"), character:WaitForChild("Humanoid")

		self:Reset()

		task.wait(1)

		if not self.Player or not self.Connections or self.Disabled then return end

		self.Character = character
		self.RootPart = rootPart
		self.Humanoid = humanoid
		
		if self.Player and self.Player.Team and self.Player.Team.Name ~= "Class-D" then return end

		self.Connections["AnimationPlayed"] = humanoid.AnimationPlayed:Connect(function(animationTrack)
			local animationId = animationTrack.Animation.AnimationId

			if #animationId >= 50 then
				self:Kick("stop exploiting 🙄 [1A]", "EXPLOIT | "..self.Player.Name.." kicked for long animation id")
			elseif animationId == "rbxassetid://0" then -- create an empty animation and upload it to the delta group and change the id here
				self:Kick("stop exploiting 🙄 [2A]", "EXPLOIT | "..self.Player.Name.." kicked for playing ban animation")
			elseif string.sub(animationId, 0, 13) ~= "rbxassetid://" and string.sub(animationId, 0, 32) ~= "http://www.roblox.com/asset/?id=" and string.sub(animationId, 0, 32) ~= "http://www.roblox.com/Asset?ID=" then
				self:Kick("stop exploiting 🙄 [3A]", "EXPLOIT | "..self.Player.Name.." kicked for invalid animation id")
			end
		end)

		self.Connections["DescendantRemoving"] = character.DescendantRemoving:Connect(function(removed)
			if self.Character and self.Character:GetAttribute("SCP2949") or self.Character:GetAttribute("SCP268") or self.Character:GetAttribute("PS_Infected") or self.Character:GetAttribute("SCP330") or self.Character:GetAttribute("SCP1079") or self.Player:GetAttribute("PS_Ghostify") or self.Character:GetAttribute("PS_NegateRemovalCheck") then return end
			if removed:GetAttribute("1B_EXEMPTION") then return end
			if removed and removed:IsA("BasePart") and removed.Position.Y > workspace.FallenPartsDestroyHeight + 5 and not (removed.Parent:GetAttribute("TempTool") or removed:GetAttribute("TempTool")) and removed.Parent.ClassName ~= "Tool" and (removed.Parent.Parent and removed.Parent.Parent.ClassName ~= "Tool") and (removed.Parent.Parent.Parent and removed.Parent.Parent.Parent.ClassName ~= "Tool") and (not removed.Parent:IsA("Accoutrement")) and (not self.Character:GetAttribute("PS_Ragdolled")) and self.Humanoid ~= nil and self.Humanoid.Health > 0 and self.Player.Team.Name ~= "Joining" and not self.Teleporting then
				task.delay(0.5, function()
					if self.Character then
						self:Kick("stop exploiting 🙄 [1B]", "EXPLOIT | "..self.Player.Name.." kicked for removing basepart | PATH: "..removed:GetFullName())
					end
				end)
			elseif removed:IsA("Humanoid") and not self.Character:GetAttribute("Testing") then
				task.delay(0.2, function()
					if player then
						self:Kick("stop exploiting 🙄 [2B]", "EXPLOIT |",player,"kicked for removing humanoid")
					end
				end)
			end
		end)

		self.Connections["DescendantAdded"] = character.DescendantAdded:Connect(function(added)
			if added.Name == "RightGrip" and added:IsA("Weld") and (added.Parent.Name ~= "RightHand" or getRightGrips(added.Part0) > 2) then
				self:Kick("stop exploiting 🙄 [1C]", "EXPLOIT | "..self.Player.Name.." kicked for right grip check")
			elseif added:IsA("Tool") and #added:GetChildren() < 1 then
				added:Destroy()
			end
		end)

		self.Connections["StateChanged"] = humanoid.StateChanged:Connect(function(old, new)
			if new == Enum.HumanoidStateType.StrafingNoPhysics then
				self:Kick("stop exploiting 🙄 [1J]", "EXPLOIT | "..self.Player.Name.." kicked for setting humanoid state to StrafingNoPhysics (noclip)")
			end
		end)

		self:SetYTolerance(defaultYTolerance, 1)
	end)

	self.Connections["CharacterRemoving"] = self.Player.CharacterRemoving:Connect(function(character)
		self.Character = nil
		self.RootPart = nil
		self.Humanoid = nil

		for i,v in pairs({"AnimationPlayed", "DescendantRemoving", "DescendantAdded", "Sit"}) do
			if self.Connections[v] then
				self.Connections[v]:Disconnect()
				self.Connections[v] = nil
			end
		end
	end)

	return self
end

function mPlayer:Lagback(position, reason)
	if self.Disabled or self.Teleporting or self.Spawning then return end

	if not self.Player then self:Cleanup() end

	if not position then return end
	if typeof(position) == "Vector3" then position = CFrame.new(position) end
	if typeof(position) ~= 'CFrame' then return end

	if self.Strikes >= 5 then 
		self:Kick("stop exploiting 🙄 [1D]", "EXPLOIT | "..self.Player.Name.." kicked for too many strikes")
		return
	end

	self:AddStrike(60)

	if not self.RootPart then return end

	if self.Humanoid and self.Humanoid.SeatPart and self.Humanoid.SeatPart:FindFirstChild("SeatWeld") then self.Humanoid.SeatPart.SeatWeld:Destroy() self.Humanoid.Sit = false task.wait() end

	self.Teleporting = true
	self.RootPart.Velocity = emptyVector
	task.delay(0.01, function()
		self.RootPart:PivotTo(position)
		self.RootPart.Anchored = true
	end)
	--self.RootPart.CFrame = position

	task.delay(1, function()
		if self:CheckCharacter() then
			self.RootPart.Anchored = false
			self.RootPart.Velocity = emptyVector
			self.RootPart:PivotTo(position)
			self.Teleporting = false
		end
	end)
end

function mPlayer:Teleport(position, spawning)
	if self.Disabled then return end

	if not position then return end
	if typeof(position) == "Vector3" then position = CFrame.new(position) end
	if typeof(position) ~= 'CFrame' then return end

	if self.Humanoid and self.Humanoid.SeatPart and self.Humanoid.SeatPart:FindFirstChild("SeatWeld") then self.Humanoid.SeatPart.SeatWeld:Destroy() self.Humanoid.Sit = false task.wait() end

	if not self.RootPart then
		repeat task.wait() until self.RootPart
	end
	
	if spawning then
		self.Spawning = true
		
		task.delay(2, function()
			self.Spawning = false
		end)
	end
	
	if not self.RootPart then return end	
	
	self.Player:RequestStreamAroundAsync(position.Position, 10)
	
	task.delay(1, function()
		if self.RootPart then
			local DistanceFromDestination = (self.RootPart.Position - self.ExpectedTeleportDestination.Position).Magnitude
			if DistanceFromDestination > 75 and self.Player and self.Player.Team and self.Player.Team.Name == "Class-D" then
				self:Lagback(self.LastTPPosition, "Teleport")
				print("EXPLOIT | "..self.Player.Name.." lagged back for teleportation | STRIKES: "..self.Strikes)
			end
		end
		self.Teleporting = false
		self.ExpectedTeleportDestination = CFrame.new()
		self.LastTPPosition = CFrame.new()
	end)
	
	task.wait()
	
	self.Teleporting = true
	if self.RootPart then
		self.LastTPPosition = self.RootPart.CFrame
	end
	self.ExpectedTeleportDestination = position
	
	task.delay(0.01, function()
		self.RootPart:PivotTo(position)
	end)
end

function mPlayer:Update()
	if self.Disabled then return end
	if not self:CheckCharacter() then return end
	if not self.LastPosition or self.LastPosition == Vector3.new() then self.LastPosition = self.RootPart.Position end

	if self.LastPosition == nil then return end

	if not self.Player then self:Cleanup() return end
	
	local team = self.Player.Team
	if team and team.Name ~= "Class-D" then return end
	local playerName = self.Player.Name

	local difference = self.RootPart.Position - self.LastPosition

	local differenceNoY = difference * yVector
	local yDifference = difference * xzVector

	local distance, distanceY = abs(differenceNoY.Magnitude), abs(yDifference.Magnitude)

	local addition = team.Name == "Class-D" and 0 or 5

	if not self.Teleporting and not self.Spawning and not self.Player:GetAttribute("Cuffed") then
		if distance >= self.XTolerance + addition or distanceY >= self.YTolerance + addition then
			self:Lagback(self.LastPosition, "Speed")
			print("EXPLOIT | "..playerName.." lagged back for speed | STRIKES: "..self.Strikes.." | XZ/Y distance: "..distance.." "..distanceY)
		end

		if self.RootPart.Velocity.Magnitude >= 1000 then
			print("EXPLOIT | "..playerName.." lagged back for flinging")
			self:Lagback(self.LastPosition, "Fling")
		end
	end

	self.LastDistance = distance
	self.LastYDistance = distanceY
	self.LastPosition = self.RootPart.Position
end

function mPlayer:SetXTolerance(tolerance, clock)
	self.XTolerance = tolerance
	if clock ~= math.huge then
		task.delay(clock or 5, function() self.XTolerance = defaultXTolerance end)
	end
end

function mPlayer:SetYTolerance(tolerance, clock)
	self.YTolerance = tolerance
	if clock ~= math.huge then
		task.delay(clock or 5, function() self.YTolerance = defaultYTolerance end)
	end
end

function mPlayer:AddStrike(length)
	if (not self.Strikes) then return end
	self.Strikes += 1
	task.delay(length, function()
		if (not self.Strikes) then return end
		self.Strikes -= 1
	end)
end

function mPlayer:ClearStrikes()
	self.Strikes = 0
end

function mPlayer:SetStrikes(amount)
	if (not amount) then return end
	self.Strikes = amount
end

function mPlayer:CheckCharacter()
	return self.RootPart ~= nil and self.Humanoid ~= nil and self.Character ~= nil
end

function mPlayer:Reset()
	self.LastPosition = Vector3.new()
	self.LastDistance = 0
	self.LastYDistance = 0

	self.ExpectedTeleportDestination = CFrame.new()
	self.LastTPPosition = CFrame.new()
	self.Teleporting = false
	self.YTolerance = defaultYTolerance
	self.XTolerance = defaultXTolerance

	self.Strikes = 0
end

function mPlayer:StartViewing(player)
	local ViewEvent = mPlayer.Exploits.Remotes.ViewEvent
	ViewEvent:FireClient(self.Player, true)
	self.GettingViewed = true
	self.PlayerViewing = player
	
	self.Player.ReplicationFocus = player.Character.HumanoidRootPart

	self.Connections["ViewingConnection"] = game:GetService("RunService").Heartbeat:Connect(function()
		ViewEvent:FireClient(player, self.MousePosition, self.MouseTarget, self.CameraPosition, self.Player)
	end)
end

function mPlayer:StopViewing(player)
	mPlayer.Exploits.Remotes.ViewEvent:FireClient(self.Player, false)
	mPlayer.Exploits.Remotes.ViewEvent:FireClient(player, "Stop")
	self.GettingViewed = false
	self.PlayerViewing = nil
	self.Connections["ViewingConnection"]:Disconnect()
	self.Player.ReplicationFocus = self.RootPart
end

function mPlayer:Spawn()
	local team = self.Player.Team
	local eventService = mPlayer.Exploits.Services.Events
	local selectedSpawnLocation

	if team and siteSpawnLocations:FindFirstChild(team.Name) and team.Name ~= "Joining" then
		local spawns
		local altSpawn = false
		
		if table.find(defenders, team.Name) then
			for i,v in pairs(eventService.Events) do
				if v.Active and v.ShortRaid then
					altSpawn = true
					break
				end
			end
		end
		
		if altSpawn then
			spawns = siteSpawnLocations.ShortRaidCombative:GetChildren()
		else
			spawns = siteSpawnLocations[team.Name]:GetChildren()
		end
		
		selectedSpawnLocation = spawns[math.random(1, #spawns)]
	end

	if selectedSpawnLocation then
		self:Teleport(selectedSpawnLocation.CFrame * CFrame.new(0,5,0), true)
	end
end

function mPlayer:Kick(reason, output)
	if self.Id and players:GetPlayerByUserId(self.Id) then
		self.Player:Kick(reason)

		mPlayer.Exploits.CleanupPlayer(self.Player)
	end
end

function mPlayer:Cleanup()
	if self.GettingViewed then
		self:StopViewing(self.PlayerViewing)
	end
	if self.Connections then
		for i,v in self.Connections do
			v:Disconnect()
		end
		table.clear(self)
	end

end

return mPlayer
