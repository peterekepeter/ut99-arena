class FFNArena expands FFNArenaBase;

function PreBeginPlay()
{
	local string str;
	str = Level.GetLocalURL();
	str = ParseProfileName(str);
	LoadConfigurationProfile(str);
	Super.PreBeginPlay();
}

static function string ParseProfileName(string str) 
{
	local int i;

	i = InStr(str, "ArenaProfile=");
	if ( i < -1 ) 
		return "";
	str = Mid(str, i + 13); // lenght of key
	i = InStr(str, "?");
	if ( i == -1 )
		return str;
	else 
		return Mid(str, 0, i);
}

function LoadConfigurationProfile(string name) 
{
	local NameConverter nameConverter;
	local ArenaDynamicProfile p;
	local name n;
	local int i;

	nameConverter = new class'NameConverter';

	n = nameConverter.Convert("ArenaProfile"$name);
	Nfo("Using config from "@n);
	
	// from FFNArena.ini load secion n
	p = new (class'FFNArena', n)class'ArenaDynamicProfile';

	if ( p.bFirstRun )
	{
        // generate INI entries on first run
		p.bFirstRun = False;
		p.SaveConfig(); 
	}

	// copy vars
	Description = p.Description;
	bFirstRun = p.bFirstRun;
	bDebugLog = p.bDebugLog;
	bAutoGenerateAmmoReplacementRules = p.bAutoGenerateAmmoReplacementRules;
	bPreventAdditionalReplacements = p.bPreventAdditionalReplacements;
	bUseNewReplacementEngine = p.bUseNewReplacementEngine;
	bRemoveDefaultInventory = p.bRemoveDefaultInventory;
	bShuffleWeapons = p.bShuffleWeapons;
	bShuffleAdvancedWeaponSwitch = p.bShuffleAdvancedWeaponSwitch;
	ShuffleTimer = p.ShuffleTimer;
	bSetPlayerStartingHealth = p.bSetPlayerStartingHealth;
	PlayerStartingHealth = p.PlayerStartingHealth;
	bDropWeapon = p.bDropWeapon;
	bRegenAmmo = p.bRegenAmmo;
	RegenAmmoTimer = p.RegenAmmoTimer;
	RegenAmmoModifier = p.RegenAmmoModifier;
	bRegenAmmoInfinite = p.bRegenAmmoInfinite;
	RegenAmmoExclude = p.RegenAmmoExclude;
	bRegenHealth = p.bRegenHealth;
	RegenHealthTimer = p.RegenHealthTimer;
	RegenHealthAmount = p.RegenHealthAmount;
	RegenHealthLimit = p.RegenHealthLimit;
	DamageModifier = p.DamageModifier;
	MomentumModifier = p.MomentumModifier;
	SelfDamageModifier = p.SelfDamageModifier;
	SelfMomentumModifier = p.SelfMomentumModifier;
	TeamDamageModifier = p.TeamDamageModifier;
	TeamMomentumModifier = p.TeamMomentumModifier;
	bDropAllOnDeath = p.bDropAllOnDeath;
	bDropBootsOnDeath = p.bDropBootsOnDeath;
	bDropUDamageOnDeath = p.bDropUDamageOnDeath;
	bDropInvisibilityOnDeath = p.bDropInvisibilityOnDeath;
	bDropRedeemerOnDeath = p.bDropRedeemerOnDeath;
	bDropArmorOnDeath = p.bDropArmorOnDeath;
	bDebugLogDamage = p.bDebugLogDamage;
	bRemoveBulletKnockback = p.bRemoveBulletKnockback;

	// copy arrays
	for ( i = 0; i < MAX_REPLACEMENT_RULES; i+=1 ) 
	{
		// these both have length 32
		Replace[i] = p.Replace[i];
		Loadout[i] = p.Loadout[i];
	}
}
