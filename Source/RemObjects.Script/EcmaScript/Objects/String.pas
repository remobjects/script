//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Text,
  System.Text.RegularExpressions,
  RemObjects.Script.EcmaScript.Internal;

type
  GlobalObject = public partial class(EcmaScriptObject)
  private
    class var fStringReplacementPlaceholders: Regex := new Regex("(\\$[`'&])|(\\$([1-9]{1}(?![0-9])|[0-9]{2}))", RegexOptions.Compiled);

  public
    method CreateString: EcmaScriptObject;

    method StringCall(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringCtor(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringFromCharCode(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringToString(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringValueOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringCharAt(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringCharCodeAt(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringConcat(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringIndexOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringLastIndexOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringLocaleCompare(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringMatch(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringReplace(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringSearch(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringSlice(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method StringSplit(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method StringSubString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method StringSubStr(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method StringToLowerCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringToUpperCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringToLocaleLowerCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringToLocaleUpperCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method StringTrim(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
  end;


  EcmaScriptStringObject = class(EcmaScriptFunctionObject)
  public
    method Call(context: ExecutionContext;  params args: array of Object): Object; override;
    method Construct(context: ExecutionContext;  params args: array of Object): Object; override;
  end;


implementation


method GlobalObject.CreateString: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get('String'));
  if  (result <> nil)  then
    exit;

  result := new EcmaScriptStringObject(self, 'String', @StringCall, 1, &Class := 'String');
  Values.Add('String', PropertyValue.NotEnum(Result));

  StringPrototype := new EcmaScriptObject(self, &Class := 'String');
  StringPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  StringPrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(StringPrototype);
  
  result.Values.Add('fromCharCode', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'fromCharCode', @StringFromCharCode, 1)));
  StringPrototype.Values.Add('length', PropertyValue.NotAllFlags(0));
  StringPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @StringToString, 0)));
  StringPrototype.Values.Add('valueOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'valueOf', @StringValueOf, 0)));
  StringPrototype.Values.Add('charAt', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'charAt', @StringCharAt, 1)));
  StringPrototype.Values.Add('charCodeAt', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'charCodeAt', @StringCharCodeAt, 1)));
  StringPrototype.Values.Add('concat', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'concat', @StringConcat, 1)));
  StringPrototype.Values.Add('indexOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'indexOf', @StringIndexOf, 1)));
  StringPrototype.Values.Add('lastIndexOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'lastIndexOf', @StringLastIndexOf, 1)));

  StringPrototype.Values.Add('match', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'match', @StringMatch, 1))); // depends on regex support
  StringPrototype.Values.Add('replace', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'replace', @StringReplace, 2)));
  StringPrototype.Values.Add('search', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'search', @StringSearch, 1))); // depends on regex support
  StringPrototype.Values.Add('slice', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'slice', @StringSlice, 2)));
  StringPrototype.Values.Add('split', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'split', @StringSplit, 2)));
  StringPrototype.Values.Add('substring', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'substring', @StringSubString, 2)));
  StringPrototype.Values.Add('substr', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'substr', @StringSubStr, 2)));
  StringPrototype.Values.Add('toLowerCase', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLowerCase', @StringToLowerCase, 0)));
  StringPrototype.Values.Add('toUpperCase', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toUpperCase', @StringToUpperCase, 0)));
  StringPrototype.Values.Add('toLocaleLowerCase', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleLowerCase', @StringToLocaleLowerCase, 0)));
  StringPrototype.Values.Add('toLocaleUpperCase', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleUpperCase', @StringToLocaleUpperCase, 0)));

  StringPrototype.Values.Add('localeCompare', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'localeCompare', @StringLocaleCompare, 1)));
  StringPrototype.Values.Add('trim', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'trim', @StringTrim, 0)));
end;


