class Test extends Commandlet;

var int FailCount;
var int PassCount;
var class<ArenaFFNParser> Parser;

function int Main(string Params)
{
	Parser = Class'ArenaFFNParser';
	TestTrySplitCases();
	TestTrySplitLoop();
	TestParseReplacementRule();
	TestTryParseLoadoutItem();
	TestMatcherReplacer();
	TestNodeBuilder();
	Summary();
	return GetExitCode();
}

function TestNodeBuilder()
{
	local NodeMatcher m;
	local NodeBuilder b;
	local int errorCount;

	Describe("NodeBuilder");

	b = new class'NodeBuilder';

	AssertEquals(b.AddRuleString("Botpack.WarheadLauncher->Botpack.SuperShockRifle"), 0, "parser rule without errors");
	AssertEquals(b.AddRuleString("Botpack.WarheadLauncher"), 1, "rule without -> has error");
	AssertEquals(b.AddRuleString("Banana->Botpack.SuperShockRifle"), 1, "cannot replace class that does not exist");
	AssertEquals(b.AddRuleString("Botpack.WarheadLauncher->Banana"), 1, "replacement class must exist");

	m = b.GetMatcher();
	AssertTrue(m != None, "returns non null matcher");
	AssertEquals(m.GetReplacementString(class'Botpack.WarheadLauncher', 0), "Botpack.SuperShockRifle", "returns replacement string");

	AssertEquals(b.AddRuleString("Botpack.ShockRifle->Botpack.SuperShockRifle"), 0, "adds second rule without issues");
	m = b.GetMatcher();
	AssertEquals(m.GetReplacementString(class'Botpack.ShockRifle', 0), "Botpack.SuperShockRifle", "returns replacement string from second rule");
	AssertEquals(m.GetReplacementString(class'Botpack.WarheadLauncher', 0), "Botpack.SuperShockRifle", "still returns replacement string from first rule");
	
	AssertEquals(b.AddRuleString("Botpack.WarheadLauncher->Botpack.ShockRifle"), 1, "cannot add same rule twice");
	
}

function TestMatcherReplacer()
{
	local NodeMatcher m, m2;
	local NodeReplacer r1, r2, r3;
	local string s;
	local int i;

	Describe("NodeMatcher");
	m = new class'NodeMatcher';
	m.ReplaceMatchClass = class'Botpack.WarheadLauncher';  
	m2 = new class'NodeMatcher';
	m2.ReplaceMatchClass = class'Botpack.ShockRifle';
	m.NextMatcher = m2;
	
	AssertTrue(m.GetMatch(class'Botpack.WarheadLauncher') == m, "first matcher matches");
	AssertTrue(m.GetMatch(class'Botpack.ShockRifle') == m2, "second matcher matches");
	AssertTrue(m.GetMatch(class'Botpack.SuperShockRifle') == m2, "second matcher matches child class");

	Describe("NodeReplacer");
	r1 = new class'NodeReplacer';
	r2 = new class'NodeReplacer';
	r3 = new class'NodeReplacer';
	r1.NextReplacer = r2;
	r2.NextReplacer = r3;

	AssertTrue(r1.GetReplacerCount() == 3, "replacer count is 3 on first node");
	AssertTrue(r2.GetReplacerCount() == 2, "replacer count is 2 on second node");
	AssertTrue(r3.GetReplacerCount() == 1, "replacer count is 1 on third node");
	AssertTrue(r1.GetReplacer(0) == r1, "gets replacer 0");
	AssertTrue(r1.GetReplacer(1) == r2, "gets replacer 1");
	AssertTrue(r1.GetReplacer(2) == r3, "gets replacer 2");
	AssertTrue(r1.GetReplacer(3) == None, "gets replacer 3 (out of bounds)");
	AssertTrue(r1.GetReplacer(4) == None, "gets replacer 4 (out of bounds)");


	m2.Replacer = r1;
	m.Replacer = r3;
	r1.ReplacementString = "Apple";
	r2.ReplacementString = "Orange";
	r3.ReplacementString = "Banana";

	Describe("NodeMatcher.GetFirstReplacer");

	AssertTrue(m.GetFirstReplacer(class'Botpack.WarheadLauncher') == r3, "gets correct replacer r3");
	AssertTrue(m.GetFirstReplacer(class'Engine.Weapon') == None, "returns None if no match");
	AssertTrue(m.GetFirstReplacer(class'Botpack.ShockRifle') == r1, "gets correct replacer r1");

	Describe("NodeMatcher.GetReplacementString");

	AssertEquals(m.GetReplacementString(class'Botpack.WarheadLauncher', 0), "Banana", "replace WarheadLauncher with banana");
	AssertEquals(m.GetReplacementString(class'Engine.Weapon', 0), "", "returns empty string if no match");
	AssertEquals(m.GetReplacementString(class'Botpack.ShockRifle', 0), "Apple", "gets correct replacer r1");
	AssertEquals(m.GetReplacementString(class'Botpack.ShockRifle', 1), "Orange", "ordered 1 gets correct replacer r2");
	AssertEquals(m.GetReplacementString(class'Botpack.ShockRifle', 2), "Banana", "ordered 2 gets correct replacer r3");

	Describe("NodeMatcher.GetRandomReplacementString");

	s = m.GetRandomReplacementString(class'Engine.Weapon');
	AssertEquals(s, "", "returns empty string if no match");
	s = m.GetRandomReplacementString(class'Botpack.WarheadLauncher');
	AssertTrue(s == "Banana", "gets same string if 1 candidate");
	s = m.GetRandomReplacementString(class'Botpack.ShockRifle');
	AssertTrue(s == "Apple" || s == "Orange" || s == "Banana", "gets random string from 3 candidats");

	
}

