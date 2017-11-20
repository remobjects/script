//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;


type
  NativeErrorType = public enum (EvalError, RangeError, ReferenceError, SyntaxError, TypeError, URIError);
  GlobalObject = public partial class(EcmaScriptObject)
  public
    method CreateError: EcmaScriptObject;
    method ErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method EvalErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method RangeErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ReferenceErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method SyntaxErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method TypeErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method URIErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ErrorToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method CreateNativeError: EcmaScriptObject;
    
    property EvalError: EcmaScriptObject;
    property RangeError: EcmaScriptObject;
    property ReferenceError: EcmaScriptObject;
    property SyntaxError: EcmaScriptObject;
    property TypeError: EcmaScriptObject;
    property URIError: EcmaScriptObject;

    method NativeErrorCtor(proto: EcmaScriptObject; arg: String): EcmaScriptObject;

    method RaiseNativeError(e: NativeErrorType; msg: String);
    class var Method_RaiseNativeError: System.Reflection.MethodInfo := typeOf(GlobalObject).GetMethod('RaiseNativeError'); readonly;
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
  ErrorPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  ErrorPrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(ErrorPrototype);
  ErrorPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @ErrorToString, 0)));
  ErrorPrototype.Values.Add('name', PropertyValue.NotEnum("Error"));
  ErrorPrototype.Values.Add('message', PropertyValue.NotEnum(""));
  //result.Prototype := ErrorPrototype;
end;

method GlobalObject.ErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lUndef := (0 = length(args)) or (args[0] = Undefined.Instance);
  var lMessage := if lUndef then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  if (lObj = nil) or (lObj.Class <> 'Error') then 
    lObj := new EcmaScriptObject(self, ErrorPrototype, &Class := 'Error');
  if not lUndef then
  lObj.AddValue('message', lMessage);
  exit lObj;
end;

method GlobalObject.ErrorToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lSelf := Utilities.GetObjAsEcmaScriptObject(aSelf, aCaller);
  var lMsg := if lSelf.Get(aCaller, 0, 'message') = nil then nil else Utilities.GetObjAsString(lSelf.Get(aCaller, 0, 'message'), aCaller);
  var lName := coalesce(Utilities.GetObjAsString(lSelf.Get(aCaller, 0, 'name'), aCaller), 'Error');
  if String.IsNullOrEmpty(lMsg) then
    exit lName

  else
    exit lName+': '+lMsg;
end;

