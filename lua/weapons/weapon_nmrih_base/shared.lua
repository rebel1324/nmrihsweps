if (SERVER) then
	AddCSLuaFile()
	AddCSLuaFile( "effect.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
end

if ( CLIENT ) then
	include("effect.lua")
	SWEP.BobScale = 0
	SWEP.SwayScale = 0
	SWEP.DrawAmmo			= true
	SWEP.DrawCrosshair		= false
	SWEP.ViewModelFOV		= 50
	SWEP.ViewModelFlip		= false
	SWEP.CSMuzzleFlashes	= true
end

SWEP.Author			= "No More Room In Hell"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""
SWEP.Base				= "weapon_base"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary.Sound			= Sound( "Weapon_AK47.Single" )
SWEP.Primary.Recoil			= 1.5
SWEP.Primary.Damage			= 40
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.02
SWEP.Primary.Delay			= 0.15

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Melee = {}
SWEP.Melee.Damage = 10
SWEP.Melee.Delay = 1
SWEP.animTable = {}
SWEP.DeployTime = 1

if (CLIENT) then
	function SWEP:ViewModelDrawn()
		local vm = self.Owner:GetViewModel()
		local at = vm:LookupAttachment("muzzle")
		local atpos = vm:GetAttachment(at)

		self.emitter:DrawAt(atpos.Pos, atpos.Ang)
	end

	EVENT_VMUZZLE = 0
	EVENT_WMUZZLE = 1
	EVENT_SHELL = 2
	local eventTable = {
		[5001] = EVENT_VMUZZLE,
		[6001] = EVENT_VMUZZLE,
		[6001] = EVENT_WMUZZLE,
		[20] = EVENT_VMUZZLE,
		[21] = EVENT_VMUZZLE,
	}


	local posOutput = Vector(0, 0, 0)
	local posTarget = Vector(0, 0, 0)
	local angOutput = Angle(0, 0, 0)
	local angTarget = Angle(0, 0, 0)
	local oldAimVec = Vector(0 ,0, 0)
	local viewMoveMul = .01
	local curStep = 0
	local sin, cos = math.sin, math.cos
	local clamp = math.Clamp

	local function fTime() return math.Clamp(FrameTime(), 1/15, 1) end

	local function int(delta, from, to)
		local intType = type(from)

		if intType == "Angle" then
			from = util_NormalizeAngles(from)
			to = util_NormalizeAngles(to)
		end

		local out = from + (to-from)*delta

		return out
	end

	local bobPos = Vector()
	local lateBobPos = Vector()
	local restPos = Vector()
	SWEP.aimAngle = Angle()
	SWEP.oldAimAngle = Angle()
	SWEP.aimDiff = Angle()
	SWEP.ironMul = 1
	function SWEP:GetViewModelPosition( pos, ang )
		local owner = self.Owner
		local EP, EA = EyePos(), EyeAngles()
		local PA = owner:GetViewPunchAngles()
		local vel = clamp(owner:GetVelocity():Length2D()/owner:GetWalkSpeed(), 0, 1.5)
		local rest = 1 - clamp(owner:GetVelocity():Length2D()/20, 0, 1)

		posOutput = Vector(0, 0, 0)
		curStep = curStep + (vel/math.pi)*(fTime()*2)
		local ws = owner:GetWalkSpeed()

		self.aimAngle = owner:EyeAngles()	
		self.aimDiff = self.aimAngle - self.oldAimAngle
		self.oldAimAngle = self.aimAngle
		self.ironMul = Lerp(fTime()*.1, self.ironMul, (self:GetIronsight() or self:GetSprint()) and .1 or 1)

		local Right 	= EA:Right()
		local Up 		= EA:Up()
		local Forward 	= EA:Forward()	

		bobPos[1] = -sin(curStep/2)*vel
		bobPos[2] = sin(curStep/4)*vel*1.5
		bobPos[3] = sin(curStep)/1.5*vel
		restPos[3] = sin(CurTime()*2)*4
		restPos[1] = cos(CurTime()*1)*3

		posTarget = bobPos*15*self.ironMul + restPos*rest
		posOutput = LerpVector(fTime()*.3, posOutput, posTarget)
		angTarget = self.aimDiff*2*self.ironMul
		angOutput = LerpAngle(fTime()*.3, angOutput, angTarget)

		ang:RotateAroundAxis(ang:Right(), angOutput[1])
		ang:RotateAroundAxis(ang:Up(), angOutput[2])
		ang:RotateAroundAxis(ang:Forward(), angOutput[3])

		pos = pos + posOutput.x * Right 
		pos = pos + posOutput.y * Forward
		pos = pos + posOutput.z * Up
			
		return pos, ang
	end

	function SWEP:FireAnimationEvent(pos,ang,event)
		local eventNum = eventTable[event]

		if (eventNum) then
			if (eventNum == EVENT_VMUZZLE) then
				if (!self.nextEffect or self.nextEffect < CurTime()) then
					local vm = self.Owner:GetViewModel()
					if !IsValid(vm) then return end
					local at = vm:LookupAttachment( "muzzle" )
					local atpos = vm:GetAttachment(at)

					local e = EffectData()
					e:SetEntity(self)
					e:SetScale(.05)
					e:SetOrigin(atpos.Pos)
					e:SetNormal(atpos.Ang:Forward())
					util.Effect("btMuzzleFlash", e)

					if (!self.NoShell) then
						local at = vm:LookupAttachment( "Eject" )
						local atpos = vm:GetAttachment(at)

						local e = EffectData()
						e:SetEntity(self)
						e:SetOrigin(atpos.Pos)

						local ang = atpos.Ang
						local addAng = self.ShellAng or Angle(0, 0, 0)
						atpos.Ang:RotateAroundAxis(ang:Right(), math.random(-10, 10) + addAng[1])
						atpos.Ang:RotateAroundAxis(ang:Up(), math.random(-10, 10) + addAng[2])
						atpos.Ang:RotateAroundAxis(ang:Forward(), math.random(-10, 10) + addAng[3])
						e:SetNormal(atpos.Ang:Forward())
						e:SetScale(1)
						e:SetMagnitude(self.ShellType or 1)
						util.Effect("btShellEject", e)
					end

					self.nextEffect = CurTime() + self.Primary.Delay
				end
			elseif (eventNum == EVENT_WMUZZLE) then

			end

			return true
		else
			print(event)
		end
	end	
end

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 2, "Spread")
	self:NetworkVar("Float", 1, "NextIdle")
	self:NetworkVar("Float", 0, "NextMelee")
	self:NetworkVar("Bool", 5, "Holster")
	self:NetworkVar("Bool", 4, "CheckAmmo")
	self:NetworkVar("Bool", 3, "Melee")
	self:NetworkVar("Bool", 2, "Sprint")
	self:NetworkVar("Bool", 1, "Ironsight")
	self:NetworkVar("Bool", 0, "Reloading")
