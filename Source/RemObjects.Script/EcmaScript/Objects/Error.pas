{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  Microsoft,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;


type
  NativeErrorType = public enum (EvalError, RangeError, ReferenceError, SyntaxError, TypeError, URIError);
  GlobalObject = public partial class(EcmaScriptObject)
  public
    method CreateError: EcmaScriptObject;
    method ErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ErrorToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method CreateNativeError: EcmaScriptObject;
    
    property EvalError: EcmaScriptObject;
    property RangeError: EcmaScriptObject;
    property ReferenceError: EcmaScriptObject;
    property SyntaxError: EcmaScriptObject;
    property TypeError: EcmaScriptObject;
    property URIError: EcmaScriptObject;

    method NativeErrorCtor(proto: EcmaScriptObject; arg: string): EcmaScriptObject;

    method RaiseNativeError(e: NativeErrorType; msg: string);
    class var Method_RaiseNativeError: System.Reflection.MethodInfo := typeof(GlobalObject).GetMethod('RaiseNativeError'); readonly;
  end;  
implementation

method GlobalObject.CreateError: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 'Error'));
  if result <> nil then exit;

  result := new EcmaScriptFunctionObject(self, 'Error', @ErrorCtor, 1, &Class := 'Error');
  Values.Add('Error', PropertyValue.NotEnum(Result));

  ErrorPrototype := new EcmaScriptFunctionObject(self, 'Error', @ErrorCtor, 1, &Class := 'Error');
  ErrorPrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(ErrorPrototype);
  ErrorPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @ErrorToString, 0)));
  ErrorPrototype.Values.Add('name', PropertyValue.NotEnum("Error"));
  ErrorPrototype.Values.Add('message', PropertyValue.NotEnum(""));
  result.Prototype := ErrorPrototype;
end;

method GlobalObject.ErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lMessage := if 0 = Length(args) then nil else Utilities.GetArgAsString(args, 0);
  result := new EcmaScriptObject(self, ErrorPrototype, &Class := 'Error');
  EcmaScriptObject(result).AddValue('message', lMessage);
end;

method GlobalObject.ErrorToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lSelf := Utilities.GetObjAsEcmaScriptObject(aSelf);
  var lMsg := if lSelf.Get(aCaller, 'message') = nil then nil else Utilities.GetObjAsString(lSelf.Get(aCaller, 'message'));
  var lName := coalesce(Utilities.GetObjAsString(lSelf.Get(aCaller, 'name')), 'Error');
  if STring.IsNullOrEmpty(lMsg) then
    exit lName

  else
    exit lName+': '+lMsg;
end;

method GlobalObject.CreateNativeError: EcmaScriptObject;
begin
  EvalError := new EcmaScriptFunctionObject(self, 'EvalError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  EvalError.Values['name'] := PropertyValue.NotDeleteAndReadOnly('EvalError');
  Values.Add('EvalError', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'EvalError', @ErrorCtor, 1, Prototype := EvalError)));
  
  RangeError := new EcmaScriptFunctionObject(self, 'RangeError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  RangeError.Values['name'] := PropertyValue.NotDeleteAndReadOnly('RangeError');
  Values.Add('RangeError', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'RangeError', @ErrorCtor, 1, Prototype := RangeError)));
  
  ReferenceError := new EcmaScriptFunctionObject(self, 'ReferenceError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  ReferenceError.Values['name'] := PropertyValue.NotDeleteAndReadOnly('ReferenceError');
  Values.Add('ReferenceError', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'ReferenceError', @ErrorCtor, 1, Prototype := ReferenceError)));
    
  SyntaxError := new EcmaScriptFunctionObject(self, 'SyntaxError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  SyntaxError.Values['name'] := PropertyValue.NotDeleteAndReadOnly('SyntaxError');
  Values.Add('SyntaxError', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'SyntaxError', @ErrorCtor, 1, Prototype := SyntaxError)));
  
  TypeError := new EcmaScriptFunctionObject(self, 'TypeError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  TypeError.Values['name'] := PropertyValue.NotDeleteAndReadOnly('TypeError');
  Values.Add('TypeError', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'TypeError', @ErrorCtor, 1, Prototype := TypeError)));
  
  URIError := new EcmaScriptFunctionObject(self, 'URIError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  URIError.Values['name'] := PropertyValue.NotDeleteAndReadOnly('URIError');  
  Values.Add('URIError', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'URIError', @ErrorCtor, 1, Prototype := URIError)));
  
end;


method GlobalObject.RaiseNativeError(e: NativeErrorType; msg: string);
begin
  case e of
    NativeErrorType.EvalError: raise new ScriptRuntimeException(NativeErrorCtor(EvalError, msg));
    NativeErrorType.RangeError: raise new ScriptRuntimeException(NativeErrorCtor(RangeError, msg));
    NativeErrorType.ReferenceError: raise new ScriptRuntimeException(NativeErrorCtor(ReferenceError, msg));
    NativeErrorType.SyntaxError: raise new ScriptRuntimeException(NativeErrorCtor(SyntaxError, msg));
    NativeErrorType.TypeError: raise new ScriptRuntimeException(NativeErrorCtor(TypeError, msg));
    NativeErrorType.URIError: raise new ScriptRuntimeException(NativeErrorCtor(URIError, msg));
  else
    raise ErrorCtor(nil, nil, ['Unknown']);
  end; // case
  
end;


method GlobalObject.NativeErrorCtor(proto: EcmaScriptObject; arg: string): EcmaScriptObject;
begin
  var lMessage := Utilities.GetObjAsString(arg);
  result := new EcmaScriptObject(self, proto, &Class := 'Error');
  EcmaScriptObject(result).AddValue('message', lMessage);
end;

end.