method GlobalObject.CreateNativeError: EcmaScriptObject;
begin
  EvalError := new EcmaScriptExceptionFunctionObject(self, 'EvalError', @EvalErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('EvalError', PropertyValue.NotEnum(EvalError));

  var lPrototype := new EcmaScriptObject(self, &Class := 'EvalError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(EvalError));
  lPrototype.Prototype := ErrorPrototype;
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('EvalError');
  EvalError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  //EvalError.Prototype := lPrototype;

  
  RangeError := new EcmaScriptExceptionFunctionObject(self, 'RangeError', @RangeErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('RangeError', PropertyValue.NotEnum(RangeError));
  

  lPrototype := new EcmaScriptObject(self, &Class := 'RangeError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(RangeError));
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('RangeError');
  lPrototype.Prototype := ErrorPrototype;
  RangeError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  //RangeError.Prototype := lPrototype;

  ReferenceError := new EcmaScriptExceptionFunctionObject(self, 'ReferenceError', @ReferenceErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('ReferenceError', PropertyValue.NotEnum(ReferenceError));
    
  lPrototype := new EcmaScriptObject(self, &Class := 'ReferenceError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('ReferenceError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(ReferenceError));
  lPrototype.Prototype := ErrorPrototype;
  ReferenceError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  //ReferenceError.Prototype := lPrototype;

  SyntaxError := new EcmaScriptExceptionFunctionObject(self, 'SyntaxError', @SyntaxErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('SyntaxError', PropertyValue.NotEnum(SyntaxError));
  
  lPrototype := new EcmaScriptObject(self, &Class := 'SyntaxError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('SyntaxError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(SyntaxError));
  lPrototype.Prototype := ErrorPrototype;
  SyntaxError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  //SyntaxError.Prototype := lPrototype;

  TypeError := new EcmaScriptExceptionFunctionObject(self, 'TypeError', @TypeErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('TypeError', PropertyValue.NotEnum(TypeError));
  
  lPrototype := new EcmaScriptObject(self, &Class := 'TypeError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('TypeError');
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(TypeError));
  lPrototype.Prototype := ErrorPrototype;
  TypeError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  //TypeError := lPrototype;
  
  URIError := new EcmaScriptExceptionFunctionObject(self, 'URIError', @URIErrorCtor, 1, Prototype := ErrorPrototype);
  Values.Add('URIError', PropertyValue.NotEnum(URIError));
  
  lPrototype := new EcmaScriptObject(self, &Class := 'URIError');
  lPrototype.Values['name'] := PropertyValue.NotDeleteAndReadOnly('URIError');  
  lPrototype.Values.Add('constructor', PropertyValue.NotEnum(URIError));
  lPrototype.Prototype := ErrorPrototype;
  URIError.Values['prototype'] := PropertyValue.NotAllFlags(lPrototype);
  //URIError.Prototype := lPrototype;
end;


method GlobalObject.RaiseNativeError(e: NativeErrorType; msg: String);
begin
  case e of
    NativeErrorType.EvalError:      raise new ScriptRuntimeException(EvalErrorCtor(fExecutionContext, nil, msg));
    NativeErrorType.RangeError:     raise new ScriptRuntimeException(RangeErrorCtor(fExecutionContext, nil, msg));
    NativeErrorType.ReferenceError: raise new ScriptRuntimeException(ReferenceErrorCtor(fExecutionContext, nil, msg));
    NativeErrorType.SyntaxError:    raise new ScriptRuntimeException(SyntaxErrorCtor(fExecutionContext, nil, msg));
    NativeErrorType.TypeError:      raise new ScriptRuntimeException(TypeErrorCtor(fExecutionContext, nil, msg));
    NativeErrorType.URIError:       raise new ScriptRuntimeException(URIErrorCtor(fExecutionContext, nil, msg));
    else                            raise ErrorCtor(nil, nil, [ 'Unknown' ]);
  end;
end;


method GlobalObject.NativeErrorCtor(proto: EcmaScriptObject; arg: String): EcmaScriptObject;
begin
  var lMessage := arg;
  result := new EcmaScriptObject(self, proto, &Class := proto.Class);
  EcmaScriptObject(result).AddValue('message', lMessage);
end;

method GlobalObject.EvalErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lUndef := (0 = length(args)) or (args[0] = Undefined.Instance);
  var lMessage := if lUndef then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  if (lObj = nil) or (lObj.Class <> 'EvalError') then 
    lObj := new EcmaScriptObject(self, EcmaScriptObject(EvalError.Values['prototype'].Value), &Class := 'EvalError');
  if not lUndef then
  lObj.AddValue('message', lMessage);
  exit lObj;
end;

method GlobalObject.RangeErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lUndef := (0 = length(args)) or (args[0] = Undefined.Instance);
  var lMessage := if lUndef then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  if (lObj = nil) or (lObj.Class <> 'RangeError') then 
    lObj := new EcmaScriptObject(self, EcmaScriptObject(RangeError.Values['prototype'].Value), &Class := 'RangeError');
  if not lUndef then
  lObj.AddValue('message', lMessage);
  exit lObj;
end;

method GlobalObject.ReferenceErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lUndef := (0 = length(args)) or (args[0] = Undefined.Instance);
  var lMessage := if lUndef then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  if (lObj = nil) or (lObj.Class <> 'ReferenceError') then 
    lObj := new EcmaScriptObject(self, EcmaScriptObject(ReferenceError.Values['prototype'].Value), &Class := 'ReferenceError');
  if not lUndef then
  lObj.AddValue('message', lMessage);
  exit lObj;
end;

method GlobalObject.SyntaxErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lUndef := (0 = length(args)) or (args[0] = Undefined.Instance);
  var lMessage := if lUndef then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  if (lObj = nil) or (lObj.Class <> 'SyntaxError') then 
    lObj := new EcmaScriptObject(self, EcmaScriptObject(SyntaxError.Values['prototype'].Value), &Class := 'SyntaxError');
  if not lUndef then
  lObj.AddValue('message', lMessage);
  exit lObj;
end;

method GlobalObject.TypeErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lUndef := (0 = length(args)) or (args[0] = Undefined.Instance);
  var lMessage := if lUndef then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  if (lObj = nil) or (lObj.Class <> 'TypeError') then 
    lObj := new EcmaScriptObject(self, EcmaScriptObject(TypeError.Values['prototype'].Value), &Class := 'TypeError');
  if not lUndef then
  lObj.AddValue('message', lMessage);
  exit lObj;
end;

method GlobalObject.URIErrorCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lUndef := (0 = length(args)) or (args[0] = Undefined.Instance);
  var lMessage := if lUndef then nil else Utilities.GetArgAsString(args, 0, aCaller);
  var lObj := EcmaScriptObject(aSelf);
  if (lObj = nil) or (lObj.Class <> 'URIError') then 
    lObj := new EcmaScriptObject(self, EcmaScriptObject(URIError.Values['prototype'].Value), &Class := 'URIError');
  if not lUndef then
  lObj.AddValue('message', lMessage);
  exit lObj;
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
