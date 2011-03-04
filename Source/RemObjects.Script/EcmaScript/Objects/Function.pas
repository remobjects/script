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

  EcmaScriptFunctionObject = public class(EcmaScriptObject)
  private
    fDelegate: InternalDelegate;
    fOriginalName: string;
  public
    constructor (aScope: GlobalObject; aOriginalName: String; aDelegate: InternalDelegate; aLength: Integer);
    property &Delegate: InternalDelegate read fDelegate;
    property OriginalName: String read fOriginalName;
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

constructor EcmaScriptFunctionObject(aScope: GlobalObject; aOriginalName: String; aDelegate: InternalDelegate; aLength: Integer);
begin 
  inherited constructor(aScope, new EcmaScriptObject(aScope, aScope.Root.FunctionPrototype));
  Values['constructor'] := new PropertyValue(PropertyAttributes.Configurable, Prototype);
  &Class := 'Function';
  fOriginalName := aOriginalName;
  fDelegate := aDelegate;
  Values.Add('length', PropertyValue.NotAllFlags(aLength));
  //Values.Add('
end;


method EcmaScriptFunctionObject.Construct(context: ExecutionContext; params args: array of Object): Object;
begin
  var lRes := new EcmaScriptObject(Root);
  if Prototype <> nil then lRes.Prototype := Prototype else lRes.Prototype := Root.ObjectPrototype;
  var lFunc := (*coalesce(EcmaScriptFunctionObject(Get('constructor'):fDelegate, *)fDelegate;
  result := lFunc(context, lRes, args);
  if Result is not EcmaScriptObject then exit lRes;
end;



method EcmaScriptFunctionObject.CallEx(context: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  exit fDelegate(context, aSelf, args);
end;


method EcmaScriptFunctionObject.Call(context: ExecutionContext; params args: array of Object): Object;
begin
  exit fDelegate(context, self, args);
end;

end.