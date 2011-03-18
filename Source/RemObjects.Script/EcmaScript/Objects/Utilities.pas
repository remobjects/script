{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;

type
  PrimitiveType = public enum (None, String, Number);
  Utilities = public static class
  private
  public
    class method ParseDouble(s: String): Double;
    class method UrlEncode(s: String): String;
    class method UrlEncodeComponent(s: String): String;
    class method UrlDecode(s: String): String;
    class method GetArg(arg: Array of object; &index: Integer): Object;
    class method GetArgAsEcmaScriptObject(arg: Array of object; &index: Integer; ec: ExecutionContext): EcmaScriptObject;
    class method GetArgAsInteger(arg: Array of object; &index: Integer; ec: ExecutionContext): Integer;
    class method GetArgAsInt64(arg: Array of object; &index: Integer; ec: ExecutionContext): Int64;
    class method GetArgAsDouble(arg: Array of object; &index: Integer; ec: ExecutionContext): Double;
    class method GetArgAsBoolean(arg: Array of object; &index: Integer; ec: ExecutionContext): Boolean;
    class method GetArgAsString(arg: Array of object; &index: Integer; ec: ExecutionContext): string;
    class method GetObjAsEcmaScriptObject(arg: object; ec: ExecutionContext): EcmaScriptObject;
    class method GetObjAsInteger(arg: object; ec: ExecutionContext): Integer;
    class method GetObjAsInt64(arg: object; ec: ExecutionContext): Int64;
    class method GetObjAsDouble(arg: object; ec: ExecutionContext): Double;
    class method GetObjAsBoolean(arg: Object; ec: ExecutionContext): Boolean;
    class method GetObjAsString(arg: object; ec: ExecutionContext): string;

    class method GetObjectAsPrimitive(ec: ExecutionContext; arg: EcmaScriptObject; aPrimitive: PrimitiveType): Object;

    class var method_GetObjAsBoolean: System.Reflection.MethodInfo := typeof(Utilities).GetMethod('GetObjAsBoolean'); readonly;
    class var Method_GetObjAsString: System.Reflection.MethodInfo := typeof(UtilitieS).GetMethod('GetObjAsString'); readonly;

    class method ToObject(ec: ExecutionContext; o: Object): EcmaScriptObject;
    class method IsPrimitive(arg: Object): Boolean;

    class method IsCallable(o: Object): Boolean;
  end;
implementation
class method Utilities.GetArg(arg: Array of object; &index: Integer): Object;
begin
  if (index < 0) or (index >= arg.Length) Then begin
    result := Undefined.Instance;
  end else 
    result := arg[&index];
end;

class method Utilities.GetArgAsEcmaScriptObject(arg: Array of object; &index: Integer; ec: ExecutionContext): EcmaScriptObject;
begin
  var lValue := GetArg(arg, index);
    result := EcmaScriptObject(lValue);
end;

class method Utilities.GetArgAsInteger(arg: Array of object; &index: Integer; ec: ExecutionContext): Integer;
begin
  var lValue := GetArg(arg, index);
  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := 0;
  end else
    result := GetObjAsInteger(lValue, ec);
end;

class method Utilities.GetArgAsInt64(arg: Array of object; &index: Integer; ec: ExecutionContext): Int64;
begin
    var lValue := GetArg(arg, index);
  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := 0;
  end else 
    result := GetObjAsInt64(lValue, ec);
end;

class method Utilities.GetArgAsDouble(arg: Array of object; &index: Integer; ec: ExecutionContext): Double;
begin
  var lValue := GetArg(arg, index);
  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := 0;
  end else
   result :=  GetObjAsDouble(lValue, ec);
end;

class method Utilities.GetArgAsBoolean(arg: Array of object; &index: Integer; ec: ExecutionContext): Boolean;
begin
    var lValue := GetArg(arg, index);
  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := false;
  end else 
   result := GetObjAsBoolean(lValue, ec);
end;

class method Utilities.GetArgAsString(arg: Array of object; &index: Integer; ec: ExecutionContext): string;
begin
  var lValue := GetArg(arg, index);

  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := nil;
  end else 
    result := GetObjAsString(lValue, ec);
end;
class method Utilities.GetObjAsEcmaScriptObject(arg: object; ec: ExecutionContext): EcmaScriptObject;
begin
    result := EcmaScriptObject(arg);
end;

class method Utilities.GetObjAsInteger(arg: object; ec: ExecutionContext): Integer;
begin
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);
  if (arg = nil) then exit 0;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(boolean(arg), 1, 0);
    TypeCode.Byte: result := byte(arg);
    TypeCode.Char: result := Integer(Char(arg));
    TypeCode.Decimal: result := Integer(Decimal(arg));
    TypeCode.Double: result := IntegeR(Double(arg));
    TypeCode.Int16: result := Int16(arg);
    TypeCode.Int32: result := Int32(arg);
    TypeCode.Int64: result := Int64(arg);
    TypeCode.SByte: result := SByte(arg);
    TypeCode.Single: result := Integer(Single(arg));
    TypeCode.String: begin
       arg := String(arg).Trim();
       if not (if string(arg).StartsWith('0x', StringComparison.InvariantCultureIgnoreCase) then
         Int32.TryParse(string(arg).Substring(2), System.Globalization.NumberStyles.HexNumber, System.Globalization.NumberFormatInfo.InvariantInfo, out result)
       else
          Int32.TryParse(string(arg), out result)) then
        Result := 0;
    end;
    TypeCode.UInt16: result := UInt16(arg);
    TypeCode.UInt32: result := UInt32(arg);
    TypeCode.UInt64: result := UInt64(arg);
    else 
      result := 0;
  end; // case
