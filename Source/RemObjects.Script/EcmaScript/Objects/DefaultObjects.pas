{
  Copyright (c) 2009-2013 RemObjects Software, LLC.
  See LICENSE.txt for more details.
}

namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Runtime.CompilerServices,
  System.Text,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;

type
  Undefined = public class 
  private
    class var fInstance: Undefined := new Undefined;
    constructor; empty;
  public
    class property Instance: Undefined read fInstance;
    method ToString: String; override;

    class var Method_Instance: System.Reflection.MethodInfo := typeOf(Undefined).GetMethod('get_Instance'); readonly;
  end;


  GlobalObject = public partial class(EcmaScriptObject)
  private
    var fExecutionContext: ExecutionContext;
    var fDebug: IDebugSink;

    method get_ExecutionContext: ExecutionContext;
    method get_Debug: IDebugSink;

  assembly
    fParser: EcmaScriptCompiler;
    fDelegates: List<InternalFunctionDelegate> := new List<InternalFunctionDelegate>;

  public
    constructor(aParser: EcmaScriptCompiler);
    constructor();

    property ExecutionContext: ExecutionContext read get_ExecutionContext write fExecutionContext;

    property MaxFrames: Integer := 1024;
    property FrameCount: Integer;
    method IncreaseFrame;
    method DecreaseFrame;

    class var Method_IncreaseFrame: System.Reflection.MethodInfo := typeOf(GlobalObject).GetMethod('IncreaseFrame'); readonly;
    class var Method_DecreaseFrame: System.Reflection.MethodInfo := typeOf(GlobalObject).GetMethod('DecreaseFrame'); readonly;

    method StoreFunction(aDelegate: InternalFunctionDelegate): Integer;
    class var Method_GetFunction: System.Reflection.MethodInfo := typeOf(GlobalObject).GetMethod('GetFunction'); readonly;
    method GetFunction(i: Integer): InternalFunctionDelegate;

    property Parser: EcmaScriptCompiler read fParser write fParser;

    property Debug: IDebugSink read get_Debug write fDebug;

    property FunctionPrototype: EcmaScriptObject;
    property ObjectPrototype: EcmaScriptObject;
    property ArrayPrototype: EcmaScriptObject;
    property NumberPrototype: EcmaScriptObject;
    property StringPrototype: EcmaScriptObject;
    property DatePrototype: EcmaScriptObject;
    property BooleanPrototype: EcmaScriptObject;
    property RegExpPrototype:EcmaScriptObject;
    property ErrorPrototype:EcmaScriptObject;
    property Thrower: EcmaScriptFunctionObject;
    property NativePrototype: EcmaScriptObject;
    property NotStrictGlobalEvalFunc: EcmaScriptFunctionObject;
    method NativeToString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method eval(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method NotStrictGlobalEval(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;

    method InnerExecutionContext(caller: ExecutionContext;  strict: Boolean): ExecutionContext;
    method InnerCompile(strict: Boolean;  script: String): InternalDelegate;
    method InnerEval(caller: ExecutionContext;  strict: Boolean;  &self: Object;  params args: array of Object): Object;
    method InnerEval(caller: ExecutionContext;  strict: Boolean;  &self: Object;  evalDelegate: InternalDelegate): Object;
    method InnerEval(strict: Boolean;  params args: array of Object): Object;
    method InnerEval(strict: Boolean;  evalDelegate: InternalDelegate): Object;

    method parseInt(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method parseFloat(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method isNaN(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method isFinite(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method escape(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method unescape(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method encodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method decodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method encodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method decodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;

    // Proto:
    method ObjectToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectToLocaleString(aCaller: ExecutionContext; aSelf: Object; params args: Array of Object): Object;
    method ObjectValueOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectIsPrototypeOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectHasOwnProperty(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectPropertyIsEnumerable(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;

    // Static:
    method ObjectgetPrototypeOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectgetOwnPropertyDescriptor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectgetOwnPropertyNames(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectCreate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectdefineProperty(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectdefineProperties(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectSeal(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectFreeze(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectPreventExtensions(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectisSealed(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectisFrozen(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectisExtensible(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectKeys(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;

    method CreateObject: EcmaScriptObject;
    method ToString: String; override;
  end;


  EcmaScriptEvalFunctionObject = class(EcmaScriptFunctionObject);


  EcmaScriptObjectObject = class(EcmaScriptBaseFunctionObject)
  public
    constructor(aOwner: GlobalObject; aName: String);

    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
  end;


implementation

constructor GlobalObject(aParser: EcmaScriptCompiler);
begin
  inherited constructor(nil, nil);
  Root := self;
  fParser := aParser;
  Values.Add('NaN', PropertyValue.NotAllFlags(Double.NaN));
  Values.Add('Infinity', PropertyValue.NotAllFlags(Double.PositiveInfinity));
  Values.Add('undefined', PropertyValue.NotAllFlags(Undefined.Instance));

  CreateObject;
  CreateFunction;
  CreateMath;
  CreateArray;
  CreateNumber;
  CreateDate;
  CreateString;
  CreateBoolean;
  CreateRegExp;
  CreateError;
  CreateNativeError;
  CreateJSON;

  self.Prototype := ObjectPrototype;

  Thrower := new EcmaScriptFunctionObject(self, 'ThrowTypeError', method begin
    RaiseNativeError(NativeErrorType.TypeError, 'caller/arguments not available in strict mode')
  end, 0, false);

  NotStrictGlobalEvalFunc := new EcmaScriptEvalFunctionObject(self, 'eval', @NotStrictGlobalEval, 1);
  // Add function prototype here first!
  Values.Add('eval', PropertyValue.NotEnum(new EcmaScriptEvalFunctionObject(self, 'eval', @eval, 1)));
  Values.Add('parseInt', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parseInt', @parseInt, 2)));
  Values.Add('parseFloat', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parseFloat', @parseFloat, 1)));
  Values.Add('isNaN', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isNaN', @isNaN, 1)));
  Values.Add('isFinite', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isFinite', @isFinite, 1)));
  Values.Add('decodeURI', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'decodeURI', @decodeURI, 1)));
  Values.Add('encodeURI', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'encodeURI', @encodeURI, 1)));
  Values.Add('escape', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'escape', @escape, 1)));
  Values.Add('unescape', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'unescape', @unescape, 1)));
  Values.Add('decodeURIComponent', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'decodeURIComponent', @decodeURIComponent, 1)));
  Values.Add('encodeURIComponent', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'encodeURIComponent', @encodeURIComponent, 1)));

  NativePrototype := new EcmaScriptObject(self);
  NativePrototype.Extensible := false;
  NativePrototype.Values['toString'] := new PropertyValue(PropertyAttributes.None, new EcmaScriptFunctionObject(self, 'toString', @NativeToString, 0));
end;


method GlobalObject.eval(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit InnerEval(aCaller, true, aSelf, args); // strict; this is called through the 
end;


method GlobalObject.InnerExecutionContext(caller: ExecutionContext;  strict: Boolean): ExecutionContext;
begin
  if caller.Strict or strict then
    exit new ExecutionContext(new DeclarativeEnvironmentRecord(caller.LexicalScope, self), true);

  exit caller;
end;


method GlobalObject.InnerCompile(strict: Boolean;  script: String): InternalDelegate;
begin
  if String.IsNullOrEmpty(script) then
    exit nil;

  var lTokenizer: Tokenizer := new Tokenizer();
  var lParser: Parser := new Parser();
  lTokenizer.Error += lParser.fTok_Error;
  lTokenizer.SetData(script, '<eval>');
  lTokenizer.Error -= lParser.fTok_Error;

  try
    var lElement: ProgramElement := lParser.Parse(lTokenizer);
    for each el in lParser.Messages do begin
      if el.IsError then 
        RaiseNativeError(NativeErrorType.SyntaxError, el.ToString());// this will reveal real error
    end;

    exit InternalDelegate(fParser.EvalParse(strict, script));
  except
    on e: ScriptParsingException do
      RaiseNativeError(NativeErrorType.SyntaxError, e.Message);
  end;
end;


method GlobalObject.InnerEval(caller: ExecutionContext;  strict: Boolean;  &self: Object;  params args: array of Object): Object;
begin
  if (args.Length < 0) or (args[0] is not String) then
    exit iif(args.Length=0,Undefined.Instance,args[0]);

  var lScript: String := String(args[0]);

  var lContext: ExecutionContext := self.InnerExecutionContext(caller, strict);
  var lEval: InternalDelegate := self.InnerCompile(lContext.Strict, lScript);

  exit lEval(lContext, &self, []);
end;


method GlobalObject.InnerEval(caller: ExecutionContext;  strict: Boolean;  &self: Object;  evalDelegate: InternalDelegate): Object;
begin
  if not assigned(evalDelegate) then
    exit Undefined.Instance;

  var lContext: ExecutionContext := self.InnerExecutionContext(caller, strict);

  exit evalDelegate(lContext, &self, []);
end;


method GlobalObject.InnerEval(strict: Boolean;  params args: array of Object): Object;
begin
  exit InnerEval(self.ExecutionContext, strict, self, args);
end;


method GlobalObject.InnerEval(strict: Boolean;  evalDelegate: InternalDelegate): Object;
begin
  exit InnerEval(self.ExecutionContext, strict, self, evalDelegate);
end;


method GlobalObject.parseInt(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lVal: String;
  var lRadix: Integer;
  if length(args) < 1 then 
    lVal := '0'
  else begin
    lVal := Utilities.GetArgAsString(args, 0, aCaller);
    if length(args) < 2 then
      lRadix := 0
    else if (args[1] = nil) or (args[1] = Undefined.Instance) then 
      lRadix := 0
    else 
      lRadix := Utilities.GetArgAsInteger(args, 1, aCaller);
  end;
  var lSign: Integer := 1;
  lVal := lVal.Trim();
  if lVal.StartsWith('-') then begin
    lSign := -1;
    lVal := lVal.Substring(1);
  end else if lVal.StartsWith('+') then
    lVal := lVal.Substring(1);

  if (lRadix = 0) or (lRadix = 16) then
    if lVal.StartsWith('0x', StringComparison.InvariantCultureIgnoreCase) then begin lRadix := 16; lVal := lVal.Substring(2); end;
  if lRadix = 0 then lRadix := 10;
  if (lRadix < 2) or (lRadix > 36) then exit Double.NaN;
  for i: Integer := 0 to lVal.Length -1 do begin
    var n := BaseString.IndexOf(lVal[i], 0, lRadix, StringComparison.OrdinalIgnoreCase);
    if (n < 0) then begin
      lVal := lVal.Substring(0, i);
      break;
    end;
  end;
  if lVal = '' then Exit Double.NaN;

  var lRes: Int64;
  (*
  if lRadix = 10 then begin
    if Length(lVal) <= 20 then begin
      if not Int64.TryParse(lVal, System.Globalization.NumberStyles.Integer, System.Globalization.NumberFormatInfo.InvariantInfo, out lRes) then 
       exit Double.NaN;
       exit lSign * lRes;
     end;
  end else if lRadix = 16 then begin
    if Length(lVal) <= 16 then begin
      if not Int64.TryParse(lVal, System.Globalization.NumberStyles.HexNumber, System.Globalization.NumberFormatInfo.InvariantInfo, out lRes) then 
       exit Double.NaN;
      exit lSign * lRes;
    end;
  end;*)
  var lResD: Double := 0.0;

  lResD := 0;
  for i: Integer := 0 to lVal.Length -1 do begin
    var n := BaseString.IndexOf(lVal[i], 0, lRadix, StringComparison.InvariantCultureIgnoreCase);
    lResD := lResD * lRadix + n;
  end;
  exit lSign * lResD;
end;

method GlobalObject.parseFloat(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lVal := Utilities.GetArgAsString(args, 0, aCaller);
  result := Utilities.ParseDouble(lVal, false);
end;

method GlobalObject.isNaN(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit Double.IsNaN(Utilities.GetArgAsDouble(args, 0, aCaller));
end;

method GlobalObject.isFinite(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lVal := Utilities.GetArgAsDouble(args, 0, aCaller);
  exit not Double.IsInfinity(lVal) and not Double.IsNaN(lVal);
end;



method GlobalObject.ObjectToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := EcmaScriptObject(aSelf);
  if lValue = nil then result := '[object null]' else result := '[object '+lValue.Class+']';
end;

method GlobalObject.ObjectValueOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := EcmaScriptObject(aSelf);
  if lValue = nil then result := Undefined.Instance else result := coalesce(lValue.Value, lValue);
end;

method GlobalObject.ObjectIsPrototypeOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lThis := Utilities.ToObject(aCaller, aSelf);
  if (args.Length = 0) then exit false;
  var lValue := EcmaScriptObject(args[0]);
  if lValue = nil then exit nil;
  repeat
    lValue := lValue.Prototype;
    if lThis = lValue then exit true;
  until lValue = nil;
  exit false;
end;

method GlobalObject.CreateObject: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Object'));
  if result <> nil then exit;

  ObjectPrototype := new EcmaScriptObject(self);
  CreateFunctionPrototype;

 
  result := new EcmaScriptObjectObject(self, 'Object');
  Values.Add('Object', PropertyValue.NotEnum(Result));

  result.Values['prototype'] := PropertyValue.NotAllFlags(ObjectPrototype);
  result.Values.Add('getPrototypeOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getPrototypeOf', @ObjectgetPrototypeOf, 1)));
  result.Values.Add('getOwnPropertyDescriptor', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getOwnPropertyDescriptor', @ObjectgetOwnPropertyDescriptor, 2)));
  result.Values.Add('getOwnPropertyNames', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getOwnPropertyNames', @ObjectgetOwnPropertyNames, 1)));
  result.Values.Add('create', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'create', @ObjectCreate, 1)));
  result.Values.Add('defineProperty', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'defineProperty', @ObjectdefineProperty, 3)));
  result.Values.Add('defineProperties', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'defineProperties', @ObjectdefineProperties, 3)));
  result.Values.Add('seal', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'seal', @ObjectSeal, 1)));
  result.Values.Add('freeze', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'freeze', @ObjectFreeze, 1)));
  result.Values.Add('preventExtensions', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'preventExtensions', @ObjectPreventExtensions, 1)));
  result.Values.Add('isSealed', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isSealed', @ObjectisSealed, 1)));
  result.Values.Add('isFrozen', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isFrozen', @ObjectisFrozen, 1)));
  result.Values.Add('isExtensible', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isExtensible', @ObjectisExtensible, 1)));
  result.Values.Add('keys', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'keys', @ObjectKeys, 1)));

  ObjectPrototype.Values['constructor'] := PropertyValue.NotEnum(result);

  ObjectPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @ObjectToString, 0, false, true)));
  ObjectPrototype.Values.Add('toLocaleString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleString', @ObjectToLocaleString, 0, false, true)));

  ObjectPrototype.Values.Add('valueOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'valueOf', @ObjectValueOf, 0, false, true)));

  ObjectPrototype.Values.Add('isPrototypeOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isPrototypeOf', @ObjectIsPrototypeOf, 1, false, true)));
  ObjectPrototype.Values.Add('propertyIsEnumerable', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'propertyIsEnumerable', @ObjectPropertyIsEnumerable, 1, false, true)));
  ObjectPrototype.Values.Add('hasOwnProperty', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'hasOwnProperty', @ObjectHasOwnProperty, 1, false, true)));
