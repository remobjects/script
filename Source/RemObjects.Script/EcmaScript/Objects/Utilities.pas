{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Globalization,
  System.Text,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;


type
  PrimitiveType = public enum (None, String, Number);
  Utilities = public static class
  private
    const EPSILON: Double = 0.00000000001;
    const PRECISION: Int32 = 18;

    class method DoubleToString(value: Double): String;
    class method AllZeroesAhead(arr: array of Char; i: Int32): Boolean;
  public
    class var fEncoding : Encoding := new UTF8Encoding(false, true); readonly;
    class method ParseDouble(s: String;  allowHex: Boolean := true): Double;
    class method UrlEncode(s: String): String;
    class method UrlEncodeComponent(s: String): String;
    class method UrlDecode(s: String; aComponent: Boolean): String;
    class method GetArg(arg: Array of Object; &index: Integer): Object;
    class method GetArgAsEcmaScriptObject(arg: Array of Object; &index: Integer; ec: ExecutionContext): EcmaScriptObject;
    class method GetArgAsInteger(arg: Array of Object; &index: Integer; ec: ExecutionContext; aTreatInfinity: Boolean := false): Integer;
    class method GetArgAsInt64(arg: Array of Object; &index: Integer; ec: ExecutionContext): Int64;
    class method GetArgAsDouble(arg: Array of Object; &index: Integer; ec: ExecutionContext): Double;
    class method GetArgAsBoolean(arg: Array of Object; &index: Integer; ec: ExecutionContext): Boolean;
    class method GetArgAsString(arg: Array of Object; &index: Integer; ec: ExecutionContext): String;
    class method GetObjAsEcmaScriptObject(arg: Object; ec: ExecutionContext): EcmaScriptObject;
    class method GetObjAsInteger(arg: Object; ec: ExecutionContext; aTreatInfinity: Boolean := false): Integer;
    class method GetObjAsCardinal(arg: Object; ec: ExecutionContext): Cardinal;
    class method GetObjAsInt64(arg: Object; ec: ExecutionContext): Int64;
    class method GetObjAsDouble(arg: Object; ec: ExecutionContext): Double;
    class method GetObjAsBoolean(arg: Object; ec: ExecutionContext): Boolean;
    class method GetObjAsString(arg: Object; ec: ExecutionContext): String;

    class method GetObjectAsPrimitive(ec: ExecutionContext; arg: EcmaScriptObject; aPrimitive: PrimitiveType): Object;

    class var method_GetObjAsBoolean: System.Reflection.MethodInfo := typeOf(Utilities).GetMethod('GetObjAsBoolean'); readonly;
    class var Method_GetObjAsString: System.Reflection.MethodInfo := typeOf(Utilities).GetMethod('GetObjAsString'); readonly;

    class method ToObject(ec: ExecutionContext; o: Object): EcmaScriptObject;
    class method IsPrimitive(arg: Object): Boolean;

    class method IsCallable(o: Object): Boolean;
  end;
implementation
class method Utilities.GetArg(arg: Array of Object; &index: Integer): Object;
begin
  if (index < 0) or (index >= arg.Length) Then begin
    result := Undefined.Instance;
  end else 
    result := arg[&index];
end;

class method Utilities.GetArgAsEcmaScriptObject(arg: Array of Object; &index: Integer; ec: ExecutionContext): EcmaScriptObject;
begin
  var lValue := GetArg(arg, index);
    result := EcmaScriptObject(lValue);
end;

class method Utilities.GetArgAsInteger(arg: Array of Object; &index: Integer; ec: ExecutionContext; aTreatInfinity: Boolean := false): Integer;
begin
  var lValue := GetArg(arg, index);
  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := 0;
  end else
    result := GetObjAsInteger(lValue, ec, aTreatInfinity);
end;

class method Utilities.GetArgAsInt64(arg: Array of Object; &index: Integer; ec: ExecutionContext): Int64;
begin
    var lValue := GetArg(arg, index);
  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := 0;
  end else 
    result := GetObjAsInt64(lValue, ec);
end;

class method Utilities.GetArgAsDouble(arg: Array of Object; &index: Integer; ec: ExecutionContext): Double;
begin
  var lValue := GetArg(arg, index);
 result :=  GetObjAsDouble(lValue, ec);
end;

class method Utilities.GetArgAsBoolean(arg: Array of Object; &index: Integer; ec: ExecutionContext): Boolean;
begin
    var lValue := GetArg(arg, index);
  if (lValue = nil) or (lValue = Undefined.Instance) then begin
    result := false;
  end else 
   result := GetObjAsBoolean(lValue, ec);
end;

class method Utilities.GetArgAsString(arg: Array of Object; &index: Integer; ec: ExecutionContext): String;
begin
  var lValue := GetArg(arg, index);

  result := GetObjAsString(lValue, ec);
end;
class method Utilities.GetObjAsEcmaScriptObject(arg: Object; ec: ExecutionContext): EcmaScriptObject;
begin
    result := EcmaScriptObject(arg);
end;

class method Utilities.GetObjAsInteger(arg: Object; ec: ExecutionContext; aTreatInfinity: Boolean := false): Integer;
begin
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);
  if (arg = nil) then exit 0;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(Boolean(arg), 1, 0);
    TypeCode.Byte: result := Byte(arg);
    TypeCode.Char: result := Integer(Char(arg));
    TypeCode.Decimal: result := Integer(Decimal(arg));
    TypeCode.Double: begin
      var lVal := Double(arg);
      if aTreatInfinity then begin
        if Double.IsPositiveInfinity(lVal) then exit Int32.MaxValue;
        if Double.IsNegativeInfinity(lVal) then exit Int32.MinValue;
      end;
      if Double.IsNaN(lVal) or (Double.IsInfinity(lVal)) then 
        exit 0;
      result := Integer(Cardinal(Math.Sign(lVal) * Math.Floor(Math.Abs(lVal))));
    end;
    TypeCode.Int16: result := Int16(arg);
    TypeCode.Int32: result := Int32(arg);
    TypeCode.Int64: result := Int64(arg);
    TypeCode.SByte: result := SByte(arg);
    TypeCode.Single: result := Integer(Single(arg));
    TypeCode.String: begin
       arg := String(arg).Trim();
       if not (if String(arg).StartsWith('0x', StringComparison.InvariantCultureIgnoreCase) then
         Int32.TryParse(String(arg).Substring(2), System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out result)
       else
          Int32.TryParse(String(arg), out result)) then begin
        var lWork: Double := Utilities.ParseDouble(String(arg));
        if Double.IsNaN(lWork) then result := 0
        else
          result := Integer(Cardinal(Math.Sign(lWork) * Math.Floor(Math.Abs(lWork))));
      end;
    end;
    TypeCode.UInt16: result := UInt16(arg);
    TypeCode.UInt32: result := UInt32(arg);
    TypeCode.UInt64: result := UInt64(arg);
    else 
      result := 0;
  end; // case
