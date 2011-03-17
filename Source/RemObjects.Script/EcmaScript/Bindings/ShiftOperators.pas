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
    class method ShiftLeft(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method ShiftRight(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method ShiftRightUnsigned(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class var Method_ShiftLeft: System.Reflection.MethodInfo := typeof(Operators).GetMethod('ShiftLeft');
    class var Method_ShiftRight: System.Reflection.MethodInfo := typeof(Operators).GetMethod('ShiftRight');
    class var Method_ShiftRightUnsigned: System.Reflection.MethodInfo := typeof(Operators).GetMethod('ShiftRightUnsigned');

  end;

implementation

class method Operators.ShiftLeft(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft, ec) shl Utilities.GetObjAsInteger(aright, ec);
end;

class method Operators.ShiftRight(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft, ec) shr Utilities.GetObjAsInteger(aright, ec);
end;

class method Operators.ShiftRightUnsigned(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Integer(Cardinal(Utilities.GetObjAsInteger(aLeft, ec)) shl Cardinal(Utilities.GetObjAsInteger(aright, ec)));
end;

end.
