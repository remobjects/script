{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Runtime.CompilerServices,
  System.Text,
  Microsoft,
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

    class var Method_Instance: System.Reflection.MethodInfo := typeof(Undefined).GetMethod('get_Instance'); readonly;
  end;

  GlobalObject = public partial class(EcmaScriptObject)
  assembly
    fParser: EcmaScriptCompiler;
  public
    constructor (aParser: EcmaScriptCompiler);
		constructor;

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
    
    method eval(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method parseInt(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method parseFloat(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method isNaN(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method isFinite(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method encodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method decodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method encodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    method decodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
    
    // Proto:
    method ObjectCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectValueOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectIsPrototypeOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;

    // Static:
    method ObjectgetPrototypeOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectgetOwnPropertyDescriptor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectgetOwnPropertyNames(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectCreate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectdefineProperty(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectdefineProperties(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectSeal(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method Objectfreeze(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectpreventExtensions(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectisSealed(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectisFrozen(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectisExtensible(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method ObjectKeys(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    
    method CreateObject: EcmaScriptObject;
    method ToString: String; override;
  private
    fDebug: IDebugSink;
    method get_Debug: IDebugSink;
  end;
  EcmaScriptEvalFunctionObject = public class(EcmaScriptFunctionObject);
implementation

constructor GlobalObject(aParser: EcmaScriptCompiler);
begin
  inherited constructor(nil, nil);
  Root := self;
  fParser := aParser;
  Values.Add('NaN', PropertyValue.NotAllFlags(Double.NaN));
  Values.Add('Infinity', PropertyValue.NotAllFlags(Double.PositiveInfinity));
  Values.Add('undefined', PropertyValue.NotAllFlags(Undefined.Instance));

  Values.Add('Math', PropertyValue.NotEnum(new Func<EcmaScriptObject>(CreateMath)));
  CreateObject;
  CreateFunction;
  CreateArray;
  CreateNumber;
  CreateDate;
  CreateString;
  CreateBoolean;
  CreateRegExp;
  CreateError;
  CreateNativeError;

  // Add function prototype here first!
  Values.Add('eval', PropertyValue.NotEnum(new EcmaScriptEvalFunctionObject(self, 'eval', @eval, 1)));
  Values.Add('parseInt', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parseInt', @parseInt, 2)));
  Values.Add('parseFloat', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parseFloat', @parseFloat, 1)));
  Values.Add('isNaN', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isNaN', @isNaN, 1)));
  Values.Add('isFinite', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isFinite', @isFinite, 1)));
  Values.Add('decodeURI', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'decodeURI', @decodeURI, 1)));
  Values.Add('encodeURI', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'encodeURI', @encodeURI, 1)));
  Values.Add('decodeURIComponent', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'decodeURIComponent', @decodeURIComponent, 1)));
  Values.Add('encodeURIComponent', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'encodeURIComponent', @encodeURIComponent, 1)));
end;


method GlobalObject.eval(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  (*
  if (Length(args) < 1) then exit Undefined.Instance;
  var lScope := aCaller.Scope;
  var lStr: Object;
  if aSelf is IScopeObject then begin
    lScope := aSelf as IScopeObject;
    if (Length(args) < 1) then exit Undefined.Instance;
  end;
  lStr := args[0];

  if EcmaScriptObject(lStr):Value is String then 
    lStr := EcmaScriptObject(lStr).Value;
  if (lStr is not String) then exit lStr;

  var lTokenizer := new Tokenizer;
  var lParser := new Parser;
  lTokenizer.Error += lParser.fTok_Error;
  lTokenizer.SetData(lStr.ToString, '<eval>');
  lTokenizer.Error -= lParser.fTok_Error;
  
  var lElement := lParser.Parse(lTokenizer);
  for each el in lParser.Messages do begin
    if el.IsError then 
      RaiseNativeError(NativeErrorType.SyntaxError, el.IntToString());
  end;
  
  
  var x := fParser.EvalParse(lScope, lElement);
  result := InternalDelegate(x.Compile).Invoke(nil, lScope, args); // scope is really ignored here
  *)
end;

method GlobalObject.parseInt(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  var lVal: String;
  var lRadix: Integer;
  if Length(args) < 1 then 
    lVal := '0'
  else begin
    lVal := Args[0].ToString;
    if Length(Args) < 2 then
      lRadix := 10
    else if (args[1] = nil) or (args[1] = Undefined.Instance) then 
      lRadix := 10
    else 
      lRadix := Convert.ToInt32(args[1]);
  end;

  if lRadix = 16 then
    result := Int64.Parse(lVal, System.Globalization.NumberStyles.HexNumber)
  else
    result := Int64.Parse(lVal, System.Globalization.NumberStyles.Integer);
end;

method GlobalObject.parseFloat(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  var lVal: String;
  if (Length(args) < 1) or (args[1] = nil) or (args[1] = Undefined.Instance) then 
    lVal := '0'
  else lVal := args[0].ToString;

  result := Double.Parse(lVal, System.Globalization.NumberFormatInfo.InvariantInfo);
end;

method GlobalObject.isNaN(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  exit Double.IsNaN(Utilities.GetObjAsDouble(args[0]));
end;

method GlobalObject.isFinite(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  var lVal := Convert.ToDouble(args[0]);
  exit not Double.IsInfinity(lVal) and not Double.IsNaN(lVal);
end;


method GlobalObject.ObjectCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Length(args) = 0 then result := new EcmaScriptObject(self, self.ObjectPrototype) else begin
    result := new EcmaScriptObject(self, self.ObjectPrototype, Value := args[0]);
  end;
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
  if (args.Length = 0) or (aSelf is not EcmaScriptObject) then exit false;
  var lValue := EcmaScriptObject(args[1]);

  if lValue = nil then result := false else result := lValue.Prototype = aSelf;
end;

method GlobalObject.CreateObject: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 'Object'));
  if result <> nil then exit;

  ObjectPrototype := new EcmaScriptFunctionObject(self, 'Object', @ObjectCtor, 1, &Class := 'Object');

  result := new EcmaScriptObject(self, ObjectPrototype);
  Values.Add('Object', PropertyValue.NotEnum(Result));

  result.Values['prototype'] := PropertyValue.NotAllFlags(ObjectPrototype);
  result.Values.Add('getPrototypeOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getPrototypeOf', @ObjectgetPrototypeOf, 1)));
  result.Values.Add('getOwnPropertyDescriptor', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getOwnPropertyDescriptor', @ObjectgetOwnPropertyDescriptor, 2)));
  result.Values.Add('getOwnPropertyNames', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getOwnPropertyNames', @ObjectgetOwnPropertyNames, 1)));
  result.Values.Add('create', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'create', @ObjectCreate, 1)));
  result.Values.Add('defineProperty', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'defineProperty', @ObjectdefineProperty, 3)));
  result.Values.Add('defineProperties', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'defineProperties', @ObjectdefineProperties, 3)));
  result.Values.Add('seal', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'seal', @ObjectSeal, 1)));
  result.Values.Add('freeze', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'freeze', @Objectfreeze, 1)));
  result.Values.Add('preventExtensions', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'preventExtensions', @ObjectpreventExtensions, 1)));
  result.Values.Add('isSealed', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isSealed', @ObjectisSealed, 1)));
  result.Values.Add('isFrozen', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isFrozen', @ObjectisFrozen, 1)));
  result.Values.Add('isExtensible', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isExtensible', @ObjectisExtensible, 1)));
  result.Values.Add('keys', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'keys', @ObjectKeys, 1)));

  ObjectPrototype.Values['constructor'] := PropertyValue.NotEnum(ObjectPrototype);

  ObjectPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @ObjectToString, 0)));

  ObjectPrototype.Values.Add('valueOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'valueOf', @ObjectValueOf, 0)));

  ObjectPrototype.Values.Add('isPrototypeOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isPrototypeOf', @ObjectIsPrototypeOf, 0)));
