local Castbars = LibStub("AceAddon-3.0"):NewAddon("Castbars", "AceConsole-3.0");

Castbars.SharedMedia = LibStub("LibSharedMedia-3.0");
Castbars.DoNothing = function() end;

Castbars.SpellToTicks = {
	-- Warlock
	[GetSpellInfo(689)] = 5, -- Drain Life
	[GetSpellInfo(1120)] = 5, -- Drain Soul
	[GetSpellInfo(5138)] = 5, -- Drain Mana
	[GetSpellInfo(5740)] = 4, -- Rain of Fire
	-- Druid
	[GetSpellInfo(740)] = 4, -- Tranquility
	[GetSpellInfo(16914)] = 10, -- Hurricane
	-- Priest
	[GetSpellInfo(15407)] = 3, -- Mind Flay
	[GetSpellInfo(48045)] = 5, -- Mind Sear
	[GetSpellInfo(47540)] = 2, -- Penance
	-- Mage
	[GetSpellInfo(10)] = 5, -- Blizzard
	[GetSpellInfo(5143)] = 5, -- Arcane Missiles
	[GetSpellInfo(12051)] = 4, -- Evocation
	-- Hunter
	[GetSpellInfo(1510)] = 6, -- Volley
	-- Sirus
	[GetSpellInfo(309231)] = 5 -- Землетрясение
}

Castbars.Barticks = setmetatable({}, {
		__index = function(tick, i)
		local spark = CastingBarFrame:CreateTexture(nil, 'OVERLAY');
		tick[i] = spark;
		spark:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-Skills-Bar]]);
		spark:SetVertexColor(1, 1, 1, 0.75);
		spark:SetBlendMode('ADD');
		spark:SetWidth(1);
		return spark;
	end
})

function Castbars:CastingBarFrameTicksSet(ticks)
	if (ticks and ticks > 0) then
		local delta = (self.db.profile["CastingBarFrame"]["Width"] / ticks);
		for i = 1, ticks do
			local tick = self.Barticks[i];
			tick:SetHeight(self.db.profile["CastingBarFrame"]["Height"] * 1);
			tick:SetPoint("CENTER", CastingBarFrame, "LEFT", delta * (i - 1), 0);
			tick:Show();
		end
	else
		for _, tick in ipairs(self.Barticks) do
			tick:Hide();
		end
	end
end

function Castbars:GcdSpellNameFind()
	local spells = {1126, 1494, 168, 465, 1243, 1752, 8017, 687, 49895, 6673};
	for i, spellId in ipairs(spells) do
		local spellName = GetSpellInfo(spellId);
		if (GetSpellCooldown(spellName)) then
			self.GcdSpellNameFind = nil;
			return spellName;
		end
	end
end

function Castbars:FrameMediaRestore(frame)
	local barTexture = self.SharedMedia:Fetch("statusbar", self.db.profile[frame.configName]["Texture"]);
	local borderTexture = self.SharedMedia:Fetch("border", self.db.profile[frame.configName]["Border"]);
	local font = self.SharedMedia:Fetch("font", self.db.profile[frame.configName]["Font"]);
	if (barTexture) then
		frame.statusBar:SetStatusBarTexture(barTexture);
	end
	if (borderTexture) then
		frame.backdrop:SetBackdrop({
			edgeFile = borderTexture,
			edgeSize = 16,
			tileSize = 16,
			insets = {
				bottom = 5,
				top = 5,
				right = 5,
				left = 5
			}
		});
		local brightness = self.db.profile[frame.configName]["BorderBrightness"];
		frame.backdrop:SetBackdropBorderColor(brightness, brightness, brightness, 1.0);
	end
	if (font) then
		local textSize = self.db.profile[frame.configName]["FontSize"];
		local outline = self.db.profile[frame.configName]["FontOutline"] and "OUTLINE" or nil;
		frame.text:SetFont(font, textSize, outline);
		if (frame.timer) then
			frame.timer:SetFont(font, textSize, outline);
		end
	end
end

function Castbars:FrameMediaRestoreAll()
	for i, frame in pairs(self.frames) do
		self:FrameMediaRestore(frame)
	end
end

function Castbars:FrameTimerRestore(frame)
	if (frame.timer) then
		if (frame.casting or frame.mergingTradeSkill) then
			if (frame.delayTime) then
				frame.timer:SetFormattedText("|cFFFF0000+%.1f |cFFFFFFFF" .. frame.castTimeFormat, frame.delayTime, max(frame.maxValue - frame.value, 0), frame.maxValue);
			else
				frame.timer:SetFormattedText(frame.castTimeFormat, max(frame.maxValue - frame.value, 0), frame.maxValue + (frame.delayTime or 0));
			end
		elseif (frame.channeling) then
			frame.timer:SetFormattedText(frame.castTimeFormat, max(frame.value, 0), frame.maxValue);
		elseif (self.ConfigMode) then
			if (self.db.profile[frame.configName]["ShowPushback"]) then
				frame.timer:SetFormattedText("|cFFFF0000+%.1f |cFFFFFFFF" .. frame.castTimeFormat, 0, 0, 0);
			else
				frame.timer:SetFormattedText(frame.castTimeFormat, 0, 0);
			end
		else
			frame.timer:SetText();
		end
	end
end

function Castbars:FrameColourRestore(frame)
	if (frame.shield and frame.shield:IsShown() or frame.outOfRange) then
		frame.statusBar:SetStatusBarColor(0.6, 0.6, 0.6);
	elseif (self.db.profile[frame.configName]["UseBarColor"]) then
		frame.statusBar:SetStatusBarColor(unpack(self.db.profile[frame.configName]["BarColor"]));
	end
