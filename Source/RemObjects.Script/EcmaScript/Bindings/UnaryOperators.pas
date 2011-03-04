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
    class method BitwiseNot(aData: Object): Object; // ~
    class method LogicalNot(aData: Object): OBject; // !
    class method Minus(aData: Object): OBject; // -
    class method Plus(aData: Object): OBject; // -
    
    class var Method_BitwiseNot: System.Reflection.MethodInfo := typeof(Operators).GetMethod('BitwiseNot');
    class var Method_LogicalNot: System.Reflection.MethodInfo := typeof(Operators).GetMethod('LogicalNot');
    class var Method_Minus: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Minus');
    class var Method_Plus: System.Reflection.MethodInfo := typeof(Operators).GetMethod('Plus');
  end;

implementation

class method Operators.BitwiseNot(aData: Object): Object;
begin
  exit not Utilities.GetObjAsInteger(aData);
end;

class method Operators.LogicalNot(aData: Object): OBject;
begin
  exit not Utilities.GetObjAsBoolean(aData);
end;

class method Operators.Minus(aData: Object): OBject;
begin
  if aData is Integer then
    exit - Integer(aData);
  exit -Utilities.GetObjAsDouble(aData);
end;

class method Operators.Plus(aData: Object): OBject;
begin
  if aData is Integer then
    exit aData;
  exit Utilities.GetObjAsDouble(aData);
end;

end.