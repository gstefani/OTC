setDefaultTab("Tools")

-- =========================
-- UI: Setup Window
-- =========================
g_ui.loadUIFromString([[
ExtrasWindow < MainWindow
  !text: tr('SCRIPTS')
  size: 440 360
  padding: 25

  VerticalScrollBar
    id: contentScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: separator.top
    step: 28
    pixels-scroll: true
    margin-right: -10
    margin-top: 5
    margin-bottom: 5

  ScrollablePanel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: separator.top
    vertical-scrollbar: contentScroll
    margin-bottom: 10

    Panel
      id: left
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.horizontalCenter
      margin-top: 5
      margin-left: 10
      margin-right: 10
      layout:
        type: verticalBox
        fit-children: true

    Panel
      id: right
      anchors.top: parent.top
      anchors.left: parent.horizontalCenter
      anchors.right: parent.right
      margin-top: 5
      margin-left: 10
      margin-right: 10
      layout:
        type: verticalBox
        fit-children: true

    VerticalSeparator
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: parent.horizontalCenter

  HorizontalSeparator
    id: separator
    anchors.right: parent.right
    anchors.left: parent.left
    anchors.bottom: closeButton.top
    margin-bottom: 8

  Button
    id: closeButton
    !text: tr('Close')
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 45 21
    margin-right: 5
]])

ExtrasWindow = UI.createWindow("ExtrasWindow", rootWidget)
ExtrasWindow:hide()
ExtrasWindow.closeButton.onClick = function()
	ExtrasWindow:hide()
end

-- LABEL --
UI.Label("Scripts Custom"):setColor("orange")

-- Button Setup
local ui = setupUI([[
Panel
  height: 19
  Button
    id: open
    anchors.fill: parent
    text: Scrips
]])
ui.open.onClick = function()
	ExtrasWindow:show()
	ExtrasWindow:raise()
	ExtrasWindow:focus()
end

local leftPanel = ExtrasWindow.content.left
local rightPanel = ExtrasWindow.content.right

-- =========================
-- Storage
-- =========================
storage.configs = storage.configs or {}

-- Helper toggle
local function addToggle(id, text, panel)
	storage.configs[id] = storage.configs[id] or false
	local sw = UI.createWidget("BotSwitch", panel)
	sw:setText(text)
	sw:setOn(storage.configs[id])
	sw.onClick = function(w)
		storage.configs[id] = not storage.configs[id]
		w:setOn(storage.configs[id])
	end
end

-- =========================
-- SETUP UI (ALL INPUTS HERE)
-- =========================

-- LEFT
addToggle("huntWalkSmarter", "Hunt Walk Smarter", leftPanel)
addToggle("runeOnTarget", "Rune On Target", leftPanel)

UI.createWidget("Label", leftPanel):setText("Runa no Target:")
local runeEdit = UI.createWidget("TextEdit", leftPanel)
runeEdit:setText(storage.runeTarget or "3150")
runeEdit.onTextChange = function(_, text)
	storage.runeTarget = text
end

addToggle("autoLootOnLook", "Auto Loot On Look", leftPanel)

addToggle("autoBuff", "Auto Buff", leftPanel)
UI.createWidget("Label", leftPanel):setText("Buff Spell:")
local buffEdit = UI.createWidget("TextEdit", leftPanel)
buffEdit:setText(storage.buffName or "Power Up")
buffEdit.onTextChange = function(_, text)
	storage.buffName = text
end

addToggle("abrirMainBp", "Abrir Main BP", leftPanel)

-- RIGHT
addToggle("revidarPk", "Revidar PK", rightPanel)
addToggle("turnTarget", "Turn Target Canudo", rightPanel)

addToggle("manaTrainer", "Mana Trainer Hunt", rightPanel)
UI.createWidget("Label", rightPanel):setText("Spell, Porcentagem:")
local manaEdit = UI.createWidget("TextEdit", rightPanel)
manaEdit:setText(storage.manaTrainer and storage.manaTrainer.spellAndPercent or "power down, 80")
manaEdit.onTextChange = function(_, text)
	storage.manaTrainer = storage.manaTrainer or {}
	storage.manaTrainer.spellAndPercent = text
