//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript;

interface
uses
  System.Collections.Generic;

type
  // LexicalEnvironment = EnvironmentRecord
  Reference = public class
  private
  public
    constructor(aBase: Object; aName: String; aStrict: Integer);
    property Base: Object; // Undefined, Simple, IEnvironmentRecord or Object
    property Name: String;
    property &Flags: Integer;
    property Strict: Boolean read 0 <> (1 and &Flags);
    property ArrayAccess: Boolean read 0 <> (2 and &Flags);

    class method GetValue(aReference: Object; aExecutionContext: ExecutionContext): Object;
    class method SetValue(aReference: Object; aValue: Object; aExecutionContext: ExecutionContext): Object;
    class method Delete(aReference: Object; aExecutionContext: ExecutionContext): Boolean;
    class method CreateReference(aBase, aSub: Object; aExecutionContext: ExecutionContext; aStrict: Integer): Reference;

    class var Method_GetValue: System.Reflection.MethodInfo := typeOf(Reference).GetMethod('GetValue'); readonly;
    class var Method_SetValue: System.Reflection.MethodInfo := typeOf(Reference).GetMethod('SetValue'); readonly;
    class var Method_Delete: System.Reflection.MethodInfo := typeOf(Reference).GetMethod('Delete'); readonly;
    class var Method_Create: System.Reflection.MethodInfo := typeOf(Reference).GetMethod('CreateReference'); readonly;
  end;

  ExecutionContext = public class
  private
    method get_Global: GlobalObject;
  public
    constructor; empty;
    constructor(aScope: EnvironmentRecord; aStrict: Boolean);

    method &With(aVal: Object): ExecutionContext;
    class method Catch(value: Object;  context: ExecutionContext;  name: String): ExecutionContext;

    property Strict: Boolean;
    property LexicalScope: EnvironmentRecord;
    property VariableScope: EnvironmentRecord;

    property Global: GlobalObject read get_Global;

    method StoreParameter(Args: array of Object; index: Integer; name: String; aStrict: Boolean);
    method GetDebugSink: IDebugSink;

    class var method_SetStrict: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('set_Strict'); readonly;
    class var &Method_Catch: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('Catch'); readonly;
    class var &Method_With: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('With'); readonly;
    class var &Constructor: System.Reflection.ConstructorInfo := typeOf(ExecutionContext).GetConstructor([typeOf(EnvironmentRecord), typeOf(Boolean)]); readonly;
    class var Method_GetDebugSink: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('GetDebugSink'); readonly;
    class var Method_get_LexicalScope: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('get_LexicalScope'); readonly;
    class var Method_get_VariableScope: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('get_VariableScope'); readonly;
    class var Method_get_Global: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('get_Global'); readonly;
    class var Method_StoreParameter: System.Reflection.MethodInfo := typeOf(ExecutionContext).GetMethod('StoreParameter'); readonly;
  end;

  EnvironmentRecord = public abstract class
  public
    class method GetIdentifier(aLex: EnvironmentRecord; aName: String; aStrict: Boolean): Reference; 

    class var Method_GetIdentifier: System.Reflection.MethodInfo := typeOf(EnvironmentRecord).GetMethod('GetIdentifier'); readonly;
    
    constructor(aPrev: EnvironmentRecord);
    property Previous: EnvironmentRecord; readonly;
    property Global: GlobalObject read ; abstract;
    property IsDeclarative: Boolean read; abstract; 
    method CreateMutableBindingNoFail(aName: String; aDeleteAfter: Boolean);

    method HasBinding(aName: String): Boolean; abstract;
    method CreateMutableBinding(aName: String; aDeleteAfter: Boolean); abstract;
    method SetMutableBinding(aName: String; aValue: Object; aStrict: Boolean); abstract;
    method GetBindingValue(aName: String; aStrict: Boolean): Object; abstract;
    method DeleteBinding(aName: String): Boolean;  abstract;
    method ImplicitThisValue: Object; abstract;

    method Names: sequence of String; abstract;

    class method CreateAndSetMutableBindingNoFail(aVal: Object; aName: String; Ex: EnvironmentRecord; aImmutable, aDeleteAfter: Boolean);

    class var Method_CreateAndSetMutableBindingNoFail: System.Reflection.MethodInfo := typeOf(EnvironmentRecord).GetMethod('CreateAndSetMutableBindingNoFail'); readonly;
    class var Method_CreateMutableBindingNoFail: System.Reflection.MethodInfo := typeOf(EnvironmentRecord).GetMethod('CreateMutableBindingNoFail'); readonly;
    class var Method_SetMutableBinding: System.Reflection.MethodInfo := typeOf(EnvironmentRecord).GetMethod('SetMutableBinding'); readonly;
    class var Method_HasBinding: System.Reflection.MethodInfo := typeOf(EnvironmentRecord).GetMethod('HasBinding'); readonly;
  end;
  ObjectEnvironmentRecord = public class(EnvironmentRecord)
  private
    fObject: EcmaScriptObject;
  public
    constructor(aPrevious: EnvironmentRecord; aObject: EcmaScriptObject; aProvideThis: Boolean := false);

    method Names: sequence of String; override;
    property Global: GlobalObject read fObject.Root; override;
    property IsDeclarative: Boolean read false; override;
    method HasBinding(aName: String): Boolean; override;
    method CreateMutableBinding(aName: String; aDeleteAfter: Boolean); override;
    method SetMutableBinding(aName: String; aValue: Object; aStrict: Boolean); override;
    method GetBindingValue(aName: String; aStrict: Boolean): Object; override;
    method DeleteBinding(aName: String): Boolean; override;
    method ImplicitThisValue: Object; override;
    property ProvideThis: Boolean;
  end;
  DeclarativeEnvironmentRecord = public class(EnvironmentRecord)
  private
    fGlobal: GlobalObject;
    fBag: Dictionary<String, PropertyValue> := new Dictionary<String,PropertyValue>();
  public
    constructor(aPrevious: EnvironmentRecord; aGlobal: GlobalObject);
    method Names: sequence of String; override;
    property Global: GlobalObject read fGlobal write fGlobal; override;
    property Bag: Dictionary<String, PropertyValue> read fBag;
    property IsDeclarative: Boolean read true; override;
    method HasBinding(aName: String): Boolean; override;
    method CreateMutableBinding(aName: String; aDeleteAfter: Boolean); override;
    method SetMutableBinding(aName: String; aValue: Object; aStrict: Boolean); override;
    method GetBindingValue(aName: String; aStrict: Boolean): Object; override;
    method DeleteBinding(aName: String): Boolean; override;
    method ImplicitThisValue: Object; empty; override;
    method CreateImmutableBinding(aName: String); virtual;
    method InitializeImmutableBinding(aName: String; aValue: Object); virtual;
    class method SetAndInitializeImmutable(val: EcmaScriptBaseFunctionObject; aName: String): EcmaScriptBaseFunctionObject;
    class var &Constructor: System.Reflection.ConstructorInfo := typeOf(DeclarativeEnvironmentRecord).GetConstructor([typeOf(EnvironmentRecord), typeOf(GlobalObject)]); readonly;
    class var Method_SetAndInitializeImmutable: System.Reflection.MethodInfo := typeOf(DeclarativeEnvironmentRecord).GetMethod('SetAndInitializeImmutable'); readonly;
  end;

