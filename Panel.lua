do
	local addon, namespace = ...
	_G[addon] = _G[addon] or {}
	setfenv(1, setmetatable(namespace, { __index = _G }))
end

PANELSIZE = 20

panel = CreateFrame("Frame", nil, UIParent)
panel:SetHeight(PANELSIZE)
panel:SetPoint("BOTTOMLEFT", 0, PANELSIZE / 2)
panel:SetPoint("BOTTOMRIGHT", 0, PANELSIZE / 2)
panel:SetBackdrop({ bgFile = [[Interface\BUTTONS\White8x8]] })
panel:SetBackdropColor(0, 0, 0, 0.8)
