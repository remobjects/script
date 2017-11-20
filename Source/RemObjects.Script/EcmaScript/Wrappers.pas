//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

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
    constructor(aInstance: Object;  aItems: List<MethodBase>);
    property Instance: Object;
    property Items: List<MethodBase>;
  end;


  EcmaScriptObjectWrapper = public class(EcmaScriptBaseFunctionObject)
  private
    var fValue: Object;
    var fType: &Type;

    class method FindBestMatchingMethod(aMethods: List<MethodBase>; aParameters: array of Object);
    class method BetterFunctionMember(aBest, aCurrent: MethodEntry; aParameters: array of Object): Boolean;
    class method BetterConversionFromExpression(aMine: Object; aBest, aCurrent: &Type): Integer;
    class method IsMoreSpecific(aBest, aCurrent: &Type): Integer;
    class method IsInteger(o: &Type): Boolean;
    class method IsFloat(o: &Type): Boolean;
  public
    constructor(aValue: Object; aType: &Type; aGlobal: GlobalObject);

    property &Type: &Type read fType;
    property Value: Object read fValue; reintroduce;
    property &Static: Boolean read fValue = nil;

    class method UnwrapValue(value: Object): Object;
    class method IsCompatibleType(sourceType: &Type;  targetType: &Type): Boolean;
    class method ConvertTo(value: Object;  &type: &Type): Object;
    class method FindAndCallBestOverload(methods: List<MethodBase>;  root: GlobalObject;  methodName: String;  &self: Object;  parameters: array of Object): Object;

    method DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean; override;
    method GetOwnProperty(name: String;  getPropertyValue: Boolean): PropertyValue; override;
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
    TypeCode.DateTime:  exit  (&Global.CreateDateObject(DateTime(aValue).ToUniversalTime()));
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

      FieldInfo(lItems[0]).SetValue(fValue, EcmaScriptObjectWrapper.ConvertTo(aValue.Value, FieldInfo(lItems[0]).FieldType));

      exit  (true);
    end;

    if  (lItems[0].MemberType = MemberTypes.Property)  then  begin
      if  (not PropertyInfo(lItems[0]).CanWrite)  then  begin
        if  (aThrow)  then
          Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly property');

        exit  (false);
      end;

      PropertyInfo(lItems[0]).SetValue(fValue, EcmaScriptObjectWrapper.ConvertTo(aValue.Value, PropertyInfo(lItems[0]).PropertyType), []);

      exit  (true);
    end;
  end;

  if  (aThrow)  then
    Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Readonly property');

  exit  (false);
end;


method EcmaScriptObjectWrapper.GetOwnProperty(name: String;  getPropertyValue: Boolean): PropertyValue;
begin
  var lItems := fType.GetMembers(BindingFlags.Public  or  BindingFlags.FlattenHierarchy  or  iif(self.Static, BindingFlags.Static, BindingFlags.Instance)).Where(a->a.Name = name).ToList();

  if  (length(lItems) = 0)  then
    exit inherited;


  if  (lItems.Count  = 1)  then  begin
    if  (lItems[0].MemberType = MemberTypes.Field)  then
      exit new PropertyValue(iif(FieldInfo(lItems[0]).IsInitOnly, PropertyAttributes.None, PropertyAttributes.Writable),
                   iif(getPropertyValue, EcmaScriptScope.DoTryWrap(self.Root,FieldInfo(lItems[0]).GetValue(fValue)), nil));

    if  (lItems[0].MemberType = MemberTypes.Property)  then
      exit new PropertyValue(iif(PropertyInfo(lItems[0]).CanWrite, PropertyAttributes.Writable, PropertyAttributes.None),
                   iif(getPropertyValue and PropertyInfo(lItems[0]).CanRead, EcmaScriptScope.DoTryWrap(self.Root,PropertyInfo(lItems[0]).GetValue(fValue, [])), nil));
  end;

  if  ((lItems.Count > 0) and (lItems.All(a->a.MemberType = MemberTypes.Method)))  then
    exit new PropertyValue(PropertyAttributes.None,
                   new EcmaScriptObjectWrapper(new Overloads(fValue, lItems.Cast<MethodBase>().ToList), typeOf(Overloads), Root));

  exit nil;
end;


