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
    
    class method PostDecrement(aLeft: Object): Object;
    class method PostIncrement(aLeft: Object): Object;
    class method PreDecrement(aLeft: Object): Object;
    class method PreIncrement(aLeft: Object): Object;

    // OR, AND, ?: have side effects in evaluation and are not specified here.
    class var Method_PostDecrement: System.Reflection.MethodInfo := typeof(Operators).GetMethod('PostDecrement');
    class var Method_PostIncrement: System.Reflection.MethodInfo := typeof(Operators).GetMethod('PostIncrement');
    class var Method_PreDecrement: System.Reflection.MethodInfo := typeof(Operators).GetMethod('PreDecrement');
    class var Method_PreIncrement: System.Reflection.MethodInfo := typeof(Operators).GetMethod('PreIncrement');
  end;

implementation
class method Operators.PostDecrement(aLeft: Object): Object;
begin

end;

class method Operators.PostIncrement(aLeft: Object): Object;
begin
end;

class method Operators.PreDecrement(aLeft: Object): Object;
begin
end;

class method Operators.PreIncrement(aLeft: Object): Object;
begin
end;

end.
