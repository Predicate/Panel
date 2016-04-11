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
local onetimeframe
local function updateDisplay()
	local totalwidth = 0
	for n, b in pairs(buttons) do
		b:SetPoint("LEFT", totalwidth, 0)
		local w = b.label:GetStringWidth()
		if w == 0 and not onetimeframe then --hack for blizz bug
			onetimeframe = CreateFrame("Frame")
			onetimeframe:SetScript("OnUpdate", function()
				updateDisplay()
				onetimeframe:SetScript("OnUpdate", nil)
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

local function tooltip_OnEnter(self)
	self.tooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	if self.OnTooltipShow then self.OnTooltipShow(self.tooltip) end
	self.tooltip:Show()
end
local function tooltip_OnLeave(self) self.tooltip:Hide() end

local function _TooltipChanged(self, _, _, _, _, dobj)
	if dobj.tooltip then
		self.tooltip = dobj.tooltip
		self:SetScript("OnEnter", tooltip_OnEnter)
		self:SetScript("OnLeave", tooltip_OnLeave)
	elseif dobj.OnEnter or dobj.OnLeave then
		self.tooltip = nil
		self:SetScript("OnEnter", dobj.OnEnter)
		self:SetScript("OnLeave", dobj.OnLeave)
	elseif dobj.OnTooltipShow then
		if not self.defaultTooltip then
			local tt = CreateFrame("GameTooltip", nil, self)
			tt:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			})
			tt:SetBackdropColor(0, 0, 0, 0.8)

			for i = 1, 10 do
				local left, right = tt:CreateFontString(), tt:CreateFontString()
				left:SetPoint("TOPLEFT", 10, -1 * (i * 14 - 4))
				right:SetPoint("TOPRIGHT", -10, -1 * (i * 14 - 4))
				left:SetFont([[Fonts/ARIALN.TTF]], 12)
				right:SetFont([[Fonts/ARIALN.TTF]], 12)
				tt:AddFontStrings(left, right)
			end
			self.defaultTooltip = tt
		end
		self.tooltip = self.defaultTooltip
		self.OnTooltipShow = dobj.OnTooltipShow
		self:SetScript("OnEnter", tooltip_OnEnter)
		self:SetScript("OnLeave", tooltip_OnLeave)
	end
end


local function addStatusItem(name, dobj)
	if buttons[name] then return end
	local b = CreateFrame("Button", nil, status)
	b:SetHighlightTexture([[Interface/QUESTFRAME/UI-QuestLogTitleHighlight]])
	b:GetHighlightTexture():SetVertexColor(1,1,1,0.3)

	b:SetHeight(PANELSIZE)
	local icon = b:CreateTexture()
	b.icon = icon
	icon:SetHeight(PANELSIZE - PADDING)
	icon:SetWidth(PANELSIZE - PADDING)
	icon:SetPoint("LEFT", PADDING, 0)

	local label = b:CreateFontString()
	b.label = label
	label:SetPoint("LEFT", icon, "RIGHT", PADDING, 0)
	label:SetPoint("RIGHT", -1*PADDING, 0)
	label:SetJustifyH("LEFT")
	label:SetFont([[Fonts/ARIALN.TTF]], PANELSIZE * .75)
	label:SetShadowOffset(1, -1)
	b:SetFontString(label)

	b.name = name
	b.IconChanged = _IconChanged
	b.TextChanged = _TextChanged
	b.OnClickChanged = _OnClickChanged
	b.TooltipChanged = _TooltipChanged

	_IconChanged(b, nil, nil, nil, dobj.icon)
	_TextChanged(b, nil, nil, nil, dobj.text or name)
	_OnClickChanged(b, nil, nil, nil, dobj.OnClick)
	_TooltipChanged(b, nil, nil, nil, nil, dobj)

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
	local frame = addStatusItem(name, dobj)
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_icon", "IconChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_text", "TextChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_tooltip", "TooltipChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_OnClick", "OnClickChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_OnEnter", "TooltipChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_OnLeave", "TooltipChanged")
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
