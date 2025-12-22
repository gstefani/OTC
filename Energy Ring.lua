local s = {}

g_ui.loadUIFromString([[
PvPScriptsScrollBar < Panel
  height: 28
  margin-top: 3

  UIWidget
    id: text
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: center
    
  HorizontalScrollBar
    id: scroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 3
    minimum: 0
    maximum: 10
    step: 1

PvPScriptsItem < Panel
  height: 40
  margin-top: 10  
  UIWidget
    id: text
    anchors.left: parent.left
    anchors.verticalCenter: next.verticalCenter

  BotItem
    id: item
    anchors.top: parent.top
    anchors.right: parent.right
    
]])

local addScrollBar = function(id, title, min, max, defaultValue, dest, tooltip)
	local widget = UI.createWidget("PvPScriptsScrollBar", dest)
	widget.text:setTooltip(tooltip)
	widget.scroll.onValueChange = function(scroll, value)
		widget.text:setText(title .. value)
		if value == 0 then
			value = 1
		end
		storage[id] = value
	end
	widget.scroll:setRange(min, max)
	widget.scroll:setTooltip(tooltip)
	widget.scroll:setValue(storage[id] or defaultValue)
	widget.scroll.onValueChange(widget.scroll, widget.scroll:getValue())
end

local addItem = function(id, title, defaultItem, dest, tooltip)
	local widget = UI.createWidget("PvPScriptsItem", dest)
	widget:setId(id)
	widget.text:setText(title)
	widget.text:setTooltip(tooltip)
	widget.item:setTooltip(tooltip)
	widget.item:setItemId(storage[id] or defaultItem)
	widget.item.onItemChange = function(widget)
		storage[id] = widget:getItemId()
	end
	storage[id] = storage[id] or defaultItem
	return widget
end

addLabel()

addLabel("", "E-Ring"):setColor("#5DF2BD")
addScrollBar("ERingHPGreater", "Equipar E-Ring HP <= ", 0, 100, 90, nil, "")
addScrollBar("ERingHPLess", "Remover E-Ring HP >= ", 0, 100, 50, nil, "")
addItem("ERing", "Energy Ring", storage.ERing or 3051, nil, "")
addItem("ERingEquipped", "Ring Normal", storage.ERingEquipped or 3088, nil, "")

s.equipItem = function(normalId, activeId, slot)
	local item = getInventoryItem(slot)
	if item and item:getId() == activeId then
		return false
	end

	if g_game.getClientVersion() >= 870 then
		g_game.equipItemId(activeId)
		return true
	end

	local itemToEquip = findItem(activeId)
	if itemToEquip then
		moveToSlot(itemToEquip, slot, itemToEquip:getCount())
		return true
	end
end

s.m_main = macro(200, "Energy Ring", function()
	local hp = hppercent()
	local mp = manapercent()

	if hp <= storage.ERingHPGreater then
		s.equipItem(storage.ERingEquipped, storage.ERing, SlotFinger)
	elseif hp >= storage.ERingHPLess then
		s.equipItem(storage.ERing, storage.ERingEquipped, SlotFinger)
	end
end)
