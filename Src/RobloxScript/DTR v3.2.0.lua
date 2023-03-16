------- 
-- Made by: corehimself
-- Created: 2/28/2023
-- Updated: 3/12/2023
------- 

-- // Services
local PlayersService = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- // Variables
local MainStore = DataStoreService:GetDataStore("DTRD")
local Cooldown = (math.random(6, 14))

local BanMethods = {
	[1] = {Name = "Ban", Message = "You are banned until %s.", Handler = function(plr, banEndTime) 
		return {IsValid = os.time() < banEndTime and true or false, Message = BanMethods[1].Message:format(os.date("!%Y-%m-%dT%H:%M:%S", tonumber(banEndTime)))}
	end},
	[2] = {Name = "Kick", Message = "You are kicked from the server.", Handler = function(plr, _) return {IsValid = false, Message = BanMethods[2].Message} end},
}

local function GetData(plr)
	local succ, response = pcall(MainStore.GetAsync, MainStore, MainStore, "user_"..plr.UserId)
	if not succ then
		warn("Failed to get data for player "..plr.Name.." with error: "..response)
	end
	return response
end

local function UpdateData(plr, updateFunction)
	local success, response = pcall(function() MainStore:UpdateAsync("user_"..plr.UserId, updateFunction) end)
	if not success then
		warn("Failed to update data for player "..plr.Name.." with error: "..response)
	end
end

-- // Functions
-------------------------- 

-- Temp. Anti-Api-Exhaust

--------------------------
local function HandleBanMethod(plr, method, time)
	local banMethod = nil
	for _, info in ipairs(BanMethods) do
		if info.Name == method then
			banMethod = info
			break
		end
	end

	if banMethod ~= nil then
		local result = banMethod.Handler(plr, time)
		if result.IsValid then
			plr:Kick(result.Message)
		end
	end
end

local function CheckPlayer(plr)
	spawn(function()
		while task.wait(Cooldown) do
			local data = GetData(plr)

			if type(data) == "table" and data.method ~= nil and data.time ~= nil then
				HandleBanMethod(plr, data.method, data.time)
			end
		end
	end)
end

-- // Init
local function PlayerAdded(plr)
	local data = GetData(plr)

	if type(data) == "table" then
		if data.method ~= nil and data.time ~= nil then
			HandleBanMethod(plr, data.method, data.time)
		elseif data.method == "Unban" then
			UpdateData(plr, function(old) return {method = "stressFree"} end)
			CheckPlayer(plr)
		end
	else 
		task.wait(3)
		CheckPlayer(plr)
	end
end

PlayersService.PlayerAdded:Connect(PlayerAdded)

-- Return module table
return {CheckPlayer = CheckPlayer, HandleBanMethod = HandleBanMethod, GetData = GetData}