include('shared.lua')

-- kent.textscreen.0 -> kent.textscreen.15

local FONT_HEIGHT = 10

for i = 1, 16 do
	kent.ui.createFont('textscreen.' .. (i-1), FONT_HEIGHT*i, nil, false)
end

function ENT:Initialize()
	self.LineSizes = {}
	self.LineColors = {}
	self.Lines = {}
end

local bit = bit
local ipairs = ipairs
local start3D2D = cam.Start3D2D
local end3D2D = cam.End3D2D
local drawText = kent.ui.draw.shadowText
local textAlignCenter = TEXT_ALIGN_CENTER
local textAlignTop = TEXT_ALIGN_TOP
local colorWhite = color_white
local dist = 750^2 

hook.Add('kent.onPerfSettingsChanged', 'kent.textScreens', function(val)
	drawText = val and kent.ui.draw.simpleText or kent.ui.draw.shadowText
	dist = val and 400^2 or 700^2 
end)

function ENT:Draw()
	local pos = self:GetPos()
	local ang = self:GetAngles()

	if pos:DistToSqr(EyePos()) > dist then
		return
	end

	local height = 0
	local lineSizes = self.LineSizes
	local lines = self.Lines
	for k, v in ipairs(lines) do
		height = height + FONT_HEIGHT * ((lineSizes[k] or 0) + 1)
	end

	height = height / -2

	local lineColors = self.LineColors

	start3D2D(pos, ang, 0.15)
		for k, v in ipairs(lines) do
			local lineSize = lineSizes[k] or 0
			local fontHeight = FONT_HEIGHT * (lineSize + 1)
			local color = lineColors[k] or colorWhite

			drawText(v, 'kent.textscreen.' .. lineSize, 0, height, color, textAlignCenter, textAlignTop)

			height = height + fontHeight
		end
	end3D2D()
end