end

function SWEP:GetFireAnimation(empty)
	return table.Random(self.animTable[ANIM_FIRE][(self:GetIronsight() and ATTACK_IRON or ATTACK_NORMAL)][(empty and STATUS_EMPTY or (self:Clip1() == 0 and STATUS_DRY or STATUS_NORMAL))])
end

function SWEP:GetReloadAnimation()
	return table.Random(self.animTable[ANIM_RELOAD][(self:Clip1() == 0 and STATUS_DRY or STATUS_NORMAL)])
end

function SWEP:GetSprintAnimation(sprint, loop)
	return self.animTable[ANIM_SPRINT][(self:Clip1() == 0 and STATUS_EMPTY or STATUS_NORMAL)][loop and 2 or (sprint and 0 or 1)]
end

function SWEP:GetMeleeAnimation()
	return table.Random(self.animTable[ANIM_MELEE][(self:Clip1() == 0 and STATUS_EMPTY or STATUS_NORMAL)])
end

function SWEP:GetIronAnimation()
	return self.animTable[ANIM_IRON][(self:Clip1() == 0 and STATUS_EMPTY or STATUS_NORMAL)][(self:GetIronsight() and 1 or 0)]
end

function SWEP:GetCheckAnimation()
	return table.Random(self.animTable[ANIM_CHECK][(self:Clip1() == 0 and STATUS_EMPTY or STATUS_NORMAL)])
end

function SWEP:GetHolsterAnimation()
	return self.animTable[ANIM_HOLSTER][(self:Clip1() == 0 and STATUS_EMPTY or STATUS_NORMAL)]
end

function SWEP:GetDeployAnimation()
	return self.animTable[ANIM_DEPLOY][(self:Clip1() == 0 and STATUS_EMPTY or STATUS_NORMAL)]
end

function SWEP:GetIdleAnimation()
	return self.animTable[ANIM_IDLE][(self:GetIronsight() and 1 or 0)][(self:Clip1() == 0 and STATUS_EMPTY or STATUS_NORMAL)]
end

function SWEP:Initialize()
	if ( SERVER ) then
		self:SetNPCMinBurst( 30 )
		self:SetNPCMaxBurst( 30 )
		self:SetNPCFireRate( 0.01 )
	else
		self.emitter = ParticleEmitter(Vector(0, 0, 0))
		self.cycle = 0
	end
	
	self:SetWeaponHoldType(self.HoldType)
	self:SetIronsight(false)
end

function SWEP:Deploy()
	self:PlaySequence(self:GetDeployAnimation())
	self:SetNextPrimaryFire(CurTime() + (self.DeployTime or 1))
	return true
