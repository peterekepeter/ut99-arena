
class ArenaFFNReplacementRules extends ArenaFFNInfo;

const MAX_RULE_COUNT = 286;
const STR_KEEP = "Keep";
const STR_NONE = "None";

var class<ArenaFFNParser> Parser;
var class<Actor> ReplaceMatchClass[286];
var class<Actor> ReplaceWithClass[286];
var string ReplaceWithClassString[286];
var int RuleCount;

function PreBeginPlay(){
    Parser = Class'ArenaFFNParser';
    RuleCount = 0;
}

function AddRuleString(string input){
    local string listItem, toReplace, replaceWith;
    while (Parser.static.TrySplit(input, ",", listItem, input)) {
        if (Parser.static.TryParseReplacementRule(listItem, toReplace, replaceWith))
        {
            _AddRule(toReplace, replaceWith);
        }
        else {
            Err("invalid replacement rule"@listItem);
        }
    }
}

function bool TryGetReplacementClassString(Actor target, out string replacementResult) {
    local int index;
    index = _GetReplacementIndex(target);
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

function int _GetReplacementIndex(Actor targetActor){
    local int i;
    local class target, matcher;
    target = targetActor.Class;
    for (i = 0; i < RuleCount; i += 1){
        matcher = ReplaceMatchClass[i];
        if (target == matcher || ClassIsChildOf(target, matcher))
        {
            return i;
        }
    }
    return -1;
}

function _AddRule(string toReplace, string replaceWith)
{
    local class<Actor> replaceClass, withClass, loaded;
    if (RuleCount >= MAX_RULE_COUNT){
        Err("max rule count reached, cannot add"@toReplace$"->"$replaceWith);
        return;
    }
    loaded = class<Actor>(DynamicLoadObject(toReplace, class'Class'));
    if (loaded == None){
        Err("failed to load"@toReplace);
        return;
    }
    ReplaceMatchClass[RuleCount] = loaded;

    if (replaceWith == STR_NONE){
        ReplaceWithClass[RuleCount] = None;
        ReplaceWithClassString[RuleCount] = STR_NONE;
    }
    else if (replaceWith == STR_KEEP){
        ReplaceWithClass[RuleCount] = None;
        ReplaceWithClassString[RuleCount] = STR_KEEP;
    }
    else {
        loaded = class<Actor>(DynamicLoadObject(replaceWith, class'Class'));
        if (loaded == None){
            Err("failed to load"@replaceWith);
        return;
        }
        ReplaceWithClass[RuleCount] = loaded;
        ReplaceWithClassString[RuleCount] = replaceWith;
    }

    RuleCount += 1;
}


