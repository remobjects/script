{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script;

interface

uses
  System.Collections,
  System.Collections.Generic,
  System.Collections.ObjectModel,
  System.Text,
	System.ComponentModel,
	System.Reflection,
  RemObjects.Script.EcmaScript;

type
	ScriptDebugEventArgs = public class(EventArgs)
	public
		constructor(aName: string; aSpan: PositionPair);
    constructor(aName: string; aSpan: PositionPair; ex: Exception);
		property Name: String; readonly;
    property Exception: Exception; readonly;
		property SourceFileName: String read SourceSpan.File;
		property SourceSpan: PositionPair; readonly;
	end;
	ScriptComponentException = public class(Exception);
  ScriptStatus = public enum(
		Stopped,
		StepInto, 
		StepOver,
		StepOut,
		Running,
		Stopping,
		Paused,
		Pausing);

  ScriptBaseLocalInfo = public abstract class
  private
  public
    property Internal: Boolean read; abstract;
		property Name: String read; abstract;
		property Value: Object read write; abstract; 
  end;

	ScriptLocalInfo = public class(ScriptBaseLocalInfo)
	private
		fInternal: Boolean;
		fName: String;
		fScope: IDictionary<Object,Object>;
		method set_Value(aValue: Object);
		method get_Value: Object;
	assembly
	  constructor(aScope: IDictionary<Object,Object>; aKey: string);
	public
    property Internal: Boolean read fInternal; override;
		property Name: String read fName; override;
		property Value: Object read get_Value write set_Value; override;
	end;

  ScriptScopeLocalInfo = public class(ScriptBaseLocalInfo)
  private
    fInst: EnvironmentRecord;
    fName: String;
    method set_Value(aValue: Object); override;
    method get_Value: Object; override;
  public
    constructor(aInst: EnvironmentRecord; aName: String);
    property Internal: Boolean read false; override;
    property Name: String read fName; override;
    property Value: Object read get_Value write set_Value; override;
  end;

  ScriptStackFrame = public class
  private
    fMethod: string;
    fFrame: EnvironmentRecord;
  assembly
    constructor(aMethod: String; aFrame: EnvironmentRecord);
  public
    property Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo> read nil;
    property &Method: string read fMethod;
  end;

  ScriptComponent = public abstract class(Component, IDebugSink)
	private
		fWorkThread: System.Threading.Thread;
		fRunResult: Object;
		fRunInThread: Boolean;
		fDebug: Boolean;
		//fSetup: ScriptRuntimeSetup;
		fTracing: boolean; volatile;
		fStatus: ScriptStatus;
    fStackItems: System.Collections.ObjectModel.ReadOnlyCollection<ScriptStackFrame>;
    fExceptionResult: Exception;
    fDebugLastPos: PositionPair;
    fLastFrame: Integer;
    method DebugLine(aFilename: string; aStartRow, aStartCol, aEndRow, aEndCol: Integer); 
    method EnterScope(aName: string; aContext: ExecutionContext); // enter method
    method ExitScope(aName: string; aContext: ExecutionContext); // exit method
    method CaughtException(e: Exception); // triggers on a CATCH before the js code itself
    method UncaughtException(e: Exception); // triggers when an exception escapes the main method
    method Debugger; 
    method Idle;
		method get_Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
		method set_Status(value: ScriptStatus);
		method set_RunInThread(value: Boolean);
    method CheckShouldPause;
  protected
    fStackList: List<ScriptStackFrame> := new List<ScriptStackFrame>;
		fGlobals: ScriptScope;
    fEntryStatus: ScriptStatus := ScriptStatus.Running;
		method IntRun: Object; abstract;
		method LoadLocals;
		method SetDebug(b: Boolean); virtual;
  public
		constructor;
		[Category('Script')]
		property Debug: Boolean read fDebug write SetDebug;
		[Category('Script')]
		property SourceFileName: String;
		[Category('Script')]
		property Source: String;
		[Category('Script')]
		property RunInThread: Boolean read fRunInThread write set_RunInThread;		

    [Browsable(false)]
    property CallStack: ReadOnlyCollection<ScriptStackFrame> read fStackItems;
		[Browsable(false)]
		property Globals: ScriptScope read; abstract;
		[Browsable(false)]
		property Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo> read get_Locals;

		method ExposeAssembly(asm: &Assembly); virtual;
    method ExposeType(&type: &Type; Name: String := nil); abstract;
		//method UseNamespace(ns: String); virtual;
		/// <summary>Clears all assemblies and exposed variables</summary>
		method Clear; abstract;

		/// <summary>starts the script,
		///	 this should be ran from another thread
		///	 if you want to use the debugger</summary>
		method Run; 
		property RunResult: Object read fRunResult;
    property RunException: Exception read fExceptionResult;
		
		/// <summary>Returns if there is a function by that name. After calling Run the global object
		///	 will contain a list of all functions, these can be called
		///	 by name. Note this only works after calling Run first.</summary>
		method HasFunction(aName: String): Boolean; abstract;
		/// <summary>Executes the given function by name. After calling Run the global object
		///	 will contain a list of all functions, these can be called
		///	 by name. Note this only works after calling Run first.</summary>
		method RunFunction(aName: String; params args: Array of object): Object; abstract;

		property Status: ScriptStatus read fStatus protected write set_Status;
		method StepInto;
		method StepOver;
		method StepOut;
		method Pause;
		method &Stop;

		event DebugFrameEnter: EventHandler<ScriptDebugEventArgs>;
    event DebugFrameExit: EventHandler<ScriptDebugEventArgs>;
    event DebugThreadExit: EventHandler<ScriptDebugEventArgs>;
    event DebugTracePoint: EventHandler<ScriptDebugEventArgs>;
    event DebugDebugger: EventHandler<ScriptDebugEventArgs>;
    event DebugException: EventHandler<ScriptDebugEventArgs>;
    event DebugExceptionUnwind: EventHandler<ScriptDebugEventArgs>;
		event StatusChanged: EventHandler;
    event NonThreadedIdle: EventHandler;
  end;

  ScriptAbortException = class (Exception) end;

  {$REGION Designtime Attributes}
  {$IFDEF DESIGN}
  [System.Drawing.ToolboxBitmap(typeof(RemObjects.Script.EcmaScriptComponent), 'Glyphs.EcmaScriptComponent.png')]
  {$ENDIF}
  {$ENDREGION}
	EcmaScriptComponent = public class(ScriptComponent)
	protected
    fCompiler: EcmaScriptCompiler;
    fScope: ScriptScope;
    fRoot: ExecutionContext;
		fGlobalObject: RemObjects.Script.EcmaScript.GlobalObject;
		method SetDebug(b: Boolean); override;
		method IntRun: Object; override;
	public
    method Clear; override;
    property Globals: ScriptScope read fScope; override;
		property GlobalObject: RemObjects.Script.EcmaScript.GlobalObject read fGlobalObject;
    method ExposeType(&type: &Type; Name: String); override;
		method HasFunction(aName: String): Boolean; override;
		method RunFunction(aName: String; params args: Array of object): Object; override;
	end;
  SyntaxErrorException = public class(Exception)
  private
  public
    constructor(aSource: string; aMessage: String; aSpan: PositionPair; anErrorCode: Int32); 
    property Message: string; readonly; reintroduce;
    property Source: string; readonly; reintroduce;
    property SourceFilename: string; readonly; reintroduce;
    property Span: PositionPair; readonly;
    property ErrorCode: Int32; readonly;
    
    method ToString: String; override;
  end;
implementation

constructor ScriptDebugEventArgs(aName: string; aSpan: PositionPair);
begin
	Name := aName;
  SourceSpan := aSpan;
end;

constructor ScriptDebugEventArgs(aName: string; aSpan: PositionPair; ex: Exception);
begin
  constructor(aname, aSpan);
  Exception := ex;
end;

constructor ScriptComponent;
begin
  inherited constructor;
  fStackItems := new ReadOnlyCollection<ScriptStackFrame>(fStackList);
	Clear;
end;


method ScriptComponent.ExposeAssembly(asm: &Assembly);
begin
  // TODO: Implement
end;

method ScriptComponent.SetDebug(b: Boolean);
begin
  if fDebug = b then exit;
	fDebug := b;
end;


method ScriptComponent.StepInto;
begin
  locking self do begin
    if STatus = ScriptStatus.Stopped then begin
      fEntryStatus := ScriptStatus.StepInto;
      fLastFrame := fStackList.Count;
      Run;
      exit;
    end;

    if Status in [ScriptStatus.Paused, ScriptStatus.Pausing, ScriptStatus.Running] then begin
      if Status = ScriptStatus.Paused then begin
        Status := ScriptStatus.StepInto;
{$HIDE PW3}
        fWorkThread.Resume;
{$SHOW PW3}
      end else 
        Status := ScriptStatus.StepInto;
      fLastFrame := fStackList.Count;
    end;
  end;
end;

method ScriptComponent.StepOver;
begin
  locking self do begin
    if STatus = ScriptStatus.Stopped then begin
      fEntryStatus := ScriptStatus.StepInto;
      fLastFrame := fStackList.Count;
      Run;
      exit;
    end;
    if Status in [ScriptStatus.Paused, ScriptStatus.Pausing, ScriptStatus.Running] then begin
      if Status = ScriptStatus.Paused then begin
        Status := ScriptStatus.StepOver;
{$HIDE PW3}
        fWorkThread.Resume;
{$SHOW PW3}
      end else 
      Status := ScriptStatus.StepOver;
      fLastFrame := fStackList.Count;
    end;
  end;
end;

method ScriptComponent.StepOut;
begin
  locking self do begin
    if STatus = ScriptStatus.Stopped then begin
      fEntryStatus := ScriptStatus.StepInto;
      fLastFrame := fStackList.Count;
      Run;
      exit;
    end;
    if Status in [ScriptStatus.Paused, ScriptStatus.Pausing, ScriptStatus.Running] then begin
      if Status = ScriptStatus.Paused then begin
        Status := ScriptStatus.StepOut;
{$HIDE PW3}
        fWorkThread.Resume;
{$SHOW PW3}
      end else 
        Status := ScriptStatus.StepOut;
      fLastFrame := fStackList.Count;
    end;
  end;
end;

method ScriptComponent.Stop;
begin
	locking self do begin
		case Status of
{$HIDE PW3}
			ScriptStatus.Paused: begin Status := ScriptStatus.Stopping; fWorkThread.Resume; end;
{$SHOW PW3}
			ScriptStatus.Stopping,
			ScriptStatus.Pausing, 
			ScriptStatus.Running, 
			ScriptStatus.StepInto,
			ScriptStatus.StepOut, 
			ScriptStatus.StepOver:  Status := ScriptStatus.Stopping;
			ScriptStatus.Stopped: ;
		end; // case
	end;
end;

method ScriptComponent.set_RunInThread(value: Boolean);
begin
  if Status = ScriptStatus.Stopped then 
	  fRunInThread := value 
	else
	  raise new ScriptComponentException(Properties.Resources.eRunInThreadCannotBeModifiedWhenScriptIsRunning);
end;

method ScriptComponent.set_Status(value: ScriptStatus);
begin
	fStatus := value;
	if assigned(StatusChanged) then StatusChanged(self, EventArgs.Empty);
end;


method ScriptComponent.LoadLocals;
begin
   // TODO: Impl
	//fREAo
end;

method ScriptComponent.get_Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
begin
	LoadLocals;
	exit new ReadOnlyCollection<ScriptBaseLocalInfo>([]);
end;


method ScriptComponent.Run;
begin
	if fRunInThread then begin
    locking self do begin
	  	if Status in [ScriptStatus.StepInto, ScriptStatus.StepOut, ScriptStatus.StepOver] then begin
		  	Status := ScriptStatus.Running;
			  exit;
  		end else if Status = ScriptStatus.Paused  then begin
		    Status := ScriptStatus.Running;
{$HIDE PW3}
	  		fWorkThread.Resume;
{$SHOW PW3}
		  	exit;
  		end else if Status <> ScriptStatus.Stopped then raise new ScriptComponentException(RemObjects.Script.Properties.Resources.eAlreadyRunning);
			Status := ScriptStatus.Running;
		end;
      fExceptionResult := nil;
		  fWorkThread := new System.Threading.Thread(method begin
        try
				  fRunResult := IntRun;
        except
          on e: Exception do
            fExceptionResult := e;
				end;
			end);
			try
			  fWorkThread.Start;
			except
				Status := ScriptStatus.Stopped;
				raise;
			end;
	end else begin
    if Status = ScriptStatus.Paused then begin Status := ScriptStatus.Running; exit; end;
		if Status <> ScriptStatus.Stopped then raise new ScriptComponentException(RemObjects.Script.Properties.Resources.eAlreadyRunning);
    fRunResult := IntRun;
	end;

end;

method ScriptComponent.Pause;
begin
  locking self do begin
  	if Status = ScriptStatus.Running then begin
		  Status := ScriptStatus.Pausing;
  	end;
	end;
end;

method ScriptComponent.Idle;
begin
  if Status = ScriptStatus.Pausing then
    Status := ScriptStatus.Paused;
  while Status = ScriptStatus.Paused do begin
    if NonThreadedIdle <> nil then NonThreadedIdle(self, EventArgs.Empty) else
      System.Threading.Thread.Sleep(10);
  end;
end;


method ScriptComponent.DebugLine(aFilename: string; aStartRow, aStartCol, aEndRow, aEndCol: Integer);
begin
  fDebugLastPos := new PositionPair(aStartRow, aStartCol, aEndRow, aendCol, aFilename);
  if Status = ScriptStatus.Stopping then raise new ScriptAbortException();
  if  fTracing then exit;
  fTracing := true;
  try
    if DebugTracePoint <> nil then DebugTracePoint(self, new ScriptDebugEventArgs(fStackList[fStackItems.Count-1].Method, new PositionPair(aSTartRow, aStartCol, aEndRow, aEndCol, aFilename)));
    if (Status = ScriptStatus.StepInto) or 
          ((Status = ScriptStatus.StepOver) and (fLastFrame = fStackList.Count)) then Status := ScriptStatus.Pausing;
    CheckShouldPause;
  finally
    fTracing := false;
  end;
end;

method ScriptComponent.EnterScope(aName: string; aContext: ExecutionContext);
begin
  fStackList.Add(new ScriptStackFrame(aName, aContext.LexicalScope));
  if Status = ScriptStatus.Stopping then raise new ScriptAbortException();
  if  fTracing then exit;
  fTracing := true;
  try
    if Status = ScriptStatus.StepInto then Status := ScriptStatus.Pausing;
    CheckShouldPause;
  finally
    fTracing := false;
  end;
end;

method ScriptComponent.ExitScope(aName: string; aContext: ExecutionContext);
begin
  fStackList.RemoveAt(fStackList.Count-1);
  if  fTracing then exit;
  fTracing := true;
  try
    if (status = ScriptStatus.StepOut) and (fLastFrame < fStackList.Count) then Status := ScriptStatus.Pausing;
    CheckShouldPause;
  finally
    fTracing := false;
  end;
end;

method ScriptComponent.CaughtException(e: Exception);
begin
  if  fTracing then exit;
  fTracing := true;
  try
    if DebugException <> nil then DebugException(self, new ScriptDebugEventArgs(fStackList[fStackList.Count-1].Method, fDebugLastPos));
    CheckShouldPause;
  finally
    fTracing := false;
  end;
end;

method ScriptComponent.UncaughtException(e: Exception);
begin
  if  fTracing then exit;
  fTracing := true;
  try
    if DebugExceptionUnwind <> nil then DebugExceptionUnwind(self, new ScriptDebugEventArgs(nil, fDebugLastPos));
  finally
    fTracing := false;
  end;
end;

method ScriptComponent.Debugger;
begin
  if  fTracing then exit;
  fTracing := true;
  try
    if DebugDebugger <> nil then DebugDebugger(self, new ScriptDebugEventArgs(fStackList[fStackList.Count-1].Method, fDebugLastPos));
    CheckShouldPause;
  finally
    fTracing := false;
  end;
end;

method ScriptComponent.CheckShouldPause;
begin
  if Status in [ScriptStatus.Paused, ScriptStatus.Pausing] then begin
    if fRunInThread then begin
      Status := ScriptStatus.Paused;
{$HIDE PW3}
      fWorkThread.Suspend;
{$SHOW PW3}
    end else Idle;
  end;
end;

method EcmaScriptComponent.HasFunction(aName: String): Boolean;
begin
	exit fGlobalObject.Get(aName) is RemObjects.Script.EcmaScript.EcmaScriptFunctionObject;
end;

method EcmaScriptComponent.RunFunction(aName: String; params args: Array of object): Object;
begin
	var lItem := fGlobalObject.Get(aName) as RemObjects.Script.EcmaScript.EcmaScriptFunctionObject;
	if lItem = nil then raise new ScriptComponentException(String.Format(RemObjects.Script.Properties.Resources.eNoSuchFunction, aName));
  exit lItem.Call(fRoot, Args);
end;

method EcmaScriptComponent.IntRun: Object;
begin
  Status := fEntryStatus; 
  fEntryStatus := ScriptStatus.Running;
  try
	  if String.IsNullOrEmpty(SourceFileName) then SourceFileName := 'main.js';
	  if Source = nil then Source := '';
    
    var lCallback := fCompiler.Parse(SourceFileName, Source);
    result := lCallback(fRoot, fGlobalObject, []);
  except
    on e: ScriptAbortException do
      exit Undefined.Instance;
  finally
    Status := ScriptStatus.Stopped;
  end;
end;


method EcmaScriptComponent.ExposeType(&type: &Type; Name: String);
begin
  // TODO: impl
end;

method EcmaScriptComponent.SetDebug(b: Boolean);
begin
  if b <> inherited Debug then begin
    inherited SEtDebug(b);
    Clear;
  end;
end;

method EcmaScriptComponent.Clear;
begin
  fGlobalObject := new GlobalObject();
  fScope := new ScriptScope(nil, fGlobalObject);
  if Debug then
    fGlobalObject.Debug := self;
  var lRoot := new ObjectEnvironmentRecord(fScope, fGlobalObject, false);

  froot := new ExecutionContext(lRoot);
  fCompiler := new EcmaScriptCompiler(new EcmaScriptCompilerOptions(EmitDebugCalls := Debug, GlobalObject := fGlobalObject, Context := fRoot.LexicalScope));
  fGlobalObject.Parser := fCompiler;
end;

method ScriptLocalInfo.get_Value: Object;
begin
  if not fScope.TryGetValue(fName, out Result) then 
    result := Undefined.Instance;
end;

method ScriptLocalInfo.set_Value(aValue: Object);
begin
  fScope.Item[fName] := aValue;
end;


constructor ScriptLocalInfo(aScope: IDictionary<Object,Object>; aKey: string);
begin
	fScope := aScope;
	fName := aKey;
  if fName.Contains('$') then fInternal := true;
end;



constructor ScriptStackFrame(aMethod: String; aFrame: EnvironmentRecord);
begin
  fMethod := aMethod;
  fFrame := aFrame;
end;

method ScriptScopeLocalInfo.get_Value: Object;
begin
  exit fInst.GetBindingValue(fName, false);
end;

method ScriptScopeLocalInfo.set_Value(aValue: Object);
begin
  fInst.SetMutableBinding(fName, AValue, false);
end;

constructor ScriptScopeLocalInfo(aInst: EnvironmentRecord; aName: String);
begin
  fName := aName;
  fInst := aInst;
end;

constructor SyntaxErrorException(aSource: string; aMessage: String; aSpan: PositionPair; anErrorCode: Int32);
begin
  inherited constructor(String.Format('{0}({1}, {2}): {4} {3}',
    aSource, aSpan.StartRow, aSpan.StartCol, aMessage,
    'error'));
  Source := aSource;
  Span := aSpan;
  ErrorCode := anErrorCode;
  Message := aMessage;
end;

method SyntaxErrorException.ToString: String;
begin
  exit inherited Message;
end;


end.