end

function Castbars:FrameIconRestore(frame)
	if (frame.icon) then
		if (frame.shield and frame.shield:IsShown() and (self.db.profile[frame.configName]["ShowShield"])) then
			local hb, wb = frame.shield:GetHeight(), frame.shield:GetWidth();
			frame.icon:ClearAllPoints();
			frame.icon:SetPoint("TOPRIGHT", frame, "TOPLEFT", -0.03515625 * wb, 0.09375 * hb);
			frame.icon:SetHeight(0.328125 * hb);
			frame.icon:SetWidth(0.08203125 * wb);
			frame.icon:Show();
		elseif (self.db.profile[frame.configName]["ShowIcon"]) then
			frame.icon:ClearAllPoints();
			if (self.db.profile[frame.configName]["Border"] == "None") then
				frame.icon:SetPoint("RIGHT", frame, "LEFT", 0, 0);
				frame.icon:SetHeight(self.db.profile[frame.configName]["Height"]);
				frame.icon:SetWidth(self.db.profile[frame.configName]["Height"]);
			else
				frame.icon:SetPoint("RIGHT", frame, "LEFT", -5, 0);
				frame.icon:SetHeight(self.db.profile[frame.configName]["Height"] + 5);
				frame.icon:SetWidth(self.db.profile[frame.configName]["Height"] + 5);
			end
			frame.icon:Show();
		else
			frame.icon:Hide();
		end
	end
end

function Castbars:FrameRestoreOnCast(frame, unit)
	self:FrameColourRestore(frame);
	self:FrameIconRestore(frame);
	self:FrameTimerRestore(frame);
	if ((unit == "player") and (frame.unit == "player")) then
		if (frame.latency and self.db.profile[frame.configName]["ShowLatency"] and frame.sentTime) then
			local min, max = frame:GetMinMaxValues();
			local latency = (GetTime() - frame.sentTime) / (max - min);
			frame.sentTime = nil;
			if (latency < 0) then
				latency = 0
			elseif (latency > 1) then
				latency = 1
			end
			frame.latency:SetWidth(frame:GetWidth() * latency);
			frame.latency:ClearAllPoints();
			if (frame.channeling) then
				frame.latency:SetPoint("LEFT", frame, "LEFT", 0, 0);
			else
				frame.latency:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
			end
			frame.latency:Show();
		end
		local spellName = UnitCastingInfo(unit) or UnitChannelInfo(unit);
		if (spellName) then
			if (self.db.profile[frame.configName]["ShowSpellTarget"]) then
				if (spellName == frame.spellName and frame.spellTargetName and frame.spellTargetName ~= "") then
					frame.text:SetFormattedText("%s (%s)", frame.spellName, frame.spellTargetName);
				elseif (spellName ~= frame.spellName and UnitName("target")) then
					frame.text:SetFormattedText("%s (%s)", spellName, UnitName("target"));
				else
					frame.text:SetText(spellName);
				end
			else
				frame.text:SetText(spellName);
			end
		end
	end
end

function Castbars:FrameLayoutRestore(frame)
	-- Position
	local position = self.db.profile[frame.configName]["Position"];
	if (frame.dragable and position) then
		frame:clearAllPoints();
		frame:setPoint(position.point, position.parent, position.relpoint, position.x, position.y);
	end

	-- Texture
	self:FrameMediaRestore(frame);

	-- Visibility
	if (self.db.profile[frame.configName]["Show"]) then
		if (frame == PetCastingBarFrame) then
			frame.showCastbar = self.db.profile[frame.configName]["Show"] or UnitIsPossessed("pet");
		else
			frame.showCastbar = true;
		end
	else
		frame.showCastbar = false;
	end

	-- Shield visibility
	if (frame.shield) then
		if (self.db.profile[frame.configName]["ShowShield"]) then
			frame.shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield");
			frame.shield:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.5, 1, 1, 1, 0.5);
		else
			frame.shield:SetTexture();
		end
	end

	-- Total cast time
	if (frame.timer) then
		frame.castTimeFormat = "%.1f";
		if (self.db.profile[frame.configName]["ShowTotalCastTime"]) then
			frame.castTimeFormat = frame.castTimeFormat .. "/%." .. (self.db.profile[frame.configName]["TotalCastTimeDecimals"] or "1") .. "f";
		end
		if (self.db.profile[frame.configName]["ShowPushback"]) then
			frame.timer:SetFormattedText("|cFFFF0000+%.1f |cFFFFFFFF" .. frame.castTimeFormat, 0, 0, 0);
		else
			frame.timer:SetFormattedText(frame.castTimeFormat, 0, 0);
		end
	end

	-- Text Alignment
	frame.text:SetJustifyH(self.db.profile[frame.configName]["TextAlignment"]);

	-- Dimensions
	frame:SetWidth(self.db.profile[frame.configName]["Width"]);
	frame:SetHeight(self.db.profile[frame.configName]["Height"]);

	-- Restore dynamic settings
	self:FrameRestoreOnCast(frame);
end

function Castbars:FrameLayoutRestoreAll()
	for i, frame in pairs(self.frames) do
		self:FrameLayoutRestore(frame)
	end
end

