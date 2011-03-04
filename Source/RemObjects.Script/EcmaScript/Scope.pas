namespace RemObjects.Script.EcmaScript;

interface
uses
  System.Collections.Generic;

type
  // LexicalEnvironment = EnvironmentRecord
  Reference = public record
  private
  public
    constructor(aBase: Object; aName: string; aStrict: Boolean);
    property Base: Object; // Undefined, Simple, IEnvironmentRecord or Object
    property Name: string;
    property Strict: Boolean;

    class method GetValue(aReference: Object; aExecutionContext: ExecutionContext): Object;
    class method SetValue(aReference: Object; aValue: Object; aExecutionContext: ExecutionContext): Object;
    class method Delete(aReference: Object; aExecutionContext: ExecutionContext): Boolean;

    class var Method_GetValue: System.Reflection.MethodInfo := typeof(ExecutionContext).GetMethod('GetValue'); readonly;
    class var Method_SetValue: System.Reflection.MethodInfo := typeof(ExecutionContext).GetMethod('SetValue'); readonly;
    class var Method_Delete: System.Reflection.MethodInfo := typeof(ExecutionContext).GetMethod('Delete'); readonly;
  end;

  ExecutionContext = public class
  private
  public
    constructor; empty;
    constructor(aScope: EnvironmentRecord);
    constructor(aScope: EnvironmentRecord; aThis: Object);
    property LexicalScope: EnvironmentRecord;
    property VariableScope: EnvironmentRecord;
    property This: Object;

    property Global: GlobalObject read LexicalScope.Global;

    method GetDebugSink: IDebugSink;

    class var Method_GetDebugSink: System.Reflection.MethodInfo := typeof(ExecutionContext).GetMethod('GetDebugSink'); readonly;
    class var Method_get_This: System.Reflection.MethodInfo := typeof(ExecutionContext).GetMethod('get_This'); readonly;
    class var Method_get_LexicalScope: System.Reflection.MethodInfo := typeof(ExecutionContext).GetMethod('get_LexicalScope'); readonly;
    class var Method_get_Global: System.Reflection.MethodInfo := typeof(ExecutionContext).GetMethod('get_Global'); readonly;
  end;

  EnvironmentRecord = public abstract class
  public
    class method GetIdentifier(aLex: EnvironmentRecord; aName: String; aStrict: Boolean): Reference; 
    
    constructor(aPrev: EnvironmentRecord);
    property Previous: EnvironmentRecord; readonly;
    property Global: GlobalObject read ; abstract;
    property IsDeclarative: Boolean read; abstract; 
    method HasBinding(aName: string): Boolean; abstract;
    method CreateMutableBinding(aName: string; aDeleteAfter: Boolean); abstract;
    method SetMutableBinding(aName: string; aValue: Object; aStrict: Boolean); abstract;
    method GetBindingValue(aName: string; aStrict: Boolean): Object; abstract;
    method DeleteBinding(aName: string): Boolean;  abstract;
    method ImplicitThisValue: Object; abstract;
  end;
  ObjectEnvironmentRecord = public class(EnvironmentRecord)
  private
    fObject: EcmaScriptObject;
  public
    constructor(aPrevious: EnvironmentRecord; aObject: EcmaScriptObject; aProvideThis: Boolean := false);
    property Global: GlobalObject read fObject.Root; override;
    property IsDeclarative: Boolean read false; override;
    method HasBinding(aName: string): Boolean; override;
    method CreateMutableBinding(aName: string; aDeleteAfter: Boolean); override;
    method SetMutableBinding(aName: string; aValue: Object; aStrict: Boolean); override;
    method GetBindingValue(aName: string; aStrict: Boolean): Object; override;
    method DeleteBinding(aName: string): Boolean; override;
    method ImplicitThisValue: Object; override;
    property ProvideThis: Boolean;
  end;
  DeclarativeEnvironmentRecord = public class(EnvironmentRecord)
  private
    fGlobal: GlobalObject;
    fBag: Dictionary<string, PropertyValue> := new Dictionary<String,PropertyValue>();
  public
    constructor(aPrevious: EnvironmentRecord; aGlobal: GlobalObject);
    property Global: GlobalObject read fGlobal; override;
    property Bag: Dictionary<string, PropertyValue> read fBag;
    property IsDeclarative: Boolean read true; override;
    method HasBinding(aName: string): Boolean; override;
    method CreateMutableBinding(aName: string; aDeleteAfter: Boolean); override;
    method SetMutableBinding(aName: string; aValue: Object; aStrict: Boolean); override;
    method GetBindingValue(aName: string; aStrict: Boolean): Object; override;
    method DeleteBinding(aName: string): Boolean; override;
    method ImplicitThisValue: Object; empty; override;
    method CreateImmutableBinding(aName: string); virtual;
    method InitializeImmutableBinding(aName: string; aValue: Object); virtual;
  end;

