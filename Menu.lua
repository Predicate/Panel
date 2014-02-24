do
	local addon, namespace = ...
	_G[addon] = _G[addon] or {}
	setfenv(1, setmetatable(namespace, { __index = _G }))
end

local MENUITEMSIZE, PADDING, MAXWIDTH = 20, 6, panel:GetWidth() / 6

menu = CreateFrame("Button", nil, panel)
menu:SetFrameStrata("HIGH")
menu:SetHeight(PANELSIZE * 2)
menu:SetWidth(PANELSIZE * 2)
menu:SetPoint("LEFT", PADDING, 0)
local tex = menu:CreateTexture()
local pushedTex = menu:CreateTexture()
tex:SetAllPoints()
pushedTex:SetAllPoints()
pushedTex:SetVertexColor(0.5, 0.5, 0.5)
local faction = UnitFactionGroup("player")
if faction == "Alliance" or faction == "Horde" then
	tex:SetTexture([[Interface/WorldStateFrame/]]..faction..[[Icon]])
	pushedTex:SetTexture([[Interface/WorldStateFrame/]]..faction..[[Icon]])
else
	tex:SetTexture([[Interface/WorldMap/UI-World-Icon]])
	pushedTex:SetTexture([[Interface/WorldMap/UI-World-Icon]])
	local f = CreateFrame("Frame")
	f:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
	f:SetScript("OnEvent", function()
		tex:SetTexture([[Interface/WorldStateFrame/]]..UnitFactionGroup("player")..[[Icon]])
		pushedTex:SetTexture([[Interface/WorldStateFrame/]]..UnitFactionGroup("player")..[[Icon]])
	end)
end
menu:SetNormalTexture(tex)
menu:SetPushedTexture(pushedTex)

local menucontainer = CreateFrame("Frame", nil, menu)
menucontainer:Hide()
menucontainer:SetFrameStrata("MEDIUM")
menucontainer:SetBackdrop({ bgFile = [[Interface\BUTTONS\White8x8]] })
menucontainer:SetBackdropColor(0, 0, 0, 0.5)
menucontainer:SetPoint("BOTTOMLEFT", menu, "TOPLEFT", 0, -1*PANELSIZE/2)

local buttons, buttonorder = {}, {}