function Castbars:FrameCustomize(frame)
	local frameName = frame:GetName();
	local frameType;

	if (frameName:sub(1, 11) == "MirrorTimer") then
		local index = tonumber(frameName:sub(12, 12));
		frameType = "Mirror";
		frame.statusBar = _G[frameName .. "StatusBar"];
		frame.configName = "MirrorTimer";
		frame.friendlyName = "Таймер " .. index;
		if (index == 1) then
			frame.dragable = true;
		end
	elseif (frameName == "CastingBarFrame") then
		frameType = "Castbar";
		frame.statusBar = frame;
		frame.configName = frameName;
		frame.friendlyName = "Игрок/Транспорт";
		frame.dragable = true;
		frame.icon = _G[frameName .. "Icon"];
		frame.shield = _G[frameName .. "BorderShield"];
	elseif (frameName == "PetCastingBarFrame") then
		frameType = "Castbar";
		frame.statusBar = frame;
		frame.configName = UnitIsPossessed("pet") and "CastingBarFrame" or "PetCastingBarFrame";
		frame.friendlyName = "Питомец";
		frame.dragable = true;
		frame.icon = _G[frameName .. "Icon"];
		frame.shield = _G[frameName .. "BorderShield"];
	elseif (frameName == "TargetCastingBarFrame") then
		frameType = "Castbar";
		frame.statusBar = frame;
		frame.configName = frameName;
		frame.friendlyName = "Цель";
		frame.dragable = true;
		frame.icon = _G[frameName .. "Icon"];
		frame.shield = _G[frameName .. "BorderShield"];
	elseif (frameName == "FocusCastingBarFrame") then
		frameType = "Castbar";
		frame.statusBar = frame;
		frame.configName = frameName;
		frame.friendlyName = "Фокус";
		frame.dragable = true;
		frame.icon = _G[frameName .. "Icon"];
		frame.shield = _G[frameName .. "BorderShield"];
	end

	-- Make dragable
	if (frame.dragable) then
		frame:SetMovable(true);
		frame:RegisterForDrag("LeftButton");
		frame:SetScript("OnDragStart", function(frame)
			if (self.ConfigMode) then
				frame:StartMoving();
			end
		end);
		frame:SetScript("OnDragStop", function(frame)
			frame:StopMovingOrSizing();
			if (not self.db.profile[frame.configName]["Position"]) then
				self.db.profile[frame.configName]["Position"] = {};
			end
			local position = self.db.profile[frame.configName]["Position"];
			position.point, position.parent, position.relpoint, position.x, position.y = frame:GetPoint();
		end);
	end

	-- Adjust spark position
	frame.spark = _G[frameName .. "Spark"];
	if (frame.spark) then
		local setPoint = frame.spark.SetPoint;
		frame.spark.SetPoint = function(self, point, relativeFrame, relativePoint, x, y)
			setPoint(self, point, relativeFrame, relativePoint, x, 0);
		end
	end

	-- Adjust text position
	frame.text = _G[frameName .. "Text"];
	frame.text:ClearAllPoints();
	if (frameType == "Castbar") then
		frame.text:SetPoint("LEFT", frame.statusBar, "LEFT", 5, 1);
	elseif (frameType == "Mirror") then
		frame.text:SetPoint("CENTER", frame.statusBar, "CENTER", 0, 1);
	end

	-- Prevent other addons moving the text (and setting the width)
	frame.text.SetWidthReal = frame.text.SetWidth;
	frame.text.SetWidth = self.DoNothing;
	frame.text.ClearAllPoints = self.DoNothing;
	frame.text.SetPoint = self.DoNothing;

	-- Prevent other addons moving the frame
	frame.clearAllPoints = frame.ClearAllPoints;
	frame.ClearAllPoints = self.DoNothing;
	frame.setPoint = frame.SetPoint;
	frame.SetPoint = self.DoNothing;

	-- Prevent other addons from modifying event registrations
	frame.UnregisterEvent = self.DoNothing;
	frame.UnregisterAllEvents = self.DoNothing;
	frame.RegisterEvent = self.DoNothing;

	-- Remove the border
	local frameBorder = _G[frameName .. "Border"];
	frameBorder:SetTexture();

	-- Remove the flash
	local frameFlash = _G[frameName .. "Flash"];
	if (frameFlash) then
		frameFlash:SetTexture();
	end

	-- Create backdrop
	frame.backdrop = CreateFrame("Frame", frameName .. "Backdrop", frame);
	if (frameType == "Castbar") then
		frame.backdrop:SetPoint("CENTER", frame, "CENTER", 0, 0);
	elseif (frameType == "Mirror") then
		frame.backdrop:SetPoint("CENTER", frame, "CENTER", 0, 3);
	end

	if (frameName == "CastingBarFrame") then
		frame.gcd = CreateFrame("Frame", nil, UIParent);
		frame.gcd:SetPoint("BOTTOM", frame.statusBar, "TOP", 0, 0);
		frame.gcd:SetHeight(4);
		frame.gcd:Hide();
		local border = frame.gcd:CreateTexture(nil, "BACKGROUND");
		border:SetAllPoints(frame.gcd);
		local texture = frame.gcd:CreateTexture(nil, "OVERLAY");
		texture:SetTexture("Spells\\AURA_01");
		texture:SetVertexColor(1, 1, 1, 1)
		texture:SetBlendMode('ADD');
		texture:SetWidth(35);
		texture:SetHeight(35);
		frame.gcd:SetScript("OnUpdate", function(frameGcd, elapsed)
			frameGcd.elapsed = (frameGcd.elapsed or 0) + elapsed;
			if (frameGcd.elapsed > 0.1) then
				frameGcd.elapsed = 0;
				if (frame:IsVisible()) then
					border:SetTexture(0, 0, 0, 0)
				else
					border:SetTexture(0, 0, 0, 0.3)
				end
			end
			local x = GetTime() * frameGcd.a - frameGcd.b;
			if (x > frameGcd:GetWidth()) then
				frameGcd:Hide();
			else
				texture:SetPoint("CENTER", frameGcd, "LEFT", x, 0);
			end
		end);
	end

	if (frameType == "Castbar") then
		-- Add timer text
		frame.timer = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		frame.timer:SetPoint("RIGHT", frame, "RIGHT", -5, 1);
		frame.nextupdate = 0.1;

		-- Add latency indication texture
		if (frameName == 'CastingBarFrame') then
			frame.latency = frame:CreateTexture(nil, "ARTWORK");
			frame.latency:Hide();
			frame.latency:SetHeight(frame:GetHeight());
			frame.latency:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
			frame.latency:SetTexture(1, 0, 0, 0.65);
		end

		-- Adjust shield layer
		frame.shield:SetDrawLayer("OVERLAY");
	elseif (frameType == "Mirror") then
		for i, region in pairs({frame:GetRegions()}) do
			if (region.GetTexture and region:GetTexture() == "SolidTexture") then
				frame.shade = region;
			end
		end
	end

	-- Automatically adjust the height of sub elements
	local setHeight = frame.SetHeight;
	if (frameType == "Castbar") then
		frame.SetHeight = function(self, height)
			frame.backdrop:SetHeight(height + 10);
			frame.spark:SetHeight(2.5 * height);
			if (frame.latency) then
				frame.latency:SetHeight(height);
			end
			frame.shield:SetHeight(5.82 * height);
			setHeight(self, height);
		end
	elseif (frameType == "Mirror") then
		frame.SetHeight = function(self, height)
			frame.backdrop:SetHeight(height + 10);
			frame.statusBar:SetHeight(height);
			frame.shade:SetHeight(height);
			setHeight(self, height + 10);
		end
	end

	-- Automatically adjust the width of sub elements
	local setWidth = frame.SetWidth
	if (frameType == "Castbar") then
		frame.SetWidth = function(self, width)
			frame.backdrop:SetWidth(width + 10);
			frame.text:SetWidthReal(width - 10 - frame.timer:GetWidth());
			frame.shield:SetWidth(1.36 * width);
			frame.shield:ClearAllPoints();
			frame.shield:SetPoint("CENTER", frame.statusBar, "CENTER", -0.031875 * width, 0);
			if (frame.gcd) then
				frame.gcd:SetWidth(width);
			end
			setWidth(self, width);
		end
	elseif (frameType == "Mirror") then
		frame.SetWidth = function(self, width)
			frame.backdrop:SetWidth(width + 10);
			frame.statusBar:SetWidth(width);
			frame.shade:SetWidth(width);
			setWidth(self, width + 10);
		end
	end

	frame:Hide();
