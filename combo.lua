UI.Separator()
setDefaultTab("News")
local lbT = UI.Label("Config Combo Spells")
lbT:setColor("orange")

local _combo = {
	spellCount = 4, -- magias para monstros
	spellCountPlayers = 4, -- magias para players
}

storage.uCombo = storage.uCombo or {}
storage.uComboPlayers = storage.uComboPlayers or {}
storage.areaSpellData = storage.areaSpellData or { spell = "", distance = 2, monsterCount = 1 } -- Adicionado monsterCount
storage.ignorePlayersOnScreen = storage.ignorePlayersOnScreen or false
storage.comboMacroActive = storage.comboMacroActive or false

-- Função para verificar se há players visíveis na tela
local function hasPlayersOnScreen()
	local spectators = g_map.getSpectators(pos(), false)
	for _, creature in ipairs(spectators) do
		if creature:isPlayer() and creature ~= g_game.getLocalPlayer() then
			return true
		end
	end
	return false
end

-- Função para calcular a distância entre duas posições
local function getDistance(p1, p2)
	return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

-- Função para contar monstros dentro da distância especificada
local function countMonstersInRange(distance)
	local count = 0
	local playerPos = g_game.getLocalPlayer():getPosition()
	local spectators = g_map.getSpectators(pos(), false)

	for _, creature in ipairs(spectators) do
		if creature:isMonster() then
			local creaturePos = creature:getPosition()
			local creatureDistance = getDistance(playerPos, creaturePos)

			if creatureDistance <= distance then
				count = count + 1
			end
		end
	end

	return count
end

-- Função para extrair a spell, a distância e a quantidade mínima de monstros da entrada do usuário
local function parseAreaSpellInput(input)
	local spell = ""
	local distance = 2 -- valor padrão
	local monsterCount = 1 -- valor padrão

	-- Separar a string pela vírgula
	local parts = string.split(input, ",")
	if #parts >= 1 then
		spell = parts[1]:trim() -- Remove espaços extras
		if #parts >= 2 then
			-- Tenta converter o segundo valor para número (distância)
			local distVal = tonumber(parts[2]:trim())
			if distVal and distVal > 0 then
				distance = distVal
			end

			if #parts >= 3 then
				-- Tenta converter o terceiro valor para número (quantidade de monstros)
				local countVal = tonumber(parts[3]:trim())
				if countVal and countVal > 0 then
					monsterCount = countVal
				end
			end
		end
	end

	return spell, distance, monsterCount
end

-- Adicionar a função split se não existir
if not string.split then
	function string.split(str, sep)
		local result = {}
		local pattern = string.format("([^%s]+)", sep)
		for segment in string.gmatch(str, pattern) do
			table.insert(result, segment)
		end
		return result
	end
end

-- Adicionar a função trim se não existir
if not string.trim then
	function string.trim(s)
		return s:match("^%s*(.-)%s*$")
	end
end

-- Macro principal, roda só se o controle estiver ativo
comboMacro = macro(200, function()
	if not storage.comboMacroActive then
		return
	end
	local target = g_game.getAttackingCreature()
	if not target then
		return
	end

	if target:isPlayer() then
		-- Combo para players
		for i, spell in ipairs(storage.uComboPlayers) do
			if spell ~= "" and g_game.isAttacking() then
				say(spell)
			end
		end
	else
		-- PRIORIDADE: Verificar condições para usar a spell de área primeiro
		local useAreaSpell = false

		if storage.areaSpellData.spell ~= "" and g_game.isAttacking() then
			-- Verificar se deve ignorar players ou se não há players na tela
			if storage.ignorePlayersOnScreen or not hasPlayersOnScreen() then
				-- Verificar distância do monstro
				local playerPos = g_game.getLocalPlayer():getPosition()
				local targetPos = target:getPosition()
				local distance = getDistance(playerPos, targetPos)

				-- Contar monstros dentro da distância configurada
				local monstersInRange = countMonstersInRange(storage.areaSpellData.distance)

				-- Usar spell de área se o monstro estiver dentro da distância configurada
				-- E se houver pelo menos a quantidade mínima de monstros configurada
				if distance <= storage.areaSpellData.distance and monstersInRange >= storage.areaSpellData.monsterCount then
					say(storage.areaSpellData.spell)
					useAreaSpell = true
				end
			end
		end

		-- Só executa o combo normal se não usou a spell de área
		if not useAreaSpell then
			-- Combo para monstros
			for i, spell in ipairs(storage.uCombo) do
				if spell ~= "" and g_game.isAttacking() then
					say(spell)
				end
			end
		end
	end
end)
comboMacro:setOn(storage.comboMacroActive)

-- Ícone moveable e que mantém a posição após relogar
local comboIcon = addIcon("comboToggle", { text = "Combo\nSpells", switchable = false, moveable = true }, function()
	storage.comboMacroActive = not storage.comboMacroActive
	comboMacro:setOn(storage.comboMacroActive)
end)

comboIcon:setSize({ height = 30, width = 60 })
comboIcon.text:setFont("verdana-11px-rounded")

-- Macro visual: muda a cor do texto ON/verde ou OFF/vermelho
macro(200, function()
	if storage.comboMacroActive then
		comboIcon.text:setColoredText({ "Combo\nSpells\n", "white", "ON", "green" })
	else
		comboIcon.text:setColoredText({ "Combo\nSpells\n", "white", "OFF", "red" })
	end
end)

-- Inputs para spells de monstros
UI.Label("Spells para monstros"):setColor("orange")
for i = 1, _combo.spellCount do
	addTextEdit("id_monstro" .. i, storage.uCombo[i] or "", function(self, text)
		storage.uCombo[i] = text
	end)
end

-- Input para spell de área com condições especiais
UI.Label("Spell Area\nSpell,Distancia,QtdMonstros"):setColor("yellow")
local areaSpellText = ""
if storage.areaSpellData.spell ~= "" then
	areaSpellText = storage.areaSpellData.spell .. "," .. tostring(storage.areaSpellData.distance) .. "," .. tostring(storage.areaSpellData.monsterCount)
end
addTextEdit("id_area_spell", areaSpellText, function(self, text)
	local spell, distance, monsterCount = parseAreaSpellInput(text)
	storage.areaSpellData = {
		spell = spell,
		distance = distance,
		monsterCount = monsterCount,
	}
end)

-- Botão para alternar ignorar players na tela
UI.Label("Ignorar Players P/ Spell em Area"):setColor("yellow")
local ignorePlayersButton = UI.Button("Ignorar players: " .. (storage.ignorePlayersOnScreen and "SIM" or "NAO"))
ignorePlayersButton.onClick = function(widget)
	storage.ignorePlayersOnScreen = not storage.ignorePlayersOnScreen
	widget:setText("Ignorar players: " .. (storage.ignorePlayersOnScreen and "SIM" or "NAO"))
end

-- Inputs para spells de players
UI.Label("Spells para players"):setColor("red")
for i = 1, _combo.spellCountPlayers do
	addTextEdit("id_player" .. i, storage.uComboPlayers[i] or "", function(self, text)
		storage.uComboPlayers[i] = text
	end)
end
