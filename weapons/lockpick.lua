if CLIENT then
	SWEP.Slot = 5
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.PrintName = 'Отмычка'
SWEP.Author = 'Raskumar'
SWEP.Instructions = 'ЛКМ для взлома двери.'
SWEP.Contact = ''
SWEP.Purpose = ''
SWEP.IsDarkRPLockpick = true

SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.ViewModel = Model('models/weapons/c_crowbar.mdl')
SWEP.WorldModel = Model('models/weapons/w_crowbar.mdl')

SWEP.UseHands = true

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = 'Raskumar'

SWEP.Sound = Sound('physics/wood/wood_box_impact_hard3.wav')

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ''

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ''

function SWEP:SetupDataTables()
	--IsLockpicking kinda useless to..
	self:NetworkVar('Float', 0, 'LockpickStartTime')
	--LockpickEndTime is kinda useless...... Use cfg.
	--Lockpick's NextSoundTime is useless too. We have SharedRandom, prediction by all means.
	--TotalLockpicks is litteraly useless too....
	self:NetworkVar('Entity', 0, 'LockpickEnt')
end

function SWEP:GetLockpickEndTime()
	return self:LockpickStartTime()+kent.cfg.LockpickDuration
end

function SWEP:SetLockpickEndTime() end

function SWEP:GetNextSoundTime()
	return CurTime() + 2 -- compat issue
end

function SWEP:SetNextSoundTime() end -- no funcitonal though.

function SWEP:GetIsLockpicking()
	return IsValid(self:GetLockpickEnt())
end

function SWEP:SetIsLockpicking() end -- why?


function SWEP:SecondaryAttack() end

function SWEP:Initialize()
	self.NextSoundTime = 0 -- This is predicte, so it shouldn't be networked.
end

function SWEP:Deploy()
	self:SetHoldType('normal')
end 

do
	local traceResultTab = {}
	local traceTab = {output = traceResultTab}

	function SWEP:PrimaryAttack()
		local ply = self:GetOwner()

		if not IsValid(ply) then
			return
		end

		if IsValid(self:GetLockpickEnt()) then return end

		local time = CurTime()
		self:SetNextPrimaryFire(time + 0.5)

		local pos = ply:EyePos()
		local endPos = ply:GetAimVector()
		endPos:Mul(100)
		endPos:Add(pos)

		traceTab.filter = ply
		traceTab.start = pos
		traceTab.endpos = endPos

		ply:LagCompensation(true)

		util.TraceLine(traceTab)

		ply:LagCompensation(false)

		local ent = traceResultTab.Entity

		if not IsValid(ent) or ent.DarkRPCanLockpick == false then
			return
		end

		local canLockpick = hook.Call('canLockpick', nil, ply, ent, traceResultTab)
		if canLockpick == false then
			return
		elseif canLockpick == true then
			goto skipcheck
		end

		if ent:IsPlayer() and ent:GetNetVar('HandCuffed') then goto skipcheck end

		do
			if not ent:IsDoor() then return end

			local coOwners = ent:GetNetVar('DoorCoOwners')
			if ent:GetNetVar('DoorOwner') == ply or coOwners and coOwners[ply] or not ent:IsDoorLocked() then 
				return
			end
			local specialData = ent.kentSpecialData

			if specialData then
				local doorGroup = specialData.doorGroup
				if doorGroup then
					local doorCategory = kent.cfg.doors.doorCategories[doorGroup]
					if doorCategory and doorCategory.jobs and doorCategory[ply:Team()] then
						return
					end
				else
					return
				end
			end
		end

		::skipcheck::

		self:SetHoldType('pistol')
		self:SetLockpickEnt(ent)
		self:SetLockpickStartTime(time)

		if SERVER then
			local function onFail(_, deadPly)
				if ply == deadPly then
					hook.Call('onLockpickCompleted', nil, ply, false, ent)
				end
			end

			hook.Add('PlayerDeath', self, onFail)
			hook.Add('PlayerDisconnected', self, onFail)

			hook.Add('onLockpickCompleted', self, function()
				hook.Remove('PlayerDeath', self)
				hook.Remove('PlayerDisconnected', self)
				hook.Remove('onLockpickCompleted', self)
			end)
		end
	end

	function SWEP:Think()
		local ent = self:GetLockpickEnt()
		if not IsValid(ent) then return end

		local ply = self:GetOwner()
		local time = CurTime()

		if time > self.NextSoundTime then
			self.NextSoundTime = time + util.SharedRandom('lockpicksound', kent.cfg.LockpickSoundMinTime, kent.cfg.LockpickSoundMaxTime, math.floor(time))
			self:EmitSound(self.Sound)
		end

		local pos = ply:EyePos()
		local endPos = ply:GetAimVector()
		endPos:Mul(100)
		endPos:Add(pos)

		traceTab.filter = ply
		traceTab.start = pos
		traceTab.endpos = endPos

		ply:LagCompensation(true)

		util.TraceLine(traceTab)

		ply:LagCompensation(false)

		if traceResultTab.Entity ~= ent or not ply:KeyDown(IN_ATTACK) then
			self:Fail()
			return
		end

		if time > self:GetLockpickStartTime()+kent.cfg.LockpickDuration then
			self:Succeed()
		end
	end
end

function SWEP:Holster()
	if IsValid(self:GetLockpickEnt()) then
		self:Fail()
	end

	return true
end 

function SWEP:Fail()
	self:SetHoldType('normal')

	hook.Call('onLockpickCompleted', nil, self:GetOwner(), false, self:GetLockpickEnt())
	self:SetLockpickEnt(nil)
end

function SWEP:Succeed()
	local ent = self:GetLockpickEnt()

	self:SetHoldType('normal')
	self:SetLockpickEnt(nil)

	if not IsValid(ent) then return end

	local override = hook.Call('onLockpickCompleted', nil, self:GetOwner(), true, ent)

	if override then return end

	--Only doors
	if ent:IsPlayer() and ent:GetNetVar("HandCuffed") and SERVER then
		ent:UnHandCuff()
	end

	if ent.Fire then
		ent:DoorLock(false)
		ent:Fire('open', '', .6)
		ent:Fire('setanimation', 'open', .6)
	end
end

if CLIENT then
	local dotPattern = {
		[0] = '',
		[1] = '.',
		[2] = '..',
		[3] = '...'
	}

	local uiCfg = kent.cfg.ui
	local colorBackground = uiCfg.colors.panelBackground
	local statusColor = Color(0, 0, 0)
	local ss = kent.ui.screenScale
	local offset = ss(uiCfg.offset)
	local border = ss(uiCfg.border)

	function SWEP:DrawHUD()
		if not IsValid(self:GetLockpickEnt()) then return end

		local time = CurTime()

		local w = ScrW()
		local h = ScrH()

		local x, y, width, height = w * 0.4, h * 0.5 - 60, w * 0.2 , h * 0.066

		draw.RoundedBox(border, x, y, width, height, colorBackground)

		local lockpickTime = kent.cfg.LockpickDuration
		local curTime = time - self:GetLockpickStartTime()
		
		local status = math.Clamp(curTime / lockpickTime, 0, 1)
		local barWidth = status * (width - offset*2)

		local statusMul = status*255

		statusColor.r = 255 - statusMul
		statusColor.g = statusMul

		draw.RoundedBox(border, x + offset, y + offset, barWidth, height - offset*2, statusColor)

		kent.ui.draw.shadowText(
			kent.lang.phraseToContents['picking_lock'] .. dotPattern[math.floor(time)%4],
			'kent.24',
			w * 0.5, y + height * 0.5,
			color_white,
			1, 1)
	end
end