end

function Castbars:FrameCustomizeAll()
	for i, frame in pairs(self.frames) do
		self:FrameCustomize(frame)
	end
end

function Castbars:GetOptionsTableForBar(frameConfigName, friendlyName, order, textAlign, showHideShield, enableDisable, showHideIcon,
	showHideLatency, showHideSpellTarget, showHideTotalCastTime, totalCastTimeDecimals, showHidePushback, showHideCooldownSpark, showHideTick)
	local options = {
		type = "group",
		name = friendlyName,
		order = order,
		args = {
			width = {
				name = "Ширина",
				type = "range",
				order = 10,
				desc = "Установите ширину панели для " .. friendlyName,
				min = 100,
				max = 600,
				step = 1,
				get = function()
					return self.db.profile[frameConfigName]["Width"]
				end,
				set = function(info, value)
					self.db.profile[frameConfigName]["Width"] = value;
					self:FrameLayoutRestoreAll();
				end
			},
			height = {
				name = "Высота",
				type = "range",
				order = 11,
				desc = "Установите высоту панели для " .. friendlyName,
				min = 10,
				max = 100,
				step = 1,
				get = function()
					return self.db.profile[frameConfigName]["Height"]
				end,
				set = function(info, value)
					self.db.profile[frameConfigName]["Height"] = value;
					self:FrameLayoutRestoreAll();
				end
			},
			texture = {
				name = "Текстура",
				type = "select",
				order = 12,
				desc = "Выберите текстуру для использования в " .. friendlyName,
				dialogControl = "LSM30_Statusbar",
				values = AceGUIWidgetLSMlists.statusbar,
				get = function()
					return self.db.profile[frameConfigName]["Texture"]
				end,
				set = function(info, value)
					self.db.profile[frameConfigName]["Texture"] = value;
					self:FrameLayoutRestoreAll();
				end
			},
			color = {
				name = "Цвет панели",
				type = "color",
				order = 13,
				desc = "Используется, только если выбран параметр «Свой цвет панели».",
				get = function(info)
					return unpack(self.db.profile[frameConfigName]["BarColor"]);
				end,
				set = function(info, r, g, b)
					self.db.profile[frameConfigName]["BarColor"] = {r, g, b};
				end
			},
			customcolor = {
				name = "Свой цвет панели",
				type = "toggle",
				order = 14,
				desc = "Разрешает изменить цвет панели.",
				get = function()
					return self.db.profile[frameConfigName]["UseBarColor"]
				end,
				set = function()
					self.db.profile[frameConfigName]["UseBarColor"] =
						not self.db.profile[frameConfigName]["UseBarColor"];
					self:FrameLayoutRestoreAll();
				end
			},
			font = {
				name = "Шрифт",
				type = "select",
				order = 15,
				desc = "Выберите шрифт для использования в " .. friendlyName,
				dialogControl = "LSM30_Font",
				values = AceGUIWidgetLSMlists.font,
				get = function()
					return self.db.profile[frameConfigName]["Font"]
				end,
				set = function(info, value)
					self.db.profile[frameConfigName]["Font"] = value;
					self:FrameLayoutRestoreAll();
				end
			},
			fontsize = {
				name = "Размер шрифта",
				type = "range",
				order = 16,
				desc = "Установите размер шрифта для " .. friendlyName,
				min = 6,
				max = 30,
				step = 1,
				get = function()
					return self.db.profile[frameConfigName]["FontSize"]
				end,
				set = function(info, value)
					self.db.profile[frameConfigName]["FontSize"] = value;
					self:FrameLayoutRestoreAll();
				end
			},
			fontoutline = {
				name = "Контур шрифта",
				type = "toggle",
				order = 17,
				desc = "Переключает контур шрифта для " .. friendlyName,
				get = function()
					return self.db.profile[frameConfigName]["FontOutline"]
				end,
				set = function()
					self.db.profile[frameConfigName]["FontOutline"] =
						not self.db.profile[frameConfigName]["FontOutline"];
					self:FrameLayoutRestoreAll();
				end
			},
			border = {
				name = "Граница",
				type = "select",
				order = 20,
				desc = "Выберите границу для использования в " .. friendlyName,
				dialogControl = "LSM30_Border",
				values = AceGUIWidgetLSMlists.border,
				get = function()
					return self.db.profile[frameConfigName]["Border"]
				end,
				set = function(info, value)
					self.db.profile[frameConfigName]["Border"] = value;
					self:FrameLayoutRestoreAll();
				end
			},
			borderbrightness = {
				name = "Прозрачность границы",
				type = "range",
				order = 21,
				desc = "Установите прозрачность границы для " .. friendlyName,
				min = 0.0,
				max = 1.0,
				step = 0.05,
				isPercent = true,
				get = function()
					return self.db.profile[frameConfigName]["BorderBrightness"]
				end,
				set = function(info, value)
					self.db.profile[frameConfigName]["BorderBrightness"] = value;
					self:FrameLayoutRestoreAll();
				end
			}
		}
	};
	if (enableDisable) then
		options.args.enable = {
			name = "Включить",
			type = "toggle",
			order = 1,
			desc = "Переключает видимость панели " .. friendlyName,
			get = function()
				return self.db.profile[frameConfigName]["Show"]
			end,
			set = function()
				self.db.profile[frameConfigName]["Show"] = not self.db.profile[frameConfigName]["Show"];
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (showHideIcon) then
		options.args.showicon = {
			name = "Иконка",
			type = "toggle",
			order = 2,
			desc = "Переключает отображение иконки в левой части панели.",
			get = function()
				return self.db.profile[frameConfigName]["ShowIcon"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowIcon"] = not self.db.profile[frameConfigName]["ShowIcon"];
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (showHideShield) then
		options.args.showshield = {
			name = "Щит",
			type = "toggle",
			order = 3,
			desc = "Переключает отображение щита вокруг панели, когда заклинание нельзя прервать.",
			get = function()
				return self.db.profile[frameConfigName]["ShowShield"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowShield"] = not self.db.profile[frameConfigName]["ShowShield"];
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (showHideLatency) then
		options.args.showlatency = {
			name = "Задержка",
			type = "toggle",
			order = 4,
			desc = "Переключает индикатор задержки, который показывает задержку во время произнесения заклинания - красной полосой в конце панели каста.",
			get = function()
				return self.db.profile[frameConfigName]["ShowLatency"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowLatency"] = not self.db.profile[frameConfigName]["ShowLatency"];
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (showHideSpellTarget) then
		options.args.showspelltarget = {
			name = "Цель заклинания",
			type = "toggle",
			order = 5,
			desc = "Переключает отображение имени цели наложенного заклинания.",
			get = function()
				return self.db.profile[frameConfigName]["ShowSpellTarget"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowSpellTarget"] = not self.db.profile[frameConfigName]["ShowSpellTarget"];
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (showHideTotalCastTime) then
		options.args.showtotalcasttime = {
			name = "Общее время каста",
			type = "toggle",
			order = 6,
			desc = "Переключает отображение общего времени чтения заклинания.",
			get = function()
				return self.db.profile[frameConfigName]["ShowTotalCastTime"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowTotalCastTime"] = not self.db.profile[frameConfigName]["ShowTotalCastTime"];
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (totalCastTimeDecimals) then
		options.args.totalcasttimedecimals = {
			name = "Десятичные",
			type = "range",
			order = 7,
			desc = "Установите количество десятичных для общего времени каста (количество цифр после запятой).",
			min = 0,
			max = 5,
			step = 1,
			get = function()
				return self.db.profile[frameConfigName]["TotalCastTimeDecimals"]
			end,
			set = function(info, value)
				self.db.profile[frameConfigName]["TotalCastTimeDecimals"] = value;
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (showHidePushback) then
		options.args.showpushback = {
			name = "Отклик",
			type = "toggle",
			order = 8,
			desc = "Переключает отображение дополнительного времени от полученного урона при произнесения заклинания.",
			get = function()
				return self.db.profile[frameConfigName]["ShowPushback"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowPushback"] = not self.db.profile[frameConfigName]["ShowPushback"];
				self:FrameLayoutRestoreAll();
			end
		}
	end
	if (showHideCooldownSpark) then
		options.args.showspark = {
			name = "ГКД",
			type = "toggle",
			order = 9,
			desc = "Переключает отображение глобального кулдауна.",
			get = function()
				return self.db.profile[frameConfigName]["ShowCooldownSpark"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowCooldownSpark"] = not self.db.profile[frameConfigName]["ShowCooldownSpark"];
			end
		}
	end
	if (showHideTick) then
		options.args.showtick = {
			name = "Такт",
			type = "toggle",
			order = 9.5,
			desc = "Переключает отображение тиков на потоковых заклинаниях.",
			get = function()
				return self.db.profile[frameConfigName]["ShowTick"]
			end,
			set = function()
				self.db.profile[frameConfigName]["ShowTick"] = not self.db.profile[frameConfigName]["ShowTick"];
			end
		}
	end
	if (textAlign) then
		options.args.textalign = {
			name = "Выравнивание текста",
			type = "select",
			order = 16,
			desc = "Расположение текста на панели каста",
			values = {
				LEFT = "Слева",
				CENTER = "По центру"
			},
			get = function()
				return self.db.profile[frameConfigName]["TextAlignment"]
			end,
			set = function(info, value)
				self.db.profile[frameConfigName]["TextAlignment"] = value;
				self:FrameLayoutRestoreAll();
			end
		}
	end
	return options;
end

function Castbars:GetOptionsTable()
	local options = {
		type = "group",
		args = {
			general = {
				type = "group",
				name = "Конфигурация",
				childGroups = "tab",
				args = {
					toggleconfigmode = {
						name = "Режим настройки",
						type = "toggle",
						order = 1,
						desc = "Показать панели, для перемещения и настройки внешнего вида",
						get = function()
							return self.ConfigMode
						end,
						set = function()
							self:Toggle()
						end
					},
					player = self:GetOptionsTableForBar("CastingBarFrame", "Игрок/Транспорт", 2, true, false, true, true, true, true, true, true, true, true, true),
					pet = self:GetOptionsTableForBar("PetCastingBarFrame", "Питомец", 3, true, false, true, true, false, false, true, false, false, false),
					target = self:GetOptionsTableForBar("TargetCastingBarFrame", "Цель", 4, true, true, true, true, false, false, true, false, false, false),
					focus = self:GetOptionsTableForBar("FocusCastingBarFrame", "Фокус", 5, true, true, true, true, false, false, true, false, false, false),
					mirror = self:GetOptionsTableForBar("MirrorTimer", "Дыхание/Усталость", 6)
				}
			},
			profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
		}
	};
	return options;
end

function Castbars:UnitFullName(unit)
	local name, realm = UnitName(unit);
	if (realm and realm ~= "") then
		return name .. "-" .. realm;
	else
		return name;
	end
end

function Castbars:NameToUnitID(targetName)
	return UnitExists(targetName) and targetName or (targetName == self:UnitFullName("target") and "target") or (targetName == self:UnitFullName("focus") and "focus") or
	(targetName == self:UnitFullName("targettarget") and "targettarget") or (targetName == self:UnitFullName("focustarget") and "focustarget") or nil;
end

function Castbars:OpenConfig()
	InterfaceOptionsFrame_OpenToCategory("Castbars");
end

function Castbars:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("CastbarsDB", {
		profile = {
			["**"] = {
				Width = 205,
				Height = 13,
				Texture = "Blizzard",
				Border = "None",
				Font = "Friz Quadrata TT",
				FontSize = 12,
				FontOutline = true,
				TextAlignment = "CENTER",
				BorderBrightness = 0.2,
				Position = nil,
				BarColor = {0.3, 0.3, 0.8},
				UseBarColor = true
			},
			CastingBarFrame = {
				Show = true,
				ShowLatency = true,
				ShowIcon = true,
				ShowSpellTarget = true,
				ShowTotalCastTime = true,
				TotalCastTimeDecimals = 1,
				ShowPushback = true,
				ShowCooldownSpark = true,
				ShowTick = true,
				Width = 240,
				Height = 24,
				Position = {
					point = "BOTTOM",
					relpoint = "BOTTOM",
					x = 0,
					y = 220
				}
			},
			PetCastingBarFrame = {
				Show = true,
				ShowIcon = true,
				Width = 150,
				Height = 12,
				Border = "None",
				Position = {
					point = "BOTTOM",
					relpoint = "BOTTOM",
					x = 0,
					y = 200
				}
			},
			TargetCastingBarFrame = {
				Show = true,
				ShowIcon = true,
				ShowShield = true,
				Height = 12,
				Border = "None",
				Position = {
					point = "CENTER",
					relpoint = "CENTER",
					x = 0,
					y = 200
				}
			},
			FocusCastingBarFrame = {
				Show = false,
				ShowIcon = true,
				ShowShield = true,
				Height = 12,
				Border = "None",
				Position = {
					point = "CENTER",
					relpoint = "CENTER",
					x = 0,
					y = 220
				}
			},
			MirrorTimer = {}
		}
	});
	self.db.RegisterCallback(self, "OnProfileChanged", "FrameLayoutRestoreAll");
	self.db.RegisterCallback(self, "OnProfileCopied", "FrameLayoutRestoreAll");
	self.db.RegisterCallback(self, "OnProfileReset", "FrameLayoutRestoreAll");

	self.options = self:GetOptionsTable();
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Castbars", self.options);
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Castbars", nil, nil, "general");
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Castbars", "Профили", "Castbars", "profile");
	self:RegisterChatCommand("cb", "OpenConfig");
	self:RegisterChatCommand("castbars", "OpenConfig");

	-- Prevent the UIParent from moving the CastingBarFrame around
	UIPARENT_MANAGED_FRAME_POSITIONS["CastingBarFrame"] = nil;

	-- Create target casting bar
	CreateFrame("StatusBar", "TargetCastingBarFrame", UIParent, "CastingBarFrameTemplate");
	TargetCastingBarFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
	CastingBarFrame_OnLoad(TargetCastingBarFrame, "target", false, true);

	-- Create focus casting bar
	CreateFrame("StatusBar", "FocusCastingBarFrame", UIParent, "CastingBarFrameTemplate");
	FocusCastingBarFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
	CastingBarFrame_OnLoad(FocusCastingBarFrame, "focus", false, true);

	-- Register additional events on CastingBarFrame
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
	CastingBarFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");

	-- Setup table with all frames
	self.frames = {CastingBarFrame, PetCastingBarFrame, TargetCastingBarFrame, FocusCastingBarFrame, MirrorTimer1, MirrorTimer2, MirrorTimer3};

	-- Customize the bars
	self:FrameCustomizeAll();

	-- Restore layout of all frames
	local loginRestoreOnce;
	if (IsLoggedIn()) then
		self:FrameLayoutRestoreAll();
		loginRestoreOnce = true;
	end

	-- Listen to LibSharedMedia-3.0 callbacks
	self.SharedMedia.RegisterCallback(self, "LibSharedMedia_Registered", "FrameMediaRestoreAll")
	self.SharedMedia.RegisterCallback(self, "LibSharedMedia_SetGlobal", "FrameMediaRestoreAll")

	self.CastingBarFrame_OnUpdate = function(frame, elapsed, ...)
		CastingBarFrame_OnUpdate(frame, elapsed, ...);
		if (frame:IsVisible()) then
			if (frame.outOfRange ~= nil) then
				local outOfRange = frame.outOfRange;
				frame.outOfRange = frame.spellName and frame.spellTarget and (IsSpellInRange(frame.spellName, frame.spellTarget) == 0) and true or false;
				if (outOfRange ~= frame.outOfRange) then
					self:FrameColourRestore(frame);
				end
			end
			if (frame.timer) then
				if (frame.nextupdate < elapsed) then
					self:FrameTimerRestore(frame);
					frame.nextupdate = 0.1;
				else
					frame.nextupdate = frame.nextupdate - elapsed;
				end
			end
		end
	end

	-- Hook DoTradeSkill
	local orgDoTradeSkill = DoTradeSkill;
	DoTradeSkill = function(index, num, ...)
		orgDoTradeSkill(index, num, ...);
		CastingBarFrame.mergingTradeSkill = true;
		CastingBarFrame.countCurrent = 0;
		CastingBarFrame.countTotal = tonumber(num) or 1;
	end

	self.CastingBarFrame_OnEvent = function(frame, event, ...)
		if (self.ConfigMode) then
			return
		end
		frame.Show = nil; -- Protect against addons that override the Show method
		if (event == "UNIT_SPELLCAST_SENT") then
			local unit, spellName, _, targetName = ...;
			if (unit == "player") then
				frame.sentTime = GetTime();
				frame.outOfRange = false;
				frame.spellName = spellName;
				frame.spellTargetName = targetName;
				frame.spellTarget = self:NameToUnitID(targetName);
			end
			return;
		elseif ((event == "ACTIONBAR_UPDATE_COOLDOWN") and self.db.profile[frame.configName]["ShowCooldownSpark"]) then
			frame.gcd.spellName = frame.gcd.spellName or self:GcdSpellNameFind();
			frame.gcd:SetFrameLevel(frame.backdrop:GetFrameLevel() + 1);
			local startTime, duration = GetSpellCooldown(frame.gcd.spellName or "");
			if (duration and (duration > 0)) then
				frame.gcd.a = frame.gcd:GetWidth() / duration;
				frame.gcd.b = (startTime * frame.gcd:GetWidth()) / duration;
				frame.gcd:Show();
			else
				frame.gcd:Hide();
			end
			return;
		elseif (event == "PLAYER_ENTERING_WORLD") then
			if (not loginRestoreOnce) then
				self:FrameLayoutRestoreAll();
				loginRestoreOnce = true;
			end
		elseif (event == "PLAYER_TARGET_CHANGED") then
			CastingBarFrame_OnEvent(frame, "PLAYER_ENTERING_WORLD", ...);
			if (frame.unit == "target") then
				self:FrameRestoreOnCast(frame, unit);
			end
			return;
		elseif (event == "PLAYER_FOCUS_CHANGED") then
			CastingBarFrame_OnEvent(frame, "PLAYER_ENTERING_WORLD", ...);
			if (frame.unit == "focus") then
				self:FrameRestoreOnCast(frame, unit);
			end
			return;
		elseif ((event == "UNIT_PET") and (... == "player")) then
			frame.configName = UnitIsPossessed("pet") and "CastingBarFrame" or "PetCastingBarFrame";
			self:FrameLayoutRestore(frame);
			return;
		end
		CastingBarFrame_OnEvent(frame, event, ...);
		if ((event == "UNIT_SPELLCAST_START") or (event == "UNIT_SPELLCAST_CHANNEL_START")) then
			local unit = ...;
			if ((unit == "player") and (frame.unit == "player")) then
				if (frame.channeling and self.db.profile[frame.configName]["ShowTick"]) then
					self:CastingBarFrameTicksSet(self.SpellToTicks[frame.spellName] or 0);
				end
				if (frame.casting) then
					frame.startTime = GetTime() - (frame.value or 0);
					frame.delayTime = nil;
					if (frame.mergingTradeSkill) then
						frame.value = frame.value + frame.maxValue * frame.countCurrent;
						frame.maxValue = frame.maxValue * frame.countTotal;
						frame:SetMinMaxValues(0, frame.maxValue);
						frame:SetValue(frame.value);
						frame.countCurrent = frame.countCurrent + 1;
						if (frame.countCurrent == frame.countTotal) then
							frame.mergingTradeSkill = nil;
						end
						frame.latency:Hide();
					end
				end
			end
			if (unit == frame.unit) then
				self:FrameRestoreOnCast(frame, unit);
				frame.text:SetWidthReal(frame:GetWidth() - 10 - frame.timer:GetWidth());
			end
		elseif ((event == "UNIT_SPELLCAST_STOP") or (event == "UNIT_SPELLCAST_CHANNEL_STOP")) then
			if ((... == "player") and (frame.unit == "player")) then
				if (not frame.casting and not frame.channeling) then
					frame.latency:Hide();
					self:CastingBarFrameTicksSet(0);
				end
				if (frame.mergingTradeSkill) then
					frame.value = frame.maxValue * frame.countCurrent / frame.countTotal;
					frame:SetValue(frame.value);
					frame:SetStatusBarColor(unpack(self.db.profile[frame.configName]["BarColor"]))
					frame.fadeOut = nil;
					local sparkPosition = (frame.value / frame.maxValue) * frame:GetWidth();
					frame.spark:SetPoint("CENTER", frame, "LEFT", sparkPosition, 2);
					frame.spark:Show();
				end
			end
		elseif (event == "UNIT_SPELLCAST_DELAYED") then
			if ((... == "player") and (frame.unit == "player") and frame.casting) then
				frame.delayTime = (GetTime() - (frame.value or 0)) - (frame.startTime or 0);
				self:FrameTimerRestore(frame);
				frame.text:SetWidthReal(frame:GetWidth() - 10 - frame.timer:GetWidth());
			end
		elseif ((event == "UNIT_SPELLCAST_FAILED") or (event == "UNIT_SPELLCAST_INTERRUPTED")) then
			if ((... == "player") and (frame.unit == "player")) then
				frame.mergingTradeSkill = nil;
			end
		elseif ((event == "UNIT_SPELLCAST_INTERRUPTIBLE") or (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")) then
			if (... == frame.unit) then
				self:FrameIconRestore(frame);
			end
		end
	end

	-- Replace the OnEvent handler
	CastingBarFrame:SetScript("OnEvent", self.CastingBarFrame_OnEvent);
	PetCastingBarFrame:SetScript("OnEvent", self.CastingBarFrame_OnEvent);
	TargetCastingBarFrame:SetScript("OnEvent", self.CastingBarFrame_OnEvent);
	FocusCastingBarFrame:SetScript("OnEvent", self.CastingBarFrame_OnEvent);

	-- Replace the OnUpdate handler
	CastingBarFrame:SetScript("OnUpdate", self.CastingBarFrame_OnUpdate);
	PetCastingBarFrame:SetScript("OnUpdate", self.CastingBarFrame_OnUpdate);
	TargetCastingBarFrame:SetScript("OnUpdate", self.CastingBarFrame_OnUpdate);
	FocusCastingBarFrame:SetScript("OnUpdate", self.CastingBarFrame_OnUpdate);

	self.GetOptionsTableForBar = nil;
	self.GetOptionsTable = nil;
	self.FrameCustomize = nil;
	self.FrameCustomizeAll = nil;
	self.OnInitialize = nil;
end

--[[ ConfigMode Support ]] --

Castbars.MirrorTimerFrame_OnEvent = MirrorTimerFrame_OnEvent;
Castbars.MirrorTimer_Show = MirrorTimer_Show;

function Castbars:Show()
	if (not self.ConfigMode) then
		self.ConfigMode = true;

		-- Prevent event handling
		MirrorTimerFrame_OnEvent = self.DoNothing
		MirrorTimer_Show = self.DoNothing;

		-- Make the Pet Castbar appear as a Pet Castbar even if in a vehicle while configuring.
		PetCastingBarFrame.configName = "PetCastingBarFrame";
		self:FrameLayoutRestore(PetCastingBarFrame);

		-- Condition and show all bars
		for i, frame in pairs(self.frames) do
			frame:EnableMouse(true);
			frame.text:SetText(frame.friendlyName);
			frame.statusBar:SetStatusBarColor(unpack(self.db.profile[frame.configName]["BarColor"]));
			frame.statusBar:SetAlpha(1);
			frame.statusBar:SetValue(select(2, frame.statusBar:GetMinMaxValues()));
			if (frame.spark) then
				frame.spark:Hide();
			end
			frame.fadeOut = nil;
			frame.paused = 1;
			frame:Show();
		end
	end
end

function Castbars:Hide()
	if (self.ConfigMode) then
		for i, frame in pairs(self.frames) do
			frame:EnableMouse(false);
			frame:Hide();
		end

		-- Restore the config name of the Pet Castbar
		PetCastingBarFrame.configName = UnitIsPossessed("pet") and "CastingBarFrame" or "PetCastingBarFrame";
		self:FrameLayoutRestore(PetCastingBarFrame);

		-- Restore event handling
		MirrorTimerFrame_OnEvent = self.MirrorTimerFrame_OnEvent;
		MirrorTimer_Show = self.MirrorTimer_Show;
		self.ConfigMode = false;
	end
end

function Castbars:Toggle()
	if (self.ConfigMode) then
		self:Hide();
	else
		self:Show();
	end
end

CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {};
CONFIGMODE_CALLBACKS["Castbars"] = function(action)
	if (action == "ON") then
		Castbars:Show()
	elseif (action == "OFF") then
		Castbars:Hide()
	end
end