implementation


method ObjectEnvironmentRecord.HasBinding(aName: String): Boolean;
begin
  exit fObject.HasProperty(aName);
end;

method ObjectEnvironmentRecord.CreateMutableBinding(aName: String; aDeleteAfter: Boolean);
begin
  if fObject.HasProperty(aName) then fObject.Root.RaiseNativeError(NativeErrorType.TypeError, 'Duplicate property '+aName);
  var lProp := PropertyAttributes.All;
  if not aDeleteAfter then lProp := lProp and not PropertyAttributes.Configurable;
  fObject.DefineOwnProperty(aName, new PropertyValue(lProp, Undefined.Instance), false);
end;

method ObjectEnvironmentRecord.SetMutableBinding(aName: String; aValue: Object; aStrict: Boolean);
begin
  fObject.Put(nil, aName, aValue, if aStrict then 1 else 0);
end;

method ObjectEnvironmentRecord.GetBindingValue(aName: String; aStrict: Boolean): Object;
begin
  if (fObject = &Global) and (aName = 'eval') and not aStrict then begin
    exit Global.NotStrictGlobalEvalFunc;
  end;

  if fObject.HasProperty(aName) then begin
    exit fObject.Get(aName);
  end;
  if aStrict then 
    fObject.Root.RaiseNativeError(NativeErrorType.ReferenceError, aName+' does not exist in this object');
  exit Undefined.Instance;   
