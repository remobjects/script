﻿{

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
  private
    class var 
      Epoch: Int64 := new DateTime(1970, 1, 1).Ticks;
  public
    class method DateTimeToUnix(d: DateTime): Int64;
    class method UnixToDateTime(dt: Int64): DateTime;
    method CreateDate: EcmaScriptObject;
    method DateCall(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method CreateDateObject(date: DateTime): Object;
    method DateParse(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateUTC(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToUTCString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToLocaleString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToLocaleDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToLocaleTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateValueOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetTime(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateGetUTCMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
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

    method DateSetTime(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetUTCMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetUTCSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetUTCMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetUTCHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetUTCDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetUTCMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateSetUTCFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateNow(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DatetoISOString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
    method DateToJSON(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
  end;

  EcmaScriptDateObject = public class(EcmaScriptFunctionObject)
  public
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
  end;
implementation

class method GlobalObject.DateTimeToUnix(d: DateTime): Int64;
begin
  result := (d.Ticks - Epoch)/10000000;
end;

class method GlobalObject.UnixToDateTime(dt: Int64): DateTime;
begin
  result := new DateTime((dt * 10000000) + Epoch);
end;

method GlobalObject.CreateDate: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Date'));
  if result <> nil then exit;

  result := new EcmaScriptDateObject(self, 'Date', @DateCall, 1, &Class := 'Date');
  Values.Add('Date', PropertyValue.NotEnum(Result));
  Result.Values.Add('now', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'now', @DateNow, 0)));
  Result.Values.Add('parse', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'parse', @DateParse, 1)));
  Result.Values.Add('UTC', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'UTC', @DateUTC, 2)));

  DatePrototype := new EcmaScriptObject( self, Value := Double.NaN, &Class := 'Date');
  DatePrototype.Values.Add('constructor', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'Date', @DateCtor, 1, &Class := 'Date')));
  DatePrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(DatePrototype);
  DatePrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @DateToString, 0)));
  DatePrototype.Values.Add('toISOString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toISOString', @DateToISOString, 0)));
  DatePrototype.Values.Add('toJSON', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toJSON', @DAteToJSON, 1)));
  DatePrototype.Values.Add('toUTCString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toUTCString', @DateToUTCString, 1)));
  DatePrototype.Values.Add('toGMTString', PropertyValue.NotEnum(DatePrototype.Values['toUTCString'].Value));
  Dateprototype.Values.Add('toDateString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toDateString', @DateToDateString, 1)));
  Dateprototype.Values.Add('toTimeString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toTimeString', @DateToTimeString, 1)));
  Dateprototype.Values.Add('toLocaleString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleString', @DateToLocaleString, 1)));
  Dateprototype.Values.Add('toLocaleDateString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleDateString', @DateToLocaleDateString, 1)));
  Dateprototype.Values.Add('toLocaleTimeString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleTimeString', @DateToLocaleTimeString, 1)));
  DatePrototype.Values.Add('valueOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'valueOf', @DateValueOf, 1)));
  Dateprototype.Values.Add('getTime', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getTime', @DateGetTime, 1)));
  Dateprototype.Values.Add('getFullYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getFullYear', @DateGetFullYear, 1)));
  Dateprototype.Values.Add('getYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getYear', @DateGetFullYear, 1)));
  Dateprototype.Values.Add('getUTCFullYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCFullYear', @DateGetUTCFullYear, 1)));
  Dateprototype.Values.Add('getMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getMonth', @DateGetMonth, 1)));
  Dateprototype.Values.Add('getUTCMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCMonth', @DateGetUTCMonth, 1)));
  Dateprototype.Values.Add('getDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getDate', @DateGetDate, 1)));
  DatePrototype.Values.Add('getUTCDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCDate', @DateGetUTCDate, 1)));
  Dateprototype.Values.Add('getDay', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getDay', @DateGetDay, 1)));
  Dateprototype.Values.Add('getUTCDay', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCDay', @DateGetUTCDay, 1)));
  Dateprototype.Values.Add('getHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getHours', @DateGetHours, 1)));
  Dateprototype.Values.Add('getUTCHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCHours', @DateGetUTCHours, 1)));
  Dateprototype.Values.Add('getMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getMinutes', @DateGetMinutes, 1)));
  Dateprototype.Values.Add('getUTCMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCMinutes', @DateGetUTCMinutes, 1)));
  Dateprototype.Values.Add('getSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getSeconds', @DateGetSeconds, 1)));
  Dateprototype.Values.Add('getUTCSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCSeconds', @DateGetUTCSeconds, 1)));
  Dateprototype.Values.Add('getMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getMilliseconds', @DateGetMilliseconds, 1)));
  Dateprototype.Values.Add('getUTCMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getUTCMilliseconds', @DateGetUTCMilliseconds, 1)));

  Dateprototype.Values.Add('getTimezoneOffset', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'getTimezoneOffset', @DateGetTimezoneOffset, 1)));

  Dateprototype.Values.Add('setTime', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setTime', @DateSetTime, 1)));
  Dateprototype.Values.Add('setMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setMilliseconds', @DateSetMilliseconds, 1)));
  Dateprototype.Values.Add('setUTCMilliseconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCMilliseconds' , @DateSetUTCMilliseconds, 1)));
  Dateprototype.Values.Add('setSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setSeconds', @DateSetSeconds, 1)));
  Dateprototype.Values.Add('setUTCSeconds', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCSeconds', @DateSetUTCSeconds, 1)));
  Dateprototype.Values.Add('setMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setMinutes', @DateSetMinutes, 1)));
  Dateprototype.Values.Add('setUTCMinutes', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCMinutes', @DateSetUTCMinutes, 1)));
  Dateprototype.Values.Add('setHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setHours', @DateSetHours, 1)));
  Dateprototype.Values.Add('setUTCHours', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCHours', @DateSetUTCHours, 1)));
  Dateprototype.Values.Add('setDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setDate', @DateSetDate, 1)));
  Dateprototype.Values.Add('setUTCDate', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCDate', @DateSetUTCDate, 1)));
  Dateprototype.Values.Add('setMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setMonth', @DateSetMonth, 1)));
  Dateprototype.Values.Add('setUTCMonth', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setUTCMonth', @DateSetUTCMonth, 1)));
  Dateprototype.Values.Add('setFullYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setFullYear', @DateSetFullYear, 1)));
  Dateprototype.Values.Add('setYear', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'setYear', @DateSetFullYear, 1)));
  Dateprototype.Values.Add('setUTCFullYear', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'setUTCFullYear', @DateSetUTCFullYear, 1)));
