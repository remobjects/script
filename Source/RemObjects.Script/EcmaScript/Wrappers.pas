namespace RemObjects.Script.EcmaScript;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Text,
  System.Reflection;

type
  EcmaScriptScope = public class(RemObjects.Script.ScriptScope)
  private
  public
    method TryWrap(aValue: Object): Object; override;
    class method DoTryWrap(&Global: GlobalObject; aValue: Object): Object;
  end;

  Overloads = public class
  private
  public
    constructor; empty;
    constructor(aInstance: OBject; aItems: array of MethodBase);
    property Instance: Object;
    property Items: array of MethodBase;
  end;

  EcmaScriptObjectWrapper = public class(EcmaScriptBaseFunctionObject)
  private
    fValue: Object;
    fType: &Type;
    class method ConvertTo(val: Object; aType: &Type): Object;
  public
    property &Type: &Type read fType;
    property Value: Object read fValue; reintroduce;
    property &Static: Boolean read fValue = nil;
    class method IsCompatibleType(aInput: &Type; aTarget: &Type): Boolean;
    class method FindAndCallBestOverload(aMethods: array of System.Reflection.MethodBase; aRoot: GlobalObject; aNiceName: string; aSelf: Object; aArgs: array of Object): Object;
    constructor(aValue: Object; aType: &Type; aGlobal: GlobalObject);
    method DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean; override;
    method GetOwnProperty(aName: String): PropertyValue; override;
    method Get(aExecutionContext: ExecutionContext; aFlags: Integer; aName: String): Object; override;
    method Put(aExecutionContext: ExecutionContext; aName: String; aValue: Object; aFlags: Integer): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;

    method GetOwnNames: IEnumerable<String>;
    method GetNames: IEnumerator<String>; override;
  end;

implementation

method EcmaScriptScope.TryWrap(aValue: Object): Object;
begin
  exit DoTryWrap(Global, aValue);
end;

class method EcmaScriptScope.DoTryWrap(&Global: GlobalObject; aValue: Object): Object;
begin
  if (aValue = nil) or (aValue is EcmaScriptObject) then exit aValue;
  if Avalue = Undefined.Instance then exit aValue;
  var lType := aValue.GetType();
  case &Type.GetTypeCode(lType) of
    TypeCode.Boolean: exit aValue;
    TypeCode.Byte: exit Convert.ToInt32(Byte(aValue));
    TypeCode.Char: exit Char(aValue).ToString;
    TypeCode.DateTime: exit GlobalObject.DateTimeToUnix(DateTime(aValue));
    TypeCode.Decimal: exit Convert.ToDouble(Decimal(aValue));
    TypeCode.Double: exit aValue;
    TypeCode.Int16: exit Convert.ToInt32(Int16(avalue));
    TypeCode.Int32: exit aValue;
    TypeCode.Int64: exit Convert.ToDouble(Int64(avalue));
    TypeCode.SByte: exit Convert.ToInt32(SByte(avalue));
    TypeCode.Single: exit Convert.ToDouble(Single(aValue));
    TypeCode.String: exit aValue;
    TypeCode.UInt16: exit convert.ToInt32(UInt16(avalue));
    TypeCode.UInt32: exit convert.ToInt32(UInt32(avalue));
    TypeCode.UInt64: exit Convert.ToDouble(UInt64(aValue));
  end; // case
  exit new EcmaScriptObjectWrapper(aValue, lType, &Global);
end;

constructor EcmaScriptObjectWrapper(aValue: Object; aType: &Type; aGlobal: GlobalObject);
begin
  inherited constructor(aGlobal, aGlobal.NativePrototype);
  self.Class := 'Native '+aType;
  fValue := aValue;
  fType := aType;
end;

