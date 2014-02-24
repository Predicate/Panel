do
	local addon, namespace = ...
	_G[addon] = _G[addon] or {}
	setfenv(1, setmetatable(namespace, { __index = _G }))
end

local PADDING, MAXWIDTH, MAXBUTTONWIDTH = 3, panel:GetWidth() - 50, panel:GetWidth()/6

status = CreateFrame("Frame", nil, panel)
status:SetFrameStrata("HIGH")
status:SetHeight(PANELSIZE)
status:SetPoint("RIGHT", -1 * PADDING, 0)

local buttons = {}
local function updateDisplay()
	local totalwidth = 0
	for n, b in pairs(buttons) do
		b:SetPoint("LEFT", totalwidth, 0)
		local w = b.label:GetStringWidth()
		if w == 0 then --hack for blizz bug
			local f = CreateFrame("Frame")
			f:SetScript("OnUpdate", function(self)
				updateDisplay()
				self:SetScript("OnUpdate", nil)
			end)
			return
		end
		w = math.min(w + PANELSIZE + PADDING*2, MAXBUTTONWIDTH)
		b:SetWidth(w)
		totalwidth = totalwidth + w
	end
	status:SetWidth(math.min(totalwidth, MAXWIDTH))
	status:SetScript("OnUpdate", nil)
end
status:SetScript("OnUpdate", updateDisplay)

local function _IconChanged(self, _, _, _, iconpath) self.icon:SetTexture(iconpath) end
local function _TextChanged(self, _, _, _, newtext)
	self:SetText(newtext)
	status:SetScript("OnUpdate", updateDisplay)
end
local function _OnClickChanged(self, _, _, _, onclick) self:SetScript("OnClick", onclick) end


local function addStatusItem(name, iconpath, dobj)
	if buttons[name] then return end
	local b = CreateFrame("Button", nil, status)
	b:SetHeight(PANELSIZE)
	local icon = b:CreateTexture()
	b.icon = icon
	icon:SetHeight(PANELSIZE - PADDING)
	icon:SetWidth(PANELSIZE - PADDING)
	icon:SetPoint("LEFT", PADDING, 0)
	icon:SetTexture(iconpath)

	local label = b:CreateFontString()
	b.label = label
	label:SetPoint("LEFT", icon, "RIGHT", PADDING, 0)
	label:SetPoint("RIGHT", -1*PADDING, 0)
	label:SetJustifyH("LEFT")
	label:SetFont([[Fonts/ARIALN.TTF]], PANELSIZE * .75)
	label:SetShadowOffset(1, -1)
	label:SetText(dobj.text or name)
	b:SetFontString(label)

	b.name = name
	b.OnClick = dobj.OnClick
	b.IconChanged = _IconChanged
	b.TextChanged = _TextChanged
	b.OnClickChanged = _OnClickChanged

	b:SetScript("OnEnter", dobj.OnEnter)
	b:SetScript("OnLeave", dobj.OnLeave)
	b:SetScript("OnClick", dobj.OnClick)

	buttons[name] = b
	status:SetScript("OnUpdate", updateDisplay)
	return b
end

local function removeStatusItem(name)
	buttons[name]:Hide()
	buttons[name] = nil
	status:SetScript("OnUpdate", updateDisplay)
end

local function newDataObject(name, dobj)
	if dobj.type ~= "data source" then return end
	local frame = addStatusItem(name, dobj.icon, dobj)
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_icon", "IconChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_text", "TextChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_OnClick", "OnClickChanged")
end

for name, dobj in DataRegistry.DataObjectIterator() do
	if dobj.type == "data source" then newDataObject(name, dobj) end
end
DataRegistry.RegisterCallback(status, "DataRegistry_DataObjectCreated", function(_, name, dobj)
	if dobj.type == "data source" then newDataObject(name, dobj) end
end)
DataRegistry.RegisterCallback(status, "DataRegistry_AttributeChanged__type", function(_, name, _, v, dobj)
	if buttons[name] then
		removeStatusItem(name)
	elseif v == "data source" then
		newDataObject(name, dobj)
	end
end)
DataRegistry.RegisterCallback(status, "DataRegistry_DataObjectDestroyed", function(event, name)
	if buttons[name] then removeStatusItem(name) end
end)
