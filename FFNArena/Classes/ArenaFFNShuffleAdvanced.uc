class ArenaFFNShuffleAdvanced extends ArenaFFNShuffle;

//
//	Advanced weapon enforcement
//  	

function EnforcePlayerWeapon(Pawn P)
{
	local Inventory i;
	local Weapon w;
	local Ammo a;
	local class<Weapon> weaponClass;
	local class<Ammo> ammoClass;
	local int sinceShuffle;
	
	sinceShuffle = ShuffleTimer - ShuffleTimerCounter;

	weaponClass = ArenaLouadout.GetWeaponClass(CurrentShuffleWeaponIndex);
	ammoClass = weaponClass.default.AmmoName;

	if (sinceShuffle == 0 || sinceShuffle >= 2)
	{
		GiveWeapon(P, weaponClass);
	}

	for ( i = P.Inventory; i!=None; i = i.Inventory )
	{
		a = Ammo(i);
		if (a != None)
		{
			if (a.class != ammoClass)
			{
				a.AmmoAmount = 0;
			}
			else 
			{
				a.AmmoAmount = 100;
			}
		}
		ArenaLouadout.GetWeaponClass(CurrentShuffleWeaponIndex);

		w = Weapon(i);
		if (w != None)
		{

			if (w.class != weaponClass)
			{
				w.AutoSwitchPriority = 0;
				if(sinceShuffle >= 1)
				{
					i.Destroy();
				}
			}
			else 
			{
				w.AutoSwitchPriority = 1;
			}
		}
	}

	if (sinceShuffle == 0 || sinceShuffle >= 2)
	{
		P.SwitchToBestWeapon();
	}

}


function GiveWeapon(Pawn PlayerPawn, class < Weapon> weaponClass )
{
	local Weapon NewWeapon;

	if( PlayerPawn.FindInventoryType(WeaponClass) != None )
		return;
	newWeapon = Spawn(WeaponClass);
	if( newWeapon != None )
	{
		newWeapon.bCanThrow = False;
		newWeapon.RespawnTime = 0.0;
		newWeapon.GiveTo(PlayerPawn);
		newWeapon.bHeldItem = True;
		newWeapon.GiveAmmo(PlayerPawn);
		newWeapon.SetSwitchPriority(PlayerPawn);
		newWeapon.WeaponSet(PlayerPawn);
		newWeapon.AmbientGlow = 0;
		newWeapon.AutoSwitchPriority = 100;
	}
}
	