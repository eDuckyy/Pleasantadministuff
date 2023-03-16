------- 
-- Made by: corehimself
-- Created: 2/28/2023
-- Updated: 3/12/2023
-------

-- // Services
local plrServ = game:GetService("Players");
local msgServ = game:GetService("MessagingService");
local httpServ = game:GetService("HttpService");
local dataStoreServ = game:GetService("DataStoreService");

-- // Variables
local mainStore = dataStoreServ:GetDataStore("DTRD");
local cooldown = (math.random(6, 14));

-- // Functions
-------------------------- 

-- Temp. Anti-Api-Exhaust

--------------------------

local function check(plr : Instance)
	spawn(function()
		while task.wait(cooldown) do
			local succ, inf = pcall(function()
				return mainStore:GetAsync("user_"..plr.UserId)
			end)
			
			if (succ) then
				if ((inf.method == "Ban" and inf.time)) then
					banHandler(plr, inf.time)
				elseif (inf.method == "Kick") then
					plr:Kick("DTR");
				end
			end
		end
	end)
end

function banHandler(plr, banEndTime)
	if banEndTime == "permanent" then 
		plr:Kick("You are permanently banned."); 
		return 
	end

	local banEndDateTime = os.date("!%Y-%m-%dT%H:%M:%S", tonumber(banEndTime))
	local currentDateTime = os.date("!%Y-%m-%dT%H:%M:%S")

	if currentDateTime < banEndDateTime then
		plr:Kick("You are banned until "..banEndTime..".")
		return
	else
		-- Remove the ban from the database
		local succ, err = pcall(function()
			mainStore:UpdateAsync("user_"..plr.UserId, function(old)
				return "stressFree"
			end)
		end)

		if (succ) then
			check(plr)
			return
		else
			warn("Error removing ban for "..plr.Name..": "..tostring(err))
		end
	end
end

-- // Init
plrServ.PlayerAdded:Connect(function(plr)
	local succ, inf = pcall(function()
		return mainStore:GetAsync("user_"..plr.UserId)
	end)

	if (succ) then
		local method = inf.method
		local banEndTime = inf.banEndTime
		if (method and method == "Ban" and banEndTime) then
			banHandler(plr, banEndTime);
		elseif (inf == "Kick" or inf == "Unban") then
			local succ, err = pcall(function()
				mainStore:UpdateAsync("user_"..plr.UserId, function(old)
					return "stressFree"
				end)
			end)

			if (succ) then
				check(plr)
				return
			else
				warn("Error unban/kick for "..plr.Name..": "..tostring(err))
			end
		else
			check(plr)
			return
		end
	else
		task.wait(3)
		check(plr)
		return
	end
end)
