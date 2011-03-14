{

  Copyright (c) 2009-2011 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  Microsoft,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)
  public
    method CreateJSON: EcmaScriptObject;
    method JSONParse(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method JSONStringify(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;

    method JSONParse(aTok: Tokenizer): Object;
    method Walk(aCaller: ExecutionContext; aRoot: EcmaScriptObject; aReviver: EcmaScriptBaseFunctionObject; aName: string; aCurrent: EcmaScriptObject): Object;
  end;  


implementation

method GlobalObject.CreateJSON: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'JSON'));
  if result <> nil then exit;

  result := new EcmaScriptObject(self, ObjectPrototype, &Class := 'JSON');
  Values.Add('parse', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parse', @JSONParse, 1, false)));
  Values.Add('stringify', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'stringify', @JSONStringify, 1, false)));

  result.Prototype := ObjectPrototype;
end;

method GlobalObject.JSONParse(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lTok := new Tokenizer();
  lTok.Error += method (Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String); 
    begin
      RaiseNativeError(NativeErrorType.SyntaxError, 'Error in json data at '+caller.Row+':'+caller.Col);
    end;
  lTok.SetData(UTilities.GetArgAsString(args, 0), '');
  result := JSONParse(lTok);
  if lTok.Token <> TokenKind.EOF then 
    RaiseNativeError(NativeErrorType.SyntaxError, 'EOF expected '+lTok.Row+':'+lTok.Col);
  var lReviver := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 1));
  if lReviver <> nil then begin
    var lWork := new EcmaScriptObject(self);
    lWork.DefineOwnProperty('', new PropertyValue(PropertyAttributes.None, result), false);
    result := Walk(aCaller, lWork, lReviver, '', lWork);
  end;
end;

method GlobalObject.JSONParse(aTok: Tokenizer): Object;
begin
  case aTok.Token of 
    TokenKind.K_null: exit nil;
    TokenKind.K_true: exit true;
    TokenKind.K_false: exit false;
    TokenKind.OpeningBracket: begin
      aTok.Next;
      result := new EcmaScriptArrayObject(self, 0);
      if aTok.Token = TokenKind.ClosingBracket then begin
        aTok.Next;
        exit;
      end;

      loop begin
        EcmaScriptArrayObject(result).AddValue(JSONParse(aTok));
        if aTok.Token = TokenKind.ClosingBracket then begin
          aTok.Next;
          exit;
        end;
        if atok.Token <> TokenKind.Comma then begin
          RaiseNativeError(NativeErrorType.SyntaxError, 'Comma expected at '+aTok.Row+':'+aTok.Col);
        end;
        aTok.Next;
      end;
    end;

    TokenKind.CurlyOpen: begin
      aTok.Next;
      result := new EcmaScriptObject(self);
      if aTok.Token = TokenKind.CurlyClose then begin
        aTok.Next;
        exit;
      end;
      loop begin
        if aTok.Token <> TokenKind.String then 
          RaiseNativeError(NativeErrorType.SyntaxError, 'String expected at '+aTok.Row+':'+aTok.Col);
        var lKey := Tokenizer.DecodeString(aTok.TokenStr);
        aTok.Next;
        if aTok.Token <> TokenKind.Colon then 
          RaiseNativeError(NativeErrorType.SyntaxError, 'Colon expected at '+aTok.Row+':'+aTok.Col);
        aTok.Next;
        var lValue := JSONParse(aTok);
        EcmaScriptObject(result).AddValue(lKey, lValue);
        if aTok.Token = TokenKind.CurlyClose then begin
          aTok.Next;
          exit;
        end;
        if atok.Token <> TokenKind.Comma then begin
          RaiseNativeError(NativeErrorType.SyntaxError, 'Comma expected at '+aTok.Row+':'+aTok.Col);
        end;
        aTok.Next;
      end;
    end;

    TokenKind.String: exit Tokenizer.DecodeString(aTok.TokenStr);
    TokenKind.Float: begin
      var d: Double;
      if not Double.TryParse(aTok.TokenStr, System.Globalization.NumberStyles.Float, System.Globalization.NumberFormatInfo.InvariantInfo, out d) then
        RaiseNativeError(NativeErrorType.SyntaxError, 'Number expected at '+aTok.Row+':'+aTok.Col);
      exit d;
    end;
    TokenKind.Number: begin
      var i: Integer; 
      var i6: Int64;
      if not Int32.TryParse(aTok.TokenStr, out i) then begin
        if Int64.TryParse(aTok.Tokenstr, out i6) then exit i6;
        RaiseNativeError(NativeErrorType.SyntaxError, 'Number expected at '+aTok.Row+':'+aTok.Col);
      end;
      exit i;
    end;
  else
    RaiseNativeError(NativeERrorType.SyntaxError, 'JSON object expected at '+aTok.Row+':'+aTok.Col);
  end; // case
end;

method GlobalObject.JSONStringify(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;


method GlobalObject.Walk(aCaller: ExecutionContext; 
  aRoot: EcmaScriptObject; 
  aReviver: EcmaScriptBaseFunctionObject; 
  aName: string; aCurrent: EcmaScriptObject): Object;
begin
  var lItem := aCurrent.Get(aCaller, 2, aName);
  var lEc := EcmaScriptObject(lItem);
  if lEc <> nil then begin
    var lArr := EcmaScriptArrayObject(lEc);
    if lArr <> nil then begin
      var i: Integer := 0;
      while i < lArr.Items.Count do begin
        var lNewVal := Walk(aCaller, aRoot, aReviver,i.ToString, lArr);
        if lNewVal = Undefined.Instance then
          lArr.Items.RemoveAt(i)
        else begin
          lArr.Items[i] := lNewVal;
          inc(i);
        end;
      end;
    end else begin
      for each el in System.Linq.Enumerable.ToArray(lEc.Values.Keys) do begin // copy it first
        var lNewVal := Walk(aCaller, aRoot, aReviver, el, lArr);
        if lNewVal = undefined.Instance then
          lEc.Delete(el, false)
        else
          lEc.DefineOwnProperty(el, new PropertyValue(PropertyAttributes.None, lNewVal), false);
      end;
    end;
  end;
  exit aReviver.CallEx(aCaller, aRoot,aName, lItem);
end;

end.
