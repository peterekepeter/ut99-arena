
class ArenaFFN expands Mutator abstract;

const MAX_REPLACEMENT_RULES = 32;
const MAX_LOUADOUT_ITEM = 32;

var config string Description;
var config bool bFirstRun;
var config bool bDebugLog;
var config string Replace[32];
var config bool bAutoGenerateAmmoReplacementRules;
var config bool bPreventAdditionalReplacements;
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

var DeathMatchPlus Game;
var bool bIsModifyingPlayer;
var bool bIsModifyingLevelPickups;
var bool bModifyTeamDamageOrMomentum;

var ArenaFFNLoadout ArenaLoadout;
var ArenaFFNReplacementRules ReplacementRules;
var ArenaFFNShuffle ArenaShuffle;
var ArenaFFNAmmoRegen AmmoRegen;
var ArenaFFNHealthRegen HealthRegen;

var bool bGameStarted;

function PreBeginPlay(){
	Nfo(Class$" "$Description);
	if (bFirstRun){
        // generate INI entries on first run
		bFirstRun=False;
		SaveConfig(); 
	}
	if (bShuffleWeapons && bDropWeapon){
		Nfo("setting bDropWeapon to False because bShuffleWeapons is True");
		bDropWeapon = false;
	}
	InitializeLouadout();
	InitializeReplacementRules();
	InitializeShuffleWeapons();
	InitializeAmmoRegen();
	InitializeHealthRegen();
	bIsModifyingLevelPickups = true;
	bIsModifyingPlayer = false;
	bGameStarted = false;
	Nfo("loaded"@ArenaLoadout.GetWeaponCount()@"weapons,"@ArenaLoadout.GetPickupCount()@"pickups for loadout");
	Nfo("registered"@ReplacementRules.GetRuleCount()@"replacement rules");
	if (bDebugLog){
		ReplacementRules.PrintAllRules();
	}
}

function InitializeLouadout(){
	local int i;
	ArenaLoadout = Spawn(class'ArenaFFNLoadout');
	ArenaLoadout.SetRemoveDefaultInventory(bRemoveDefaultInventory);
	ArenaLoadout.ConfigurePlayerStartingHealth(bSetPlayerStartingHealth, PlayerStartingHealth);
	ArenaLoadout.SetCanThrowWeapon(bDropWeapon);
	for (i=0; i<MAX_LOUADOUT_ITEM; i=i+1){
		ArenaLoadout.AddLoadoutConfigLine(Loadout[i]);
	}
}

function InitializeAmmoRegen(){
	AmmoRegen = Spawn(class'ArenaFFNAmmoRegen');
	AmmoRegen.Initialize(bRegenAmmo && !(bShuffleWeapons && bShuffleAdvancedWeaponSwitch), RegenAmmoTimer, bRegenAmmoInfinite, RegenAmmoExclude, RegenAmmoModifier);
}

function InitializeHealthRegen(){
	HealthRegen = Spawn(class'ArenaFFNHealthRegen');
	HealthRegen.Initialize(bRegenHealth, RegenHealthTimer, RegenHealthAmount, RegenHealthLimit);
}

function InitializeShuffleWeapons(){
	if (bShuffleAdvancedWeaponSwitch){
		Nfo("ArenaFFNShuffle using advanced weapon switcher");
		ArenaShuffle = Spawn(class'ArenaFFNShuffleAdvanced');
	} else {
		Nfo("ArenaFFNShuffle using classic weapon switcher");
		ArenaShuffle = Spawn(class'ArenaFFNShuffle');
	}
	ArenaShuffle.Initialize(bShuffleWeapons, ShuffleTimer, ArenaLoadout, ReplacementRules);
}

function InitializeReplacementRules(){
	local int i, errorCount;
	ReplacementRules = Spawn(class'ArenaFFNReplacementRules');
    
	ReplacementRules.bAutoGenerateAmmoReplacementRules = bAutoGenerateAmmoReplacementRules;
	ReplacementRules.bPreventAdditionalReplacements = bPreventAdditionalReplacements;
	for (i = 0; i < MAX_REPLACEMENT_RULES; i += 1){
		errorCount = ReplacementRules.AddRuleString(Replace[i]);
		if (errorCount > 0){
			Err("Replace["$i$"] had "$errorCount$" error(s)");
		}
	}
}

function PostBeginPlay()
{
	SetTimer(1.0, true);
	Game = DeathMatchPlus(Level.Game);
	Super.PostBeginPlay();

	if (Game != None){

		bModifyTeamDamageOrMomentum = Game.bTeamGame && (
			TeamDamageModifier != 1.0 ||
			TeamMomentumModifier != 1.0
		);

		if (DamageModifier != 1.0 || SelfDamageModifier != 1.0 || 
			MomentumModifier != 1.0 || SelfMomentumModifier != 1.0)
		{
			Game.RegisterDamageMutator(self);
		}
	}
	else {
		Nfo("Incompatible gametype, expected gametype to be subclass of DeathMatchPlus, damage/momentum modifier will not work");
	}

}

