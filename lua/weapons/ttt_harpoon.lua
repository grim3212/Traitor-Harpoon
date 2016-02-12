-- First some standard GMod stuff
if SERVER then
   AddCSLuaFile()
end

if CLIENT then
   SWEP.PrintName = "Harpoon"
   SWEP.Slot = 7
   SWEP.Icon = "VGUI/ttt/icon_ttt_harpoon"
   
   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "A throwable harpoon that is a one shot kill."
   };
end

-- Always derive from weapon_tttbase directly or indirectly
SWEP.Base = "ttt_custom_swep_model_base"

-- Standard GMod values
SWEP.Primary.Ammo = "Harpoon"
SWEP.Primary.Delay = 0
SWEP.Primary.Recoil = 0
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 0
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Round = ("ttt_harpoon_entity")
SWEP.Primary.Sound = Sound( "Weapon_harpoon.Thrown" )
SWEP.Primary.IronAccuracy = 0 -- Ironsight accuracy, should be the same for shotguns
--none of this matters for IEDs and other ent-tossing sweps

-- Ironsights
SWEP.IronSightsPos = Vector(-0.24, 0, 0.039)
SWEP.IronSightsAng = Vector(0, 0, 0)

-- Model properties
SWEP.HoldType = "melee"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = false
SWEP.ViewModel = "models/weapons/ttt_harpoon/v_invisib.mdl"
SWEP.WorldModel = "models/weapons/ttt_harpoon/w_ttt_harpoon.mdl"
SWEP.ViewModelBoneMods = {
	["l-upperarm"] = { scale = Vector(1, 1, 1), pos = Vector(-7.223, 1.667, 7.592), angle = Angle(7.777, 0, 0) },
	["r-upperarm-movement"] = { scale = Vector(1, 1, 1), pos = Vector(-30, -30, -30), angle = Angle(0, 0, 0) },
	["Da Machete"] = { scale = Vector(1, 1, 1), pos = Vector(-15.37, -6.112, -1.297), angle = Angle(0, 0, 0) },
	["l-upperarm-movement"] = { scale = Vector(1, 1, 1), pos = Vector(3.615, 0.546, 4.635), angle = Angle(-45.93, -39.95, -76.849) },
	["l-forearm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-3.932, -42.389, 171.466) },
	["lwrist"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-47.502, -5.645, 0.55) },
	["r-upperarm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(7.335, 0, 0) }
}

SWEP.VElements = {
	["harpoon"] = { type = "Model", model = "models/weapons/ttt_harpoon/w_ttt_harpoon.mdl", bone = "Da Machete", rel = "", pos = Vector(-23.378, 1.557, 23.377), angle = Angle(-26.883, 64.286, -155.456), size = Vector(1.014, 1.014, 1.014), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

-- TTT config values

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EQUIP2

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2, then this gun can
-- be spawned as a random weapon.
SWEP.AutoSpawnable = false

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = nil

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_TRAITOR }

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = true

-- InLoadoutFor is a table of ROLE_* entries that specifies which roles should
-- receive this weapon as soon as the round starts. In this case, None.
SWEP.InLoadoutFor = { nil }

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
SWEP.IsSilent = true

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = false

-- Precache custom sounds
function SWEP:Precache()
   util.PrecacheSound( "weapons/ttt_harpoon/deploy.mp3" )
end

-- Give the primary sound an alias
sound.Add ( {
   name = "Weapon_harpoon.Thrown",
   channel = CHAN_USER_BASE + 10,
   volume = 1.0,
   sound = "weapons/ttt_harpoon/deploy.mp3"
} )

-- Tell the server that it should download our icon to clients.
if SERVER then
   -- It's important to give your icon a unique name. GMod does NOT check for
   -- file differences, it only looks at the name. This means that if you have
   -- an icon_ak47, and another server also has one, then players might see the
   -- other server's dumb icon. Avoid this by using a unique name.
   resource.AddFile("materials/VGUI/ttt/icon_ttt_harpoon.vmt")
end

function SWEP:PrimaryAttack()
	self:FireRocket()
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.Weapon:SetNextPrimaryFire(CurTime()+1/1)
	self.Weapon:EmitSound(Sound("Weapon_Knife.Slash"))
	self.Weapon:TakePrimaryAmmo(1)
	self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
	self:CheckWeaponsAndAmmo()
end

function SWEP:FireRocket()
	pos = self.Owner:GetShootPos()
	if SERVER then
	local rocket = ents.Create(self.Primary.Round)
	if !rocket:IsValid() then return false end
	rocket:SetAngles(self.Owner:GetAimVector():Angle())
	rocket:SetPos(pos)
	rocket:SetOwner(self.Owner)
	rocket:Spawn()
	rocket.Owner = self.Owner
	rocket:Activate()
	eyes = self.Owner:EyeAngles()
		local phys = rocket:GetPhysicsObject()
			phys:SetVelocity(self.Owner:GetAimVector() * 2000)
	end
		if SERVER and !self.Owner:IsNPC() then
			local anglo = Angle(-10, -5, 0)
			self.Owner:ViewPunch(anglo)
		end

end

function SWEP:CheckWeaponsAndAmmo()
	if SERVER and self.Weapon != nil then
		if self.Weapon:Clip1() == 0 && self.Owner:GetAmmoCount( self.Weapon:GetPrimaryAmmoType() ) == 0 then
			timer.Simple(.1, function() if SERVER then if not IsValid(self) then return end
				if self.Owner == nil then return end
				self.Owner:StripWeapon("ttt_harpoon")
			end end)
		else
			self:Reload()
		end
	end
end

function SWEP:Reload()
	if not IsValid(self) then return end if not IsValid(self.Owner) then return end

	if self.Owner:IsNPC() then
		self.Weapon:DefaultReload(ACT_VM_RELOAD)
	return end

	if self.Owner:KeyDown(IN_USE) then return end
		self.Weapon:DefaultReload(ACT_VM_DRAW)

	if !self.Owner:IsNPC() then
		if self.Owner:GetViewModel() == nil then self.ResetSights = CurTime() + 3 else
			self.ResetSights = CurTime() + self.Owner:GetViewModel():SequenceDuration()
		end
	end
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:Think()
end