end;

class method Utilities.GetObjAsInt64(arg: Object; ec: ExecutionContext): Int64;
begin
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);
  if (arg = nil)  then exit 0;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(Boolean(arg), 1, 0);
    TypeCode.Byte: result := Byte(arg);
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
       if not (if String(arg).StartsWith('0x', StringComparison.InvariantCultureIgnoreCase) then
         Int64.TryParse(String(arg).Substring(2), System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out result)
       else
          Int64.TryParse(String(arg), out result)) then
        Result := 0;
    end;
    TypeCode.UInt16: result := UInt16(arg);
    TypeCode.UInt32: result := UInt32(arg);
    TypeCode.UInt64: result := UInt64(arg);
    else 
      result := 0;
  end; // case
end;

class method Utilities.GetObjAsDouble(arg: Object; ec: ExecutionContext): Double;
begin
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);

  if (arg = nil)  then exit 0;
  if arg = Undefined.Instance then exit Double.NaN;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(Boolean(arg), 1, 0);
    TypeCode.Byte: result := Byte(arg);
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
  //if (arg is EcmaScriptObject)and (EcmaScriptObject(arg).Class = 'Boolean') then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);
  if (arg is EcmaScriptObject) then exit true;
  
  if (arg = nil) or (arg = Undefined.Instance)  then exit false;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := Boolean(arg);
    TypeCode.Byte: result := Byte(arg) <> 0;
    TypeCode.Char: result := Char(arg) <> #0;
    TypeCode.Decimal: result := Decimal(arg) <> 0;
    TypeCode.Double: result := if not Double.IsNaN(Double(arg)) then Double(arg) <> 0 else false;
    TypeCode.Int16: result := Int16(arg) <> 0;
    TypeCode.Int32: result := Int32(arg) <> 0;
    TypeCode.Int64: result := Int64(arg) <> 0;
    TypeCode.SByte: result := SByte(arg) <> 0;
    TypeCode.Single: result := Single(arg)  <> 0;
    TypeCode.String: result := String(arg) <> '';
    TypeCode.UInt16: result := UInt16(arg) <> 0;
    TypeCode.UInt32: result := UInt32(arg) <> 0;
    TypeCode.UInt64: result := UInt64(arg) <> 0;
    else 
      result := false;
  end; // case