implementation


method ObjectEnvironmentRecord.HasBinding(aName: string): Boolean;
begin
  exit fObject.HasProperty(aName);
end;

method ObjectEnvironmentRecord.CreateMutableBinding(aName: string; aDeleteAfter: Boolean);
begin
  if fObject.HasProperty(aName) then fObject.Root.RaiseNativeError(NativeErrorType.TypeError, 'Duplicate property '+aName);
  var lProp := PropertyAttributes.All;
  if not aDeleteAfter then lProp := lProp and not PropertyAttributes.Configurable;
  fObject.DefineOwnProperty(aName, new PropertyValue(lProp, Undefined.Instance), false);
end;

method ObjectEnvironmentRecord.SetMutableBinding(aName: string; aValue: Object; aStrict: Boolean);
begin
  fObject.Put(aName, aValue, aStrict);
end;

method ObjectEnvironmentRecord.GetBindingValue(aName: string; aStrict: Boolean): Object;
begin
  if fObject.HasProperty(aName) then begin
    exit fObject.Get(aName);
  end;
  if aStrict then 
    fObject.Root.RaiseNativeError(NAtiveErrorType.ReferenceError, aName+' does not exist in this object');
  exit Undefined.Instance;   
end;

method ObjectEnvironmentRecord.DeleteBinding(aName: string): Boolean;
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

constructor DeclarativeEnvironmentRecord(aPrevious: EnvironmentRecord; aGlobal: GlobalObject);
begin
  inherited constructor(aPrevious);
  fGlobal := aGlobal;
end;

method DeclarativeEnvironmentRecord.HasBinding(aName: string): Boolean;
begin
  exit fBag.ContainsKey(aName);
end;

method DeclarativeEnvironmentRecord.CreateMutableBinding(aName: string; aDeleteAfter: Boolean);
begin
  if fBag.ContainsKey(aName) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Duplicate property: '+aName);
  fBag.Add(aName, new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, Undefined.Instance));
end;

method DeclarativeEnvironmentRecord.SetMutableBinding(aName: string; aValue: Object; aStrict: Boolean);
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then begin
    fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Unknown property: '+aName);
  end;
  if PropertyAttributes.writable not in lVal.Attributes then 
    fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Property is immutable: '+aName);
  lVal.Value := aValue;
end;

method DeclarativeEnvironmentRecord.GetBindingValue(aName: string; aStrict: Boolean): Object;
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Unknown property: '+aName);
  if (lVal.Attributes = PropertyAttributes.Configurable) and (lVal.Value = Undefined.Instance) and aStrict then // immutable but not set yet
    fGlobal.RaiseNativeError(NativeErrorType.ReferenceError, 'Property not initialized: '+aName);
  exit lVal.Value;
end;

method DeclarativeEnvironmentRecord.DeleteBinding(aName: string): Boolean;
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then exit true;
  if lVal.Attributes <> (PropertyAttributes.Configurable or PropertyAttributes.writable) then exit false;
  exit fBag.Remove(aName);
end;

method DeclarativeEnvironmentRecord.CreateImmutableBinding(aName: string);
begin
  if fBag.ContainsKey(aName) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Duplicate property: '+aName);
  fBag.Add(aName, new PropertyValue(PropertyAttributes.Configurable, Undefined.Instance));
end;

