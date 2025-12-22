--Join Discord server for free scripts
--https://discord.gg/RkQ9nyPMBH
--Made By VivoDibra
--Tested on vBot 4.8 / OTCV8 3.2 rev 4

--------------------------------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------------------------------
local MAX_WALK_DISTANCE = 5 -- Maximum distance to look for safe zones (max 7 recommended for performance)
local DELAY_AFTER_WALK = 500 -- Delay after walking to avoid lag (max 500)
local AVOIDED_EFFECT_IDS = { 413, 43, 3383, 3361 } -- List of effect IDs to avoid

--------------------------------------------------------------------------------------------------------
-- Diagonal Movement Offsets
--------------------------------------------------------------------------------------------------------
local diagonalOffsets = {
	{ x = -1, y = -1, dir = NorthWest },
	{ x = 1, y = -1, dir = NorthEast },
	{ x = -1, y = 1, dir = SouthWest },
	{ x = 1, y = 1, dir = SouthEast },
}

--------------------------------------------------------------------------------------------------------
-- State Variables
--------------------------------------------------------------------------------------------------------
local avoidEffectsMacro = macro(10000, "Avoid Effects", function() end)
local safeTiles = {}
local isAvoiding = false
local lastSafePosition = nil

--------------------------------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------------------------------

-- Marks a tile as temporarily invalid for walking
local function markTileAsInvalid(tile)
	tile.invalid = true
	tile:setText("Invalid")
	schedule(500, function()
		if tile then
			tile.invalid = false
			tile:setText("")
		end
	end)
end

--------------------------------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------------------------------

-- Handles the appearance of new effects and updates the tile text
onAddThing(function(tile, thing)
	if avoidEffectsMacro.isOff() or not thing:isEffect() then
		return
	end

	if not table.find(AVOIDED_EFFECT_IDS, thing:getId()) then
		tile:setText(thing:getId())
		schedule(1000, function()
			if tile then
				tile:setText("")
			end
		end)
	else
		markTileAsInvalid(tile)
	end
end)

-- Detects if the player is standing on an avoided effect and finds a nearby safe tile
onAddThing(function(tile, thing)
	if avoidEffectsMacro.isOff() or not tile or not thing or not thing:isEffect() then
		return
	end

	local playerPos = pos()
	local tilePos = tile:getPosition()

	if not table.equals(tilePos, playerPos) then
		return
	end
	if not table.find(AVOIDED_EFFECT_IDS, thing:getId()) then
		return
	end
	if isAvoiding then
		return
	end

	isAvoiding = true

	-- Clear previous safe tile entries
	for i = 1, MAX_WALK_DISTANCE do
		safeTiles[i] = {}
	end

	-- Scan for valid tiles
	schedule(100, function()
		for _, mapTile in ipairs(g_map.getTiles(playerPos.z)) do
			local distance = getDistanceBetween(playerPos, mapTile:getPosition())
			if distance < MAX_WALK_DISTANCE and not mapTile.invalid and mapTile:isWalkable() and findPath(playerPos, mapTile:getPosition(), 10) then
				table.insert(safeTiles[distance], mapTile)
				if #safeTiles[1] > 0 then
					break
				end -- Early exit if tile is adjacent
			end
		end

		-- Try to walk to the closest safe tile
		for distance = 1, MAX_WALK_DISTANCE do
			if #safeTiles[distance] > 0 then
				local targetTile = safeTiles[distance][1]
				local targetPos = targetTile:getPosition()
				lastSafePosition = targetPos

				-- If tile is adjacent, use direct walk direction
				if distance == 1 then
					for _, offset in ipairs(diagonalOffsets) do
						local offsetPos = { x = posx() + offset.x, y = posy() + offset.y, z = posz() }
						if table.equals(offsetPos, targetPos) then
							g_game.walk(offset.dir)
							schedule(DELAY_AFTER_WALK, function()
								isAvoiding = false
							end)
							return
						end
					end
				end

				-- Otherwise, use autoWalk
				autoWalk(targetPos)
				schedule(DELAY_AFTER_WALK, function()
					isAvoiding = false
				end)
				break
			end
		end
	end)
end)

--------------------------------------------------------------------------------------------------------
-- Macro: Retry walking to last safe position
--------------------------------------------------------------------------------------------------------
macro(500, "Force Walk Retry", function()
	if lastSafePosition then
		player:autoWalk(lastSafePosition, true)
	end

	if lastSafePosition and table.equals(pos(), lastSafePosition) then
		lastSafePosition = nil
	end
end)

addButton("", "+ Free Scripts", function()
	g_platform.openUrl("https://discord.gg/RkQ9nyPMBH")
end)

--Join Discord server for free scripts
--https://discord.gg/RkQ9nyPMBH
--Made By VivoDibra
--Tested on vBot 4.8 / OTCV8 3.2 rev 4
