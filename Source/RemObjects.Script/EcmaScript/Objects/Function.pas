{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)
  private
  public
    method CreateFunction: EcmaScriptObject;

    method FunctionCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method FunctionToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method FunctionApply(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method FunctionCall(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
  end;

  EcmaScriptBaseFunctionObject = public class(EcmaScriptObject)
  protected
    fOriginalName: string;
  public
    property Scope: EnvironmentRecord;

    class var Method_set_Scope: System.Reflection.MethodInfo := typeof(EcmaScriptFunctionObject).GetMethod('set_Scope'); readonly;
    property OriginalName: String read fOriginalName;
  end;

  EcmaScriptFunctionObject = public class(EcmaScriptBaseFunctionObject)
  private
    fDelegate: InternalDelegate;
  public
    constructor (aScope: GlobalObject; aOriginalName: String; aDelegate: InternalDelegate; aLength: Integer; aStrict: Boolean := false);
    property &Delegate: InternalDelegate read fDelegate;
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
  end;
  EcmaScriptInternalFunctionObject = public class(EcmaScriptBaseFunctionObject)
  private
    fDelegate: InternalFunctionDelegate;
  public
    constructor (aScope: GlobalObject; aScopeVar: ExecutionContext; aOriginalName: String; aDelegate: InternalFunctionDelegate; aLength: Integer; aStrict: Boolean := false);
    property Scope: ExecutionContext;
    property &Delegate: InternalFunctionDelegate read fDelegate;
    class var &Constructor: System.Reflection.ConstructorInfo := typeof(EcmaScriptInternalFunctionObject).GetConstructor([
      typeof(GlobalObject), typeof(ExecutionContext), typeof(string), typeof(InternalFunctionDelegate), typeof(Integer),typeof(Boolean)]); readonly;
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
  end;

implementation

method GlobalObject.CreateFunction: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 'Function'));
  if result <> nil then exit;

  result := new EcmaScriptObject(self, nil, &Class := 'Function');
  Values.Add('Function', PropertyValue.NotEnum(Result));

  FunctionPrototype := new EcmaScriptFunctionObject(self, 'Function', @FunctionCtor, 1, &Class := 'Function');
  FunctionPrototype.Prototype := ObjectPrototype;
  
  result.Values['prototype'] := PropertyValue.NotAllFlags(FunctionPrototype);

  FunctionPrototype.Values['constructor'] := PropertyValue.NotEnum(FunctionPrototype);
  FunctionPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @FunctionToString, 0)));
  FunctionPrototype.Values.Add('apply', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'apply', @FunctionApply, 2)));
  FunctionPrototype.Values.Add('call', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'call', @FunctionCall, 1)));
end;


method GlobalObject.FunctionCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  // Todo: Implement
end;

method GlobalObject.FunctionToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptFunctionObject(aSelf);
  result := 'function '+lSelf:&Class+'()'
end;

method GlobalObject.FunctionApply(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if aSelf is not EcmaScriptObject then RaiseNativeError(NativeErrorType.TypeError, 'Function.prototype.apply is not generic');
  var lSelf: Object := nil;
  if (Length(args) = 0) or (args[0] is not EcmaScriptObject) then lSelf := self else lSelf := args[0];
  var lArgs: array of object;
  if (Length(args) < 2) then lArgs := [] else begin
    if (args[1] = nil) or (args[1] = Undefined.Instance) then lArgs := [] else 
    if args[1] is array of object then begin
      lArgs := array of object(args[1]);
    end else if args[1] is EcmaScriptArrayObject then begin
      lArgs := EcmaScriptArrayObject(args[1]).ToArray;
    end else RaiseNativeError(NativeErrorType.TypeError, 'Function.prototype.apply requires two parameters')
  end;
  exit EcmaScriptObject(aSelf).CallEx(aCaller, self, lSelf, lArgs);
end;

method GlobalObject.FunctionCall(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if aSelf is not EcmaScriptObject then RaiseNativeError(NativeErrorType.TypeError, 'Function.prototype.call is not generic');
  var lSelf: Object := nil;
  if (Length(args) = 0) or (args[0] is not EcmaScriptObject) then lSelf := self else lSelf := args[0];
  var lArgs: array of object := new Object[iif(Length(Args) < 1, 0, Length(args) -1)];
  if lArgs.Length >0 then Array.Copy(Args, 1, lArgs, 0, lArgs.Length);
  exit EcmaScriptObject(aSelf).CallEx(aCaller, self, lSelf, lArgs);
end;

constructor EcmaScriptFunctionObject(aScope: GlobalObject; aOriginalName: String; aDelegate: InternalDelegate; aLength: Integer; aStrict: Boolean := false);
begin 
  inherited constructor(aScope, new EcmaScriptObject(aScope, aScope.Root.FunctionPrototype));
  &Class := 'Function';
  var lProto := new EcmaScriptObject(aScope);
  lProto.DefineOwnProperty('constructor', new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, self));
  fOriginalName := aOriginalName;
  fDelegate := aDelegate;
  Values.Add('length', PropertyValue.NotAllFlags(aLength));
  DefineOwnProperty('prototype', new PropertyValue(PropertyAttributes.writable, lProto));
  if aStrict then begin
    DefineOwnProperty('caller', new PropertyValue(PropertyAttributes.None, aScope.Thrower, aScope.Thrower));
    DefineOwnProperty('arguments', new PropertyValue(PropertyAttributes.None, aScope.Thrower, aScope.Thrower));
  end;
  //Values.Add('
end;


method EcmaScriptFunctionObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  var lRes := new EcmaScriptObject(Root);
  lRes.Prototype := coalesce(EcmaScriptObject(Get(context, 'prototype')), Root.ObjectPrototype);
  var lFunc := fDelegate;
  result := lFunc(context, lRes, args);
  if Result is not EcmaScriptObject then result := lRes;
end;



method EcmaScriptFunctionObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit fDelegate(context, aSelf, args);
end;


method EcmaScriptFunctionObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  exit fDelegate(context, self, args);
end;

constructor EcmaScriptInternalFunctionObject(aScope: GlobalObject; aScopeVar: ExecutionContext; aOriginalName: String; aDelegate: InternalFunctionDelegate; aLength: Integer; aStrict: Boolean := false);
begin
  inherited constructor(aScope, new EcmaScriptObject(aScope, aScope.Root.FunctionPrototype));
  &Class := 'Function';
  Scope := aScopeVar;
  var lProto := new EcmaScriptObject(aScope);
  lProto.DefineOwnProperty('constructor', new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, self));
  fOriginalName := aOriginalName;
  fDelegate := aDelegate;
  Values.Add('length', PropertyValue.NotAllFlags(aLength));
  DefineOwnProperty('prototype', new PropertyValue(PropertyAttributes.writable, lProto));
  if aStrict then begin
    DefineOwnProperty('caller', new PropertyValue(PropertyAttributes.None, aScope.Thrower, aScope.Thrower));
    DefineOwnProperty('arguments', new PropertyValue(PropertyAttributes.None, aScope.Thrower, aScope.Thrower));
  end;
end;

method EcmaScriptInternalFunctionObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  exit fDelegate(Scope, self, args, self);
end;

method EcmaScriptInternalFunctionObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit fDelegate(Scope, aSelf, args, self);
end;

method EcmaScriptInternalFunctionObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  var lRes := new EcmaScriptObject(Root);
  lRes.Prototype := coalesce(EcmaScriptObject(Get(context, 'prototype')), Root.ObjectPrototype);
  var lFunc := fDelegate;
  result := lFunc(context, lRes, args, self);
  if Result is not EcmaScriptObject then result := lRes;
end;

end.