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
    class var Method_ShiftLeft: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('ShiftLeft');
    class var Method_ShiftRight: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('ShiftRight');
    class var Method_ShiftRightUnsigned: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('ShiftRightUnsigned');

  end;

implementation

class method Operators.ShiftLeft(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft, ec) shl Utilities.GetObjAsInteger(aRight, ec);
end;

class method Operators.ShiftRight(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit Utilities.GetObjAsInteger(aLeft, ec) shr Utilities.GetObjAsInteger(aRight, ec);
end;

class method Operators.ShiftRightUnsigned(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  var l := Cardinal(Utilities.GetObjAsInteger(aLeft, ec));
  var r := Cardinal(Utilities.GetObjAsInteger(aRight, ec));
  var res := Int64(l shr r);
  exit Double(res);
end;

end.
