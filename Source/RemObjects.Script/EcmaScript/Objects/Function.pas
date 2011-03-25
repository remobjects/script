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
    method CreateFunctionPrototype;

    method FunctionCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method FunctionToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method FunctionApply(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method FunctionCall(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method FunctionBind(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
  end;

  EcmaScriptBaseFunctionObject = public class(EcmaScriptObject)
  protected
    fOriginalName: string;
  public
    property Scope: EnvironmentRecord;

    property OriginalName: String read fOriginalName;
  end;

  EcmaScriptBoundFunctionObject = public class(EcmaScriptBaseFunctionObject)
  private
    fFunc: InternalFunctionDelegate;
    fFunc2: EcmaScriptBaseFunctionObject;
    fNewSelf: Object;
    fNewArgs: array of Object;
    fOriginal: EcmaScriptInternalFunctionObject;
  public
    constructor(aGlobal: GlobalObject; aFunc: EcmaScriptInternalFunctionObject; args: array of Object);
    constructor(aScope: EnvironmentRecord; aGlobal: GlobalObject; aFunc: EcmaScriptBaseFunctionObject; args: array of Object);

    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;
  end;

  
  RemObjects.Script.EcmaScript.Internal.EcmaScriptFunctionObject = public class(EcmaScriptBaseFunctionObject)
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
    constructor (aScope: GlobalObject; aScopeVar: EnvironmentRecord; aOriginalName: String; aDelegate: InternalFunctionDelegate; aLength: Integer; aStrict: Boolean := false);
    property &Delegate: InternalFunctionDelegate read fDelegate;
    class var &Constructor: System.Reflection.ConstructorInfo := typeof(EcmaScriptInternalFunctionObject).GetConstructor([
      typeof(GlobalObject), typeof(EnvironmentRecord), typeof(string), typeof(InternalFunctionDelegate), typeof(Integer),typeof(Boolean)]); readonly;
    method Call(context: ExecutionContext; params args: array of Object): Object; override;
    method CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object; override;
    method Construct(context: ExecutionContext; params args: array of Object): Object; override;
  end;

implementation

method GlobalObject.CreateFunction: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Function'));
  if result <> nil then exit;

  result := new EcmaScriptFunctionObject(self, nil, @FunctionCtor,1, &Class := 'Function');
  Values.Add('Function', PropertyValue.NotEnum(Result));

  
  result.Values['prototype'] := PropertyValue.NotAllFlags(FunctionPrototype);

  FunctionPrototype.Values['constructor'] := PropertyValue.NotEnum(result);
  FunctionPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @FunctionToString, 0)));
  FunctionPrototype.Values.Add('apply', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'apply', @FunctionApply, 2)));
  FunctionPrototype.Values.Add('call', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'call', @FunctionCall, 1)));
  FunctionPrototype.Values.Add('bind', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'bind', @FunctionBind, 1)));
 
end;


method GlobalObject.FunctionCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lNames: string := '';
  var lBody := '';
  if Length(Args) <> 0 then begin
    lBody := Utilities.GetArgAsString(Args, Length(Args)-1, aCaller);
    for i: Integer := 0 to Length(Args) -2 do begin
      if i = 0 then lNames := Utilities.GetArgAsString(args, i, aCaller) else
        lNames := lNames+','+Utilities.GetArgAsString(args, i, aCaller);
    end;
  end;
  var lTokenizer := new Tokenizer;
  var lParser := new Parser;
  lTokenizer.Error += lParser.fTok_Error;
  lTokenizer.SetData(lNames, 'Function Constructor Names');
  lTokenizer.Error -= lParser.fTok_Error;

  var lParams: List<ParameterDeclaration> := new List<ParameterDeclaration>;
  if lTokenizer.Token <> TokenKind.EOF then
  loop begin
    if lTokenizer.Token <> TokenKind.Identifier then begin
      RaiseNativeError(NativeErrorType.SyntaxError, 'Unknown token in parameter names');
    end;
    lParams.Add(new ParameterDeclaration(lTokenizer.PositionPair, lTokenizer.TokenStr));
    lTokenizer.Next;
    if lTokenizer.Token = TokenKind.Comma then begin
      lTokenizer.Next;
    end else if lTokenizer.Token = TokenKind.EOF then begin
      lTokenizer.Next;
      break;
    end else begin
      RaiseNativeError(NativeErrorType.SyntaxError, 'Unknown token in parameter names');
    end;
  end;
  for each el in lParser.Messages do
    if el.IsError then 
      RaiseNativeError(NativeErrorType.SyntaxError, el.IntToString());
  lTokenizer.Error += lParser.fTok_Error;
  lTokenizer.SetData(lBody, 'Function Body');
  lTokenizer.Error -= lParser.fTok_Error;

  var lCode := lParser.Parse(lTokenizer);
  for each el in lParser.Messages do
    if el.IsError then 
      RaiseNativeError(NativeErrorType.SyntaxError, el.IntToString());

  var lFunc := new FunctionDeclarationElement(lCode.PositionPair, FunctionDeclarationType.None, nil, lParams, lCode);

 
  exit new EcmaScriptInternalFunctionObject(self, fParser.fRoot, nil, InternalFunctionDelegate(fParser.Parse(lFunc, false, nil, lCode.Items)), lFunc.Parameters.Count, aCaller.Strict);
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
  exit EcmaScriptObject(aSelf).CallEx(aCaller, lSelf, lArgs);
end;

