class ArenaFFNAmmoRegen extends ArenaFFNInfo;

var bool bEnabled;
var bool bInfiniteAmmo;
var float PeriodSeconds;
var float AmmoAmountScale;
var ArenaFFNClassFilter ExcludeClassFilter;

function Initialize(bool enabled, float regenSeconds, bool infiniteAmmo, string excludeClasses, float regenAmmoModifier)
{
	bEnabled = enabled;
	bInfiniteAmmo = infiniteAmmo;
	PeriodSeconds = regenSeconds;
	AmmoAmountScale = regenAmmoModifier;
	if (enabled)
	{
		ExcludeClassFilter = Spawn(class'ArenaFFNClassFilter');
		ExcludeClassFilter.AddMatchClassesLine(excludeClasses);
		OptimizeExcludeClasses();
		SetTimer(PeriodSeconds*Level.TimeDilation, True);
	}
}

function Timer()
{
	local Pawn P;
	for (P=Level.PawnList; P!=None; P=P.NextPawn)
	{
		if (P.bIsPlayer)
		{
			ApplyAmmoRegen(P);
		}
	}
}

function ApplyAmmoRegen(Pawn P)
{
	local Ammo A;
	local Inventory Inv;
	local int amount;

	if (bInfiniteAmmo)
	{
		for( Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory )   
		{
			A = Ammo(Inv);
			if (A != None)
			{
				if (ExcludeClassFilter.Matches(A.class))
				{
					continue;
				}
				A.AmmoAmount = 100;
			}
		}
	}
	else if (True)
	{
		for( Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory )   
		{
			A = Ammo(Inv);
			if (A != None)
			{
				if (ExcludeClassFilter.Matches(A.class))
				{
					continue;
				}
				amount = A.default.AmmoAmount * AmmoAmountScale;
				if (amount <= 0)
				{
					amount = 1;
				}
				A.AddAmmo(amount);
			}
		}
	}

}

function bool WeaponIsFiring(Weapon W)
{
	if (W == None)
	{
		return False;
	}
	if (W.bPointing || W.IsInState('NormalFire') || W.IsInState('AltFiring'))
	{
		return True;
	}
	return False;
}

function bool RanOutOfAmmo(Pawn P, Weapon W)
{
	return GetCurrentAmmo(P,W) == 0;
}

function int GetCurrentAmmo(Pawn P, Weapon W)
{
	local Ammo Ammo;
	local class<Ammo> AmmoClass;
	AmmoClass = W.AmmoName;
	if (AmmoClass == None)
		return -1; 
	Ammo = Ammo(P.FindInventoryType(AmmoClass));
	if (Ammo == None)
	{
		return -1;
	}
	return Ammo.AmmoAmount;
}

function OptimizeExcludeClasses()
{
	// convert weapon classes to ammo classes
	local ArenaFFNClassFilter optimized;
	local int i;
	local class matcher, rootWeaponClass, rootAmmoClass;
	local class<Weapon> weaponClass;

	rootWeaponClass = class'Weapon';
	rootAmmoClass = class'Ammo';
	optimized = Spawn(class'ArenaFFNClassFilter');

	for (i=0; ExcludeClassFilter.Matchers[i] != None; i=i+1)
	{
		matcher = ExcludeClassFilter.Matchers[i];
		if (matcher == rootWeaponClass)
		{
			Err("excluding Engine.Weapon from ammo regen doesn't make sense");
			continue;
		}
		if (ClassIsChildOf(matcher, rootWeaponClass))
		{
			weaponClass = class<Weapon>(matcher);
			matcher = weaponClass.default.AmmoName;
			Nfo("ammo regen transforming"@weaponClass@"into"@matcher);
		}
		if (matcher == rootAmmoClass)
		{
			Err("excluding Engine.Ammo from ammo regen doesn't make sense");
			continue;
		}
		if (optimized.Matches(matcher))
		{
			Err("regen ammo exclude already matches"@matcher@"check for duplicate rule or subclass");
			continue;
		}
		if (!ClassIsChildOf(matcher, rootAmmoClass))
		{
			Err(matcher@"not subclass of Engine.Ammo");
			continue;
		}
		optimized.AddMatchClass(matcher);
	}
	ExcludeClassFilter = optimized;
	Nfo("excluding "$ExcludeClassFilter.MatchersCount$" ammo clases from ammo regen");
}