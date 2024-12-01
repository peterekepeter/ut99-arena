class ArenaDynamicProfile extends ArenaFFNObject perobjectconfig config(FFNArena);

var config string Description;
var config bool bFirstRun;
var config bool bDebugLog;
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
