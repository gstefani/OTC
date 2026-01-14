setDefaultTab("News")

-- Configurações de armazenamento
storage.configs = storage.configs or {}

local function createToggle(name, label)
	storage.configs[name] = storage.configs[name] or false

	local button = UI.Button(label .. ": OFF")
	button:setColor("red")

	local function refresh()
		if storage.configs[name] then
			button:setText(label .. ": ON")
			button:setColor("green")
		else
			button:setText(label .. ": OFF")
			button:setColor("red")
		end
	end

	button.onClick = function()
		storage.configs[name] = not storage.configs[name]
		refresh()
	end

	refresh()
end

UI.Separator()
UI.Label("Configs Gerais"):setColor("orange")

createToggle("huntWalkSmarter", "Hunt Walk Smarter")
createToggle("runeOnTarget", "Rune On Target")
createToggle("autoLootOnLook", "Auto Loot On Look")
createToggle("autoBuff", "Auto Buff")
createToggle("revidarPk", "Revidar PK")
createToggle("manaTrainer", "Mana Trainer Hunt")
createToggle("iconCaveBot", "Icon CaveBot/TargetBot")
createToggle("abrirMainBp", "Abrir Main BP")
createToggle("turnTarget", "Turn Target Canudo")
createToggle("bugMapMouse", "Bug Map Mouse")
createToggle("bugMapWasd", "Bug Map WASD")
createToggle("hideSprites", "Esconder Sprites")

--------------------------------------------------------------------------------------------------------------------------

-- Aumentar tamanho do CaveBot List
local size = 250
CaveBot.actionList:getParent():setHeight(size)

--------------------------------------------------------------------------------------------------------------------------

