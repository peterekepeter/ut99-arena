class NodeBuilder extends ArenaFFNObject;

var NodeMatcher FirstMatcher, LastMatcher;

function int AddRuleString(string input)
{
	local int errorCount;
	local bool successfullyAdded;
	local string listItem, toReplace, replaceWith;
	errorCount = 0;
	while (class'ArenaFFNParser'.static.TrySplit(input, ",", listItem, input)) 
	{
		if (class'ArenaFFNParser'.static.TryParseReplacementRule(listItem, toReplace, replaceWith))
		{
			successfullyAdded = AddRule(toReplace, replaceWith);
			if ( ! successfullyAdded)
			{
				errorCount += 1;
				Err("ignoring rule "$toReplace$"->"$replaceWith);
			}
		}
		else 
		{
			errorCount += 1;
			Err("invalid replacement rule"@listItem);
		}
	}
	return errorCount;

}

function bool AddRule(string toReplace, string replaceWith)
{
	local class<Actor> replaceClass, withClass;
	replaceClass = class < Actor > (DynamicLoadObject(toReplace, class'Class'));
	if (replaceClass == None)
	{
		Err("failed to load '"$toReplace$"'");
		return False;
	}
	
	withClass = class < Actor > (DynamicLoadObject(replaceWith, class'Class'));
	if (withClass == None)
	{
		Err("failed to load '"$replaceWith$"'");
		return False;
	}
	return True;
}

function NodeMatcher GetMatcher()
{
	local NodeMatcher m;
	if (FirstMatcher == None)
	{
		// return a dummy matcher
		m = new class'NodeMatcher';
		m.ReplaceMatchClass = class'ArenaFFN';
		return m;
	}
	return FirstMatcher;
}