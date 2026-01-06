setDefaultTab("Tools")

local DANGER_TILE_ID = 55636
local SEARCH_RADIUS = 3 -- SQMs
local MOVE_COOLDOWN = 200 -- ms

local function nowMs()
	if g_clock and g_clock.millis then
		return g_clock.millis()
	end
	return os.time() * 1000
end

local function tileHasThingId(tile, targetId)
	if not tile then
		return false
	end
	local things = tile:getThings()
	if not things then
		return false
	end

	for _, thing in ipairs(things) do
		if thing.getId and thing:getId() == targetId then
			return true
		end
	end
	return false
end

local function manhattan(a, b)
	return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

local function findSafeTileCross(centerPos, playerPos, radius, dangerId)
	local bestDist, bestPos = nil, nil

	local directions = {
		{ dx = 1, dy = 0 }, -- leste
		{ dx = -1, dy = 0 }, -- oeste
		{ dx = 0, dy = 1 }, -- sul
		{ dx = 0, dy = -1 }, -- norte
	}

	for _, dir in ipairs(directions) do
		for step = 1, radius do
			local p = {
				x = centerPos.x + dir.dx * step,
				y = centerPos.y + dir.dy * step,
				z = centerPos.z,
			}

			local tile = g_map.getTile(p)
			if tile and not tileHasThingId(tile, dangerId) then
				local dist = manhattan(playerPos, p)
				if not bestDist or dist < bestDist then
					bestDist = dist
					bestPos = p
				end
			end
		end
	end

	return bestPos
end

-- Macro Principal
local lastMove = 0
macro(200, "Boss Safe Position (2 Modos)", function(m)
	if not m:isOn() then
		return
	end

	local now = nowMs()
	if now - lastMove < MOVE_COOLDOWN then
		return
	end

	local playerPos = pos()
	if not playerPos then
		return
	end

	local boss = g_game.getAttackingCreature()
	local centerPos

	if boss and boss:getPosition() then
		-- MODO 1: com target (boss como centro)
		centerPos = boss:getPosition()
	else
		-- MODO 2: sem target (player como centro)
		centerPos = playerPos
	end

	local safePos = findSafeTileCross(centerPos, playerPos, SEARCH_RADIUS, DANGER_TILE_ID)

	if safePos then
		autoWalk(safePos, 50, {
			precision = 1,
			ignoreNonPathable = true,
		})
		lastMove = now
	end
end)