end;

method GlobalObject.DateCall(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  Result := DateCtor(nil, []);
end;

method GlobalObject.DateCtor(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue: DateTime;
  if args.Length = 0 then begin
    lValue := DateTime.UtcNow;
  end else if args.Length = 1 then begin
    if args[0] is EcmaScriptObject then args[0] := EcmaScriptObject(args[0]).Value;
    if args[0] is String then begin
      exit DateParse(aCaller, args[0]);
    end else begin
      lValue := UnixToDateTime(Utilities.GetArgAsInt64(args, 0));
    end;
  end else begin
    var lYear := Utilities.GetArgAsInteger(args, 0);
    var lMonth := Utilities.GetArgAsInteger(args, 1);
    var lDay := Utilities.GetArgAsInteger(args, 2);
    var lHour := Utilities.GetArgAsInteger(args, 3);
    var lMinute := Utilities.GetArgAsInteger(args, 4);
    var lSec := Utilities.GetArgAsInteger(args, 5);
    var lMSec := Utilities.GetArgAsInteger(args, 6);
    if lDay = 0 then lDay := 1;
    lValue := new DateTime(lYear, lMonth, lDay, lHour, lMinute, lSec, lMsec).ToUniversalTime;
  end;
  result := new EcmaScriptObject(self, DatePrototype, &Class := 'Date', Value := DateTimeToUnix(lValue));
end;

method GlobalObject.DateParse(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := DateTime.Parse(Utilities.GetArgAsString(args, 0), System.Globalization.DateTimeFormatInfo.InvariantInfo,
    System.Globalization.DateTimeStyles.AdjustToUniversal);
  result := new EcmaScriptObject(self, DatePrototype, &Class := 'Date', Value := DateTimeToUnix(lValue));
end;

method GlobalObject.DateUTC(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue: DateTime;
  var lYear := Utilities.GetArgAsInteger(args, 0);
  var lMonth := Utilities.GetArgAsInteger(args, 1);
  var lDay := Utilities.GetArgAsInteger(args, 2);
  var lHour := Utilities.GetArgAsInteger(args, 3);
  var lMinute := Utilities.GetArgAsInteger(args, 4);
  var lSec := Utilities.GetArgAsInteger(args, 5);
  var lMSec := Utilities.GetArgAsInteger(args, 6);
  if lDay = 0 then lDay := 1;
  lValue := new DateTime(lYear, lMonth, lDay, lHour, lMinute, lSec, lMsec);
  result := new EcmaScriptObject( self, DatePrototype, &Class := 'Date', Value := DateTimeToUnix(lValue));
end;

method GlobalObject.DateToString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime.ToString(System.Globalization.DateTimeFormatInfo.InvariantInfo);
end;

method GlobalObject.DateToUTCString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToString(System.Globalization.DateTimeFormatInfo.InvariantInfo);
end;

method GlobalObject.DateToDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime.ToString('d', System.Globalization.DateTimeFormatInfo.InvariantInfo);
end;

method GlobalObject.DateToTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime.ToString('T', System.Globalization.DateTimeFormatInfo.InvariantInfo);
end;

method GlobalObject.DateToLocaleString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime.ToString(System.Globalization.DateTimeFormatInfo.CurrentInfo);
end;

method GlobalObject.DateToLocaleDateString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime.ToString('d', System.Globalization.DateTimeFormatInfo.CurrentInfo);
end;

method GlobalObject.DateToLocaleTimeString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime.ToString('T', System.Globalization.DateTimeFormatInfo.CurrentInfo);
end;

method GlobalObject.DateValueOf(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit Utilities.GetObjAsInt64(aSelf);
end;

method GlobalObject.DateGetTime(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit Utilities.GetObjAsInt64(aSelf);
end;

method GlobalObject.DateGetFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.Year;
end;

method GlobalObject.DateGetUTCFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.Year;
end;

method GlobalObject.DateGetMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.Month;
end;

method GlobalObject.DateGetUTCMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.Month;
end;

method GlobalObject.DateGetDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.Day;
end;

method GlobalObject.DateGetUTCDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.Day;
end;

method GlobalObject.DateGetDay(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.DayOfWeek;
end;

method GlobalObject.DateGetUTCDay(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.DayOfWeek;
end;

method GlobalObject.DateGetHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.Hour;
end;

method GlobalObject.DateGetUTCHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.Hour;
end;

method GlobalObject.DateGetMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.Minute;
end;

method GlobalObject.DateGetUTCMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.Minute;
end;

method GlobalObject.DateGetSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.Second;
end;

method GlobalObject.DateGetUTCSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.Second;
end;

method GlobalObject.DateGetMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  exit lValue.Millisecond;
end;

method GlobalObject.DateGetUTCMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit lValue.Millisecond;
end;

method GlobalObject.DateGetTimezoneOffset(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  if Double.IsNaN(Utilities.GetObjAsDouble(aSelf)) then exit double.NaN;
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  exit (lValue.ToUniversalTime - lValue).TotalMinutes;
end;

method GlobalObject.DateSetTime(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  (aSelf as EcmaScriptObject).Value := Utilities.GetArgAsInt64(args, 0);
end;

method GlobalObject.DateSetMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, lValue.Second, Utilities.GetArgAsInt64(args, 0));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime);
end;

method GlobalObject.DateSetUTCMilliseconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, lValue.Second, Utilities.GetArgAsInt64(args, 0));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue);
end;

method GlobalObject.DateSetSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1), lValue.Millisecond));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime);
end;

method GlobalObject.DateSetUTCSeconds(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, lValue.Minute, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1), lValue.Millisecond));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue);
end;

