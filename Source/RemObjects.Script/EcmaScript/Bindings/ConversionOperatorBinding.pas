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
  ConversionOperatorBinding = class(ConvertBinder)
  private
    fBinding: EcmaScriptLanguageBinder;
    fConversion: ConversionResultKind;
  protected
  public
    constructor (aBinder: EcmaScriptLanguageBinder; aType: &Type; aConversion: ConversionResultKind);
    method FallbackConvert(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;
  
implementation

constructor ConversionOperatorBinding(aBinder: EcmaScriptLanguageBinder; aType: &Type; aConversion: ConversionResultKind);
begin
  inherited constructor(aType, (aConversion = ConversionResultKind.ExplicitCast) or (aConversion = ConversionResultKind.ExplicitTry));
  fBinding := aBinder;
  fConversion := aConversion;
end;

method ConversionOperatorBinding.FallbackConvert(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  if target.LimitType = typeof(void) then 
    exit new DynamicMetaObject(
      LExpr.Block(
        target.Expression,
        LExpr.Constant(Undefined.Instance)
        ), 
      target.Restrictions);
  if &Type = typeof(Boolean) then begin
    if target.LimitType.IsValueType then begin
      if target.LimitType = typeof(Boolean) then
        exit new DynamicMetaObject(Expression.Convert(target.Expression, typeof(Boolean)), target.Restrictions);
      if target.LimitType = typeof(Int32) then
        exit new DynamicMetaObject(Expression.NotEqual(Expression.Convert(target.Expression, typeof(Int32)), Expression.Constant(0, typeof(Int32))), target.Restrictions);
      if target.LimitType = typeof(Int64) then
        exit new DynamicMetaObject(Expression.NotEqual(Expression.Convert(target.Expression, typeof(Int64)), Expression.Constant(0, typeof(Int64))), target.Restrictions);
      if target.LimitType = typeof(Double) then
        exit new DynamicMetaObject(Expression.NotEqual(Expression.Convert(target.Expression, typeof(Double)), Expression.Constant(0.0, typeof(double))), target.Restrictions);
    end;
    if target.LimitType = typeof(Undefined) then
      exit new DynamicMetaObject(Expression.Constant(false), target.Restrictions)
    else 
      exit new DynamicMetaObject(Expression.NotEqual(Expression.Convert(target.Expression, typeof(object)), Expression.Constant(nil, typeof(object))), target.Restrictions);
  end;
  if target.LimitType <> target.Expression.Type then
    target := new DynamicMetaObject(Expression.Convert(target.Expression, target.LimitType), target.Restrictions);
  exit fBinding.ConvertTo(&Type, fConversion, target, fBinding.Factory);
end;

end.