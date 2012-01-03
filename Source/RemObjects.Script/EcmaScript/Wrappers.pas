namespace RemObjects.Script.EcmaScript;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Reflection,
  System.Text;

type
  EcmaScriptScope = public class(RemObjects.Script.ScriptScope)
  public
    method TryWrap(aValue: Object): Object; override;
    class method DoTryWrap(&Global: GlobalObject; aValue: Object): Object;
  end;


  Overloads = public class
  public
    constructor; empty;
    constructor(aInstance: Object;  aItems: array of MethodBase);
    property Instance: Object;
    property Items: array of MethodBase;
  end;


  EcmaScriptObjectWrapper = public class(EcmaScriptBaseFunctionObject)
  private
    var fValue: Object;
    var fType: &Type;
    class method ConvertTo(val: Object; aType: &Type): Object;
  public
    constructor(aValue: Object; aType: &Type; aGlobal: GlobalObject);

    property &Type: &Type read fType;
    property Value: Object read fValue; reintroduce;
    property &Static: Boolean read fValue = nil;

    class method IsCompatibleType(sourceType: &Type;  targetType: &Type): Boolean;
    class method FindAndCallBestOverload(methods: array of MethodBase;  root: GlobalObject;  methodName: String;  &self: Object;  parameters: array of Object): Object;

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
  if  ((aValue = nil) or (aValue is EcmaScriptObject))  then
    exit  (aValue);

  if  (aValue = Undefined.Instance)  then
    exit  (aValue);

  var lType := aValue.GetType();
  case  &Type.GetTypeCode(lType)  of
    TypeCode.Boolean:   exit  (aValue);
    TypeCode.Byte:      exit  (Convert.ToInt32(Byte(aValue)));
    TypeCode.Char:      exit  (Char(aValue).ToString);
    TypeCode.DateTime:  exit  (GlobalObject.DateTimeToUnix(DateTime(aValue)));
    TypeCode.Decimal:   exit  (Convert.ToDouble(Decimal(aValue)));
    TypeCode.Double:    exit  (aValue);
    TypeCode.Int16:     exit  (Convert.ToInt32(Int16(aValue)));
    TypeCode.Int32:     exit  (aValue);
    TypeCode.Int64:     exit  (Convert.ToDouble(Int64(aValue)));
    TypeCode.SByte:     exit  (Convert.ToInt32(SByte(aValue)));
    TypeCode.Single:    exit  (Convert.ToDouble(Single(aValue)));
    TypeCode.String:    exit  (aValue);
    TypeCode.UInt16:    exit  (Convert.ToInt32(UInt16(aValue)));
    TypeCode.UInt32:    exit  (Convert.ToInt32(UInt32(aValue)));
    TypeCode.UInt64:    exit  (Convert.ToDouble(UInt64(aValue)));
  end; // case

  exit  (new EcmaScriptObjectWrapper(aValue, lType, &Global));
end;


constructor EcmaScriptObjectWrapper(aValue: Object; aType: &Type; aGlobal: GlobalObject);
begin
  inherited constructor(aGlobal, aGlobal.NativePrototype);

  self.Class := 'Native '+aType;
  self.fValue := aValue;
  self.fType := aType;
end;


method EcmaScriptObjectWrapper.DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean;
begin
  var lItems := fType.GetMembers(BindingFlags.Public or BindingFlags.FlattenHierarchy or
                   if  self.Static  then  BindingFlags.Static  else  BindingFlags.Instance).Where(a->a.Name = aName).ToArray();

  if  (length(lItems) = 0)  then
    exit inherited;

  if  (lItems.Length = 1)  then  begin
    if  (lItems[0].MemberType = MemberTypes.Field)  then  begin
      if  (FieldInfo(lItems[0]).IsInitOnly)  then  begin
        if  (aThrow)  then
          Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly field');
        exit  (false);
      end;

      FieldInfo(lItems[0]).SetValue(fValue, ConvertTo(aValue.Value, FieldInfo(lItems[0]).FieldType));

      exit  (true);
    end;

    if  (lItems[0].MemberType = MemberTypes.Property)  then  begin
      if  (not PropertyInfo(lItems[0]).CanWrite)  then  begin
        if  (aThrow)  then
          Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly property');

        exit  (false);
      end;

      PropertyInfo(lItems[0]).SetValue(fValue, ConvertTo(aValue.Value, PropertyInfo(lItems[0]).PropertyType), []);

      exit  (true);
    end;
  end;

  if  (aThrow)  then
    Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly property');

  exit  (false);