end;


method GlobalObject.ToString: String;
begin
  result := '[object global]';
end;


constructor GlobalObject;
begin
  constructor(nil);
end;

method GlobalObject.encodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  exit Utilities.UrlEncode(Utilities.GetArgAsString(Args, 0));
end;

method GlobalObject.decodeURI(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  exit Utilities.UrlDecode(Utilities.GetArgAsString(args, 0));
end;

method GlobalObject.encodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  exit Utilities.UrlEncodeComponent(Utilities.GetArgAsString(Args, 0));  
end;

method GlobalObject.decodeURIComponent(aCaller: ExecutionContext;aSelf: Object; params args: Array of object): Object;
begin
  exit Utilities.UrlDecode(Utilities.GetArgAsString(args, 0));
end;

method GlobalObject.ObjectgetPrototypeOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  exit lWork.Prototype;
end;

method GlobalObject.ObjectgetOwnPropertyDescriptor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lWork := Utilities.GetArgAsEcmaScriptObject(args, 0);
  if lWork = nil then RaiseNativeError(NativeErrorType.TypeError, 'Type(O) is not Object');
  var lName := Utilities.GetArgAsString(args, 1);

  var lPV: PropertyValue;
  if lWork.Values.TryGetValue(lName, out lPV) then
    exit FromPropertyDescriptor(lPV);
  exit Undefined.Instance;
end;

method GlobalObject.ObjectgetOwnPropertyNames(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectCreate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectdefineProperty(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectdefineProperties(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectSeal(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.Objectfreeze(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectpreventExtensions(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectisSealed(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectisFrozen(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectisExtensible(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;

method GlobalObject.ObjectKeys(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
end;


method GlobalObject.get_Debug: IDebugSink;
begin
  if fDebug = nil then fDebug := new DebugSink; // dummy one
  exit fDebug;
end;

method Undefined.ToString: String;
begin
  exit 'undefined';
end;

end.