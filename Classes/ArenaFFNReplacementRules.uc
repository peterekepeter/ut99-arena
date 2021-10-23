
class ArenaFFNReplacementRules extends ArenaFFNInfo;

const MAX_RULE_COUNT = 286;
const STR_KEEP = "Keep";
const STR_NONE = "None";

var bool bAutoGenerateAmmoReplacementRules;
var bool bPreventAdditionalReplacements;

var class<ArenaFFNParser> Parser;
var class<Actor> ReplaceMatchClass[286];
var class<Actor> ReplaceWithClass[286];
var string ReplaceWithClassString[286];
var int RuleCount;

function PreBeginPlay(){
    Parser = Class'ArenaFFNParser';
    RuleCount = 0;
}

function int AddRuleString(string input){
    local int errorCount;
    local bool successfullyAdded;
    local string listItem, toReplace, replaceWith;
    errorCount = 0;
    while (Parser.static.TrySplit(input, ",", listItem, input)) {
        if (Parser.static.TryParseReplacementRule(listItem, toReplace, replaceWith))
        {
            successfullyAdded = _AddRule(toReplace, replaceWith);
            if (!successfullyAdded){
                errorCount += 1;
                Err("ignoring rule "$toReplace$"->"$replaceWith);
            }
        }
        else {
            errorCount += 1;
            Err("invalid replacement rule"@listItem);
        }
    }
    return errorCount;
}

function bool TryGetReplacementClassString(Actor target, out string replacementResult) {
    local int index;
    index = _GetReplacementIndex(target.Class);
    if (index == -1) {
        replacementResult = "";
        return false;
    }
    replacementResult = ReplaceWithClassString[index];
    return true;
}

function bool IsKeep(string replacementResult) {
    return replacementResult == STR_KEEP;
}

function bool IsNone(string replacementResult) {
    return replacementResult == STR_NONE;
}

function int GetRuleCount(){
    return RuleCount;
}

function int _GetReplacementIndex(Class target){
    local int i;
    local class matcher;
    for (i = 0; i < RuleCount; i += 1){
        matcher = ReplaceMatchClass[i];
        if (target == matcher || ClassIsChildOf(target, matcher))
        {
            return i;
        }
    }
    return -1;
}

function bool _AddRule(string toReplace, string replaceWith)
{
    local int existingMatch;
    local class<Actor> replaceClass, withClass;
    if (RuleCount >= MAX_RULE_COUNT){
        Err("max rule count reached, cannot add"@toReplace$"->"$replaceWith);
        return false;
    }
    replaceClass = class<Actor>(DynamicLoadObject(toReplace, class'Class'));
    if (replaceClass == None){
        Err("failed to load '"$toReplace$"'");
        return false;
    }
    existingMatch = _GetReplacementIndex(replaceClass);
    if (existingMatch != -1){
        Err(replaceClass@"is already being replaced with"@ReplaceWithClass[existingMatch]);
        return false;
    }

    if (replaceWith == STR_NONE){
        ReplaceMatchClass[RuleCount] = replaceClass;
        ReplaceWithClass[RuleCount] = None;
        ReplaceWithClassString[RuleCount] = STR_NONE;
    }
    else if (replaceWith == STR_KEEP){
        ReplaceMatchClass[RuleCount] = replaceClass;
        ReplaceWithClass[RuleCount] = None;
        ReplaceWithClassString[RuleCount] = STR_KEEP;
    }
    else {
        withClass = class<Actor>(DynamicLoadObject(replaceWith, class'Class'));
        if (withClass == None){
            Err("failed to load '"$replaceWith$"'");
            return false;
        }
        if (bPreventAdditionalReplacements){
            if (_GetReplacementIndex(withClass) == -1){
                if (!_AddRule(replaceWith, "Keep")) {
                    Err("failed register keep rule: "$replaceWith$"->Keep");
                    return false;
                }
            }
        }
        if (bAutoGenerateAmmoReplacementRules){
            if (_IsWeapon(replaceClass) && _IsWeapon(withClass))
            {
                if (!_AddAmmoReplacement(replaceClass, withClass)){
                    Err("failed to generate ammo replacement for "$replaceClass$"->"$withClass);
                    return false;
                }
            }
        }
        ReplaceMatchClass[RuleCount] = replaceClass;
        ReplaceWithClass[RuleCount] = withClass;
        ReplaceWithClassString[RuleCount] = replaceWith;
    }

    RuleCount += 1;
    return true;
}

function bool _AddAmmoReplacement(class replaceClass, class withClass){
    local class replaceAmmoClass, withAmmoClass;
    replaceAmmoClass = _GetAmmoClass(class<Weapon>(replaceClass));
    withAmmoClass = _GetAmmoClass(class<Weapon>(withClass));
    if (replaceAmmoClass == None || withAmmoClass == None){
        // okay, one of the weapons has no ammo class
        return true;
    }
    if (_GetReplacementIndex(replaceAmmoClass) != -1){
        // okay, there is already a replacement rule for ammo type
        return true;
    }
    return _AddRule(string(replaceAmmoClass), string(withAmmoClass));
}

function bool _IsWeapon(class c){
    if (c == class'Engine.Weapon'){
        return true;
    }
    if (ClassIsChildOf(c, class'Engine.Weapon')){
        return true;
    }
    return false;
}

function class _GetAmmoClass(class<Weapon> c){
    if (c == class'Engine.Weapon'){
        return class'Engine.Ammo';
    }
    if (c == class'Botpack.TournamentWeapon'){
        return class'Botpack.TournamentAmmo';
    }
    return c.Default.AmmoName;
}

function PrintAllRules(){
    local int i;
    for (i=0; i<RuleCount; i+=1){
        Nfo("Rule["$i$"]: "$ReplaceMatchClass[i]$"->"$ReplaceWithClassString[i]);
    }
}