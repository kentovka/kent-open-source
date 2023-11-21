TOOL.Category		= "Raskumar"
TOOL.Name			= "Текст"
TOOL.Command		= nil
TOOL.ConfigName		= ""

local MAX_LINES = 8 -- не менять!!!
local bit = bit

for i = 1, MAX_LINES do
	TOOL.ClientConVar['text' .. i] = ""
	TOOL.ClientConVar['color' .. i] = 'ffffffff'
end

TOOL.ClientConVar['size'] = '77777777'

if CLIENT then
	language.Add("Tool.textscreen.name", "Текст")
	language.Add("Tool.textscreen.desc", "Создайте текст с несколькими линиями и цветами.")

	local txt = 'ЛКМ: создать текст. ПКМ: обновить текст'
	language.Add("Tool.textscreen.0", txt)
	language.Add("Tool_textscreen_0", txt)

	language.Add("Undone.textscreens", "Undone textscreen")
	language.Add("Undone_textscreens", "Undone textscreen")
	language.Add("Cleanup.textscreens", "Textscreens")
	language.Add("Cleanup_textscreens", "Textscreens")
	language.Add("Cleaned.textscreens", "Cleaned up all textscreens")
	language.Add("Cleaned_textscreens", "Cleaned up all textscreens")
end

function TOOL:GetText()
	local tab = {}
	local index = 0
	for i = 1, MAX_LINES do
		local txt = self:GetClientInfo('text' .. i):Replace('\n', ''):sub(1, 63) -- Максимально возможно ток 63 символа

		if txt and txt ~= '' then
			index = index + 1
			tab[index] = txt
		end
	end

	return table.concat( tab, "\n")
end

function TOOL:GetSize()
	return bit.tobit(tonumber(self:GetClientInfo('size'), 16))
end

function TOOL:GetColor(line)
	return bit.tobit(tonumber(self:GetClientInfo('color' .. line), 16))
end

local maxScreens = kent.cfg.maxTextScreens
function TOOL:LeftClick(tr)
	local ent = tr.Entity

	if ent:IsPlayer() then return false end

	if CLIENT then return true end
	local ply = self:GetOwner()

	if ply:GetCount('textScreens') >= maxScreens then
		kent.sendErrorNotify(ply, 'propLimitReached')
		return false 
	end


	local spawnPos = tr.HitPos
	spawnPos:Add(tr.HitNormal)

	local textScreen = ents.Create("kent_textscreen")
	textScreen:SetPos(spawnPos)
	textScreen:Spawn()

	local angle = tr.HitNormal:Angle()
	local angle2 = Angle(angle)
	angle:RotateAroundAxis(angle2:Right(), 270)
	angle:RotateAroundAxis(angle2:Forward(), 90)

	if textScreen.CPPISetOwner then
		textScreen:CPPISetOwner(ply)
	end

	textScreen:SetAngles(angle)

	undo.Create("textScreens")

	undo.AddEntity(textScreen)
	undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCount("textScreens", textScreen)
	ply:AddCleanup("textScreens", textScreen)

	local text, size = self:GetText(), self:GetSize()
	timer.Simple(0.5, function() -- иначе будут баги
		if not IsValid(textScreen) then return end


		textScreen:SetText(text) 
		textScreen:SetFontSize(size)

		for i = 1, MAX_LINES do
			local num = self:GetColor(i)

			textScreen['SetLineColor' .. i ](textScreen, num)
		end
	end)

	return true
end


function TOOL:RightClick(tr)
	local ent = tr.Entity

	if ent:GetClass() ~= 'kent_textscreen' then return false end
	if ent.CPPIGetOwner and ent:CPPIGetOwner() ~= self:GetOwner() then return false end
	if CLIENT then return true end

	ent:SetText(self:GetText()) 
	ent:SetFontSize(self:GetSize() )

	for i = 1, MAX_LINES do
		local num = self:GetColor(i)

		ent['SetLineColor' .. i ](ent, num)
	end

	return true
end

if SERVER then return end

function TOOL.BuildCPanel(pnl)
	local sizeVar = GetConVar('textscreen_size')

	pnl:AddControl('Header', {
		Text = '#Tool.textscreen.name',
		Description = '#Tool.textscreen.desc',
	})

	for i=1, MAX_LINES do
		local label

		local color = vgui.Create('DColorMixer')
		color:SetLabel('Цвет ' .. i .. ' линии')

		local colorVar = GetConVar('textscreen_color' .. i)
		local col = colorVar:GetString()
		local r, g, b, a = tonumber(col:sub(1, 2), 16), tonumber(col:sub(3, 4), 16), tonumber(col:sub(5, 6), 16), tonumber(col:sub(7, 8), 16)

		local startColor = Color(r or 255, g or 255, b or 255, a or 255)
		color:SetColor(startColor)
		function color:ValueChanged(clr)
			local num = bit.bor(
				bit.lshift(clr.r or 255, 24),
				bit.lshift(clr.g or 255, 16),
				bit.lshift(clr.b or 255, 8),
				clr.a or 255
			)

			colorVar:SetString(bit.tohex(num))
			label:SetColor(Color(clr.r, clr.g, clr.b))
		end

		pnl:AddItem(color)

		local size = vgui.Create('DNumSlider')
		size:SetText('Размер шрифта')
		size:SetMinMax(0, 15)
		size:SetDecimals(0)

		local val = tonumber(sizeVar:GetString()[i], 16)
		size:SetValue(val)

		function size:OnValueChanged(value)
			sizeVar:SetString(sizeVar:GetString():SetChar(i, bit.tohex(value, 1)))
		end

		pnl:AddItem(size)

		local textBox = vgui.Create("DTextEntry")
		textBox:SetUpdateOnType(true)
		textBox:SetEnterAllowed(true)
		textBox:SetConVar("textscreen_text"..i)
		textBox:SetValue(GetConVarString("textscreen_text" .. i))
		
		function textBox:OnValueChange(str)
			label:SetText(str)
		end

		pnl:AddItem(textBox)

		label = pnl:AddControl("Label", {
			Text = GetConVarString("textscreen_text" .. i),
			Description = "Линия " .. i
		})

		label:SetColor(startColor)
	end
end