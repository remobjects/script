{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Text,
  System.Dynamic,
  Microsoft.Scripting.Ast,
  RemObjects.Script.EcmaScript.Internal,
  Microsoft.Scripting,
  Microsoft.Scripting.Actions;

type
  BinaryOperatorMethod  nested in BinaryOperatorBinding = private method (target, arg: DynamicMetaObject): DynamicMetaObject;
  BinaryOperatorBinding = class(BinaryOperationBinder)
  private
    fBinder: EcmaScriptLanguageBinder;
    fHandler: BinaryOperatorMethod;
    fOperator: ExpressionType;
    method GetMetaObject(target: DynamicMetaObject; arg: DynamicMetaObject; left: Expression):DynamicMetaObject;
  protected
    method AddHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method SubHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method ComparisonHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method EqualityComparisonHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method DefaultHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method AndAlsoHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method OrElseHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method MultiplicativeHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method ShiftHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
    method OrHandler(target, arg: DynamicMetaObject): DynamicMetaObject;

 
  public
    const ShiftRightUnsigned: ExpressionType = ExpressionType(High(ExpressionType) + 1);
    constructor(aOperator: ExpressionType; aBinder: EcmaScriptLanguageBinder);
    method FallbackBinaryOperation(target, arg, errorSuggestion: DynamicMetaObject): DynamicMetaObject; override;
  end;
  
implementation

method BinaryOperatorBinding.FallbackBinaryOperation(target, arg, errorSuggestion: DynamicMetaObject): DynamicMetaObject;
begin
  result := fHandler(target, arg);
end;

constructor BinaryOperatorBinding(aOperator: ExpressionType; aBinder: EcmaScriptLanguageBinder);
begin
  fOperator := aOperator;
  if aOperator = ExpressionType.AndAlso then aOperator := ExpressionType.And;
  if aOperator = ExpressionType.OrElse then aOperator := ExpressionType.Or;
  if aOperator = ShiftRightUnsigned then aOperator := ExpressionType.RightShift;
  inherited constructor(aOperator);
  fBinder := aBinder;
  case fOperator of
    ExpressionType.Add: fHandler := @AddHandler;
    ExpressionType.Subtract: fHandler := @SubHandler;
    ExpressionType.LessThan,
    ExpressionType.GreaterThan,
    ExpressionType.LessThanOrEqual,
    ExpressionType.GreaterThanOrEqual: fHandler := @ComparisonHandler;
    ExpressionType.Equal,
    ExpressionType.NotEqual: fHandler := @EqualityComparisonHandler;
    ExpressionType.AndAlso: fHandler := @AndAlsoHandler;
    ExpressionType.OrElse: fHandler := @OrElseHandler;

    ExpressionType.Or,
    ExpressionType.And,
    EXpressionType.ExclusiveOr: fHandler := @OrHandler;

    ExpressionType.Multiply,
    ExpressionType.Divide,
    ExpressionType.Modulo: fHandler := @MultiplicativeHandler;
    ExpressionType.LeftShift,
    ExpressionType.RightShift,
    ShiftRightUnsigned: fHandler := @ShiftHandler;
  else
    fHandler := @DefaultHandler;
  end; // case
end;

method BinaryOperatorBinding.AddHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var lBinding: BindingRestrictions;
  if target.Value = nil then 
    lBinding := BindingRestrictions.GetInstanceRestriction(target.Expression, target.Value)
  else
    lBinding := BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType);
  if arg.Value = nil then 
    lBinding := lBinding.Merge(BindingRestrictions.GetInstanceRestriction(arg.Expression, arg.Value))
  else
    lBinding := lBinding.Merge(BindingRestrictions.GetTypeRestriction(arg.Expression, arg.LimitType));

  if (target.LimitType = typeof(String)) or (arg.LimitType = typeof(String)) then begin
    arg := new DynamicMetaObject(fBinder.ConvertExpression(arg.Expression, typeof(string), ConversionResultKind.ImplicitCast, nil), arg.Restrictions);
    Target := new DynamicMetaObject(fBinder.ConvertExpression(target.Expression, typeof(string), ConversionResultKind.ImplicitCast, nil), target.Restrictions);
  end else if (target.LimitType = typeof(Integer)) and (arg.LimitType= typeof(Integer)) then begin
    target := fBinder.ConvertTo(typeof(Integer), ConversionResultKind.ImplicitCast, target);
    arg := fBinder.ConvertTo(typeof(Integer), ConversionResultKind.ImplicitCast, arg);
  end else  begin
    target := fBinder.ConvertTo(typeof(Double), ConversionResultKind.ImplicitCast, target);
    arg := fBinder.ConvertTo(typeof(Double), ConversionResultKind.ImplicitCast, arg);
  end;
  
  //fBinder.Do
  result := fBinder.DoOperation(ExpressionType.Add, target, arg);
  if result.LimitType = typeof(void) then 
    result := new DynamicMetaObject(Expression.Block(result.Expression, Expression.Constant(Undefined.Instance)), lBinding)
  else
    result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), lBinding);
