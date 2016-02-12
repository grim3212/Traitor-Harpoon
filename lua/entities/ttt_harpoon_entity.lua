ENT.Type = "anim"

if CLIENT then
   ENT.PrintName = "Harpoon"
   ENT.Icon = "vgui/ttt/icon_ttt_harpoon"
end

ENT.Purpose	= "To kill terrorists!"
ENT.Instructions = "Throw at your enemies!"
ENT.Spawnable = false
ENT.AdminOnly = true 
ENT.DoNotDuplicate = true 
ENT.DisableDuplicator = true
ENT.Projectile = true

ENT.Damage = 200
ENT.Stuck = false
ENT.CanHavePrints = false

if SERVER then

AddCSLuaFile()

/*---------------------------------------------------------
   Name: ENT:Initialize()
---------------------------------------------------------*/
function ENT:Initialize()
	self:SetModel("models/props_junk/harpoon002a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	local phys = self.Entity:GetPhysicsObject()
	--self.NextThink = CurTime() +  1

	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(10)
	end
	
	self.InFlight = true

	util.PrecacheSound("physics/metal/metal_grenade_impact_hard3.wav")
	util.PrecacheSound("physics/metal/metal_grenade_impact_hard2.wav")
	util.PrecacheSound("physics/metal/metal_grenade_impact_hard1.wav")
	util.PrecacheSound("physics/flesh/flesh_impact_bullet1.wav")
	util.PrecacheSound("physics/flesh/flesh_impact_bullet2.wav")
	util.PrecacheSound("physics/flesh/flesh_impact_bullet3.wav")

	self.Hit = { 
	Sound("physics/metal/metal_grenade_impact_hard1.wav"),
	Sound("physics/metal/metal_grenade_impact_hard2.wav"),
	Sound("physics/metal/metal_grenade_impact_hard3.wav")};

	self.FleshHit = { 
	Sound("physics/flesh/flesh_impact_bullet1.wav"),
	Sound("physics/flesh/flesh_impact_bullet2.wav"),
	Sound("physics/flesh/flesh_impact_bullet3.wav")}

	self:GetPhysicsObject():SetMass(2)	

	self.Entity:SetUseType(SIMPLE_USE)
	self.CanTool = false
end

/*---------------------------------------------------------
   Name: ENT:Think()
---------------------------------------------------------*/
function ENT:Think()
	if self.InFlight and self.Entity:GetAngles().pitch <= 55 then
		self.Entity:GetPhysicsObject():AddAngleVelocity(Vector(0, 10, 0))
	end
	
	if self.Stuck then return end

     local vel = self:GetVelocity()
     if vel == vector_origin then return end

     local tr = util.TraceLine({start=self:GetPos(), endpos=self:GetPos() + vel:GetNormal() * 20, filter={self, self:GetOwner()}, mask=MASK_SHOT_HULL})

     if tr.Hit and tr.HitNonWorld and IsValid(tr.Entity) then
        local other = tr.Entity
        if other:IsPlayer() then
           self:HitPlayer(other, tr)
        end
     end

     self:NextThink(CurTime())
     return true
end

/*---------------------------------------------------------
   Name: ENT:Disable()
---------------------------------------------------------*/
function ENT:Disable()
	self.PhysicsCollide = function() end
	self.InFlight = false
	self.Entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end

/*---------------------------------------------------------
   Name: ENT:HitPlayer()
---------------------------------------------------------*/
function ENT:HitPlayer(other, tr)
	self:EmitSound(self.FleshHit[math.random(1,#self.Hit)])
	self:Disable()

	--Kill the player
	local dmg = DamageInfo()
	dmg:SetDamage(self.Damage)
	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	dmg:SetDamageForce(self:EyeAngles():Forward())
	dmg:SetDamagePosition(self:GetPos())
	dmg:SetDamageType(DMG_SLASH)
	
	-- this bone is why we need the trace
   local bone = tr.PhysicsBone
   local pos = tr.HitPos
   local norm = tr.Normal
   local ang = Angle(-28,0,0) + norm:Angle()
   ang:RotateAroundAxis(ang:Right(), -90)
   pos = pos - (ang:Forward() * 8)
   
   local harpoon = self
   local prints = self.fingerprints
   
   other.effect_fn = function(rag)

                        if not IsValid(harpoon) or not IsValid(rag) then return end

                        harpoon:SetPos(pos)
                        harpoon:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                        harpoon:SetAngles(ang)

                        harpoon:SetMoveCollide(MOVECOLLIDE_DEFAULT)
                        harpoon:SetMoveType(MOVETYPE_VPHYSICS)

                        harpoon.fingerprints = prints
                        harpoon:SetNWBool("HasPrints", true)

                        -- harpoon:SetSolid(SOLID_NONE)
                        -- harpoon needs to be trace-able to get prints
                        local phys = harpoon:GetPhysicsObject()
                        if IsValid(phys) then
                           phys:EnableCollisions(false)
                        end

                        constraint.Weld(rag, harpoon, bone, 0, 0, true)

						--Use the same as knives on cleanup
                        rag:CallOnRemove("ttt_knife_cleanup", function() SafeRemoveEntity(knife) end)
                    end


   other:DispatchTraceAttack(dmg, self:GetPos() + ang:Forward() * 3, other:GetPos())

   self.Stuck = true
	
	-- As a thrown harpoon, after we hit a target we can never hit one again.
   -- If we are picked up and re-thrown, a new harpoon_proj entity is created.
   -- To make sure we can never deal damage twice, make HitPlayer do nothing.
	self.HitPlayer = util.noop
end

/*---------------------------------------------------------
   Name: ENT:PhysicsCollided()
---------------------------------------------------------*/
function ENT:PhysicsCollide(data, phys)
	if self.Stuck then return false end
	
	local Ent = data.HitEntity
	if !(Ent:IsValid() or Ent:IsWorld()) then return end

	if Ent:IsWorld() and self.InFlight then
			if data.Speed > 500 then
				self:EmitSound(Sound("weapons/ttt_harpoon/impact.mp3"))
				self:SetPos(data.HitPos - data.HitNormal * 10)
				self:SetAngles(self.Entity:GetAngles())
				self:GetPhysicsObject():EnableMotion(false)
			else
				self:EmitSound(self.Hit[math.random(1, #self.Hit)])
			end

			self:Disable()
			
	elseif Ent.Health then
		if not(Ent:IsPlayer() or Ent:IsNPC() or Ent:GetClass() == "prop_ragdoll") then 
			util.Decal("ManhackCut", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
			self:SetPos(data.HitPos - data.HitNormal * 10)
			self:SetAngles(self.Entity:GetAngles())
			self:SetParent(Ent)
			self:EmitSound(self.Hit[math.random(1, #self.Hit)])
			self:Disable()
		end

		if (Ent:IsPlayer() or Ent:IsNPC()) then 
			local effectdata = EffectData()
			effectdata:SetStart(data.HitPos)
			effectdata:SetOrigin(data.HitPos)
			effectdata:SetScale(1)
			util.Effect("BloodImpact", effectdata)
			
			local tr = util.TraceLine({start=self:GetPos(), endpos=Ent:LocalToWorld(Ent:OBBCenter()), filter={self, self:GetOwner()}, mask=MASK_SHOT_HULL})
			if tr.Hit and tr.Entity == Ent then
				self:HitPlayer(Ent, tr)
			end
			
			return true
			
		elseif Ent:GetClass() == "prop_ragdoll" then
			local effectdata = EffectData()
			effectdata:SetStart(data.HitPos)
			effectdata:SetOrigin(data.HitPos)
			effectdata:SetScale(1)
			util.Effect("BloodImpact", effectdata)
			
			self:EmitSound(self.FleshHit[math.random(1,#self.Hit)])
			self:Disable()
			
			--self.Entity:GetPhysicsObject():SetVelocity(data.OurOldVelocity / 4)
			self:SetPos(data.HitPos - data.HitNormal * 10)
			self:SetAngles(self.Entity:GetAngles())
			self:SetParent(Ent)
		end
	end

	self.Entity:SetOwner(NUL)
end

/*---------------------------------------------------------
   Name: ENT:Use()
---------------------------------------------------------*/
function ENT:Use(activator, caller) 
	if (activator:IsPlayer()) then
		if activator:GetWeapon("ttt_harpoon") == NULL then
			activator:Give("ttt_harpoon")
			self.Entity:Remove()
		else
			activator:GiveAmmo(1, "Harpoon")
			self.Entity:Remove()
		end
	end
end

end

if CLIENT then
	function ENT:Draw()
		self.Entity:DrawModel()
	end
end