class Test extends Commandlet;

var int FailCount;
var int PassCount;

function int Main(string Params)
{
    TestTrySplitCases();
    TestTrySplitLoop();
    TestParseReplacementRule();
    Summary();
    return GetExitCode();
}

function TestParseReplacementRule(){
    
    local string A, B;
    local bool bResult;

    Describe("ParseReplacementRule generic case");

    bResult = Class'ArenaFFNParser'.static.TryParseReplacementRule("W1->W2", A, B);
    AssertEquals(A, "W1", "left side of arrow");
    AssertEquals(B, "W2", "right side of arrow");
    AssertTrue(bResult, "successfully parsed");

    Describe("ParseReplacementRule arrow missing");

    bResult = Class'ArenaFFNParser'.static.TryParseReplacementRule("W1", A, B);
    AssertFalse(bResult, "arrow is required");
}

function TestTrySplitCases(){
    
    local string A, B;
    local bool bResult;
    
    Describe("Split generic case");

    bResult = Class'ArenaFFNParser'.static.TrySplit("W1,W2,W3", ",", A, B);
    AssertEquals(A, "W1", "first item is text before the separator");
    AssertEquals(B, "W2,W3", "rest is text after the separator");
    AssertTrue(bResult, "returns true if valid first item is returned");

    Describe("Split last item");

    bResult = Class'ArenaFFNParser'.static.TrySplit("W3", ",", A, B);
    AssertEquals(A, "W3", "first item is whole input");
    AssertEquals(B, "", "rest is empty string");
    AssertTrue(bResult, "returns true because first item is valid");

    Describe("Split empty input");

    bResult = Class'ArenaFFNParser'.static.TrySplit("", ",", A, B);
    AssertEquals(A, "", "empty result");
    AssertEquals(B, "", "empty result");
    AssertFalse(bResult, "finished parsing");
}

function TestTrySplitLoop(){
    local string result[4], item, input, rest;
    local int index;
    index = 0;

    Describe("Split loop");
    
    index = 0;
    input = "W1,W2,W3";
    result[3] = "<did not write>";

    while (Class'ArenaFFNParser'.static.TrySplit(input, ",", item, rest)) {
        result[index] = item;
        input = rest;
        index = index + 1;
    }

    
    AssertEquals(result[0], "W1", "first list item");
    AssertEquals(result[1], "W2", "second list item");
    AssertEquals(result[2], "W3", "last list item");
    AssertEquals(result[3], "<did not write>", "did not write beyond last item");

}

function AssertEquals(string a, string b, string message){
    if (a != b) 
        FailEquals(a,b,message);
    else 
        Pass(message);
}

function AssertTrue(bool b, string message){
    if (b != true) 
        Fail(message);
    else 
        Pass(message);
}

function AssertFalse(bool b, string message){
    if (b != false) 
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

function Summary(){
    Nfo("-------------------");
    Nfo("Summary: failed:"@FailCount$", passed:"@PassCount);
}

function int GetExitCode(){
    if (PassCount > 0 && FailCount <= 0){
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