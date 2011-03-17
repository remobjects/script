{

  Copyright (c) 2009-2011 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  System.Linq,
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
  private
    method JSONStr(aExecutionContext: ExecutionContext; aStack: List<Object>; aGap, aIndent: string; aReplacerFunction: EcmaScriptBaseFunctionObject; 
      aProplist: List<String>; aWork: EcmaScriptObject; aValue: String): string;
    class method JSONQuote(val: String): string;
  end;  


implementation

method GlobalObject.CreateJSON: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'JSON'));
  if result <> nil then exit;

  result := new EcmaScriptObject(self, ObjectPrototype, &Class := 'JSON');
  Values.Add('JSON', PropertyValue.NotEnum(Result));
  result.Values.Add('parse', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parse', @JSONParse, 1, false)));
  result.Values.Add('stringify', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'stringify', @JSONStringify, 1, false)));

  result.Prototype := ObjectPrototype;
end;

method GlobalObject.JSONParse(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lTok := new Tokenizer();
  lTok.JSON := true;
  lTok.Error += method (Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String); 
    begin
      RaiseNativeError(NativeErrorType.SyntaxError, 'Error in json data at '+caller.Row+':'+caller.Col);
    end;
  lTok.SetData(UTilities.GetArgAsString(args, 0, aCaller), '');
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
    TokenKind.K_null: begin result := nil; aTok.Next; exit; end;
    TokenKind.K_true: begin result := true; aTok.Next; exit; end;
    TokenKind.K_false: begin result := false; aTok.Next; exit; end;
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

    TokenKind.String: begin
      result := Tokenizer.DecodeString(aTok.TokenStr);
      aTok.Next;
      exit;
    end;
    TokenKind.Float: begin
      var d: Double;
      if not Double.TryParse(aTok.TokenStr, System.Globalization.NumberStyles.Float, System.Globalization.NumberFormatInfo.InvariantInfo, out d) then
        RaiseNativeError(NativeErrorType.SyntaxError, 'Number expected at '+aTok.Row+':'+aTok.Col);
      aTok.Next;
      exit d;
    end;
    TokenKind.Number: begin
      var i: Integer; 
      var i6: Int64;
      if not Int32.TryParse(aTok.TokenStr, out i) then begin
        if Int64.TryParse(aTok.Tokenstr, out i6) then exit i6;
        RaiseNativeError(NativeErrorType.SyntaxError, 'Number expected at '+aTok.Row+':'+aTok.Col);
      end;
      aTok.Next;
      exit i;
    end;
  else
    RaiseNativeError(NativeERrorType.SyntaxError, 'JSON object expected at '+aTok.Row+':'+aTok.Col);
  end; // case
end;

method GlobalObject.JSONStringify(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lStack := new List<Object>;
  var lIndent := string.Empty;
  var lGap: string := String.Empty;
  var lReplacerFunction := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 1));
  var lProplist: List<string> := nil;
  if lReplacerFunction = nil then begin 
    var lItem :=  EcmaScriptArrayObject(Utilities.GetArg(Args, 1));
    lPropList := new List<String>;
    if lItem <> nil then begin
      for i: Integer := 0 to lItem.Items.Count -1 do begin
        var lEl := lItem.Items[i];
        if (lEl = nil) or (lEl =  Undefined.Instance) then continue;
        lPropList.Add(lEl.ToString);
      end;
    end;
  end;
  var lSpace := Utilities.GetArg(args, 2);
  if lSpace is EcmaScriptObject then begin
    if EcmaScriptObject(lSpace).Class = 'Number' then
      lGap := new String(' ', Utilities.GetObjAsInteger(lSpace, aCaller))
    else if EcmaScriptObject(lSpace).Class = 'String' then
      lGap := Utilities.GetObjAsString(lSpace, aCaller);
  end else if lSpace is string then
    lGap := String(lSpace)
  else if (lSpace is Int32) or (lSpace is Double) then
    lGap := new String(' ', Utilities.GetObjAsInteger(lSpace, aCaller));
  if Length(lGap) > 10 then lGap := lGap.Substring(0,10);
  var lWork := new EcmaScriptObject(self);
  lWork.DefineOwnProperty('', new PropertyValue(PropertyAttributes.All, Utilities.GetArg(args, 0)), false);
  exit JSONStr(aCaller, lStack, lGap, lIndent, lReplacerFunction, lProplist, lWork, '');
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

method GlobalObject.JSONStr(aExecutionContext: ExecutionContext; aStack: List<Object>; aGap, aIndent: string; aReplacerFunction: EcmaScriptBaseFunctionObject; 
      aProplist: List<String>; aWork: EcmaScriptObject; aValue: String): string;
