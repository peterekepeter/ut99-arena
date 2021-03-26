
class ArenaFFNMutator expands Mutator;

var config string Item[32];
var config bool bDropWeapon;
var config bool bRemoveDefaultInventory;
var config bool bRegenAmmo;
var config bool bHealthPickup;
var config bool bInvisibilityPickup;
var config bool bUDamagePickup;
var config bool bShieldBeltPickup;
var config bool bArmorPickup;
var config bool bWeaponPickup;
var config bool bAmmoPickup;
var config bool bReplaceWeaponAndAmmoPickups;
var config bool bSetPlayerStartingHealth;
var config int PlayerStartingHealth;

var class<Weapon> ParsedWeaponsClass[32];
var string ParsedWeaponsName[32];
var class<Weapon> PrimaryWeaponClass;
var string PrimaryWeaponName;
var int WeaponCount;
var class<Pickup> ParsedPickups[32];
var int PickupCount;
var DeathMatchPlus Game;
var bool bIsModifyingPlayer;
var bool bIsModifyingLevelPickups;
var int HealingAmount;
var int SuperHealingAmount;


function PreBeginPlay(){
    InitializeItems();
    bIsModifyingLevelPickups = true;
    bIsModifyingPlayer = false;
}

function PostBeginPlay()
{
    SetTimer(1.0, true);
	Game = DeathMatchPlus(Level.Game);
	Super.PostBeginPlay();
}

function ModifyPlayer(Pawn pawn)
{
	// called by GameInfo.RestartPlayer()
    local Bot bot;
    bIsModifyingPlayer = true;
    bIsModifyingLevelPickups = false;

    ModifyPlayerInventory(pawn);
    ModifyPlayerHealth(pawn);

	if ( NextMutator != None )
		NextMutator.ModifyPlayer(pawn);

	bot = Bot(pawn);
	if ( bot != None )
		bot.bHasImpactHammer = (bot.FindInventoryType(class'ImpactHammer') != None);
    bIsModifyingPlayer = false;
}

function ModifyPlayerInventory(Pawn pawn){
    local int i;
    if (bRemoveDefaultInventory) DestroyPlayerInventory(pawn);
    for (i=WeaponCount-1; i>=0; i=i-1){
        GiveWeapon(pawn, ParsedWeaponsName[i]);
    }
    for (i=0; i<PickupCount; i=i+1){
        GivePickup(pawn, ParsedPickups[i]);
    }
}

