--Add different things that are needed

print("Grim3212 Initializing Harpoon")

if CLIENT then
	language.Add("AMMO_HARPOON", "Harpoon")
end

game.AddAmmoType( {
	name = "Harpoon",
	dmgtype = DMG_BULLET
} )