method EcmaScriptObjectWrapper.DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean;
begin
  var lItems := fType.GetMembers(BindingFlags.Public or bindingFlags.FlattenHierarchy or if Static then BindingFlags.Static else BindingFlags.Instance).Where(a->a.Name = aName).ToArray;
  if Length(lItems) = nil then begin
  exit inherited;
  end;

  if lItems.Length = 1 then begin
    if lItems[0].MemberType = MemberTypes.Field then begin
      if FieldInfo(lItems[0]).IsInitOnly then begin
        if aThrow then Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly field');
        exit false;
      end;
      FieldInfo(lItems[0]).SetValue(fValue, ConvertTo(aValue.Value, FieldInfo(lItems[0]).FieldType));
      exit true;
    end;
    if lItems[0].MemberType = MemberTypes.Property then begin
      if not PropertyInfo(lItems[0]).CanWrite then begin
        if aThrow then Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly property');
        exit false;
      end;
      PropertyInfo(lItems[0]).SetValue(fValue, ConvertTo(aValue.Value, PropertyInfo(lItems[0]).PropertyType), []);
      exit true;
    end;
  end;
  if aThrow then Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly property');
  exit false;
end;

method EcmaScriptObjectWrapper.GetOwnProperty(aName: String): PropertyValue;
begin
  var lItems := fType.GetMembers(BindingFlags.Public or bindingFlags.FlattenHierarchy or if Static then BindingFlags.Static else BindingFlags.Instance).Where(a->a.Name = aName).ToArray;
  if Length(lItems) = nil then begin
    exit inherited;
  end;

  if lItems.Length = 1 then begin
    if lItems[0].MemberType = MemberTypes.Field then     
      exit new PropertyValue(if FieldInfo(lItems[0]).IsInitOnly then PropertyAttributes.None else PropertyAttributes.writable, EcmaScriptScope.DoTryWrap(Root,FieldInfo(lItems[0]).GetValue(fValue)));
    if lItems[0].MemberType = MemberTypes.Property then
      exit new PropertyValue(if PropertyInfo(lItems[0]).CanWrite then PropertyAttributes.writable else PropertyAttributes.none, if PropertyInfo(lItems[0]).CanRead then EcmaScriptScope.DoTryWrap(Root,PropertyInfo(lItems[0]).GetValue(fValue, [])));
  end;
  if (lItems.Length > 0) and (lItems.All(a->a.MemberType = MemberTypes.Method)) then
    exit new PropertyValue(PropertyAttributes.None, new EcmaScriptObjectWrapper(new Overloads(fValue, lItems.Cast<MethodBase>().ToArray), typeof(Overloads), Root));
  exit nil;
end;

method EcmaScriptObjectWrapper.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  if typeof(MulticastDelegate).IsAssignableFrom(fType) then begin
    var lMeth := fType.GetMethod('Invoke');
    if lMeth <> nil then begin
      exit FindAndCallBestOverload([lMeth], Root, 'Delegate Invoke', fValue, args);
    end;
  end;
  if typeof(Overloads) = fType then begin
    exit FindAndCallBestOverload(Overloads(fValue).Items, Root, Overloads(fValue).Items[0].Name, Overloads(fvalue).Instance, Args);
  end;

  Root.RaiseNativeError(NativeErrorType.ReferenceError, fType.ToString+' not callable');
end;

method EcmaScriptObjectWrapper.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit Call(context, args);
end;

