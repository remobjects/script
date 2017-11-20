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
    class method IsNegativeZero(aValue: Double): Boolean;
  protected
  public
    class method Multiply(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method Divide(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method Modulus(aLeft, aRight: Object; ec: ExecutionContext): Object;

    class var Method_Multiply: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Multiply');
    class var Method_Divide: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Divide');
    class var Method_Modulus: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Modulus');
  end;
implementation
class method Operators.Multiply(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) then begin
    var lL := Integer(aLeft);
    var lR := Integer(aRight);
    var lRes := lL * lR;
    if lR = 0 then exit lRes;
    var lNegativeSign := (lL < 0) = (lR < 0);
    if lNegativeSign then begin
      if lRes < lL then exit lRes;
    end else
      if lRes > lL then exit lRes;
  end;
  var lL := Utilities.GetObjAsDouble(aLeft, ec);
  var lR :=Utilities.GetObjAsDouble(aRight, ec);
  exit lL * lR;
end;

class method Operators.Divide(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) and (Integer(aRight) <> 0) and (Integer(aLeft) <> 0) and (Integer(aLeft) mod Integer(aRight) = 0) then begin
    exit Integer(aLeft) div Integer(aRight);
  end;
  
  exit Utilities.GetObjAsDouble(aLeft, ec) / Utilities.GetObjAsDouble(aRight, ec);
end;

class method Operators.Modulus(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  if (aLeft is Int32) and (aRight is Int32) and (Integer(aRight) <> 0) and (Integer(aLeft) > 0) then 
    exit Integer(aLeft) mod Integer(aRight);
  
  var lLeft := Utilities.GetObjAsDouble(aLeft, ec);
  var lRight := Utilities.GetObjAsDouble(aRight, ec);
  var lWork := lLeft / lRight;
  if lWork < 0 then 
    lWork := Math.Ceiling(lWork)
  else 
    lWork := Math.Floor(lWork);
  lWork := lLeft - (lRight * lWork);
  if Double.IsInfinity(lRight) and not Double.IsInfinity(lLeft) then begin
    lWork := lLeft;
  end else
  if (lWork = 0.0) and (lLeft < 0) or IsNegativeZero(lLeft) then
    lWork := - lWork;
  result := lWork;
end;

class method Operators.IsNegativeZero(aValue: Double): Boolean;
begin
  exit (aValue = 0.0) and Double.IsNegativeInfinity(1.0 / aValue) 
end;

end.