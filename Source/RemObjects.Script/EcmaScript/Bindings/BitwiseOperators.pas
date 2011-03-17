
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
    class method &And(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method &Or(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method &Xor(aLeft, aRight: Object; ec: ExecutionContext): Object;

    class var Method_And: System.Reflection.MethodInfo := typeof(Operators).GetMethod('And');
    class var Method_Or: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Or');
    class var Method_XOr: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Xor');
  end;

implementation

class method Operators.And(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft, ec) and Utilities.GetObjAsInteger(aRight, ec);
end;

class method Operators.Or(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft, ec) or Utilities.GetObjAsInteger(aRight, ec);
end;

class method Operators.Xor(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft, ec) xor Utilities.GetObjAsInteger(aRight, ec);
end;

end.
