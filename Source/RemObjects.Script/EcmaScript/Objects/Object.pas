{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  RemObjects.Script,
  System.Text;

type
  PropertyAttributes = public flags (
  All = 1 +2 +4,
    writable = 1, Enumerable = 2, Configurable = 4, None = 0);

  PropertyValue = public class
  private
  public
    constructor(aAttributes: PropertyAttributes; aValue: Object);
    constructor(aAttributes: PropertyAttributes; aGet, aSet: EcmaScriptFunctionObject);
    class method NotEnum(aValue: Object): PropertyValue;
    class method NotAllFlags(aValue: Object): PropertyValue;
    class method NotDeleteAndReadOnly(aValue: Object): PropertyValue;
    property Value: Object;
    property Get: EcmaScriptFunctionObject;
    property &Set: EcmaScriptFunctionObject;
    property Attributes: PropertyAttributes;
  end;


  EcmaScriptObject = public class 
  private
    fValues: Dictionary<string, PropertyValue> := new Dictionary<String,PropertyValue>;
    method set_Prototype(avalue: EcmaScriptObject);
    method get_Prototype: EcmaScriptObject;
    fGlobal: GlobalObject;
  protected
  public
    property Extensible: Boolean := true;
    property Root: GlobalObject read fGlobal write fGlobal;
    constructor(obj: GlobalObject); 
    constructor(obj: GlobalObject; aProto: EcmaScriptObject);

    class var &Constructor: System.Reflection.ConstructorInfo := typeof(EcmaScriptObject).GetConstructor([typeof(GlobalObject)]); readonly;
    class var Method_ObjectLiteralSet: System.Reflection.MethodInfo := typeof(EcmaScriptObject).GetMethod('ObjectLiteralSet'); readonly;

    method AddValue(aValue: string; aData: Object): EcmaScriptObject;
    method AddValues(aValue: array of string; aData: array of Object): EcmaScriptObject;
    method ObjectLiteralSet(aName: string; aMode: RemObjects.Script.EcmaScript.Internal.FunctionDeclarationType; aData: Object; aStrict: Boolean): EcmaScriptObject;
    

    property Values: Dictionary<String, PropertyValue> read fValues;

    property Prototype: EcmaScriptObject read get_Prototype write set_Prototype;
    property &Class: string := 'Object';
    property Value: Object;

    method GetOwnProperty(aName: String): PropertyValue; virtual;
    method GetProperty(aName: String): PropertyValue; virtual;
    method &Get(aExecutionContext: ExecutionContext := nil; aName: String): Object; virtual;

    method CanPut(aName: String): Boolean; virtual;
    method &Put(aExecutionContext: ExecutionContext := nil; aName: String; aValue: Object; aThrow: Boolean := true): Object; virtual;
    method HasProperty(aName: string): Boolean; virtual;

    method Delete(aName: string; aThrow: Boolean): Boolean; virtual;

    method DefineOwnProperty(aName: string; aValue: PropertyValue; aThrow: Boolean := true): Boolean; virtual;

    method &PutIndex(aName: Integer; aValue: Object): Object; virtual;
    method &GetIndex(aName: Integer): Object; virtual;
    method Construct(context: ExecutionContext; params args: array of Object): Object; virtual;
    method Call(context: ExecutionContext; params args: array of Object): Object; virtual;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; virtual;
    method ToString: String; override;

    method IsAccessorDescriptor(aProp: PropertyValue): Boolean;
    method IsDataDescriptor(aProp: PropertyValue): Boolean;
    method IsGenericDescriptor(aProp: PropertyValue): Boolean;
    method FromPropertyDescriptor(aProp: PropertyValue): EcmaScriptObject;
    method ToPropertyDescriptor(aProp: EcmaScriptObject): PropertyValue;

    property Names: sequence of string read Values.Keys;
  end;

  
implementation

constructor EcmaScriptObject(obj: GlobalObject);
begin
  fGlobal := obj;
  if fGlobal <> nil then Prototype := obj.ObjectPrototype;
end;

constructor EcmaScriptObject(obj: GlobalObject; aProto: EcmaScriptObject);
begin
  fGlobal := obj;
  Prototype := aProto;
end;

method EcmaScriptObject.GetOwnProperty(aName: String): PropertyValue;
begin
  if not fValues.TryGetValue(aName, out Result) then result := nil;
end;

method EcmaScriptObject.GetProperty(aName: String): PropertyValue;
begin
  var lSelf := self;
  while assigned(lSelf) do begin
    var lRes := lSelf.GetOwnProperty(aname);
    if lRes <> nil then exit lRes;
    lSelf := lSelf.Prototype;
  end;
  exit nil;
end;

method EcmaScriptObject.Get(aExecutionContext: ExecutionContext; aName: String): Object;
begin
  var lDesc := GetProperty(aName);
  if lDesc = nil then exit Undefined.Instance;
  if IsDataDescriptor(lDesc) then
    exit lDesc.Value;
  if IsAccessorDescriptor(lDesc) and (lDesc.Get <> nil) then begin
    exit lDesc.Get.CallEx(aExecutionContext, self);
  end;
  exit Undefined.Instance;
end;


method EcmaScriptObject.CanPut(aName: String): Boolean;
begin
  var lValue: PropertyValue := GetOwnProperty(aName);
  if lValue <> nil then begin
    if IsAccessorDescriptor(lValue) then
      exit lValue.Set <> nil;
    if IsDataDescriptor(lValue) then
      exit PropertyAttributes.writable in lValue.Attributes;
  end;
  var lProperty := Prototype:GetProperty(aName);
  if lValue <> nil then begin
    if IsAccessorDescriptor(lValue) then
      exit lValue.Set <> nil;
    if IsDataDescriptor(lValue) then
      exit PropertyAttributes.writable in lValue.Attributes;
  end;

  exit Extensible;
end;

method EcmaScriptObject.&Put(aExecutionContext: ExecutionContext; aName: String; aValue: Object; aThrow: Boolean): Object; 
begin
  if not CanPut(aName) then begin
    if aThrow then
      Root.RaiseNativeError(NativeErrorType.TypeError, 'Property '+aName+' cannot be written to');
    exit Undefined.Instance;
  end;
  var lOwn := GetOwnProperty(aName);
  if assigned(lOwn) and IsDataDescriptor(lOwn) then begin
    if DefineOwnProperty(aName, new PropertyValue(PropertyAttributes.None, aValue), aThrow) then
      exit aValue;
    exit Undefined.Instance;
  end;
  lOwn := GetProperty(aName);
  if assigned(lOwn) and IsAccessorDescriptor(lOwn) and (lOwn.Set <> nil) then begin
    exit lOwn.Set.CallEx(aExecutionContext, self, [aValue]);
  end;
  if DefineOwnProperty(aName, new PropertyValue(PropertyAttributes.All, aValue), aThrow) then
    exit Avalue;
  exit Undefined.Instance;
end;

method EcmaScriptObject.HasProperty(aName: string): Boolean;
begin
  exit GetProperty(aName) <> nil;
end;

method EcmaScriptObject.Delete(aName: string; aThrow: Boolean): Boolean;
begin
  var lValue := GetOwnProperty(aname);
  if lValue = nil then exit true;
  if PropertyAttributes.Configurable in lValue.Attributes then
    exit fValues.Remove(aName);
  if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Cannot delete property '+aName);
  exit false;
end;

method EcmaScriptObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  root:RaiseNativeError(NativeErrorType.TypeError, 'object is not a function');
end;

method EcmaScriptObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  root:RaiseNativeError(NativeErrorType.TypeError, 'object is not a function');
end;


method EcmaScriptObject.get_Prototype: EcmaScriptObject;
begin
  var lObj: PropertyValue;
  fValues.TryGetValue('prototype', out lObj);
  exit EcmaScriptObject(lObj.Value);
end;

method EcmaScriptObject.set_Prototype(avalue: EcmaScriptObject);
begin
  var lValue := aValue;
  while assigned (lValue) and (lValue <> self) do begin
    lValue := lValue.Prototype;
  end;
  if lValue = self  then exit;
  fValues['prototype'] := new PropertyValue(PropertyAttributes.writable, aValue);
end;

method EcmaScriptObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
   root.RaiseNativeError(NAtiveErrorType.TypeError, 'Object '+ToString+' is not a function');
end;

method EcmaScriptObject.AddValue(aValue: string; aData: Object): EcmaScriptObject;
begin
  Values[aValue] := new PropertyValue(PropertyAttributes.All, aData);
  result := self;
end;

method EcmaScriptObject.AddValues(aValue: array of string; aData: array of Object): EcmaScriptObject;
begin
  if aValue.Length <> aData.Length then raise new ArgumentException;
  for i: Integer := 0 to aValue.Length -1 do begin
    Values[aValue[i]] := new PropertyValue(PropertyAttributes.All, aData[i]);
  end;
  result := self;
end;

method EcmaScriptObject.ToString: String;
begin
  var lFunc := EcmaScriptObject(Get(nil, 'toString'));
  if lFunc <> nil then exit Utilities.GetObjAsString(lFunc.CallEx(nil, self));
  result := '[object '+&Class+']';
end;

method EcmaScriptObject.PutIndex(aName: Integer; aValue: Object): Object;
begin
  exit Put(nil, aName.ToString, aValue, true);
end;

method EcmaScriptObject.GetIndex(aName: Integer): Object;
begin
  result := Get(nil, aName.ToString);
end;

method EcmaScriptObject.IsAccessorDescriptor(aProp: PropertyValue): Boolean;
begin
  exit (aProp.Get <> nil) or (aProp.Set <> nil);
end;

method EcmaScriptObject.IsDataDescriptor(aProp: PropertyValue): Boolean;
begin
  exit (PropertyAttributes.Writable in aProp.Attributes) or ((aProp.Value <> nil) and (aProp.Value <> Undefined.Instance));
end;

method EcmaScriptObject.IsGenericDescriptor(aProp: PropertyValue): Boolean;
begin
  exit not IsAccessorDescriptor(aProp) and not IsDataDescriptor(aProp);
end;

method EcmaScriptObject.FromPropertyDescriptor(aProp: PropertyValue): EcmaScriptObject;
begin
  var lRes := new EcmaScriptObject(Root, Root.ObjectPrototype);
  lRes.Put('value', aProp.Value);
  lREs.Put('writable', PropertyAttributes.writable in aProp.Attributes);
  lREs.Put('enumerable', PropertyAttributes.enumerable in aProp.Attributes);
  lREs.Put('configurable', PropertyAttributes.configurable in aProp.Attributes);
  if aProp.Get <> nil then
    lREs.Put('get', aProp.Get);
  if aProp.Set <> nil then
    lREs.Put('set', aProp.Set);
  exit lRes;
end;

method EcmaScriptObject.ToPropertyDescriptor(aProp: EcmaScriptObject): PropertyValue;
begin
  result := new PropertyValue(PropertyAttributes.None, nil);
  if aProp.HasProperty('enumerable') then
    if Utilities.GetObjAsBoolean(aProp.Get('enumerable')) then result.Attributes := result.Attributes or PropertyAttributes.Enumerable;
  if aProp.HasProperty('configurable') then
    if Utilities.GetObjAsBoolean(aProp.Get('configurable')) then result.Attributes := result.Attributes or PropertyAttributes.configurable;
  if aProp.HasProperty('value') then
    result.Value := aProp.Get('value');
 if aProp.HasProperty('writable') then
    if Utilities.GetObjAsBoolean(aProp.Get('writable')) then result.Attributes := result.Attributes or PropertyAttributes.writable;
  if aProp.HasProperty('get') then begin
    var lGet := aProp.Get('get');
    if lGet is not EcmaScriptFunctionObject then Root.RaiseNativeError(NativeErrorType.TypeError, 'get not callable');
    result.Get := EcmaScriptFunctionObject(lGet);
  end;
  if aProp.HasProperty('set') then begin
    var lset := aProp.Get('set');
    if lset is not EcmaScriptFunctionObject then Root.RaiseNativeError(NativeErrorType.TypeError, 'set not callable');
    result.Set := EcmaScriptFunctionObject(lset);
  end;
  if IsAccessorDescriptor(result) and IsDataDescriptor(result) then
    Root.RaiseNativeError(NativeErrorType.TypeError, 'both get/set and data/writable is set');

  exit result;
end;

method EcmaScriptObject.DefineOwnProperty(aName: string; aValue: PropertyValue; aThrow: Boolean := true): Boolean;
begin
  var lCurrent := GetOwnProperty(aName);
  if lCurrent = nil then begin
    if Extensible then begin
      fValues[aname] := aValue;
      exit true;
    end else begin
      if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Object not extensible');
      exit false;
    end;
  end;
  if IsGenericDescriptor(aValue) and (aValue.Attributes = PropertyAttributes.None) then exit true;
  
  if (aValue.Attributes = lCurrent.Attributes) and (Operators.SameValue(aValue.Value, lCurrent.Value)) and (aValue.Get = lCurrent.Get) and (aValue.Set = lCurrent.Set) then exit true;
  if PropertyAttributes.Configurable not in lCurrent.Attributes then begin
    if PropertyAttributes.Configurable in aValue.Attributes then begin
      if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Property '+aName+' not configurable');
      exit false;
    end;
    if (PropertyAttributes.Enumerable in aValue.Attributes) and (PropertyAttributes.Enumerable not in lCurrent.Attributes) then begin
      if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Property '+aName+' enumerable mismatch');
      exit false;
    end;
  end;
  if not IsGenericDescriptor(aValue) then begin
    if IsDataDescriptor(aValue) <> IsDataDescriptor(lCurrent) then begin
      if PropertyAttributes.Configurable not in lCurrent.Attributes then begin
        if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Property '+aName+' not configurable');
        exit false;
      end;
      if IsDataDescriptor(lCurrent) then begin
        lCurrent.Attributes := lCurrent.Attributes and not PropertyAttributes.writable;
        lCurrent.Set := avalue.Set;
        lCurrent.Get := aValue.Set;
      end else begin
        lCurrent.Attributes := lCurrent.Attributes and not PropertyAttributes.writable or aValue.Attributes;
        lCurrent.Set := avalue.Set;
        lCurrent.Get := aValue.Set;
      end;
    end else if IsDataDescriptor(aValue) and IsDataDescriptor(lCurrent) then begin
      if PropertyAttributes.Configurable not in lCurrent.Attributes then begin
        if (PropertyAttributes.writable not in lCurrent.Attributes) and (PropertyAttributes.writable in avalue.Attributes) then begin
          if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Property '+aName+' not writable');
          exit false;
        end;
        if (PropertyAttributes.writable not in lCurrent.Attributes) and not Operators.SameValue(aValue.Value, lCurrent.Value) then begin
          if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Property '+aName+' not writable');
          exit false;
        end;
      end;
    end else if IsAccessorDescriptor(aValue) and IsAccessorDescriptor(lCurrent) then begin
      if PropertyAttributes.Configurable not in lCurrent.Attributes then begin
        if (lCurrent.Get <> aValue.Get) or (lCurrent.Set <> aValue.Set) then  begin
          if aThrow then Root.RaiseNativeError(NativeErrorType.TypeError, 'Property '+aName+' not writable');
          exit false;
        end;
      end;
    end;
  end;

  lCurrent.Value := aValue.Value;
  lCurrent.Set := aValue.Set;
  lCurrent.Get := aValue.Get;
  lCurrent.Attributes := lCurrent.Attributes or aValue.Attributes;

  exit true;
end;

method EcmaScriptObject.ObjectLiteralSet(aName: string; aMode: RemObjects.Script.EcmaScript.Internal.FunctionDeclarationType; aData: Object; aStrict: Boolean): EcmaScriptObject;
begin
  var lDescr: PropertyValue;
  case aMode of
    RemObjects.Script.EcmaScript.Internal.FunctionDeclarationType.Get: lDescr := new PropertyValue(PropertyAttributes.Configurable or PropertyAttributes.Enumerable, EcmaScriptFunctionObject(aData), nil);
    
    RemObjects.Script.EcmaScript.Internal.FunctionDeclarationType.Set: lDescr := new PropertyValue(PropertyAttributes.Configurable or PropertyAttributes.Enumerable, nil, EcmaScriptFunctionObject(aData));
    else // RemObjects.Script.EcmaScript.Internal.FunctionDeclarationType.None
      lDescr := new PropertyValue(PropertyAttributes.All, aData);
  end; // case
  if aStrict and ((aName = 'eval') or (aName = 'arguments')) then begin
    Root.RaiseNativeError(NativeErrorType.SyntaxError, 'eval and arguments not allowed as object literals when using strict mode');
  end;
  var lOwn := GetOwnProperty(aName);
  if lOwn <> nil then begin
    if aStrict and IsDataDescriptor(lOwn) and IsDataDescriptor(lDescr) then Root.RaiseNativeError(NativeErrorType.SyntaxError, 'Duplicate property');
    if IsDataDescriptor(lOwn) and IsAccessorDescriptor( lDescr) then Root.RaiseNativeError(NativeErrorType.SyntaxError, 'Duplicate property');
    if IsAccessorDescriptor(lOwn) and IsDataDescriptor(lDescr) then Root.RaiseNativeError(NativeErrorType.SyntaxError, 'Duplicate property');
    if IsAccessorDescriptor(lOwn) and IsAccessorDescriptor(lDescr) and (((lOwn.Get <> nil) = (lDescr.Get <> nil)) or (lOwn.Set <> nil) = (lDescr.Set <> nil)) then Root.RaiseNativeError(NativeErrorType.SyntaxError, 'Duplicate property');
  end;
  DefineOwnProperty(aName, lDescr, false);
  exit self;
end;

constructor PropertyValue(aAttributes: PropertyAttributes; aValue: Object);
begin
  Value := aValue;
  Attributes := aAttributes;
end;

class method PropertyValue.NotEnum(aValue: Object): PropertyValue;
begin
  result := new PropertyValue(PropertyAttributes.All and not PropertyAttributes.Enumerable, aValue);
end;

class method PropertyValue.NotAllFlags(aValue: Object): PropertyValue;
begin
  result := new PropertyValue(PropertyAttributes.None, aValue);
end;

class method PropertyValue.NotDeleteAndReadOnly(aValue: Object): PropertyValue;
begin
  result := new PropertyValue(PropertyAttributes.All and not PropertyAttributes.writable and not PropertyAttributes.Configurable, aValue);
end;

constructor PropertyValue(aAttributes: PropertyAttributes; aGet, aSet: EcmaScriptFunctionObject);
begin
  Attributes := aAttributes;
  Get := aGet;
  &Set := aSet;
end;

end.