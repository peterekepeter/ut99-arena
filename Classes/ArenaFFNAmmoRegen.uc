class ArenaFFNAmmoRegen extends ArenaFFNInfo;

var bool bEnabled;

function Initialize(bool enabled){
    bEnabled = enabled;
}

function ApplyAmmoRegenIfEnabled(Pawn P){
    local Weapon W;
    if (!bEnabled || P.Weapon == None){
        return;
    }
    W = P.Weapon;
    // regenerate some ammo
    if (!WeaponIsFiring(W) || RanOutOfAmmo(P,W))
    {
        // only regen when not firing, otherwise might break weapons
        // eg. biorifle alt fire seems to break if it receives ammo while charging
        P.Weapon.GiveAmmo(P);
    }
}

function bool WeaponIsFiring(Weapon W)
{
    if (W == None){
        return false;
    }
    if (W.bPointing || W.IsInState('NormalFire') || W.IsInState('AltFiring')){
        return true;
    }
    return false;
}

function bool RanOutOfAmmo(Pawn P, Weapon W)
{
    return GetCurrentAmmo(P,W) == 0;
}

function int GetCurrentAmmo(Pawn P, Weapon W){
    local Ammo Ammo;
    local Class<Ammo> AmmoClass;
    AmmoClass = W.AmmoName;
	if (AmmoClass == None)
		return -1; 
	Ammo = Ammo(P.FindInventoryType(AmmoClass));
    if (Ammo == None){
        return -1;
    }
    return Ammo.AmmoAmount;
}