end;

method BinaryOperatorBinding.DefaultHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  result := fBinder.ConvertTo(typeof(Object), ConversionResultKind.ImplicitTry, fBinder.DoOperation(fOperator, target, arg), fBinder.Factory);
end;

method BinaryOperatorBinding.ComparisonHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var lBinding: BindingRestrictions;
  if target.Value = nil then 
    lBinding := BindingRestrictions.GetInstanceRestriction(target.Expression, target.Value)
  else
    lBinding := BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType);
  if arg.Value = nil then 
    lBinding := lBinding.Merge(BindingRestrictions.GetInstanceRestriction(arg.Expression, arg.Value))
  else
    lBinding := lBinding.Merge(BindingRestrictions.GetTypeRestriction(arg.Expression, arg.LimitType));
  var lRes: Expression;
  if (target.LimitType = typeof(String)) or (arg.LimitType = typeof(String)) then begin
    arg := new DynamicMetaObject(fBinder.ConvertExpression(arg.Expression, typeof(string), ConversionResultKind.ImplicitCast, nil), arg.Restrictions);
    Target := new DynamicMetaObject(fBinder.ConvertExpression(target.Expression, typeof(string), ConversionResultKind.ImplicitCast, nil), target.Restrictions);
    //String.Compare( StringComparison.Ordinal
    
    lRes := Expression.Call(typeof(String).GetMethod('Compare', [typeof(string), typeof(string), typeof(StringComparison)]),  target.Expression, arg.Expression, Expression.Constant(StringComparison.Ordinal));
    case foperator of
      ExpressionType.LessThan: lRes := Expression.LessThan(lres, Expression.Constant(0));
      ExpressionType.LessThanOrEqual: lRes := Expression.LessThanOrEqual(lres, Expression.Constant(0));
      ExpressionType.GreaterThan: lRes := Expression.GreaterThan(lres, Expression.Constant(0));
      //ExpressionType.GreaterThanOrEqual: ;
    else
      lRes := Expression.GreaterThanOrEqual(lres, Expression.Constant(0));
    end;
  end else if (target.LimitType = typeof(Integer)) and (arg.LimitType= typeof(Integer)) then begin
    target := fBinder.ConvertTo(typeof(Integer), ConversionResultKind.ImplicitCast, target);
    arg := fBinder.ConvertTo(typeof(Integer), ConversionResultKind.ImplicitCast, arg);
    
    case foperator of
      ExpressionType.LessThan: lRes := Expression.LessThan(target.Expression, arg.Expression);
      ExpressionType.LessThanOrEqual: lRes := Expression.LessThanOrEqual(target.Expression, arg.Expression);
      ExpressionType.GreaterThan: lRes := Expression.GreaterThan(target.Expression, arg.Expression);
      //ExpressionType.GreaterThanOrEqual: ;
    else
      lRes := Expression.GreaterThanOrEqual(target.Expression, arg.Expression);
    end; // case
  end else  begin
    target := fBinder.ConvertTo(typeof(Double), ConversionResultKind.ImplicitCast, target);
    arg := fBinder.ConvertTo(typeof(Double), ConversionResultKind.ImplicitCast, arg);
    var left := Expression.Variable(target.LimitType);
    var right := Expression.Variable(arg.LimitType);
    case foperator of
      ExpressionType.LessThan: lRes := Expression.LessThan(left, right);
      ExpressionType.LessThanOrEqual: lRes := Expression.LessThanOrEqual(left, right);
      ExpressionType.GreaterThan: lRes := Expression.GreaterThan(left, right);
      //ExpressionType.GreaterThanOrEqual: ;
    else
      lRes := Expression.GreaterThanOrEqual(left, right);
    end; // case
    lRes := Expression.Block(typeof(Object), [left, right],
      Expression.Assign(left, target.Expression),
      Expression.Assign(right, arg.Expression),
      Expression.Condition(Expression.OrElse(Expression.Equal(left, Expression.Constant(double.NaN)), 
        Expression.Equal(right, Expression.Constant(double.NaN))), Expression.Constant(Undefined.Instance, typeof(Object)),
      Expression.Convert(lRes, typeof(Object))));
  end;
  
  result := new DynamicMetaObject(Expression.Convert(lRes, typeof(Object)), lBinding);