end;


method EcmaScriptObjectWrapper.GetOwnProperty(aName: String): PropertyValue;
begin
  var lItems := fType.GetMembers(BindingFlags.Public  or  BindingFlags.FlattenHierarchy  or
                   if  (self.Static)  then  BindingFlags.Static  else  BindingFlags.Instance).Where(a->a.Name = aName).ToArray();

  if  (length(lItems) = 0)  then
    exit inherited;


  if  (lItems.Length = 1)  then  begin
    if  (lItems[0].MemberType = MemberTypes.Field)  then     
      exit  (new PropertyValue(if FieldInfo(lItems[0]).IsInitOnly then PropertyAttributes.None else PropertyAttributes.writable,
                   EcmaScriptScope.DoTryWrap(Root,FieldInfo(lItems[0]).GetValue(fValue))));

    if  (lItems[0].MemberType = MemberTypes.Property)  then
      exit  (new PropertyValue(if PropertyInfo(lItems[0]).CanWrite then PropertyAttributes.writable else PropertyAttributes.None,
                   if  PropertyInfo(lItems[0]).CanRead  then  EcmaScriptScope.DoTryWrap(Root,PropertyInfo(lItems[0]).GetValue(fValue, []))));
  end;

  if  ((lItems.Length > 0) and (lItems.All(a->a.MemberType = MemberTypes.Method)))  then
    exit  (new PropertyValue(PropertyAttributes.None,
                   new EcmaScriptObjectWrapper(new Overloads(fValue, lItems.Cast<MethodBase>().ToArray), typeOf(Overloads), Root)));

  exit  (nil);
end;


method EcmaScriptObjectWrapper.Call(context: ExecutionContext;  params args: array of Object): Object;
begin
  if  (typeOf(MulticastDelegate).IsAssignableFrom(fType))  then  begin
    var lMeth := fType.GetMethod('Invoke');
    if  (assigned(lMeth))  then
      exit  (FindAndCallBestOverload([lMeth], Root, 'Delegate Invoke', fValue, args));
  end;

  if  (typeOf(Overloads) = fType)  then
    exit  (FindAndCallBestOverload(Overloads(fValue).Items, Root, Overloads(fValue).Items[0].Name, Overloads(fValue).Instance, args));

  Root.RaiseNativeError(NativeErrorType.ReferenceError, fType.ToString+' not callable');
end;


method EcmaScriptObjectWrapper.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit  (Call(context, args));
end;


class method EcmaScriptObjectWrapper.FindAndCallBestOverload(methods: array of MethodBase;  root: GlobalObject;  methodName: String;
                   &self: Object;  parameters: array of Object): Object;
