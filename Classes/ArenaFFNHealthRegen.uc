class ArenaFFNHealthRegen extends ArenaFFNInfo;

var bool bEnabled;
var float PeriodSeconds;
var int RegenAmount;
var int RegenMax;


function Initialize(bool enabled, float period, int amount, int limit)
{
	bEnabled = enabled;
	PeriodSeconds = period;
	RegenAmount = amount;
	RegenMax = limit;
	Nfo("Initialize hp regen bEnabled"@bEnabled@"PeriodSeconds"@PeriodSeconds@"RegenAmount"@RegenAmount@"RegenMax"@RegenMax);
	if (enabled)
	{
		SetTimer(PeriodSeconds * Level.TimeDilation, True);
	} 
}


function Timer()
{
	local Pawn P;
	for (P = Level.PawnList; P!=None; P = P.NextPawn)
	{
		if (P.bIsPlayer)
		{
			ApplyHealthRegen(P);
		}
	}
}

function ApplyHealthRegen(Pawn pawn)
{
	local int hp;
	hp = pawn.Health;
	if (hp <= 0 || hp >= RegenMax)
	{
		Nfo("cannot regen");
		return;
	}
	hp += RegenAmount;
	if (hp > RegenMax)
	{
		hp = RegenMax;
	}
	pawn.Health = hp;
	Nfo("adding"@RegenAmount@"hp to"@pawn);
}