end;

method BinaryOperatorBinding.EqualityComparisonHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var left, right: Expression;
  left := Expression.Convert(target.Expression, target.LimitType);
  right := Expression.Convert(arg.Expression, arg.LimitType);
  
  if left.Type <> right.Type then begin
    if ((left.Type = typeof(Undefined)) or (left.Type = typeof(Microsoft.Scripting.Runtime.DynamicNull))) and
    ((right.Type = typeof(Undefined)) or (right.Type = typeof(Microsoft.Scripting.Runtime.DynamicNull))) then
      left := Expression.Constant(true)
    else if ((left.Type = typeof(string)) or (left.Type = typeof(boolean))) and (&Type.GetTypeCode(right.Type) in [TypeCode.Int32, TypeCode.Int64, TypeCode.Int16, TypeCode.SByte,
      TypeCode.UInt32, TypeCode.UInt64, TypeCode.UInt16, TypeCode.Byte, TypeCode.Double, TypeCode.Single]) then
      left := Expression.Equal(
         Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), left),
         Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), right))
    else if ((right.Type = typeof(string)) or (right.Type = typeof(boolean))) and (&Type.GetTypeCode(left.Type) in [TypeCode.Int32, TypeCode.Int64, TypeCode.Int16, TypeCode.SByte,
      TypeCode.UInt32, TypeCode.UInt64, TypeCode.UInt16, TypeCode.Byte, TypeCode.Double, TypeCode.Single]) then
      left := Expression.Equal(
         Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), left),
         Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), right))
    else if ((&Type.GetTypeCode(left.Type) in [TypeCode.Int32, TypeCode.Int64, TypeCode.Int16, TypeCode.SByte,
      TypeCode.UInt32, TypeCode.UInt64, TypeCode.UInt16, TypeCode.Byte, TypeCode.Double, TypeCode.Single, Typecode.String])) and (typeof(EcmaScriptObject).IsAssignableFrom(right.Type)) then
      left := Expression.Dynamic(new BinaryOperatorBinding(fOperator, fBinder), typeof(Boolean), left, Expression.Call(typeof(Utilities), 'GetPrimitive', [], right))
    else if ((&Type.GetTypeCode(right.Type) in [TypeCode.Int32, TypeCode.Int64, TypeCode.Int16, TypeCode.SByte,
      TypeCode.UInt32, TypeCode.UInt64, TypeCode.UInt16, TypeCode.Byte, TypeCode.Double, TypeCode.Single, Typecode.String])) and (typeof(EcmaScriptObject).IsAssignableFrom(left.Type)) then
      left := Expression.Dynamic(new BinaryOperatorBinding(fOperator, fBinder), typeof(Boolean), Expression.Call(typeof(Utilities), 'GetPrimitive', [], left), right)
    else
       left := Expression.Constant(false);
    // step 14
  end else begin
    if left.Type = typeof(Undefined) then left := Expression.Constant(true) else
    if arg.LimitType = typeof(Microsoft.Scripting.Runtime.DynamicNull) then left := Expression.Constant(true) else
    if &Type.GetTypeCode(arg.LimitType) in [TypeCode.Int32, TypeCode.Int64, TypeCode.Int16, TypeCode.SByte,
    TypeCode.UInt32, TypeCode.UInt64, TypeCode.UInt16, TypeCode.Byte, TypeCode.Boolean] then
      left := Expression.Equal(left, right)
    else if left.Type = (typeof(string)) then
      left := Expression.Call(typeof(String).GetMethod('Equals', [typeof(string), typeof(string)]), left, right)
    else 
      left := Expression.Equal(left, right);
  end;
  if fOperator = ExpressionType.NotEqual then
    left := Expression.Not(left);

  exit GetMetaObject(target, arg, left);
