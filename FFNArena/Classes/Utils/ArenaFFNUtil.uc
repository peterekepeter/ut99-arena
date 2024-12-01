
class ArenaFFNUtil extends ArenaFFNInfo abstract;

static function Err(coerce string message)
{
	Log("ArenaFFN [ERROR]: "$message$"!!!");
}

static function Nfo(coerce string message)
{
	Log("ArenaFFN: "$message$".");
}

static function GiveWeapon(Pawn pawn, String weaponString, bool bCanThrow)
{
	local DeathMatchPlus game;
	game = DeathMatchPlus(pawn.Level.Game);
	game.GiveWeapon(pawn, weaponString);
	pawn.Weapon.bCanThrow = bCanThrow;
}