end;

class method Utilities.GetObjAsInt64(arg: object; ec: ExecutionContext): Int64;
begin
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);
  if (arg = nil)  then exit 0;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(boolean(arg), 1, 0);
    TypeCode.Byte: result := byte(arg);
    TypeCode.Char: result := Integer(Char(arg));
    TypeCode.Decimal: result := Int64(Decimal(arg));
    TypeCode.Double: result := Int64(Double(arg));
    TypeCode.Int16: result := Int16(arg);
    TypeCode.Int32: result := Int32(arg);
    TypeCode.Int64: result := Int64(arg);
    TypeCode.SByte: result := SByte(arg);
    TypeCode.Single: result := Int64(Single(arg));
    TypeCode.String: begin
       arg := String(arg).Trim();
       if not (if string(arg).StartsWith('0x', StringComparison.InvariantCultureIgnoreCase) then
         Int64.TryParse(string(arg).Substring(2), System.Globalization.NumberStyles.HexNumber, System.Globalization.NumberFormatInfo.InvariantInfo, out result)
       else
          Int64.TryParse(string(arg), out result)) then
        Result := 0;
    end;
    TypeCode.UInt16: result := UInt16(arg);
    TypeCode.UInt32: result := UInt32(arg);
    TypeCode.UInt64: result := UInt64(arg);
    else 
      result := 0;
  end; // case
end;

class method Utilities.GetObjAsDouble(arg: object; ec: ExecutionContext): Double;
begin
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);

  if (arg = nil)  then exit 0;
  if arg = Undefined.Instance then exit Double.NaN;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(boolean(arg), 1, 0);
    TypeCode.Byte: result := byte(arg);
    TypeCode.Char: result := Integer(Char(arg));
    TypeCode.Decimal: result := Double(Decimal(arg));
    TypeCode.Double: result := Double(arg);
    TypeCode.Int16: result := Int16(arg);
    TypeCode.Int32: result := Int32(arg);
    TypeCode.Int64: result := Int64(arg);
    TypeCode.SByte: result := SByte(arg);
    TypeCode.Single: result := Single(arg);
    TypeCode.String: begin
       result := ParseDouble(String(arg).Trim());
    end;
    TypeCode.UInt16: result := UInt16(arg);
    TypeCode.UInt32: result := UInt32(arg);
    TypeCode.UInt64: result := UInt64(arg);
    else 
      result := 0;
  end; // case
end;