end;

method ObjectEnvironmentRecord.DeleteBinding(aName: String): Boolean;
begin
  exit fObject.Delete(aName, false);
end;

method ObjectEnvironmentRecord.ImplicitThisValue: Object;
begin
  if ProvideThis then exit fObject else exit Undefined.Instance;
end;

constructor ObjectEnvironmentRecord(aPrevious: EnvironmentRecord; aObject: EcmaScriptObject; aProvideThis: Boolean := false);
begin
  inherited constructor(aPrevious);
  fObject := aObject;
  ProvideThis := aProvideThis;
end;

method ObjectEnvironmentRecord.Names: sequence of String;
begin
  exit fObject.Names;
end;

constructor DeclarativeEnvironmentRecord(aPrevious: EnvironmentRecord; aGlobal: GlobalObject);
begin
  inherited constructor(aPrevious);
  fGlobal := aGlobal;
end;

method DeclarativeEnvironmentRecord.HasBinding(aName: String): Boolean;
begin
  exit fBag.ContainsKey(aName);
end;

method DeclarativeEnvironmentRecord.CreateMutableBinding(aName: String; aDeleteAfter: Boolean);
begin
  if fBag.ContainsKey(aName) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Duplicate property: '+aName);
  fBag.Add(aName, new PropertyValue(PropertyAttributes.Writable or PropertyAttributes.Configurable, Undefined.Instance));
end;

method DeclarativeEnvironmentRecord.SetMutableBinding(aName: String; aValue: Object; aStrict: Boolean);
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then begin
    fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Unknown property: '+aName);
  end;
  if PropertyAttributes.Writable not in lVal.Attributes then 
    fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Property is immutable: '+aName);
  lVal.Value := aValue;
end;

method DeclarativeEnvironmentRecord.GetBindingValue(aName: String; aStrict: Boolean): Object;
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Unknown property: '+aName);
  if (lVal.Attributes = PropertyAttributes.Configurable) and (lVal.Value = Undefined.Instance) and aStrict then // immutable but not set yet
    fGlobal.RaiseNativeError(NativeErrorType.ReferenceError, 'Property not initialized: '+aName);
  exit lVal.Value;
end;

method DeclarativeEnvironmentRecord.DeleteBinding(aName: String): Boolean;
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then exit true;
  if lVal.Attributes <> (PropertyAttributes.Configurable or PropertyAttributes.Writable) then exit false;
  exit fBag.Remove(aName);
end;

method DeclarativeEnvironmentRecord.CreateImmutableBinding(aName: String);
begin
  if fBag.ContainsKey(aName) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Duplicate property: '+aName);
  fBag.Add(aName, new PropertyValue(PropertyAttributes.Configurable, Undefined.Instance));
end;

method DeclarativeEnvironmentRecord.InitializeImmutableBinding(aName: String; aValue: Object);
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Unknown property: '+aName);
  if PropertyAttributes.Configurable or PropertyAttributes.HasValue <> lVal.Attributes then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Property not an unitialized immutable: '+aName);
  lVal.Attributes := PropertyAttributes.None;
  lVal.Value := aValue;
end;

