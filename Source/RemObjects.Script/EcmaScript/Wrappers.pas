namespace RemObjects.Script.EcmaScript;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  EcmaScriptScope = public class(RemObjects.Script.ScriptScope)
  private
  public
    method TryWrap(aValue: Object): Object; override;
  end;

  EcmaScriptObjectWrapper = public class(EcmaScriptBaseFunctionObject)
  private
    fValue: Object;
    fType: &Type;
  public
    class method FindAndCallBestOverload(aMethods: array of System.Reflection.MethodBase; aSelf: Object; aArgs: array of Object): Object;
    constructor(aValue: Object; aType: &Type; aGlobal: GlobalObject);
    method DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean; override;
    method GetOwnProperty(aName: String): PropertyValue; override;
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;
  end;

implementation

method EcmaScriptScope.TryWrap(aValue: Object): Object;
begin
  if (aValue = nil) or (aValue is EcmaScriptObject) then exit aValue;
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
  exit EcmaScriptObjectWrapper(aValue, lType, self.Global);
end;

constructor EcmaScriptObjectWrapper(aValue: Object; aType: &Type; aGlobal: GlobalObject);
begin
  inherited constructor(aGlobal, aGlobal.ObjectPrototype);
  self.Class := 'Native '+aType;
  fValue := aValue;
  fType := aType;
end;

method EcmaScriptObjectWrapper.DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean;
begin

end;

method EcmaScriptObjectWrapper.GetOwnProperty(aName: String): PropertyValue;
begin
end;

method EcmaScriptObjectWrapper.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  if typeof(MulticastDelegate).IsAssignableFrom(fType) then begin
    var lMeth := fType.GetMethod('Invoke');
    if lMeth <> nil then begin
      exit FindAndCallBestOverload([lMeth], fValue, args);
    end;
  end;
  Root.RaiseNativeError(NativeErrorType.ReferenceError, lType.ToString+' not callable');
end;

method EcmaScriptObjectWrapper.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit Call(context, args);
end;

end.
