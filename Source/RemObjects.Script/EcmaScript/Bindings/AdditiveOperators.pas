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
    class method Add(aLeft, aRight: Object): Object;
    class method Subtract(aLeft, aRight: Object): Object;

    class var Method_Add: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Add');
    class var Method_Subtract: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Subtract');
  end;

implementation

class method Operators.Add(aLeft, aRight: Object): Object;
begin
  if (aLeft is String) or (aRight is String) then
     exit Utilities.GetObjAsString(aLeft) + Utilities.GetObjAsString(aRight);
  if (aLeft is Int32) and (aRight is Int32) then
    exit Int32(aLeft) + Int32(aRight);
  exit Utilities.GetObjAsDouble(aLeft) + Utilities.GetObjAsDouble(aRight);
end;

class method Operators.Subtract(aLeft, aRight: Object): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) then
    exit Int32(aLeft) - Int32(aRight);
  exit Utilities.GetObjAsDouble(aLeft) - Utilities.GetObjAsDouble(aRight);
end;

end.
