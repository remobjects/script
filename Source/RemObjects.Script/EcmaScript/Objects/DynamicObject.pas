namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  Microsoft.Scripting,
  Microsoft.Scripting.Ast,
  RemObjects.Script,
  System.Dynamic,
  Microsoft.Scripting.Utils,
  System.Text;

type
  EcmaScriptDynamicMetaObject = public class(DynamicMetaObject)
  private
    fOwner: EcmaScriptObject;
  assembly 
    class var
      fSetMemberMethod,
      fGetMemberMethod,
      fSetIndexMethod,
      fGetIndexMethod,
      fInvokeMethod,
      fCreateMethod,
      fInvokeExMethod: System.Reflection.MethodInfo; readonly;
  public
    class constructor;
    constructor (aParameter: Expression; aOwner: EcmaScriptObject; aValue: Object);
    constructor(aParameter: Expression; aOwner: EcmaScriptObject);

    method BindSetMember(binder: SetMemberBinder; value: DynamicMetaObject): DynamicMetaObject; override;
    method BindSetIndex(binder: SetIndexBinder; indexes: array of DynamicMetaObject; value: DynamicMetaObject): DynamicMetaObject; override;
    method BindInvoke(binder: InvokeBinder; args: array of DynamicMetaObject): DynamicMetaObject; override;
    method BindInvokeMember(binder: InvokeMemberBinder; args: array of DynamicMetaObject): DynamicMetaObject; override;
    method BindGetMember(binder: GetMemberBinder): DynamicMetaObject; override;
    method BindGetIndex(binder: GetIndexBinder; indexes: array of DynamicMetaObject): DynamicMetaObject; override;
    method GetDynamicMemberNames: IEnumerable<String>; override;
    method BindCreateInstance(binder: CreateInstanceBinder; args: array of DynamicMetaObject): DynamicMetaObject; override;
    method MakeObject(aValue: Expression): Expression; 
  end;

  EcmaScriptTypeHelperDynamicObject = public abstract class(DynamicMetaObject)
  private
  public
    method Put(aSelf: Object; aName: String; aValue: Object): Object; abstract;
    method Get(aSelf: Object; aName: String): Object; abstract;
    method PutIndex(aSelf: Object; aIndex: Integer; aValue: Object): Object; abstract;
    method GetIndex(aSelf: Object; aIndex: Integer): Object; abstract;

    method BindGetIndex(binder: GetIndexBinder; indexes: array of DynamicMetaObject): DynamicMetaObject; override;
    method BindGetMember(binder: GetMemberBinder): DynamicMetaObject; override;
    method BindSetIndex(binder: SetIndexBinder; indexes: array of DynamicMetaObject; value: DynamicMetaObject): DynamicMetaObject; override;
    method BindSetMember(binder: SetMemberBinder; value: DynamicMetaObject): DynamicMetaObject; override;
    method BindInvokeMember(binder: InvokeMemberBinder; args: array of DynamicMetaObject): DynamicMetaObject; override;
    class method MakeObject(aValue: Expression): Expression;
  end;
  
implementation

constructor EcmaScriptDynamicMetaObject(aParameter: Expression; aOwner: EcmaScriptObject);
begin
  inherited constructor(aParameter, BindingRestrictions.GetTypeRestriction(aParameter, aOwner.GetType), aOwner);
  fOwner := aOwner;
end;

method EcmaScriptDynamicMetaObject.BindSetMember(binder: SetMemberBinder; value: DynamicMetaObject): DynamicMetaObject;
begin
  result := new DynamicMetaObject(LExpr.Call(MakeObject(Expression), fSetMemberMethod, [LExpr.Constant(binder.Name, typeof(string)), value.Expression]), 
    Restrictions);
end;