begin
  var lMethods := new List<MethodBase>(methods);

  for  i: Int32  :=  0  to  length(parameters)-1  do  begin
    if  (parameters[i] is EcmaScriptObjectWrapper)  then
      parameters[i] := EcmaScriptObjectWrapper(parameters[i]).Value; // if these were wrapped before, we should unwrap
  end;

  for  i: Int32  :=  lMethods.Count-1  downto  0  do  begin
    var lMeth := lMethods[i];
    var lParams := lMeth.GetParameters();
    var lParamStart := -1;

    if  (lParams.Length <> length(parameters))  then  begin
      if  (not ((lParams.Length > 0)  and  (length(lParams[lParams.Length-1].GetCustomAttributes(typeOf(ParamArrayAttribute), false)) > 0)
                   and  (parameters.Length >= lParams.Length-1)))  then  begin
        lMethods.RemoveAt(i);

        continue;
      end;

      lParamStart := lParams.Length -1;
    end
    else if  ((lParams.Length > 0)  and  (length(lParams[lParams.Length-1].GetCustomAttributes(typeOf(ParamArrayAttribute), false)) > 0))  then 
      lParamStart := lParams.Length -1;
    // Now we'll have to see if the parameter types matches what's in the arguments array
    for  j: Int32  :=  0  to  length(parameters)-1  do  begin
      if  (not IsCompatibleType(parameters[j]:GetType(), iif(((lParamStart <> -1)  and  (j >= lParamStart)), lParams[lParams.Length-1].ParameterType.GetElementType(), lParams[j].ParameterType)))  then  begin
        lMeth := nil;
        break;
      end;
    end;

    if  (lMeth = nil)  then
      lMethods.RemoveAt(i);
  end;

  if  (lMethods.Count > 1)  then
    root.RaiseNativeError(NativeErrorType.TypeError,String.Format( RemObjects.Script.Properties.Resources.Ambigious_overloaded_method_0_with_1_parameters, methodName, parameters.Length));

  if  (lMethods.Count = 0)  then
    root.RaiseNativeError(NativeErrorType.TypeError,String.Format( RemObjects.Script.Properties.Resources.No_overloaded_method_0_with_1_parameters, methodName, parameters.Length));

  var lMeth := lMethods[0];
  var lParams := lMeth.GetParameters();
  var lReal := new Object[lParams.Length];
  var lParamStart := -1;

  if  ((lParams.Length > 0)  and  (length(lParams[lParams.Length-1].GetCustomAttributes(typeOf(ParamArrayAttribute), false)) > 0)) then 
    lParamStart := lParams.Length -1;

  for  j: Int32  :=  0  to  length(parameters)-1  do  begin
    if  ((lParamStart <> -1)  and  (j >= lParamStart))  then  begin
      if  (j = lParamStart)  then
        lReal[j] := Array.CreateInstance(lParams[lParams.Length-1].ParameterType.GetElementType, length(parameters) - lParamStart);

      Array(lReal[lParamStart]).SetValue(ConvertTo(parameters[j], lParams[lParams.Length-1].ParameterType.GetElementType()), j - lParamStart);
    end
    else  begin
      lReal[j] := ConvertTo(parameters[j], lParams[j].ParameterType);
    end;
  end;

  try
    if  (lMeth  is  ConstructorInfo)  then
      exit  (EcmaScriptScope.DoTryWrap(root, ConstructorInfo(lMeth).Invoke(lReal)));

    exit  (EcmaScriptScope.DoTryWrap(root, lMeth.Invoke(&self, lReal)));
  except
    on  ex: TargetInvocationException  do  begin
      if  (ex.InnerException is RemObjects.Script.ScriptRuntimeException)  then
        raise ex.InnerException;

      raise  new RemObjects.Script.ScriptRuntimeException(EcmaScriptScope.DoTryWrap(root, ex.InnerException) as EcmaScriptObject);
    end;
    on  ex: Exception where ex is not RemObjects.Script.ScriptRuntimeException  do
      raise new RemObjects.Script.ScriptRuntimeException(EcmaScriptScope.DoTryWrap(root, ex) as EcmaScriptObject);
  end;
end;


class method EcmaScriptObjectWrapper.IsCompatibleType(sourceType: &Type;  targetType: &Type): Boolean;
begin
  if  ((sourceType = nil)  or  (sourceType = typeOf(Undefined)))  then
    exit  (not targetType.IsValueType);

  if  (targetType.IsAssignableFrom(sourceType))  then
    exit  (true);

  if  (((sourceType = typeOf(Double))  or  (sourceType = typeOf(Int32)))
                   and  (&Type.GetTypeCode(targetType)  in  [ TypeCode.Byte, TypeCode.Char, TypeCode.DateTime, TypeCode.Decimal,
                                       TypeCode.Double, TypeCode.Int16, TypeCode.Int32, TypeCode.Int64, TypeCode.SByte,
                                       TypeCode.Single, TypeCode.UInt16, TypeCode.UInt32, TypeCode.UInt64 ]))  then
    exit  (true);

  if  (targetType = typeOf(String))  then
    exit  (true);

  exit  (false);
end;


class method EcmaScriptObjectWrapper.ConvertTo(val: Object;  aType: &Type): Object;
begin
  if  (not assigned(val))  then
    exit  (nil);

  if  (aType = typeOf(Object))  then
    exit  (val);

  if  (val = Undefined.Instance)  then
    exit  (nil);

  if  (aType.IsAssignableFrom(val.GetType()))  then
    exit  (val);

  with matching  wrapper := EcmaScriptObjectWrapper(val)  do
    exit  (ConvertTo(wrapper.Value, aType));

  exit  (Convert.ChangeType(val, aType, System.Globalization.CultureInfo.InvariantCulture));
