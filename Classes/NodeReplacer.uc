class NodeReplacer extends ArenaFFNObject;

var NodeReplacer NextReplacer;
var string ReplacementString;
var bool bSelfMatch;


function int GetReplacerCount()
{
	local NodeReplacer r;
	local int i;
	i = 0;
	for (r = self; r != None; r = r.NextReplacer)
	{
		i ++ ;
	}
	return i;
}

function NodeReplacer GetReplacer(int index)
{
	local NodeReplacer r;
	for (r = self; index > 0 && r != None; index -- )
	{
		r = r.NextReplacer;
	}
	return r;
}
