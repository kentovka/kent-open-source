ENT.Type = 'anim'
ENT.Base = 'base_anim'
ENT.PrintName = 'Текстскрин'
ENT.Author = 'Raskumar'

ENT.Category = "Raskumar"
ENT.Spawnable = false

local MAX_LINES = 8 -- Не изменять сук

local changeSizeFunc, changeColorFunc, changeTextFunc

if CLIENT then
	do -- Цвет линии.
		local redMask = bit.tobit(tonumber('11111111000000000000000000000000', 2))
		local greenMask = bit.tobit(tonumber('00000000111111110000000000000000', 2))
		local blueMask = bit.tobit(tonumber('00000000000000001111111100000000', 2))
		local alphaMask = bit.tobit(tonumber('00000000000000000000000011111111', 2))

		changeColorFunc = function(ent, name, old, new)
			local r = bit.rshift(bit.band(redMask, new), 24)
			local g = bit.rshift(bit.band(greenMask, new), 16)
			local b = bit.rshift(bit.band(blueMask, new), 8)
			local a = bit.band(alphaMask, new)

			ent.LineColors[tonumber(name:sub(-1, -1))] = Color(r, g, b, a)
		end
	end

	do
		local sizeMasks = {}
		
		for i=1, MAX_LINES do
			sizeMasks[i] = bit.lshift(15, (MAX_LINES-i)*4)
		end

		changeSizeFunc = function(ent, name, old, new)
			for i = 1, MAX_LINES do
				ent.LineSizes[i] = bit.rshift(bit.band(sizeMasks[i], new), 4*(MAX_LINES-i)) -- по сути тут номер стоит, от 0 дооооо 15.
			end
		end
	end

	do
		changeTextFunc = function(ent, name, old, new)
			if new == '' or new == nil then
				ent.Lines = {} -- создавать новую таблицу имхо быстрее чем чистить старую (даже со сборщиком мусора)
			end

			local lineCount = select(2, new:gsub('\n', '\n'))
			if lineCount > MAX_LINES then
				return ErrorNoHaltWithStack('PIZDEC! TextScreen has more than max "\\n"\'s!')
			end

			ent.Lines = new:Split('\n')
		end
	end
end


function ENT:SetupDataTables()
	self:NetworkVar('Int', 0, 'FontSize') -- 4 бита на 8 линий, т.е 16 размеров шрифта на линию.

	if CLIENT then
		self:NetworkVarNotify('FontSize', changeSizeFunc)
	end
	
	for i = 1, MAX_LINES do
		self:NetworkVar('Int', i, 'LineColor' .. i) -- rgba - как раз 32 бита на линию.

		if CLIENT then
			self:NetworkVarNotify('LineColor' .. i, changeColorFunc)
		end
	end

	self:NetworkVar('String', 0, 'Text') -- \n линии разделяет. Получается максимум можно 31 байта на линию.

	if CLIENT then
		self:NetworkVarNotify('Text', changeTextFunc)
	end
	-- =А У СУПА 50 СИМВОЛОВ=
end


