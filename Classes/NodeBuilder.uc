class NodeBuilder extends ArenaFFNObject;

var NodeMatcher FirstMatcher, LastMatcher;
var bool bPreventAdditionalReplacements;
var bool bAutoGenerateAmmoReplacementRules;
var bool bAllowMultipleReplace;

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
	local NodeMatcher matcher, subMatcher;
	local NodeReplacer replacer;
	local bool isSelfMatch;
	isSelfMatch = False;

	replaceClass = class < Actor > (DynamicLoadObject(toReplace, class'Class'));
	if (replaceClass == None)
	{
		Err("failed to load '"$toReplace$"'");
		return False;
	}
	
	if (replaceWith != "None" && replaceWith != "Keep")
	{
		if (InStr(replaceWith, "|") != -1)
		{
			return HandleMultiReplace(toReplace, replaceWith);
		}
		withClass = class < Actor > (DynamicLoadObject(replaceWith, class'Class'));
		if (withClass == None)
		{
			Err("failed to load '"$replaceWith$"'");
			return False;
		}
		isSelfMatch = replaceClass == withClass; 
		if (bPreventAdditionalReplacements)
		{
			subMatcher = GetOrAddMatcher(withClass);
			if (subMatcher.Replacer == None)
			{
				if ( ! AddRule(replaceWith, "Keep")) 
				{
					Err("failed register keep rule: "$replaceWith$"->Keep");
					return False;
				}
			}
		}
		if (bAutoGenerateAmmoReplacementRules)
		{
			if (IsWeapon(replaceClass) && IsWeapon(withClass))
			{
				if ( ! AddAmmoReplacement(replaceClass, withClass))
				{
					Err("failed to generate ammo replacement for "$replaceClass$"->"$withClass);
					return False;
				}
			}
		}

	}
	matcher = GetOrAddMatcher(replaceClass);
	if (bAllowMultipleReplace == False && matcher.Replacer != None)
	{
		Err(replaceClass@"is already being replaced with"@matcher.Replacer.ReplacementString);
		return False;
	}

	replacer = new class'NodeReplacer';
	replacer.ReplacementString = replaceWith;
	replacer.bSelfMatch = isSelfMatch;
	AppendReplacerToMatcher(matcher, replacer);
	return True;
}

function AppendReplacerToMatcher(NodeMatcher matcher, NodeReplacer replacer)
{
	local NodeReplacer target;
	if (matcher.Replacer == None)
	{
		matcher.Replacer = replacer;
	}
	else 
	{
		target = matcher.Replacer;
		while (target.NextReplacer != None)
		{
			target = target.NextReplacer;
		}
		target.NextReplacer = replacer;
	}
}

function bool HandleMultiReplace(string toReplace, string replaceWith)
{
	local string listItem;
	bAllowMultipleReplace = True;
	while (class'ArenaFFNParser'.static.TrySplit(replaceWith, "|", listItem, replaceWith)) 
	{
		if ( ! AddRule(toReplace, listItem))
		{
			return False;
		}
	}
	bAllowMultipleReplace = False;
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

function NodeMatcher GetOrAddMatcher(class toReplace)
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

function bool AddAmmoReplacement(class replaceClass, class withClass)
{
	local class replaceAmmoClass, withAmmoClass;
	replaceAmmoClass = GetAmmoClass(class < Weapon > (replaceClass));
	withAmmoClass = GetAmmoClass(class < Weapon > (withClass));
	if (replaceAmmoClass == None || withAmmoClass == None)
	{
        // okay, one of the weapons has no ammo class
		return True;
	}
	if (GetOrAddMatcher(replaceAmmoClass).Replacer != None)
	{
        // okay, there is already a replacement rule for ammo type
		return True;
	}
	return AddRule(string(replaceAmmoClass), string(withAmmoClass));
}

function bool IsWeapon(class c)
{
	if (c == class'Engine.Weapon')
	{
		return True;
	}
	if (ClassIsChildOf(c, class'Engine.Weapon'))
	{
		return True;
	}
	return False;
}

function class GetAmmoClass(class < Weapon> c)
{
	if (c == class'Engine.Weapon')
	{
		return class'Engine.Ammo';
	}
	if (c == class'Botpack.TournamentWeapon')
	{
		return class'Botpack.TournamentAmmo';
	}
	return c.Default.AmmoName;
}