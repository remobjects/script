{

  Copyright (c) 2009-2011 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Globalization,
  System.Text,
  System.Linq,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;

type
  GlobalObject = public partial class(EcmaScriptObject)
  public
    method CreateJSON: EcmaScriptObject;
    method JSONParse(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method JSONStringify(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method JSONParse(aTok: Tokenizer): Object;
    method Walk(aCaller: ExecutionContext;  aRoot: EcmaScriptObject;  aReviver: EcmaScriptBaseFunctionObject;
                   aName: String;  aCurrent: EcmaScriptObject): Object;
  private
    method JSONStr(aExecutionContext: ExecutionContext;  aStack: List<Object>;  aGap: String;  aIndent: String;
                   aReplacerFunction: EcmaScriptBaseFunctionObject;  aProplist: List<String>; aWork: EcmaScriptObject;
                   aValue: String): String;
  end;


  JSON = public static class
  public
    class method QuoteString(value: String): String;
    class method ToString(value: Object): String;
  end;


implementation


method GlobalObject.CreateJSON: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'JSON'));
  if  (result <> nil)  then
    exit;

  result := new EcmaScriptObject(self, ObjectPrototype, &Class := 'JSON');
  Values.Add('JSON', PropertyValue.NotEnum(Result));
  result.Values.Add('parse', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parse', @JSONParse, 1, false)));
  result.Values.Add('stringify', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'stringify', @JSONStringify, 1, false)));

  result.Prototype := ObjectPrototype;
end;


method GlobalObject.JSONParse(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lTok := new Tokenizer();
  lTok.JSON := true;
  lTok.Error +=    method(caller: Tokenizer;  kind: TokenizerErrorKind;  parameter: String); 
                   begin
                     RaiseNativeError(NativeErrorType.SyntaxError, 'Error in json data at '+caller.Row+':'+caller.Col);
                   end;

  lTok.SetData(Utilities.GetArgAsString(args, 0, aCaller), '');
  result := JSONParse(lTok);

  if  (lTok.Token <> TokenKind.EOF)  then 
    RaiseNativeError(NativeErrorType.SyntaxError, 'EOF expected '+lTok.Row+':'+lTok.Col);

  var lReviver := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 1));
  if  (lReviver <> nil)  then  begin
    var lWork := new EcmaScriptObject(self);
    lWork.DefineOwnProperty('', new PropertyValue(PropertyAttributes.None, result), false);
    result := Walk(aCaller, lWork, lReviver, '', lWork);
  end;
end;


method GlobalObject.JSONParse(aTok: Tokenizer): Object;
begin
  case  aTok.Token  of 
    TokenKind.K_null:
                   begin
                     result := nil;
                     aTok.Next();
                     exit;
                   end;

    TokenKind.K_true:
                   begin
                     result := true;
                     aTok.Next();
                     exit;
                   end;

    TokenKind.K_false:
                   begin
                     result := false;
                     aTok.Next();
                     exit;
                   end;

    TokenKind.OpeningBracket:
                   begin
                     aTok.Next;
                     result := new EcmaScriptArrayObject(self, 0);
                     if  (aTok.Token = TokenKind.ClosingBracket)  then  begin
                       aTok.Next();
                       exit;
                     end;

                     loop  begin
                       EcmaScriptArrayObject(result).AddValue(JSONParse(aTok));
                       if  (aTok.Token = TokenKind.ClosingBracket)  then  begin
                         aTok.Next();
                         exit;
                       end;

                       if  (aTok.Token <> TokenKind.Comma)  then
                         RaiseNativeError(NativeErrorType.SyntaxError, 'Comma expected at '+aTok.Row+':'+aTok.Col);

                       aTok.Next();
                     end;
                   end;

    TokenKind.CurlyOpen:
                   begin
                     aTok.Next;
                     result := new EcmaScriptObject(self);
                     if  (aTok.Token = TokenKind.CurlyClose)  then  begin
                       aTok.Next();
                       exit;
                     end;

                     loop  begin
                       if  (aTok.Token <> TokenKind.String)  then
                         RaiseNativeError(NativeErrorType.SyntaxError, 'String expected at '+aTok.Row+':'+aTok.Col);

                       var lKey := Tokenizer.DecodeString(aTok.TokenStr);
                       aTok.Next();

                       if  (aTok.Token <> TokenKind.Colon)  then
                         RaiseNativeError(NativeErrorType.SyntaxError, 'Colon expected at '+aTok.Row+':'+aTok.Col);
                       aTok.Next();

                       var lValue := JSONParse(aTok);
                       EcmaScriptObject(result).AddValue(lKey, lValue);
                       if  (aTok.Token = TokenKind.CurlyClose)  then  begin
                         aTok.Next();
                         exit;
                       end;

                       if  (aTok.Token <> TokenKind.Comma)  then
                         RaiseNativeError(NativeErrorType.SyntaxError, 'Comma expected at '+aTok.Row+':'+aTok.Col);

                       aTok.Next();
                     end;
                   end;

    TokenKind.String:
                   begin
                     result := Tokenizer.DecodeString(aTok.TokenStr);
                     aTok.Next();
                     exit;
                   end;

    TokenKind.Float:
                   begin
                     var d: Double;
                     if  (not Double.TryParse(aTok.TokenStr, System.Globalization.NumberStyles.Float, System.Globalization.NumberFormatInfo.InvariantInfo, out d))  then
                       RaiseNativeError(NativeErrorType.SyntaxError, 'Number expected at '+aTok.Row+':'+aTok.Col);

                     aTok.Next();
                     exit (d);
                   end;

    TokenKind.Number:
                   begin
                     var i: Integer; 
                     if  (not Int32.TryParse(aTok.TokenStr, out i))  then  begin
                       var i6: Int64;
                       if  (Int64.TryParse(aTok.TokenStr, out i6))  then begin
                         aTok.Next;
                         exit  (i6);
                       end;

                       RaiseNativeError(NativeErrorType.SyntaxError, 'Number expected at '+aTok.Row+':'+aTok.Col);
                     end;

                     aTok.Next;
                     exit  (i);
                   end;

    else           RaiseNativeError(NativeErrorType.SyntaxError, 'JSON object expected at '+aTok.Row+':'+aTok.Col);
  end;
