{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Text,
  System.Text.RegularExpressions,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)

  public
    method CreateRegExp: EcmaScriptObject;
    method RegExpCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method RegExpExec(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method MatchToArray(aSelf: EcmaScriptRegexpObject; aInput: String; aMatch: MatchCollection): EcmaScriptArrayObject;
    method RegExpTest(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method RegExpToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method RegExpCompile(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
  end;
  RemObjects.Script.EcmaScript.Internal.EcmaScriptRegexpObject = public class(EcmaScriptObject)
  private
    fRegex: Regex;
    fGlobalVal: Boolean;
    method set_LastIndex(value: Integer);
  assembly
    method Recreate(aPattern: String; aSettings: RegexOptions);
  public
    property GlobalVal: Boolean read fGlobalVal write fGlobalVal;
    property Options: RegexOptions read fRegex.Options;
    //fRegEx: Regex;
    property Regex: Regex read fRegex;
    constructor(aGlobal: GlobalObject; aPattern, aFlags: String);
    property LastIndex: Integer read Utilities.GetObjAsInteger(Get(nil, 0, 'lastIndex'), Root.ExecutionContext) write set_LastIndex;
  end;
implementation
method GlobalObject.CreateRegExp: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get('RegExp'));
  if result <> nil then exit;

  result := new EcmaScriptFunctionObject(self, 'RegExp', @RegExpCtor, 1, &Class := 'RegExp');
  Values.Add('RegExp', PropertyValue.NotEnum(Result));

  RegExpPrototype := new EcmaScriptFunctionObject(self, 'RegExp', @RegExpCtor, 1, &Class := 'RegExp');
  RegExpPrototype.Prototype := ObjectPrototype;
  RegExpPrototype.Values['source'] := PropertyValue.NotAllFlags(Undefined.Instance);
  RegExpPrototype.Values['global'] := PropertyValue.NotAllFlags(false);
  RegExpPrototype.Values['ignoreCase'] := PropertyValue.NotAllFlags(false);
  RegExpPrototype.Values['multiline'] := PropertyValue.NotAllFlags(false);
  RegExpPrototype.Values['lastIndex'] := new PropertyValue(PropertyAttributes.Writable, Undefined.Instance);

  result.Values['prototype'] := PropertyValue.NotAllFlags(RegExpPrototype);

  RegExpPrototype.Values['constructor'] := PropertyValue.NotEnum(RegExpPrototype);
  RegExpPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @RegExpToString, 0)));
  RegExpPrototype.Values.Add('test', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'test', @RegExpTest, 1)));
  RegExpPrototype.Values.Add('compile', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'test', @RegExpCompile, 2)));
  RegExpPrototype.Values.Add('exec', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'exec', @RegExpExec, 1)));
end;

method GlobalObject.RegExpCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  result := new EcmaScriptRegexpObject(self, if (length(Args) = 0) or (Args[0] = Undefined.Instance) then '' else Utilities.GetArgAsString(Args, 0, aCaller), if (length(Args) < 2) or (Args[1] = Undefined.Instance) then '' else Utilities.GetArgAsString(Args, 1, aCaller));
end;

