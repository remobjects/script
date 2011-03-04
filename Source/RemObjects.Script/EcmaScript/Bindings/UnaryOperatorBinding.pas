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
  UnaryOperatorMethod  nested in UnaryOperatorBinding = private method (target: DynamicMetaObject): DynamicMetaObject;
  UnaryOperatorBinding = class(ExtensionUnaryOperationBinder)
  private
    fBinder: EcmaScriptLanguageBinder;
    fHandler: UnaryOperatorMethod;
  protected
    method NotHandler(target: DynamicMetaObject): DynamicMetaObject;
    method OnesComplementHandler(target: DynamicMetaObject): DynamicMetaObject;
    method NegateHandler(target: DynamicMetaObject): DynamicMetaObject;
    method UnaryPlusHandler(target: DynamicMetaObject): DynamicMetaObject;
    method PostDecrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
    method PostIncrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
    method PreDecrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
    method PreIncrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
  public
    constructor(aOperator: ExpressionType; aBinder: EcmaScriptLanguageBinder);
    method FallbackUnaryOperation(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;
  
implementation


constructor UnaryOperatorBinding(aOperator: ExpressionType; aBinder: EcmaScriptLanguageBinder);
begin
  inherited constructor(aOperator.ToString());
  fBinder := aBinder;
  case aOperator of
    ExpressionType.Not: fHandler := @NotHandler;
    ExpressionType.OnesComplement: fHandler := @OnesComplementHandler;
    ExpressionType.Negate: fHandler := @NegateHandler;
    ExpressionType.UnaryPlus: fHandler := @UnaryPlusHandler;
    ExpressionType.PostDecrementAssign: fHandler := @PostDecrementAssignHandler;
    ExpressionType.PostIncrementAssign: fHandler := @PostIncrementAssignHandler;
    ExpressionType.PreDecrementAssign: fHandler := @PreDecrementAssignHandler;
    ExpressionType.PreIncrementAssign: fHandler := @PreIncrementAssignHandler;
  end; // case
end;

method UnaryOperatorBinding.FallbackUnaryOperation(target, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  result := fHandler(target);
  if not result.Expression.Type.Equals(typeof(System.Object)) then
    result := fBinder.ConvertTo(typeof(Object), ConversionResultKind.ImplicitCast, result, fBinder.Factory);
end;

method UnaryOperatorBinding.NotHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  var lOrg := target;
  if target.LimitType <> typeof(Int32) then
    target := fBinder.ConvertTo(typeof(Int32), ConversionResultKind.ImplicitCast, target);
  var el := target.Expression;
  if el.Type <> typeof(Int32) then
     el := Expression.Convert(el, typeof(Int32));
  exit new DynamicMetaObject(Expression.Not(el), BindingRestrictions.GetTypeRestriction(lOrg.Expression, lOrg.LimitType));
end;

method UnaryOperatorBinding.OnesComplementHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  var lOrg := target;
  if target.LimitType <> typeof(Boolean) then
    target := fBinder.ConvertTo(typeof(Boolean), ConversionResultKind.ImplicitCast, target);
  var el := target.Expression;
  if el.Type <> typeof(Boolean) then
     el := Expression.Convert(el, typeof(Boolean));  exit new DynamicMetaObject(Expression.Not(el), BindingRestrictions.GetTypeRestriction(lOrg.Expression, lOrg.LimitType));
end;

method UnaryOperatorBinding.NegateHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  var lOrg := target;
  if target.LimitType = typeof(Int32) then begin
    var el := target.Expression;
    if el.Type <> typeof(Int32) then
       el := Expression.Convert(el, typeof(Int32));
    exit new DynamicMetaObject(Expression.Negate(el), BindingRestrictions.GetTypeRestriction(lOrg.Expression, lOrg.LimitType));
  end;
  target := self.fBinder.ConvertTo(typeof(Double), ConversionResultKind.ImplicitCast, target);

  var el := target.Expression;
  if el.Type <> typeof(Double) then
     el := Expression.Convert(el, typeof(Double));
  exit new DynamicMetaObject(Expression.Negate(el), BindingRestrictions.GetTypeRestriction(lOrg.Expression, lOrg.LimitType));
end;

method UnaryOperatorBinding.UnaryPlusHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  var lOrg := Target;
  if target.LimitType = typeof(Int32) then
    exit target;
  target := self.fBinder.ConvertTo(typeof(Double), ConversionResultKind.ImplicitCast, target);
  exit new DynamicMetaObject(target.Expression, BindingRestrictions.GetTypeRestriction(lOrg.Expression, lOrg.LimitType));
end;

method UnaryOperatorBinding.PostDecrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  result := fBinder.DoOperation(self.Operation, target);
end;

method UnaryOperatorBinding.PostIncrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  result := fBinder.DoOperation(self.Operation, target);
end;

method UnaryOperatorBinding.PreDecrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  result := fBinder.DoOperation(self.Operation, target);
end;

method UnaryOperatorBinding.PreIncrementAssignHandler(target: DynamicMetaObject): DynamicMetaObject;
begin
  result := fBinder.DoOperation(self.Operation, target);
end;

end.