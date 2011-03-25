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
  var l := Cardinal(Utilities.GetObjAsInteger(aLeft, ec));
  var r := Cardinal(Utilities.GetObjAsInteger(aright, ec));
  var res := Int64(l shr r);
  exit double(res);
end;

end.