end;

method BinaryOperatorBinding.AndAlsoHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var lBinding: BindingRestrictions;
  if target.Value = nil then 
    lBinding := BindingRestrictions.GetInstanceRestriction(target.Expression, target.Value)
  else
    lBinding := BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType);
  if arg.Value = nil then 
    lBinding := lBinding.Merge(BindingRestrictions.GetInstanceRestriction(arg.Expression, arg.Value))
  else
    lBinding := lBinding.Merge(BindingRestrictions.GetTypeRestriction(arg.Expression, arg.LimitType));

  var te := target.Expression;
  var ae := arg.Expression;
  if target.LimitType <> typeof(Object) then
    te := fBinder.ConvertExpression(Expression.Convert(te, target.LimitType), typeof(Object), ConversionResultKind.ImplicitTry, nil);
  if arg.LimitType <> typeof(Object) then
    ae := fBinder.ConvertExpression(Expression.Convert(ae, arg.LimitType), typeof(Object), ConversionResultKind.ImplicitTry, nil);
  if ae.Type <> typeof(Object) then
    ae := Expression.Convert(ae, typeof(Object));
  var lVar := Expression.Variable(typeOf(object));
  exit new DynamicMetaObject(Expression.Block(typeof(object), [lVar], [Expression.Assign(lVar, te), Expression.Condition(
    fBinder.ConvertExpression(te, typeof(Boolean), ConversionResultKind.ImplicitTry, nil),
    ae, lVar)]), lBinding);
end;

method BinaryOperatorBinding.OrElseHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var lBinding: BindingRestrictions;
  if target.Value = nil then 
    lBinding := BindingRestrictions.GetInstanceRestriction(target.Expression, target.Value)
  else
    lBinding := BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType);
  if arg.Value = nil then 
    lBinding := lBinding.Merge(BindingRestrictions.GetInstanceRestriction(arg.Expression, arg.Value))
  else
    lBinding := lBinding.Merge(BindingRestrictions.GetTypeRestriction(arg.Expression, arg.LimitType));
  var te := target.Expression;
  var ae := arg.Expression;
  if target.LimitType = typeof(Undefined) then
   te := Expression.Constant(nil, typeof(object))
  else
  if target.LimitType <> typeof(Object) then
    te := fBinder.ConvertExpression(Expression.Convert(te, target.LimitType), typeof(Object), ConversionResultKind.ImplicitTry, nil);
  if arg.LimitType <> typeof(Object) then
    ae := fBinder.ConvertExpression(Expression.Convert(ae, arg.LimitType), typeof(Object), ConversionResultKind.ImplicitTry, nil);
  if te.Type <> typeof(Object) then
    te := Expression.Convert(te, typeof(Object));
  if ae.Type <> typeof(Object) then
    ae := Expression.Convert(ae, typeof(Object));
  var lVar := Expression.Variable(typeOf(object));
  exit new DynamicMetaObject(Expression.Block(typeof(object), [lVar], [Expression.Assign(lVar, te), Expression.Condition(
    fBinder.ConvertExpression(te, typeof(Boolean), ConversionResultKind.ImplicitTry, nil),
    lVar, ae)]), lBinding);