class method Utilities.GetObjAsBoolean(arg: Object; ec: ExecutionContext): Boolean;
begin
  if arg is EcmaScriptObject then exit true;
  
  if (arg = nil) or (arg = Undefined.Instance)  then exit false;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := boolean(arg);
    TypeCode.Byte: result := byte(arg) <> 0;
    TypeCode.Char: result := Char(arg) <> #0;
    TypeCode.Decimal: result := Decimal(arg) <> 0;
    TypeCode.Double: result := if not Double.IsNaN(Double(arg)) then Double(arg) <> 0 else false;
    TypeCode.Int16: result := Int16(arg) <> 0;
    TypeCode.Int32: result := Int32(arg) <> 0;
    TypeCode.Int64: result := Int64(arg) <> 0;
    TypeCode.SByte: result := SByte(arg) <> 0;
    TypeCode.Single: result := Single(arg)  <> 0;
    TypeCode.String: result := string(arg) <> '';
    TypeCode.UInt16: result := UInt16(arg) <> 0;
    TypeCode.UInt32: result := UInt32(arg) <> 0;
    TypeCode.UInt64: result := UInt64(arg) <> 0;
    else 
      result := false;
  end; // case
end;

class method Utilities.GetObjAsString(arg: object; ec: ExecutionContext): string;
begin
  var lOrg := arg;
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.String);
  if arg = Undefined.Instance then exit 'undefined';
  if arg = nil then exit 'null';
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(boolean(arg), 'true', 'false');
    TypeCode.Byte: result := byte(arg).ToString;
    TypeCode.Char: result := Char(arg).ToString;
    TypeCode.Decimal: result := Decimal(arg).ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
    TypeCode.Double: result := Double(arg).ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
    TypeCode.Int16: result := Int16(arg).ToString;
    TypeCode.Int32: result := Int32(arg).ToString;
    TypeCode.Int64: result := Int64(arg).ToString;
    TypeCode.SByte: result := SByte(arg).ToString;
    TypeCode.Single: result := Single(arg).ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
    TypeCode.String: result := arg.ToString;
    TypeCode.UInt16: result := UInt16(arg).ToString;
    TypeCode.UInt32: result := UInt32(arg).ToString;
    TypeCode.UInt64: result := UInt64(arg).ToString;
    else 
      result := nil;
  end; // case
end;


class method Utilities.IsCallable(o: Object): Boolean;
begin
  result := (o is &MulticastDelegate);
  if result and (o is EcmaScriptObject) then
    result := result and (o is EcmaScriptBaseFunctionObject);
end;


class method Utilities.UrlEncode(s: String): String;
begin
  if String.IsNullOrEmpty(s) then exit String.Empty;
  var bytes := Encoding.UTF8.GetBytes(s);
  var res := new StringBuilder;
  for i: Integer := 0 to bytes.Length -1 do begin
    case bytes[i] of
      byte('A')..Byte('Z'), Byte('?'), Byte(':'), Byte('@'), Byte('&'), Byte('='), Byte('+'), Byte('$'), Byte(','),
      byte('a')..Byte('z'),
      byte('0')..Byte('9'),
      byte('.'), byte('_'), byte('-'), byte('~'):
        res.Append(char(bytes[i]));
    else
      res.Append('%');
      res.Append(((bytes[i] shr 4) and 15).ToString('X'));
      res.Append(((bytes[i]) and 15).ToString('X'));
    end; // case
  end;
  exit res.ToString;
end;

class method Utilities.UrlDecode(s: String): String;
begin
  if String.IsNullOrEmpty(s) then exit String.Empty;
  var ms := new System.IO.MemoryStream(s.Length);
  var i:= 0;
  while i < s.Length do begin
    if s[i] = '+' then begin
      ms.WriteByte(32);
      inc(i);
    end else
    if (s[i] = '%') and (i +2 < s.Length) then begin
       var b: Byte;
       if byte.TryParse(s[i+1]+s[i+2], System.Globalization.NumberStyles.HexNumber, System.Globalization.NumberFormatInfo.InvariantInfo, out b) then
         ms.Writebyte(b);
       inc(i, 3);
    end else begin
      ms.WriteByte(byte(s[i]));
      inc(i);
    end;
  end;
  exit Encoding.UTF8.GetString(ms.GetBuffer, 0, ms.Length);
end;


class method Utilities.UrlEncodeComponent(s: String): String;
begin
if String.IsNullOrEmpty(s) then exit String.Empty;
  var bytes := Encoding.UTF8.GetBytes(s);
  var res := new StringBuilder;
  for i: Integer := 0 to bytes.Length -1 do begin
    case bytes[i] of

      Byte(';'), Byte('/'), 
      byte('A')..Byte('Z'),
      byte('a')..Byte('z'),
      byte('0')..Byte('9'),
      byte('.'), byte('_'), byte('-'), byte('~'):
        res.Append(char(bytes[i]));
    else
      res.Append('%');
      res.Append(((bytes[i] shr 4) and 15).ToString('X'));
      res.Append(((bytes[i]) and 15).ToString('X'));
    end; // case
  end;
  exit res.ToString;
