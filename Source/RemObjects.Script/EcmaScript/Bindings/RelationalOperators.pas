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
    class method LessThan(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method GreaterThan(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method LessThanOrEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method GreaterThanOrEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method InstanceOf(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method &In(aLeft, aRight: Object; ec: ExecutionContext): Object;

    class var Method_LessThan: System.Reflection.MethodInfo := typeof(Operators).GetMethod('LessThan');
    class var Method_GreaterThan: System.Reflection.MethodInfo := typeof(Operators).GetMethod('GreaterThan');
    class var Method_LessThanOrEqual: System.Reflection.MethodInfo := typeof(Operators).GetMethod('LessThanOrEqual');
    class var Method_GreaterThanOrEqual: System.Reflection.MethodInfo := typeof(Operators).GetMethod('GreaterThanOrEqual');
    class var Method_InstanceOf: System.Reflection.MethodInfo := typeof(Operators).GetMethod('InstanceOf');
    class var Method_In: System.Reflection.MethodInfo := typeof(Operators).GetMethod('In');
  end;

implementation

class method Operators.InstanceOf(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  var lLeft := EcmaScriptObject(aLeft);;
  if lLeft = nil then exit false;
  var lRight := EcmaScriptObject(aRight);
  lRight := EcmaScriptObject(lRight.Get(ec, 0, 'prototype'));
  if lRight = nil then ec.Global.RaiseNativeError(NativeErrorType.TypeError, 'Not an object');

  repeat
    if lLeft = lRight then exit true;
    lLeft := lLeft.Prototype;
  until lLeft = nil;
  exit false;
end;


class method Operators.In(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  var lObj := EcmaScriptObject(aRight);
  if lObj = nil then exit false;

  exit lObj.HasProperty(Utilities.GetObjAsString(aLeft, ec));
end;



class method Operators.LessThan(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if aLeft is EcmaScriptObject then aLeft := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aLeft), PrimitiveType.Number);
  if aRight is EcmaScriptObject then aRight := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aRight), PrimitiveType.Number);

  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  var l := Utilities.GetObjAsDouble(aLeft, ec);
  var r := Utilities.GetObjAsDouble(aRight, ec);
  if Double.IsNaN(l) or Double.IsNaN(R) then exit false;
  exit l < r;  
end;

class method Operators.GreaterThan(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if aLeft is EcmaScriptObject then aLeft := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aLeft), PrimitiveType.Number);
  if aRight is EcmaScriptObject then aright := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aRight), PrimitiveType.Number);
  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  var l := Utilities.GetObjAsDouble(aLeft, ec);
  var r := Utilities.GetObjAsDouble(aRight, ec);
  if Double.IsNaN(l) or Double.IsNaN(R) then exit false;
  exit l > r;  
end;

class method Operators.LessThanOrEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if aLeft is EcmaScriptObject then aLeft := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aLeft), PrimitiveType.Number);
  if aRight is EcmaScriptObject then aright := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aRight), PrimitiveType.Number);
  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  var l := Utilities.GetObjAsDouble(aLeft, ec);
  var r := Utilities.GetObjAsDouble(aRight, ec);
  if Double.IsNaN(l) or Double.IsNaN(R) then exit false;
  exit l <=r;  
end;

class method Operators.GreaterThanOrEqual(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if aLeft is EcmaScriptObject then aLeft := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aLeft), PrimitiveType.Number);
  if aRight is EcmaScriptObject then aright := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aRight), PrimitiveType.Number);
  if (aLeft is String) and (aRight is String) then
   exit String(aLeft) < String(aRight);
  var l := Utilities.GetObjAsDouble(aLeft, ec);
  var r := Utilities.GetObjAsDouble(aRight, ec);
  if Double.IsNaN(l) or Double.IsNaN(R) then exit false;
  exit l >=r;  
end;

end.
