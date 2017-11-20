//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Dynamic,
  Microsoft.Scripting.Ast,
  Microsoft.Scripting.Generation,
  Microsoft.Scripting.Actions.*,
	RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal,
  Microsoft.Scripting,
  Microsoft.Scripting.Runtime,
  System.Runtime.CompilerServices;

type
  EcmaScriptLanguageBinder = class(DefaultBinder)
  private
    class var 
      fExtensionTypes: Dictionary<&Type, array of &Type>;
      
    var
      fItems: Array[0 .. Integer(BinaryOperatorBinding.ShiftRightUnsigned)] of CallSiteBinder := new array[0 .. Integer(BinaryOperatorBinding.ShiftRightUnsigned)] of CallSiteBinder;
      fFactory: OverloadResolverFactory;
    
  public
    constructor(manager: ScriptDomainManager);

    property Factory: OverloadResolverFactory read fFactory;

    method CreateUnaryOperationBinder(aType: ExpressionType): UnaryOperationBinder;
    method CreateBinaryOperationBinder(aType: ExpressionType): BinaryOperationBinder;
    method CreateConversionOperationBinder(aTo: &Type; aExplicit: Boolean): ConvertBinder;
    
    method CreateInvokeBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): InvokeBinder;
    method CreateGetMemberBinder(aGlobal: GlobalObject; aName: String): GetMemberBinder;
    method CreateSetMemberBinder(aGlobal: GlobalObject; aName: String): SetMemberBinder;
    method CreateInvokeMemberBinder(aGlobal: GlobalObject; aName: String; aCallInfo: CallInfo): InvokeMemberBinder;
    method CreateGetIndexBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): GetIndexBinder;
    method CreateSetIndexBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): SetIndexBinder;
    method CreateCreateInstanceBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): CreateInstanceBinder;

    method CanConvertFrom(fromType, toType: &Type; toNotNullable: Boolean; level: Microsoft.Scripting.Actions.Calls.NarrowingLevel): Boolean; override;
    method ConvertExpression(expr: Expression; toType: &Type; kind: ConversionResultKind; resolverFactory: OverloadResolverFactory): Expression; override;
    method PreferConvert(t1, t2: &Type): Microsoft.Scripting.Actions.Calls.Candidate; override;
    method GetExtensionTypes(t: &Type): IList<&Type>; override;
  end;
  DefaultOverloadResolverFactory =class(OverloadResolverFactory)
  private
    fBinder: EcmaScriptLanguageBinder;
  public
    constructor (aBinder: EcmaScriptLanguageBinder);
    method CreateOverloadResolver(args: IList<DynamicMetaObject>; signature: CallSignature; callType: CallTypes): DefaultOverloadResolver; override;
  end;

  //OverloadResolver
implementation


method EcmaScriptLanguageBinder.CreateBinaryOperationBinder(aType: ExpressionType): BinaryOperationBinder;
begin
  if fItems[aType] = nil then begin
    var lOperator := new BinaryOperatorBinding(aType, self);
    fItems[aType] := lOperator;
  end;

  exit fItems[aType] as BinaryOperatorBinding;
end;

method EcmaScriptLanguageBinder.CanConvertFrom(fromType, toType: &Type; toNotNullable: Boolean; level: Microsoft.Scripting.Actions.Calls.NarrowingLevel): Boolean;
begin
  var lFrom := &Type.GetTypeCode(fromType);
  var lTo := &Type.GetTypeCode(toType);

  if Microsoft.Scripting.Generation.CompilerHelpers.GetImplicitConverter(fromType, toType) <> nil then exit true;
  if fromType = toType then exit true;
  if toType.IsAssignableFrom(fromType) then exit true;

  result := toType = typeof(String);
end;

method EcmaScriptLanguageBinder.PreferConvert(t1, t2: &Type): Microsoft.Scripting.Actions.Calls.Candidate;
begin
  var t1Code := &Type.GetTypeCode( t1 );
	var t2Code := &Type.GetTypeCode( t2 );

  exit iif ( t1Code > t2Code, Candidate.One, iif (t1Code < t2Code, Candidate.Two, Candidate.Equivalent));
end;

