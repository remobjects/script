{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface
uses
  System.Collections.Generic,
  System.Reflection,
  System.Text,
  Microsoft.Scripting.Actions.Calls,
  Microsoft.Scripting.Ast,
  Microsoft.Scripting.Utils,
  RemObjects.Script.EcmaScript.Internal,
  Microsoft.Scripting,
  System.Dynamic,
  Microsoft.Scripting.Actions;

type
  InvokeBinding = class(InvokeBinder)
  private
    fBinder: EcmaScriptLanguageBinder;
    fGlobal: GlobalObject;
  protected
  public
    constructor (aGlobal: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);
    method FallbackInvoke(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;
  InvokeMemberBinding = class(InvokeMemberBinder)
  private
    fBinder: EcmaScriptLanguageBinder;
    fGlobal: GlobalObject;
  protected
  public
    property Binder: EcmaScriptLanguageBinder read fBinder;
    constructor (aGlobal: GlobalObject; aBinder: EcmaScriptLanguageBinder; aName: String; aCallInfo: CallInfo);
    method FallbackInvoke(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
    method FallbackInvokeMember(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

  ScopeInvokeBinder = class(DynamicMetaObjectBinder)
  private
    fName: String;
    fBinder: EcmaScriptLanguageBinder;
    fArgCount: Integer;
  public
    method Bind(target: DynamicMetaObject; args: array of DynamicMetaObject): DynamicMetaObject; override;
    property ReturnType: &Type read typeof(Object); override;
    constructor(aBinder: EcmaScriptLanguageBinder; aName: String; aArgCount: Integer);
  end;

  CreateInstanceBinding = class(CreateInstanceBinder)
  private
    fGlobal: GlobalObject;
    fBinder: EcmaScriptLanguageBinder;
  public
    constructor(aGlobal: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);

    class method GetConstructors(aType: &Type): MemberGroup;
    method FallbackCreateInstance(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;
implementation

constructor InvokeBinding(aGlobal: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);
begin
  inherited constructor(aCAllInfo);
  fGlobal := aGlobal;
  fBinder := aBinder;
end;

method InvokeBinding.FallbackInvoke(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  exit fBinder.Call(new CallSignature(CallInfo.ArgumentCount), 
  fBinder.Factory,
  target,args);
end;

constructor InvokeMemberBinding(aGlobal: GlobalObject; aBinder: EcmaScriptLanguageBinder; aName: String; aCallInfo: CallInfo);
begin
  inherited Constructor(aName, false, aCallInfo);
  fGlobal := aGlobal;
  fBinder := abinder;
end;

method InvokeMemberBinding.FallbackInvokeMember(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  result := Utilities.FallbackDynamic(fGlobal, target);
  if result <> nil then begin 
    result := result.BindInvokeMember(self, args);
    if assigned(result) and result.Expression.Type.IsValueType then 
      result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
    exit;
  end;

  
  var lTarget := fBinder.GetMember(Name, target, fBinder.Factory);
  var lArgs := new Expression[args.Length + 1];
  lArgs[0] := lTarget.Expression;
  for i: Integer := 0 to args.Length-1 do lArgs[i+1] := args[i].Expression;

  var lValue := Expression.Dynamic(
    new InvokeBinding(fGlobal, fBinder, CallInfo), 
    typeof(Object), 
    lArgs);
  result := new DynamicMetaObject(lValue, BindingRestrictions.Combine(ArrayUtils.Insert(target, args)));
end;

method InvokeMemberBinding.FallbackInvoke(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  exit fBinder.Call(new CallSignature(CallInfo.ArgumentCount), 
  fBinder.Factory,
  target,args);
end;

constructor CreateInstanceBinding(aGlobal: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);
begin
  inherited constructor(aCAllInfo);
  fGlobal := aGlobal;
  fBinder := aBinder;
end;

method CreateInstanceBinding.FallbackCreateInstance(target: DynamicMetaObject; args: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  if fBinder.CanConvertFrom(target.RuntimeType, typeof(&Type), false, NarrowingLevel.All) then begin
    target := 
      new DynamicMetaObject(Expression.Call(typeof(CreateInstanceBinding).GetMethod('GetConstructors', [typeof(&Type)]),
      fBinder.ConvertExpression(target.Expression, typeof(&Type), ConversionResultKind.ExplicitTry, fBinder.Factory)), target.Restrictions);
    
    result := fBinder.Call(new CallSignature(CallInfo.ArgumentCount), 
    fBinder.Factory,
    target,args);
  end;
  if assigned(result) and result.Expression.Type.IsValueType then 
    result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
end;

//  exit self.FallbackInvoke(fBinder.GetMember(self.Name, target), args, errorSuggestion);
class method CreateInstanceBinding.GetConstructors(aType: &Type): MemberGroup;
begin
  var lConstructors := aType.GetConstructors(BindingFlags.Public);
  exit new MemberGroup(lConstructors);
end;

method ScopeInvokeBinder.Bind(target: DynamicMetaObject; args: array of DynamicMetaObject): DynamicMetaObject;
begin
  var fGlobal := IScopeObject(args[0].Value):Root;
  if assigned(fName) then begin
    var lDym := Utilities.FallbackDynamic(fGlobal, target);
    if lDym <> nil then target := lDym;
    var lBinder := new GetMemberBinding(fGlobal, fBinder, fName);
    var orgtarget := target;
    target := lBinder.Bind(target, []);

    var lTmp := Expression.Variable(typeof(Object));
    target := new DynamicMetaObject(Expression.Block(typeof(Object), [lTmp], [Expression.Assign(lTmp, Expression.Convert(target.Expression, typeof(Object))), 
  Expression.IfThen(Expression.Equal(lTmp, Expression.Constant(Undefined.Instance)),  
    Expression.Call(Expression.Constant(fGlobal), 'RaiseNativeError', [], Expression.Constant(NativeErrorType.TypeError),
      Expression.Call(typeof(String), 'Format', [], Expression.Constant('Object {0} has no method ''{1}'''), Expression.Convert(orgtarget.Expression,typeof(object)), Expression.Constant(fName)))),
  Expression.IfThen(Expression.Not(Expression.Call(Typeof(Utilities), 'IsCallable', [], lTmp)),
    Expression.Call(Expression.Constant(fGlobal), 'RaiseNativeError', [], Expression.Constant(NativeErrorType.TypeError),
      Expression.Call(typeof(String), 'Format', [], Expression.Constant('Property ''{1}'' of object {0} is not callable'), Expression.Convert(orgtarget.Expression,typeof(object)) , Expression.Constant(fName)))),
      lTmp]), target.Restrictions);



    args[0] := orgtarget;
    var lNewArgs := new DynamicMetaObject[args.Length+2];
    var lArgs2 := new Expression[args.Length+1];
    for i: Integer := 0 to Length(args) -1 do
      lArgs2[1+i] := args[i].Expression;
    lArgs2[0] := target.Expression;
    exit new DynamicMetaObject(
      Expression.Dynamic(new ScopeInvokeBinder(fBinder, nil, fArgCount), typeof(Object), lArgs2), BindingRestrictions.Combine(args));
  end else begin
    //var lArgs := iif(target.LimitType = typeof(EcmaScriptEvalFunctionObject), args, ArrayUtils.RemoveFirst(args));
    if typeof(EcmaScriptFunctionObject).IsAssignableFrom(target.LimitType) then begin 
      var lBinder := new InvokeBinding(fGlobal, fBinder, new CallInfo(fArgCount));
      var lValue := lBinder.Bind(target, Args):Expression;

      if assigned(lValue) and lValue.Type.IsValueType then 
        lValue := Expression.Convert(lValue, typeof(Object));

      result := new DynamicMetaObject(lValue, BindingRestrictions.Combine(args));    
    end else begin
      var lBinder := new InvokeBinding(fGlobal, fBinder, new CallInfo(fArgCount));
      args := ArrayUtils.RemoveFirst(args);
      var lValue := lBinder.Bind(target, Args):Expression;

      if assigned(lValue) and lValue.Type.IsValueType then 
        lValue := Expression.Convert(lValue, typeof(Object));

      result := new DynamicMetaObject(lValue, BindingRestrictions.Combine(args));    
    end;
  end;
end;

constructor ScopeInvokeBinder(aBinder: EcmaScriptLanguageBinder; aName: String; aArgCount: Integer);
begin
  inherited constructor;
  fbinder := aBinder;
  fName := aName;
  fArgCount := aArgCount;
end;

end.