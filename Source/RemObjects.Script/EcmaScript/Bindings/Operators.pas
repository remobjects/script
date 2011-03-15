namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Text,
  System.Runtime.CompilerServices,
  RemObjects.Script;
type
  Operators = public partial class
  private
    class method DoubleCompare(aLeft, aRight: Double): Boolean;
  protected
  public
    
    class method SameValue(aLeft, aright: Object): Boolean;


    class method Equal(aLeft, aRight: Object): Object;
    class method NotEqual(aLeft, aRight: Object): Object;
    class method StrictEqual(aLeft, aRight: Object): Object;
    class method StrictNotEqual(aLeft, aRight: Object): Object;
    class method _TypeOf(aValue: Object): String;

    // OR, AND, ?: have side effects in evaluation and are not specified here.
    class var Method_SameValue: System.Reflection.MethodInfo := typeof(Operators).GetMethod('SameValue');
    class var Method_Equal: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Equal');
    class var Method_NotEqual: System.Reflection.MethodInfo := typeof(Operators).GetMethod('NotEqual');
    class var Method_StrictEqual: System.Reflection.MethodInfo := typeof(Operators).GetMethod('StrictEqual');
    class var Method_StrictNotEqual: System.Reflection.MethodInfo := typeof(Operators).GetMethod('StrictNotEqual');
    class var Method_TypeOf: System.Reflection.MethodInfo := typeof(Operators).GetMethod('_TypeOf');
  end;

implementation

class method Operators.Equal(aLeft, aRight: Object): Object;
begin
  var lLeft: TypeCode := iif(aLeft = nil, TypeCode.Empty, &Type.GetTypeCode(aLeft.GetType));
  var lRight: TypeCode := iif(aRight = nil, TypeCode.Empty, &Type.GetTypeCode(aRight.GetType));
  if lLeft = TypeCode.Empty then begin
    case lRight of 
      TypeCode.Empty: exit true;
      TypeCode.Boolean: exit not Boolean(aRight);
      TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64: exit Convert.ToInt64(aRight) = 0;
      TypeCode.Single: exit Single(aRight) = 0;
      TypeCode.Double: exit  Double(aRight) = 0;
      TypeCode.String: result := string(aRight) = '';
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64: result := Convert.ToUInt64(aRight) = 0;
    else exit false;
    end; // case
  end else if lRight = TypeCode.Empty then begin
    case lLeft of 
      TypeCode.Empty: exit true;
      TypeCode.Boolean: exit not Boolean(aLeft);
      TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64: exit Convert.ToInt64(aLeft) = 0;
      TypeCode.Single: exit Single(aLeft) = 0;
      TypeCode.Double: exit  Double(aLeft) = 0;
      TypeCode.String: result := string(aLeft) = '';
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64: result := Convert.ToUInt64(aLeft) = 0;
    else exit false;
    end; // case
  end;
  if (aLeft is EcmaScriptObject) <> (aRight is EcmaScriptObject) then begin
    if EcmaScriptObject(aLeft):Value <> nil then begin
      aLeft := EcmaScriptObject(aLeft):Value;
      lLeft := &Type.GetTypeCode(aLeft.GetType);
    end;
    if EcmaScriptObject(aRight):Value <> nil then begin
      aRight := EcmaScriptObject(aRight):Value;
      lRight := &Type.GetTypeCode(aRight.GetType);
    end;
  end;

  if (lLeft = TypeCode.String) or (lRight = TypeCode.String) then begin
    if lRight = TypeCode.Single then
      aRight := Single(aRight).ToString(System.Globalization.NumberFormatInfo.InvariantInfo)
    else if lRight = TypeCode.Double then
      aRight := Double(aRight).ToString(System.Globalization.NumberFormatInfo.InvariantInfo)
    else aRight := aRight.ToString;
    if lLeft = TypeCode.Single then
      aLeft := Single(aLeft).ToString(System.Globalization.NumberFormatInfo.InvariantInfo)
    else if lLeft = TypeCode.Double then
      aLeft := Double(aLeft).ToString(System.Globalization.NumberFormatInfo.InvariantInfo)
    else aLeft := aLeft.ToString;

    exit string.Equals(string(aLeft), string(aRight));
  end;
  if (lLeft in [TypeCode.Double, TypeCode.Single]) and (lRight in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Single,
      TypeCode.Double,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64]) then
    exit Convert.ToDouble(aLeft) = Convert.ToDouble(aRight);
  if (lRight in [TypeCode.Double, TypeCode.Single]) and (lLeft in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Single,
      TypeCode.Double,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64]) then
    exit Convert.ToDouble(aLeft) = Convert.ToDouble(aRight);

  if (lLeft in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64]) and (lRight in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64]) then
    exit Convert.ToInt64(aLeft) = Convert.ToInt64(aRight);

  result := aLeft.Equals(aRight);