method EcmaScriptDynamicMetaObject.BindSetIndex(binder: SetIndexBinder; indexes: array of DynamicMetaObject; value: DynamicMetaObject): DynamicMetaObject;
begin
  if Length(indexes) <> 1 then exit binder.FallbackSetIndex(self, indexes, value);
  var lRestrict := BindingRestrictions.Combine(array of DynamicMetaObject([self, indexes[0]]));

  if &Type.GetTypeCode(indexes[0].RuntimeType) in [TypeCode.Byte, Typecode.Decimal, Typecode.Double, TypeCode.Int16, typeCode.Int32, TypeCode.Int64, TypeCode.SByte, Typecode.UInt16, TypeCode.UInt32, TypeCode.Single, TypeCode.UInt64] then 
    exit new DynamicMetaObject(LExpr.Call(MakeObject(Expression), fSetIndexMethod, [
      LEXpr.Convert(indexes[0].Expression, typeof(Integer)),
      LExpr.Convert(value.Expression, typeof(Object))]), lRestrict);

  result := new DynamicMetaObject(LExpr.Call(MakeObject(Expression), fSetMemberMethod, [
    LExpr.Convert(indexes[0].Expression, typeof(String)),
      LExpr.Convert(value.Expression, typeof(Object))]), lRestrict);  
end;

method EcmaScriptDynamicMetaObject.BindInvoke(binder: InvokeBinder; args: array of DynamicMetaObject): DynamicMetaObject;
begin
  var lRestrictions := BindingRestrictions.Combine(array of DynamicMetaObject(Microsoft.Scripting.Utils.ArrayUtils.Append(args, self)));
  

  var lPar1 := args[0];
  args := ArrayUtils.RemoveFirst(args);
  var lItems: array of Expression := new Expression[args.Length];
  for i: Integer := 0 to args.Length -1 do begin
    lItems[i] := args[i].Expression;
    if lItems[i].Type.IsValueType then
      lItems[i] := LExpr.Convert(lItems[i], typeof(ObjecT));
  end;
  
  result := new DynamicMetaObject(lExpr.Call(MakeObject(Expression), fInvokeExMethod,lPar1.Expression, LExpr.NewArrayInit(typeof(object), lItems)), lRestrictions);
end;

method EcmaScriptDynamicMetaObject.BindGetMember(binder: GetMemberBinder): DynamicMetaObject;
begin
  var lExpr := MakeObject(Expression);
  result := new DynamicMetaObject(LExpr.Call(lExpr, fGetMemberMethod, [LExpr.Constant(binder.Name, typeof(string))]), Restrictions);
end;

method EcmaScriptDynamicMetaObject.BindGetIndex(binder: GetIndexBinder; indexes: array of DynamicMetaObject): DynamicMetaObject;
begin
  if Length(indexes) <> 1 then exit binder.FallbackGetIndex(self, indexes);
  var lRestrict := BindingRestrictions.Combine(array of DynamicMetaObject([self, new DynamicMetaObject(indexes[0].Expression, BindingRestrictions.GetTypeRestriction(indexes[0].Expression, indexes[0].LimitType))]));


  if &Type.GetTypeCode(indexes[0].RuntimeType) in [TypeCode.Byte, Typecode.Decimal, Typecode.Double, TypeCode.Int16, typeCode.Int32, TypeCode.Int64, TypeCode.SByte, Typecode.UInt16, TypeCode.UInt32, TypeCode.Single, TypeCode.UInt64] then 
    exit new DynamicMetaObject(LExpr.Call(MakeObject(Expression), fGetIndexMethod, [LEXpr.Convert(Expression.Convert(indexes[0].Expression, indexes[0].LimitType), typeof(Integer))]), lRestrict);

  result := new DynamicMetaObject(LExpr.Call(MakeObject(Expression), fGetMemberMethod, [LExpr.Convert(Expression.Convert(indexes[0].Expression, indexes[0].LimitType), typeof(String))]), lRestrict);
end;

method EcmaScriptDynamicMetaObject.GetDynamicMemberNames: IEnumerable<String>;
begin
  result := fOwner.Names;
