
class ArenaFFNMutator expands Mutator;

var string Item[16];
var bool bDropWeapon;
var bool bRemoveDefaultInventory;
var bool bRegenAmmo;
var bool bHealthPickup;
var bool bInvisibilityPickup;
var bool bUDamagePickup;
var bool bShieldBeltPickup;
var bool bArmorPickup;
var bool bWeaponPickup;
var bool bAmmoPickup;

var class<Weapon> ParsedWeaponsClass[16];
var string ParsedWeaponsName[16];
var int WeaponCount;
var class<Pickup> ParsedPickups[16];
var int PickupCount;
var DeathMatchPlus Game;
var bool bIsModifyingPlayer;

function ModifyPlayerInventory(Pawn pawn){
    local int i;
    if (bRemoveDefaultInventory) DestroyPlayerInventory(pawn);
    for (i=0; i<WeaponCount; i=i+1){
        GiveWeapon(pawn, ParsedWeaponsName[i]);
    }
    for (i=0; i<PickupCount; i=i+1){
        GivePickup(pawn, ParsedPickups[i]);
    }
}

function PreBeginPlay(){
    local int i;
    local string itemString;
    local class<Actor> actorClass;
    local class<Weapon> W;
    local class<Pickup> PickupClass;
    WeaponCount = 0;
    for (i=0; i<16; i=i+1){
        itemString = Item[i];
        if (itemString == ""){
            continue;
        }
        actorClass = class<Actor>(DynamicLoadObject(itemString, class'Class'));
        if (actorClass == None){
            log("ArenaFFN: Failed to load "$itemString);
            continue;
        }
        W = class<Weapon>(actorClass);
        if (W != None){
            ParsedWeaponsName[WeaponCount] = itemString;
            ParsedWeaponsClass[WeaponCount] = W;
            WeaponCount = WeaponCount + 1;
            log("ArenaFFN: OK! Weapon "$WeaponCount$": "$itemString);
            continue;
        }
        PickupClass = class<Pickup>(actorClass);
        if (PickupClass != None){
            ParsedPickups[PickupCount] = PickupClass;
            PickupCount = PickupCount + 1;
            log("ArenaFFN: OK! Pickup "$PickupCount$": "$itemString);
            continue;
        }
        log("ArenaFFN: Not a valid item "$itemString);
    }
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

    ModifyPlayerInventory(pawn);

	if ( NextMutator != None )
		NextMutator.ModifyPlayer(pawn);

	bot = Bot(pawn);
	if ( bot != None )
		bot.bHasImpactHammer = (bot.FindInventoryType(class'ImpactHammer') != None);
    bIsModifyingPlayer = false;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{ 
    // called by Mutator.IsRelevant
    if (bIsModifyingPlayer) return true;
    if (Other.IsA('TournamentHealth')) return bHealthPickup;
    if (Other.IsA('UT_Invisibility')) return bInvisibilityPickup;
    if (Other.IsA('UDamage')) return bUDamagePickup;
    if (Other.IsA('UT_Shieldbelt')) return bShieldBeltPickup;
    if ((Other.IsA('Armor2') || Other.IsA('ThighPads'))) return bArmorPickup;
	if (Other.IsA('Weapon')) return bWeaponPickup;
	if (Other.IsA('Ammo')) return bAmmoPickup;

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

defaultproperties {
    Item(0)="Botpack.UT_Eightball"
    Item(1)="Botpack.Translocator"
    Item(2)="Botpack.UT_JumpBoots"
    Item(3)="Botpack.RocketPack"
    Item(4)="Botpack.Armor2"
    bDropWeapon=True
    bRegenAmmo=False
    bRemoveDefaultInventory=True
    bHealthPickup=True
    bInvisibilityPickup=False
    bUDamagePickup=True
    bShieldBeltPickup=True
    bArmorPickup=False
    bWeaponPickup=False
    bAmmoPickup=False
}