method EcmaScriptObjectWrapper.Call(context: ExecutionContext;  params args: array of Object): Object;
begin
  if  (typeOf(MulticastDelegate).IsAssignableFrom(fType))  then  begin
    var lMeth := fType.GetMethod('Invoke');
    if  (assigned(lMeth))  then
      exit  (FindAndCallBestOverload(new List<MethodBase>([lMeth]), Root, 'Delegate Invoke', fValue, args));
  end;

  if  (typeOf(Overloads) = fType)  then
    exit  (FindAndCallBestOverload(Overloads(fValue).Items, Root, Overloads(fValue).Items[0].Name, Overloads(fValue).Instance, args));

  Root.RaiseNativeError(NativeErrorType.ReferenceError, fType.ToString+' not callable');
end;


method EcmaScriptObjectWrapper.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit  (Call(context, args));
end;

type
  MethodEntry = class
  public
    property &Method: MethodBase;    
    property ParamsType: &Type; // if it's an is params 
    property Args: array of ParameterInfo;
  end;

class method EcmaScriptObjectWrapper.FindBestMatchingMethod(aMethods: List<MethodBase>; aParameters: array of Object);
begin
  var lWork := new List<MethodEntry>();
  for each el in aMethods do begin
    var lPars := coalesce(el.GetParameters(), array of ParameterInfo([]));
    if lPars.Any(b-> b.ParameterType.IsByRef) then continue;
    var lArrType: &Type := nil;
    if length(aParameters) <> length(lPars) then begin
      if (length(aParameters) >= length(lPars)-1) and
        (length(lPars) > 0) and 
        (length(lPars[length(lPars)-1].GetCustomAttributes(typeOf(ParamArrayAttribute), true)) >0) then begin
        lArrType := lPars[length(lPars)-1].ParameterType.GetElementType();
      end else continue;
    end else
      if (length(lPars) > 0) and 
        (length(lPars[length(lPars)-1].GetCustomAttributes(typeOf(ParamArrayAttribute), true)) >0)
        and (aParameters[length(aParameters)-1] is not EcmaScriptArrayObject) then
      lArrType := lPars[length(lPars)-1].ParameterType.GetElementType();
    for i: Integer := 0 to aParameters.Length -1 do begin
      if not IsCompatibleType(aParameters[i]:GetType, if i < lPars.Length then coalesce(lArrType, lPars[i].ParameterType) else lArrType) then begin
        lPars := nil;
        break;
      end;
    end;
    if lPars = nil then continue;
    lWork.Add(new MethodEntry(&Method := el, ParamsType := lArrType, Args := lPars));
  end;

  var lResult := -1;
  for i: Integer := 0 to lWork.Count -1 do begin
    if lResult = -1 then begin
      lResult := i;
      continue
    end;

    if BetterFunctionMember(lWork[lResult], lWork[i], aParameters) then
      lResult := i
  end;

  if lResult <> -1 then begin
    var n := lWork[lResult];
    aMethods.Clear;
    aMethods.Add(n.Method);
  end;
end;