end

addToggle("bugMapMouse", "Bug Map Mouse", rightPanel)
addToggle("bugMapWasd", "Bug Map WASD", rightPanel)
addToggle("hideSprites", "Esconder Sprite Magias", rightPanel)

-- =========================
-- SCRIPTS (NO UI)
-- =========================

-- Hunt Walk Smarter
macro(200, function()
	if not storage.configs.huntWalkSmarter then
		return
	end
	if g_game:isAttacking() then
		CaveBot.Config.values["walkDelay"] = 80
	else
		CaveBot.Config.values["walkDelay"] = 10
	end
	CaveBot.save()
end)

--------------------------------------------------------------------------------------------------------------------------

-- Rune on Target
macro(200, function()
	if not storage.configs.runeOnTarget then
		return
	end
	if not g_game.isAttacking() then
		return
	end
	local t = g_game.getAttackingCreature()
	if not t or not t:canShoot() then
		return
	end
	useWith(tonumber(storage.runeTarget or 3150), t)
	delay(500)
end)

--------------------------------------------------------------------------------------------------------------------------

-- Auto Buff
macro(200, function()
	if not storage.configs.autoBuff then
		return
	end
	if hasPartyBuff() then
		return
	end
	say(storage.buffName or "Power Up")
end)

--------------------------------------------------------------------------------------------------------------------------

-- Mana Trainer
local function parse(text)
	local s, p = tostring(text):match("([^,]+),?%s*(%d*)")
	return (s or "power down"):trim(), math.max(1, math.min(100, tonumber(p) or 80))
end

macro(200, function()
	if not storage.configs.manaTrainer then
		return
	end
	local spell, pct = parse(storage.manaTrainer.spellAndPercent or "power down, 80")
	if manapercent() >= pct then
		say(spell)
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Bug Map Mouse
macro(20, function()
	if not storage.configs.bugMapMouse then
		return
	end
	local tile = getTileUnderCursor()
	if tile and g_mouse.isPressed(4) then
		g_game.use(tile:getTopUseThing())
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Bug Map WASD
local function checkPos(x, y)
	local p = g_game.getLocalPlayer():getPosition()
	p.x = p.x + x
	p.y = p.y + y
	local t = g_map.getTile(p)
	if t then
		g_game.use(t:getTopUseThing())
	end
end
local consoleModule = modules.game_console
macro(50, function()
	if not storage.configs.bugMapWasd then
		return
	end
	if consoleModule:isChatEnabled() then
		return
	end
	if modules.corelib.g_keyboard.isKeyPressed("w") then
		checkPos(0, -5)
	elseif modules.corelib.g_keyboard.isKeyPressed("e") then
		checkPos(3, -3)
	elseif modules.corelib.g_keyboard.isKeyPressed("d") then
		checkPos(5, 0)
	elseif modules.corelib.g_keyboard.isKeyPressed("c") then
		checkPos(3, 3)
	elseif modules.corelib.g_keyboard.isKeyPressed("s") then
		checkPos(0, 5)
	elseif modules.corelib.g_keyboard.isKeyPressed("z") then
		checkPos(-3, 3)
	elseif modules.corelib.g_keyboard.isKeyPressed("a") then
		checkPos(-5, 0)
	elseif modules.corelib.g_keyboard.isKeyPressed("q") then
		checkPos(-3, -3)
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- Hide Sprites
macro(200, function() end)
onAddThing(function(_, thing)
	if not storage.configs.hideSprites then
		return
	end
	if thing:isEffect() then
		thing:hide()
	end
end)

--------------------------------------------------------------------------------------------------------------------------

-- FPS Button
UI.Label("FPS Button"):setColor("orange")
UI.Button("5 fps", function()
	modules.client_options.setOption("backgroundFrameRate", 5)
end)
UI.Button("200 fps", function()
	modules.client_options.setOption("backgroundFrameRate", 200)
end)

--------------------------------------------------------------------------------------------------------------------------
