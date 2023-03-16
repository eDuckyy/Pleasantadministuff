------- 
-- Made by: corehimself
-- Created: 2/28/2023
-- Updated: 3/15/2023
-------

-- // Services
local PlayersService = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HTTPService = game:GetService("HttpService")

-- // Variables
local MainStore = DataStoreService:GetDataStore("DTRD")
local Cooldown = (math.random(6, 14))

local BanMethods = {
	[1] = {Name = "Ban", Message = "You are banned for %s", Lengths = {hr = 1, day = 24, wk = 168, mo = 720, yr = 8760}},
	[2] = {Name = "Kick", Message = "You are kicked from the server"},
	[3] = {Name = "Unban", Message = "You have been unbanned"}
}

local function GetData(plr)
	local plrData = {};
	local succ, info = pcall(function()
		return MainStore:GetAsync("user_"..plr.UserId, {plrData})
	end)

	if not succ then
		warn("Failed to get data for player "..plr.Name.." with error: "..info)
	end

	return info
end

local function UpdateData(plr, method, time)
	local success, response = pcall(function()
		MainStore:UpdateAsync("user_"..plr.UserId, function(old)
			if old and old.time then
				return { method = method, time = string.format("%d%s", time, "hr") }
			elseif time == nil then
				return nil
			end
		end)
	end)
	if not success then
		warn("Failed to update data for player "..plr.Name.." with error: "..response)
	end
end


-- // Functions
local function HandleBanMethod(plr, method, time)
	local banMethod = nil
	for _, info in ipairs(BanMethods) do
		if info.Name == method then
			banMethod = info
			break
		end
	end

	if banMethod ~= nil then
		if banMethod == BanMethods[1] then -- Ban
			local timeLength, timeUnit = string.match(time, "(%d+)(%a+)")
			timeLength = tonumber(timeLength)
			if timeLength and timeUnit then
				local lengthInHours = banMethod.Lengths[timeUnit]
				if lengthInHours then
					local banEndTime = os.time() + (timeLength * lengthInHours * 3600)
					UpdateData(plr, method, timeLength) -- save ban time as string
					plr:Kick(banMethod.Message:format(time))
				else
					warn("Invalid time unit provided.")
				end
			elseif time == "Permanent" then
				plr:Kick(banMethod.Message:format(time))
			else
				warn("Invalid time format provided.")
			end
		elseif banMethod == BanMethods[2] then -- Kick
			plr:Kick(banMethod.Message)
		elseif banMethod == BanMethods[3] then -- Unban
			UpdateData(plr, "StressFree", nil) -- clear ban data
			warn("Player "..plr.Name.." has been unbanned.")
		end
	end
end


local function CheckPlayer(plr)
	spawn(function()
		while task.wait(Cooldown) do
			local data = GetData(plr)

			if type(data) == "table" and data.method ~= nil and data.time ~= nil then
				HandleBanMethod(plr, data.method, data.time)
			elseif data and data.method == "Unban" then
				UpdateData(plr, function(old) return {method = "StressFree"} end)
				warn("Player "..plr.Name.." has been unbanned.")
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

return { CheckPlayer = CheckPlayer, HandleBanMethod = HandleBanMethod, GetData = GetData, UpdateData = UpdateData }