class method EcmaScriptObjectWrapper.FindAndCallBestOverload(methods: List<MethodBase>;  root: GlobalObject;  methodName: String;  &self: Object;  parameters: array of Object): Object;
begin
  var lMethods := methods;

  for i: Int32 := 0 to length(parameters)-1 do
    parameters[i] := EcmaScriptObjectWrapper.UnwrapValue(parameters[i]);

  FindBestMatchingMethod(lMethods, parameters);

  if lMethods.Count > 1 then
    root.RaiseNativeError(NativeErrorType.TypeError, String.Format(RemObjects.Script.Properties.Resources.Ambigious_overloaded_method_0_with_1_parameters, methodName, parameters.Length));

  if lMethods.Count = 0 then
    root.RaiseNativeError(NativeErrorType.TypeError, String.Format(RemObjects.Script.Properties.Resources.No_overloaded_method_0_with_1_parameters, methodName, parameters.Length));

  var lMeth := lMethods[0];
  var lParams := lMeth.GetParameters();
  var lReal := new Object[lParams.Length];
  var lParamStart := -1;

  if  ((lParams.Length > 0)  and  (length(lParams[lParams.Length-1].GetCustomAttributes(typeOf(ParamArrayAttribute), false)) > 0)) then 
    lParamStart := lParams.Length -1;

  for j: Int32 := 0 to length(parameters)-1 do begin
    if (lParamStart <> -1) and (j >= lParamStart) then begin
      if j = lParamStart then
        lReal[j] := Array.CreateInstance(lParams[lParams.Length-1].ParameterType.GetElementType, length(parameters) - lParamStart);

      Array(lReal[lParamStart]).SetValue(EcmaScriptObjectWrapper.ConvertTo(parameters[j], lParams[lParams.Length-1].ParameterType.GetElementType()), j - lParamStart);
    end
    else begin
      lReal[j] := EcmaScriptObjectWrapper.ConvertTo(parameters[j], lParams[j].ParameterType);
    end;
  end;

  for j: Int32 := length(parameters) to lReal.Length -1 do  begin
    var lParameter: ParameterInfo := lParams[j];
    if (lParamStart <> -1) and (j >= lParamStart) then begin
      lReal[j] := Array.CreateInstance(lParams[lParams.Length-1].ParameterType.GetElementType, 0);// call method with empty array
      break;// create empty array and exit no more parameters
    end
    else begin
      if ParameterAttributes.HasDefault = (lParameter.Attributes and ParameterAttributes.HasDefault) then begin
        lReal[j] := lParameter.RawDefaultValue;
      end
      else begin
        if System.Type.GetTypeCode(lParameter.ParameterType) = TypeCode.Object then
          lReal[j] := Undefined.Instance;
      end;
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
  if targetType.IsGenericParameter then
    exit true;

  if  (((sourceType = typeOf(Double))  or  (sourceType = typeOf(Int32)))
                   and  (&Type.GetTypeCode(targetType)  in  [ TypeCode.Byte, TypeCode.Char, TypeCode.DateTime, TypeCode.Decimal,
                                       TypeCode.Double, TypeCode.Int16, TypeCode.Int32, TypeCode.Int64, TypeCode.SByte,
                                       TypeCode.Single, TypeCode.UInt16, TypeCode.UInt32, TypeCode.UInt64 ]))  then
    exit  (true);

  if  (targetType = typeOf(String))  then
    exit  (true);

  exit  (false);
end;


class method EcmaScriptObjectWrapper.UnwrapValue(value: Object): Object;
begin
  // Preferred method is EcmaScriptObjectWrapper.ConvertTo(Object, &Type): Object;
  // This method uses way less sophiscated approach, so some of the JS-specific value transitions are lost

  // if provided object was wrapped before then we should unwrap it
  with matching objectWrapper := EcmaScriptObjectWrapper(value) do
    exit objectWrapper.Value; 

  // DateTime handling
  with matching scriptObject := EcmaScriptObject(value) do begin
    if scriptObject.Class <> 'Date' then
      exit coalesce(scriptObject.Value, value);

    if scriptObject.Value.GetType() = typeOf(DateTime) then
      exit DateTime(scriptObject.Value).ToLocalTime();

    exit GlobalObject.UnixToDateTime(Convert.ToInt64(scriptObject.Value)).ToLocalTime();
  end;

  exit value;
end;


