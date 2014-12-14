

if ( SERVER ) then

	AddCSLuaFile( "shared.lua" )
	
end

if ( CLIENT ) then
	SWEP.PrintName			= "Remington 500"			
	SWEP.Author				= "Black Tea"
	SWEP.Slot				= 3
	SWEP.SlotPos			= 1
end

SWEP.HoldType			= "ar2"
SWEP.Base				= "weapon_cs_base"
SWEP.Category			= "No More Room In Hell"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/fa_500a/v_fa_500a.mdl"
SWEP.WorldModel			= "models/weapons/w_rif_m4a1.mdl"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Primary.Sound			= Sound( "Weapon_500Pump.Single" )
SWEP.Primary.Recoil			= 1
SWEP.Primary.Damage			= 30
SWEP.Primary.NumShots		= 12
SWEP.Primary.Cone			= 0.08
SWEP.Primary.ClipSize		= 5
SWEP.Primary.Delay			= 0.8
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.NumShot	= 12
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "22LR"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.ShellType = SHELL_SHOTSHELL
SWEP.ShellAng = Angle(-30, 0, 0)

SWEP.animTable = {
	[ANIM_IDLE] = {
		[ATTACK_NORMAL] = {
			[STATUS_NORMAL] = {
				"idle01"
			},
			[STATUS_EMPTY] = {
				"idledry"
			},
		},
		[ATTACK_IRON] = {
			[STATUS_NORMAL] = {
				"Idle_Iron"
			},
			[STATUS_EMPTY] = {
				"Idle_Iron_dry"
			},
		}
	},

	[ANIM_HOLSTER] = {
		[STATUS_NORMAL] = {
			"holster"
		},
		[STATUS_EMPTY] = {
			"holsterdry"
		},
	},

	[ANIM_DEPLOY] = {
		[STATUS_NORMAL] = {
			"draw"
		},
		[STATUS_EMPTY] = {
			"drawdry"
		},
	},
	
	[ANIM_FIRE] = {
		[ATTACK_NORMAL] = {
			[STATUS_NORMAL] = {
				"fire1",
			},
			[STATUS_DRY] = {
				"Fire_Last",
			},
			[STATUS_EMPTY] = {
				"dryfire",
			}
		},

		[ATTACK_IRON] = {
			[STATUS_NORMAL] = {
				"Fire_Iron",
			},
			[STATUS_DRY] = {
				"Fire_Iron_Last",
			},
			[STATUS_EMPTY] = {
				"Fire_Iron_Dry",
			}
		},
	},

	[ANIM_RELOAD] = {
		[STATUS_NORMAL] = {
			"reload_end_nopump",
		},
		[STATUS_DRY] = {
			"reload_end",
		},
	},

	[ANIM_IRON] = {
		[STATUS_NORMAL] = {
			[0] = "Idle_to_Iron",
			[1] = "Iron_to_Idle"
		},
		[STATUS_EMPTY] = {
			[0] = "Idle_to_Iron_dry",
			[1] = "Iron_to_Idle_dry"
		},
	},

	[ANIM_SPRINT] = {
		[STATUS_NORMAL] = {
			[0] = "Idle_to_Sprint",
			[1] = "Sprint_to_Idle",
			[2] = "Sprint_Loop"
		},
		[STATUS_EMPTY] = {
			[0] = "Idle_to_Sprint_empty",
			[1] = "Sprint_to_Idle_Empty",
			[2] = "Sprint_Empty_Loop"
		},
	},

	[ANIM_MELEE] = {
		[STATUS_NORMAL] = {
			"Shove",
		},
		[STATUS_EMPTY] = {
			"Shove_dry",
		},
	},

	[ANIM_CHECK] = {
		[STATUS_NORMAL] = {
			"AmmoCheck_Full",
		},
		[STATUS_EMPTY] = {
			"AmmoCheck_Empty",
		},
	},
}
SWEP.LoadAnim = "reload2ne"

SWEP.NextLoadTime = 1
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

	if (self:GetReloading() == true) then
		if ((!self.nextLoad or self.nextLoad < CurTime()) and self.stopLoad != true) then
			self:SetClip1(self:Clip1() + 1)
			self.Owner:RemoveAmmo(1, self.Weapon:GetPrimaryAmmoType())

			-- to unscrew reload animation -.-
			self:PlaySequence("reload_end")
			local vm = self.Owner:GetViewModel()
			vm:SetPlaybackRate(0)

			timer.Simple(-0, function()
				self:PlaySequence(self.LoadAnim or "reload2ne")
			end)

			if (self:Clip1() >= self.Primary.ClipSize or owner:KeyDown(IN_ATTACK)) then
				self.stopLoad = true
				if (IsFirstTimePredicted()) then
					timer.Simple(self.NextLoadTime, function()
						if (self and IsValid(self)) then
							self.stopLoad = false
							self:SetNextPrimaryFire( CurTime() + .8 )
							local reloadAnim = self:GetReloadAnimation()
							self:PlaySequence(reloadAnim)
							self:SetReloading(false)
						end
					end)
				end
			end

			self.nextLoad = CurTime() + self.NextLoadTime
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

function SWEP:Reload(call)
	if (!call) then
		return
	end

	if (!self:CanReload()) then
		return false
	end

	self.nextLoad = CurTime() + .8
	self:PlaySequence("reload_start")
	self:SetIronsight(false)
	self:SetReloading(true)
end

btSoundRegister("Weapon_ShotgunPump.Single", {
	"weapons/firearms/shtg_remington870/remington_fire_01.wav",
}, 5)
btSoundRegister("Weapon_ShotgunPump.DryFire", {
	"weapons/firearms/shtg_remington870/Shotgun_Pump_DryFire2.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_DryFire2.wav",
}, 5, CHAN_ITEM)
btSoundRegister("Weapon_ShotgunPump.PumpBack", {
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Back4.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Back4.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Back4.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Back4.wav",
}, 5, CHAN_ITEM)
btSoundRegister("Weapon_ShotgunPump.PumpForward", {
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Forward4.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Forward4.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Forward4.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_Forward4.wav",
}, 5, CHAN_ITEM)
btSoundRegister("Weapon_ShotgunPump.LoadShell", {
	"weapons/firearms/shtg_remington870/Shotgun_Pump_LoadShell1.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_LoadShell1.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_LoadShell1.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_LoadShell1.wav",
	"weapons/firearms/shtg_remington870/Shotgun_Pump_LoadShell1.wav",
}, 5, CHAN_ITEM)
btSoundRegister("Weapon_ShotgunPump.LoadShell_Special", {
	"weapons/firearms/shtg_remington870/Shotgun_Pump_LoadShell3.wav",
}, 5, CHAN_ITEM)