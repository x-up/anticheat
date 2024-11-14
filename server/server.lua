local wait, delay = task.wait, task.delay
--[[
Documentation:

ExploitService:InitializePlayer(Player)
 > Initializes 'Player' for the antiexploit
    - return: 'mPlayer'

		mPlayer:CheckCharacter()
		 > Sanity check for the Player's character

		mPlayer:CheckCharacter()
		 > Sanity check for the Player's character

		mPlayer:Lagback(Position, Reason)
		 > Lags back the Player to 'Position' for reason 'Reason'

		mPlayer:Teleport(Position)
		 > Teleports the Player to 'Position'

		mPlayer:SetXTolerance(Tolerance)
		 > Sets the Player's X tolerance (how far the player can go on the X axis every 0.01 seconds)

		mPlayer:SetYTolerance(Tolerance)
		 > Sets the Player's Y tolerance (how far the player can go on the Y axis every 0.01 seconds)

		mPlayer:ClearStrikes()
		 > Clears the Player's exploit strikes

		mPlayer:SetStrikes(Amount)
		 > Sets the Player's strikes to 'Amount'
		 
		mPlayer:Update(Amount)
		 > Updates the Player object (runs checks, sets new vars)
		
		mPlayer:Reset()
		 > Resets mPlayer's to original values (when the object was first created)
		
		mPlayer:Cleanup()
		 > Destroy's the 'mPlayer' object and garbage collects it


ExploitService:GetmPlayer(Player)
 > Gets the 'mPlayer' object from 'Player'
    - return: 'mPlayer'
    
ExploitService:CleanupPlayer(Player)
 > Destroys the 'mPlayer' object from 'Player' and garbage collects it

ExploitService:Teleport(Player, Position)
 > Teleports 'Player' to 'Position'
 
ExploitService:Disable()
 > Enables the antiexploit

ExploitService:Enable()
 > Disables the antiexploit
]]

local serverScriptService = game:GetService("ServerScriptService")
local httpService = game:GetService("HttpService")
local clientTeamInfo = require(game.ReplicatedStorage.Data.ClientTeamInfo)

local players, runService, collectionService, teams = game:GetService("Players"), game:GetService("RunService"), game:GetService("CollectionService"), game:GetService("Teams")

local services = {}

for _, service in game:GetChildren() do
	local success, result = pcall(function()
		table.insert(services, service.Name)
	end)
end

local signal = require(game.ReplicatedStorage.Signal)


local intelTeamNames = {
--snipped for security
}

local combativeTeamNames = {
--snipped for security
}

local plrObject = require(serverScriptService.Classes.Exploits.PlayerObject)

local self = {}

self.Name = "Exploits"
self.Disabled = true
self.Players = {}
self.Connects = {}

self.DefaultXTolerance = 40
self.DefaultYTolerance = 100

self.Remotes = {
	RemoteEvent = Instance.new("RemoteEvent");
	SpectateEvent = Instance.new("RemoteEvent");
	ViewEvent = Instance.new("RemoteEvent");
}

plrObject.Exploits = self

self.OnInitialize = signal.new()

self.Connects["ChildAdded"] = workspace.ChildAdded:Connect(function(child)
	runService.Stepped:Wait()

	if child:IsA("Accoutrement") then
		child:Destroy()
	elseif child:IsA("Weld") and child.Part0 then
		local character = child.Part0.Parent
		local player = players:GetPlayerFromCharacter(character)

		if player then 
			local mPlayer = self:GetmPlayer(player)
			if mPlayer then
				mPlayer:Kick("stop exploiting 🙄 [1E]", "EXPLOIT | "..player.Name.." kicked for replicating Weld to workspace")
			end
		end

		child:Destroy()
	elseif child:IsA("Tool") then
		local tags = collectionService:GetTags(child)
		local player

		for _, v in tags do
			player = players:FindFirstChild(v)
		end

		if player then
			local mPlayer = self:GetmPlayer(player)
			if mPlayer then
				mPlayer:Kick("stop exploiting 🙄 [2E]", "EXPLOIT | " .. child.Name.. " dropped in workspace by: " .. player.Name)
			end
		else
			print("EXPLOIT | " .. child.Name .. " droppped in workspace by unknown player")
		end

		child:Destroy()
	end
end)


