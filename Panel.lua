do
	local addon, namespace = ...
	_G[addon] = _G[addon] or {}
	setfenv(1, setmetatable(namespace, { __index = _G }))
end


panel = CreateFrame("Frame", nil, UIParent)
panel:SetHeight(20)
panel:SetPoint("BOTTOMLEFT", 0, 6)
panel:SetPoint("BOTTOMRIGHT", 0, 6)
panel:SetBackdrop({ bgFile = [[Interface\BUTTONS\White8x8]] })
panel:SetBackdropColor(0, 0, 0, 0.8)
