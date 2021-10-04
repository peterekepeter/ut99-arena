class ArenaFFNParser extends ArenaFFNInfo abstract;

const EMPTY_STRING = "";

static function bool TryParseReplacementRule(string input, out string toReplace, out string replaceWith)
{
    return TrySplit(input, "->", toReplace, replaceWith) && replaceWith != EMPTY_STRING;
}

static function bool TrySplit(string input, string separator, out string first, out string rest)
{
    local int pos;

    if (input == EMPTY_STRING) {
        first = EMPTY_STRING;
        rest = EMPTY_STRING;
        return false;
    }

    pos = InStr(input, separator);

    if (pos >= 0) {
        first = Left(input, pos);
        rest = Mid(input, pos + Len(separator));
        return true;
    } 
    else if (pos == -1) {
        first = input;
        rest = "";
        return true;
    }
}