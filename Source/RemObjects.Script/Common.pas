//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script;

interface

{$HIDE W27}

uses
  System.Collections.Generic,
  System.Reflection,
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


  ScriptRuntimeException = public class(ScriptException)
  private
    var fOriginal: Object; readonly;
  public
    class method SafeEcmaScriptToObject(o: Object): String;
    class method Wrap(arg: Object): Exception;
    class method Unwrap(arg: Object): Object;

    class var Method_Unwrap: MethodInfo := typeOf(ScriptRuntimeException).GetMethod('Unwrap'); readonly;
    class var Method_Wrap: MethodInfo := typeOf(ScriptRuntimeException).GetMethod('Wrap'); readonly;

    constructor(original: Object);

    property Original: Object read fOriginal;

    method ToString(): String; override;
  end;


  PositionPair = public record
  public
    constructor; empty;
    constructor (aStart, aEnd: Position);
    constructor (aStartPos, aStartRow, aStartCol, aEndPos, aEndRow, aEndCol: Integer; aFile: String);

    property Start: Position read new Position(StartPos, StartRow, StartCol, File);
    property &End: Position read new Position(EndPos, EndRow, EndCol, File);
    property IsValid: Boolean read (StartRow > 0) and not  String.IsNullOrEmpty(File);
    property StartRow: Integer;
    property StartCol: Integer;
    property StartPos: Integer;
    property EndRow: Integer;
    property EndCol: Integer;
    property EndPos: Integer;
    property File: String;
  end;
  Position = public record
  private
    fRow: Integer;
    fCol: Integer;
    fPos: Integer;
    fModule: String;
  public
    constructor(aPos, aRow, aCol: Integer; aModule: String);
    constructor; empty;
    property Row: Integer read fRow write fRow;
    property Col: Integer read fCol write fCol;
    property Pos: Integer read fPos write fPos;
    property Column: Integer read Col;
    property Line: Integer read Row;
    property &Module: String read fModule write fModule;
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
  StartPos := aStart.Pos;
  EndRow := aEnd.Row;
  EndCol := aEnd.Col;
  EndPos := aEnd.Pos;
  File := aStart.Module;
end;

constructor PositionPair(aStartPos, aStartRow, aStartCol, aEndPos, aEndRow, aEndCol: Integer; aFile: String);
begin
  StartRow := aStartRow;
  StartCol := aStartCol;
  StartPos := aStartPos;
  EndRow := aEndRow;
  EndCol := aEndCol;
  EndPos := aEndPos;
  File := aFile;
end;
constructor Position(aPos, aRow, aCol: Integer; aModule: String);
begin
  fRow := aRow;
  fCol := aCol;
  fPos := aPos;
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


{$REGION ScriptRuntimeException }
constructor ScriptRuntimeException(original: Object);
begin
  self.fOriginal := original;

  inherited constructor(ScriptRuntimeException.SafeEcmaScriptToObject(original));
end;


class method ScriptRuntimeException.SafeEcmaScriptToObject(o: Object): String;
begin
  if not assigned(o) then
    exit 'Error';

  try
    exit o.ToString();
  except
    exit 'Error';
  end;
end;


class method ScriptRuntimeException.Wrap(arg: Object): Exception;
begin
  var lResult: Exception := Exception(arg);
  if assigned(lResult) then
    exit lResult;

  exit new ScriptRuntimeException(arg);
end;


class method ScriptRuntimeException.Unwrap(arg: Object): Object;
begin
  if arg is ScriptRuntimeException then
    exit ScriptRuntimeException(arg).Original;

  exit arg;
end;


method ScriptRuntimeException.ToString(): String;
begin
  exit self.Message;
end;
{$ENDREGION}


method ScriptScope.ContainsVariable(name: String): Boolean;
begin
  exit Bag.ContainsKey(name);
end;

method ScriptScope.GetItems: IEnumerable<KeyValuePair<String, Object>>;
begin
  for each el in Bag do begin
    yield new KeyValuePair<String, Object>(el.Key, if el.Value.Value <> nil then el.Value:Value else RemObjects.Script.EcmaScript.Undefined.Instance);
  end;
end;

method ScriptScope.GetVariable<T>(name: String): T;
begin
  exit GetVariable(name) as T;
end;

method ScriptScope.GetVariable(name: String): Object;
begin
  var lWork := Bag[name];

  exit  (iif(assigned(lWork), lWork.Value, RemObjects.Script.EcmaScript.Undefined.Instance));
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
  result := Bag.ContainsKey(name);
  if result then value := GetVariable(name) else value := nil;
end;

method ScriptScope.TryGetVariable<T>(name: String; out value: T): Boolean;
begin
  result := Bag.ContainsKey(name);
  if result then value := GetVariable<T>(name) else value := default(T);
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