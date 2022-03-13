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
	local NodeMatcher matcher;

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
	matcher = GetOrAddMatcher(replaceClass);
	if (matcher.Replacer != None)
	{
		Err(replaceClass@"is already being replaced with"@matcher.Replacer.ReplacementString);
		return False;
	}
	matcher.Replacer = new class'NodeReplacer';
	matcher.Replacer.ReplacementString = replaceWith;
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

function NodeMatcher GetOrAddMatcher(class < Actor> toReplace)
{
	local NodeMatcher m;
	// find existing
	for (m = FirstMatcher; m != None; m = m.NextMatcher)
	{
		if (m.ReplaceMatchClass == toReplace)
		{
			return m;
		}
	}
	// new matcher
	m = new class'NodeMatcher';
	m.ReplaceMatchClass = toReplace;

	if (FirstMatcher == None)	
	{
		FirstMatcher = m;
		LastMatcher = m;
	}
	else 
	{
		LastMatcher.NextMatcher = m;
		LastMatcher = m;
	}
	return m;
}