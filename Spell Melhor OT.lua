-- Script OTC para Tibia
-- Configurações de cooldown e prioridades

local config = {
	runa = {
		enabled = true,
		itemId = 3155, -- ID da runa (ex: 3155 = SD, ajuste conforme sua runa)
		cooldown = 2000, -- 2 segundos em ms
		lastUse = 0,
		priority = 1,
		useRune = true,
	},
	rpSafado = {
		enabled = true,
		spell = "rp safado",
		cooldown = 2000, -- 2 segundos em ms
		lastUse = 0,
		priority = 2,
	},
	utitoTempoSan = {
		enabled = true,
		spell = "utito tempo san",
		cooldown = 1000, -- Verificação de buff
		lastUse = 0,
		priority = 3,
	},
	capotaNoia = {
		enabled = true,
		spell = "capota noia",
		cooldown = 1000, -- 1 segundo em ms
		lastUse = 0,
		priority = 4,
	},
}

-- Função para verificar se há target
local function hasTarget()
	return g_game.getAttackingCreature() ~= nil
end

-- Função para usar spell/runa
local function useSpell(spell)
	g_game.talk(spell)
end

-- Função para usar runa por ID
local function useRune(itemId)
	local target = g_game.getAttackingCreature()
	if not target then
		return false
	end

	-- Procura a runa no inventário
	local player = g_game.getLocalPlayer()
	if not player then
		return false
	end

	local item = g_game.findPlayerItem(itemId, -1)
	if item then
		g_game.useWith(item, target)
		return true
	end
	return false
end

-- Função principal do script
local function combat()
	local currentTime = os.mtime()
	local target = hasTarget()

	-- Prioridade 1: Runa (apenas com target)
	if config.runa.enabled and target then
		if (currentTime - config.runa.lastUse) >= config.runa.cooldown then
			if useRune(config.runa.itemId) then
				config.runa.lastUse = currentTime
			end
			return
		end
	end

	-- Prioridade 2: RP Safado (apenas com target)
	if config.rpSafado.enabled and target then
		if (currentTime - config.rpSafado.lastUse) >= config.rpSafado.cooldown then
			useSpell(config.rpSafado.spell)
			config.rpSafado.lastUse = currentTime
			return
		end
	end

	-- Prioridade 3: Utito Tempo San (sem buff)
	if config.utitoTempoSan.enabled and not hasPartyBuff() then
		if (currentTime - config.utitoTempoSan.lastUse) >= config.utitoTempoSan.cooldown then
			useSpell(config.utitoTempoSan.spell)
			config.utitoTempoSan.lastUse = currentTime
			return
		end
	end

	-- Prioridade 4: Capota Noia (apenas com target)
	if config.capotaNoia.enabled and target then
		if (currentTime - config.capotaNoia.lastUse) >= config.capotaNoia.cooldown then
			useSpell(config.capotaNoia.spell)
			config.capotaNoia.lastUse = currentTime
			return
		end
	end
end

-- Macro principal
macro(100, function()
	if not g_game.isOnline() then
		return
	end
	combat()
end)
