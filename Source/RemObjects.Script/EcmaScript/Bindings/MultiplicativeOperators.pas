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
    class method Multiply(aLeft, aRight: Object): Object;
    class method Divide(aLeft, aRight: Object): Object;
    class method Modulus(aLeft, aRight: Object): Object;

    class var Method_Multiply: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Multiply');
    class var Method_Divide: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Divide');
    class var Method_Modulus: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Modulus');
  end;
implementation
class method Operators.Multiply(aLeft, aRight: Object): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) then
    exit Integer(aLeft) * Integer(aRight);
  
  exit Utilities.GetObjAsDouble(aLeft) * Utilities.GetObjAsDouble(aRight);
end;

class method Operators.Divide(aLeft, aRight: Object): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) then
    exit Integer(aLeft) div Integer(aRight);
  
  exit Utilities.GetObjAsDouble(aLeft) * Utilities.GetObjAsDouble(aRight);
end;

class method Operators.Modulus(aLeft, aRight: Object): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) then
    exit Integer(aLeft) div Integer(aRight);
  
   exit Math.IEEERemainder(Utilities.GetObjAsDouble(aLeft), Utilities.GetObjAsDouble(aRight));
end;

end.