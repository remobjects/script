namespace RemObjects.Script.EcmaScript;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  EcmaScriptArgumentObject = class(EcmaScriptObject)
  public
    constructor(ex: ExecutionContext; aArgs: array of Object; aCaller: EcmaScriptFunctionObject; aStrict: Boolean);
    //eecution context, object[], function

    class var &Constructor: System.Reflection.ConstructorInfo := typeof (EcmaScriptArgumentObject).GetConstructors()[0];
  end;
  
implementation

constructor EcmaScriptArgumentObject(ex: ExecutionContext; aArgs: array of Object; aCaller: EcmaScriptFunctionObject; aStrict: Boolean);
begin
  inherited constructor(ex.Global, ex.Global.ObjectPrototype);
  &Class := 'Arguments';
  DefineOwnProperty('length', new PropertyValue(PropertyAttributes.Configurable or PropertyAttributes.writable, Length(aArgs)));
  if aStrict then begin
    DefineOwnProperty('caller', new PropertyValue(PropertyAttributes.None, ex.Global.Thrower));
    DefineOwnProperty('callee', new PropertyValue(PropertyAttributes.None, ex.Global.Thrower));
  end else begin
    DefineOwnProperty('callee', new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, aCaller));
  end;
  // Implement page 60 logic here!
end;

end.
