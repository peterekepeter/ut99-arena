
class FFNArenaBase expands Mutator abstract config(FFNArena);

const MAX_REPLACEMENT_RULES = 32;
const MAX_LOUADOUT_ITEM = 32;

var config string Description;
var config bool bFirstRun;
var config bool bDebugLog;
var config bool bDebugLogDamage;
var config string Replace[32];
var config bool bAutoGenerateAmmoReplacementRules;
var config bool bPreventAdditionalReplacements;
var config bool bUseNewReplacementEngine;
var config bool bRemoveDefaultInventory;
var config bool bShuffleWeapons;
var config bool bShuffleAdvancedWeaponSwitch;
var config int ShuffleTimer;
var config bool bSetPlayerStartingHealth;
var config int PlayerStartingHealth;
var config bool bDropWeapon;
var config bool bRegenAmmo;
var config float RegenAmmoTimer;
var config float RegenAmmoModifier;
var config bool bRegenAmmoInfinite;
var config string RegenAmmoExclude;
var config bool bRegenHealth;
var config float RegenHealthTimer;
var config int RegenHealthAmount;
var config int RegenHealthLimit;
var config string Loadout[32];
var config float DamageModifier;
var config float MomentumModifier;
var config float SelfDamageModifier;
var config float SelfMomentumModifier;
var config float TeamDamageModifier;
var config float TeamMomentumModifier;
var config bool bRemoveBulletKnockback;
var config bool bDropAllOnDeath;
var config bool bDropBootsOnDeath;
var config bool bDropUDamageOnDeath;
var config bool bDropInvisibilityOnDeath;
var config bool bDropRedeemerOnDeath;
var config bool bDropArmorOnDeath;

var DeathMatchPlus Game;
var bool bIsModifyingPlayer;
var bool bIsModifyingLevelPickups;
var bool bModifyTeamDamageOrMomentum;

var ArenaFFNLoadout ArenaLoadout;
var ArenaFFNReplaceEngine ReplacementRules;
var ArenaFFNShuffle ArenaShuffle;
var ArenaFFNAmmoRegen AmmoRegen;
var ArenaFFNHealthRegen HealthRegen;

var bool bGameStarted;

function PreBeginPlay()
{
	Nfo(Class$" "$Description);
	if ( bFirstRun )
	{
        // generate INI entries on first run
		bFirstRun = False;
		SaveConfig(); 
	}
	if ( bShuffleWeapons && bDropWeapon )
	{
		Nfo("setting bDropWeapon to False because bShuffleWeapons is True");
		bDropWeapon = False;
	}
	InitializeLouadout();
	InitializeReplacementRules();
	InitializeShuffleWeapons();
	InitializeAmmoRegen();
	InitializeHealthRegen();
	bIsModifyingLevelPickups = True;
	bIsModifyingPlayer = False;
	bGameStarted = False;
	Nfo("loaded"@ArenaLoadout.GetWeaponCount()@"weapons,"@ArenaLoadout.GetPickupCount()@"pickups for loadout");
	Nfo("registered"@ReplacementRules.GetRuleCount()@"replacement rules");
	if ( bDebugLog )
	{
		ReplacementRules.PrintAllRules();
	}
}

function InitializeLouadout()
{
	local int i;
	ArenaLoadout = Spawn(class'ArenaFFNLoadout');
	ArenaLoadout.SetRemoveDefaultInventory(bRemoveDefaultInventory);
	ArenaLoadout.ConfigurePlayerStartingHealth(bSetPlayerStartingHealth, PlayerStartingHealth);
	ArenaLoadout.SetCanThrowWeapon(bDropWeapon);
	for ( i = 0; i < MAX_LOUADOUT_ITEM; i = i + 1 )
	{
		ArenaLoadout.AddLoadoutConfigLine(Loadout[i]);
	}
}

function InitializeAmmoRegen()
{
	AmmoRegen = Spawn(class'ArenaFFNAmmoRegen');
	AmmoRegen.Initialize(bRegenAmmo && !(bShuffleWeapons && bShuffleAdvancedWeaponSwitch), RegenAmmoTimer, bRegenAmmoInfinite, RegenAmmoExclude, RegenAmmoModifier);
}

