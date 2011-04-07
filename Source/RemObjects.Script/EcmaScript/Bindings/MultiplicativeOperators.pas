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
    class method Multiply(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method Divide(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method Modulus(aLeft, aRight: Object; ec: ExecutionContext): Object;

    class var Method_Multiply: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Multiply');
    class var Method_Divide: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Divide');
    class var Method_Modulus: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Modulus');
  end;
implementation
class method Operators.Multiply(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) then begin
    var lL := Integer(aLeft);
    var lR := Integer(aRight);
    var lRes := lL * lR;
    if lR = 0 then exit lRes;
    var lNegativeSign := (lL < 0) = (lR < 0);
    if lNegativeSign then begin
      if lRes < lL then exit lRes;
    end else
      if lRes > lL then exit lRes;
  end;
  var lL := Utilities.GetObjAsDouble(aLeft, ec);
  var lR :=Utilities.GetObjAsDouble(aRight, ec);
  exit lL * lR;
end;

class method Operators.Divide(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) and (Integer(aRight) <> 0) then begin
    exit Integer(aLeft) div Integer(aRight);
  end;
  
  exit Utilities.GetObjAsDouble(aLeft, ec) / Utilities.GetObjAsDouble(aRight, ec);
end;

class method Operators.Modulus(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) and (Integer(aRight) <> 0) then
    exit Integer(aLeft) mod Integer(aRight);
  
   exit Math.IEEERemainder(Utilities.GetObjAsDouble(aLeft, ec), Utilities.GetObjAsDouble(aRight, ec));
end;

end.