local needSort
local function toggleMenu()
	if menucontainer:IsShown() then
		menucontainer:Hide()
		menu:SetButtonState("NORMAL", false)
	else
		if needSort then
			table.sort(buttonorder)
			menucontainer:SetHeight(#buttonorder * (MENUITEMSIZE + PADDING) + PADDING*2)
			local maxwidth = 0
			for i, name in ipairs(buttonorder) do
				buttons[name]:ClearAllPoints()
				buttons[name]:SetPoint("TOPLEFT", menucontainer, 0, -1*(MENUITEMSIZE + PADDING) * (i - 1) - PADDING)
				buttons[name]:SetPoint("TOPRIGHT", menucontainer, 0, -1 * (MENUITEMSIZE + PADDING) * (i - 1) - PADDING)
				maxwidth = math.max(maxwidth, buttons[name].label:GetStringWidth())
			end
			if maxwidth ~= 0 then
				menucontainer:SetWidth(math.min(maxwidth + MENUITEMSIZE + 5*PADDING, MAXWIDTH))
			else --hack for blizz bug
				menucontainer:SetWidth(150)
				local f = CreateFrame("Frame")
				f:SetScript("OnUpdate", function(self)
					local maxwidth = 0
					for _, name in ipairs(buttonorder) do
						maxwidth = math.max(maxwidth, buttons[name].label:GetStringWidth())
					end
					menucontainer:SetWidth(math.min(maxwidth + MENUITEMSIZE + 5*PADDING, MAXWIDTH))
					self:SetScript("OnUpdate", nil)
				end)
			end
			needSort = nil
		end

		menucontainer:Show()
		menu:SetButtonState("PUSHED", true)
	end
end
menu:SetScript("OnClick", toggleMenu)

local hidetimer = 0
local function timerOnUpdate(_, elapsed)
	hidetimer = hidetimer + elapsed
	if hidetimer > 3 then
		toggleMenu()
		menu:SetScript("OnUpdate", nil)
	end
end
local function timerOnEnter()
	menu:SetScript("OnUpdate", nil)
end
local function timerOnLeave()
	if menucontainer:IsShown() then
		hidetimer = 0
		menu:SetScript("OnUpdate", timerOnUpdate)
	end
end
menu:SetScript("OnEnter", timerOnEnter)
menu:SetScript("OnLeave", timerOnLeave)
menucontainer:SetScript("OnEnter", timerOnEnter)
menucontainer:SetScript("OnLeave", timerOnLeave)

local function _IconChanged(self, _, _, _, iconpath) self.icon:SetTexture(iconpath) end
local function _LabelChanged(self, _, _, _, newlabel)
	self:SetText(newlabel)
	needSort = true
end
local function _DescChanged(self, _, _, _, newdesc) self.desc = newdesc end
local function _OnClickChanged(self, _, _, _, onclick) self.OnClick = onclick end

local function _OnEnter(self)
	timerOnEnter()
	GameTooltip:SetOwner(self)
	GameTooltip:ClearLines()
	if self.desc or self.label:GetStringWidth() > self.label:GetWidth() then
		GameTooltip:AddLine(self:GetText(), 1, 1, 1)
	end
	if self.desc then
		GameTooltip:AddLine(self.desc)
	end
	GameTooltip:Show()
end
local function _OnLeave(self)
	timerOnLeave()
	GameTooltip:Hide()
end
local function _OnClick(self, ...)
	toggleMenu()
	if self.OnClick then self.OnClick(...) end
end

local function addMenuItem(name, iconpath, dobj)
	if buttons[name] then return end
	local b = CreateFrame("Button", nil, menucontainer)
	b:SetHeight(MENUITEMSIZE + PADDING)
	b:SetHighlightTexture([[Interface/QUESTFRAME/UI-QuestLogTitleHighlight]])
	b:GetHighlightTexture():SetVertexColor(1,1,1,0.3)
	local icon = b:CreateTexture()
	b.icon = icon
	icon:SetHeight(MENUITEMSIZE)
	icon:SetWidth(MENUITEMSIZE)
	icon:SetPoint("LEFT", PADDING*2, 0)
	icon:SetTexture(iconpath)

	local label = b:CreateFontString()
	b.label = label
	label:SetPoint("LEFT", icon, "RIGHT", PADDING, 0)
	label:SetPoint("RIGHT", -1*PADDING, 0)
	label:SetJustifyH("LEFT")
	label:SetFont([[Fonts/ARIALN.TTF]], MENUITEMSIZE * .75)
	label:SetShadowOffset(1, -1)
	label:SetText(name)
	b:SetFontString(label)

	b.name = name
	b.desc = dobj.desc
	b.OnClick = dobj.OnClick
	b.IconChanged = _IconChanged
	b.LabelChanged = _LabelChanged
	b.DescChanged = _DescChanged
	b.OnClickChanged = _OnClickChanged

	b:SetScript("OnEnter", _OnEnter)
	b:SetScript("OnLeave", _OnLeave)
	b:SetScript("OnClick", _OnClick)

	buttons[name] = b
	buttonorder[#buttonorder+1] = name
	needSort = true
	return b
end

local function removeMenuItem(name)
	buttons[name]:Hide()
	buttons[name] = nil
	for i, v in ipairs(buttonorder) do
		if v == name then
			table.remove(buttonorder, i)
			needSort = true
			return
		end
	end
end

local function newDataObject(name, dobj)
	local frame = addMenuItem(name, dobj.icon, dobj)
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_icon", "IconChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_label", "LabelChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_desc", "DescChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_OnClick", "OnClickChanged")
end

for name, dobj in DataRegistry.DataObjectIterator() do
	if dobj.type == "launcher" then newDataObject(name, dobj) end
end
DataRegistry.RegisterCallback(menucontainer, "DataRegistry_DataObjectCreated", function(_, name, dobj)
	if dobj.type == "launcher" then newDataObject(name, dobj) end
end)
DataRegistry.RegisterCallback(menucontainer, "DataRegistry_AttributeChanged__type", function(_, name, _, v, dobj)
	if buttons[name] then
		removeMenuItem(name)
	elseif v == "launcher" then
		newDataObject(name, dobj)
	end
end)
DataRegistry.RegisterCallback(menucontainer, "DataRegistry_DataObjectDestroyed", function(event, name)
	if buttons[name] then removeMenuItem(name) end
end)
