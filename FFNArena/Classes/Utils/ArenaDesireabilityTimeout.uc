class ArenaDesireabilityTimeout extends ArenaFFNInfo;

const DUMMY_DESIRABILITY = -2026.0;
const RESTORE_DELAY = 15.0;

var Inventory TargetItem;
var float MaxDesireability;

function SetDesireabilityTimeout(Inventory item)
{
	if ( item != None )
	{
		TargetItem = item;
		MaxDesireability = item.MaxDesireability;
		item.MaxDesireability = DUMMY_DESIRABILITY;
	}
	SetTimer(RESTORE_DELAY, False);
}

event Timer()
{
	if ( TargetItem != None )
	{
		if ( TargetItem.MaxDesireability == DUMMY_DESIRABILITY )
		{
			TargetItem.MaxDesireability = MaxDesireability;
		}
	}
	Destroy();
}
