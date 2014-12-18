if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
end

if ( CLIENT ) then
	SWEP.PrintName			= "Crowbar"			
	SWEP.Author				= "Black Tea"
	SWEP.Slot				= 3
	SWEP.SlotPos			= 1
end

SWEP.HoldType			= "ar2"
SWEP.Base				= "weapon_nmrih_melee"
SWEP.Category			= "No More Room In Hell"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/me_crowbar/v_me_crowbar.mdl"
SWEP.WorldModel			= "models/weapons/w_rif_m4a1.mdl"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Primary.Delay			= 1.2

SWEP.animTable = {
	[ANIM_IDLE] = {
		[STATUS_NORMAL] = {"Idle"},
		[STATUS_CHARGE] = {"Attack_Charge_Idle"}
	},

	[ANIM_HOLSTER] = {
		"Holster"
	},

	[ANIM_DEPLOY] = {
		"Draw"
	},
	
	[ANIM_FIRE] = {
		[STATUS_NORMAL] = {"Attack_Quick_2"},
		[STATUS_CHARGE] = {"Attack_Charge_End"}
	},

	[ANIM_SPRINT] = {
		"Sprint"
	},

	[ANIM_MELEE] = {
		"Shove"
	},

	[ANIM_CHARGE] = {
		"Attack_Charge_Begin"
	}
}

	local matBeam = Material( "effects/lamp_beam" )
	local GLOW_MATERIAL = Material("sprites/glow04_noz.vmt")
	function SWEP:ViewModelDrawn()
		local vm = self.Owner:GetViewModel()
		local at = vm:LookupAttachment("nmrih_trace_start")
		local atpos = vm:GetAttachment(at)

		if (!self.nextRecord or self.nextRecord < CurTime()) then
			self.trailPos.insert(atpos.Pos + atpos.Ang:Forward()*1 + atpos.Ang:Up()*-4 + atpos.Ang:Right()*30)
			self.nextRecord = CurTime() + .03
		end
	end

	function SWEP:PreDrawViewModel(vm, weapon, client)

		local vm = self.Owner:GetViewModel()
		local at = vm:LookupAttachment("nmrih_trace_start")
		local atpos = vm:GetAttachment(at)

		render.SetMaterial( matBeam )
		render.StartBeam( 3 )
			render.AddBeam(atpos.Pos + atpos.Ang:Forward()*1 + atpos.Ang:Up()*-4 + atpos.Ang:Right()*30, 8, .1, Color( 255, 255, 255, 255) )
			render.AddBeam(self.trailPos[0], 8, .2, Color(255, 255, 255, 255) )
			render.AddBeam(self.trailPos[1], 4, .3, Color( 255, 255, 255, 255) )
			render.AddBeam(self.trailPos[2], 2, .4, Color( 255, 255, 255, 255) )
		render.EndBeam()
	end