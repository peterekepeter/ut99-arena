class NodeMatcher extends ArenaFFNObject;

var NodeMatcher NextMatcher;
var class ReplaceMatchClass;
var NodeReplacer Replacer;
var int ReplacerCount;
var int _rnd;


function string GetRandomReplacementString(Class target)
{
	return GetReplacementString(target, -1);
}

function string GetReplacementString(Class target, int index)
{
	local NodeMatcher m;
	local NodeReplacer r;
	m = GetMatch(target);
	if (m == None || m.Replacer == None)
	{
		return "";
	}
	if (index < 0)
	{
		ReplacerCount = m.Replacer.GetReplacerCount();
		index = CustomRand(ReplacerCount);
	}
	r = m.Replacer.GetReplacer(index);
	if (r.bSelfMatch)
	{
		return "";
	}
	return r.ReplacementString;
}

function NodeReplacer GetFirstReplacer(Class target)
{
	local NodeMatcher m;
	m = GetMatch(target);
	if (m != None)
	{
		return m.Replacer;
	}
}

function NodeMatcher GetMatch(Class target)
{
	local NodeMatcher m;
	for (m = self; m != None; m = m.NextMatcher) 
	{
		if (m.IsMatch(target))
		{
			return m;
		}
	}
	return None;
}


function bool IsMatch(Class target)
{
	if (target == ReplaceMatchClass || ClassIsChildOf(target, ReplaceMatchClass))
	{
		return True;
	}
	return False;
}


function int CustomRand(int max)
{
	local int value;
	_rnd = (_rnd * 31337 + 12344) / 8;
	if (_rnd < 0) 
	{
		_rnd = -_rnd;
	}
	return _rnd - ((_rnd / max) * max);
}