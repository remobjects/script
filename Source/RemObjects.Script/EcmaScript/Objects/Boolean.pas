{

  Copyright (c) 2009-2011 RemObjects Software. See LICENSE.txt for more details.

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
    method CreateBoolean: EcmaScriptObject;

    method BooleanCall(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method BooleanCtor(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method BooleanToString(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
    method BooleanValueOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
  end;


  EcmaScriptBooleanObject = class(EcmaScriptFunctionObject)
  public
    method Call(context: ExecutionContext;  params args: array of Object): Object; override;
    method Construct(context: ExecutionContext;  params args: array of Object): Object; override;
  end;


implementation


method GlobalObject.CreateBoolean(): EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Boolean'));
  if  (assigned(result))  then
    exit;

  result := new EcmaScriptBooleanObject(self, 'Boolean', @BooleanCall, 1, &Class := 'Boolean');
  Values.Add('Boolean', PropertyValue.NotEnum(Result));

  BooleanPrototype := new EcmaScriptObject(self, &Class := 'Boolean');
  BooleanPrototype.Values.Add('constructor', PropertyValue.NotEnum(result));
  BooleanPrototype.Prototype := ObjectPrototype;
  result.Values['prototype'] := PropertyValue.NotAllFlags(BooleanPrototype);

  BooleanPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @BooleanToString, 0)));
  BooleanPrototype.Values.Add('valueOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'valueOf', @BooleanValueOf, 0)));
end;


method GlobalObject.BooleanCall(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  exit  (Utilities.GetArgAsBoolean(args, 0, aCaller));
end;


method GlobalObject.BooleanCtor(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  var lVal := Utilities.GetArgAsBoolean(args, 0, aCaller);
  var lObj := new EcmaScriptObject(self, BooleanPrototype, &Class := 'Boolean', Value := lVal);

  exit  (lObj);
end;


method GlobalObject.BooleanToString(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  if  (aSelf is Boolean)  then
    exit  (iif(Boolean(aSelf), 'true', 'false'));

  var El := EcmaScriptObject(aSelf);

  if  ((El = nil) or (El.Class <> 'Boolean'))  then
    RaiseNativeError(NativeErrorType.TypeError, 'Boolean.toString() is not generic');

  exit  (iif(Utilities.GetObjAsBoolean(El.Value, aCaller), 'true', 'false'));
end;


method GlobalObject.BooleanValueOf(aCaller: ExecutionContext;  aSelf: Object;  params args: array of Object): Object;
begin
  if  (aSelf is Boolean)  then
    exit  (Boolean(aSelf));

  var El := EcmaScriptObject(aSelf);
  if  ((El = nil)  or  (El.Class <> 'Boolean'))  then
    RaiseNativeError(NativeErrorType.TypeError, 'Boolean.toString() is not generic');

  exit  (Utilities.GetObjAsBoolean(El.Value, aCaller));
end;


method EcmaScriptBooleanObject.Call(context: ExecutionContext;  params args: array of Object): Object;
begin
  exit  (self.Root.BooleanCall(context, self, args));
end;


method EcmaScriptBooleanObject.Construct(context: ExecutionContext;  params args: array of Object): Object;
begin
  exit  (self.Root.BooleanCtor(context, self, args));
end;


end.