class method EcmaScriptObjectWrapper.ConvertTo(value: Object;  &type: &Type): Object;
begin
  // Undefined -> Double is Double.NaN, not just nil
  // Null -> Double is 0.0, not just nil
  if &type = typeOf(Double) then begin
    if value = Undefined.Instance then
      exit Double.NaN;

    if not assigned(value) then
      exit 0;
  end;

  if (not assigned(value)) then
    exit nil;

  if value = Undefined.Instance then
    exit iif(&type = typeOf(Object), Undefined.Instance, nil);

  with matching wrapper := EcmaScriptObjectWrapper(value) do
    exit ConvertTo(wrapper.Value, &type);

  // Unwrap EcmaScriptObject before conversion
  with matching wrapper := EcmaScriptObject(value) do begin
    if wrapper.Class = 'Date' then begin
      if wrapper.Value.GetType() = typeOf(DateTime) then
        value := DateTime(wrapper.Value).ToLocalTime()
      else
        value := GlobalObject.UnixToDateTime(Convert.ToInt64(wrapper.Value)).ToLocalTime();

      exit ConvertTo(value, &type);
    end;

    // For arbitrary EcmaScriptObject objects their .toString() method is called
    if &type = typeOf(String) then
      exit value.ToString();

    if assigned(wrapper.Value) then
      exit ConvertTo(wrapper.Value, &type);
  end;

  if &type.IsAssignableFrom(value.GetType()) then
    exit value;

  // Special cases
{$REGION Double -> DateTime }
  // Double -> DateTime conversion
  // type in [ .. ] doesn't compile on Silverlight
  var lValueType: &Type := value.GetType();
  if (&type = typeOf(DateTime)) and ((lValueType = typeOf(Double)) or (lValueType = typeOf(Int32)) or (lValueType = typeOf(Int64)) or (lValueType = typeOf(UInt32)) or (lValueType = typeOf(UInt64))) then
    exit GlobalObject.UnixToDateTime(Convert.ToInt64(value)).ToLocalTime();

  // Implicitly convert Date to its String representation while sending it to .NET code
  if value.GetType() = typeOf(DateTime) then begin
    if &type = typeOf(String) then
      exit Convert.ChangeType(value, &type, System.Globalization.CultureInfo.CurrentCulture);

    // Implicit DateTime -> Double conversion
    if &type = typeOf(Double) then
      exit GlobalObject.DateTimeToUnix(DateTime(value));
  end;
{$ENDREGION}

{$REGION Boolean }
  // Special-case Boolean conversions
  if &type = typeOf(Boolean) then begin
    // Number.NaN equals to false in JS while .NET converts it to true
    if (value.GetType() = typeOf(Double)) and Double.IsNaN(Double(value)) then
      exit false;

    // Arbitrary Strings are converted to Boolean using simple rule - empty string is False, anything else is True
    if value.GetType() = typeOf(String) then
      exit not String.IsNullOrEmpty(String(value));

    if (value is EcmaScriptObject) then
      exit true;
  end;

  // In JS Boolean .toString is always lowercased, while .NET returs 'True' or 'False'
  if (value.GetType() = typeOf(Boolean)) and (&type = typeOf(String)) then
    exit iif(Boolean(value), 'true', 'false');
{$ENDREGION}

{$REGION Double }
  // Special-case Double conversions
  if &type = typeOf(Double) then begin
    // Arbitrary strings are converted to Double.NaN
    if value.GetType() = typeOf(String) then begin
      var lResult: Double;
      if Double.TryParse(String(value), out lResult) then
        exit lResult;

      exit Double.NaN;
    end;

    // Special rules for Boolean -> Double conversion (JS supports this)
    if value.GetType() = typeOf(Boolean) then
      exit iif(Boolean(value),1.0,0.0);
  end;
{$ENDREGION}

{$REGION Int32, Int64, UInt32, UInt64}
  // &type in [ .. ] doesn't compile on Silverlight
  if (&type = typeOf(Int32)) or (&type = typeOf(Int64)) or (&type = typeOf(UInt32)) or (&type = typeOf(UInt64)) then begin
    // Convert String to Double first, and then to the target type
    if value.GetType() = typeOf(String) then begin
      var lResult: Double;
      if Double.TryParse(String(value), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out lResult) then
        exit Convert.ChangeType(lResult, &type, System.Globalization.CultureInfo.InvariantCulture);

      raise new FormatException('Cannot convert provided String value to an Integer value');
    end;

    // Throw away fraction part
    if value.GetType() = typeOf(Double) then
      exit Convert.ChangeType(Math.Truncate(Double(value)), &type, System.Globalization.CultureInfo.InvariantCulture);
  end;
{$ENDREGION}

  exit Convert.ChangeType(value, &type, System.Globalization.CultureInfo.InvariantCulture);
end;