-- Smart Walk Hunt
macro(200, "Hunt Walk Smarter", function()
	if not storage.configs.huntWalkSmarter then
		return
	end
	if g_game:isAttacking() then
		CaveBot.Config.values["walkDelay"] = 80
		CaveBot.save()
	else
		CaveBot.Config.values["walkDelay"] = 10
		CaveBot.save()
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Runa no target
UI.Label("Runa no Target:"):setColor("yellow")
UI.TextEdit(storage.runeTarget or "3150", function(widget, text)
	storage.runeTarget = text
end)
macro(200, "Rune On Target", function()
	if not storage.configs.runeOnTarget then
		return
	end
	if not g_game.isAttacking() then
		return
	end
	if not g_game.getAttackingCreature():canShoot() then
		return
	end
	useWith(tonumber(storage.runeTarget), g_game.getAttackingCreature())
	delay(500)
end)

--------------------------------------------------------------------------------------------------------------------------

-- Auto Loot ao dar look
local doAutoLootLook = macro(5000, "Auto Loot on Look", function() end)
onTextMessage(function(mode, text)
	if not storage.configs.autoLootOnLook then
		return
	end
	if mode == 20 and text:find("You see") and doAutoLootLook:isOn() then
		local regex = [[You see (?:an|a)([a-z A-Z]*).]]
		local data = regexMatch(text, regex)[1]
		if data and data[2] then
			say("!autoloot add, " .. data[2]:trim())
		end
	end
end)
addIcon("doAutoLootLook", { item = 35729, text = "LOOT" }, function(icon, isOn)
	doAutoLootLook.setOn(isOn)
end)

--------------------------------------------------------------------------------------------------------------------------

-- Toggle CaveBot
hotkey("Insert", function()
	if CaveBot.isOff() then
		CaveBot.setOn()
		warn("CaveBot ON")
	else
		CaveBot.setOff()
		warn("CaveBot OFF")
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Auto Buff
macro(200, "AutoBuff", function()
	if not storage.configs.autoBuff then
		return
	end
	if hasPartyBuff() then
		return
	end
	say(storage.buffName or "Power Up")
end)
addTextEdit("buffName", storage.buffName or "Power Up", function(widget, text)
	storage.buffName = text
end)

--------------------------------------------------------------------------------------------------------------------------
UI.Separator()
-- Revide PK
local macroName = "Revidar PK" -- macro name
local pauseTarget = true -- pause targetbot
local pauseCave = true -- pause cavebot
local followTarget = true -- set chase mode to follow (valor inicial)

-- Armazenamento para o estado do followTarget
storage.followTargetState = storage.followTargetState or true

-- Interface para controlar o followTarget
UI.Label("Follow PK:"):setColor("yellow")
local followTargetButton = UI.Button("Follow PK: " .. (storage.followTargetState and "SIM" or "NAO"))
followTargetButton.onClick = function(widget)
	storage.followTargetState = not storage.followTargetState
	widget:setText("Follow PK: " .. (storage.followTargetState and "SIM" or "NAO"))
end

local st = "AutoRevide"
storage[st] = storage[st] or {
	pausedTarget = false,
	pausedCave = false,
}
local c = storage[st]
local target = nil
local m = macro(250, macroName, function()
	if not storage.configs.revidarPk then
		return
	end
	-- Atualiza o followTarget com base no estado armazenado
	followTarget = storage.followTargetState

	if not target then
		if c.pausedTarget then
			c.pausedTarget = false
			TargetBot.setOn()
		end
		if c.pausedCave then
			c.pausedCave = false
			CaveBot.setOn()
		end
		return
	end

	local creature = getPlayerByName(target)
	if not creature then
		target = nil
		return
	end
	if pauseTargetBot then
		c.pausedTarget = true
		TargetBot.setOff()
	end
	if pauseTarget then
		c.pausedTarget = true
		TargetBot.setOff()
	end
	if pauseCave then
		c.pausedCave = true
		CaveBot.setOff()
	end

	if followTarget then
		g_game.setChaseMode(1)
	end

	if g_game.isAttacking() then
		if g_game.getAttackingCreature():getName() == target then
			return
		end
	end
	g_game.attack(creature)
end)

onTextMessage(function(mode, text)
	if m:isOff() then
		return
	end
	if not text:find("hitpoints due to an attack by") then
		return
	end
	local p = "You lose (%d+) hitpoints due to an attack by (.+)%."
	local hp, attacker = text:match(p)
	local c = getPlayerByName(attacker)
	if not c then
		return
	end
	target = c:getName()
end)

--------------------------------------------------------------------------------------------------------------------------

-- Mana Trainer Hunt
-- Namespace dedicado para armazenamento
if not storage.manaTrainer then
	storage.manaTrainer = {}
end

-- Garantir que tenha um valor padrão
storage.manaTrainer.spellAndPercent = storage.manaTrainer.spellAndPercent or "power down, 80"

-- Função para extrair spell e porcentagem do texto
local function parseSpellAndPercent(text)
	-- Garantir que 'text' seja sempre uma string válida
	text = tostring(text or "power down, 80")

	local spell, percent = string.match(text, "([^,]+),?%s*(%d*)")
	spell = spell and spell:trim() or "power down"
	percent = tonumber(percent) or 80

	-- Garantir que a porcentagem esteja entre 1 e 100
	if percent < 1 then
		percent = 1
	end
	if percent > 100 then
		percent = 100
	end

	return spell, percent
end

-- Extrair configurações iniciais
local spell, percent = parseSpellAndPercent(storage.manaTrainer.spellAndPercent)

-- Configuração
local config = {
	percent_train_ml = percent, -- Porcentagem que irá lançar a spell
	spell_train = spell, -- Nome da spell para treinar
}

-- Interface para configuração
UI.Separator()
UI.Label("Mana Trainer Hunt"):setColor("orange")

-- Text Edit para a spell e porcentagem
UI.Label("Spell, Porcentagem"):setColor("yellow")
addTextEdit("spell_percent_edit", storage.manaTrainer.spellAndPercent, function(widget, text)
	local newSpell, newPercent = parseSpellAndPercent(text)
	config.spell_train = newSpell
	config.percent_train_ml = newPercent
	storage.manaTrainer.spellAndPercent = newSpell .. ", " .. newPercent

	-- Atualizar o TextEdit com valores validados
	widget:setText(newSpell .. ", " .. newPercent)
end)

-- Macro principal
macro(200, "Mana Trainer Hunt", function()
	if not storage.configs.manaTrainer then
		return
	end
	if manapercent() >= config.percent_train_ml then
		say(config.spell_train)
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- ICON Ligar e Desligar CaveBot/TargetBot
local cIcon = addIcon("cI", { text = "Cave\nBot", switchable = false, moveable = true }, function()
	if CaveBot.isOff() then
		CaveBot.setOn()
	else
		CaveBot.setOff()
	end
end)
cIcon:setSize({ height = 30, width = 50 })
cIcon.text:setFont("verdana-11px-rounded")

local tIcon = addIcon("tI", { text = "Target\nBot", switchable = false, moveable = true }, function()
	if TargetBot.isOff() then
		TargetBot.setOn()
	else
		TargetBot.setOff()
	end
end)
tIcon:setSize({ height = 30, width = 50 })
tIcon.text:setFont("verdana-11px-rounded")

macro(200, function()
	if not storage.configs.iconCaveBot then
		return
	end
	if CaveBot.isOn() then
		cIcon.text:setColoredText({ "CaveBot\n", "white", "ON", "green" })
	else
		cIcon.text:setColoredText({ "CaveBot\n", "white", "OFF", "red" })
	end
	if TargetBot.isOn() then
		tIcon.text:setColoredText({ "Target\n", "white", "ON", "green" })
	else
		tIcon.text:setColoredText({ "Target\n", "white", "OFF", "red" })
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Abrir BP principal
macro(200, "Abrir Main BP", function()
	if not storage.configs.abrirMainBp then
		return
	end
	if not getContainers()[0] and getBack() then
		g_game.open(getBack())
	end
end)

-- Spy Level
local keyUp = "="
local keyDown = "-"
local lockedLevel = pos().z

onPlayerPositionChange(function(newPos, oldPos)
	lockedLevel = pos().z
	modules.game_interface.getMapPanel():unlockVisibleFloor()
end)

onKeyPress(function(keys)
	if keys == keyDown then
		lockedLevel = lockedLevel + 1
		modules.game_interface.getMapPanel():lockVisibleFloor(lockedLevel)
	elseif keys == keyUp then
		lockedLevel = lockedLevel - 1
		modules.game_interface.getMapPanel():lockVisibleFloor(lockedLevel)
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Turn Target Canudo
Turn = {}

Turn.maxDistance = { x = 7, y = 7 }
Turn.minDistance = 1
Turn.macro = macro(100, "Turn by Ryan", function()
	if not storage.configs.turnTarget then
		return
	end
	local target = g_game.getAttackingCreature()
	if target then
		local targetPos = target:getPosition()
		if targetPos then
			local pos = pos()
			local targetDistance = { x = math.abs(pos.x - targetPos.x), y = math.abs(pos.y - targetPos.y) }
			if not (targetDistance.x > Turn.minDistance and targetDistance.y > Turn.minDistance) then
				if targetDistance.x <= Turn.maxDistance.x and targetDistance.y <= Turn.maxDistance.y then
					local playerDir = player:getDirection()
					if targetDistance.y >= targetDistance.x then
						if targetPos.y > pos.y then
							return playerDir ~= 2 and turn(2)
						else
							return playerDir ~= 0 and turn(0)
						end
					else
						if targetPos.x > pos.x then
							return playerDir ~= 1 and turn(1)
						else
							return playerDir ~= 3 and turn(3)
						end
					end
				end
			end
		end
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Bugmap pelo mouse
macro(50, "Bug Map - Mouse", function(m)
	if not storage.configs.bugMapMouse then
		return
	end
	--Made By VivoDibra#1182
	local tile = getTileUnderCursor()
	if not tile then
		return
	end
	if g_mouse.isPressed(4) then
		g_game.use(tile:getTopUseThing())
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Bugmap WASD
local function checkPos(x, y)
	xyz = g_game.getLocalPlayer():getPosition()
	xyz.x = xyz.x + x
	xyz.y = xyz.y + y
	tile = g_map.getTile(xyz)
	if tile then
		return g_game.use(tile:getTopUseThing())
	else
		return false
	end
end

consoleModule = modules.game_console
macro(50, "Bug Map - WASD", function()
	if not storage.configs.bugMapWasd then
		return
	end
	if modules.corelib.g_keyboard.isKeyPressed("w") and not consoleModule:isChatEnabled() then
		checkPos(0, -5)
	elseif modules.corelib.g_keyboard.isKeyPressed("e") and not consoleModule:isChatEnabled() then
		checkPos(3, -3)
	elseif modules.corelib.g_keyboard.isKeyPressed("d") and not consoleModule:isChatEnabled() then
		checkPos(5, 0)
	elseif modules.corelib.g_keyboard.isKeyPressed("c") and not consoleModule:isChatEnabled() then
		checkPos(3, 3)
	elseif modules.corelib.g_keyboard.isKeyPressed("s") and not consoleModule:isChatEnabled() then
		checkPos(0, 5)
	elseif modules.corelib.g_keyboard.isKeyPressed("z") and not consoleModule:isChatEnabled() then
		checkPos(-3, 3)
	elseif modules.corelib.g_keyboard.isKeyPressed("a") and not consoleModule:isChatEnabled() then
		checkPos(-5, 0)
	elseif modules.corelib.g_keyboard.isKeyPressed("q") and not consoleModule:isChatEnabled() then
		checkPos(-3, -3)
	end
end)

--------------------------------------------------------------------------------------------------------------------------

--[[Esconder MAGIAS(SPRITES)]]
sprh = macro(200, "Esconde Sprite Magias", function() end)
if not storage.configs.hideSprites then
	return
end
onAddThing(function(tile, thing)
	if sprh.isOff() then
		return
	end
	if thing:isEffect() then
		thing:hide()
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- FPS Button
UI.Button("5 fps", function()
	modules.client_options.setOption("backgroundFrameRate", 5)
end)
UI.Button("200 fps", function()
	modules.client_options.setOption("backgroundFrameRate", 200)
end)

--------------------------------------------------------------------------------------------------------------------------
