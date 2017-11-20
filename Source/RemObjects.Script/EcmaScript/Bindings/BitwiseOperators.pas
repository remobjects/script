//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Runtime.CompilerServices,
  System.Text,
  RemObjects.Script;

type
  Operators = public partial class
  public
    class method &And(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method &Or(aLeft, aRight: Object; ec: ExecutionContext): Object;
    class method &Xor(aLeft, aRight: Object; ec: ExecutionContext): Object;

    class var Method_And: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('And');
    class var Method_Or: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Or');
    class var Method_XOr: System.Reflection.MethodInfo := typeOf(Operators).GetMethod('Xor');
  end;


implementation


class method Operators.And(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit  (Utilities.GetObjAsInteger(aLeft, ec) and Utilities.GetObjAsInteger(aRight, ec));
end;


class method Operators.Or(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit  (Utilities.GetObjAsInteger(aLeft, ec) or Utilities.GetObjAsInteger(aRight, ec));
end;


class method Operators.Xor(aLeft, aRight: Object; ec: ExecutionContext): Object;
begin
  exit  (Utilities.GetObjAsInteger(aLeft, ec) xor Utilities.GetObjAsInteger(aRight, ec));
end;


end.