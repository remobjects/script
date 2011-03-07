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
    class method &And(aLeft, aRight: Object): Object;
    class method &Or(aLeft, aRight: Object): Object;
    class method &Xor(aLeft, aRight: Object): Object;

    class var Method_And: System.Reflection.MethodInfo := typeof(Operators).GetMethod('And');
    class var Method_Or: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Or');
    class var Method_XOr: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Xor');
  end;

implementation

class method Operators.And(aLeft, aRight: Object): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft) and Utilities.GetObjAsInteger(aRight);
end;

class method Operators.Or(aLeft, aRight: Object): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft) or Utilities.GetObjAsInteger(aRight);
end;

class method Operators.Xor(aLeft, aRight: Object): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft) xor Utilities.GetObjAsInteger(aRight);
end;

end.
