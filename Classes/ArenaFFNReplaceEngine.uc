
class ArenaFFNReplaceEngine extends ArenaFFNInfo abstract;

function int AddRuleString(string input);
function bool TryGetReplacementClassString(Actor target, out string replacementResult);
function bool IsKeep(string replacementResult);
function bool IsNone(string replacementResult);
function int GetRuleCount();
function PrintAllRules();
function SetAutoGenerateAmmoReplacementRules(bool value);
function SetPreventAdditionalReplacements(bool value);