function InitializeHealthRegen()
{
	HealthRegen = Spawn(class'ArenaFFNHealthRegen');
	HealthRegen.Initialize(bRegenHealth, RegenHealthTimer, RegenHealthAmount, RegenHealthLimit);
}

function InitializeShuffleWeapons()
{
	if ( bShuffleAdvancedWeaponSwitch )
	{
		Nfo("ArenaFFNShuffle using advanced weapon switcher");
		ArenaShuffle = Spawn(class'ArenaFFNShuffleAdvanced');
	} 
	else 
	{
		Nfo("ArenaFFNShuffle using classic weapon switcher");
		ArenaShuffle = Spawn(class'ArenaFFNShuffle');
	}
	ArenaShuffle.Initialize(bShuffleWeapons, ShuffleTimer, ArenaLoadout, ReplacementRules);
}

function InitializeReplacementRules()
{
	local int i, errorCount;
	if ( bUseNewReplacementEngine )
	{
		ReplacementRules = Spawn(class'ArenaFFNReplaceUsingNodes');
	}
	else 
	{
		ReplacementRules = Spawn(class'ArenaFFNReplacementRules');
	}
    
	ReplacementRules.SetAutoGenerateAmmoReplacementRules(bAutoGenerateAmmoReplacementRules);
	ReplacementRules.SetPreventAdditionalReplacements(bPreventAdditionalReplacements);
	for ( i = 0; i < MAX_REPLACEMENT_RULES; i += 1 )
	{
		errorCount = ReplacementRules.AddRuleString(Replace[i]);
		if ( errorCount > 0 )
		{
			Err("Replace["$i$"] had "$errorCount$" error(s)");
		}
	}
}

function PostBeginPlay()
{
	SetTimer(1.0, True);
	Game = DeathMatchPlus(Level.Game);
	Super.PostBeginPlay();

	if ( Game != None )
	{

		bModifyTeamDamageOrMomentum = Game.bTeamGame && (
			TeamDamageModifier != 1.0 ||
			TeamMomentumModifier != 1.0
		);

		if ( DamageModifier != 1.0 || SelfDamageModifier != 1.0 || 
			MomentumModifier != 1.0 || SelfMomentumModifier != 1.0 )
		{
			Game.RegisterDamageMutator(Self);
		}
	}
	else 
	{
		Nfo("Incompatible gametype, expected gametype to be subclass of DeathMatchPlus, damage/momentum modifier will not work");
	}

}

function bool HandleEndGame()
{
	ArenaShuffle.HandleEndGame();
	
	if ( NextMutator != None )
		return NextMutator.HandleEndGame();
	return False;
}

function AddMutator(Mutator M)
{
    // don't add the same mutator twice, this can happen with this mutator
    // because if its custom handling when replacing the DM mutator with a custom mutator
	if ( M == Self ) return;
    // same functionality as parent
	Super.AddMutator(M); 
}

function ModifyPlayer(Pawn pawn)
{
	// called by GameInfo.RestartPlayer()
	local Bot bot;
	bGameStarted = True;
	bIsModifyingPlayer = True;
	bIsModifyingLevelPickups = False;

	if ( bShuffleWeapons )
	{
		ArenaShuffle.ModifyPlayer(pawn);
	} 
	else 
	{
		ArenaLoadout.ModifyPlayer(pawn);
	}

	if ( NextMutator != None )
		NextMutator.ModifyPlayer(pawn);

	bot = Bot(pawn);
	if ( bot != None )
		bot.bHasImpactHammer = (bot.FindInventoryType(class'ImpactHammer') != None);
	bIsModifyingPlayer = False;
}