end;


method GlobalObject.ToString: String;
begin
  result := '[object global]';
end;


constructor GlobalObject;
begin
  constructor(nil);
end;

method GlobalObject.encodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var val := Utilities.GetArgAsString(args, 0, aCaller);
  try
  exit Utilities.UrlEncode(val);
  except
    RaiseNativeError(NativeErrorType.URIError, 'Invalid input');
  end;
end;

method GlobalObject.decodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var val := Utilities.GetArgAsString(args, 0, aCaller);
  try
    result := Utilities.UrlDecode(val, false);
  except
    RaiseNativeError(NativeErrorType.URIError, 'Invalid input');
  end;

  if result = nil then RaiseNativeError(NativeErrorType.URIError, 'Invalid input');
end;

method GlobalObject.encodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var val := Utilities.GetArgAsString(args, 0, aCaller);
  try
    exit Utilities.UrlEncodeComponent(val);  
  except
    RaiseNativeError(NativeErrorType.URIError, 'Invalid input');
  end;

end;

method GlobalObject.decodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var val :=Utilities.GetArgAsString(args, 0, aCaller);
  try
    result := Utilities.UrlDecode(val, true);
  except
    RaiseNativeError(NativeErrorType.URIError, 'Invalid input');
  end;

  if result = nil then RaiseNativeError(NativeErrorType.URIError, 'Invalid input');