class method EcmaScriptObjectWrapper.FindAndCallBestOverload(aMethods: array of MethodBase; aRoot: GlobalObject; aNiceName: string; aSelf: Object; aArgs: array of Object): Object;
begin
  var lMethods := new List<System.Reflection.MethodBase>(aMethods);
  for i: Integer := 0 to length(aArgs) -1 do begin
    if aArgs[i] is EcmaScriptObjectWrapper then 
      aArgs[i] := EcmaScriptObjectWrapper(aArgs[i]).Value; // if these were wrapped before, we should unwrap
  end;

  for i: Integer:= lMethods.Count -1 downto 0 do begin
    var lMeth := lMethods[i];
    var lParams := lMeth.GetParameters();
    var lParamStart := -1;
    if lParams.Length <> length(aArgs) then begin
      if not ((lParams.Length > 0) and (Length(lParams[lParams.Length-1].GetCustomAttributes(typeof(ParamArrayAttribute), false)) >0) and (aArgs.Length >= LParams.Length-1)) then begin
        lMethods.RemoveAt(i);
        continue;
      end;
      lParamStart := lParams.Length -1;
    end else if ((lParams.Length > 0) and (Length(lParams[lParams.Length-1].GetCustomAttributes(typeof(ParamArrayAttribute), false)) >0)) then 
      lParamStart := lParams.Length -1;
    // Now we'll have to see if the parameter types matches what's in the arguments array
    for j: Integer := 0 to Length(aArgs) -1 do begin
      if not IsCompatibleType(aArgs[j]:GetType, if (lParamSTart <> -1) and (j >= lParamStart) then lParams[lParams.Length-1].ParameterType.GetElementType() else lParams[j].ParameterType) then  begin
        lMeth := nil;
        break;
      end;
    end;
    if lmeth = nil then begin
      lMethods.RemoveAt(i);
    end;
  end;

  if lMethods.Count > 1 then begin
    aRoot.RaiseNativeError(NativeErrorType.TypeError,String.Format( RemObjects.Script.Properties.Resources.Ambigious_overloaded_method_0_with_1_parameters, aNiceName, aArgs.Length));
  end else if lMethods.Count = 0 then begin
    aRoot.RaiseNativeError(NativeErrorType.TypeError,String.Format( RemObjects.Script.Properties.Resources.No_overloaded_method_0_with_1_parameters, aNiceName, aArgs.Length));
  end;
  var lMeth := lMethods[0];
  var lParams := lMeth.GetParameters();
  var lReal := new Object[lParams.Length];
  var lParamSTart := -1;
  if ((lParams.Length > 0) and (Length(lParams[lParams.Length-1].GetCustomAttributes(typeof(ParamArrayAttribute), false)) >0)) then 
    lParamStart := lParams.Length -1;
  for j: Integer := 0 to Length(aArgs) -1 do begin
    if (lParamStart <> -1) and (j >= lParamStart) then begin
      if j = lParamstart then begin
        lReal[j] := Array.CreateInstance(lParams[lParams.Length-1].ParameterType.GetElementType, Length(aArgs) - lParamSTart);
      end;
      Array(lReal[lParamSTart]).SetValue(ConvertTo(aArgs[j], lParams[lParams.Length-1].ParameterType.GetElementType()), j - lParamSTart);
    end else
      lReal[j] := ConvertTo(aArgs[j], lParams[j].ParameterType);
  end;
  try 
  exit EcmaScriptScope.DoTryWrap(aRoot, lMeth.Invoke(aSelf, lReal));
  except
    on e: TargetInvocationException do begin
      if e.InnerException is RemObjects.Script.ScriptRuntimeException then
        raise e.InnerException;
      raise new RemObjects.Script.ScriptRuntimeException(EcmaScriptScope.DoTryWrap(aRoot, e.InnerException) as EcmaScriptObject);
    end;
    on e: Exception where e is not RemObjects.Script.ScriptRuntimeException do
      raise new RemObjects.Script.ScriptRuntimeException(EcmaScriptScope.DoTryWrap(aRoot, e) as EcmaScriptObject);
  end;
end;

class method EcmaScriptObjectWrapper.IsCompatibleType(aInput: &Type; aTarget: &Type): Boolean;
begin
  if (aInput = nil) or (aInput = typeof(Undefined)) then begin
    exit not aTarget.IsValueType;
  end;
  if aTarget.IsAssignableFrom(aInput) then exit true;
  if ((aInput = typeof(Double)) or (aInput = typeof(Int32))) 
    and (&Type.GetTypeCode(aTarget) in [TypeCode.Byte, Typecode.Char, TypeCode.DateTime, TypeCode.Decimal, TypeCode.Double, TypeCode.Int16, TypeCode.Int32, TypeCode.Int64, TypeCode.SByte, TypeCode.Single, 
      TypeCode.UInt16, TypeCode.UInt32, TypeCode.UInt64]) then exit true;
  if aTarget = typeof(string) then exit true;
  exit false;