function TestTryParseLoadoutItem()
{
	local string A;
	local int B;
	local bool bResult;

	Describe("TryParseLoadoutItem generic case");
	bResult = Parser.static.TryParseLoadoutItem("Health*3", A, B);
	AssertEquals(A, "Health", "parsed item name");
	AssertEquals(B, 3, "parsed item count");
	AssertTrue(bResult, "parses successfully");

	Describe("TryParseLoadoutItem missing count case");
	bResult = Parser.static.TryParseLoadoutItem("Health", A, B);
	AssertEquals(A, "Health", "parsed item name");
	AssertEquals(B, 1, "parsed item count");
	AssertTrue(bResult, "parses successfully");

	Describe("TryParseLoadoutItem empty string");
	bResult = Parser.static.TryParseLoadoutItem("", A, B);
	AssertFalse(bResult, "returns false on empty string");
}

function TestParseReplacementRule()
{
    
	local string A, B;
	local bool bResult;

	Describe("ParseReplacementRule generic case");

	bResult = Parser.static.TryParseReplacementRule("W1->W2", A, B);
	AssertEquals(A, "W1", "left side of arrow");
	AssertEquals(B, "W2", "right side of arrow");
	AssertTrue(bResult, "successfully parsed");

	Describe("ParseReplacementRule arrow missing");

	bResult = Parser.static.TryParseReplacementRule("W1", A, B);
	AssertFalse(bResult, "arrow is required");
}

function TestTrySplitCases()
{
	local string A, B;
	local bool bResult;
    
	Describe("Split generic case");

	bResult = Parser.static.TrySplit("W1,W2,W3", ",", A, B);
	AssertEquals(A, "W1", "first item is text before the separator");
	AssertEquals(B, "W2,W3", "rest is text after the separator");
	AssertTrue(bResult, "returns true if valid first item is returned");

	Describe("Split last item");

	bResult = Parser.static.TrySplit("W3", ",", A, B);
	AssertEquals(A, "W3", "first item is whole input");
	AssertEquals(B, "", "rest is empty string");
	AssertTrue(bResult, "returns true because first item is valid");

	Describe("Split empty input");

	bResult = Parser.static.TrySplit("", ",", A, B);
	AssertEquals(A, "", "empty result");
	AssertEquals(B, "", "empty result");
	AssertFalse(bResult, "finished parsing");
}

function TestTrySplitLoop()
{
	local string result[4], item, input, rest;
	local int index;
	index = 0;

	Describe("Split loop");
    
	index = 0;
	input = "W1,W2,W3";
	result[3] = "<did not write>";

	while (Parser.static.TrySplit(input, ",", item, rest)) 
	{
		result[index] = item;
		input = rest;
		index = index + 1;
	}

    
	AssertEquals(result[0], "W1", "first list item");
	AssertEquals(result[1], "W2", "second list item");
	AssertEquals(result[2], "W3", "last list item");
	AssertEquals(result[3], "<did not write>", "did not write beyond last item");

}

function AssertEquals(coerce string a, coerce string b, string message)
{
	if (a != b) 
		FailEquals(a,b,message);
	else 
		Pass(message);
}

function AssertTrue(bool b, string message)
{
	if (b != True) 
		Fail(message);
	else 
		Pass(message);
}

function AssertFalse(bool b, string message)
{
	if (b != False) 
		Fail(message);
	else 
		Pass(message);
}

function FailEquals(coerce string a, coerce string b, string message)
{
	Fail(message$": expected \""$a$"\" to be \""$b$"\"");
}

function Fail(coerce string a)
{
	Err(a);
	FailCount += 1;
}

function Pass(coerce string a)
{
	Nfo("    Passed "$a);
	PassCount += 1;
}

function Summary()
{
	Nfo("-------------------");
	Nfo("Summary: failed:"@FailCount$", passed:"@PassCount);
}

function int GetExitCode()
{
	if (PassCount > 0 && FailCount <= 0)
	{
		return 0;
	}
	return 1;
}

function Describe(coerce string a)
{
	Nfo("-------------------");
	Nfo("Testing:"@a);
}

function Err(coerce string a)
{
	Log(" !! Failed "$a);
}

function Nfo(coerce string a)
{
	Log(a);
}