end


function SWEP:Holster(nextWeapon)
	self:SetReloading(false)
	self:SetSprint(false)
	self:SetMelee(false)
	self:SetIronsight(false)

	if (self.goHolster) then
		self.goHolster = nil
		return true
	end

	self:PlaySequence(self:GetHolsterAnimation())
	self:SetHolster(true)
	self.nextWeapon = nextWeapon
	self.holsterDelay = CurTime() + (self.HolsterTime or .7)

	return false
end

function SWEP:Think()	
	local owner = self.Owner
	local vel = owner:GetVelocity():Length()

	if (self:GetHolster() == true) then
		if (self.holsterDelay and self.holsterDelay < CurTime()) then
			owner:ConCommand("use " .. self.nextWeapon:GetClass())
			self.goHolster = true
			self.holsterDelay = nil
			self:SetHolster(false)
		end
	end

	if (!self.NoAmmoCheck and self:GetReloading() != true and self:GetSprint() != true and self:GetMelee() != true) then
		if (owner:KeyDown(IN_RELOAD)) then
			if (!self.checkAmmo) then
				self.checkAmmo = CurTime() + .5
			end

			if (!self.ammoTrigger and self:GetCheckAmmo() != true and self.checkAmmo < CurTime()) then
				self.ammoTrigger = true
				self:CheckAmmo()
			end
		else
			if (self.checkAmmo) then
				self.ammoTrigger = nil
				self.checkAmmo = nil
				if (!self.ammoTrigger and self:GetCheckAmmo() != true) then
					self:Reload(true)
				end
			end
		end
	end

	-- Sprint Think
	if (owner:OnGround() and owner:KeyDown(IN_SPEED) and vel > owner:GetWalkSpeed()*1.01) then
		if (!self:GetSprint()) then
			self:GoSprint(true)
		end
	else
		if (self:GetSprint()) then
			self:GoSprint(false)
		end
	end
end

function SWEP:CanReload()
	local clip = self:Clip1()
	local reserve = self:Ammo1()

	return (self:GetSprint() != true and 
			self:GetReloading() != true and
			self:GetMelee() != true and
			self:GetCheckAmmo() != true and
			clip < self.Primary.ClipSize and
			reserve > 0)
end

function SWEP:CheckAmmo()
	self:SetCheckAmmo(true)
	self:PlaySequence(self:GetIdleAnimation())
	timer.Simple(0, function()
		self:PlaySequence(self:GetCheckAnimation())
	end)			

	local checkTime =self.CheckAmmoTime or 3
	self:SetNextPrimaryFire(CurTime() + checkTime)
	self:SetNextSecondaryFire(CurTime() + checkTime)
	timer.Simple(checkTime, function()
		if (self and IsValid(self)) then
			self:SetCheckAmmo(false)
		end
	end)
end

function SWEP:Reload(call)
	if (!call) then
		return
	end

	if (!self:CanReload()) then
		return false
	end

	local reloadAnim = self:GetReloadAnimation()
	local vm = self.Owner:GetViewModel()
	local seq = vm:LookupSequence(reloadAnim)
	local reloadTime = self:SequenceDuration(reloadAnim)

	self:PlaySequence(self:GetIdleAnimation())
	timer.Simple(0, function()
		self:PlaySequence(reloadAnim)
	end)		

	self:SetIronsight(false)
	self:SetReloading(true)

	local reloadTimer = reloadTime*2
	if (self:Clip1() == 0 and self.EmptyReloadTime) then
		reloadTimer = self.EmptyReloadTime
	elseif (self.ReloadTime) then
		reloadTimer = self.ReloadTime
	end

	self.Owner.lastReloadWeapon = self
	timer.Simple(reloadTimer, function()
		if (self and IsValid(self) and self.Owner.lastReloadWeapon == self) then
			local clip = self:Clip1()
			local clipSize = self.Primary.ClipSize
			local reserve = self:Ammo1()
			local need = clipSize - clip

			self:SetReloading(false)
			self:SetClip1(clip + math.Clamp(need, 0, reserve))
			self.Owner:RemoveAmmo(math.Clamp(need, 0, reserve), self.Weapon:GetPrimaryAmmoType())
		end
	end)
end

function SWEP:GoSprint(bool)
	if (self:GetReloading() != true and self:GetMelee() != true and self:GetCheckAmmo() != true) then
		if (bool == true) then
			timer.Simple(self.TimeToSprint or .2, function()
				if (self and IsValid(self) and self:GetSprint()) then
					self:PlaySequence(self:GetSprintAnimation(bool, true))
				end
			end)
		end

		self:SetNextPrimaryFire( CurTime() + .4 )
		self:PlaySequence(self:GetSprintAnimation(bool))
		self:SetIronsight(false)
		self:SetSprint(bool)
	end
