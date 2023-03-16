local DTR = require(script.Parent["DTR v3.2.1"]);

function onPlayerAdded(plr)
	DTR.CheckPlayer(plr);
end

game.Players.PlayerAdded:Connect(onPlayerAdded)