function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, 
	out Vector Momentum, name DamageType)
{
	local int VictimTeam, InstigatorTeam, initialDamage;
	local float size, size2;
	local string msg;

	// save values for debug log
	initialDamage = ActualDamage;
	size = VSize(Momentum);

    // generic modifiers are always applied
	ActualDamage *= DamageModifier;
	Momentum *= MomentumModifier;

	if ( Victim == InstigatedBy ) 
	{
        // apply self damage/momentum modifiers
		ActualDamage *= SelfDamageModifier;
		Momentum *= SelfMomentumModifier;
	}
	else if (bModifyTeamDamageOrMomentum)
	{
        // apply team damage/momentum modifiers
		VictimTeam = -1;
		InstigatorTeam = -2;
		if ( Victim != None ) 
			VictimTeam = Victim.PlayerReplicationInfo.Team;
		if ( InstigatedBy != None ) 
			InstigatorTeam = InstigatedBy.PlayerReplicationInfo.Team;
		if ( VictimTeam == InstigatorTeam ) 
		{
			ActualDamage *= TeamDamageModifier;
			Momentum *= TeamMomentumModifier;
		}
	}
	
	if ( bRemoveBulletKnockback && DamageType == 'shot' ) 
		Momentum *= FClamp((size - 200) * 0.01,0,1);

	if ( NextDamageMutator != None )
		NextDamageMutator.MutatorTakeDamage( ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType );

	if ( bDebugLogDamage ) 
	{
		msg = "";
		msg = msg$"dmg: "$initialDamage$" ";
		if ( initialDamage != ActualDamage ) 
			msg = msg$"-> "$ActualDamage$" ";
		msg = msg$"dt: '"$DamageType$"' ";
		msg = msg$"momentum: "$int(size)$" ";
		size2 = VSize(Momentum);
		if ( size != size2 )
			msg = msg$"-> "$int(size2);
		Nfo(msg);
	}
}

function bool AlwaysKeep(Actor Other)
{
	local string replacementResult;

	if ( ReplacementRules.TryGetReplacementClassString(other, replacementResult) )
	{
		if ( ReplacementRules.IsKeep(replacementResult) )
		{
			if ( bDebugLog )
			{
				Nfo("keep"@other);
			}
			return True;
		} 
	}

	if ( NextMutator != None )
		return ( NextMutator.AlwaysKeep(Other) );
	return False;
}

function bool CheckReplacement(Actor other, out byte bSuperRelevant)
{ 
	local string replacementResult;
    // called by Mutator.IsRelevant
	if ( bIsModifyingPlayer ) 
	{
		return True;
	}
	if ( ReplacementRules.TryGetReplacementClassString(other, replacementResult) )
	{
		if ( ReplacementRules.IsKeep(replacementResult) )
		{
			if ( bDebugLog )
			{
				Nfo("keep"@other);
			}
			return True;
		} 
		else if (ReplacementRules.IsNone(replacementResult))
		{
			if ( bDebugLog )
			{
				Nfo("delete"@other);
			}
			return False;
		}
		else 
		{
			if ( bDebugLog )
			{
				Nfo("replace"@other@"with"@replacementResult);
			}
			ReplaceWith(other, replacementResult);
			return False;
		}
	}
    
	bSuperRelevant = 0;
	return True;
}

function Timer()
{
	local Pawn P;
	if ( !bGameStarted )
	{
		return;
	}
	if ( bShuffleWeapons ) 
	{
		ArenaShuffle.ShuffleTimerTickIfEnabled();
		for ( P = Level.PawnList; P != None; P = P.NextPawn )
		{
			bIsModifyingPlayer = True;
			ArenaShuffle.EnsurePlayerWeaponIfEnabled(P);
			bIsModifyingPlayer = False;
		}
	}
}

function bool PreventDeath(Pawn Killed, Pawn Killer, name damageType, vector HitLocation)
{
	local bool prevented;
	prevented = False;
	if ( NextMutator != None )
		prevented = NextMutator.PreventDeath(Killed,Killer, damageType,HitLocation);

	if ( !prevented )
		DropPawnInventory(Killed);
	
	return prevented;
}


function bool ShouldDrop(Inventory inv)
{
	return bDropAllOnDeath
		|| bDropBootsOnDeath && inv.IsA('UT_JumpBoots')
		|| bDropUDamageOnDeath && inv.IsA('UDamage')
		|| bDropInvisibilityOnDeath && inv.IsA('UT_Invisibility')
		|| bDropRedeemerOnDeath && inv.IsA('WarHeadLauncher')
		|| bDropArmorOnDeath && (inv.IsA('Armor2') || inv.IsA('ThighPads'))
		;
}

