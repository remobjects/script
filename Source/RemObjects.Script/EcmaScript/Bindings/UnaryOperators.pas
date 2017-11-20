//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

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
    class method BitwiseNot(aData: Object; ec: ExecutionContext): Object; // ~
    class method LogicalNot(aData: Object; ec: ExecutionContext): Object; // !
    class method Minus(aData: Object; ec: ExecutionContext): Object; // -
    class method Plus(aData: Object; ec: ExecutionContext): Object; // -
    
    class var Method_BitwiseNot: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('BitwiseNot');
    class var Method_LogicalNot: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('LogicalNot');
    class var Method_Minus: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Minus');
    class var Method_Plus: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Plus');
  end;

implementation

class method Operators.BitwiseNot(aData: Object; ec: ExecutionContext): Object;
begin
  exit not Utilities.GetObjAsInteger(aData, ec);
end;

class method Operators.LogicalNot(aData: Object; ec: ExecutionContext): Object;
begin
  exit not Utilities.GetObjAsBoolean(aData, ec);
end;

class method Operators.Minus(aData: Object; ec: ExecutionContext): Object;
begin
  if aData is Integer then begin
    if Integer(aData) = 0 then begin
      var d: Double := 0;
      d := -d;
      exit d;
    end;
    exit - Integer(aData);
  end;
  exit -Utilities.GetObjAsDouble(aData, ec);
end;

class method Operators.Plus(aData: Object; ec: ExecutionContext): Object;
begin
  if aData is Integer then
    exit aData;
  exit Utilities.GetObjAsDouble(aData, ec);
end;

end.