class method DeclarativeEnvironmentRecord.SetAndInitializeImmutable(val: EcmaScriptBaseFunctionObject; aName: String): EcmaScriptBaseFunctionObject;
begin
  var lSelf := (val.Scope as DeclarativeEnvironmentRecord);
  lSelf.CreateImmutableBinding(aName);
  lSelf.InitializeImmutableBinding(aName, val);
  exit val;
end;

method DeclarativeEnvironmentRecord.Names: sequence of String;
begin
  exit fBag.Keys;
end;

constructor Reference(aBase: Object; aName: String; aStrict: Integer);
begin
  Base := aBase;
  Name := aName;
  Flags := aStrict;
end;

class method Reference.GetValue(aReference: Object; aExecutionContext: ExecutionContext): Object;
begin
  var lRef := Reference(aReference);
  if lRef = nil then exit aReference;
  if lRef.Base = Undefined.Instance then
     aExecutionContext.Global.RaiseNativeError(NativeErrorType.ReferenceError, lRef.Name +' is not defined');
  if lRef.Base = nil then exit aExecutionContext.Global.ObjectPrototype.Get(aExecutionContext, lRef.Name);
  var lObj := EcmaScriptObject(lRef.Base);
  if assigned(lObj) then 
    exit lObj.Get(aExecutionContext, lRef.Flags, lRef.Name);
  var lExec := EnvironmentRecord(lRef.Base); 
  if assigned(lExec) then
    exit lExec.GetBindingValue(lRef.Name, lRef.Strict);
  if lRef.Base is Boolean then exit aExecutionContext.Global.BooleanPrototype.Get(aExecutionContext, lRef.Name);
  if lRef.Base is Integer then exit aExecutionContext.Global.NumberPrototype.Get(aExecutionContext, lRef.Name);
  if lRef.Base is Double then exit aExecutionContext.Global.NumberPrototype.Get(aExecutionContext, lRef.Name);
  if lRef.Base is String then begin
    if lRef.Name = 'length' then 
      exit String(lRef.Base).Length;
    exit aExecutionContext.Global.StringPrototype.Get(aExecutionContext, lRef.Name);
  end;
end;

class method Reference.SetValue(aReference: Object; aValue: Object; aExecutionContext: ExecutionContext): Object;
begin
  var lRef := Reference(aReference);
  if lRef = nil then begin
    aExecutionContext.Global.RaiseNativeError(NativeErrorType.ReferenceError, 'Invalid left-hand side in assignment');
    exit lRef;
  end;

  if lRef.Base = Undefined.Instance then
    if lRef.Strict then
      aExecutionContext.Global.RaiseNativeError(NativeErrorType.TypeError,'Cannot call '+lRef.Name+' on undefined')
    else
      exit aExecutionContext.Global.Put(aExecutionContext, lRef.Name, aValue, lRef.Flags);
  var lObj := EcmaScriptObject(lRef.Base);
  if assigned(lObj) then 
    exit lObj.Put(aExecutionContext, lRef.Name, aValue, lRef.Flags);
  var lExec := EnvironmentRecord(lRef.Base);
  if assigned(lExec) then begin
    lExec.SetMutableBinding(lRef.Name, aValue, lRef.Strict);
    exit aValue;
  end;
  if lRef.Strict then
    aExecutionContext.Global.RaiseNativeError(NativeErrorType.TypeError, 'Cannot set value on transient object');
  exit aValue; // readonly so the on the fly Object 
end;

class method Reference.Delete(aReference: Object; aExecutionContext: ExecutionContext): Boolean;
begin
  var lRef := Reference(aReference);
  if lRef = nil then exit true;
  if (lRef.Base = nil) or (lRef.Base = Undefined.Instance) then begin
    if lRef.Strict then 
      aExecutionContext.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'Cannot delete undefined reference');
    exit true;
  end;
  var lObj := EcmaScriptObject(lRef.Base);
  if assigned(lObj) then
    exit lObj.Delete(lRef.Name, lRef.Strict);
  var lExec := EnvironmentRecord(lRef.Base);
  if assigned(lExec) then begin
    if lRef.Strict then aExecutionContext.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'Cannot delete execution context element');
    exit lExec.DeleteBinding(lRef.Name);
  end;
  if lRef.Strict then
    aExecutionContext.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'Cannot delete transient object');