end;

class method Utilities.ToObject(ec: ExecutionContext; o: Object): EcmaScriptObject;
begin
  result := EcmaScriptObject(o);
  if result <> nil then exit;
  if o is Boolean then exit ec.Global.BooleanCtor(ec, nil, [o]) as EcmaScriptObject;
  if o is String then exit ec.Global.StringCtor(ec, nil, [o]) as EcmaScriptObject;
  if (o is Int32) or (o is Double) then exit ec.Global.NumberCtor(ec, nil, [o]) as EcmaScriptObject;
  ec.Global.RaiseNativeError(NativeErrorType.TypeError, 'Object expected');
end;

class method Utilities.GetObjectAsPrimitive(ec: ExecutionContext; arg: EcmaScriptObject; aPrimitive: PrimitiveType): Object;
begin
  if aPrimitive = PrimitiveType.None then
    aPrimitive := if arg.Class = 'Date' then PrimitiveType.String else PrimitiveType.Number;
  if aPrimitive = PrimitiveType.String then begin
    var func := EcmaScriptBaseFunctionObject(arg.Get('toString'));
    if func <> nil then begin
      result := func.CallEx(ec, arg, []);
      if IsPrimitive(result) then exit;
    end;
    func := EcmaScriptBaseFunctionObject(arg.Get('valueOf'));
    if func <> nil then begin
      result := func.CallEx(ec, arg, []);
      if IsPrimitive(result) then exit;
    end;
  end else begin
    var func := EcmaScriptBaseFunctionObject(arg.Get('valueOf'));
    if func <> nil then begin
      result := func.CallEx(ec, arg, []);
      if IsPrimitive(result) then exit;
    end;
    func := EcmaScriptBaseFunctionObject(arg.Get('toString'));
    if func <> nil then begin
      result := func.CallEx(ec, arg, []);
      if IsPrimitive(result) then exit;
    end;
  end;
  ec.Global.RaiseNativeError(NativeErrorType.TypeError, 'toString/valueOf does not return a value primitive value');
end;

class method Utilities.IsPrimitive(arg: Object): Boolean;
begin
  if (arg = nil) or (arg = Undefined.Instance) then exit true;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean,
    TypeCode.Byte,
    TypeCode.Char,
    TypeCode.Decimal,
    TypeCode.Double,
    TypeCode.Int16,
    TypeCode.Int32,
    TypeCode.Int64,
    TypeCode.SByte,
    TypeCode.Single,
    TypeCode.String,
    TypeCode.UInt16,
    TypeCode.UInt32,
    TypeCode.UInt64: exit true;
  end; // case
  exit false;
end;

class method Utilities.ParseDouble(s: String): Double;
var 
  lNegative: Boolean := false;
begin
  if s.StartsWith('+') then begin
    s := s.Substring(1);
  end else if s.StartsWith('-') then begin
    s := s.Substring(1);
    lNegative := true;
  end;
  if String.Compare(s, 'Infinity', StringComparison.InvariantCultureIgnoreCase) =0 then begin
    if lNegative then 
      exit Double.NegativeInfinity
    else
      exit Double.PositiveInfinity;
  end;
  var lExp := s.IndexOfAny(['e','E']);
  if lExp <> -1 then begin
    var lTmp := s.Substring(lExp+1);
    s:= s.Substring(0, lExp);
    if not Int32.TryParse(lTmp, out lExp) then
      exit Double.NaN;
  end else
    lExp := 0;
    
  if not Double.TryParse(s, System.Globalization.NumberStyles.Float, System.Globalization.NumberFormatInfo.InvariantInfo, out Result) then exit Double.NaN;

  
  var lIncVal: Double;
  if lExp < 0 then  begin
    lIncVal := 0.1;
    lExp := -lExp;
  end else 
    lIncVal := 10.0;
  while lExp > 0 do begin
    result := result * lIncVal;
    dec(lExp);
  end;
  if lNegative then
    result := -result;
end;



end.