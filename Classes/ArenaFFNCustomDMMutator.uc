//=============================================================================
// A copy of DMMutator, without weapon replacements
//=============================================================================

class ArenaFFNCustomDMMutator expands Mutator;

var DeathMatchPlus MyGame;

function PostBeginPlay()
{
	MyGame = DeathMatchPlus(Level.Game);
	Super.PostBeginPlay();
}

function bool AlwaysKeep(Actor Other)
{
	local bool bTemp;

	if ( Other.IsA('StationaryPawn') )
		return true;

	if ( NextMutator != None )
		return ( NextMutator.AlwaysKeep(Other) );
	return false;
}

function AddMutator(Mutator M)
{
    log("ArenaFFNCustomDMMutator: add mutator "$M);
	if ( NextMutator == None )
		NextMutator = M;
	else
		NextMutator.AddMutator(M);
}


function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local Inventory Inv;

	// set bSuperRelevant to false if want the gameinfo's super.IsRelevant() function called
	// to check on relevancy of this actor.

	bSuperRelevant = 1;
	if ( MyGame.bMegaSpeed && Other.bIsPawn && Pawn(Other).bIsPlayer )
	{
		Pawn(Other).GroundSpeed *= 1.4;
		Pawn(Other).WaterSpeed *= 1.4;
		Pawn(Other).AirSpeed *= 1.4;
		Pawn(Other).AccelRate *= 1.4;
	}

	if ( Other.IsA('StationaryPawn') )
		return true;

	Inv = Inventory(Other);
 	if ( Inv == None )
	{
		bSuperRelevant = 0;
		if ( Other.IsA('TorchFlame') )
			Other.NetUpdateFrequency = 0.5;
		return true;
	}

	if ( MyGame.bNoviceMode && MyGame.bRatedGame && (Level.NetMode == NM_Standalone) )
		Inv.RespawnTime *= (0.5 + 0.1 * MyGame.Difficulty);

	return true;
}

defaultproperties
{
}