end;

class method Reference.CreateReference(aBase, aSub: Object; aExecutionContext: ExecutionContext; aStrict: Integer): Reference;
begin
  if (aBase = nil) then aExecutionContext.Global.RaiseNativeError(NativeErrorType.TypeError, 'Cannot get property on null');
  if (aBase = Undefined.Instance) then aExecutionContext.Global.RaiseNativeError(NativeErrorType.TypeError, 'Cannot get property of undefined');
  exit new Reference(aBase, Utilities.GetObjAsString(aSub, aExecutionContext), aStrict);
end;

class method EnvironmentRecord.GetIdentifier(aLex: EnvironmentRecord; aName: String; aStrict: Boolean): Reference;
begin
  while aLex <> nil do begin
    if aLex.HasBinding(aName) then begin
      exit new Reference(aLex, aName, if aStrict then 1 else 0);
    end;
    aLex := aLex.Previous;
  end;

  if aLex = nil then exit new Reference(Undefined.Instance, aName, if aStrict then 1 else 0);
end;

constructor EnvironmentRecord(aPrev: EnvironmentRecord);
begin
  Previous := aPrev;
end;


method EnvironmentRecord.CreateMutableBindingNoFail(aName: String; aDeleteAfter: Boolean);
begin
  if not HasBinding(aName) then CreateMutableBinding(aName, aDeleteAfter);
end;

class method EnvironmentRecord.CreateAndSetMutableBindingNoFail(aVal: Object; aName: String; Ex: EnvironmentRecord; aImmutable, aDeleteAfter: Boolean);
begin
  if aImmutable then begin
    var lDec := DeclarativeEnvironmentRecord(Ex);
    if lDec <> nil then begin
      lDec.CreateImmutableBinding(aName);
      lDec.InitializeImmutableBinding(aName, aVal);
      exit;
    end;
  end;
  Ex.CreateMutableBinding(aName, aDeleteAfter);
  Ex.SetMutableBinding(aName, aVal, false);
end;

constructor ExecutionContext(aScope: EnvironmentRecord; aStrict: Boolean);
begin
  LexicalScope := aScope;
  VariableScope := aScope;
  Strict := aStrict;
end;

method ExecutionContext.GetDebugSink: IDebugSink;
begin
  exit &Global.Debug;
end;

method ExecutionContext.StoreParameter(Args: array of Object; &index: Integer; name: String; aStrict: Boolean);
begin
  var lVal := if index < Args.Length then Args[index] else Undefined.Instance;
  if not VariableScope.HasBinding(name) then begin
    VariableScope.CreateMutableBinding(name, false);
    VariableScope.SetMutableBinding(name, lVal, aStrict);
  end;
end;

method ExecutionContext.With(aVal: Object): ExecutionContext;
begin
  exit new ExecutionContext(new ObjectEnvironmentRecord(LexicalScope, Utilities.ToObject(self, aVal), true), false);
end;


class method ExecutionContext.Catch(value: Object;  context: ExecutionContext;  name: String): ExecutionContext;
begin
  var lResult: ExecutionContext := new ExecutionContext(new DeclarativeEnvironmentRecord(context.LexicalScope, context.Global), context.Strict);
  lResult.LexicalScope.CreateMutableBinding(name, false);

  if (value is EcmaScriptObjectWrapper) and (EcmaScriptObjectWrapper(value).Value is Exception) then
    lResult.LexicalScope.SetMutableBinding(name, lResult.Global.ErrorCtor(lResult, nil, Exception(EcmaScriptObjectWrapper(value).Value).Message), false)
  else
    lResult.LexicalScope.SetMutableBinding(name, value, false);

  exit lResult;
end;


method ExecutionContext.get_Global: GlobalObject;
begin
  exit LexicalScope.Global;
end;

end.
