// Generic AST node, serves as a parent to group methods
class ArenaFFNObject extends Object abstract;

var bool bDisableLogs;

function Err(coerce string message)
{
	if (bDisableLogs) 
	{
		return;
	}
	class'ArenaFFNUtil'.static.Err(message);
}

function Nfo(coerce string message)
{
	if (bDisableLogs) 
	{
		return;
	}
	class'ArenaFFNUtil'.static.Nfo(message);
} 
