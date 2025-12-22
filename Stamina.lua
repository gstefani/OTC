local orange = 60 * 40
macro(10000, "Stamina Refill", function()
	if stamina() < orange then
		use(3233)
		delay(200)
	end
end, macroTab)
