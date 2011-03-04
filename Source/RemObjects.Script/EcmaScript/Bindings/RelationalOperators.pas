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
  protected
  public
    class method LessThan(aLeft, aRight: Object): Object;
    class method GreaterThan(aLeft, aRight: Object): Object;
    class method LessThanOrEqual(aLeft, aRight: Object): Object;
    class method GreaterThanOrEqual(aLeft, aRight: Object): Object;
    class method InstanceOf(aLeft, aRight: Object): Boolean;
    class method &In(aLeft, aRight: Object): Boolean;

    class var Method_LessThan: System.Reflection.MethodInfo := typeof(Operators).GetMethod('LessThan');
    class var Method_GreaterThan: System.Reflection.MethodInfo := typeof(Operators).GetMethod('GreaterThan');
    class var Method_LessThanOrEqual: System.Reflection.MethodInfo := typeof(Operators).GetMethod('LessThanOrEqual');
    class var Method_GreaterThanOrEqual: System.Reflection.MethodInfo := typeof(Operators).GetMethod('GreaterThanOrEqual');
    class var Method_InstanceOf: System.Reflection.MethodInfo := typeof(Operators).GetMethod('InstanceOf');
    class var Method_In: System.Reflection.MethodInfo := typeof(Operators).GetMethod('In');
  end;

implementation

class method Operators.InstanceOf(aLeft, aRight: Object): Boolean;
begin
  var lRight := EcmaScriptObject(aRight);
  if lRight = nil then exit false;
  if aLeft = nil then exit false;
  lRight := lRight.Prototype;

  var lLeft := EcmaScriptObject(aLeft);
  if (lLeft <> nil) then  begin
    repeat
      if lLeft = lRight then exit true;
      lLeft := lLeft.Prototype;
    until lLeft = nil;
    exit false;
  end;
  if (aLeft is String) and (lRight.Class = 'String') then exit true;
  if (&Type.GetTypecode(aLeft.GetType) in [TypeCode.SByte, 
      TypeCode.Int16,
      TypeCode.Int32, 
      TypeCode.Int64,
      TypeCode.Single,
      TypeCode.Double,
      TypeCode.Byte,
      TypeCode.UInt16,
      TypeCode.UInt32,
      TypeCode.UInt64, Typecode.Single, TypeCode.Double]) and (lRight.Class = 'Number') then exit true;
  exit false;
end;


class method Operators.In(aLeft, aRight: Object): Boolean;
begin
  var lObj := EcmaScriptObject(aRight);
  if lObj = nil then exit false;

  exit lObj.HasProperty(Utilities.GetObjAsString(aLeft));
end;



class method Operators.LessThan(aLeft, aRight: Object): Object;
begin
  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  exit Utilities.GetObjAsDouble(aLeft) < Utilities.GetObjAsDouble(aRight); 
end;

class method Operators.GreaterThan(aLeft, aRight: Object): Object;
begin
  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  exit Utilities.GetObjAsDouble(aLeft) > Utilities.GetObjAsDouble(aRight); 
end;

class method Operators.LessThanOrEqual(aLeft, aRight: Object): Object;
begin
  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  exit Utilities.GetObjAsDouble(aLeft) <= Utilities.GetObjAsDouble(aRight); 
end;

class method Operators.GreaterThanOrEqual(aLeft, aRight: Object): Object;
begin
  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  exit Utilities.GetObjAsDouble(aLeft) >= Utilities.GetObjAsDouble(aRight); 
end;

end.
