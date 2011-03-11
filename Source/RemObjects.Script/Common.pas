{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script;

interface

uses
  System.Reflection,
  System.Collections.Generic,
  System.Text;

type
  ParserMessage = public abstract class 
  private
    fPosition: Position;
  public
    constructor(aPosition: Position);
    property IsError: Boolean read; abstract;
    property Position: Position read fPosition;
    method IntToString: String; abstract;
    method ToString: String; override;
    property Code: Integer read; abstract;
  end;
  ScriptException = public class(Exception);
  //ScriptException = 
  ScriptRuntimeException = public class(ScriptException)
  private
    fOriginal: RemObjects.Script.EcmaScript.EcmaScriptObject;
  public
    class method SafeEcmaScriptToObject(o: RemObjects.Script.EcmaScript.EcmaScriptObject): string;
    class method Wrap(arg: Object): Exception;
    class method Unwrap(arg: Object): Object;

    class var Method_Unwrap: MethodInfo := typeof(ScriptRuntimeException).GetMethod('Unwrap'); readonly;
    class var Method_Wrap: MethodInfo := typeof(ScriptRuntimeException).GetMethod('Wrap'); readonly;

    constructor(aOriginal: RemObjects.Script.EcmaScript.EcmaScriptObject);
    property Original: RemObjects.Script.EcmaScript.EcmaScriptObject read fOriginal;
    method ToString: String; override;
  end;

  PositionPair = public record
  public
    constructor; empty;
    constructor (aStart, aEnd: Position);
    constructor (aStartRow, aStartCol, aEndRow, aEndCol: Integer; aFile: String);

    property Start: Position read new Position(StartRow, STartCol, File);
    property &End: Position read new Position(EndRow, EndCol, File);
    property IsValid: Boolean read (StartRow > 0) and not  string.IsNullOrEmpty(File);
    property StartRow: Integer;
    property StartCol: Integer;
    property EndRow: Integer;
    property EndCol: Integer;
    property File: String;
  end;
  Position = public record
  private
    fRow: Integer;
    fCol: Integer;
    fModule: String;
  public
    constructor(aRow, aCol: Integer; aModule: String);
    constructor; empty;
    property Row: Integer read fRow write fRow;
    property Col: Integer read fCol write fCol;
    property Column: Integer read Col;
    property Line: Integer read Row;
    property &Module: string read fModule write fModule;
  end;
  ScriptScope = public class(RemObjects.Script.EcmaScript.DeclarativeEnvironmentRecord)
  private
  public
    method ContainsVariable(name: String): Boolean;
    method GetItems: IEnumerable<KeyValuePair<String, Object>>; iterator;
    method GetVariable<T>(name: String): T;
    method GetVariable(name: String): Object;
    method GetVariableNames: IEnumerable<String>;
    method RemoveVariable(name: String): Boolean;
    method SetVariable(name: String; value: Object);
    method TryGetVariable(name: String; out value: Object): Boolean;
    method TryGetVariable<T>(name: String; out value: T): Boolean;

    method SetMutableBinding(aName: String; aValue: Object; aStrict: Boolean); override;

    method TryWrap(aValue: Object): Object; virtual; 
  end;

implementation

constructor PositionPair(aStart, aEnd: Position);
begin
  StartRow := aStart.Row;
  StartCol := aStart.Col;
  EndRow := aEnd.Row;
  EndCol := aEnd.Col;
  File := aStart.Module;
end;

constructor PositionPair(aStartRow, aStartCol, aEndRow, aEndCol: Integer; aFile: String);
begin
  StartRow := aStartRow;
  StartCol := aStartCol;
  EndRow := aEndRow;
  EndCol := aEndCol;
  File := aFile;
end;
constructor Position(aRow, aCol: Integer; aModule: String);
begin
  fRow := aRow;
  fCol := aCol;
  fModule := aModule;
end;
constructor ParserMessage(aPosition: Position);
begin
  fPosition := aPosition;
end;

method ParserMessage.ToString: String;
begin
  result := String.Format('{0}({1}:{2}): {3}', fPosition.Module, fPosition.Row, fPosition.Col, IntToString);
end;
(*
constructor TypeWrapper(aType: &Type; aBinder: RemObjects.Script.EcmaScript.EcmaScriptLanguageBinder);
begin
  fType := aType;
  fBinder := aBinder
end;

method TypeWrapper.GetMetaObject(parameter: Expression): DynamicMetaObject;
begin
  result := new TypeWrapperMetaObject(parameter, self);
end;

class operator TypeWrapper.Implicit(aType: TypeWrapper) : &Type;
begin
  result := aType:fType;
end;


constructor TypeWrapperMetaObject(parameter: Expression; aInstance: TypeWrapper);
begin
  inherited constructor(parameter, BindingRestrictions.GetTypeRestriction(parameter, aInstance.GetType), aInstance);
  fInstance := aInstance;
end;

method TypeWrapperMetaObject.BindCreateInstance(binder: CreateInstanceBinder; args: array of DynamicMetaObject): DynamicMetaObject;
begin
  var lOverloads: List<MethodBase> := new List<MethodBase>;
  for each el in fInstance.Type.GetConstructors(BindingFlags.Public or bindingFlags.Instance) do begin
    lOverloads.Add(ConstructorInfo(el));
  end;

  var lResolver := new NewOverloadResolver(fInstance.Binder, args);
  result := fInstance.Binder.CallMethod(lResolver, lOverloads);
  if result.Expression.Type = typeof(Void) then
    result := new DynamicMetaObject(
      LExpr.Block(result.Expression, LExpr.Constant(RemObjects.Script.EcmaScript.Undefined.Instance))
      
      , BindingRestrictions.Combine([self, result]))
  else
    result := new DynamicMetaObject(result.Expression,BindingRestrictions.Combine([self, result]));
end;

method TypeWrapperMetaObject.BindGetIndex(binder: GetIndexBinder; indexes: array of DynamicMetaObject): DynamicMetaObject;
begin
  var lAttr := array of System.ComponentModel.DefaultPropertyAttribute(fInstance.Type.GetCustomAttributes(typeof(System.ComponentModel.DefaultPropertyAttribute), true));
  if Length(lAttr) = 0 then raise new ArgumentException(RemObjects.Script.Properties.Resources.eNoSuchFunction);
  result := BindCall('get_'+lAttr[0].Name, false, indexes);
end;

method TypeWrapperMetaObject.BindGetMember(binder: GetMemberBinder): DynamicMetaObject;
begin
  if Length(fInstance.Type.GetProperties(BindingFlags.Static or BindingFlags.Public) ) > 0 then
    result := BindCall('get_'+binder.Name, binder.IgnoreCase, [])
  else begin
		var res := fInstance.Binder.GetMember(MemberRequestKind.Get, fInstance.Type, binder.Name);
    
    result := new DynamicMetaObject(Expression.Constant(res), BindingRestrictions.Empty)
	end;
  if assigned(result) and result.Expression.Type.IsValueType then 
    result := new DynamicMetaObject(Expression.Convert(result.Expression, typeof(Object)), result.Restrictions);
end;

method TypeWrapperMetaObject.BindInvokeMember(binder: InvokeMemberBinder; args: array of DynamicMetaObject): DynamicMetaObject;
begin
  result := BindCall(binder.Name, binder.IgnoreCase, args);
end;

method TypeWrapperMetaObject.BindSetIndex(binder: SetIndexBinder; indexes: array of DynamicMetaObject; value: DynamicMetaObject): DynamicMetaObject;
begin
  var lAttr := array of System.ComponentModel.DefaultPropertyAttribute(fInstance.Type.GetCustomAttributes(typeof(System.ComponentModel.DefaultPropertyAttribute), true));
  if Length(lAttr) = 0 then raise new ArgumentException(RemObjects.Script.Properties.Resources.eNoSuchFunction);
  result := BindCall( 'set_'+lATtr[0].Name,  Microsoft.Scripting.Utils.ArrayUtils.Append(indexes, value));
end;

method TypeWrapperMetaObject.GetDynamicMemberNames: IEnumerable<String>;
begin
  for each el in fInstance.Type.GetMembers(BindingFlags.Public or BindingFlags.Static) do
    yield el.Name;
end;

method TypeWrapperMetaObject.BindCall(name: String; aIgnoreCase: Boolean; indexes: array of DynamicMetaObject): DynamicMetaObject;
begin
  var lOverloads: List<MethodBase> := new List<MethodBase>;
  for each el in fInstance.Type.GetMethods(BindingFlags.Public or bindingFlags.Static or BindingFlags.InvokeMethod) do begin
    if aIgnoreCase then begin
      if String.Compare(name, el.Name, StringComparison.InvariantCultureIgnoreCase) = 0 then
      lOverloads.Add(MethodInfo(el))
    end else if String.Compare(name, el.Name, StringComparison.InvariantCulture) = 0 then
      lOverloads.Add(MethodInfo(el));
  end;

  if lOverloads = nil then begin
    exit new DynamicMetaObject(
      LExpr.Block(LExpr.Throw(LExpr.New(typeof(Exception).GetConstructor([typeof(String)]), LExpr.Constant('Cannot find member by that name: '+name))), LExpr.Constant(RemObjects.Script.EcmaScript.Undefined.Instance))
      
      , BindingRestrictions.Combine([self, result]))

  end;

  var lResolver := new NewOverloadResolver(fInstance.Binder, indexes);
  result := fInstance.Binder.CallMethod(lResolver, lOverloads);
  if result.Expression.Type = typeof(Void) then
    result := new DynamicMetaObject(
      LExpr.Block(result.Expression, LExpr.Constant(RemObjects.Script.EcmaScript.Undefined.Instance))
      
      , BindingRestrictions.Combine([self, result]))
  else
    result := new DynamicMetaObject(result.Expression, BindingRestrictions.Combine([self, result]));
end;

method TypeWrapperMetaObject.BindSetMember(binder: SetMemberBinder; value: DynamicMetaObject): DynamicMetaObject;
begin
  result := BindCall('set_'+binder.Name, binder.IgnoreCase, [value]);
end;
*)
class method ScriptRuntimeException.SafeEcmaScriptToObject(o: RemObjects.Script.EcmaScript.EcmaScriptObject): string;
begin
  try
    exit o.ToString;
  except
    exit 'Error';
  end;
end;

constructor ScriptRuntimeException(aOriginal: RemObjects.Script.EcmaScript.EcmaScriptObject);
begin
  inherited constructor(SafeEcmaSCriptToObject(aOriginal));
  fOriginal := aOriginal;
end;

method ScriptRuntimeException.ToString: String;
begin
  exit Message;
end;

class method ScriptRuntimeException.Wrap(arg: Object): Exception;
begin
  result := Exception(arg);
  if assigned(result) then exit;

  var ln := RemObjects.Script.EcmaScript.EcmaScriptObject(arg);
  if ln <> nil then exit new ScriptRuntimeException(ln);
  
  if arg = nil then arg := 'empty exception';
  exit new Exception(arg.ToString);
end;

class method ScriptRuntimeException.Unwrap(arg: Object): Object;
begin
  if arg is ScriptRuntimeException then begin
    exit ScriptRuntimeException(arg).Original;
  end;
  exit arg;
end;

method ScriptScope.ContainsVariable(name: String): Boolean;
begin
  exit Bag.ContainsKey(name);
end;

method ScriptScope.GetItems: IEnumerable<KeyValuePair<String, Object>>;
begin
  for each el in Bag do begin
    yield new KeyValuePair<string, object>(el.Key, if el.Value.Value = nil then el.Value.Value else el.Value);
  end;
end;

method ScriptScope.GetVariable<T>(name: String): T;
begin
  exit GetVariable(Name) as T;
end;

method ScriptScope.GetVariable(name: String): Object;
begin
  exit Bag[name];
end;

method ScriptScope.GetVariableNames: IEnumerable<String>;
begin
  exit Bag.Keys;
end;

method ScriptScope.RemoveVariable(name: String): Boolean;
begin
  exit inherited DeleteBinding(name);
end;

method ScriptScope.SetVariable(name: String; value: Object);
begin
  if not Bag.ContainsKey(name) then  CreateMutableBinding(name, true);
  SetMutableBinding(name, value, true);
end;

method ScriptScope.TryGetVariable(name: String; out value: Object): Boolean;
begin
  result := bag.ContainsKey(name);
  if result then Value := GetVariable(Name) else Value := nil;
end;

method ScriptScope.TryGetVariable<T>(name: String; out value: T): Boolean;
begin
  result := bag.ContainsKey(name);
  if result then Value := GetVariable<T>(Name) else Value := default(T);
end;

method ScriptScope.SetMutableBinding(aName: String; aValue: Object; aStrict: Boolean);
begin
  inherited SetMutableBinding(aName, TryWrap(aValue), aStrict);
end;

method ScriptScope.TryWrap(aValue: Object): Object;
begin
  exit aValue;
end;

end.