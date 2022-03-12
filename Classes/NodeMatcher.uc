class NodeMatcher extends Node;

var NodeMatcher NextMatcher;
var class<Actor> ReplaceMatchClass;
var NodeReplacer Replacer;


function bool IsMatch(Class target)
{
	if (target == ReplaceMatchClass || ClassIsChildOf(target, ReplaceMatchClass))
	{
		return True;
	}
	return False;
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