method EcmaScriptObjectWrapper.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  if  (not self.Static)  then
    self.Root.RaiseNativeError(NativeErrorType.ReferenceError, 'Cannot call new on instance');

  exit  (EcmaScriptObjectWrapper.FindAndCallBestOverload(self.fType.GetConstructors(BindingFlags.Public Or BindingFlags.Instance).Cast<MethodBase>.ToList(),
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

class method EcmaScriptObjectWrapper.BetterFunctionMember(aBest, aCurrent: MethodEntry; aParameters: array of Object): Boolean;
begin
  var lAtLeastOneBetterConversion := false;
  for i: System.Int32 := 0 to aParameters.Length -1 do begin
    var lBestParam := if i >= length(aBest.Args) then aBest.ParamsType else aBest.Args[i].ParameterType;
    var lCurrentParam := if i >= length(aCurrent.Args) then aCurrent.ParamsType else aCurrent.Args[i].ParameterType;
    case BetterConversionFromExpression(aParameters[i], lBestParam, lCurrentParam) of
      1: exit false;
      -1: lAtLeastOneBetterConversion := true;
    end;
  end;
  if lAtLeastOneBetterConversion then    
    exit true;
  if (length(aBest.Method.GetGenericArguments) <> 0) and (length(aCurrent.Method.GetGenericArguments) = 0) then    exit true;
  if (length(aBest.Method.GetGenericArguments) = 0) and (length(aCurrent.Method.GetGenericArguments) <> 0) then  exit false; // exit if the reverse is true
  if length(aBest.Args) > length(aCurrent.Args) then exit true;
  if length(aBest.Args) < length(aCurrent.Args) then exit false;

  for i: Integer := 0 to length(aParameters) -1 do begin
    var lBestParam := if i >= length(aBest.Args) then aBest.ParamsType else aBest.Args[i].ParameterType;
    var lCurrentParam := if i >= length(aCurrent.Args) then aCurrent.ParamsType else aCurrent.Args[i].ParameterType;
    case IsMoreSpecific(lBestParam, lCurrentParam) of
      1: exit false;
      -1: lAtLeastOneBetterConversion := true;
    end;
  end;
  exit lAtLeastOneBetterConversion;
end;

class method EcmaScriptObjectWrapper.BetterConversionFromExpression(aMine: Object; aBest: &Type; aCurrent: &Type): Integer;
begin
  if aBest = aCurrent then
    exit 0;
  var lGT := aMine:GetType;
  if lGT = aBest then exit 1;
  if lGT = aCurrent then exit -1;
  if IsCompatibleType(aBest, aCurrent) and not IsCompatibleType(aCurrent, aBest) then exit 1;
  if IsCompatibleType(aCurrent, aBest) and not IsCompatibleType(aBest, aCurrent) then exit -1;

  if IsCompatibleType(lGT, aBest) and not IsCompatibleType(lGT, aCurrent) then exit 1;
  if IsCompatibleType(lGT, aCurrent) and not IsCompatibleType(lGT, aBest) then exit -1;

  if (lGT = nil) and (aBest.IsValueType) and (not aCurrent.IsValueType) then exit -1;
  if (lGT = nil) and (not aBest.IsValueType) and (aCurrent.IsValueType) then exit 1;

  if lGT <> nil then begin
    if IsFloat(lGT) and IsFloat(aCurrent) and not IsFloat(aBest) then exit -1;
    if IsFloat(lGT) and not IsFloat(aCurrent) and IsFloat(aBest) then exit 1;

    if IsInteger(lGT) and IsInteger(aCurrent) and not IsInteger(aBest) then exit -1;
    if IsInteger(lGT) and not IsInteger(aCurrent) and IsInteger(aBest) then exit 1;
  end;

  exit 0;
end;

class method EcmaScriptObjectWrapper.IsMoreSpecific(aBest: &Type; aCurrent: &Type): Integer;
begin
  if aBest.IsGenericParameter and not aCurrent.IsGenericParameter then exit -1;
  if not aBest.IsGenericParameter and aCurrent.IsGenericParameter then exit 1;

  exit 0;
end;

class method EcmaScriptObjectWrapper.IsInteger(o: &Type): Boolean;
begin
  exit &Type.GetTypeCode(o) 
    in [TypeCode.Byte, TypeCode.Int16, TypeCode.Int32, TypeCode.Int64,
    TypeCode.SByte, TypeCode.UInt16, TypeCode.UInt32, TypeCode.UInt64];
end;

class method EcmaScriptObjectWrapper.IsFloat(o: &Type): Boolean;
begin
  exit &Type.GetTypeCode(o) 
    in [TypeCode.Decimal, TypeCode.Single, TypeCode.Double];
end;


constructor Overloads(aInstance: Object;  aItems: List<MethodBase>);
begin
  self.Instance := aInstance;
  self.Items := aItems;
end;


end.