end;

class method Operators.StrictEqual(aLeft, aRight: Object): Object;
begin
  if (aLeft = nil) and (aRight = nil) then exit true;
  if (aLeft = nil) or (aRight = nil) then exit false;
  if (&Type.GetTypeCode(aLeft.GetType()) in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64,
      TypeCode.Single, 
      TypeCode.Double]) and (&Type.GetTypeCode(aRight.GetType()) in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64,
      TypeCode.Single, 
      TypeCode.Double]) then
        exit DoubleCompare(Utilities.GetObjAsDouble(aLeft), Utilities.GetObjAsDouble(aRight));
  if aLeft.GetType() <> aRight.GetType() then exit false;
  if aLeft = Undefined.Instance then exit true;
  if aLEft is Double then begin
    if Double(aLeft) = Double.NaN then exit false;
    if Double(aRight) = Double.NaN then exit false;
  end;

  exit &Equals(aLeft, aRight);
end;

class method Operators.StrictNotEqual(aLeft, aRight: Object): Object;
begin
  result := NOT Boolean(StrictEqual(aLeft, aRight));
end;
class method Operators.DoubleCompare(aLeft, aRight: Double): Boolean;
begin
  if Double.IsNegativeInfinity(aLeft) and Double.IsNegativeInfinity(aRight) then exit true;
  if Double.IsPositiveInfinity(aLeft) and Double.IsPositiveInfinity(aRight) then exit true;
  exit Math.Abs(aRight - aLeft) < 0.00000001;
end;

class method Operators.SameValue(aLeft, aright: Object): Boolean;
begin
  exit (aLeft = aRight) or Boolean(StrictEqual(aLeft, aRight));
end;

class method Operators._TypeOf(aValue: Object): String;
begin
  if aValue = nil then exit 'object';
  if aValue = Undefined.Instance then exit 'undefined';
  var lObj := EcmaScriptObject(aValue);
  if (lObj <> nil) and (lObj.Value <> nil) then begin
    aValue:= lObj.Value;
    lObj := nil;
  end;

  if lObj <> nil then begin
    if lObj is EcmaScriptBaseFunctionObject then 
    exit 'function';
    exit 'object';
  end;

  case &Type.GetTypeCode(aValue.GetType) of
    TypeCode.Boolean: exit 'boolean';
    TypeCode.Char: exit 'string';
    TypeCode.Decimal,
    TypeCode.Double,
    TypeCode.Byte,
    TypeCode.Int16,
    TypeCode.Int32,
    TypeCode.Int64,    
    TypeCode.SByte,
    TypeCode.UInt16,
    TypeCode.UInt32,
    TypeCode.UInt64,
    TypeCode.Single: exit 'number';
    TypeCode.String: exit 'string';
  end; // case
  exit 'object';
end;

class method Operators.NotEqual(aLeft, aRight: Object): Object;
begin
  exit Not Boolean(Equal(aLeft, aRight));
end;

end.
