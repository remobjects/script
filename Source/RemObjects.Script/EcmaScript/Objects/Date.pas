//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)
  private
    class var Epoch: Int64 := new DateTime(1970, 1, 1).Ticks; readonly;

  public
    class method DateTimeToUnix(date: DateTime): Int64;
    class method UnixToDateTime(date: Int64): DateTime;

    method CreateDate: EcmaScriptObject;
    method DateCall(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateCtor(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method CreateDateObject(date: DateTime): Object;
    method DateParse(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateUTC(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateToString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateToUTCString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToLocaleString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToLocaleDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToLocaleTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateValueOf(caller: ExecutionContext;  instance: Object;  params args: array of Object): Object;
    method DateGetTime(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCMonth(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateGetDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetDay(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCDay(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetTimezoneOffset(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetTime(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetMilliseconds(caller: ExecutionContext;  &self: Object; params args: array of Object): Object;
    method DateSetUTCMilliseconds(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;

    method DateSetSeconds(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetUTCSeconds(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetMinutes(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetUTCMinutes(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetHours(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetUTCHours(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetDate(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetUTCDate(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetMonth(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetUTCMonth(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetFullYear(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateSetUTCFullYear(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;

    method DateNow(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToISOString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method DateToJSON(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
  end;


  EcmaScriptDateObject = class(EcmaScriptFunctionObject)
  public
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
  end;


implementation


class method GlobalObject.DateTimeToUnix(date: DateTime): Int64;
begin
  exit (date.Ticks - GlobalObject.Epoch)/10000;
end;


class method GlobalObject.UnixToDateTime(date: Int64): DateTime;
begin
  date := (date * TimeSpan.TicksPerMillisecond) + GlobalObject.Epoch;
  if  (date > DateTime.MaxValue.Ticks)  then
    date := DateTime.MaxValue.Ticks
  else if  (date < DateTime.MinValue.Ticks)  then
    date := DateTime.MinValue.Ticks;

  exit new DateTime(date);
end;


method GlobalObject.CreateDate: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Date'));
  if result <> nil then exit;

  result := new EcmaScriptDateObject(self, 'Date', @DateCall, 1, &Class := 'Date');
  Values.Add('Date', PropertyValue.NotEnum(Result));
  Result.Values.Add('now', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'now', @DateNow, 0)));
  Result.Values.Add('parse', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'parse', @DateParse, 1)));
  Result.Values.Add('UTC', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'UTC', @DateUTC, 7)));

  DatePrototype := new EcmaScriptObject( self, Value := Double.NaN, &Class := 'Date');
  DatePrototype.Values.Add('constructor', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'Date', @DateCtor, 7, &Class := 'Date')));
  DatePrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(DatePrototype);

  DatePrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @DateToString, 0)));
  DatePrototype.Values.Add('toISOString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toISOString', @DateToISOString, 0)));
  DatePrototype.Values.Add('toJSON', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toJSON', @DateToJSON, 1)));
  DatePrototype.Values.Add('toUTCString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toUTCString', @DateToUTCString, 0)));
  DatePrototype.Values.Add('toGMTString', PropertyValue.NotEnum(DatePrototype.Values['toUTCString'].Value));
  DatePrototype.Values.Add('toDateString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toDateString', @DateToDateString, 0)));
  DatePrototype.Values.Add('toTimeString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toTimeString', @DateToTimeString, 0)));
  DatePrototype.Values.Add('toLocaleString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleString', @DateToLocaleString, 0)));
  DatePrototype.Values.Add('toLocaleDateString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleDateString', @DateToLocaleDateString, 0)));
  DatePrototype.Values.Add('toLocaleTimeString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleTimeString', @DateToLocaleTimeString, 0)));
  DatePrototype.Values.Add('valueOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'valueOf', @DateValueOf, 0)));
  DatePrototype.Values.Add('getTime', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getTime', @DateGetTime, 0)));
  DatePrototype.Values.Add('getFullYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getFullYear', @DateGetFullYear, 0)));
  DatePrototype.Values.Add('getYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getYear', @DateGetYear, 0)));
  DatePrototype.Values.Add('getUTCFullYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCFullYear', @DateGetUTCFullYear, 0)));
  DatePrototype.Values.Add('getMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getMonth', @DateGetMonth, 0)));
  DatePrototype.Values.Add('getUTCMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCMonth', @DateGetUTCMonth, 0)));
  DatePrototype.Values.Add('getDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getDate', @DateGetDate, 0)));
  DatePrototype.Values.Add('getUTCDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCDate', @DateGetUTCDate, 0)));
  DatePrototype.Values.Add('getDay', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getDay', @DateGetDay, 0)));
  DatePrototype.Values.Add('getUTCDay', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCDay', @DateGetUTCDay, 0)));
  DatePrototype.Values.Add('getHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getHours', @DateGetHours, 0)));
  DatePrototype.Values.Add('getUTCHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCHours', @DateGetUTCHours, 0)));
  DatePrototype.Values.Add('getMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getMinutes', @DateGetMinutes, 0)));
  DatePrototype.Values.Add('getUTCMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCMinutes', @DateGetUTCMinutes, 0)));
  DatePrototype.Values.Add('getSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getSeconds', @DateGetSeconds, 0)));
  DatePrototype.Values.Add('getUTCSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCSeconds', @DateGetUTCSeconds, 0)));
  DatePrototype.Values.Add('getMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getMilliseconds', @DateGetMilliseconds, 0)));
  DatePrototype.Values.Add('getUTCMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCMilliseconds', @DateGetUTCMilliseconds, 0)));
  DatePrototype.Values.Add('getTimezoneOffset', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getTimezoneOffset', @DateGetTimezoneOffset, 0)));
  DatePrototype.Values.Add('setTime', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setTime', @DateSetTime, 1)));
  DatePrototype.Values.Add('setMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setMilliseconds', @DateSetMilliseconds, 1)));
  DatePrototype.Values.Add('setUTCMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCMilliseconds' , @DateSetUTCMilliseconds, 1)));
  DatePrototype.Values.Add('setSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setSeconds', @DateSetSeconds, 2)));
  DatePrototype.Values.Add('setUTCSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCSeconds', @DateSetUTCSeconds, 2)));
  DatePrototype.Values.Add('setMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setMinutes', @DateSetMinutes, 3)));
  DatePrototype.Values.Add('setUTCMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCMinutes', @DateSetUTCMinutes, 3)));
  DatePrototype.Values.Add('setHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setHours', @DateSetHours, 4)));
  DatePrototype.Values.Add('setUTCHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCHours', @DateSetUTCHours, 4)));
  DatePrototype.Values.Add('setDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setDate', @DateSetDate, 1)));
  DatePrototype.Values.Add('setUTCDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCDate', @DateSetUTCDate, 1)));
  DatePrototype.Values.Add('setMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setMonth', @DateSetMonth, 2)));
  DatePrototype.Values.Add('setUTCMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCMonth', @DateSetUTCMonth, 2)));
  DatePrototype.Values.Add('setYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setYear', @DateSetFullYear, 1)));
  DatePrototype.Values.Add('setFullYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setFullYear', @DateSetFullYear, 3)));
  DatePrototype.Values.Add('setUTCFullYear', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'setUTCFullYear', @DateSetUTCFullYear, 1)));
