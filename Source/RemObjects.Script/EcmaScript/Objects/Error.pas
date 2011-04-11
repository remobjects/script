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

  EcmaScriptExceptionFunctionObject = class(EcmaScriptFunctionObject)
  private
  public
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;
  end;
implementation

method GlobalObject.CreateError: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Error'));
  if result <> nil then exit;

  result := new EcmaScriptExceptionFunctionObject(self, 'Error', @ErrorCtor, 1, &Class := 'Error');
  Values.Add('Error', PropertyValue.NotEnum(Result));

  ErrorPrototype := new EcmaScriptObject(self, &Class := 'Error'); 
  ErrorPrototype.values.Add('constructor', PropertyValue.NotEnum(result));
  ErrorPrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(ErrorPrototype);
  ErrorPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @ErrorToString, 0)));
  ErrorPrototype.Values.Add('name', PropertyValue.NotEnum("Error"));
  ErrorPrototype.Values.Add('message', PropertyValue.NotEnum(""));
  result.Prototype := ErrorPrototype;
end;

method GlobalObject.ErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lMessage := if 0 = Length(args) then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  lObj.AddValue('message', lMessage);
  exit lObj;
end;

method GlobalObject.ErrorToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lSelf := Utilities.GetObjAsEcmaScriptObject(aSelf, aCaller);
  var lMsg := if lSelf.Get(aCaller, 0, 'message') = nil then nil else Utilities.GetObjAsString(lSelf.Get(aCaller, 0, 'message'), aCaller);
  var lName := coalesce(Utilities.GetObjAsString(lSelf.Get(aCaller, 0, 'name'), aCaller), 'Error');
  if STring.IsNullOrEmpty(lMsg) then
    exit lName

  else
    exit lName+': '+lMsg;
end;

method GlobalObject.CreateNativeError: EcmaScriptObject;
begin
  EvalError := new EcmaScriptExceptionFunctionObject(self, 'EvalError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('EvalError', PropertyValue.NotEnum(EvalError));

  var lPrototype := new EcmaScriptObject(self, &Class := 'EvalError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  lPrototype.Prototype := ErrorPrototype;
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('EvalError');
  EvalError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  EvalError.Prototype := lPrototype;

  
  RangeError := new EcmaScriptExceptionFunctionObject(self, 'RangeError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('RangeError', PropertyValue.NotEnum(RangeError));
  

  lPrototype := new EcmaScriptObject(self, &Class := 'RangeError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('RangeError');
  lPrototype.Prototype := ErrorPrototype;
  RangeError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  RangeError.Prototype := lPrototype;

  ReferenceError := new EcmaScriptExceptionFunctionObject(self, 'ReferenceError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('ReferenceError', PropertyValue.NotEnum(ReferenceError));
    
  lPrototype := new EcmaScriptObject(self, &Class := 'ReferenceError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('ReferenceError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  lPrototype.Prototype := ErrorPrototype;
  ReferenceError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  ReferenceError.Prototype := lPrototype;

  SyntaxError := new EcmaScriptExceptionFunctionObject(self, 'SyntaxError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('SyntaxError', PropertyValue.NotEnum(SyntaxError));
  
  lPrototype := new EcmaScriptObject(self, &Class := 'SyntaxError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('SyntaxError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  lPrototype.Prototype := ErrorPrototype;
  SyntaxError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  SyntaxError.Prototype := lPrototype;

  TypeError := new EcmaScriptExceptionFunctionObject(self, 'TypeError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('TypeError', PropertyValue.NotEnum(TypeError));
  
  lPrototype := new EcmaScriptObject(self, &Class := 'TypeError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('TypeError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  lPrototype.Prototype := ErrorPrototype;
  TypeError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  TypeError := lPrototype;
  
  URIError := new EcmaScriptExceptionFunctionObject(self, 'URIError', @ErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('URIError', PropertyValue.NotEnum(URIError));
  
  lPrototype := new EcmaScriptObject(self, &Class := 'URIError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('URIError');  
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  lPrototype.Prototype := ErrorPrototype;
  URIError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  URIError.Prototype := lPrototype;
end;


method GlobalObject.RaiseNativeError(e: NativeErrorType; msg: string);
begin
  case e of
    NativeErrorType.EvalError: raise new ScriptRuntimeException(NativeErrorCtor(EvalError, msg));
    NativeErrorType.RangeError: raise new ScriptRuntimeException(NativeErrorCtor(RangeError, msg));
    NativeErrorType.ReferenceError: 
      begin
        raise new ScriptRuntimeException(NativeErrorCtor(ReferenceError, msg));
      end;
    NativeErrorType.SyntaxError: raise new ScriptRuntimeException(NativeErrorCtor(SyntaxError, msg));
    NativeErrorType.TypeError: raise new ScriptRuntimeException(NativeErrorCtor(TypeError, msg));
    NativeErrorType.URIError: raise new ScriptRuntimeException(NativeErrorCtor(URIError, msg));
  else
    raise ErrorCtor(nil, nil, ['Unknown']);
  end; // case
  
end;


method GlobalObject.NativeErrorCtor(proto: EcmaScriptObject; arg: string): EcmaScriptObject;
begin
  var lMessage := arg;
  result := new EcmaScriptObject(self, proto, &Class := proto.Class);
  EcmaScriptObject(result).AddValue('message', lMessage);
end;

method EcmaScriptExceptionFunctionObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  exit Construct(context, args);
end;

method EcmaScriptExceptionFunctionObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit Construct(context, args);
end;

end.