method EcmaScriptLanguageBinder.ConvertExpression(expr: Expression; toType: &Type; kind: ConversionResultKind; resolverFactory: OverloadResolverFactory): Expression;
begin
  var lExpr := expr.Type;
  if (toType.IsAssignableFrom(lExpr) or (toType = lExpr)) and (toType.IsValueType = lExpr.IsValueType) then exit expr;
  toType := CompilerHelpers.GetVisibleType(toType);
  exit Expression.Dynamic(new ConversionOperatorBinding(self, toType, kind),
    toType, expr);
end;

method EcmaScriptLanguageBinder.GetExtensionTypes(t: &Type): IList<&Type>;
begin
  if fExtensionTypes = nil then begin
    var lExtensionTypes := new Dictionary<&Type,array of &Type>;
    lExtensionTypes.Add(typeof(double), [typeof(IntegerExtensions), typeof(DoubleExtensions)]);
    lExtensionTypes.Add(typeof(Integer), [typeof(IntegerExtensions), typeof(DoubleExtensions)]);
    lExtensionTypes.Add(typeof(Int64), [typeof(IntegerExtensions), typeof(DoubleExtensions)]);
    lExtensionTypes.Add(typeof(string), [typeof(StringExtensions)]);
    lExtensionTypes.Add(typeof(boolean), [typeof(BooleanExtensions)]);
    lExtensionTypes.Add(typeof(Undefined), [typeof(UndefinedExtensions)]);
    lExtensionTypes.Add(typeof(dynamicnull), [typeof(DynamicNullExtensions)]);
    fExtensionTypes := lExtensionTypes; 
  end;

  result := new List<&Type>;
  result.Add(t);

  var lTypes: Array of &Type;
  if fExtensionTypes.TryGetValue(t, out lTypes) then begin
    for each el in lTypes do result.Add(el);
  end;
end;

method EcmaScriptLanguageBinder.CreateConversionOperationBinder(aTo: &Type; aExplicit: Boolean): ConvertBinder;
begin
  result := new ConversionOperatorBinding(self, aTo, iif(aExplicit, ConversionResultKind.ExplicitCast, ConversionResultKind.ImplicitCast));
end;


method EcmaScriptLanguageBinder.CreateInvokeBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): InvokeBinder;
begin
  result := new InvokeBinding(aGlobal, Self, aCallInfo);
end;

constructor EcmaScriptLanguageBinder(manager: ScriptDomainManager);
begin
  inherited constructor();
  fFactory := new DefaultOverloadResolverFactory(self);
end;

method EcmaScriptLanguageBinder.CreateUnaryOperationBinder(aType: ExpressionType): UnaryOperationBinder;
begin
  if fItems[aType] = nil then begin
    var lOperator := new UnaryOperatorBinding(aType, self);
    fItems[aType] := lOperator;
  end;

  exit fItems[aType] as UnaryOperatorBinding;
end;

method EcmaScriptLanguageBinder.CreateGetMemberBinder(aGlobal: GlobalObject; aName: String): GetMemberBinder;
begin
  result := new GetMemberBinding(aGlobal, self, aName);
end;

method EcmaScriptLanguageBinder.CreateSetMemberBinder(aGlobal: GlobalObject; aName: String): SetMemberBinder;
begin
  result := new SetMemberBinding(aGlobal, self, aName);
end;

method EcmaScriptLanguageBinder.CreateInvokeMemberBinder(aGlobal: GlobalObject; aName: String; aCallInfo: CallInfo): InvokeMemberBinder;
begin
  result := new InvokeMemberBinding(aGlobal, self, aName, aCallInfo);
end;

method EcmaScriptLanguageBinder.CreateGetIndexBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): GetIndexBinder;
begin
  result := new GetIndexBinding(aGlobal, self, aCallInfo);
end;

method EcmaScriptLanguageBinder.CreateSetIndexBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): SetIndexBinder;
begin
  result := new SetIndexBinding(aGlobal, self, aCallInfo);
end;

method EcmaScriptLanguageBinder.CreateCreateInstanceBinder(aGlobal: GlobalObject; aCallInfo: CallInfo): CreateInstanceBinder;
begin
  result := new CreateInstanceBinding(aGlobal, self, aCallInfo);
end;


constructor DefaultOverloadResolverFactory(aBinder: EcmaScriptLanguageBinder);
begin
  fBinder := aBinder;
end;

method DefaultOverloadResolverFactory.CreateOverloadResolver(args: IList<DynamicMetaObject>; signature: CallSignature; callType: CallTypes): DefaultOverloadResolver;
begin
  result := new NewOverloadResolver(fBinder, args, signature, calltype);
end;

end.