method GlobalObject.DateSetMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1), lValue.Second),
    iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2), lValue.Millisecond));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime);
end;

method GlobalObject.DateSetUTCMinutes(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, lValue.Hour, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1), lValue.Second),
    iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2), lValue.Millisecond));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue);
end;

method GlobalObject.DateSetHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1), lValue.Minute),
    iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2), lValue.Second),
    iif(args.Length > 3, Utilities.GetArgAsInteger(args, 3), lValue.Millisecond));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime);
end;

method GlobalObject.DateSetUTCHours(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  lValue := new DateTime(lValue.Year, lValue.Month, lValue.Day, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1), lValue.Minute),
    iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2), lValue.Second),
    iif(args.Length > 3, Utilities.GetArgAsInteger(args, 3), lValue.Millisecond));
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue);
end;

method GlobalObject.DateSetDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  lValue := new DateTime(lValue.Year, lValue.Month,
    Utilities.GetArgAsInteger(args, 0),
    lValue.Hour,
    lValue.Minute,
    lValue.Second,
    lValue.Millisecond);
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime);
end;

method GlobalObject.DateSetUTCDate(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  lValue := new DateTime(lValue.Year, lValue.Month,
    Utilities.GetArgAsInteger(args, 0),
    lValue.Hour,
    lValue.Minute,
    lValue.Second,
    lValue.Millisecond);
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue);
end;