method GlobalObject.StringCall(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  exit coalesce(Utilities.GetArgAsString(args, 0, aCaller), String.Empty);
end;


method GlobalObject.StringCtor(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lVal := if  (length(args) = 0)  then
                String.Empty
              else
                coalesce(Utilities.GetArgAsString(args, 0, aCaller), String.Empty);

  var lObj := new EcmaScriptObject(self, StringPrototype, &Class := 'String', Value := lVal);
  lObj.Values.Add('length', PropertyValue.NotDeleteAndReadOnly(lVal.Length));

  exit  (lObj);
end;


method GlobalObject.StringFromCharCode(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lRes := new Char[length(args)];

  for  i: Int32  :=  0  to  lRes.Length-1  do
    lRes[i] := Char(Utilities.GetArgAsInteger(args, i, aCaller));

  exit  (new String(lRes));
end;


method GlobalObject.StringToString(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  if  (aSelf is String)  then
    exit  (aSelf);

  if  ((aSelf is EcmaScriptObject)  and  (EcmaScriptObject(aSelf).Class = 'String'))  then
    exit  (EcmaScriptObject(aSelf).Value);

  RaiseNativeError(NativeErrorType.TypeError, 'String.prototype.toString is not generic');
end;


method GlobalObject.StringValueOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  if  (aSelf is String)  then
    exit  (aSelf);
  if  ((aSelf is EcmaScriptObject)  and  (EcmaScriptObject(aSelf).Class = 'String'))  then
    exit  (EcmaScriptObject(aSelf).Value);

  RaiseNativeError(NativeErrorType.TypeError, 'String.prototype.valueOf is not generic');
end;


method GlobalObject.StringCharAt(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf := coalesce(Utilities.GetObjAsString(aSelf, aCaller), String.Empty);
  var lIndex := Utilities.GetArgAsInteger(args, 0, aCaller);

  if  ((lIndex < 0)  or  (lIndex >= lSelf.Length))  then
    exit  (String.Empty);

  exit  (new String(lSelf[lIndex], 1));
end;


method GlobalObject.StringCharCodeAt(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf := coalesce(Utilities.GetObjAsString(aSelf, aCaller), String.Empty);
  var lIndex := Utilities.GetArgAsInteger(args, 0, aCaller);

  if  ((lIndex < 0)  or  (lIndex >= lSelf.Length))  then
    exit  (Double.NaN);

  exit  (Integer(lSelf[lIndex]));
end;


method GlobalObject.StringConcat(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf := coalesce(Utilities.GetObjAsString(aSelf, aCaller), String.Empty);

  if  (args.Length = 0)  then
    exit  (lSelf);

  if  (args.Length = 1)  then
    exit  (lSelf + Utilities.GetArgAsString(args, 0, aCaller));

  if  (args.Length = 2)  then
    exit  (lSelf + Utilities.GetArgAsString(args, 0, aCaller)+ Utilities.GetArgAsString(args, 1, aCaller));

  var fsb := new StringBuilder();
  fsb.Append(lSelf);

  for  i: Int32  :=  0  to  args.Length-1  do
    fsb.Append(Utilities.GetArgAsString(args, i, aCaller));

  exit  (fsb.ToString());
end;


method GlobalObject.StringIndexOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf := coalesce(Utilities.GetObjAsString(aSelf, aCaller), String.Empty);
  var lNeedle := coalesce(Utilities.GetArgAsString(args, 0, aCaller), String.Empty);
  var lIndex := Utilities.GetArgAsInteger(args, 1, aCaller);

  if  (lIndex >= lSelf.Length)  then
    exit  (-1);

  exit  (lSelf.IndexOf(lNeedle, lIndex));
end;


method GlobalObject.StringLastIndexOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf := coalesce(Utilities.GetObjAsString(aSelf, aCaller), String.Empty);
  var lNeedle := coalesce(Utilities.GetArgAsString(args, 0, aCaller), String.Empty);
  var lIndex := Utilities.GetArgAsInteger(args, 1, aCaller);

  if  ((lIndex >= lSelf.Length)  or  (lIndex = 0))  then
    lIndex := lSelf.Length;

  exit  (lSelf.LastIndexOf(lNeedle, lIndex));
end;


method GlobalObject.StringReplace(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;

  method ExtractMatchPlaceholders(value: String): IList<Match>;
  begin
    var replacementPlaceholders: List<Match> := List<Match>(nil);
    for each match: Match in GlobalObject.fStringReplacementPlaceholders.Matches(value) do begin
      if not match.Success then begin
        continue;
      end;

      var i: Int32 := match.Index;
      var count: Int32 := 1;
      var &result: Int32 := 0;
      while i > 0 do begin
        dec(i);
        if value[i] <> '$' then begin
          break;
        end;
        inc(count);
      end;
      Math.DivRem(count, 2, out &result);
      if &result <> 0 then begin
        if not assigned(replacementPlaceholders) then begin
          replacementPlaceholders := new List<Match>();
        end;
        replacementPlaceholders.Add(match);
      end;
    end;

    exit replacementPlaceholders;
  end;

  method FixRegExpSymbols(pattern: String): String;
  begin
    if String.IsNullOrEmpty(pattern) then begin
      exit '';
    end;

    var symbols: array of String := ['\', '[', ']', '^', '!', '|', '$', '?', '=', '{', '}', '+', '*', '(', ')'];

    for i: Int32 := 0 to symbols.Length-1 do begin
      pattern := pattern.Replace(symbols[i], '\' + symbols[i]);
    end;

    exit pattern;
  end;

begin
  var selfReference: String := coalesce(Utilities.GetObjAsString(aSelf, aCaller), '');
  if args.Length = 0 then begin
    exit selfReference;
  end;

  var arg_0: Object := Utilities.GetArg(args, 0);
  if not assigned(arg_0) or (arg_0 = Undefined.Instance) then begin
    exit selfReference;
  end;

  var arg_1: Object := Utilities.GetArg(args, 1);
  var callback: EcmaScriptInternalFunctionObject := EcmaScriptInternalFunctionObject(arg_1);
  var newValue: String := nil;
  if not assigned(callback) then begin
    newValue := coalesce(Utilities.GetObjAsString(arg_1, aCaller), '');
  end;

  var replacementPlaceholders: IList<Match> := nil;
  if not String.IsNullOrEmpty(newValue) then begin
    replacementPlaceholders := ExtractMatchPlaceholders(newValue);
  end;

  var pattern: EcmaScriptRegexpObject := EcmaScriptRegexpObject(arg_0);
  if (not assigned(pattern)) and (assigned(callback) or assigned(replacementPlaceholders)) then begin
    pattern := new EcmaScriptRegexpObject(aCaller.Global, FixRegExpSymbols(Utilities.GetObjAsString(arg_0, aCaller)), '');
  end;

  if not (assigned(callback) or assigned(replacementPlaceholders)) then begin
   if not assigned(pattern) then begin
      // This will replace all occurrences
      exit selfReference.Replace(Utilities.GetObjAsString(arg_0, aCaller), newValue);
    end;

    if pattern.GlobalVal then begin
      exit pattern.Regex.Replace(selfReference, newValue);
    end;

    exit pattern.Regex.Replace(selfReference, newValue, 1);
  end;

  var evaluator: MatchEvaluator := nil;

  if not assigned(replacementPlaceholders) then begin
    var callbackArgs: array of Object := nil;
    var groups: Int32 := 0;
    evaluator :=
      (match) ->
      begin
        if not assigned(callbackArgs) then begin
          groups := match.Groups.Count;
          callbackArgs := new Object[groups+2];
          callbackArgs[callbackArgs.Length-1] := selfReference;
        end;

        for i: Int32 := 0 to groups-1 do begin
          if i = 0 then begin
            callbackArgs[callbackArgs.Length-2] := match.Groups[i].Index;
          end;
          callbackArgs[i] := iif(match.Groups[i].Success, Object(match.Groups[i].Value), Undefined.Instance);
        end;

        var replacment: String := Utilities.GetObjAsString(callback.CallEx(aCaller, aCaller.Global, callbackArgs), aCaller);

        exit replacment;
      end;
  end
  else begin
    var text: StringBuilder := new StringBuilder();

    evaluator :=
      (match) ->
      begin
        text.Length := 0;
        var &index: Int32 := 0;
        var matchIndex: Int32 := 0;
        var matchCount: Int32 := match.Groups.Count;
        for each placeholder in replacementPlaceholders do begin
          text.Append(newValue.Substring(&index, placeholder.Index-&index).Replace('$$', '$')); // Remove escape symbols

          case placeholder.Value of
            '$`':
                begin
                  // Insert portion of the string that precedes the matched substring
                  text.Append(selfReference.Substring(0, match.Index));
                end;
            "$'":
                begin
                  // Insert portion of the string that follows the matched substring
                  &index := match.Index + match.Value.Length;
                  if &index < selfReference.Length then begin
                    text.Append(selfReference.Substring(&index));
                  end;
                end;
            '$&':
                begin
                  text.Append(match.Groups[0].Value);
                end;
            else
                begin
                  matchIndex := Int32.Parse(placeholder.Value.Substring(1));
                  if matchIndex < matchCount then begin
                    text.Append(match.Groups[matchIndex].Value);
                  end;
               end;
          end;

          &index := placeholder.Index + placeholder.Value.Length;
        end;

        if &index < newValue.Length then begin
          text.Append(newValue.Substring(&index).Replace('$$', '$'));
        end;

        exit text.ToString();
      end;
  end;

  if pattern.GlobalVal then begin
    exit pattern.Regex.Replace(selfReference, evaluator);
  end;

  exit pattern.Regex.Replace(selfReference, evaluator, 1);
end;


method GlobalObject.StringSlice(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lSelf: String := coalesce(Utilities.GetObjAsString(&self, caller), String.Empty);

  if not assigned(lSelf) then
    exit Undefined.Instance;

  var lStart: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lObj: Object := Utilities.GetArg(args, 1);
  var lEnd: Int32 := iif((lObj = nil) or (lObj = Undefined.Instance), Int32.MaxValue, Utilities.GetObjAsInteger(lObj, caller));

  if lStart < 0 then  begin
    lStart := lSelf.Length + lStart;
    if lStart < 0 then 
      lStart := 0;
  end;

  if lEnd < 0 then begin 
    lEnd := lSelf.Length + lEnd;
    if lEnd < 0 then
      lEnd := 0;
  end;

  if lEnd < lStart then
    lEnd := lStart;

  if lStart > lSelf.Length then
    lStart := lSelf.Length;

  if lEnd > lSelf.Length then
    lEnd := lSelf.Length;

  exit lSelf.Substring(lStart, lEnd - lStart);
end;


method GlobalObject.StringSplit(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lSelf: String := coalesce(Utilities.GetObjAsString(&self, caller), String.Empty);
  var lNeedle: String := coalesce(Utilities.GetArgAsString(args, 0, caller), String.Empty);
  var lMax: Int32 := Utilities.GetArgAsInteger(args, 1, caller);

  if  (lMax <= 0)  then
    lMax := Int32.MaxValue;

  exit new EcmaScriptArrayObject(self, 0).AddValues(lSelf.Split([ lNeedle ], lMax, StringSplitOptions.None));
end;


method GlobalObject.StringSubString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lSelf: String := coalesce(Utilities.GetObjAsString(&self, caller), String.Empty);

  if not assigned(lSelf) then
    exit Undefined.Instance;

  if lSelf.Length = 0 then
    exit String.Empty;

  var lStart: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lObj: Object := Utilities.GetArg(args, 1);
  var lEnd: Int32 := iif((lObj = nil) or (lObj = Undefined.Instance), Int32.MaxValue, Utilities.GetObjAsInteger(lObj, caller));

  if lStart < 0 then
    lStart := 0;

  if lEnd < 0 then
    lEnd := 0;

  if lStart = lEnd then
    exit String.Empty;

  if lEnd < lStart then begin // swap indeces
    var bufEnd: Int32 := lEnd;
    lEnd := lStart;
    lStart := bufEnd;
  end;

  if lStart > (lSelf.Length-1) then
    exit String.Empty;

  if lEnd > lSelf.Length then
    lEnd := lSelf.Length;

  exit lSelf.Substring(lStart, lEnd-lStart);
end;


method GlobalObject.StringSubStr(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lSelf: String := coalesce(Utilities.GetObjAsString(&self, caller), String.Empty);

  if not assigned(lSelf) then
    exit Undefined.Instance;

  if lSelf.Length = 0 then
    exit String.Empty;

  var lStart: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lObj: Object := Utilities.GetArg(args, 1);
  var lEnd: Int32 := iif((lObj = nil) or (lObj = Undefined.Instance), Int32.MaxValue, Utilities.GetObjAsInteger(lObj, caller));

  if lEnd <= 0 then
    exit String.Empty;

  if lStart < 0 then begin
    lStart := lSelf.Length + lStart;
    if lStart < 0 then 
      lStart := 0;
  end;

  if lSelf.Length <= lStart then
    exit String.Empty;

  exit lSelf.Substring(lStart, Math.Min(lEnd, lSelf.Length-lStart));
end;


method GlobalObject.StringToLowerCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf: String := String(aSelf);

  if  ((lSelf = nil)  and  (aSelf is EcmaScriptObject))  then
    lSelf := String(EcmaScriptObject(aSelf).Value);

  if  (lSelf = nil)  then
    RaiseNativeError(NativeErrorType.TypeError, 'String.prototype.toLowerCase is not generic');

  exit  (lSelf.ToLowerInvariant());
end;


method GlobalObject.StringToUpperCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf: String := String(aSelf);

  if  ((lSelf = nil)  and  (aSelf is EcmaScriptObject))  then
    lSelf := String(EcmaScriptObject(aSelf).Value);

  if  (lSelf = nil)  then
    RaiseNativeError(NativeErrorType.TypeError, 'String.prototype.toUpperCase is not generic');

  exit  (lSelf.ToUpperInvariant());
end;


method GlobalObject.StringToLocaleLowerCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf: String := String(aSelf);

  if  ((lSelf = nil)  and  (aSelf is EcmaScriptObject))  then
    lSelf := String(EcmaScriptObject(aSelf).Value);

  if  (lSelf = nil)  then
    RaiseNativeError(NativeErrorType.TypeError, 'String.prototype.toLocaleLowerCase is not generic');

  exit  (lSelf.ToLower());
end;


method GlobalObject.StringToLocaleUpperCase(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf: String := String(aSelf);
  if  ((lSelf = nil)  and  (aSelf is EcmaScriptObject))  then
    lSelf := String(EcmaScriptObject(aSelf).Value);

  if  (lSelf = nil)  then
    RaiseNativeError(NativeErrorType.TypeError, 'String.prototype.toLocaleUpperCase is not generic');

  exit  (lSelf.ToUpper());
end;


method GlobalObject.StringSearch(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf := coalesce(Utilities.GetObjAsString(aSelf, aCaller), String.Empty);
  var lObj: EcmaScriptRegexpObject;

  if  ((length(args) = 0)  or  (args[0] is not EcmaScriptRegexpObject))  then
    lObj := new EcmaScriptRegexpObject(self, Utilities.GetArgAsString(args,0, aCaller), '')
  else
    lObj := EcmaScriptRegexpObject(args[0]);

  try
    var lMatch := lObj.Regex.Match(lSelf);
    exit  (iif((lMatch = nil) or not lMatch.Success, -1, lMatch.Index));
  except
    on  ex: Exception  do
      RaiseNativeError(NativeErrorType.SyntaxError, ex.Message);
  end;
end;


method GlobalObject.StringMatch(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lSelf := coalesce(Utilities.GetObjAsString(aSelf, aCaller), String.Empty);
  var lObj: EcmaScriptRegexpObject;

  if  ((length(args) = 0) or (args[0] is not EcmaScriptRegexpObject))  then
    lObj := new EcmaScriptRegexpObject(self, Utilities.GetArgAsString(args,0, aCaller), '')
  else
    lObj := EcmaScriptRegexpObject(args[0]);

  if  (not lObj.GlobalVal)  then
    exit  (RegExpExec(aCaller, lObj, lSelf));
  
  var lRealResult := new EcmaScriptArrayObject(self, 0);

  lObj.LastIndex := 0;
  var lLastMatch := true;
  var lPrevLastIndex := 0;
  while lLastMatch do begin
    var lRes := EcmaScriptArrayObject(RegExpExec(aCaller, lObj, lSelf));
    if lRes = nil then 
      lLastMatch := false
    else begin
      var lThisIndex := Utilities.GetObjAsInteger(lObj.Get(aCaller, 0, 'lastIndex'), aCaller);
      if lThisIndex = lPrevLastIndex then begin
        lPrevLastIndex := lThisIndex + 1;
        lObj.LastIndex := lPrevLastIndex;
      end else
        lPrevLastIndex := lThisIndex;
      var lMatchStr := lRes.Get(aCaller, 2, '0');
      lRealResult.AddValue(lMatchStr);
    end;
  end;

  if  (lRealResult.Length = 0)  then
    exit  (nil);

  exit  (lRealResult);
end;


method GlobalObject.StringLocaleCompare(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  if (aSelf = nil) or (aSelf = Undefined.Instance) then RaiseNativeError(NativeErrorType.TypeError, 'null/undefined not coercible');
  exit String.Compare(Utilities.GetObjAsString(aSelf, aCaller), Utilities.GetArgAsString(args, 0, aCaller), StringComparison.CurrentCulture);
end;


method GlobalObject.StringTrim(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  if (aSelf = nil) or (aSelf = Undefined.Instance) then RaiseNativeError(NativeErrorType.TypeError, 'null/undefined not coercible');
  exit Utilities.GetObjAsString(aSelf, aCaller).Trim();
end;


method EcmaScriptStringObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  exit Root.StringCall(context, self, args);
end;


method EcmaScriptStringObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  exit Root.StringCtor(context, self, args);
end;


end.