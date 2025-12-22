-- Hotkeys parar Target e Cave
hotkey("Insert", "Toggle Target", function()
	if TargetBot.isOff() then
		TargetBot.setOn()
		warn("TargetBot " .. (TargetBot.isOn() and "On" or "Off"))
		return
	end
	if TargetBot.isOn() then
		TargetBot.setOff()
		warn("TargetBot " .. (TargetBot.isOn() and "On" or "Off"))
		return
	end
end)

hotkey("Pageup", "ReturnCave", function()
	CaveBot.setOn()
	warn("CaveBot ON")
end)

hotkey("Pagedown", "PauseCave", function()
	CaveBot.setOff()
	warn("CaveBot OFF")
end)