begin
  var value := aWork.Get(aExecutionContext, 2, aValue);
  var lObj := EcmaScriptObject(Value);
  if lObj<> nil then begin
    var lCall := EcmaScriptBaseFunctionObject(lObj.Get(aExecutionContext, 2, 'toJSON'));
    if lCall <> nil then
      value := lCall.CallEx(aExecutionContext, lObj, aValue);
  end;
  if aReplacerFunction <> nil then begin
    value := aReplacerFunction.CallEx(aExecutionContext, aWork,aValue, Value);
  end;
  lObj := EcmaScriptObject(VAlue);
  if lObj <> nil then begin
    if lobj.Class = 'Number' then Value := lObj.Value else
    if lObj.Class = 'String' then Value := lObj.Value;
    if lObj.Class = 'Boolean' then Value := lObj.Value;
  end;
  if value = nil then exit 'null';
  if value is boolean then begin 
    if boolean(value) then 
      exit 'true';
    exit 'false';
  end;
  if value is string then exit JSONQuote(String(value));
  if value is double then begin
    if Double.IsInfinity(Double(value)) then
      exit 'null'
    else
      exit Double(value).ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
  end;
  if value is Int32 then exit Int32(Value).ToString;
  if value is Int64 then exit Int64(Value).ToString;
  lObj := EcmaScriptObject(VAlue);
  if (lObj <> nil) and (lObj is not EcmaScriptBaseFunctionObject) then begin
    if aStack.Contains(lObj) then RaiseNativeError(NativeErrorType.TypeError, 'Recursive JSON structure');
    aStack.Add(lObj);
    var lWork := new StringBuilder;
    if lObj.Class = 'Array' then begin
      if EcmaScriptArrayObject(lObj).Items.Count = 0 then begin
        lWork.Append('[]');

      end;

      aIndent := aIndent + aGap;

      for i: Integer := 0 to EcmaScriptArrayObject(lObj).Items.Count -1 do begin
        var el := JSONStr(aExecutionContext, aStack, aGap, aIndent,aReplacerFunction, aProplist, lObj, i.ToString());
        if el =  nil then el := 'null';
        if i = 0 then begin
          if aGap = '' then
            lWork.Append('[')
          else begin
            lWork.Append('['#10);
            lWork.Append(aIndent);
          end;
        end;
        lWork.Append(el);
        if i = EcmaScriptArrayObject(lObj).Items.Count -1 then begin
          if aGap = '' then begin
            lWork.Append(']')
          end else begin
            lWork.Append(#10);
            lWork.Append(aIndent.Substring(0, aIndent.Length - aGap.Length));
            lWork.Append(']');
          end;
        end else begin
          if aGap = '' then lWork.Append(',') else begin
            lWork.Append(','#10);
            lWork.Append(aIndent);
          end;
        end;
      end; 
    end else begin
      var lStepBack := aIndent;
      aIndent := aIndent + aGap;
      var k := aProplist:ToArray;
      if k = nil then
        k := lObj.Values.Where(a->PropertyAttributes.Enumerable in a.Value.Attributes).Select(a->a.Key).ToArray;
      var lItems := new List<string>;
      for each el in k do begin
        var lVal := JSONStr(aExecutionContext, aStack, aGap, aIndent, aReplacerFunction, aProplist, lObj, el);
        if lVal <> nil then begin
          if aGap = '' then
            lItems.Add(JSONQuote(el)+':'+lVal)
          else
            lItems.Add(JSONQuote(el)+': '+lVal);
        end;
      end;
      if lItems.Count = 0 then
        lWork.Append('{}')
      else begin
        if aGap = '' then begin
          lWork.Append('{');
          for i: Integer := 0 to lItems.Count -1 do begin
            if i <> 0 then lWork.Append(',');
            lWork.Append(lItems[i]);
          end;
          lWork.Append('}');
        end else begin
          lWork.Append('{'#10);
          lWork.Append(aIndent);
          for i: Integer := 0 to lItems.Count -1 do begin
            if (i <> 0) and (i <> lItems.Count- 1) then begin 
              lWork.Append(','#10);
              lWork.Append(aIndent);
            end;
            lWork.Append(lItems[i]);
          end;
          lWork.Append(#10);
          lWork.Append(aIndent.Substring(0, aIndent.Length - aGap.Length));
          lWork.Append('}');
        end;
      end;
    end;
    aStack.Remove(lObj);
    exit lWork.ToString;
  end;
  exit nil;
end;

class method GlobalObject.JSONQuote(val: String): string;
begin
  var sb := new StringBuilder;
  sb.Append('"');
  for i: Integer := 0 to val.Length -1 do begin
    case val[i] of
      '"': sb.Append('\"');
      '\': sb.Append('\\');
      #10: sb.Append('\n');
      #13: sb.Append('\r');
      #12: sb.Append('\f');
      #9: sb.Append('\t');
      #8: sb.Append('\b');
      #0 .. #7, #11, #14 ..#31: begin
        sb.Append('\u');
        sb.Append(Integer(val[i]).ToString('x4'));
      end
    else
      sb.Append(val[i]);
    end; // case
  end;

  sb.Append('"');
  exit sb.ToString;
end;

end.