end;


method EcmaScriptObjectWrapper.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  if  (not self.Static)  then
    self.Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Cannot call new on instance');

  exit  (EcmaScriptObjectWrapper.FindAndCallBestOverload(self.fType.GetConstructors(BindingFlags.Public Or BindingFlags.Instance).Cast<MethodBase>.ToArray(),
                   self.Root, '<constructor>', nil, args));
end;


method EcmaScriptObjectWrapper.Get(aExecutionContext: ExecutionContext; aFlags: Integer; aName: String): Object;
begin
  if  (((aFlags and 2) <> 0)  and  not self.Static)  then  begin
    // default property
    var lItems := fType.GetDefaultMembers.Where(a->a.MemberType = MemberTypes.Property).Cast<PropertyInfo>()
                   .Where(a-> length(a.GetIndexParameters) = 1).ToArray();

    var lIntValue: Int32;
    var lIsInt := Int32.TryParse(aName, out lIntValue);

    if  (lIsInt)  then  begin
      var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = typeOf(Integer)).FirstOrDefault():GetGetMethod();
      if  (assigned(lCall))  then
        exit  (EcmaScriptScope.DoTryWrap(Root, lCall.Invoke(Value, [lIntValue])));
    end;

    var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = typeOf(String)).FirstOrDefault():GetGetMethod();
    if  (assigned(lCall))  then
      exit  (EcmaScriptScope.DoTryWrap(Root,lCall.Invoke(Value, [aName])));

    self.Root.RaiseNativeError(NativeErrorType.ReferenceError, 'No default indexer with string or integer parameter');
  end;

  exit inherited;
end;


method EcmaScriptObjectWrapper.Put(aExecutionContext: ExecutionContext; aName: String; aValue: Object; aFlags: Integer): Object;
begin
  if  (((aFlags and 2) <> 0) and not self.Static)  then  begin
    // default property
    if  (aValue is EcmaScriptObjectWrapper)  then
      aValue := EcmaScriptObjectWrapper(aValue).Value;

    var lItems := fType.GetDefaultMembers.Where(a->a.MemberType = MemberTypes.Property).Cast<PropertyInfo>()
                   .Where(a-> length(a.GetIndexParameters) = 1).ToArray();

    var lIntValue: Int32;
    var lIsInt := Int32.TryParse(aName, out lIntValue);

    if  (lIsInt)  then  begin
      var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = typeOf(Integer)).FirstOrDefault():GetSetMethod();
      if  (assigned(lCall))  then
        exit  (coalesce(EcmaScriptScope.DoTryWrap(Root,lCall.Invoke(Value, [lIntValue, aValue])), Undefined.Instance));
    end;

    var lCall := lItems.Where(a->a.GetIndexParameters()[0].ParameterType = typeOf(String)).FirstOrDefault():GetSetMethod();
    if  (assigned(lCall))  then
      exit  (coalesce(EcmaScriptScope.DoTryWrap(Root, lCall.Invoke(Value, [aName, aValue])), Undefined.Instance));

    self.Root.RaiseNativeError(NativeErrorType.ReferenceError, 'No default indexer setter with string or integer parameter');
  end;

  exit  inherited;
end;


method EcmaScriptObjectWrapper.GetNames(): IEnumerator<String>;
begin
  exit  (Enumerable.Concat(IntGetNames(), GetOwnNames).GetEnumerator());
end;


method EcmaScriptObjectWrapper.GetOwnNames(): IEnumerable<String>;
begin
  exit  (fType.GetProperties(BindingFlags.Public  or  BindingFlags.FlattenHierarchy or
                   if  (self.Static)  then  BindingFlags.Static  else  BindingFlags.Instance)
                                       .Where(a -> 0 = length(a.GetIndexParameters)).Select(a->a.Name));
end;


constructor Overloads(aInstance: Object;  aItems: array of MethodBase);
begin
  self.Instance := aInstance;
  self.Items := aItems;
end;


end.