function ModifyPlayerHealth(Pawn Player){
    local int MaxHealing;
    local int Health;
    if (bSetPlayerStartingHealth){
        Health = PlayerStartingHealth;
    } else {
        Health = Player.Default.Health;
    }
    if (HealingAmount != 0)
    {
        Health = Min(Health + HealingAmount, Player.Default.Health);
    }
    if (SuperHealingAmount != 0){
        Health = Min(Health + SuperHealingAmount, 
            Min(199, Player.Default.Health * 2.0));
    }
    Player.Health = Health;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{ 
    // called by Mutator.IsRelevant
    if (bIsModifyingPlayer) return true;
    if (bIsModifyingLevelPickups) {
        if (Other.IsA('TournamentHealth')) return bHealthPickup;
        if (Other.IsA('UT_Invisibility')) return bInvisibilityPickup;
        if (Other.IsA('UDamage')) return bUDamagePickup;
        if (Other.IsA('UT_Shieldbelt')) return bShieldBeltPickup;
        if ((Other.IsA('Armor2') || Other.IsA('ThighPads'))) return bArmorPickup;
        if (bReplaceWeaponAndAmmoPickups && PrimaryWeaponClass != None){
            if (Other.IsA('Weapon')) {
                if (!bWeaponPickup){
                    return false;
                }
                if (Other.Class == PrimaryWeaponClass){
                    return true;
                }
                ReplaceWith(Other, PrimaryWeaponName);
                return false;
            }
            if (Other.IsA('Ammo')){
                if (!bAmmoPickup){
                    return false;
                }
                if (Other.Class == PrimaryWeaponClass.Default.AmmoName){
                    return true;
                }
                ReplaceWith(Other, ""$PrimaryWeaponClass.Default.AmmoName);
                return false;
            }
        } else {
            if (Other.IsA('Weapon')) return bWeaponPickup;
            if (Other.IsA('Ammo')) return bAmmoPickup;
        }
    }
    bSuperRelevant = 0;
	return true;
}

function DestroyPlayerInventory(pawn PlayerPawn)
{
	local Inventory i;
    local Weapon w;
    
	for( i=PlayerPawn.Inventory; i!=None; i=i.Inventory )
	{
        w = Weapon(i);
        if (w != None){
            w.Finish();
        }
        i.Destroy();
	}
	PlayerPawn.Weapon = None;
	PlayerPawn.SelectedItem = None;
}

function GiveWeapon(Pawn pawn, String weaponString){
    Game.GiveWeapon(pawn, weaponString);
    pawn.Weapon.bCanThrow = bDropWeapon;
}

function GivePickup(Pawn pawn, class<Pickup> pickupClass){
    local Inventory intentory;
    local Pickup item;
    item = Spawn(pickupClass);
    item.RespawnTime = 0;
    if (item == None){
        log("ArenaFFN: failed to spawn item "$pickupClass);
        return;
    }
    intentory = pawn.FindInventoryType(pickupClass);
    if (intentory != None){
        // stack items with existing items
        if (intentory.HandlePickupQuery(item)){
            if (!item.Destroy()){
                log("ArenaFFN: failed to destroy handled item "$item);
            }
            return; // handled by existing inventory
        }
    }
    // regular item handling
    item.GiveTo(pawn);
    item.Activate();
    item.PickupFunction(pawn);
}

function Timer()
{
    local Weapon W;
    local Pawn P;
	for (P=Level.PawnList; P!=None; P=P.NextPawn)
    {
        if (P.Weapon != None){
            W = P.Weapon;
            // regenerate some ammo
            if (bRegenAmmo && (!WeaponIsFiring(W) || RanOutOfAmmo(P,W)))
            {
                // only regen when not firing, otherwise might break weapons
                // eg. biorifle alt fire seems to break if it receives ammo while charging
                P.Weapon.GiveAmmo(P);
            }
        }
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

function InitializeItems(){
    local int i;
    local string ItemString;
    local Class<Actor> ActorClass;
    local Class<Weapon> WeaponClass;
    local Class<Pickup> PickupClass;
    local Class<TournamentHealth> TournamentHealthClass;
    local Class<Health> HealthClass;
    WeaponCount = 0;
    for (i=0; i<32; i=i+1){
        itemString = Item[i];
        if (itemString == ""){
            continue;
        }
        ActorClass = class<Actor>(DynamicLoadObject(itemString, class'Class'));
        if (ActorClass == None){
            log("ArenaFFN: Failed to load "$itemString);
            continue;
        }
        TournamentHealthClass = Class<TournamentHealth>(ActorClass);
        if (TournamentHealthClass != None){
            // special handling for UT99 health items
            if (TournamentHealthClass.Default.bSuperHeal){
                SuperHealingAmount += TournamentHealthClass.Default.HealingAmount;
            } else {
                HealingAmount += TournamentHealthClass.Default.HealingAmount;
            }
            continue;
        }
        HealthClass = Class<Health>(ActorClass);
        if (HealthClass != None){
            // special handling for Unreal health items
            if (HealthClass.Default.bSuperHeal){
                SuperHealingAmount += HealthClass.Default.HealingAmount;
            } else {
                HealingAmount += HealthClass.Default.HealingAmount;
            }
            continue;
        }
        WeaponClass = class<Weapon>(ActorClass);
        if (WeaponClass != None){
            ParsedWeaponsName[WeaponCount] = itemString;
            ParsedWeaponsClass[WeaponCount] = WeaponClass;
            WeaponCount = WeaponCount + 1;
            continue;
        }
        PickupClass = class<Pickup>(ActorClass);
        if (PickupClass != None){
            ParsedPickups[PickupCount] = PickupClass;
            PickupCount = PickupCount + 1;
            continue;
        }
        log("ArenaFFN: Not a valid item "$itemString);
    }
    PrimaryWeaponClass = ParsedWeaponsClass[0];
    PrimaryWeaponName = ParsedWeaponsName[0];
    log("ArenaFFN: loaded "$WeaponCount$" weapons, "$PickupCount$" pickups, primary weapon is "$PrimaryWeaponClass);
}

defaultproperties {
    Item(0)="Botpack.UT_Eightball"
    Item(1)="Botpack.Translocator"
    Item(2)="Botpack.UT_JumpBoots"
    Item(3)="Botpack.RocketPack"
    Item(4)="Botpack.Armor2"
    Item(5)="Botpack.HealthVial"
    Item(6)="Botpack.HealthVial"
    Item(7)="Botpack.HealthVial"
    Item(8)="Botpack.HealthVial"
    bDropWeapon=True
    bRegenAmmo=False
    bReplaceWeaponAndAmmoPickups=True
    bRemoveDefaultInventory=True
    bHealthPickup=True
    bInvisibilityPickup=False
    bUDamagePickup=True
    bShieldBeltPickup=True
    bArmorPickup=False
    bWeaponPickup=True
    bAmmoPickup=True
    bSetPlayerStartingHealth=False
    PlayerStartingHealth=40
}