end;

method GlobalObject.DateCall(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  Result := DateCtor(nil, []):ToString();
end;


method GlobalObject.DateCtor(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: Int64;
  if args.Length = 0 then begin
    lValue := DateTimeToUnix(DateTime.UtcNow);
  end
  else if args.Length = 1 then begin
    if args[0] is EcmaScriptObject then
      args[0] := EcmaScriptObject(args[0]).Value;
    if args[0] is String then begin
      exit DateParse(caller, &self, args[0]);
    end
    else begin
      lValue := Utilities.GetArgAsInt64(args, 0, caller);
    end;
  end
  else begin
    var lYear := Utilities.GetArgAsInteger(args, 0, caller);
    var lMonth: Int32 := Utilities.GetArgAsInteger(args, 1, caller); // Month is 0-based in JS
    var lDay := Utilities.GetArgAsInteger(args, 2, caller);
    var lHour := Utilities.GetArgAsInteger(args, 3, caller);
    var lMinute := Utilities.GetArgAsInteger(args, 4, caller);
    var lSec := Utilities.GetArgAsInteger(args, 5, caller);
    var lMSec := Utilities.GetArgAsInteger(args, 6, caller);

    lValue := DateTimeToUnix(new DateTime(lYear, 1, 1, lHour, lMinute, lSec, lMSec).AddMonths(lMonth).AddDays(lDay-1).ToUniversalTime());
  end;

  exit new EcmaScriptObject(self, DatePrototype, &Class := 'Date', Value := lValue);
end;


method GlobalObject.DateParse(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  try
    var lValue: DateTime := DateTime.Parse(Utilities.GetArgAsString(args, 0, caller), System.Globalization.DateTimeFormatInfo.InvariantInfo,
      System.Globalization.DateTimeStyles.AssumeLocal).ToUniversalTime();

    exit DateTimeToUnix(lValue);
  except
    exit Double.NaN;
  end;
  //exit new EcmaScriptObject(self, DatePrototype, &Class := 'Date', Value := lValue);
end;


method GlobalObject.DateUTC(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lYear := Utilities.GetArgAsInteger(args, 0, caller);
  var lMonth := Utilities.GetArgAsInteger(args, 1, caller);
  var lDay := Utilities.GetArgAsInteger(args, 2, caller);
  var lHour := Utilities.GetArgAsInteger(args, 3, caller);
  var lMinute := Utilities.GetArgAsInteger(args, 4, caller);
  var lSec := Utilities.GetArgAsInteger(args, 5, caller);
  var lMSec := Utilities.GetArgAsInteger(args, 6, caller);

  var lValue: DateTime := new DateTime(lYear, 1, 1, lHour, lMinute, lSec, lMSec).AddMonths(lMonth).AddDays(lDay-1);
  exit new EcmaScriptObject(self, DatePrototype, &Class := 'Date', Value := DateTimeToUnix(lValue));
end;


method GlobalObject.DateToString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lSelf: Object := coalesce(EcmaScriptObject(&self):Value, &self);

  exit UnixToDateTime(Utilities.GetObjAsInt64(lSelf, caller)).ToLocalTime().ToString(System.Globalization.DateTimeFormatInfo.CurrentInfo);
end;


method GlobalObject.DateToUTCString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToString('R', System.Globalization.DateTimeFormatInfo.InvariantInfo);
end;

method GlobalObject.DateToDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime.ToString('d', System.Globalization.DateTimeFormatInfo.InvariantInfo);
end;

method GlobalObject.DateToTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime.ToString('T', System.Globalization.DateTimeFormatInfo.InvariantInfo);
end;

method GlobalObject.DateToLocaleString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime.ToString(System.Globalization.DateTimeFormatInfo.CurrentInfo);
end;

method GlobalObject.DateToLocaleDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime.ToString('d', System.Globalization.DateTimeFormatInfo.CurrentInfo);
end;

method GlobalObject.DateToLocaleTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime.ToString('T', System.Globalization.DateTimeFormatInfo.CurrentInfo);
end;


method GlobalObject.DateValueOf(caller: ExecutionContext;  instance: Object;  params args: array of Object): Object;
begin
  var lValue: Object := coalesce(EcmaScriptObject(instance):Value, instance);
  if (not ((lValue is Double) or (lValue is Int64))) then
    RaiseNativeError(NativeErrorType.TypeError, 'Date.valueOf is not generic');

  exit Convert.ToInt64(lValue);
end;


method GlobalObject.DateGetTime(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit Utilities.GetObjAsInt64(aSelf, aCaller);
end;

method GlobalObject.DateGetFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Year;
end;

method GlobalObject.DateGetUTCFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit lValue.Year;
end;

method GlobalObject.DateGetMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Month -1;
end;


method GlobalObject.DateGetUTCMonth(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));

  exit lValue.Month-1;
end;


method GlobalObject.DateGetDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Day;
end;

method GlobalObject.DateGetUTCDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit lValue.Day;
end;

method GlobalObject.DateGetDay(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit Integer(lValue.DayOfWeek);
end;

method GlobalObject.DateGetUTCDay(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit Integer(lValue.DayOfWeek);
end;

method GlobalObject.DateGetHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Hour;
end;

method GlobalObject.DateGetUTCHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit lValue.Hour;
end;

method GlobalObject.DateGetMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Minute;
end;

method GlobalObject.DateGetUTCMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit lValue.Minute;
end;

method GlobalObject.DateGetSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Second;
end;

method GlobalObject.DateGetUTCSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit lValue.Second;
end;

method GlobalObject.DateGetMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Millisecond;
end;

method GlobalObject.DateGetUTCMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit lValue.Millisecond;
end;

method GlobalObject.DateGetTimezoneOffset(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller));
  exit (lValue.ToUniversalTime - lValue).TotalMinutes;
end;


method GlobalObject.DateSetTime(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  (&self as EcmaScriptObject).Value := Utilities.GetArgAsInt64(args, 0, caller);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetMilliseconds(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToLocalTime();
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, lValue.Second, 0).AddMilliseconds(Utilities.GetArgAsInt64(args, 0, caller));

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime());

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetUTCMilliseconds(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, lValue.Second, 0).AddMilliseconds(Utilities.GetArgAsInt64(args, 0, caller));

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetSeconds(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToLocalTime();

  var lSeconds: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lMilliseconds: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Millisecond);
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, 0, 0).AddSeconds(lSeconds).AddMilliseconds(lMilliseconds);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime());

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetUTCSeconds(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));

  var lSeconds: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lMilliseconds: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Millisecond);
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, 0, 0).AddSeconds(lSeconds).AddMilliseconds(lMilliseconds);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetMinutes(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToLocalTime();

  var lMinutes: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lSeconds: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Second);
  var lMilliseconds: Int32 := iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2, caller), lValue.Millisecond);
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, 0, 0, 0).AddMinutes(lMinutes).AddSeconds(lSeconds).AddMilliseconds(lMilliseconds);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime());

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetUTCMinutes(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));

  var lMinutes: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lSeconds: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Second);
  var lMilliseconds: Int32 := iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2, caller), lValue.Millisecond);
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, 0, 0, 0).AddMinutes(lMinutes).AddSeconds(lSeconds).AddMilliseconds(lMilliseconds);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetHours(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToLocalTime();

  var lHours: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lMinutes: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Minute);
  var lSeconds: Int32 := iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2, caller), lValue.Second);
  var lMilliseconds: Int32 := iif(args.Length > 3, Utilities.GetArgAsInteger(args, 3, caller), lValue.Millisecond);
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, 0, 0, 0, 0).AddHours(lHours).AddMinutes(lMinutes).AddSeconds(lSeconds).AddMilliseconds(lMilliseconds);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime());

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetUTCHours(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));

  var lHours: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lMinutes: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Minute);
  var lSeconds: Int32 := iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2, caller), lValue.Second);
  var lMilliseconds: Int32 := iif(args.Length > 3, Utilities.GetArgAsInteger(args, 3, caller), lValue.Millisecond);
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, 0, 0, 0, 0).AddHours(lHours).AddMinutes(lMinutes).AddSeconds(lSeconds).AddMilliseconds(lMilliseconds);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetDate(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToLocalTime();

  lValue := new DateTime(lValue.Year, lValue.Month, 1, lValue.Hour, lValue.Minute, lValue.Second, lValue.Millisecond).AddDays(Utilities.GetArgAsInteger(args, 0, caller)-1);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime());

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetUTCDate(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));

  lValue := new DateTime(lValue.Year, lValue.Month, 1, lValue.Hour, lValue.Minute, lValue.Second, lValue.Millisecond).AddDays(Utilities.GetArgAsInteger(args, 0, caller)-1);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetMonth(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToLocalTime();

  var lMonth: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lDay: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Day);
  lValue := new DateTime(lValue.Year, 1, 1, lValue.Hour, lValue.Minute, lValue.Second, lValue.Millisecond).AddMonths(lMonth).AddDays(lDay-1);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime());

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetUTCMonth(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));

  var lMonth: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lDay: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Day);
  lValue := new DateTime(lValue.Year, 1, 1, lValue.Hour, lValue.Minute, lValue.Second, lValue.Millisecond).AddMonths(lMonth).AddDays(lDay-1);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetFullYear(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToLocalTime();

  var lYear: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lMonth: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Month-1);
  var lDay: Int32 := iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2, caller), lValue.Day);
  lValue := new DateTime(lYear, 1, 1, lValue.Hour, lValue.Minute, lValue.Second, lValue.Millisecond).AddMonths(lMonth).AddDays(lDay-1);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime());

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.DateSetUTCFullYear(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: DateTime := UnixToDateTime(Utilities.GetObjAsInt64(&self, caller));

  var lYear: Int32 := Utilities.GetArgAsInteger(args, 0, caller);
  var lMonth: Int32 := iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1, caller), lValue.Month-1);
  var lDay: Int32 := iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2, caller), lValue.Day);
  lValue := new DateTime(lYear, 1, 1, lValue.Hour, lValue.Minute, lValue.Second, lValue.Millisecond).AddMonths(lMonth).AddDays(lDay-1);

  (&self as EcmaScriptObject).Value := DateTimeToUnix(lValue);

  exit (&self as EcmaScriptObject).Value;
end;


method GlobalObject.CreateDateObject(date: DateTime): Object;
begin
  exit new EcmaScriptObject(self, DatePrototype, &Class := 'Date', Value := DateTimeToUnix(date));
end;


method GlobalObject.DateNow(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit DateTimeToUnix(DateTime.UtcNow);
end;


method GlobalObject.DateToISOString(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  exit  (GlobalObject.UnixToDateTime(Utilities.GetObjAsInt64(&self, caller)).ToString('s', System.Globalization.DateTimeFormatInfo.InvariantInfo));
end;


method GlobalObject.DateToJSON(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  var lValue: EcmaScriptObject := Utilities.ToObject(caller, &self);

  if  ((lValue.Value is Int32)  or  (lValue.Value is Int64)  or  (lValue.Value is Double))  then
    exit  (self.DateToISOString(caller, lValue));

  exit  (nil);
end;


method GlobalObject.DateGetYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf, aCaller)).ToLocalTime;
  exit lValue.Year mod 100;
end;


method EcmaScriptDateObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  exit Root.DateCall(context, self, args);
end;


method EcmaScriptDateObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  exit Root.DateCtor(context, self, args);
end;


end.