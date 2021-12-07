class ArenaFFNClassFilter expands ArenaFFNInfo;

var class Matchers[42];
var int MatchersCount;

function bool Matches(class target){
    local class matcher;
    local int i;
    for (i=0; i<MatchersCount; i+=1)
    {
        matcher = Matchers[i];
        if (target == matcher || ClassIsChildOf(target, matcher))
        {
            return true;
        }
    }
    return false;
}

function Clear(){
    MatchersCount = 0;
}

function int AddMatchClassesLine(string input){
    local int errorCount;
    local bool successfullyAdded;
    local string listItem;
    errorCount = 0;
    while (class'ArenaFFNParser'.static.TrySplit(input, ",", listItem, input)) {
        successfullyAdded = AddMatchClassString(listItem);
        if (!successfullyAdded){
            errorCount += 1;
            Err("ignoring list item "$listItem);
        }
    }
    return errorCount;
}

function bool AddMatchClassString(string classString)
{
    local class<Object> class;
    class = class<Object>(DynamicLoadObject(classString, class'Class'));
    if (class == None)
    {
        Err("failed loading \""$classString$"\"");
        return false;
    }
    AddMatchClass(class);
    return true;
}

function AddMatchClass(class class)
{
    Matchers[MatchersCount] = class;
    MatchersCount+=1;
}