method GlobalObject.FunctionCall(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if aSelf is not EcmaScriptObject then RaiseNativeError(NativeErrorType.TypeError, 'Function.prototype.call is not generic');
  var lSelf: Object := nil;
  if (Length(args) = 0) or (args[0] is not EcmaScriptObject) then lSelf := self else lSelf := args[0];
  var lArgs: array of object := new Object[iif(Length(Args) < 1, 0, Length(args) -1)];
  if lArgs.Length >0 then Array.Copy(Args, 1, lArgs, 0, lArgs.Length);
  exit EcmaScriptObject(aSelf).CallEx(aCaller, lSelf, lArgs);
end;

method GlobalObject.FunctionBind(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptInternalFunctionObject(aSelf);
  if lSelf = nil then begin
    var lSelf2 :=  EcmaScriptBaseFunctionObject(aSelf);
    if lSelf2 <> nil then begin
      exit new EcmaScriptBoundFunctionObject(aCaller.LexicalScope, self, lSelf2, Args)
    end;

    RaiseNativeError(NativeErrorType.TypeError, '"this" is not a function');
  end;
  exit new EcmaScriptBoundFunctionObject(self, lSelf, Args);
end;

method GlobalObject.CreateFunctionPrototype;
begin
  FunctionPrototype := new EcmaScriptFunctionObject(self, 'Function', @FunctionCtor, 1, &Class := 'Function');
  FunctionPrototype.Prototype := ObjectPrototype;
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
  lRes.Prototype := coalesce(EcmaScriptObject(Get(context, 0, 'prototype')), Root.ObjectPrototype);
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

constructor EcmaScriptInternalFunctionObject(aScope: GlobalObject; aScopeVar: EnvironmentRecord; aOriginalName: String; aDelegate: InternalFunctionDelegate; aLength: Integer; aStrict: Boolean := false);
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
  exit fDelegate(new ExecutionContext(Scope, false), self, args, self);
end;

method EcmaScriptInternalFunctionObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit fDelegate(new ExecutionContext(Scope, false), aSelf, args, self);
end;

method EcmaScriptInternalFunctionObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  var lRes := new EcmaScriptObject(Root);
  lRes.Prototype := coalesce(EcmaScriptObject(Get(context, 0, 'prototype')), Root.ObjectPrototype);
  var lFunc := fDelegate;
  result := lFunc(context, lRes, args, self);
  if Result is not EcmaScriptObject then result := lRes;
end;

constructor EcmaScriptBoundFunctionObject(aGlobal: GlobalObject; aFunc: EcmaScriptInternalFunctionObject; args: array of Object);
begin
  inherited constructor(aGlobal);
  Prototype := aGlobal.FunctionPrototype;
  self.fFunc := EcmaScriptInternalFunctionObject(afunc):&Delegate;
  &Class := 'Function';
  Scope := aFunc.Scope;
  var lProto := new EcmaScriptObject(aGlobal);
  lProto.DefineOwnProperty('constructor', new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, self));
  var lLength := Utilities.GetObjAsInteger(aFunc.Get(nil, 0, 'length'), aGlobal.ExecutionContext);

  fOriginal := aFunc;
  lLength := lLength - (length(args) - 1);
  if lLength < 0 then lLength := 0;
  fNewSelf := Utilities.GetArg(args, 0);
  if Length(Args) = 0 then
   fNewArgs := []
  else begin
    fNewArgs := new Object[Length(Args ) -1];
    ARray.Copy(args, 1, fNewArgs, 0, fNewArgs.Length);
  end;
  Values.Add('length', PropertyValue.NotAllFlags(lLength));
  DefineOwnProperty('prototype', new PropertyValue(PropertyAttributes.writable, lProto));
  DefineOwnProperty('caller', new PropertyValue(PropertyAttributes.None, aGlobal.Thrower, aGlobal.Thrower));
  DefineOwnProperty('arguments', new PropertyValue(PropertyAttributes.None, aGlobal.Thrower, aGlobal.Thrower));
end;

method EcmaScriptBoundFunctionObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  if ffunc2 = nil then 
    exit fFunc(new ExecutionContext(Scope, false), fNewSelf, System.Linq.Enumerable.ToArray(System.Linq.Enumerable.Concat(fNewArgs, Args)), fOriginal);
  exit fFunc2.CallEx(new ExecutionContext(Scope, false), fNewSelf, System.Linq.Enumerable.ToArray(System.Linq.Enumerable.Concat(fNewArgs, Args)));
end;

method EcmaScriptBoundFunctionObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit Call(context, args);
end;

constructor EcmaScriptBoundFunctionObject(aScope: EnvironmentRecord; aGlobal: GlobalObject; aFunc: EcmaScriptBaseFunctionObject; args: array of Object);
begin
    inherited constructor(aGlobal);
  self.fFunc2 := afunc;
  &Class := 'Function';
  Scope := ascope;
  var lProto := new EcmaScriptObject(aGlobal);
  lProto.DefineOwnProperty('constructor', new PropertyValue(PropertyAttributes.writable or PropertyAttributes.Configurable, self));
  var lLength := Utilities.GetObjAsInteger(aFunc.Get(nil, 0, 'length'), aGlobal.ExecutionContext);

  
  lLength := lLength - (length(args) - 1);
  if lLength < 0 then lLength := 0;
  fNewSelf := Utilities.GetArg(args, 0);
  if Length(Args) = 0 then
   fNewArgs := []
  else begin
    fNewArgs := new Object[Length(Args ) -1];
    ARray.Copy(args, 1, fNewArgs, 0, fNewArgs.Length);
  end;
  Values.Add('length', PropertyValue.NotAllFlags(lLength));
  DefineOwnProperty('prototype', new PropertyValue(PropertyAttributes.writable, lProto));
  DefineOwnProperty('caller', new PropertyValue(PropertyAttributes.None, aGlobal.Thrower, aGlobal.Thrower));
  DefineOwnProperty('arguments', new PropertyValue(PropertyAttributes.None, aGlobal.Thrower, aGlobal.Thrower));

end;

end.