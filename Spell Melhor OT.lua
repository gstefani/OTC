-- Script OTC para Tibia
-- Configurações de cooldown e prioridades

local config = {
	runa = {
		enabled = true,
		itemId = 55381, -- ID da runa (ex: 3155 = SD, ajuste conforme sua runa)
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
	local now = g_clock.millis()
	local target = hasTarget()

	-- Prioridade 1: Runa (apenas com target)
	if config.runa.enabled and target then
		if (now - config.runa.lastUse) >= config.runa.cooldown then
			if useRune(config.runa.itemId) then
				config.runa.lastUse = now
			end
			return
		end
	end

	-- Prioridade 2: RP Safado (apenas com target)
	if config.rpSafado.enabled and target then
		if (now - config.rpSafado.lastUse) >= config.rpSafado.cooldown then
			useSpell(config.rpSafado.spell)
			config.rpSafado.lastUse = now
			return
		end
	end

	-- Prioridade 3: Utito Tempo San (sem buff)
	if config.utitoTempoSan.enabled and not hasPartyBuff() then
		if (now - config.utitoTempoSan.lastUse) >= config.utitoTempoSan.cooldown then
			useSpell(config.utitoTempoSan.spell)
			config.utitoTempoSan.lastUse = now
			return
		end
	end

	-- Prioridade 4: Capota Noia (apenas com target)
	if config.capotaNoia.enabled and target then
		if (now - config.capotaNoia.lastUse) >= config.capotaNoia.cooldown then
			useSpell(config.capotaNoia.spell)
			config.capotaNoia.lastUse = now
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

-- Comandos para ativar/desativar spells individualmente
onTalk(function(name, level, mode, text, channelId, pos)
	if name ~= g_game.getCharacterName() then
		return
	end

	local cmd = text:lower()

	if cmd == "!runa on" then
		config.runa.enabled = true
		print("Runa ativada")
	elseif cmd == "!runa off" then
		config.runa.enabled = false
		print("Runa desativada")
	elseif cmd == "!rp on" then
		config.rpSafado.enabled = true
		print("RP Safado ativado")
	elseif cmd == "!rp off" then
		config.rpSafado.enabled = false
		print("RP Safado desativado")
	elseif cmd == "!utito on" then
		config.utitoTempoSan.enabled = true
		print("Utito Tempo San ativado")
	elseif cmd == "!utito off" then
		config.utitoTempoSan.enabled = false
		print("Utito Tempo San desativado")
	elseif cmd == "!capota on" then
		config.capotaNoia.enabled = true
		print("Capota Noia ativado")
	elseif cmd == "!capota off" then
		config.capotaNoia.enabled = false
		print("Capota Noia desativado")
	end
end)