end;

method BinaryOperatorBinding.MultiplicativeHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var left, right: Expression;
  left := if target.LimitType = typeof(Double) then Expression.Convert(target.Expression, typeof(Double)) else  Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), target.Expression);
  right := if arg.LimitType = typeof(Double) then Expression.Convert(arg.Expression, typeof(Double)) else Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), arg.Expression);
   
  case fOperator of
    ExpressionType.Divide: left := Expression.Divide(left, right);
    ExpressionType.Modulo: left := Expression.Modulo(left, right);
  else left := Expression.Multiply(left, right);
  end; // case

  exit GetMetaObject(target, arg, left);
end;

method BinaryOperatorBinding.GetMetaObject(target: DynamicMetaObject; arg: DynamicMetaObject; left: Expression): DynamicMetaObject;
begin
  var lBinding: BindingRestrictions;
  if target.Value = nil then 
    lBinding := BindingRestrictions.GetInstanceRestriction(target.Expression, target.Value)
  else
    lBinding := BindingRestrictions.GetTypeRestriction(target.Expression, target.LimitType);
  if arg.Value = nil then 
    lBinding := lBinding.Merge(BindingRestrictions.GetInstanceRestriction(arg.Expression, arg.Value))
  else
    lBinding := lBinding.Merge(BindingRestrictions.GetTypeRestriction(arg.Expression, arg.LimitType));
  if left.Type <> typeof(Object) then
     left := Expression.Convert(left, typeof(Object));
  exit new DynamicMetaObject(left, lBinding);
end;

method BinaryOperatorBinding.SubHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var left, right: Expression;
  if (target.LimitType = typeof(Int32)) and (arg.LimitType = typeof(Int32)) then begin
    left := Expression.Convert(target.Expression, typeof(int32));
    right := Expression.Convert(arg.Expression, typeof(int32));
  end else begin
    left := if target.LimitType = typeof(Double) then Expression.Convert(target.Expression, typeof(Double)) else  Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), target.Expression);
    right := if arg.LimitType = typeof(Double) then Expression.Convert(arg.Expression, typeof(Double)) else Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Double), ConversionResultKind.ImplicitCast), typeof(Double), arg.Expression);
  end;
  left := Expression.Subtract(left, right);

  exit GetMetaObject(target, arg, left);

end;

method BinaryOperatorBinding.ShiftHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var left, right: Expression;
  left := Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Int32), ConversionResultKind.ImplicitCast), typeof(Int32), target.Expression);
  right := Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Int32), ConversionResultKind.ImplicitCast), typeof(Int32), arg.Expression);
   
  case fOperator of
    ExpressionType.LeftShift: left := Expression.LeftShift(left, right);
    ExpressionType.RightShift: left := Expression.RightShift(left, right);
  else left := Expression.RightShift(Expression.Convert(left, typeof(UInt32)), right);
  end; // case

  exit GetMetaObject(target, arg, left);

end;

method BinaryOperatorBinding.OrHandler(target, arg: DynamicMetaObject): DynamicMetaObject;
begin
  var left, right: Expression;
  left := Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Int32), ConversionResultKind.ImplicitCast), typeof(Int32), target.Expression);
  right := Expression.Dynamic(new ConversionOperatorBinding(fBinder, typeof(Int32), ConversionResultKind.ImplicitCast), typeof(Int32), arg.Expression);
   
  case fOperator of
    ExpressionType.Or: left := Expression.Or(left, right);
    ExpressionType.And: left := Expression.And(left, right);
  else left := Expression.ExclusiveOr(left, right);
  end; // case

  exit GetMetaObject(target, arg, left);

end;

end.