{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface
uses
  System.Collections.Generic,
  System.Text,
  Microsoft.Scripting.Ast,
  RemObjects.Script.EcmaScript.Internal,
  Microsoft.Scripting,
  System.Dynamic,
  Microsoft.Scripting.Actions;

type
  GetMemberBinding = class(GetMemberBinder)
  private
    fGlobalObject: GlobalObject; 
    fBinder: EcmaScriptLanguageBinder;
  public
    constructor (aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aName: String);
    method FallbackGetMember(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

  GetIndexBinding = class(GetIndexBinder)
  private
    fBinder: EcmaScriptLanguageBinder;
    fGlobalObject: GlobalObject; 
  public
    constructor (aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);
    method FallbackGetIndex(target: DynamicMetaObject; indexes: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

  SetIndexBinding = class(SetIndexBinder)
  private
    fBinder: EcmaScriptLanguageBinder;
    fGlobalObject: GlobalObject; 
  public
    constructor (aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);
    method FallbackSetIndex(target: DynamicMetaObject; indexes: array of DynamicMetaObject; value, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

  SetMemberBinding = class(SetMemberBinder)
  private
    fBinder: EcmaScriptLanguageBinder;
    fGlobalObject: GlobalObject; 
  public
    constructor (aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aName: String);
    method FallbackSetMember(target, value, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;

implementation

constructor GetMemberBinding(aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aName: String);
begin
  inherited constructor(aName, false);
  fGlobalObject := aGlobalObject;
  fBinder := aBinder;
end;

method GetMemberBinding.FallbackGetMember(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  result := Utilities.FallbackDynamic(fGlobalObject, target);
  if result <> nil then result := Coalesce(result.BindGetMember(self), errorSuggestion) else begin
	  var lNamespace := NamespaceTracker(target.Value);
		if lNamespace <> nil  then begin
		  var lMt: MemberTracker;
			
			if lNamespace.TryGetValue(self.Name, out lMt) then begin
			  exit new DynamicMetaObject(Expression.Constant(lMt), target.Restrictions, lMt);
			end;
		end;
		result := fBinder.GetMember(Name, target, fBinder.Factory, false, new DynamicMetaObject(Expression.Constant(Undefined.Instance), BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType)));
	end;
  if assigned(result) and result.Expression.Type.IsValueType then 
    result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
end;

constructor SetMemberBinding(aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aName: String);
begin
  inherited constructor(aName, false);
  fBinder := aBinder;
  fGlobalObject := aGlobalObject;
end;

method SetMemberBinding.FallbackSetMember(target, value, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  result := Utilities.FallbackDynamic(fGlobalObject, target);
  if result <> nil then begin
    result := Coalesce(result.BindSetMember(self, value), errorSuggestion);
  end else
    result := fBinder.SetMember(Name, target, value, errorSuggestion);
  
  if assigned(result) and result.Expression.Type.IsValueType then 
    result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
end;

constructor SetIndexBinding(aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);
begin
  inherited constructor (aCallInfo);
  fGlobalObject := aGlobalObject;
  fBinder := aBinder;
end;

method SetIndexBinding.FallbackSetIndex(target: DynamicMetaObject; indexes: array of DynamicMetaObject; value, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  result := Utilities.FallbackDynamic(fGlobalObject, target);
  if result <> nil then begin
    result := Coalesce(result.BindSetIndex(self, indexes, value), errorSuggestion);
    if assigned(result) and result.Expression.Type.IsValueType then 
      result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
    exit;
  end;
  target := new DynamicMetaObject(target.Expression, BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType), target.Value);
  for i: Integer := 0 to length(indexes) -1 do begin
    indexes[i] := new DynamicMetaObject(indexes[i].Expression, BindingRestrictions.GetTypeRestriction(indexes[i].Expression, indexes[i].LimitType), indexes[i].Value);
  end;

  errorSuggestion := coalesce(errorsuggestion, new DynamicMetaObject(Expression.Constant(Undefined.Instance), 
    BindingRestrictions.Combine(Microsoft.Scripting.Utils.ArrayUtils.Append(Microsoft.Scripting.Utils.ArrayUtils.Insert(target, indexes), value))));
  var lItems := target.LimitType.GetCustomAttributes(typeof(System.Reflection.DefaultMemberAttribute), true);
  if length(lItems) <> 0 then begin
    var lTarget := fBinder.GetMember('set_'+System.Reflection.DefaultMemberAttribute(lItems[0]).MemberName, target, fBinder.Factory, false, errorSuggestion);
    var lArgs := new Expression[indexes.Length + 2];
    lArgs[0] := lTarget.Expression;
    for i: Integer := 0 to indexes.Length-1 do lArgs[i+1] := indexes[i].Expression;
    lArgs[lARgs.Length-1] := value.Expression;

    var lValue := Expression.Dynamic(
      new InvokeBinding(fGlobalObject, fBinder, new CallInfo(2)), 
      typeof(Object), 
      lArgs);
    result := new DynamicMetaObject(lValue, errorSuggestion.Restrictions);
  end else 
    result := errorSuggestion;

  if assigned(result) and result.Expression.Type.IsValueType then 
    result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
end;

constructor GetIndexBinding(aGlobalObject: GlobalObject; aBinder: EcmaScriptLanguageBinder; aCallInfo: CallInfo);
begin
  inherited constructor (aCallInfo);
  fGlobalObject := aGlobalObject;
  fBinder := aBinder;
end;

method GetIndexBinding.FallbackGetIndex(target: DynamicMetaObject; indexes: array of DynamicMetaObject; errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  result := Utilities.FallbackDynamic(fGlobalObject, target);
  if result <> nil then begin
    result := Coalesce(result.BindGetIndex(self, indexes), errorSuggestion);
    if assigned(result) and result.Expression.Type.IsValueType then 
      result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
    exit;
  end;
  target := new DynamicMetaObject(target.Expression, BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType), target.Value);
  for i: Integer := 0 to length(indexes) -1 do begin
    indexes[i] := new DynamicMetaObject(indexes[i].Expression, BindingRestrictions.GetTypeRestriction(indexes[i].Expression, indexes[i].LimitType), indexes[i].Value);
  end;

  errorSuggestion := coalesce(errorsuggestion, new DynamicMetaObject(Expression.Constant(Undefined.Instance), BindingRestrictions.Combine(Microsoft.Scripting.Utils.ArrayUtils.Insert(target, indexes))));
  var lItems := target.LimitType.GetCustomAttributes(typeof(System.Reflection.DefaultMemberAttribute), true);
  if length(lItems) <> 0 then begin
    var lTarget := fBinder.GetMember('get_'+System.Reflection.DefaultMemberAttribute(lItems[0]).MemberName, target, fBinder.Factory, false, errorSuggestion);
    var lArgs := new Expression[indexes.Length + 1];
    lArgs[0] := lTarget.Expression;
    for i: Integer := 0 to indexes.Length-1 do lArgs[i+1] := indexes[i].Expression;

    var lValue := Expression.Dynamic(
      new InvokeBinding(fGlobalObject, fBinder, CallInfo), 
      typeof(Object), 
      lArgs);
    result := new DynamicMetaObject(lValue, errorSuggestion.Restrictions);
  end else 
    result := errorSuggestion;

  if assigned(result) and result.Expression.Type.IsValueType then 
    result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
end;


end.