function AddMutator(Mutator M)
{
    // don't add the same mutator twice, this can happen with this mutator
    // because if its custom handling when replacing the DM mutator with a custom mutator
	if (M == self) return;
    // same functionality as parent
	super.AddMutator(M); 
}

function ModifyPlayer(Pawn pawn)
{
	// called by GameInfo.RestartPlayer()
	local Bot bot;
	bGameStarted = true;
	bIsModifyingPlayer = true;
	bIsModifyingLevelPickups = false;

	if (bShuffleWeapons){
		ArenaShuffle.ModifyPlayer(pawn);
	} 
	else {
		ArenaLoadout.ModifyPlayer(pawn);
	}

	if ( NextMutator != None )
		NextMutator.ModifyPlayer(pawn);

	bot = Bot(pawn);
	if ( bot != None )
		bot.bHasImpactHammer = (bot.FindInventoryType(class'ImpactHammer') != None);
	bIsModifyingPlayer = false;
}


function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, 
out Vector Momentum, name DamageType)
{
	local int VictimTeam;
	local int InstigatorTeam;

    // generic modifiers are always applied
	ActualDamage *= DamageModifier;
	Momentum *= MomentumModifier;

	if (Victim == InstigatedBy) 
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
		if (Victim != None) 
			VictimTeam = Victim.PlayerReplicationInfo.Team;
		if (InstigatedBy != None) 
			InstigatorTeam = InstigatedBy.PlayerReplicationInfo.Team;
		if (VictimTeam == InstigatorTeam) {
			ActualDamage *= TeamDamageModifier;
			Momentum *= TeamMomentumModifier;
		}
	}
	if ( NextDamageMutator != None )
		NextDamageMutator.MutatorTakeDamage( ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType );
}

function bool AlwaysKeep(Actor Other)
{
	local string replacementResult;

	if (ReplacementRules.TryGetReplacementClassString(other, replacementResult)){
		if (ReplacementRules.IsKeep(replacementResult)){
			if (bDebugLog){
				Nfo("keep"@other);
			}
			return true;
		} 
	}

	if ( NextMutator != None )
		return ( NextMutator.AlwaysKeep(Other) );
	return false;
}

function bool CheckReplacement(Actor other, out byte bSuperRelevant)
{ 
	local string replacementResult;
    // called by Mutator.IsRelevant
	if (bIsModifyingPlayer) {
		return true;
	}
	if (ReplacementRules.TryGetReplacementClassString(other, replacementResult)){
		if (ReplacementRules.IsKeep(replacementResult)){
			if (bDebugLog){
				Nfo("keep"@other);
			}
			return true;
		} 
		else if (ReplacementRules.IsNone(replacementResult)){
			if (bDebugLog){
				Nfo("delete"@other);
			}
			return false;
		}
		else {
			if (bDebugLog){
				Nfo("replace"@other@"with"@replacementResult);
			}
			ReplaceWith(other, replacementResult);
			return false;
		}
	}
    
	bSuperRelevant = 0;
	return true;
}

function Timer()
{
	local Weapon W;
	local Pawn P;
	if (!bGameStarted){
		return;
	}
	ArenaShuffle.ShuffleTimerTickIfEnabled();
	for (P=Level.PawnList; P!=None; P=P.NextPawn)
	{
		bIsModifyingPlayer = true;
		ArenaShuffle.EnsurePlayerWeaponIfEnabled(P);
		bIsModifyingPlayer = false;
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

defaultproperties {
	Description="Your description here!"
	DamageModifier=1.0
	MomentumModifier=1.0
	SelfDamageModifier=1.0
	SelfMomentumModifier=1.0
	TeamDamageModifier=1.0
	TeamMomentumModifier=1.0
	bDebugLog=False
	bDropWeapon=True
	bRegenAmmo=False
	RegenAmmoTimer=1.000
	RegenAmmoModifier=0.100
	bRegenAmmoInfinite=False
	RegenAmmoExclude="Botpack.WarheadAmmo,Botpack.SuperShockCore"
	bRemoveDefaultInventory=False
	bSetPlayerStartingHealth=False
	PlayerStartingHealth=100
	bShuffleWeapons=False
	bShuffleAdvancedWeaponSwitch=True
	ShuffleTimer=30
	bFirstRun=True
	bAutoGenerateAmmoReplacementRules=True
	bPreventAdditionalReplacements=True
	bRegenHealth=False
	RegenHealthTimer=1
	RegenHealthAmount=1
	RegenHealthLimit=100
}