method DeclarativeEnvironmentRecord.InitializeImmutableBinding(aName: string; aValue: Object);
begin
  var lVal: PropertyValue;
  if not fBag.TryGetValue(aName, out lVal) then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Unknown property: '+aName);
  if PropertyAttributes.Configurable <> lVal.Attributes then fGlobal.RaiseNativeError(NativeErrorType.TypeError, 'Property not an unitialized immutable: '+aName);
  lVal.Attributes := PropertyAttributes.None;
  lVal.Value := aValue;
end;

constructor Reference(aBase: Object; aName: string; aStrict: Boolean);
begin
  Base := aBase;
  Name := aName;
  Strict := aStrict;
end;

class method Reference.GetValue(aReference: Object; aExecutionContext: ExecutionContext): Object;
begin
  var lRef := Reference(aReference);
  if lRef = nil then exit aReference;
  if lRef.Base = Undefined.Instance then
     aExecutionContext.Global.RaiseNativeError(NativeErrorType.TypeError, 'Cannot call '+lRef.Name+' on undefined');
  if lRef.Base = nil then exit aExecutionContext.Global.ObjectPrototype.Get(aExecutionContext, lRef.Name);
  var lObj := EcmaScriptObject(lRef.Base);
  if assigned(lObj) then 
    exit lObj.Get(aExecutionContext,lRef. Name);
  var lExec := EnvironmentRecord(lRef.Base);
  if assigned(lExec) then
    lExec.GetBindingValue(lRef.Name, lRef.Strict);
  if lRef.Base is Boolean then exit aExecutionContext.Global.BooleanPrototype.Get(aExecutionContext, lRef.Name);
  if lRef.Base is Integer then exit aExecutionContext.Global.NumberPrototype.Get(aExecutionContext, lRef.Name);
  if lRef.Base is Double then exit aExecutionContext.Global.NumberPrototype.Get(aExecutionContext, lRef.Name);
  if lRef.Base is String then exit aExecutionContext.Global.StringPrototype.Get(aExecutionContext, lRef.Name);
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
      exit aExecutionContext.Global.Put(aExecutionContext, lRef.NAme, aValue, false);
  var lObj := EcmaScriptObject(lRef.Base);
  if assigned(lObj) then 
    exit lObj.Put(aExecutionContext,lRef.Name, aValue, lRef.Strict);
  var lExec := EnvironmentRecord(lRef.Base);
  if assigned(lExec) then
    lExec.SetMutableBinding(lRef.Name, aValue, lRef.Strict);
  if lRef.Strict then
    aExecutionContext.Global.RaiseNativeError(NativeErrorType.TypeError, 'Cannot set value on transient object');
  exit aValue; // readonly so the on the fly object 
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
    exit lObj.Delete(lREf.Name, lRef.Strict);
  var lExec := EnvironmentRecord(lRef.Base);
  if assigned(lExec) then begin
    if lRef.Strict then aExecutionContext.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'Cannot delete execution context element');
    exit lExec.DeleteBinding(lRef.Name);
  end;
  if lRef.Strict then
    aExecutionContext.Global.RaiseNativeError(NativeErrorType.SyntaxError, 'Cannot delete transient object');
end;

class method EnvironmentRecord.GetIdentifier(aLex: EnvironmentRecord; aName: String; aStrict: Boolean): Reference;
begin
  while aLex <> nil do begin
    if aLex.HasBinding(aName) then begin
      exit new Reference(aLex, aName, aStrict);
    end;
    aLex := aLex.Previous;
  end;

  if aLex = nil then exit new Reference(Undefined.Instance, aName, aStrict);
end;

constructor EnvironmentRecord(aPrev: EnvironmentRecord);
begin
  Previous := aPrev;
end;


constructor ExecutionContext(aScope: EnvironmentRecord);
begin
  LexicalScope := aScope;
  VariableScope := aScope;
end;

constructor ExecutionContext(aScope: EnvironmentRecord; aThis: Object);
begin
  LexicalScope := aScope;
  VariableScope := aScope;
  This := athis;
end;

method ExecutionContext.GetDebugSink: IDebugSink;
begin
  exit &Global.Debug;
end;

end.