end;

class method EcmaScriptObjectWrapper.ConvertTo(val: Object; aType: &Type): Object;
begin
  if val = nil then exit nil;
  if aType = typeof(Object) then exit val;
  if val = Undefined.Instance then exit nil;
  exit Convert.ChangeType(val, aType, System.Globalization.CultureInfo.InvariantCulture);
end;

method EcmaScriptObjectWrapper.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  if not Static then Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Cannot call new on instance');
  exit FindAndCallBestOverload(fType.GetConstructors(bindingFlags.Public).Cast<MethodBase>.ToArray, Root, '<constructor>', nil, args);
end;

method EcmaScriptObjectWrapper.Get(aExecutionContext: ExecutionContext; aFlags: Integer; aName: String): Object;
begin
  if ((aFlags and 2) <> 0) and not Static then begin
    // default property
    var lItems := fType.GetDefaultMembers.Where(a->a.MemberType = MemberTypes.Property).Cast<PropertyInfo>().Where(a-> Length(a.GetIndexParameters) = 1).ToArray();
    var lIntValue: Integer;
    var lIsInt := Int32.TryParse(aName, out lIntValue);
    if lIsInt then begin
      var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = Typeof(Integer)).FirstOrDefault():GetGetMethod();
      if lCall <> nil then
        exit EcmaScriptScope.DoTryWrap(Root, lCall.Invoke(Value, [lIntValue]));
    end;
    var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = Typeof(String)).FirstOrDefault():GetGetMethod();
    if lCall <> nil then
      exit EcmaScriptScope.DoTryWrap(Root,lCall.Invoke(Value, [aName]));
    root.RaiseNativeError(NativeErrorType.ReferenceError, 'No default indexer with string or integer parameter');
  end;
  exit inherited;
end;

method EcmaScriptObjectWrapper.Put(aExecutionContext: ExecutionContext; aName: String; aValue: Object; aFlags: Integer): Object;
begin
  if ((aFlags and 2) <> 0) and not Static then begin
    // default property
    if aValue is EcmaScriptObjectWrapper then aValue := EcmaScriptObjectWrapper(aValue).value;
    var lItems := fType.GetDefaultMembers.Where(a->a.MemberType = MemberTypes.Property).Cast<PropertyInfo>().Where(a-> Length(a.GetIndexParameters) = 1).ToArray();
    var lIntValue: Integer;
    var lIsInt := Int32.TryParse(aName, out lIntValue);
    if lIsInt then begin
      var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = Typeof(Integer)).FirstOrDefault():GetSetMethod();
      if lCall <> nil then
        exit coalesce(EcmaScriptScope.DoTryWrap(Root,lCall.Invoke(Value, [lIntValue, aValue])), Undefined.Instance);
    end;
    var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = Typeof(String)).FirstOrDefault():GetSetMethod();
    if lCall <> nil then
      exit coalesce(EcmaScriptScope.DoTryWrap(Root, lCall.Invoke(Value, [aName, aValue])), Undefined.Instance);
    root.RaiseNativeError(NativeErrorType.ReferenceError, 'No default indexer setter with string or integer parameter');
  end;
  exit inherited;
end;

method EcmaScriptObjectWrapper.GetNames: IEnumerator<String>;
begin
  exit Enumerable.Concat(IntGetNames(),
    GetOwnNames).GetEnumerator;
end;

method EcmaScriptObjectWrapper.GetOwnNames: IEnumerable<String>;
begin
  exit fType.GetProperties(BindingFlags.Public or bindingFlags.FlattenHierarchy or if Static then BindingFlags.Static else BindingFlags.Instance).Where(a->0 = Length(a.GetIndexParameters)).Select(a->a.Name);
end;

constructor Overloads(aInstance: Object; aItems: array of MethodBase);
begin
  Instance := aInstance;
  Items := aItems;
end;

end.