method GlobalObject.DateSetMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  lValue := new DateTime(lValue.Year, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1)),
    lValue.Hour,
    lValue.Minute,
    lValue.Second,
    lValue.Millisecond);
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime);

end;

method GlobalObject.DateSetUTCMonth(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  lValue := new DateTime(lValue.Year, 
    Utilities.GetArgAsInteger(args, 0),
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1)),
    lValue.Hour,
    lValue.Minute,
    lValue.Second,
    lValue.Millisecond);
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue);
end;

method GlobalObject.DateSetFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToLocalTime;
  lValue := new DateTime(Utilities.GetArgAsInteger(args, 0), 
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1)),
    iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2)),
    lValue.Hour,
    lValue.Minute,
    lValue.Second,
    lValue.Millisecond);
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue.ToUniversalTime);
end;

method GlobalObject.DateSetUTCFullYear(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lValue := UnixToDateTime(Utilities.GetObjAsInt64(aSelf));
  lValue := new DateTime(Utilities.GetArgAsInteger(args, 0), 
    iif(args.Length > 1, Utilities.GetArgAsInteger(args, 1)),
    iif(args.Length > 2, Utilities.GetArgAsInteger(args, 2)),
    lValue.Hour,
    lValue.Minute,
    lValue.Second,
    lValue.Millisecond);
  (aSelf as EcmaScriptObject).Value := DateTimeToUnix(lValue);
end;

method GlobalObject.CreateDateObject(date: DateTime): Object;
begin
  result := new EcmaScriptObject(self, DatePrototype, &Class := 'Date', Value := DateTimeToUnix(date));
end;

method GlobalObject.DateNow(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit DateTimeToUnix(DateTime.UtcNow);
end;

method GlobalObject.DatetoISOString(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  exit UnixToDateTime(Utilities.GetObjAsInt64(aSelf)).ToString('S');
end;

method GlobalObject.DateToJSON(aCaller: ExecutionContext;aSelf: Object; params args: Array of Object): Object;
begin
  var lItem := Utilities.ToObject(aCaller, aSelf);
  if (lItem.Value is Integer) or (lItem.Value is Int64) or (lItem.Value is Double) then
    exit DatetoISOString(aCaller, lItem);
  exit nil;
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