end;

method EcmaScriptDynamicMetaObject.BindCreateInstance(binder: CreateInstanceBinder; args: array of DynamicMetaObject): DynamicMetaObject;
begin
  var lItems: array of Expression := new Expression[args.Length];
  for i: Integer := 0 to args.Length -1 do begin
    lItems[i] := LExpr.Convert(args[i].Expression, typeof(Object));
  end;

  result := new DynamicMetaObject(lExpr.Call(MakeObject(Expression), fCreateMethod, LExpr.NewArrayInit(typeof(object), lItems)), 
    Restrictions);
end;

class constructor EcmaScriptDynamicMetaObject;
begin
  var lObj := typeof(EcmaScriptObject);
  fInvokeExMethod := lObj.GetMethod('CallEx');
  fSetMemberMethod := lObj.GetMethod('Put');
  fGetMemberMethod := lObj.GetMethod('Get');
  fSetIndexMethod := lObj.GetMethod('PutIndex');
  fGetIndexMethod := lObj.GetMethod('GetIndex');
  fInvokeMethod := lObj.GetMethod('Call');
  fCreateMethod := lObj.GetMethod('Construct');
end;

method EcmaScriptDynamicMetaObject.MakeObject(aValue: Expression): Expression;
begin
  if (aValue.Type = typeof(System.Object)) or (aValue.Type.IsInterface) then result := Expression.Convert(aValue, typeof(EcmaScriptObject)) else result := aValue;
end;

constructor EcmaScriptDynamicMetaObject(aParameter: Expression; aOwner: EcmaScriptObject; aValue: Object);
begin
  inherited constructor(aParameter, BindingRestrictions.GetTypeRestriction(aParameter, aValue.GetType), aValue);
  fOwner := aOwner;
end;


method EcmaScriptDynamicMetaObject.BindInvokeMember(binder: InvokeMemberBinder; args: array of DynamicMetaObject): DynamicMetaObject;
begin
  var lValue := fOwner.Get(binder.Name);
  var lMetaValue := new DynamicMetaObject(lExpr.Constant(lValue), Self.Restrictions, lValue);
  var lRestrictions := BindingRestrictions.Combine(ArrayUtils.Append(args, lMetaValue));
  var lItems: array of Expression := new Expression[args.Length];
  for i: Integer := 0 to args.Length -1 do begin
    lItems[i] := LExpr.Convert(args[i].Expression, typeof(Object));
  end;

  var lFunc := EcmaScriptFunctionObject(lValue);
  if lFunc <> nil then begin
    result := new DynamicMetaObject(LExpr.Call(lEXpr.Constant(lFunc), fInvokeExMethod, Expression, LExpr.NewArrayInit(typeof(object), lItems)), lRestrictions);  
  end else
    exit binder.FallbackInvoke(lMetaValue, args, nil);
end;

method EcmaScriptTypeHelperDynamicObject.BindInvokeMember(binder: InvokeMemberBinder; args: array of DynamicMetaObject): DynamicMetaObject;
begin
  var lValue := Get(Value, binder.Name);
  var lMetaValue := self;
  var lRestrictions := BindingRestrictions.Combine(ArrayUtils.Append(args, lMetaValue));
  var lItems: array of Expression := new Expression[args.Length];
  for i: Integer := 0 to args.Length -1 do begin
    lItems[i] := LExpr.Convert(args[i].Expression, typeof(Object));
  end;

  var lFunc := EcmaScriptFunctionObject(lValue);
  if lFunc <> nil then begin
    result := new DynamicMetaObject(LExpr.Call(lEXpr.Constant(lFunc), EcmaScriptDynamicMetaObject.fInvokeExMethod, 
      Expression, LExpr.NewArrayInit(typeof(object), lItems)), lRestrictions);  
  end else
    exit binder.FallbackInvoke(lMetaValue, args, nil);
