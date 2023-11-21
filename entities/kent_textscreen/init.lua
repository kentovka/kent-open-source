AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')

local MAX_LINES = 8

function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:DrawShadow( false )
	self:SetModel("models/hunter/plates/plate1x1.mdl")
	self:SetMaterial("models/effects/vol_light001")
	self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

if PermaProps then
	PermaProps.SpecialENTSSave['kent_textscreen'] = function(ent)
		local tab = {}

		tab.FontSize = ent:GetFontSize()
		tab.Text = ent:GetText()
		tab.Colors = {}

		for i = 1, MAX_LINES do
			tab.Colors[i] = ent['GetLineColor' .. i](ent)
		end
		return tab
	end

	PermaProps.SpecialENTSSpawn['kent_textscreen'] = function(ent, data)
		if not data then return end
		
		ent:Spawn()

		timer.Simple(0.5, function()
			if not IsValid(ent) then return end

			ent:SetText(data.Text)
			ent:SetFontSize(data.FontSize)

			for k, v in ipairs(data.Colors) do
				ent['SetLineColor' .. k](ent, v)
			end
		end)
	end
end