//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Text,
  RemObjects.Script.EcmaScript.Internal;

type
  EcmaScriptArgumentObject = class(EcmaScriptObject)
  private
    var fExecutionScope: ExecutionContext;
    var fStrict: Boolean;
    var fNames: array of String;
    var fArgs: array of Object;

  public
    constructor(ex: ExecutionContext;  aArgs: array of Object;  aArgNames: array of String;  aCaller: EcmaScriptFunctionObject;  aStrict: Boolean);

    property Map: EcmaScriptObject;

    class var &Constructor: System.Reflection.ConstructorInfo := typeOf (EcmaScriptArgumentObject).GetConstructors()[0]; readonly;

    method Get(aExecutionContext: ExecutionContext;  aFlags: Int32;  aName: String): Object; override;
    method GetOwnProperty(name: String;  getPropertyValue: Boolean): PropertyValue; override;
    method DefineOwnProperty(aName: String;  aValue: PropertyValue;  aThrow: Boolean): Boolean; override;
    method Delete(aName: String;  aThrow: Boolean): Boolean; override;
  end;


implementation


constructor EcmaScriptArgumentObject(ex: ExecutionContext;  aArgs: array of Object;  aArgNames: array of String;
                   aCaller: EcmaScriptFunctionObject;  aStrict: Boolean);
begin
  inherited constructor(ex.Global, ex.Global.ObjectPrototype);

  &Class := 'Arguments';
  fExecutionScope := ex;
  DefineOwnProperty('length', new PropertyValue(PropertyAttributes.Configurable or PropertyAttributes.Writable, length(aArgs)));

  if  (aStrict)  then  begin
    DefineOwnProperty('caller', new PropertyValue(PropertyAttributes.None, ex.Global.Thrower));
    DefineOwnProperty('callee', new PropertyValue(PropertyAttributes.None, ex.Global.Thrower));
  end
  else  begin
    DefineOwnProperty('callee', new PropertyValue(PropertyAttributes.Writable or PropertyAttributes.Configurable, aCaller));
  end;

  fArgs := aArgs;
  fNames := aArgNames;
  fStrict := aStrict;
end;


method EcmaScriptArgumentObject.Get(aExecutionContext: ExecutionContext;  aFlags: Int32;  aName: String): Object;
begin
  var lIndex: Int32;
  if  (not fStrict  and  Int32.TryParse(aName, out lIndex))  then  begin
    if  (lIndex < Math.Min(length(fNames), length(fArgs))) then
      exit  (fExecutionScope.LexicalScope.GetBindingValue(fNames[lIndex], false));

    if  (lIndex < length(fArgs))  then
      exit  (self.fArgs[lIndex]);
  end;

  exit inherited;
end;


method EcmaScriptArgumentObject.GetOwnProperty(name: String;  getPropertyValue: Boolean): PropertyValue;
begin
  var lIndex: Int32;
  if  (not fStrict and Int32.TryParse(name, out lIndex)  and  (lIndex < Math.Min(length(fNames), length(fArgs))))  then
    exit (new PropertyValue(PropertyAttributes.Writable or PropertyAttributes.Configurable, fExecutionScope.LexicalScope.GetBindingValue(fNames[lIndex], false)));

  exit inherited;
end;


method EcmaScriptArgumentObject.DefineOwnProperty(aName: String;  aValue: PropertyValue;  aThrow: Boolean): Boolean;
begin
  var lIndex: Int32;
  if  (not fStrict  and  Int32.TryParse(aName, out lIndex))  then  begin
    if  (lIndex < Math.Min(length(fNames), length(fArgs)))  then  begin
      self.fExecutionScope.LexicalScope.SetMutableBinding(self.fNames[lIndex], aValue.Value, aThrow);
      exit  (true);
    end;

    if  ((lIndex < length(self.fArgs))  and  (PropertyAttributes.HasValue in aValue.Attributes))  then  begin
      self.fArgs[lIndex] := aValue.Value;
      exit  (true);
    end;

    exit  (true);
  end;

  exit inherited;
end;


method EcmaScriptArgumentObject.Delete(aName: String; aThrow: Boolean): Boolean;
begin
  var n: Int32;
  if  (Int32.TryParse(aName, out n))  then  begin
    if  (n < length(fArgs))  then  begin
      self.fArgs[n] := Undefined.Instance;
      exit  (true);
    end;
  end;

  exit inherited Delete(aName, aThrow);
end;


end.