//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

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
    
    class method SameValue(aLeft, aright: Object; ec: ExecutionContext): Boolean;


    class method Equal(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method NotEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method StrictEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method StrictNotEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method _TypeOf(aValue: Object; ec: ExecutionContext): String;

    // OR, AND, ?: have side effects in evaluation and are not specified here.
    class var Method_SameValue: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('SameValue');
    class var Method_Equal: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Equal');
    class var Method_NotEqual: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('NotEqual');
    class var Method_StrictEqual: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('StrictEqual');
    class var Method_StrictNotEqual: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('StrictNotEqual');
    class var Method_TypeOf: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('_TypeOf');

    class method &Type(o: Object): SimpleType;
  end;

  SimpleType = public enum (Undefined, Null, Boolean, String, Number, Object);

implementation

class method Operators.Equal(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  var lLeft := &Type(aLeft);
  var lRight := &Type(aRight);
  if lLeft = lRight then begin
    case lLeft of 
      SimpleType.Boolean: exit Utilities.GetObjAsBoolean(aLeft, ec) = Utilities.GetObjAsBoolean(aRight, ec);
      SimpleType.Undefined, SimpleType.Null: exit true;
      SimpleType.Number: begin 
        if (aLeft is Int32) and (aRight is Int32) then
          exit Int32(aLeft) = Int32(aRight);
        if (aLeft is Int64) and (aRight is Int64) then
          exit Int64(aLeft) = Int64(aRight);
        exit DoubleCompare(Utilities.GetObjAsDouble(aLeft, ec), Utilities.GetObjAsDouble(aRight, ec));
      end;
      SimpleType.String: exit Utilities.GetObjAsString(aLeft, ec) = Utilities.GetObjAsString(aRight, ec);
    else // object
      exit EcmaScriptObject(aLeft) = EcmaScriptObject(aRight);
    end; // case
  end;
  if ((lLeft = SimpleType.Undefined) and (lRight = SimpleType.Null)) or
    ((lRight = SimpleType.Undefined) and (lLeft = SimpleType.Null)) then
    exit true;
  if (lLeft = SimpleType.Number) and (lRight = SimpleType.String) then 
   exit Equal(aLeft, Utilities.GetObjAsDouble(aRight, ec), ec);
  if (lRight = SimpleType.Number) and (lLeft = SimpleType.String) then 
   exit Equal(Utilities.GetObjAsDouble(aLeft, ec), aRight, ec);

  if (lLeft = SimpleType.Boolean) then
    exit Equal(Utilities.GetObjAsDouble(aLeft, ec), aRight, ec);
  if (lRight = SimpleType.Boolean) then
    exit Equal(aLeft, Utilities.GetObjAsDouble(aRight, ec), ec);

  if (lLeft in [SimpleType.String, SimpleType.Number]) and  
    (lRight = SimpleType.Object) then 
    exit Equal(aLeft, Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aRight), PrimitiveType.None), ec);
  if (lRight in [SimpleType.String, SimpleType.Number]) and  
    (lLeft = SimpleType.Object) then 
    exit Equal(Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aLeft), PrimitiveType.None), aRight, ec);
    
    
  exit false;
end;

class method Operators.StrictEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if (aLeft = nil) and (aRight = nil) then exit true;
  if (aLeft = nil) or (aRight = nil) then exit false;
  if (System.Type.GetTypeCode(aLeft.GetType()) in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64,
      TypeCode.Single, 
      TypeCode.Double]) and (System.Type.GetTypeCode(aRight.GetType()) in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64,
      TypeCode.Single, 
      TypeCode.Double]) then begin
        exit DoubleCompare(Utilities.GetObjAsDouble(aLeft, ec), Utilities.GetObjAsDouble(aRight, ec));
      end;
  if aLeft.GetType() <> aRight.GetType() then exit false;
  if aLeft = Undefined.Instance then exit true;

  exit &Equals(aLeft, aRight);
end;

class method Operators.StrictNotEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  result := NOT Boolean(StrictEqual(aLeft, aRight, ec));
end;

class method Operators.DoubleCompare(aLeft, aRight: Double): Boolean;
begin
  if Double.IsNegativeInfinity(aLeft) and Double.IsNegativeInfinity(aRight) then exit true;
  if Double.IsPositiveInfinity(aLeft) and Double.IsPositiveInfinity(aRight) then exit true;
  if Double.IsNegativeInfinity(aLeft) and Double.IsPositiveInfinity(aRight) then exit false;
  if Double.IsPositiveInfinity(aLeft) and Double.IsNegativeInfinity(aRight) then exit false;
  if Double.IsNaN(aLeft) then exit false;
  if Double.IsNaN(aRight) then exit false;
  if Double.IsInfinity(aLeft) or Double.IsInfinity(aRight) then exit false; 
  //var bits := BitConverter.DoubleToInt64Bits(aLeft);
  // Note that the shift is sign-extended, hence the test against -1 not 1
  exit aLeft = aRight;
end;

class method Operators.SameValue(aLeft, aright: Object; ec: ExecutionContext): Boolean;
begin
  exit (aLeft = aright) or Boolean(StrictEqual(aLeft, aright, ec));
end;

class method Operators._TypeOf(aValue: Object; ec: ExecutionContext): String;
begin
  var lRef := Reference(aValue);
  if assigned(lRef) and (lRef.Base = Undefined.Instance) then exit 'undefined';
  aValue := Reference.GetValue(aValue, ec);
  if aValue = nil then exit 'object';
  if aValue = Undefined.Instance then exit 'undefined';
  var lObj := EcmaScriptObject(aValue);

  if lObj <> nil then begin
    if lObj is EcmaScriptBaseFunctionObject then 
    exit 'function';
    exit 'object';
  end;

  case System.Type.GetTypeCode(aValue.GetType) of
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

class method Operators.NotEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Not Boolean(Equal(aLeft, aRight, ec));
end;

class method Operators.Type(o: Object): SimpleType;
begin
  if o= nil then exit SimpleType.Null;
  if o = Undefined.Instance  then exit  SimpleType.Undefined;
  case System.Type.GetTypeCode(o.GetType()) of
    TypeCode.Boolean: exit SimpleType.Boolean;
    TypeCode.Int32,
    TypeCode.Double: exit SimpleType.Number;
    TypeCode.String: exit SimpleType.String;
  else
    exit SimpleType.Object;
  end; // case
end;

end.
