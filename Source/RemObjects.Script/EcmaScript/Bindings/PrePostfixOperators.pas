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
  public
    
    class method PostDecrement(aLeft: Object; aExec: ExecutionContext): Object;
    class method PostIncrement(aLeft: Object; aExec: ExecutionContext): Object;
    class method PreDecrement(aLeft: Object; aExec: ExecutionContext): Object;
    class method PreIncrement(aLeft: Object; aExec: ExecutionContext): Object;

    // OR, AND, ?: have side effects in evaluation and are not specified here.
    class var Method_PostDecrement: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('PostDecrement');
    class var Method_PostIncrement: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('PostIncrement');
    class var Method_PreDecrement: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('PreDecrement');
    class var Method_PreIncrement: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('PreIncrement');
  end;

implementation
class method Operators.PostDecrement(aLeft: Object; aExec: ExecutionContext): Object;
begin
  var lRef := Reference(aLeft);
  
  if (lRef <> nil) then begin
    if (lRef.Strict) and (lRef.Base is EnvironmentRecord) and (lRef.Name in ['eval', 'arguments']) then 
      aExec.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'eval/arguments cannot be used in post decrement operator');
    aLeft := Reference.GetValue(lRef, aExec);
  end;
  var lOldValue := aLeft;
  if aLeft is Integer then begin
    lOldValue := Integer(aLeft);
    aLeft := Integer(aLeft) -1
  end else begin
    lOldValue := Utilities.GetObjAsDouble(aLeft, aExec);
    aLeft := Utilities.GetObjAsDouble(aLeft, aExec) -1.0;
  end;
  Reference.SetValue(lRef, aLeft, aExec);
  exit lOldValue;
end;

class method Operators.PostIncrement(aLeft: Object; aExec: ExecutionContext): Object;
begin
  var lRef := Reference(aLeft);
  
  if (lRef <> nil) then begin
    if (lRef.Strict) and (lRef.Base is EnvironmentRecord) and (lRef.Name in ['eval', 'arguments']) then 
      aExec.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'eval/arguments cannot be used in post increment operator');
    aLeft := Reference.GetValue(lRef, aExec);
  end;
  var lOldValue := aLeft;
  if aLeft is Integer then begin
    lOldValue := Integer(aLeft);
    aLeft := Integer(aLeft) +1
  end else begin
    lOldValue := Utilities.GetObjAsDouble(aLeft, aExec);
    aLeft := Utilities.GetObjAsDouble(aLeft, aExec) +1.0;
  end;
  Reference.SetValue(lRef, aLeft, aExec);
  exit lOldValue;
end;

class method Operators.PreDecrement(aLeft: Object; aExec: ExecutionContext): Object;
begin
  var lRef := Reference(aLeft);
  
  if (lRef <> nil) then begin
    if (lRef.Strict) and (lRef.Base is EnvironmentRecord) and (lRef.Name in ['eval', 'arguments']) then 
      aExec.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'eval/arguments cannot be used in pre decrement operator');
    aLeft := Reference.GetValue(lRef, aExec);
  end;
  if aLeft is Integer then 
    aLeft := Integer(aLeft) -1
  else
    aLeft := Utilities.GetObjAsDouble(aLeft, aExec) -1.0;
  exit Reference.SetValue(lRef, aLeft, aExec);
end;

class method Operators.PreIncrement(aLeft: Object; aExec: ExecutionContext): Object;
begin
  var lRef := Reference(aLeft);
  
  if (lRef <> nil) then begin
    if (lRef.Strict) and (lRef.Base is EnvironmentRecord) and (lRef.Name in ['eval', 'arguments']) then 
      aExec.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'eval/arguments cannot be used in pre decrement operator');
    aLeft := Reference.GetValue(lRef, aExec);
  end;
  if aLeft is Integer then 
    aLeft := Integer(aLeft) +1
  else
    aLeft := Utilities.GetObjAsDouble(aLeft, aExec) +1.0;
  exit Reference.SetValue(lRef, aLeft, aExec);
end;

end.