method GlobalObject.RegExpExec(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := aSelf as EcmaScriptRegexpObject;
  var lIndex := iif(lSelf.GlobalVal, lSelf.LastIndex, 0);
  var lInput := coalesce(Utilities.GetArgAsString(Args, 0, aCaller), String.Empty);
  try
    var lMatch := lSelf.Regex.Matches(lInput, lIndex);


    exit MatchToArray(lSelf, lInput, lMatch);
  except
    on e: Exception do begin
      RaiseNativeError(NativeErrorType.SyntaxError, e.Message);
    end;
  end;
end;

method GlobalObject.MatchToArray(aSelf: EcmaScriptRegexpObject; aInput: String; aMatch: MatchCollection): EcmaScriptArrayObject;
begin
  var lObj := new EcmaScriptArrayObject(self, 0);
  lObj.AddValue('input', aInput);
  if aMatch.Count > 0 then begin
    lObj.AddValue('index', aMatch[0].Index);
    if not aSelf.GlobalVal then begin
      for i: Integer := 0 to aMatch[0].Groups.Count -1 do 
        lObj.AddValue(aMatch[0].Groups[i].Value);
    end else begin // global
      for i: Integer := 0 to aMatch.Count -1 do
        lObj.AddValue(aMatch[i].Value);
      aSelf.LastIndex := aMatch[aMatch.Count -1].Index + aMatch[aMatch.Count -1].Length;
    end;
  end else begin
    if aSelf.GlobalVal then 
      aSelf.LastIndex := 0;
    exit nil;
  end;
  exit lObj;
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
  if lSelf.GlobalVal then result := String(result) +'g';
  if RegexOptions.IgnoreCase in lSelf.Options then result := String(result) +'i';
  if RegexOptions.Multiline in lSelf.Options then result := String(result) +'m';
end;



method GlobalObject.RegExpCompile(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := EcmaScriptRegexpObject(aSelf);
  if lObj = nil then RaiseNativeError(NativeErrorType.TypeError, 'this is not a RegEx object');
  var lOpt := RegexOptions.ECMAScript;
  var aFlags := Utilities.GetArgAsString(Args, 1, aCaller);
  var aPattern := Utilities.GetArgAsString(Args, 0, aCaller);
  if (aFlags <> nil) and (aFlags.Contains('i')) then lOpt := lOpt or RegexOptions.IgnoreCase;
  if (aFlags <> nil) and (aFlags.Contains('m')) then lOpt := lOpt or RegexOptions.Multiline;
  if (aFlags <> nil) and (aFlags.Contains('g')) then lObj.GlobalVal := true;
  lObj.Values['source'] := PropertyValue.NotAllFlags(aPattern);
  lObj.Values['global'] := PropertyValue.NotAllFlags(lObj.GlobalVal);
  lObj.Values['ignoreCase'] := PropertyValue.NotAllFlags(RegexOptions.IgnoreCase in lOpt);
  lObj.Values['multiline'] := PropertyValue.NotAllFlags(RegexOptions.Multiline in lOpt);
  lObj.Values['lastIndex'] := new PropertyValue(PropertyAttributes.Writable, Undefined.Instance);
  try
  lObj.Recreate(aPattern, lOpt);
  except
    on e: Exception do
      RaiseNativeError(NativeErrorType.SyntaxError, e.Message);
  end;

  exit lObj;
end;

constructor EcmaScriptRegexpObject(aGlobal: GlobalObject; aPattern, aFlags: String);
begin
  inherited constructor(aGlobal, aGlobal.RegExpPrototype, &Class := 'RegExp');
  var lOpt := RegexOptions.ECMAScript;
  if aFlags <> nil then 
    for each el in aFlags do begin
      if el = 'i' then begin
        if RegexOptions.IgnoreCase in lOpt then aGlobal.RaiseNativeError(NativeErrorType.SyntaxError, 'invalid flags');
        lOpt := lOpt or RegexOptions.IgnoreCase;
      end else 
      if el = 'm' then begin
        if RegexOptions.Multiline in lOpt then aGlobal.RaiseNativeError(NativeErrorType.SyntaxError, 'invalid flags');
        lOpt := lOpt or RegexOptions.Multiline;
      end else 
      if el = 'g' then begin
        if fGlobalVal then aGlobal.RaiseNativeError(NativeErrorType.SyntaxError, 'invalid flags');
        fGlobalVal := true;
      end else aGlobal.RaiseNativeError(NativeErrorType.SyntaxError, 'invalid flags');
    end;
  Values['source'] := PropertyValue.NotAllFlags(aPattern);
  Values['global'] := PropertyValue.NotAllFlags(fGlobalVal);
  Values['ignoreCase'] := PropertyValue.NotAllFlags(RegexOptions.IgnoreCase in lOpt);
  Values['multiline'] := PropertyValue.NotAllFlags(RegexOptions.Multiline in lOpt);
  Values['lastIndex'] := new PropertyValue(PropertyAttributes.Writable, Undefined.Instance);
  try
    fRegex := new Regex(aPattern, lOpt);
  except
    on e: Exception do
      aGlobal.RaiseNativeError(NativeErrorType.SyntaxError, e.Message);
  end;
end;

method EcmaScriptRegexpObject.set_LastIndex(value: Integer);
begin
  self.Put(nil, 'lastIndex', value, 0);
end;


method EcmaScriptRegexpObject.Recreate(aPattern: String; aSettings: RegexOptions);
begin
  fRegex := new Regex(aPattern, aSettings);
end;

end.