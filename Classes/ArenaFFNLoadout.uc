class ArenaFFNLoadout extends ArenaFFNInfo;

const MAX_ITEMS = 132;

var int HealingAmount;
var int SuperHealingAmount;
var class<Weapon> ParsedWeaponsClass[132];
var string ParsedWeaponsName[132];
var int WeaponCount;
var class<Pickup> ParsedPickups[132];
var int PickupCount;
var bool bRemoveDefaultInventory;
var bool bSetPlayerStartingHealth;
var int PlayerStartingHealth;
var bool bCanThrow;
var class<ArenaFFNParser> Parser;

function PreBeginPlay(){
    WeaponCount = 0;
    PickupCount = 0;
    Parser = Class'ArenaFFNParser';
}

function ConfigurePlayerStartingHealth(bool setHealth, int toValue)
{
    bSetPlayerStartingHealth = setHealth;
    PlayerStartingHealth = toValue;
}

function SetRemoveDefaultInventory(bool value){
    bRemoveDefaultInventory = value;
}

function SetCanThrowWeapon(bool value){
    bCanThrow = value;
}

function int GetPickupCount(){
    return PickupCount;
}

function int GetWeaponCount(){
    return WeaponCount;
}

function string GetWeaponString(int index){
    return ParsedWeaponsName[index];
}

function class<Weapon> GetWeaponClass(int index){
    return ParsedWeaponsClass[index];
}

function AddLoadoutConfigLine(string input){
    local string listItem, classString;
    local int count, i;
    while (Parser.static.TrySplit(input, ",", listItem, input)) {
        if (Parser.static.TryParseLoadoutItem(listItem, classString, count)){
            for (i=0; i<count; i+=1){
                AddItemString(classString);
            }
        }
    }
}

function AddItemString(string itemString){
    
    local Class<Actor> ActorClass;
    local Class<Weapon> WeaponClass;
    local Class<Pickup> PickupClass;
    local Class<TournamentHealth> TournamentHealthClass;
    local Class<Health> HealthClass;
    if (itemString == ""){
        return;
    }
    ActorClass = class<Actor>(DynamicLoadObject(itemString, class'Class'));
    if (ActorClass == None){
        Err("Failed to load "$itemString);
        return;
    }
    TournamentHealthClass = Class<TournamentHealth>(ActorClass);
    if (TournamentHealthClass != None){
        // special handling for UT99 health items
        if (TournamentHealthClass.Default.bSuperHeal){
            SuperHealingAmount += TournamentHealthClass.Default.HealingAmount;
        } else {
            HealingAmount += TournamentHealthClass.Default.HealingAmount;
        }
        return;
    }
    HealthClass = Class<Health>(ActorClass);
    if (HealthClass != None){
        // special handling for Unreal health items
        if (HealthClass.Default.bSuperHeal){
            SuperHealingAmount += HealthClass.Default.HealingAmount;
        } else {
            HealingAmount += HealthClass.Default.HealingAmount;
        }
        return;
    }
    WeaponClass = class<Weapon>(ActorClass);
    if (WeaponClass != None){
        if (WeaponCount >= MAX_ITEMS){
            Err("Too many weapons, failed to add"@WeaponClass);
            return;
        }
        ParsedWeaponsName[WeaponCount] = itemString;
        ParsedWeaponsClass[WeaponCount] = WeaponClass;
        WeaponCount = WeaponCount + 1;
        return;
    }
    PickupClass = class<Pickup>(ActorClass);
    if (PickupClass != None){
        if (PickupCount >= MAX_ITEMS){
            Err("Too many pickups, failed to add"@PickupClass);
            return;
        }
        ParsedPickups[PickupCount] = PickupClass;
        PickupCount = PickupCount + 1;
        return;
    }
    Err("Not a valid item "$itemString);
}

function ModifyPlayer(Pawn pawn)
{
    ModifyPlayerInventory(pawn);
    ModifyPlayerHealth(pawn);
    GiveWeapons(pawn);
    GivePickups(pawn);
}

function ModifyPlayerInventory(Pawn pawn){
    if (bRemoveDefaultInventory) {
        DestroyPlayerInventory(pawn);
    } 
}

function GiveWeapons(Pawn pawn){
    local int i;
    for (i=WeaponCount-1; i>=0; i=i-1){
        class'ArenaFFNUtil'.static.GiveWeapon(pawn, ParsedWeaponsName[i], bCanThrow);
    }
}

function GivePickups(Pawn pawn){
    local int i;
    for (i=0; i<PickupCount; i=i+1){
        GivePickup(pawn, ParsedPickups[i]);
    }
}

function ModifyPlayerHealth(Pawn Player){
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

function GivePickup(Pawn pawn, class<Pickup> pickupClass){
    local Inventory intentory;
    local Pickup item;
    item = Spawn(pickupClass);
    item.RespawnTime = 0;
    if (item == None){
        Err("failed to spawn item "$pickupClass);
        return;
    }
    intentory = pawn.FindInventoryType(pickupClass);
    if (intentory != None){
        // stack items with existing items
        if (intentory.HandlePickupQuery(item)){
            if (!item.Destroy()){
                Err("failed to destroy handled item "$item);
            }
            return; // handled by existing inventory
        }
    }
    // regular item handling
    item.GiveTo(pawn);
    item.Activate();
    item.PickupFunction(pawn);
}