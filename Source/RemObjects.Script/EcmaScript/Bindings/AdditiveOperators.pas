namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Text,
  System.Runtime.CompilerServices,
  RemObjects.Script;

type
  Operators = public partial class
  public
    class method &Add(aLeft: Object;  aRight: Object;  ec: ExecutionContext): Object;
    class method Subtract(aLeft: Object;  aRight: Object;  ec: ExecutionContext): Object;

    class var Method_Add: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Add');
    class var Method_Subtract: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Subtract');
  end;


implementation


class method Operators.&Add(aLeft: Object;  aRight: Object;  ec: ExecutionContext): Object;
begin
  if  (aLeft is EcmaScriptObject)  then
    aLeft := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aLeft), PrimitiveType.None);

  if  (aRight is EcmaScriptObject)  then
    aRight := Utilities.GetObjectAsPrimitive(ec, EcmaScriptObject(aRight), PrimitiveType.None);

  if  ((aLeft is String)  or  (aRight is String)) then
    exit  (Utilities.GetObjAsString(aLeft, ec) + Utilities.GetObjAsString(aRight, ec));

  if  ((aLeft is Int32)  and  (aRight is Int32))  then
    exit  (Int32(aLeft) + Int32(aRight));

  exit  (Utilities.GetObjAsDouble(aLeft, ec) + Utilities.GetObjAsDouble(aRight, ec));
end;


class method Operators.Subtract(aLeft: Object;  aRight: Object;  ec: ExecutionContext): Object;
begin
  if  ((aLeft is Int32)  and  (aRight is Int32))  then
    exit  (Int32(aLeft) - Int32(aRight));

  exit  (Utilities.GetObjAsDouble(aLeft, ec) - Utilities.GetObjAsDouble(aRight, ec));
end;


end.