end;


method GlobalObject.JSONStringify(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lStack: List<Object> := new List<Object>();
  var lIndent: String := String.Empty;
  var lGap: String := String.Empty;
  var lReplacerFunction := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 1));
  var lPropList: List<String> := nil;

  if  (lReplacerFunction = nil)  then  begin
    var lItem :=  EcmaScriptArrayObject(Utilities.GetArg(args, 1));
    lPropList := new List<String>();
    if  (lItem <> nil)  then  begin
      for  i: Int32  :=  0  to  lItem.Length-1  do  begin
        var lEl := lItem.Get(aCaller, 0, i.ToString());
        if  ((lEl = nil)  or  (lEl =  Undefined.Instance))  then
          continue;

        lPropList.Add(lEl.ToString());
      end;
    end;
  end;

  var lSpace := Utilities.GetArg(args, 2);
  if  (lSpace is EcmaScriptObject)  then  begin
    if  (EcmaScriptObject(lSpace).Class = 'Number')  then
      lGap := new String(' ', Utilities.GetObjAsInteger(lSpace, aCaller))
    else if  (EcmaScriptObject(lSpace).Class = 'String')  then
      lGap := Utilities.GetObjAsString(lSpace, aCaller);
  end
  else if  (lSpace is String)  then
    lGap := String(lSpace)
  else if  ((lSpace is Int32) or (lSpace is Double))  then
    lGap := new String(' ', Utilities.GetObjAsInteger(lSpace, aCaller));

  if  (length(lGap) > 10)  then
    lGap := lGap.Substring(0,10);

  var lWork := new EcmaScriptObject(self);
  lWork.DefineOwnProperty('', new PropertyValue(PropertyAttributes.All, Utilities.GetArg(args, 0)), false);

  exit  (self.JSONStr(aCaller, lStack, lGap, lIndent, lReplacerFunction, lPropList, lWork, ''));
end;


method GlobalObject.Walk(aCaller: ExecutionContext;  aRoot: EcmaScriptObject;  aReviver: EcmaScriptBaseFunctionObject;
                   aName: String;  aCurrent: EcmaScriptObject): Object;
begin
  var lItem := aCurrent.Get(aCaller, 2, aName);
  var lEc := EcmaScriptObject(lItem);
  if  (lEc <> nil)  then  begin
    var lArr := EcmaScriptArrayObject(lEc);
    if  (lArr <> nil)  then  begin
      var i: Int32 := 0;
      var lLen: Int32 := Int32(lArr.Length);
      while  (i < lLen)  do  begin
        var lNewVal := self.Walk(aCaller, aRoot, aReviver, i.ToString(), lArr);
        if  (lNewVal = Undefined.Instance)  then  begin
          lArr.Delete(i.ToString(), false);
        end
        else  begin
          lArr.Put(aCaller, i.ToString(), lNewVal);
          inc(i);
        end;
      end;
    end
    else  begin
      for each  el  in  System.Linq.Enumerable.ToArray(lEc.Values.Keys)  do  begin // copy it first
        var lNewVal := Walk(aCaller, aRoot, aReviver, el, lArr);
        if  (lNewVal = Undefined.Instance)  then
          lEc.Delete(el, false)
        else
          lEc.DefineOwnProperty(el, new PropertyValue(PropertyAttributes.None, lNewVal), false);
      end;
    end;
  end;

  exit  (aReviver.CallEx(aCaller, aRoot,aName, lItem));
end;


method GlobalObject.JSONStr(aExecutionContext: ExecutionContext;  aStack: List<Object>;  aGap: String;  aIndent: String;
                   aReplacerFunction: EcmaScriptBaseFunctionObject;  aProplist: List<String>;  aWork: EcmaScriptObject;
                   aValue: String): String;
