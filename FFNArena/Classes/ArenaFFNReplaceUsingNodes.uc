class ArenaFFNReplaceUsingNodes extends ArenaFFNReplaceEngine;

var NodeBuilder _builder;

function PreBeginPlay()
{
	_builder = new class'NodeBuilder';
}

function int AddRuleString(string input)
{
	Nfo("new engine add "$input);
	return _builder.AddRuleString(input);
}

function bool TryGetReplacementClassString(Actor target, out string replacementResult)
{
	local NodeMatcher matcher;
	matcher = _builder.GetMatcher();
	replacementResult = matcher.GetRandomReplacementString(target.class);
	return replacementResult != "";
}


function bool IsKeep(string replacementResult)
{
	return replacementResult == "Keep";
}

function bool IsNone(string replacementResult)
{
	return replacementResult == "None";
}

function int GetRuleCount()
{
	local NodeMatcher m;
	local NodeReplacer r;
	local int count;
	count = 0;
	for (m = _builder.GetMatcher(); m != None; m = m.NextMatcher)
	{
		for (r = m.Replacer; r != None; r = r.NextReplacer)
		{
			count ++ ;
		}
	}
	return count;
}

function PrintAllRules()
{
	local NodeMatcher m;
	local NodeReplacer r;
	local int count;
	local string rule;
	local string separator;
	count = 0;
	for (m = _builder.GetMatcher(); m != None; m = m.NextMatcher)
	{
		separator = "->";
		rule = m.ReplaceMatchClass$"";
		for (r = m.Replacer; r != None; r = r.NextReplacer)
		{
			rule = rule$separator$r.ReplacementString;
			separator = "|";
			count ++ ;
		}
		Nfo(rule);
	}
}

function SetAutoGenerateAmmoReplacementRules(bool value)
{
	_builder.bAutoGenerateAmmoReplacementRules = value;
}

function SetPreventAdditionalReplacements(bool value)
{
	_builder.bPreventAdditionalReplacements = value;
}