end;

class method Utilities.GetObjAsString(arg: Object; ec: ExecutionContext): String;
begin
  var lOrg := arg;
  if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.String);
  if arg = Undefined.Instance then exit 'undefined';
  if arg = nil then exit 'null';
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(Boolean(arg), 'true', 'false');
    TypeCode.Byte: result := Byte(arg).ToString;
    TypeCode.Char: result := Char(arg).ToString;
    TypeCode.Decimal: result := Decimal(arg).ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
    TypeCode.Double: begin
      result := DoubleToString(Double(arg));
    end;
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
  var bytes := fEncoding.GetBytes(s);
  var res := new StringBuilder;
  for i: Integer := 0 to bytes.Length -1 do begin
    case bytes[i] of
      Byte('A')..Byte('Z'), Byte(';'), Byte('/'), Byte('?'), Byte(':'), Byte('@'), Byte('&'), Byte('='), Byte('+'), Byte('$'), Byte(','),
      Byte('-'), Byte('_'), Byte('.'), Byte('!'), Byte('~'), Byte('*'), Byte(''''), Byte('('), Byte(')'), 
      Byte('a')..Byte('z'), Byte('#'),
      Byte('0')..Byte('9'):
        res.Append(Char(bytes[i]));
    else
      res.Append('%');
      res.Append(((bytes[i] shr 4) and 15).ToString('X'));
      res.Append(((bytes[i]) and 15).ToString('X'));
    end; // case
  end;
  exit res.ToString;
end;

class method Utilities.UrlDecode(s: String; aComponent: Boolean): String;
begin
  if String.IsNullOrEmpty(s) then exit String.Empty;
  var ms := new StringBuilder;
  var i:= 0;
  while i < s.Length do begin
    //if not aComponent and (s[i] = '+') then begin
    //  ms.Append(#32);
    //  inc(i);
    //end else
    if (s[i] = '%') then begin
       if not (i +2 < s.Length)  then exit nil;
       var b: Byte;
       if 
       (s[i+1] <> #0) and (s[i+2] <> #0) and 
       Byte.TryParse(s[i+1]+s[i+2], System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out b) then begin
         if not aComponent and(b in [$3b, $2f, $3f, $3a, $40, $26, $3d, $2b, $24, $2c, $23]) then begin
          ms.Append(Char('%'));
          ms.Append(s[i+1]);
          ms.Append(s[i+2]);
          inc(i, 3);
         end else begin
           inc(i, 3);
           if 0 = (b and $80) then 
             ms.Append(Char(b))
           else begin
             // 4.d.vii.1
             var n: Integer := 0;
             if 0 = (b and $40) then exit nil else
             if 0 = (b and $20) then n := 2 else
             if 0 = (b and $10) then n := 3 else
             if 0 = (b and $8) then n := 4 else
             exit nil;
             if i + (3 * (n -1)) > s.Length then exit nil;
             var Octets := new Byte[n];
             Octets[0] := b;
             for j: Integer := 1 to n -1 do begin
              if s[i] <> '%' then exit nil;
              if (s[i+1] not in ['0'..'9', 'A'..'F', 'a'..'f']) or
                (s[i+2] not in ['0'..'9', 'A'..'F', 'a'..'f']) then exit nil;
              if not Byte.TryParse(s[i+1]+s[i+2], System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out b)  then exit nil;
              if $80 <> (b and $c0) then exit nil;
              Octets[j] := b;
              inc(i, 3);
             end;
            var w: Integer := 
            case n of 
              2: Int32((Octets[0] and %00011111) shl 6) or (Octets[1] and %00111111);
              3: Int32((Octets[0] and %00001111) shl 12) or ((Octets[1] and %00111111) shl 6) or (Octets[2] and %00111111);
              4: Int32((Octets[0] and %00000111) shl 18) or ((Octets[1] and %00111111) shl 12) or ((Octets[2] and %00111111) shl 6) or (Octets[3] and %00111111);
            else
              0
            end; // case
            if (w = 0) or (w < $80) 
            or ((w < $800) and (n <> 2)) or
              ((w >= $800) and (w < $10000) and (n <> 3)) or
              ((w >= $10000) and (w < $110000) and (n <> 4))
            then exit nil;
            if w in [$D800 .. $DFFF] then exit nil;
            if w <= $FFFF then
              ms.Append(Char(w))
            else begin
              w := w - $10000; // reencode to utf16
              ms.Append(Char($D800 + (w shr 10)));
              ms.Append(Char($DC00 + (w and $3ff)));
            end;
            (*
              From RFC 3629
              Char. number range  |        UTF-8 octet sequence
                  (hexadecimal)    |              (binary)
               --------------------+---------------------------------------------
               0000 0000-0000 007F | 0xxxxxxx
               0000 0080-0000 07FF | 110xxxxx 10xxxxxx
               0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
               0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx


               Implementations of the decoding algorithm above MUST protect against
               decoding invalid sequences.  For instance, a naive implementation may
               decode the overlong UTF-8 sequence C0 80 into the character U+0000,
               or the surrogate pair ED A1 8C ED BE B4 into U+233B4.  Decoding
               invalid sequences may have security consequences or cause other
               problems.  See Security Considerations (Section 10) below.

            *)

           end;
          end;
        end else
          exit nil;
    end else begin
      ms.Append(s[i]);
      inc(i);
    end;
  end;

  exit ms.ToString;
end;


class method Utilities.UrlEncodeComponent(s: String): String;
begin
if String.IsNullOrEmpty(s) then exit String.Empty;
  var bytes := fEncoding.GetBytes(s);
  var res := new StringBuilder;
  for i: Integer := 0 to bytes.Length -1 do begin
    case bytes[i] of
      Byte('A')..Byte('Z'),
      Byte('a')..Byte('z'),
      Byte('0')..Byte('9'),
      Byte('!'), Byte('~'), Byte('*'), Byte(''''), Byte('('), Byte(')'), 
      Byte('.'), Byte('_'), Byte('-'):
        res.Append(Char(bytes[i]));
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

class method Utilities.ParseDouble(s: String; allowHex: Boolean := true): Double;
var 
  lNegative: Boolean := false;
begin
  if s.StartsWith('+') then begin
    s := s.Substring(1);
  end else if s.StartsWith('-') then begin
    s := s.Substring(1);
    lNegative := true;
  end;
  if  s.StartsWith('Infinity', StringComparison.InvariantCulture) then begin
    if lNegative then 
      exit Double.NegativeInfinity
    else
      exit Double.PositiveInfinity;
  end;
  if allowHex and s.StartsWith('0x', StringComparison.InvariantCultureIgnoreCase) then begin
    var v: Int64;
    if Int64.TryParse(s.Substring(2), System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out v) then
      exit v;
  end;

  var lcleaned := false;
  var lp := s.Length;
  s := s.Trim();
  if s.Length <> lp then begin
    lcleaned := true;
    lp := s.Length;
  end;
  if not allowHex then
  for j: Integer := s.Length -1 downto 0 do begin
    if s[j] not in ['0'..'9','.', 'e', 'E', '+', '-'] then begin
      lp := j;
    end else if (s[j] in ['+', '-']) and (j > 0) and (s[j-1] not in ['e', 'E']) then
      lp := j
    else if (s[j] in ['e', 'E']) and (s.IndexOfAny(['e', 'E']) <> j) then
      lp := j;
  end;
  if (s.IndexOf('.') <> s.LastIndexOf('.')) and (s.LastIndexOf('.') < lp) then
    lp := s.LastIndexOf('.');
  if lp <> s.Length then begin
    s := s.Substring(0, lp);
    lcleaned := true;
  end;
  var lExp := s.IndexOfAny(['e','E']);
  if lExp <> -1 then begin
    var lTmp := s.Substring(lExp+1);
    s:= s.Substring(0, lExp);
    if (lTmp = '') or (lTmp = '+') or (lTmp = '-') then lExp := 0 else 
    if not Int32.TryParse(lTmp, out lExp) then
      exit Double.NaN;
  end else
    lExp := 0;
  if s = '' then  begin
    if lcleaned or not allowHex then exit Double.NaN;
    if lNegative then exit - 0 else exit 0;
  end;

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


class method Utilities.DoubleToString(value: Double): String;

  method SplitNumberToCharArray(value: Int64): array of Char;
  begin
    if  (value = 0)  then
      exit  ([ '0' ]);

    var buffer: StringBuilder := new StringBuilder(32);
    while  (value > 0)  do  begin
      buffer.Append(Byte(value mod 10));
      value := value div 10;
    end;

    var lReversedResult: array of Char := buffer.ToString().ToCharArray();
    var lBufferLength: Int32 := length(lReversedResult);
    var lResult: array of Char := new Char[lBufferLength];

    for  I: Int32  :=  0  to  (lBufferLength-1)  do
      lResult[I] := lReversedResult[lBufferLength-1-I];

    exit  (lResult);
  end;

begin
  // Border cases
  if  (Double.IsNaN(value))  then
    exit  ('NaN');

  if  ((value >= -EPSILON)  and  (value <= EPSILON))  then
    exit  ('0');

  if  (Double.IsNegativeInfinity(value))  then
    exit  ('-Infinity');

  if  (Double.IsPositiveInfinity(value))  then
    exit  ('Infinity');

  var lResult: StringBuilder := new StringBuilder(128);
  if  (value < 0)  then  begin
    value := -value;
    lResult.Append('-');
  end;

  // At this point we know that value > EPSILON
  // Specification step 5. Determine n, k and s
  var lRoundedValueLog10: Int32 := Convert.ToInt32(Math.Floor(Math.Log10(value)))+1;
  var n_k: Int32 := 0; // this is value of (n-k)

  // Integer part
  // First thing is to double-check for overflow
  var s_temp: Double := value;
  var lIntegertPartPower: Int32 := lRoundedValueLog10;
  if  (lIntegertPartPower >= PRECISION)  then  begin
    for  I: Int32  :=  1  to  lIntegertPartPower-PRECISION-1  do  begin
      s_temp := s_temp / 10;
      inc(n_k);
    end;
    s_temp := Math.Round(s_temp);
  end;

  // Let's check is s divisible by 10 or not
  var s: Int64 := Convert.ToInt64(s_temp);
  if  (lIntegertPartPower > 0)  then
    while  (s mod 10 = 0)  do  begin
      s := s div 10;
      inc(n_k);
    end;

  // Now we know s
  // Next step is to determine its length
  var s_length: Int32 := Math.Max(0,lRoundedValueLog10 + n_k);

  // Check if there is any place for floating point part
  if  (s_length < 19)  then  begin
    // Optimization
    // Cut the border for really small numbers
    if  (value < 1.0)  then  begin
      n_k := 0;
      var lFractionalPower: Int32 := Convert.ToInt32(Math.Floor(Math.Log10(value)))+1;
      for  I: Int32  :=  -1  downto  lFractionalPower  do  begin
        s_temp := s_temp * 10.0;
        dec(n_k);
      end;
    end;

    var s_double: Double := Math.Floor(value);
    var n_k_fractional: Int32 := 0;
    var lIsFractionalPartPresent: Boolean := false;

    var multiplier: Int64 := 10;
    while  ((Math.Abs(s_temp - s_double) > EPSILON)  and  (s_length < 19-1))  do  begin
      s_temp := value*multiplier;
      multiplier := multiplier*10;
      s_double := Math.Floor(s_temp+EPSILON);
      lIsFractionalPartPresent := true;
      dec(n_k_fractional);
      inc(s_length);
    end;

    if  (lIsFractionalPartPresent)  then  begin
      n_k := n_k_fractional;
      s := Convert.ToInt64(s_double);
      if  (Math.Abs(s_temp - s_double) >= 0.5)  then
        inc(s);
    end;
  end;

  // so we know values for s and (n-k)
  // let's think about k
  // we split s into chars so we'll immediately know both k and String representation of this number

  var s_char_array: array of Char := SplitNumberToCharArray(s);

  var k: Int32 := length(s_char_array);
  var n: Int32 := n_k + k;


  // At this point s, n & k are known

  // Specification step 6. Result
  if  ((k <= n)  and  (n <= 21))  then  begin
    for  I: Int32  :=  0  to  k-1  do
      lResult.Append(s_char_array[I]);

    for  I: Int32  :=  0  to  n_k-1  do
      lResult.Append('0');

    exit  (lResult.ToString());
  end;


  // Specification step 7. Result
  if  ((0 < n)  and  (n <= 21))  then  begin
    for  I: Int32  :=  0  to  n-1  do
      lResult.Append(s_char_array[I]);
    lResult.Append('.');
    for  I: Int32  :=  n  to  k-1  do begin
      if AllZeroesAhead(s_char_array, I) then break;
      lResult.Append(s_char_array[I]);
    end;

    exit  (lResult.ToString());
  end;

  // Specification step 8. Result
  if  ((-6 < n)  and  (n <= 0))  then  begin
    lResult.Append('0');
    lResult.Append('.');
    for  I: Int32  :=  0  to  -n-1  do
      lResult.Append('0');
    for  I: Int32  :=  0  to  k-1  do begin
      if AllZeroesAhead(s_char_array, I) then break;
      lResult.Append(s_char_array[I]);
    end;

    exit  (lResult.ToString());
  end;

  // Specification step 9. Result
  if  (k=1)  then  begin
    lResult.Append(s_char_array[0]);
    lResult.Append('e');
    lResult.Append(iif(n-1>0,'+','-'));
    lResult.Append(Math.Abs(n-1).ToString(CultureInfo.InvariantCulture));

    exit  (lResult.ToString());
  end;

  // Specification step 10. Result
  lResult.Append(s_char_array[0]);
  lResult.Append('.');
  for  I: Int32  :=  1  to  k-1  do begin
    if AllZeroesAhead(s_char_array, I) then break;
    lResult.Append(s_char_array[I]);
  end;
  lResult.Append('e');
  lResult.Append(iif(n-1>0,'+','-'));
  lResult.Append(Math.Abs(n-1).ToString(CultureInfo.InvariantCulture));

  exit  (lResult.ToString());
end;


class method Utilities.AllZeroesAhead(arr: array of Char; i: Int32): Boolean;
begin
  for n: Integer := i to length(arr) -1 do
    if arr[n] <> '0' then exit false;
  exit true;
end;

class method Utilities.GetObjAsCardinal(arg: Object; ec: ExecutionContext): Cardinal;
begin
    if arg is EcmaScriptObject then arg := GetObjectAsPrimitive(ec, EcmaScriptObject(arg), PrimitiveType.Number);
  if (arg = nil) then exit 0;
  case &Type.GetTypeCode(arg.GetType) of
    TypeCode.Boolean: Result := iif(Boolean(arg), 1, 0);
    TypeCode.Byte: result := Byte(arg);
    TypeCode.Char: result := Integer(Char(arg));
    TypeCode.Decimal: result := Integer(Decimal(arg));
    TypeCode.Double: begin
      var lVal := Double(arg);
      if Double.IsNaN(lVal) or (Double.IsInfinity(lVal)) then 
        exit 0;
      result := Integer(Cardinal(Math.Sign(lVal) * Math.Floor(Math.Abs(lVal))));
    end;
    TypeCode.Int16: result := Int16(arg);
    TypeCode.Int32: result := Int32(arg);
    TypeCode.Int64: result := Int64(arg);
    TypeCode.SByte: result := SByte(arg);
    TypeCode.Single: result := Integer(Single(arg));
    TypeCode.String: begin
       arg := String(arg).Trim();
       if not (if String(arg).StartsWith('0x', StringComparison.InvariantCultureIgnoreCase) then
         UInt32.TryParse(String(arg).Substring(2), System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out result)
       else
          UInt32.TryParse(String(arg), out result)) then begin
        var lWork: Double := Utilities.ParseDouble(String(arg));
        if Double.IsNaN(lWork) then result := 0
        else
          result := Integer(Cardinal(Math.Sign(lWork) * Math.Floor(Math.Abs(lWork))));
      end;
    end;
    TypeCode.UInt16: result := UInt16(arg);
    TypeCode.UInt32: result := UInt32(arg);
    TypeCode.UInt64: result := UInt64(arg);
    else 
      result := 0;
  end; // case
end;

end.