end;

method GlobalObject.ObjectgetPrototypeOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  exit lWork.Prototype;
end;

method GlobalObject.ObjectgetOwnPropertyDescriptor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lName := Utilities.GetArgAsString(args, 1, aCaller);


  var lPV: PropertyValue;
  if lWork.Values.TryGetValue(lName, out lPV) then
    exit FromPropertyDescriptor(lPV);
  exit Undefined.Instance;
end;

method GlobalObject.ObjectgetOwnPropertyNames(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lRes := EcmaScriptArrayObject(ArrayCtor(aCaller, 0));
  for each el in lWork.Values.Keys do 
    lRes.AddValue(el);
  exit lRes;
end;

method GlobalObject.ObjectCreate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lRes := new EcmaScriptObject(self, lWork);

  var lArgs := Utilities.GetArgAsEcmaScriptObject(args, 1, aCaller);
  if lArgs <> nil then
    ObjectdefineProperties(aCaller, nil, lRes, lArgs);
  exit lRes;
end;

method GlobalObject.ObjectdefineProperty(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lName := Utilities.GetArgAsString(args, 1, aCaller);
  var lData:= Utilities.GetArgAsEcmaScriptObject(args, 2, aCaller);
  if lData = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lValue := ToPropertyDescriptor(lData);

  lWork.DefineOwnProperty(lName, lValue, true);
  exit lWork;
end;

method GlobalObject.ObjectdefineProperties(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lProps := Utilities.GetArgAsEcmaScriptObject(args, 1, aCaller);
  if lProps = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(Properties) is not Object');
  
  for each el in lProps.Values.Keys do begin
    var lValue := Utilities.GetObjAsEcmaScriptObject(lProps.Get(aCaller, 0, el), aCaller);
    if lValue = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(Element) is not Object');
    lWork.DefineOwnProperty(el, ToPropertyDescriptor(lValue), true);
    
  end;

  exit lWork;
end;

method GlobalObject.ObjectSeal(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  for each el in lWork.Values do
    el.Value.Attributes := el.Value.Attributes and not PropertyAttributes.Enumerable;
  lWork.Extensible := false;

  exit lWork;
end;

method GlobalObject.ObjectFreeze(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  for each el in lWork.Values do
    el.Value.Attributes := el.Value.Attributes and not (PropertyAttributes.Enumerable or PropertyAttributes.Writable);
  lWork.Extensible := false;

  exit lWork;
end;

method GlobalObject.ObjectPreventExtensions(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  lWork.Extensible := false;

  exit lWork;
end;

method GlobalObject.ObjectisSealed(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  if lWork.Extensible then exit false;
  for each el in lWork.Values do
    if PropertyAttributes.Configurable in el.Value.Attributes then exit false;
  exit true;
end;

method GlobalObject.ObjectisFrozen(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  if lWork.Extensible then exit false;
  for each el in lWork.Values do begin
    if 0 <> Integer(PropertyAttributes.Configurable and el.Value.Attributes) then exit false;
    if IsDataDescriptor(el.Value) and (0 <> Integer(PropertyAttributes.Writable and el.Value.Attributes)) then exit false;
  end;
  exit true;
end;

method GlobalObject.ObjectisExtensible(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  exit lWork.Extensible;
end;

method GlobalObject.ObjectKeys(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lResult := new EcmaScriptArrayObject(0, self);
  
  for each el in lWork.Values.Keys do 
    lResult.AddValue(el);
  exit lResult;
end;


method GlobalObject.get_Debug: IDebugSink;
begin
  if fDebug = nil then fDebug := new DebugSink; // dummy one
  exit fDebug;
end;

method GlobalObject.StoreFunction(aDelegate: InternalFunctionDelegate): Integer;
begin
  result := fDelegates.Count;
  fDelegates.Add(aDelegate);
end;

method GlobalObject.GetFunction(i: Integer): InternalFunctionDelegate;
begin
  exit fDelegates[i];
end;

method GlobalObject.NotStrictGlobalEval(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if (aSelf  = Undefined.Instance) or (aSelf = nil) then begin
    aSelf := aCaller.LexicalScope.ImplicitThisValue();
    if (aSelf  = Undefined.Instance) or (aSelf = nil) then
      aSelf := self;
  end;
  exit InnerEval(aCaller, false, aSelf, args);
end;

method GlobalObject.ObjectToLocaleString(aCaller: ExecutionContext; aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetObjAsEcmaScriptObject(aSelf, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'this is not Object');
  var lToString := EcmaScriptFunctionObject(lWork.Get(aCaller, 0, 'toString'));
  if lToString = nil then RaiseNativeError(NativeErrorType.TypeError, 'toString is not callable');
  exit lToString.CallEx(aCaller, aSelf, []);
end;

method GlobalObject.ObjectHasOwnProperty(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetObjAsEcmaScriptObject(aSelf, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'this is not Object');
  exit lWork.GetOwnProperty(Utilities.GetArgAsString(args, 0, aCaller)) <> nil;
end;

method GlobalObject.ObjectPropertyIsEnumerable(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetObjAsEcmaScriptObject(aSelf, aCaller);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'this is not Object');
  var lProp := lWork.GetOwnProperty(Utilities.GetArgAsString(args, 0, aCaller));
  exit (lProp <> nil) and (PropertyAttributes.Enumerable in lProp.Attributes);
end;

method GlobalObject.escape(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsString(args, 0, aCaller);
  var sb := new StringBuilder;
  for i: Integer := 0 to length(lWork) -1 do begin
    case lWork[i] of 
      'A' .. 'Z',
      'a' .. 'z',
      '0' .. '9',
      '@', '*','_','+','-','.': 
        sb.Append(lWork[i]);
      else begin
        var c := Integer(lWork[i]);
        if c < 256 then begin
          sb.Append('%');
          sb.Append(c.ToString('x2'));
        end else begin
          sb.Append('%u');
          sb.Append(c.ToString('x5'));
        end;
      end;
    end; // case
  end;
  exit sb.ToString;
end;

method GlobalObject.unescape(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
 var lWork := Utilities.GetArgAsString(args, 0, aCaller);
  var sb := new StringBuilder;
  var i: Integer := 0;
  while i < length(lWork) do begin
    if lWork[i] = '%' then begin
      inc(i);
      var lTmp: Integer;
      if i < lWork.Length then begin
        if (lWork[i] = 'u') and (i +4 < lWork.Length) then begin
          inc(i);

          
          if Int32.TryParse(lWork.Substring(i, 4), System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out lTmp) then
            sb.Append(Char(lTmp));
          inc(i, 4);
        end else begin
          if Int32.TryParse(lWork.Substring(i, 2), System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.NumberFormatInfo.InvariantInfo, out lTmp) then
            sb.Append(Char(lTmp));
          inc(i, 2);
        end;

      end;
    end else begin
      sb.Append(lWork[i]);
      inc(i);
    end;
  end;
  exit sb.ToString;
end;

method GlobalObject.IncreaseFrame;
begin
  if FrameCount+1 > MaxFrames then
    RaiseNativeError(NativeErrorType.EvalError, 'Stack overflow');
  FrameCount := FrameCount + 1;
end;

method GlobalObject.DecreaseFrame;
begin
  FrameCount := FrameCount - 1;
end;

method GlobalObject.get_ExecutionContext: ExecutionContext;
begin
  if fExecutionContext = nil then fExecutionContext := new ExecutionContext(new ObjectEnvironmentRecord(nil, self), false);
  exit fExecutionContext;
end;


method GlobalObject.NativeToString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lObject: EcmaScriptObjectWrapper := EcmaScriptObjectWrapper(&self);
  if not assigned(lObject) then
    self.RaiseNativeError(NativeErrorType.ReferenceError, 'native toString() is not generic');

  exit lObject.Value:ToString();
end;


method Undefined.ToString: String;
begin
  exit 'undefined';
end;

constructor EcmaScriptObjectObject(aOwner: GlobalObject; aName: String);
begin
  inherited constructor(aOwner, new EcmaScriptObject(aOwner, aOwner.FunctionPrototype));
  &Class := 'Function';
  fOriginalName := aName;
  Values.Add('length', PropertyValue.NotAllFlags(1));
end;

method EcmaScriptObjectObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  var lVal := Utilities.GetArg(args, 0);
  if (lVal = nil) or (lVal = Undefined.Instance) then exit Construct(context, nil, args);
  exit Utilities.ToObject(context, lVal);
end;

method EcmaScriptObjectObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  if (length(args) <> 0) and (args[0] <> nil) and (args[0] <> Undefined.Instance) then begin
    if args[0] is EcmaScriptObject then exit args[0];
    if (args[0] is String) or (args[0] is Integer) or (args[0] is Int64) or (args[0] is Double) or( args[0] is Boolean) then exit Utilities.ToObject(context, args[0]);
  end;
  exit new EcmaScriptObject(Root);
end;

method EcmaScriptObjectObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  var lVal := Utilities.GetArg(args, 0);
  if (lVal = nil) or (lVal = Undefined.Instance) then exit Construct(context, nil, args);
  exit Utilities.ToObject(context, lVal);
end;

end.