end

function SWEP:CanPrimaryAttack()
	if (self:GetSprint() == true) then
		return false
	end

	if (self:GetReloading() == true) then
		return false
	end

	if ( self.Weapon:Clip1() <= 0 ) then
		--self:EmitSound( "Weapon_Pistol.Empty" )
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		return false
	end

	return true
end

function SWEP:CanMeleeAttack()
	return (self:GetSprint() != true and self:GetIronsight() != true and self:GetReloading() != true
		and self:GetNextMelee() < CurTime())
end

function SWEP:MeleeAttack()
	if (!self:CanMeleeAttack()) then
		return
	end

	self:SetMelee(true)
	timer.Simple(self.MeleeRecoverTime or .7, function()
		if (self and IsValid(self)) then
			self:SetMelee(false)
		end
	end)

	self:PlaySequence(self:GetIdleAnimation())
	timer.Simple(0, function()
		self:PlaySequence(self:GetMeleeAnimation())
	end)			
	self:SetNextMelee(CurTime() + self.Melee.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Melee.Delay)
end

function SWEP:PrimaryAttack()

	self.Weapon:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if (!IsFirstTimePredicted()) then
		return
	end
		
	if (self.Owner:KeyDown(IN_USE)) then
		self:MeleeAttack()	
		return
	end

	if (self:GetSprint() != true and self:GetReloading() != true) then
		self:PlaySequence(self:GetIdleAnimation())
		timer.Simple(0, function()
			self:PlaySequence(self:GetFireAnimation(true))
		end)			
	end

	if ( !self:CanPrimaryAttack() ) then return end
	
	self.Weapon:EmitSound( self.Primary.Sound )
	self:CSShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone )
	self:TakePrimaryAmmo( 1 )
	
end

function SWEP:PlaySequence(name)
	if (type(name):lower() == "table") then
		name = table.Random(name)	
	end

	local vm = self.Owner:GetViewModel()
	local seq = vm:LookupSequence(name)
	vm:SetCycle(0)
	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(1)
end

function SWEP:CSShootBullet( dmg, recoil, numbul, cone )
	self.Owner:LagCompensation( true )
	print(1)
	numbul 	= numbul 	or 1
	cone 	= cone 		or 0.01
	local ironMul = (self:GetIronsight() and .5 or 1)

	local bullet = {}
	bullet.Num 		= numbul
	bullet.Src 		= self.Owner:GetShootPos()
	bullet.Dir 		= (self.Owner:EyeAngles() + self.Owner:GetViewPunchAngles()):Forward()
	bullet.Spread 	= Vector( cone, cone, 0 )*ironMul			
	bullet.Tracer	= 4									
	bullet.Force	= 5									
	bullet.Damage	= dmg
	bullet.Callback = function(client, trace, damageInfo)
		local e = EffectData()
		e:SetOrigin(trace.HitPos)
		e:SetNormal(trace.HitNormal)
		e:SetScale(math.Rand(.4, .5))
		util.Effect( "btImpact", e )
	end
	
	//self.Owner:ViewPunchReset()
	self.Owner:ViewPunch(Angle(self.Primary.Recoil*-math.Rand(.8, 1), self.Primary.Recoil*math.Rand(-1, 1), 0)*ironMul)
	self.Owner:FireBullets( bullet )
	self.Owner:MuzzleFlash()								
	self.Owner:SetAnimation( PLAYER_ATTACK1 )	
	self:PlaySequence(self:GetIdleAnimation())
	timer.Simple(0, function()
		self:PlaySequence(self:GetFireAnimation())
	end)			

	self.Owner:LagCompensation( false )

	if ( self.Owner:IsNPC() ) then return end

end

local IRONSIGHT_TIME = 0.25

local goodVector = {
	[1] = function(ang) return ang:Right() end,
	[2] = function(ang) return ang:Forward() end,
	[3] = function(ang) return ang:Up() end,
}
local function addVector(vec, vec2, ang)
	for i = 1, 3 do
		vec = vec + goodVector[i](ang)*vec2[i]
	end

	return vec
end

SWEP.NextSecondaryAtastck = 0
function SWEP:SecondaryAttack()
	if (self:GetSprint() == true or self:GetReloading() == true) then
		return		
	end
	
	self:PlaySequence(self:GetIronAnimation())
	self:SetIronsight(!self:GetIronsight())
	self.Weapon:SetNextPrimaryFire( CurTime() + .4 )
	self.Weapon:SetNextSecondaryFire( CurTime() + .4 )
end

function SWEP:DrawHUD()
end

function SWEP:OnRestore()
	self:SetReloading(false)
	self:SetSprint(false)
	self:SetMelee(false)
	self:SetIronsight(false)
	self.NextSecondaryAttack = 0
	self:SetIronsight(false)
end
