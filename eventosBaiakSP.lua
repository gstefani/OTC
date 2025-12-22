local proxEvento = UI.Label("Próximo evento:")
proxEvento:setColor("#e4ff00")

local nextEvent = UI.Label("Aguardando próximo evento")
nextEvent:setColor("#00fff0")

local eventos = {
	{ tipo = "Invasão de Bosses", horarios = { "10:00", "15:00", "17:00", "20:00", "03:00", "07:00", "12:00" } },
	{ tipo = "Invasão de EXP", horarios = { "13:40", "15:40", "19:40", "22:40", "02:40", "05:40", "08:40", "11:40" } },
	{ tipo = "ClickUP Event", horarios = { "13:00", "18:00", "22:00" } },
}

local function atualizarEvento()
	local minutosAgora = (os.date("*t").hour * 60) + os.date("*t").min
	local proximoEvento = { tipo = "NIL", horario = "00:00", diferenca = 1440 }

	for _, evento in ipairs(eventos) do
		for _, horario in ipairs(evento.horarios) do
			local minutosEvento = (tonumber(horario:sub(1, 2)) * 60) + tonumber(horario:sub(4, 5))
			local diferenca = (minutosEvento - minutosAgora + 1440) % 1440
			if diferenca < proximoEvento.diferenca then
				proximoEvento = { tipo = evento.tipo, horario = horario, diferenca = diferenca }
			end
		end
	end

	nextEvent:setText(proximoEvento.tipo .. " às " .. proximoEvento.horario)
end

macro(1000, "", atualizarEvento)
atualizarEvento()
