{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)
  public
    class var BaseString: String := '0123456789abcdefghijklmnopqrstuvwxyz'; readonly;
    method CreateNumber: EcmaScriptObject;

    method NumberCall(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method NumberCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method NumberToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method NumberValueOf(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method NumberLocaleString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method NumberToFixed(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method NumberToExponential(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method NumberToPrecision(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
  end;


  EcmaScriptNumberObject = class(EcmaScriptFunctionObject)
  public
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
  end;

  
implementation


method GlobalObject.CreateNumber: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Number'));
  if result <> nil then exit;

  result := new EcmaScriptNumberObject(self, 'Number', @NumberCall, 1, &Class := 'Number');
  Values.Add('Number', PropertyValue.NotEnum(Result));
  Result.Values.Add('MAX_VALUE', PropertyValue.NotAllFlags(Double.MaxValue));
  Result.Values.Add('MIN_VALUE', PropertyValue.NotAllFlags(Double.Epsilon));
  Result.Values.Add('NaN', PropertyValue.NotAllFlags(Double.NaN));
  Result.Values.Add('NEGATIVE_INFINITY', PropertyValue.NotAllFlags(Double.NegativeInfinity));
  Result.Values.Add('POSITIVE_INFINITY', PropertyValue.NotAllFlags(Double.PositiveInfinity));

  NumberPrototype := new EcmaScriptObject(self, &Class := 'Number');
  NumberPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  NumberPrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(NumberPrototype);
  
  
  NumberPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @NumberToString, 0)));
  
  NumberPrototype.Values.Add('toLocaleString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleString', @NumberLocaleString, 0)));
  NumberPrototype.Values.Add('toFixed', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toFixed', @NumberToFixed, 1)));
  NumberPrototype.Values.Add('toExponential', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toExponential', @NumberToExponential, 1)));
  NumberPrototype.Values.Add('toPrecision', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toPrecision', @NumberToPrecision, 1)));

  NumberPrototype.Values.Add('valueOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'valueOf', @NumberValueOf, 0)));
end;

method GlobalObject.NumberCall(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit if length(args) = 0 then 0.0 else Utilities.GetArgAsDouble(args, 0, aCaller);
end;

method GlobalObject.NumberCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lVal := if length(args) = 0 then 0.0 else Utilities.GetArgAsDouble(args, 0, aCaller);
  var lObj := new EcmaScriptObject(self, NumberPrototype, &Class := 'Number', Value := lVal);
  exit lObj;
end;


method GlobalObject.NumberToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lVal := EcmaScriptObject(aSelf);
  if (lVal = nil) and ((aSelf is Double) or (aSelf is Integer)) then 
    lVal := EcmaScriptObject(NumberCtor(aCaller, NumberPrototype, aSelf));
  if (lVal = nil) or (lVal.Class <> 'Number') then RaiseNativeError(NativeErrorType.TypeError, 'number.prototype.valueOf is not generic');
  var lRadix := 10;
  if length(args) > 0 then lRadix := Utilities.GetArgAsInteger(args, 0, aCaller);
  if (lRadix < 2) or (lRadix > 36) then RaiseNativeError(NativeErrorType.RangeError, 'Radix parameter should be between 2 and 36');
  if lRadix = 10 then exit Utilities.GetObjAsDouble(lVal.Value, aCaller).ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
  if lRadix in [2, 16, 8] then
    exit Convert.ToString(Utilities.GetObjAsInt64(lVal.Value, aCaller), lRadix);
  var value := UInt64(Utilities.GetObjAsInt64(lVal.Value, aCaller));
  if value = 0 then exit '0';

  result := '';
  while value <> 0 do begin
    result := BaseString[value mod lRadix] + String(result);
    value := value div lRadix;
  end;
end;


method GlobalObject.NumberValueOf(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  // &self.GetType() in [ .. ] doesn't compile on Silverlight
  var lValueType: &Type := &self.GetType();

  if lValueType = typeOf(Double) then
    exit Double(&self);

  if (lValueType = typeOf(Int32)) or (lValueType = typeOf(Int64)) or (lValueType = typeOf(UInt32)) or (lValueType = typeOf(UInt64)) then
    exit Convert.ChangeType(&self, typeOf(Double), System.Globalization.CultureInfo.InvariantCulture);

  var lValue: EcmaScriptObject := EcmaScriptObject(&self);
  if (not assigned(lValue)) or (lValue.Class <> 'Number') then
    RaiseNativeError(NativeErrorType.TypeError, 'Number.prototype.valueOf is not generic');

  exit lValue.Value;
end;


method GlobalObject.NumberLocaleString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit Utilities.GetObjAsDouble(aSelf, aCaller).ToString;
end;

method GlobalObject.NumberToFixed(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lFrac := Utilities.GetArgAsInteger(args, 0, aCaller);
  var lValue := Utilities.GetObjAsDouble(aSelf, aCaller);
  exit lValue.ToString('F'+lFrac.ToString, system.Globalization.NumberFormatInfo.InvariantInfo);
end;

method GlobalObject.NumberToExponential(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lFrac := Utilities.GetArgAsInteger(args, 0, aCaller);
  var lValue := Utilities.GetObjAsDouble(aSelf, aCaller);
  exit lValue.ToString('E'+lFrac.ToString, system.Globalization.NumberFormatInfo.InvariantInfo);
end;

method GlobalObject.NumberToPrecision(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lFrac := Utilities.GetArgAsInteger(args, 0, aCaller);
  var lValue := Utilities.GetObjAsDouble(aSelf, aCaller);
  exit lValue.ToString('N'+lFrac.ToString, system.Globalization.NumberFormatInfo.InvariantInfo)  ;
end;
method EcmaScriptNumberObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  exit Root.NumberCall(context, self, args);
end;

method EcmaScriptNumberObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  exit Root.NumberCtor(context,self, args);
end;

end.