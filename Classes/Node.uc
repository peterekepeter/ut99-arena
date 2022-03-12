// Generic AST node, serves as a parent to group methods
class Node extends Object abstract;


static function Err(coerce string message)
{
	class'ArenaFFNUtil'.static.Err(message);
}

static function Nfo(coerce string message)
{
	class'ArenaFFNUtil'.static.Nfo(message);
} 
