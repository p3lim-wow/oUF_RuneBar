--[[

	Elements handled:
	 .RuneBar [fontstring or table]

	FontString only:
	- space: The space between each "counter". (Default: " ")
	- symbol: The symbol used when cooldowns are over. (Default: "*")
	- interval: The time offset used for the update script. (Default: 0.5)

	StatusBar only:
	- :PostUpdate(event, rune, usable)
--]]

local unpack = unpack
local floor = math.floor
local format = string.format

local OnUpdateBar, OnUpdateText
do
	local total = 0
	function OnUpdateText(self, elapsed)
		total = total + elapsed

		if(total >= (self.RuneBar.interval or 0.5)) then
			self:UpdateElement('RuneBar')
			total = 0
		end
	end

	function OnUpdateBar(self, rune)
		local start, duration, ready = GetRuneCooldown(rune)

		if(ready) then
			self:SetValue(1)
			self:SetScript('OnUpdate', nil)
		else
			self:SetValue((GetTime() - start) / duration)
		end
	end
end	

local function UpdateStatusBar(self, event, rune, usable)
	if(rune and not usable and GetRuneType(rune)) then
		self.RuneBar[rune]:SetScript('OnUpdate', function(self) OnUpdateBar(self, rune) end)
	end

	if(self.RuneBar.PostUpdate) then self.RuneBar:PostUpdate(event, rune, usable) end
end

local function Update(self)
	local bar = self.RuneBar
	if(#bar == 0) then
		local text = ''
		for i = 1, 6 do
			local start, duration, ready = GetRuneCooldown(i)
			local r, g, b = unpack(bar.colors[GetRuneType(i)])

			text = format('%s|cff%02x%02x%02x%s%s|r', text, r * 255, g * 255, b * 255, ready and (bar.symbol or '*') or floor(duration - floor(GetTime() - start)), i ~= 6 and (bar.space or ' ') or '')
		end

		bar:SetText(text)
	else
		for i = 1, 6 do
			local runetype = GetRuneType(i)
			if(runetype) then
				bar[i]:SetStatusBarColor(unpack(bar.colors[runetype]))
			end
		end
	end
end

local function Enable(self, unit)
	local bar = self.RuneBar
	if(bar and unit == 'player' and select(2, UnitClass('player')) == 'DEATHKNIGHT') then
		local c = self.colors.runes or {}
		bar.colors = {c[1] or {0.77, 0.12, 0.23}, c[2] or {0.3, 0.8, 0.1}, c[3] or {0, 0.4, 0.7}, c[4] or {0.8, 0.8, 0.8}}

		self:RegisterEvent('RUNE_TYPE_UPDATE', Update)
		self:RegisterEvent('RUNE_POWER_UPDATE', #bar == 0 and Update or UpdateStatusBar)

		if(#bar == 0) then
			CreateFrame('Frame'):SetScript('OnUpdate', function(_, elapsed) OnUpdateText(self, elapsed) end)
		end

		RuneFrame:Hide()

		return true
	end
end

local function Disable(self)
	local bar = self.RuneBar
	if(bar) then
		self:RegisterEvent('RUNE_TYPE_UPDATE', Update)

		if(#bar == 0) then
			self:UnregisterEvent('RUNE_POWER_UPDATE', Update)
			dummy:SetScript('OnUpdate', nil)
		else
			self:UnregisterEvent('RUNE_POWER_UPDATE', UpdateStatusBar)
		end

		RuneFrame:Show()
	end
end

oUF:AddElement('RuneBar', Update, Enable, Disable)