end;
method EcmaScriptTypeHelperDynamicObject.BindSetMember(binder: SetMemberBinder; value: DynamicMetaObject): DynamicMetaObject;
begin
  result := new DynamicMetaObject(LExpr.Call(LExpr.Constant(self), typeof(EcmaScriptTypeHelperDynamicObject).GetMethod('Put'), [MakeObject(Expression), LExpr.Constant(binder.Name, typeof(string)), value.Expression]), 
    Restrictions);
end;

method EcmaScriptTypeHelperDynamicObject.BindSetIndex(binder: SetIndexBinder; indexes: array of DynamicMetaObject; value: DynamicMetaObject): DynamicMetaObject;
begin
  if Length(indexes) <> 1 then exit binder.FallbackSetIndex(self, indexes, value);
  var lRestrict := BindingRestrictions.Combine(array of DynamicMetaObject([self, indexes[0]]));

  if &Type.GetTypeCode(indexes[0].RuntimeType) in [TypeCode.Byte, Typecode.Decimal, Typecode.Double, TypeCode.Int16, typeCode.Int32, TypeCode.Int64, TypeCode.SByte, Typecode.UInt16, TypeCode.UInt32, TypeCode.Single, TypeCode.UInt64] then 
    exit new DynamicMetaObject(LExpr.Call(LExpr.Constant(self), typeof(EcmaScriptTypeHelperDynamicObject).GetMethod('PutIndex'), [
      MakeObject(Expression),
      LEXpr.Convert(indexes[0].Expression, typeof(Integer)),
      LExpr.Convert(value.Expression, typeof(Object))]), lRestrict);

  result := new DynamicMetaObject(LExpr.Call(LExpr.Constant(self), typeof(EcmaScriptTypeHelperDynamicObject).GetMethod('Put'), [
    MakeObject(Expression),
    LExpr.Convert(indexes[0].Expression, typeof(String)),
      LExpr.Convert(value.Expression, typeof(Object))]), lRestrict);  
end;

method EcmaScriptTypeHelperDynamicObject.BindGetMember(binder: GetMemberBinder): DynamicMetaObject;
begin
  result := new DynamicMetaObject(LExpr.Call(LExpr.Constant(self), typeof(EcmaScriptTypeHelperDynamicObject).GetMethod('Get'), [Expression, LExpr.Constant(binder.Name, typeof(string))]), Restrictions);
end;

method EcmaScriptTypeHelperDynamicObject.BindGetIndex(binder: GetIndexBinder; indexes: array of DynamicMetaObject): DynamicMetaObject;
begin
  if Length(indexes) <> 1 then exit binder.FallbackGetIndex(self, indexes);
  var lRestrict := BindingRestrictions.Combine(array of DynamicMetaObject([self, indexes[0]]));

  if &Type.GetTypeCode(indexes[0].RuntimeType) in [TypeCode.Byte, Typecode.Decimal, Typecode.Double, TypeCode.Int16, typeCode.Int32, TypeCode.Int64, TypeCode.SByte, Typecode.UInt16, TypeCode.UInt32, TypeCode.Single, TypeCode.UInt64] then 
    exit new DynamicMetaObject(LExpr.Call(LExpr.Constant(self), typeof(EcmaScriptTypeHelperDynamicObject).GetMethod('GetIndex'), [MakeObject(Expression), LEXpr.Convert(indexes[0].Expression, typeof(Integer))]), lRestrict);

  result := new DynamicMetaObject(LExpr.Call(LExpr.Constant(self), typeof(EcmaScriptTypeHelperDynamicObject).GetMethod('Get'), [MakeObject(Expression), LExpr.Convert(indexes[0].Expression, typeof(String))]), lRestrict);
end;

class method EcmaScriptTypeHelperDynamicObject.MakeObject(aValue: Expression): Expression;
begin
  if aValue.Type = typeof(Object) then exit aValue;
  result := Expression.Convert(aValue, typeof(Object));
end;

end.