for i,v in {game:GetService("StarterPack"), game:GetService("StarterPlayer"), game:GetService("StarterPlayer"):WaitForChild("StarterCharacterScripts"), game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")} do
	self.Connects[v.Name.."Added"] = v.ChildAdded:Connect(function(added)
		task.wait()
		if added:IsA("Tool") then
			local tags = collectionService:GetTags(added)
			local player

			for _, v in tags do
				player = players:FindFirstChild(v)
			end

			if player then
				print("EXPLOIT | " .. added.Name.. " added to "..v.Name.." owned by: " .. player.Name)
				--local mPlayer = self:GetmPlayer(player)
				--mPlayer:Kick("stop exploiting 🙄 [3E]", "EXPLOIT | " .. added.Name.. " added to "..v.Name.." owned by: " .. player.Name)
			else
				print("EXPLOIT | " .. added.Name .. " added to "..v.Name.." owned by unknown player")
			end

			added:Destroy()
		end
	end)
end


self.Connects["Heartbeat"] = runService.Heartbeat:Connect(function()
	if not self.Disabled then
		for _,mPlayer in self.Players do
			mPlayer:Update()
		end
	end
end)

self.Remotes.RemoteEvent.OnServerEvent:Connect(function(player, num)
	local concat = (typeof(num) == "number" and (" | "..num) or "")
	local mPlayer = self.GetmPlayer(player)
	if mPlayer then
		mPlayer:Kick("stop exploiting 🙄 [1F]"..concat, "EXPLOIT | "..player.Name.." fired ban remote"..concat)
	end
end)

self.Remotes.SpectateEvent.OnServerEvent:Connect(function(player, subject, bool)
	local playerObj = self.Services.Players.Players[player.Name]
	local characterObj = playerObj.Character
	local rootPart = characterObj.RootPart
	if not bool then
		if workspace.IgnoreFolder:FindFirstChild(player.Name.."SpectatePart") then
			workspace.IgnoreFolder:FindFirstChild(player.Name.."SpectatePart"):Destroy()
		end
		rootPart.Velocity = Vector3.new()
		player.ReplicationFocus = nil
		player:RequestStreamAroundAsync(rootPart.Position, 10)
		return
	end
	local subjectPlayer = players:FindFirstChild(subject.Name)
	local subjectTeam; do 
		if subject:IsDescendantOf(workspace.SCPs) then
			subjectTeam = "SCP"
		else
			subjectTeam = subjectPlayer.Team and subjectPlayer.Team.Name or "Undefined"
		end
	end
	
	local ping = false
	if table.find(combativeTeamNames, player.Team.name) and subjectTeam == "Class-D" then
		ping = true
	end
	
	local canView = self.ValidateView(playerObj, subjectTeam, subject)
	if playerObj and playerObj.Roles and canView then
		local replicationFocus = workspace.IgnoreFolder:FindFirstChild(player.Name.."SpectatePart")
		if subject:IsA("Folder") and subject:GetAttribute("LastPosition") then
			if not replicationFocus then
				replicationFocus = Instance.new("Part")
				replicationFocus.Anchored = true
				replicationFocus.Size = Vector3.new(0,0,0)
				replicationFocus.Transparency = 1
				replicationFocus.CanCollide = false
				replicationFocus.CFrame = CFrame.new(subject:GetAttribute("LastPosition"))
				replicationFocus.Parent = workspace.IgnoreFolder
				replicationFocus.Name = player.Name.."SpectatePart"
			else
				replicationFocus.CFrame = CFrame.new(subject:GetAttribute("LastPosition"))
			end
		end
		if not replicationFocus then
			replicationFocus = subject:FindFirstChild("HumanoidRootPart")
		end
		player.ReplicationFocus = replicationFocus
		task.delay(1, function()
			rootPart.Velocity = Vector3.new()
			player:RequestStreamAroundAsync(rootPart.Position, 10)
		end)

		task.spawn(function()
			--snipped for security
		end)
	elseif not canView then
		local mPlayer = self.GetmPlayer(player)
		if mPlayer then
			--mPlayer:Kick("stop exploiting 🙄 [1G]", "EXPLOIT | "..player.Name.." fired spectate event without proper permissions")
		end
	end
end)

self.Remotes.ViewEvent.OnServerEvent:Connect(function(player, mousePosition, cameraPosition, mouseTarget)
	local mPlayer = self.GetmPlayer(player)

	if not mousePosition or not cameraPosition and mPlayer then 
		mPlayer:Kick("stop exploiting 🙄 [1H]", "EXPLOIT | "..player.Name.." was kicked for sending incorrect data via ViewEvent [1H]")
		return 
	end

	if (typeof(mouseTarget) ~= "Instance" and mouseTarget ~= nil) or typeof(mousePosition) ~= "Vector2" or typeof(cameraPosition) ~= "CFrame" then 
		if mPlayer then
			mPlayer:Kick("stop exploiting 🙄 [2H]", "EXPLOIT | "..player.Name.." was kicked for sending incorrect data via ViewEvent [2H]")
		end
		return 
	end

	if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	local mPlayer = self.Players[player.Name]
	if not mPlayer then return end

	local rootPart = player.Character.HumanoidRootPart
	local rootPartPosition = rootPart.Position

	mPlayer.MousePosition  = mousePosition
	mPlayer.MouseTarget = mouseTarget
	mPlayer.CameraPosition = cameraPosition
end)


self.OnInitialize:Connect(function()
	self.Connects["PlayerRemoving"] = self.Services.Players.OnPlayerLeave:Connect(function(player)
		self.CleanupPlayer(player)
	end)

	self.Connects["PlayerAdded"] = self.Services.Players.OnPlayerJoin:Connect(function(player)
		self.AddPlayer(player)
	end)

	for _, player in players:GetPlayers() do
		self.AddPlayer(player)
	end
end)


self.AddPlayer = function(player)
	if not runService:IsStudio() then
		if player.AccountAge < 7 then
			player:Kick("Your account must be 7 days or older to play.")
			return	
		end
	end 

	if self.Players[player.Name] then return end

	local mPlayer = plrObject.new(player)
	self.Players[player.Name] = mPlayer
end

self.GetmPlayer = function(player)
	local mPlayer = self.Players[player.Name]

	return mPlayer
end

self.CleanupPlayer = function(player)
	local mPlayer = self.GetmPlayer(player)

	if mPlayer then
		mPlayer:Cleanup()
		self.Players[player.Name] = nil
	end
end

self.Teleport = function(player, position)
	if not position then return end
	local mPlayer = self.GetmPlayer(player)

	if mPlayer then
		mPlayer:Teleport(position)
	else
		print("EXPLOIT | Error finding", player, "for teleportation to:", position)
	end
end

self.SetXTolerance = function(player, tolerance, clock)
	if not tolerance then return end
	local mPlayer = self.GetmPlayer(player)

	if mPlayer then
		mPlayer:SetXTolerance(tolerance, clock)
	end
end

self.SetYTolerance = function(player, tolerance, clock)
	if not tolerance then return end
	local mPlayer = self.GetmPlayer(player)

	if mPlayer then
		mPlayer:SetYTolerance(tolerance, clock)
	end
end

self.SetNoclipChecks = function(player, bool)
	local mPlayer = self.GetmPlayer(player)

	if mPlayer then
		mPlayer.NoclipBypass = not bool
	end
end

self.Disable = function()
	self.Disabled = true
	for _,mPlayer in self.Players do
		mPlayer:Reset()
	end
end


self.StartViewing = function(victim, player)
	if victim == player then return end
	local mPlayer1 = self.GetmPlayer(victim)
	local mPlayer2 = self.GetmPlayer(player)

	if mPlayer1 and mPlayer2 then
		if mPlayer1.GettingViewed or mPlayer2.Viewing then return end
		mPlayer1:StartViewing(player)
		mPlayer2.Viewing = victim
	end
end

self.StopViewing = function(player)
	local mPlayer = self.GetmPlayer(player)

	if mPlayer then
		if not mPlayer.Viewing then return end
		local victimPlayerObj = self.GetmPlayer(mPlayer.Viewing)
		if victimPlayerObj then
			victimPlayerObj:StopViewing(player)
			mPlayer.Viewing = nil
		end
	end
end

self.Spawn = function(player)
	local mPlayer = self.GetmPlayer(player)

	if mPlayer then
		mPlayer:Spawn()
	end
end

self.ValidateView = function(playerObj, teamName, target)
	--snipped for security
	return false
end

return self