begin
  var Value := aWork.Get(aExecutionContext, 0, aValue);

  var lObj := EcmaScriptObject(Value);
  if  (assigned(lObj))  then  begin
    var lCall := EcmaScriptBaseFunctionObject(lObj.Get(aExecutionContext, 0, 'toJSON'));
    if  (assigned(lCall))  then
      exit  (String(lCall.CallEx(aExecutionContext, lObj, aValue)));
  end;

  if  (aReplacerFunction <> nil)  then
    Value := aReplacerFunction.CallEx(aExecutionContext, aWork,aValue, Value);

  lObj := EcmaScriptObject(Value);
  if  (lObj <> nil)  then  begin
    if  (lObj.Class = 'Number')  then
      Value := lObj.Value
    else if  (lObj.Class = 'String')  then
      Value := lObj.Value
    else if  (lObj.Class = 'Boolean')  then
      Value := lObj.Value;
  end;

  var lResult: String := JSON.ToString(Value);
  if  (assigned(lResult))  then
    exit  (lResult);

  if  (lObj = nil)  then
    exit  (nil);

  if  ((lObj is EcmaScriptBaseFunctionObject)  and  (lObj is not EcmaScriptObjectWrapper))  then
    exit  (nil);

  with matching  wrapper := EcmaScriptObjectWrapper(lObj)  do
    if  (typeOf(&Delegate).IsAssignableFrom(wrapper.Value.GetType().BaseType))  then
      exit  ('function');

  if  (aStack.Contains(lObj))  then
    RaiseNativeError(NativeErrorType.TypeError, 'Recursive JSON structure');

  aStack.Add(lObj);
  var lWork := new StringBuilder;
  if  (lObj.Class = 'Array')  then  begin
    if  (EcmaScriptArrayObject(lObj).Length = 0)  then
      lWork.Append('[]');

    aIndent := aIndent + aGap;

    for i: Integer := 0 to EcmaScriptArrayObject(lObj).Length -1 do begin
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
      if i = EcmaScriptArrayObject(lObj).Length -1 then begin
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
  end
  else begin
    aIndent := aIndent + aGap;
    var k := aProplist:ToArray;
    if  (length(k) = 0)  then  begin
      if lObj is EcmaScriptObjectWrapper then
        k := EcmaScriptObjectWrapper(lObj).GetOwnNames.ToArray
      else
        k := lObj.Values.Where(a->PropertyAttributes.Enumerable in a.Value.Attributes).Select(a->a.Key).ToArray;
    end;
    var lItems: List<String> := new List<String>();
    for each el in k do begin
      var lVal := JSONStr(aExecutionContext, aStack, aGap, aIndent, aReplacerFunction, aProplist, lObj, el);
      if lVal <> nil then begin
        if aGap = '' then
          lItems.Add(JSON.QuoteString(el)+':'+lVal)
        else
          lItems.Add(JSON.QuoteString(el)+': '+lVal);
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
          if (i <> 0) then begin 
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

  exit  (lWork.ToString());
end;


class method JSON.QuoteString(value: String): String;
begin
  var sb: StringBuilder := new StringBuilder();

  sb.Append('"');
  for  i: Int32  :=  0  to  value.Length-1  do  begin
    case  value[i]  of
      '"':         sb.Append('\"');
      '\':         sb.Append('\\');
      #10:         sb.Append('\n');
      #13:         sb.Append('\r');
      #12:         sb.Append('\f');
      #9:          sb.Append('\t');
      #8:          sb.Append('\b');
      #0 .. #7,
      #11,
      #14 ..#31:   begin
                     sb.Append('\u');
                     sb.Append(Int32(value[i]).ToString('x4'));
                   end
    else           sb.Append(value[i]);
    end;
  end;

  sb.Append('"');

  exit  (sb.ToString());
end;


class method JSON.ToString(value: Object): String;
begin
  if  (value = nil)       then  exit  ('null');
  if  (value is Boolean)  then  exit  (iif(Boolean(value), 'true', 'false'));
  if  (value is Char)     then  exit  (JSON.QuoteString(new String(Char(value), 1)));
  if  (value is String)   then  exit  (JSON.QuoteString(String(value)));
  if  (value is Int32)    then  exit  (Int32(value).ToString(CultureInfo.InvariantCulture));
  if  (value is Int64)    then  exit  (Int64(value).ToString(CultureInfo.InvariantCulture));

  if  (value is DateTime)  then
    exit  (String.Format('"/Date({0:#})/"', new TimeSpan(DateTime(value).ToUniversalTime().Ticks-(new DateTime(1970, 1, 1)).Ticks).TotalMilliseconds));

  if  (value is Decimal)  then
    value := Convert.ToDouble(Decimal(value));

  if  (value is Double)  then  begin
    var lValue: Double := Double(value);
    
    if  (Double.IsInfinity(lValue))  then
      exit  ('null');

    exit  (lValue.ToString(NumberFormatInfo.InvariantInfo));
  end;

  exit  (nil);
end;


end.