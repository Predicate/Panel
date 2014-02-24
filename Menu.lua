do
	local addon, namespace = ...
	_G[addon] = _G[addon] or {}
	setfenv(1, setmetatable(namespace, { __index = _G }))
end

local MENUITEMSIZE, PADDING = 16, 5

menu = CreateFrame("Button", nil, panel)
menu:SetFrameStrata("HIGH")
menu:SetHeight(32)
menu:SetWidth(32)
menu:SetPoint("LEFT")
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
menucontainer:SetBackdropColor(0, 0, 0, 0.8)
menucontainer:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, 1)


local buttons, buttonorder = {}, {}

local needSort
local function toggleMenu()
	if menucontainer:IsShown() then
		menucontainer:Hide()
		menu:SetButtonState("NORMAL", false)
	else
		if needSort then
			table.sort(buttonorder)
			menucontainer:SetHeight(#buttonorder * (MENUITEMSIZE + PADDING) + PADDING)
			local maxwidth = 0
			for i, name in ipairs(buttonorder) do
				buttons[name]:ClearAllPoints()
				buttons[name]:SetPoint("TOPLEFT", menucontainer, PADDING, -1*(MENUITEMSIZE + PADDING) * (i - 1) - PADDING)
				buttons[name]:SetPoint("TOPRIGHT", menucontainer, -1*PADDING, -1 * (MENUITEMSIZE + PADDING) * (i - 1) - PADDING)
				maxwidth = math.max(maxwidth, buttons[name].label:GetStringWidth())
			end
			if maxwidth ~= 0 then
				menucontainer:SetWidth(math.min(maxwidth + MENUITEMSIZE + 3*PADDING, 300))
			else --hack for blizz bug
				menucontainer:SetWidth(150)
				local f = CreateFrame("Frame")
				f:SetScript("OnUpdate", function(self)
					local maxwidth = 0
					for _, name in ipairs(buttonorder) do
						maxwidth = math.max(maxwidth, buttons[name].label:GetStringWidth())
					end
					menucontainer:SetWidth(math.min(maxwidth + MENUITEMSIZE + 3*PADDING, 300))
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

local function _IconChanged(self, _, _, _, iconpath) self.icon:SetTexture(iconpath) end
local function _LabelChanged(self, _, _, _, newlabel)
	self:SetText(newlabel)
	needSort = true
end
local function _DescChanged(self, _, _, _, newdesc) self.desc = newdesc end
local function _OnClickChanged(self, _, _, _, onclick) self.OnClick = onclick end

local function _OnEnter(self)
	if self.desc then
		GameTooltip:SetOwner(self)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(self.name, 1, 1, 1)
		GameTooltip:AddLine(self.desc)
		GameTooltip:Show()
	end
end
local function _OnLeave(self) GameTooltip:Hide() end
local function _OnClick(self, ...)
	toggleMenu()
	if self.OnClick then self.OnClick(...) end
end

local function addMenuItem(name, iconpath, dobj)
	if buttons[name] then return end
	local b = CreateFrame("Button", nil, menucontainer)
	b:SetHeight(MENUITEMSIZE)
	local icon = b:CreateTexture()
	b.icon = icon
	icon:SetHeight(MENUITEMSIZE)
	icon:SetWidth(MENUITEMSIZE)
	icon:SetPoint("LEFT")
	icon:SetTexture(iconpath)

	local label = b:CreateFontString()
	b.label = label
	label:SetPoint("LEFT", icon, "RIGHT", PADDING, 0)
	label:SetJustifyH("LEFT")
	label:SetFont([[Fonts/ARIALN.TTF]], MENUITEMSIZE)
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

local function newDataObject(_, name, dobj)
	if dobj.type ~= "launcher" then return end
	local frame = addMenuItem(name, dobj.icon, dobj)
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_icon", "IconChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_label", "LabelChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_desc", "DescChanged")
	DataRegistry.RegisterCallback(frame, "DataRegistry_AttributeChanged_"..name.."_OnClick", "OnClickChanged")
end

for name, dobj in DataRegistry.DataObjectIterator() do
	if dobj.type == "launcher" then newDataObject(nil, name, dobj) end
end
DataRegistry.RegisterCallback(menucontainer, "DataRegistry_DataObjectCreated", newDataObject)
DataRegistry.RegisterCallback(menucontainer, "DataRegistry_AttributeChanged__type", function(_, name, _, v, dobj)
	if buttons[name] then
		removeMenuItem(name)
	elseif v == "launcher" then
		newDataObject(nil, name, dobj)
	end
end)
DataRegistry.RegisterCallback(menucontainer, "DataRegistry_DataObjectDestroyed", function(event, name)
	if buttons[name] then removeMenuItem(name) end
end)
