{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  Microsoft,
  System.Text.RegularExpressions,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)

  public
    method CreateRegExp: EcmaScriptObject;
    method RegExpCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method RegExpExec(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method MatchToArray(aMatch: Match): EcmaScriptArrayObject;
    method RegExpTest(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method RegExpToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
  end;
  EcmaScriptRegexpObject = public class(EcmaScriptObject)
  private
    fRegEx: Regex;
    fGlobalVal: Boolean;
    method set_LastIndex(value: Integer);
  public
    constructor(aGlobal: GlobalObject; aPattern, aFlags: String);
    property &GlobalVal: Boolean read fGlobalVal;
    property RegEx: Regex read fRegEx;
    property LastIndex: Integer read Utilities.GetObjAsInteger(Get(nil, 0, 'lastIndex')) write set_LastIndex;
  end;
implementation
method GlobalObject.CreateRegExp: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get('RegExp'));
  if result <> nil then exit;

  result := new EcmaScriptFunctionObject(self, 'RegExp', @regexpCtor, 1, &Class := 'RegExp');
  Values.Add('RegExp', PropertyValue.NotEnum(Result));

  RegExpPrototype := new EcmaScriptFunctionObject(self, 'RegExp', @RegExpCtor, 1, &Class := 'RegExp');
  RegExpPrototype.Prototype := ObjectPrototype;
  
  result.Values['prototype'] := PropertyValue.NotAllFlags(RegExpPrototype);

  RegExpPrototype.Values['constructor'] := PropertyValue.NotEnum(RegExpPrototype);
  RegExpPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @RegExpToString, 0)));
  RegExpPrototype.Values.Add('test', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'test', @RegExpTest, 1)));
  RegExpPrototype.Values.Add('exec', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'exec', @RegExpExec, 1)));
end;

method GlobalObject.RegExpCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  result := new EcmaScriptRegexpObject(self, Utilities.GetArgAsString(args, 0), Utilities.GetArgAsString(args, 1));
end;

method GlobalObject.RegExpExec(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := aSelf as EcmaScriptRegexpObject;
  var lIndex := iif(lSelf.GlobalVal, lSelf.LastIndex, 0);
  var lMatch := lSelf.RegEx.Match(coalesce(Utilities.GetArgAsString(args, 0), string.Empty));
  if (lMAtch = nil) or (not lMatch.Success) then exit nil;

  if lSelf.GlobalVal then 
    lSelf.LastIndex := lMatch.Index;

  exit MatchToArray(lMatch);
end;

method GlobalObject.RegExpTest(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit RegExpExec(aCaller, aSelf, Args) <> nil;
end;

method GlobalObject.RegExpToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptRegexpObject(aSelf);
  if lSelf = nil then begin
    exit 'RegEx Class';
  end;

  result := '/'+lSelf.Get('source').ToString+'/';
  if lSelf.GlobalVal then result := string(result) +'g';
  if RegexOptions.IgnoreCase in lSelf.RegEx.Options then result := string(result) +'i';
  if RegexOptions.Multiline in lSelf.RegEx.Options then result := string(result) +'m';
end;

method GlobalObject.MatchToArray(aMatch: Match): EcmaScriptArrayObject;
begin
  var lObj := new EcmaScriptArrayObject(self, 0);
  lObj.AddValue('index', aMatch.Index);
  lObj.AddValue('length', aMatch.Captures.Count);
  lObj.PutIndex(0, aMAtch.Value);
  for i: Integer := 1 to Math.Min(32, aMatch.Captures.Count)-1 do begin
    lObj.PutIndex(1, aMatch.Captures[1].Value);
  end;
  exit lObj;
end;

constructor EcmaScriptRegexpObject(aGlobal: GlobalObject; aPattern, aFlags: String);
begin
  inherited constructor(aGlobal, aGlobal.RegExpPrototype, &Class := 'RegExp');
  var lOpt := RegexOptions.ECMAScript;
  if (aFlags <> nil) and (aFlags.contains('i')) then lOpt := lOpt or RegExOptions.IgnoreCase;
  if (aFlags <> nil) and (aFlags.contains('m')) then lOpt := lOpt or RegExOptions.Multiline;
  if (aFlags <> nil) and (aFlags.contains('g')) then fGlobalVal := true;
  Values['source'] := PropertyValue.NotAllFlags(aPattern);
  Values['global'] := PropertyValue.NotAllFlags(fGlobalVal);
  Values['ignoreCase'] := PropertyValue.NotAllFlags(RegExOptions.IgnoreCase in lOpt);
  Values['multiLine'] := PropertyValue.NotAllFlags(RegExOptions.Multiline in lOpt);
  fRegEx := new Regex(aPattern, lOpt);
end;

method EcmaScriptRegexpObject.set_LastIndex(value: Integer);
begin
  self.Put('lastIndex', value, false);
end;

end.