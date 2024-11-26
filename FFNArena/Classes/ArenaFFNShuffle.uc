class ArenaFFNShuffle extends ArenaFFNInfo;

var bool bEnabled;
var int ShuffleTimerCounter;
var int CurrentShuffleWeaponIndex;
var int NextShuffleWeaponIndex;
var int ShuffleTimer;
var ArenaFFNLoadout ArenaLouadout;
var color ShuffleMessageColor;
var string CurrentWeaponString;
var string NextWeaponDisplayName;

function Initialize(bool enabled, int timerSeconds, ArenaFFNLoadout louadoutInstance, ArenaFFNReplaceEngine replacementRules)
{
	local int weaponCount;
	local string rule;
	bEnabled = enabled;
	if (!enabled)
	{
		return;
	}
	ShuffleTimer = timerSeconds;
	weaponCount = louadoutInstance.GetWeaponCount();
	ArenaLouadout = louadoutInstance;
	ShuffleTimerCounter = ShuffleTimer;
	if (weaponCount <= 1)
	{
		bEnabled = False;
		Nfo("bShuffleWeapons requires at least 2 weapons to work, disabling bShuffleWeapons");
		return;
	}

	rule = "Engine.Weapon->None,Engine.Ammo->None";
	NextShuffleWeaponIndex = Rand(weaponCount);
	NextShuffleWeapon();
	ReplacementRules.AddRuleString(rule);
	Nfo("bShuffleWeapons disables weapon pickups by adding level replacement rule"@rule);
}

function ShuffleTimerTickIfEnabled()
{
	if (!bEnabled)
	{
		return;
	}
	ShuffleTimerCounter -= 1;
	if (ShuffleTimerCounter <= 0)
	{
		NextShuffleWeapon();
	}
}

function NextShuffleWeapon()
{
	local int weaponCount;
	weaponCount = ArenaLouadout.GetWeaponCount();
	CurrentShuffleWeaponIndex = NextShuffleWeaponIndex;
	NextShuffleWeaponIndex = Rand(weaponCount);
    // make sure next weapon is always different
	if (CurrentShuffleWeaponIndex == NextShuffleWeaponIndex)
	{
		NextShuffleWeaponIndex = (NextShuffleWeaponIndex + 1) % weaponCount;
	}
	ShuffleTimerCounter = ShuffleTimer;
	CurrentWeaponString = ArenaLouadout.GetWeaponString(CurrentShuffleWeaponIndex);
	NextWeaponDisplayName = ArenaLouadout.GetWeaponClass(NextShuffleWeaponIndex).default.ItemName;
}

function ModifyPlayer(Pawn pawn)
{
	ArenaLouadout.ModifyPlayerInventory(pawn);
	ArenaLouadout.ModifyPlayerHealth(pawn);
	ArenaLouadout.GivePickups(pawn);
	DestroyPlayerWeapons(pawn);
	class'ArenaFFNUtil'.static.GiveWeapon(pawn, CurrentWeaponString, False);
}

function EnsurePlayerWeaponIfEnabled(Pawn P)
{
	if ( !bEnabled )
	{
		return;
	}

	if ( !P.IsA('Spectator') )
	{
		EnforcePlayerWeapon(P);
	}
	if ( P.IsA('PlayerPawn') )
	{
		if ( ShuffleTimerCounter > 0 && ShuffleTimerCounter <= 3 ) 
		{
			ShowShuffleMessage(P);
		}
	}
}

function EnforcePlayerWeapon(Pawn P)
{
	DestroyPlayerWeapons(P);
	class'ArenaFFNUtil'.static.GiveWeapon(P, CurrentWeaponString, False);
}

function ShowShuffleMessage(Pawn pawn)
{
	local PlayerPawn player;

	player = PlayerPawn(pawn);
	if ( player == None )
	{
		return; // no player to show message for
	}

	player.ClearProgressMessages();
	player.SetProgressTime(1);
    
	player.SetProgressColor(ShuffleMessageColor, 5);
	player.SetProgressMessage(NextWeaponDisplayName$" in "$ShuffleTimerCounter, 5);
}

function DestroyPlayerWeapons(pawn PlayerPawn)
{
	local Inventory i;
	local Weapon w;
    
	for( i = PlayerPawn.Inventory; i!=None; i = i.Inventory )
	{
		w = Weapon(i);
		if (w != None)
		{
			i.Destroy();
			w.Finish();
		}
	}
	PlayerPawn.Weapon = None;
}

defaultproperties 
{
	ShuffleMessageColor=(R=255,G=255,B=255)
}