function DropPawnInventory( Pawn P )
{
	local inventory inv;
	local Ammo ammo;
	local weapon weap;
	local TournamentWeapon tweap;
	local float speed;
	local int i, invArrayCount;
	local Inventory invArray[64];


	// need to convert linked list to array, because we're wrecking the list
	for( inv = P.Inventory; inv != None; inv = inv.Inventory )
	{
		if ( !ShouldDrop(inv) ) continue;
		invArray[invArrayCount] = inv;
		invArrayCount += 1;
		if ( invArrayCount == 64 )
		{
			Err("Max droppable inventory reached!!!");
			break;
		}
	}

	// additional drop weapons
	for( i = 0; i < invArrayCount; i+=1 )
	{
		inv = invArray[i];

		weap = Weapon(inv);
		if ( weap != None )
		{
			// handle weapon
			speed = FMax(1, VSize(P.Velocity));
			weap.Velocity = Normal(P.Velocity / speed + 0.5 * VRand()) * (speed + 280);
			weap.Velocity.Z = Abs(weap.Velocity.Z);
			weap.SetLocation(P.Location);
	
			// copied from tournament weapon
			tweap = TournamentWeapon(weap);
			if ( tweap != None ) 
			{
				tweap.bCanClientFire = False;
				tweap.bSimFall = True;
				tweap.SimAnim.X = 0;
				tweap.SimAnim.Y = 0;
				tweap.SimAnim.Z = 0;
				tweap.SimAnim.W = 0;
			}
			weap.AIRating = weap.default.AIRating;
			weap.bMuzzleFlash = 0;
			if ( weap.AmmoType != None )
			{
				weap.PickupAmmoCount = weap.AmmoType.AmmoAmount;
				weap.AmmoType.AmmoAmount = 0;
			}
			weap.RespawnTime = 0.0; //don't respawn
			weap.SetPhysics(PHYS_Falling);
			weap.RemoteRole = ROLE_DumbProxy;
			weap.BecomePickup();
			weap.NetPriority = 2.5;
			weap.bCollideWorld = True;
			if ( Pawn(weap.Owner) != None )
				Pawn(weap.Owner).DeleteInventory(weap);
			weap.Inventory = None;
			weap.GotoState('PickUp', 'Dropped');
	
			if ( weap.PickupAmmoCount == 0 )
				weap.Destroy();
		}
	}

	// separate look for ammo because dropping weapon will deplete the ammo
	for( i = 0; i < invArrayCount; i+=1 )
	{
		ammo = Ammo(inv);
		if ( ammo != None )
		{
			if ( ammo.AmmoAmount == 0 )
			{
				continue; // dont drop useless
			}
		}
		else 
		{
			// not weapon, not ammo
			if ( inv.Charge == 0 ) 
			{
				continue; // dont drop useless
			}
		}
		speed = FMax(1, VSize(P.Velocity));
		inv.Velocity = Normal(P.Velocity / speed + 0.5 * VRand()) * (speed + 280);
		inv.Velocity.Z = Abs(inv.Velocity.Z);
		inv.SetLocation(P.Location);

		// drop it, copied from inventory
		inv.RespawnTime = 0.0; //don't respawn
		inv.SetPhysics(PHYS_Falling);
		inv.RemoteRole = ROLE_DumbProxy;
		inv.BecomePickup();
		inv.NetPriority = 2.5;
		inv.NetUpdateFrequency = 20;
		inv.bCollideWorld = True;
		inv.GotoState('PickUp', 'Dropped'); // deactivate item before changing owner
		if ( Pawn(inv.Owner) != None )
			Pawn(inv.Owner).DeleteInventory(inv); // changes owner to none
		inv.Inventory = None;
	}
}

static function Err(coerce string message)
{
	class'ArenaFFNUtil'.static.Err(message);
}

static function Nfo(coerce string message)
{
	class'ArenaFFNUtil'.static.Nfo(message);
} 

defaultproperties 
{
	Description="Your description here!"
	DamageModifier=1.0
	MomentumModifier=1.0
	SelfDamageModifier=1.0
	SelfMomentumModifier=1.0
	TeamDamageModifier=1.0
	TeamMomentumModifier=1.0
	bDropWeapon=True
	RegenAmmoTimer=1.000
	RegenAmmoModifier=0.100
	RegenAmmoExclude="Botpack.WarheadAmmo,Botpack.SuperShockCore"
	PlayerStartingHealth=100
	bShuffleAdvancedWeaponSwitch=True
	ShuffleTimer=30
	bFirstRun=True
	bAutoGenerateAmmoReplacementRules=True
	bPreventAdditionalReplacements=True
	RegenHealthTimer=1
	RegenHealthAmount=1
	RegenHealthLimit=100
}
