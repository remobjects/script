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
    fExecutionScope: ExecutionContext;
    fCaller: EcmaScriptFunctionObject;
    fStrict: Boolean;
    fNames: array of string;
    fArgs: array of Object;
  public
    constructor(ex: ExecutionContext; aArgs: array of Object; aArgNames: array of string; aCaller: EcmaScriptFunctionObject; aStrict: Boolean);
    property Map: EcmaScriptObject;
    class var &Constructor: System.Reflection.ConstructorInfo := typeof (EcmaScriptArgumentObject).GetConstructors()[0]; readonly;

    method Get(aExecutionContext: ExecutionContext; aFlags: Integer; aName: String): Object; override;
    method GetOwnProperty(aName: String): PropertyValue; override;
    method DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean; override;
    method Delete(aName: String; aThrow: Boolean): Boolean; override;
  end;
  
implementation

constructor EcmaScriptArgumentObject(ex: ExecutionContext; aArgs: array of Object; aArgNames: array of string; aCaller: EcmaScriptFunctionObject; aStrict: Boolean);
begin
  inherited constructor(ex.Global, ex.Global.ObjectPrototype);
  &Class := 'Arguments';
  fCaller := aCaller;
  fExecutionScope := ex;
  DefineOwnProperty('length', new PropertyValue(PropertyAttributes.Configurable or PropertyAttributes.writable, Length(aArgs)));
  if aStrict then begin
    DefineOwnProperty('caller', new PropertyValue(PropertyAttributes.None, ex.Global.Thrower));
    DefineOwnProperty('callee', new PropertyValue(PropertyAttributes.None, ex.Global.Thrower));
  end else begin
    DefineOwnProperty('callee', new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, aCaller));
  end;
  fArgs := aArgs;
  fNames := aArgNames;
  fStrict := aStrict;
end;

method EcmaScriptArgumentObject.Get(aExecutionContext: ExecutionContext; aFlags: Integer; aName: String): Object;
begin
  var lIndex: Integer;
  if not fStrict and Int32.TryParse(aname, out lIndex) then begin
    if (lIndex < Math.Min(Length(fNames), Length(fArgs))) then
      exit fExecutionScope.LexicalScope.GetBindingValue(fNames[lIndex], false)
    else if lIndex < length(fArgs) then
      exit fArgs[lIndex];
  end;
  exit inherited;
end;

method EcmaScriptArgumentObject.GetOwnProperty(aName: String): PropertyValue;
begin
  var lIndex: Integer;
  if not fStrict and Int32.TryParse(aname, out lIndex) and (lIndex < Math.Min(Length(fNames), Length(fArgs))) then begin
    exit new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, fExecutionScope.LexicalScope.GetBindingValue(fNames[lIndex], false));
  end;
  exit inherited;
end;

method EcmaScriptArgumentObject.DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean;
begin
  var lIndex: Integer;
  if not fStrict and Int32.TryParse(aname, out lIndex) then begin
    if lIndex < Math.Min(Length(fNames), Length(fArgs)) then begin
      fExecutionScope.LexicalScope.SetMutableBinding(fnames[lIndex], aValue.Value, aThrow);
      exit true;
    end else if (lIndex < length(fArgs)) and (PropertyAttributes.HasValue in aValue.Attributes) then begin
      fArgs[lIndex] := aValue.Value;
      exit true;
    end;
    exit true;
  end;
  exit inherited;
end;


method EcmaScriptArgumentObject.Delete(aName: String; aThrow: Boolean): Boolean;
begin
  var n: Integer;
  if Int32.TryParse(aName, out n) then begin
    if n < length(fArgs) then begin
      fArgs[n] := Undefined.Instance;
      exit true;
    end;
  end;

  inherited Delete(aName, aThrow);
end;

end.
