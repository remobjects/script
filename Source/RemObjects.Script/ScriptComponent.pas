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
  Microsoft.Scripting.Utils,
	Microsoft.Scripting,
	Microsoft.Scripting.Hosting,
	Microsoft.Scripting.Debugging, 
  RemObjects.Script.EcmaScript;

type
	ScriptDebugEventArgs = public class(EventArgs)
	private
	public
		constructor(aName, aSourceFileName: string; aSpan: SourceSpan);
    constructor(aName, aSourceFileName: string; aSpan: SourceSpan; ex: Exception);
		property Name: String; readonly;
    property Exception: Exception; readonly;
		property SourceFileName: String; readonly;
		property SourceSpan: SourceSpan; readonly;
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
    fInst: IScopeObject;
    fName: String;
    method set_Value(aValue: Object); override;
    method get_Value: Object; override;
  public
    constructor(aInst: IScopeObject; aName: String);
    property Internal: Boolean read false; override;
    property Name: String read fName; override;
    property Value: Object read get_Value write set_Value; override;
  end;

  ScriptScopeParamInfo = public class(ScriptBaseLocalInfo)
  private
    fInst: EcmaScriptScope;
    fName: string;
    method set_Value(aValue: Object); override;
    method get_Value: Object; override;
  public
    constructor(aInst: EcmaScriptScope; aName: String);
    property Internal: Boolean read false; override;
    property Name: string read fName; override;
    property Value: Object read get_Value write set_Value; override;
  end;

  ScriptStackFrame = public class
  private
		fLocals: List<ScriptBaseLocalInfo>;
		fReadonlyLocals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
		fScopeCallback: Func<IDictionary<Object,Object>>;
		fScope: IDictionary<Object,Object>;
    fMethod: String;
    method get_Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
    method LoadLocals;
    method set_ScopeCallback(value: Func<IDictionary<Object,Object>>);
  assembly
    property ScopeCallback: Func<IDictionary<Object,Object>> read fScopeCallback write set_ScopeCallback;
    constructor(aMethod: String);
  public
    property Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo> read get_Locals;
    property &Method: string read fMethod;
  end;

  TraceHelper nested in ScriptComponent = public class(ITraceCallback) // avoid the dependancy on the scripting libraries
  private
    fOwner: ScriptComponent;
  public
    constructor (aOwner: ScriptComponent);
    method OnTraceEvent(kind: TraceEventKind; name, sourceFileName: String; sourceSpan: SourceSpan; scopeCallback: Func<IDictionary<Object,Object>>; payload, customPayload: Object);
  end;

  ScriptComponent = public abstract class(Component)
	private
		fWorkThread: System.Threading.Thread;
		fRunResult: Object;
		fRunInThread: Boolean;
		fDebug: Boolean;
		fSetup: ScriptRuntimeSetup;
		fTracing: boolean; volatile;
		fLocals: List<ScriptBaseLocalInfo>;
		fReadonlyLocals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
		fScopeCallback: Func<IDictionary<Object,Object>>;
		fScope: IDictionary<Object,Object>;
		fStatus: ScriptStatus;
    fLastFrame: Integer;
    fStackItems: System.Collections.ObjectModel.ReadOnlyCollection<ScriptStackFrame>;
    fTraceHelper: TraceHelper;
    fExceptionResult: Exception;
    method Idle;
		method get_Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
		method set_Status(value: ScriptStatus);
		method set_RunInThread(value: Boolean);
		method LoadEngine;
  protected
    fStackList: List<ScriptStackFrame> := new List<ScriptStackFrame>;
		fRuntime: ScriptRuntime;
		fGlobals: ScriptScope;
		fEngine: ScriptEngine;
    fEntryStatus: ScriptStatus := ScriptStatus.Running;
    property TraceHelperInstance: TraceHelper read fTraceHelper;
		method IntRun: Object; abstract;
		method LoadLocals;
		method GetRuntimeSetup: ScriptRuntimeSetup;  abstract;
		method GetEngine: ScriptEngine; abstract;
		method SetDebug(b: Boolean); virtual;
		method CreateTrace: ITracePipeline; abstract;
		method OnTraceEvent(kind: TraceEventKind; name, aSourceFileName: String; sourceSpan: SourceSpan; scopeCallback: Func<IDictionary<Object,Object>>; payload, customPayload: Object);
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
		property Globals: ScriptScope read fGlobals;
		[Browsable(false)]
		property Runtime: ScriptRuntime read fRuntime;
		[Browsable(false)]
		property Engine: ScriptEngine read fEngine;
		[Browsable(false)]
		property Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo> read get_Locals;

		method ExposeAssembly(asm: &Assembly); virtual;
    method ExposeType(&type: &Type; Name: String := nil); abstract;
		//method UseNamespace(ns: String); virtual;
		/// <summary>Clears all assemblies and exposed variables</summary>
		method Clear; virtual;

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
  private
    fBinding: EcmaScriptLanguageBinder;
    fListener: Listener;
	protected
		fGlobalObject: RemObjects.Script.EcmaScript.GlobalObject;
		method CreateTrace: ITracePipeline;  OVERRIDE;
		method SetDebug(b: Boolean); override;
	  method GetEngine: ScriptEngine; override;
		method GetRuntimeSetup: ScriptRuntimeSetup; override;
		method IntRun: Object; override;
	public
		property GlobalObject: RemObjects.Script.EcmaScript.GlobalObject read fGlobalObject;
    method ExposeType(&type: &Type; Name: String); override;
		method HasFunction(aName: String): Boolean; override;
		method RunFunction(aName: String; params args: Array of object): Object; override;
	end;
  Listener nested in EcmaScriptComponent = private class(ErrorListener) 
  private
    fOWner: EcmaScriptComponent;
  public
    constructor(aOwner: EcmaScriptComponent);
    method ErrorReported(source: ScriptSource; message: String; span: SourceSpan; errorCode: Int32; severity: Severity); override;
  end;
  SyntaxErrorException = public class(Exception)
  private
  public
    constructor(aSource: ScriptSource; aMessage: String; aSpan: SourceSpan; anErrorCode: Int32; aSeverity: Severity); 
    constructor(aSource: string; aMessage: String; aSpan: SourceSpan; anErrorCode: Int32; aSeverity: Severity); 
    property Message: string; readonly; reintroduce;
    property Source: ScriptSource; readonly; reintroduce;
    property SourceFilename: string; readonly; reintroduce;
    property Span: SourceSpan; readonly;
    property ErrorCode: Int32; readonly;
    property Severity: Severity;readonly;

    method ToString: String; override;
  end;
implementation

constructor ScriptDebugEventArgs(aName, aSourceFileName: string; aSpan: SourceSpan);
begin
	Name := aName;
  SourceFileName := aSourceFileName;
  SourceSpan := aSpan;
end;

constructor ScriptDebugEventArgs(aName, aSourceFileName: string; aSpan: SourceSpan; ex: Exception);
begin
  constructor(aname, aSourceFileName, aSpan);
  Exception := ex;
end;

constructor ScriptComponent;
begin
  inherited constructor;
  fTraceHelper := new TraceHelper(self);
  fStackItems := new ReadOnlyCollection<ScriptStackFrame>(fStackList);
	fSetup := GetRuntimeSetup;
	LoadEngine;
end;


method ScriptComponent.ExposeAssembly(asm: &Assembly);
begin
  fRuntime.LoadAssembly(asm);
end;

method ScriptComponent.Clear;
begin
	LoadEngine;
end;

method ScriptComponent.LoadEngine;
begin
  fRuntime := new ScriptRuntime(fSetup);
	fGlobals := fRuntime.Globals;
	fEngine := GetEngine;
end;

method ScriptComponent.SetDebug(b: Boolean);
begin
  if fDebug = b then exit;
	fDebug := b;
	fSetup := GetRuntimeSetup;
  fSetup.DebugMode := b;
  LoadEngine;
end;

method ScriptComponent.OnTraceEvent(kind: TraceEventKind; name, aSourceFileName: String; sourceSpan: SourceSpan; scopeCallback: Func<IDictionary<Object,Object>>; payload, customPayload: Object);
begin
  if Status = ScriptStatus.Stopping then begin 
    if kind in [TraceEventKind.TracePoint, TraceEventKind.FrameEnter] then
      raise new ScriptAbortException()
    else if kind =TraceEventKind.ThreadExit then 
      DebugThreadExit:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan));
    exit;
  end;
	if fTracing then exit;
	fScopeCallback := scopeCallback;
	fTracing := true;
	try
    if name:Contains('$') then name := name.Substring(0, name.LastIndexOf('$')); // drop the extension the DLR adds
		case kind of 
			TraceEventKind.Exception: 
        begin
          var lFrame := fStackList[fStackList.Count-1];
          lFrame.ScopeCallback := fScopeCallback;
          DebugException:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan, payload as Exception));
        end;
			TraceEventKind.ExceptionUnwind: DebugExceptionUnwind:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan, payload as Exception));
			TraceEventKind.FrameEnter: 
        begin
          var lFrame := new ScriptStackFrame(name);
          lFrame.ScopeCallback := fScopeCallback;
          fStackList.Add(lFrame);
          DebugFrameEnter:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan));
          if Status = ScriptStatus.StepInto then Status := ScriptStatus.Pausing;

          DebugTracePoint:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan));
          // entering a frame is a trace point of it's own
        end;
			TraceEventKind.FrameExit: begin
        DebugFrameExit:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan));
        var lFrame := fStackList[fStackList.Count-1];
        lFrame.ScopeCallback := nil;
        fStackList.RemoveAt(fStackList.Count-1);
        if (status = ScriptStatus.StepOut) and (fLastFrame < fStackList.Count) then Status := ScriptStatus.Pausing;
      end;
			TraceEventKind.ThreadExit: DebugThreadExit:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan));
			TraceEventKind.TracePoint: begin
        if (Status = ScriptStatus.StepInto) or 
          ((Status = ScriptStatus.StepOver) and (fLastFrame = fStackList.Count)) then Status := ScriptStatus.Pausing;
        var lFrame := fStackList[fStackList.Count-1];
        lFrame.ScopeCallback := fScopeCallback;
        DebugTracePoint:Invoke(self, new ScriptDebugEventArgs(name, aSourceFileName, sourceSpan));
      end;
		end; // case
    if Status in [ScriptStatus.Paused, ScriptStatus.Pausing] then begin
      if fRunInThread then begin
        Status := ScriptStatus.Paused;
{$HIDE PW3}
        fWorkThread.Suspend;
{$SHOW PW3}
      end else Idle;
    end;
	finally
		fScopeCallback := nil;
  	fScope := nil;
    fTracing := false;
	end;
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
	if fScope <> nil then exit;
	if fScopeCallback = nil then exit;
	fScope := fScopeCallback();
	if fLocals = nil then
	  fLocals := new List<ScriptBaseLocalInfo>
	else
	  fLocals.Clear;
	for each el: string in fScope.Keys do begin
  	fLocals.Add(new ScriptLocalInfo(fScope, Convert.ToString(el)));
    if el= '$newscope' then begin
      var lEl := IScopeObject(fScope[el]);
      var lTop := true;
      while lEl <> nil do begin
        for each item in lEl.Names do
          fLocals.Add(new ScriptScopeLocalInfo(lEl, item));
        if lTop then
          for each item in  EcmaScriptScope(lEl):&Params do
            fLocals.Add(new ScriptScopeParamInfo(EcmaScriptScope(lEl), item));
        lEl := lEl.Previous;
        lTop := false;
      end;
    end;
  end;
	if fReadonlyLocals = nil then
	  fReadonlyLocals := new System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>(fLocals);
end;

method ScriptComponent.get_Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
begin
	LoadLocals;
	exit fReadonlyLocals;
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

method EcmaScriptComponent.GetEngine: ScriptEngine;
begin
	result := fRuntime.GetEngine('js');
	fGlobalObject := new RemObjects.Script.EcmaScript.GlobalObject;
end;

method EcmaScriptComponent.GetRuntimeSetup: ScriptRuntimeSetup;
begin
  result := new ScriptRuntimeSetup;
  var lLang: String := typeof(RemObjects.Script.EcmaScript.EcmaScriptLanguageContext).AssemblyQualifiedName;
  result.LanguageSetups.Add(new LanguageSetup(lLang, 'js', array of string(['js']), array of string(['.js'])));
end;

method EcmaScriptComponent.HasFunction(aName: String): Boolean;
begin
	exit fGlobalObject.Get(aName) is RemObjects.Script.EcmaScript.EcmaScriptFunctionObject;
end;

method EcmaScriptComponent.RunFunction(aName: String; params args: Array of object): Object;
begin
	var lTrace := CreateTrace;
	var lItem := fGlobalObject.Get(aName) as RemObjects.Script.EcmaScript.EcmaScriptFunctionObject;
	if lItem = nil then raise new ScriptComponentException(String.Format(RemObjects.Script.Properties.Resources.eNoSuchFunction, aName));
	if lTrace <> nil then begin
	  lTrace.TraceCallback := TraceHelperInstance;
  	try
	    exit lItem.Call(args);
	  finally
  		if lTrace <> nil then lTrace.Close;
	  end;
	end else 
	  exit lItem.Call(Args);
end;

method EcmaScriptComponent.IntRun: Object;
begin
  Status := fEntryStatus; 
  fEntryStatus := ScriptStatus.Running;
  try
	  var lTrace := CreateTrace;
	  var lOpt := new RemObjects.Script.EcmaScript.EcmaScriptCompilerOptions();
	  lOpt.ExposeFunctionsInGlobalObject := true;
	  lOpt.GlobalObject := fGlobalObject;
	  if String.IsNullOrEmpty(SourceFileName) then SourceFileName := 'main.js';
	  if Source = nil then Source := '';
    var lSource := fEngine.CreateScriptSourceFromString(Source, SourceFileName, SourceCodeKind.Statements);
    if fListener = nil then fListener  := new EcmaScriptComponent.Listener(self);

	  var lData := lSource.Compile(lOpt, fListener);
	  if lTrace <> nil then begin
	    lTrace.TraceCallback := TraceHelperInstance;
  	  try
	      exit lData.Execute(fGlobals);
	    finally
  		  if lTrace <> nil then lTrace.Close;
	    end;
	  end else 
  	  exit lData.Execute(fGlobals);
  except
    on e: ScriptAbortException do
      exit Undefined.Instance;
  finally
    Status := ScriptStatus.Stopped;
  end;
end;

method EcmaScriptComponent.CreateTrace: ITracePipeline; 
begin
	if Debug then begin
    fGlobalObject.DebugCtx := Microsoft.Scripting.Debugging.CompilerServices.DebugContext.CreateInstance;
	  exit TracePipeline.CreateInstance(fGlobalObject.DebugCtx);
	end;
	exit nil;
end;

method EcmaScriptComponent.SetDebug(b: Boolean);
begin
	if b = Debug then exit;
	inherited SetDebug(b);
	if not b then  begin
		fGlobalObject.DebugCtx := nil;
	end;
end;
method EcmaScriptComponent.ExposeType(&type: &Type; Name: String);
begin
  if String.IsNullOrEmpty(Name) then Name := &Type.Name;
  fBinding := coalesce(fBinding, new EcmaScriptLanguageBinder(nil));
  Globals.SetVariable(Name, new TypeWrapper(&type, fBinding));
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

method ScriptStackFrame.set_ScopeCallback(value: Func<IDictionary<Object,Object>>);
begin
  fScope := nil;
  fScopeCallback := value;
end;

method ScriptStackFrame.get_Locals: System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>;
begin
	LoadLocals;
	exit fReadonlyLocals;
end;

method ScriptStackFrame.LoadLocals;
begin
	if fScope <> nil then exit;
	if fScopeCallback = nil then exit;
	fScope := fScopeCallback();
	if fLocals = nil then
	  fLocals := new List<ScriptBaseLocalInfo>
	else
	  fLocals.Clear;
	for each el: string in fScope.Keys do begin
  	fLocals.Add(new ScriptLocalInfo(fScope, Convert.ToString(el)));
    if el= '$newscope' then begin
      var lEl := IScopeObject(fScope[el]);
      while lEl <> nil do begin
        for each item in lEl.Names do
          fLocals.Add(new ScriptScopeLocalInfo(lEl, item));
        lEl := lEl.Previous;
      end;
    end;
  end;
	if fReadonlyLocals = nil then
	  fReadonlyLocals := new System.Collections.ObjectModel.ReadOnlyCollection<ScriptBaseLocalInfo>(fLocals);
end;


constructor ScriptStackFrame(aMethod: String);
begin
  fMethod := aMethod;
end;

constructor ScriptComponent.TraceHelper(aOwner: ScriptComponent);
begin
  fOwner := aOwner;
end;

method ScriptComponent.TraceHelper.OnTraceEvent(kind: TraceEventKind; name, sourceFileName: String; sourceSpan: SourceSpan; scopeCallback: Func<IDictionary<Object,Object>>; payload, customPayload: Object);
begin
  fOwner.OnTraceEvent(kind,name,sourceFileName,SourceSpan,scopeCallback,payload,customPayload);
end;

method ScriptScopeLocalInfo.get_Value: Object;
begin
  fInst.GetOwn(fName, out result);
end;

method ScriptScopeLocalInfo.set_Value(aValue: Object);
begin
  fInst.PutOwn(fName, aValue);
end;

constructor ScriptScopeLocalInfo(aInst: IScopeObject; aName: String);
begin
  fName := aName;
  fInst := aInst;
end;

constructor SyntaxErrorException(aSource: ScriptSource; aMessage: String; aSpan: SourceSpan; anErrorCode: Int32; aSeverity: Severity);
begin
  inherited constructor(String.Format('{0}({1}, {2}): {4} {3}',
    asource.Path, aspan.Start.Line, aSpan.Start.Column, aMessage,
    'error'));
  Source := aSource;
  Span := aSpan;
  ErrorCode := anErrorCode;
  Severity := aSeverity;
  Message := aMessage;
end;

method SyntaxErrorException.ToString: String;
begin
  exit inherited Message;
end;

constructor SyntaxErrorException(aSource: string; aMessage: String; aSpan: SourceSpan; anErrorCode: Int32; aSeverity: Severity);
begin
inherited constructor(String.Format('{0}({1}, {2}): {4} {3}',
    aSource, aspan.Start.Line, aSpan.Start.Column, aMessage,
    'error'));
  SourceFilename := aSource;
  Span := aSpan;
  ErrorCode := anErrorCode;
  Severity := aSeverity;
  Message := aMessage;
end;



constructor EcmaScriptComponent.Listener(aOwner: EcmaScriptComponent);
begin
  fOwner := aOwner;
end;

method EcmaScriptComponent.Listener.ErrorReported(source: ScriptSource; message: String; span: SourceSpan; errorCode: Int32; severity: Severity);
begin
  if Severity in [Severity.FatalError, Severity.Error] then
  raise new SyntaxErrorException(source, message, span, errorcode, Severity);

end;

method ScriptScopeParamInfo.set_Value(aValue: Object);
begin
  var lIdx := fInst.Params.IndexOf(fname);
  if (lIdx< 0) or (lIdx >= Length(fInst.Arguments))  then exit;
  fInst.Arguments[lIdx] := aValue;
end;

method ScriptScopeParamInfo.get_Value: Object;
begin
  var lIdx := fInst.Params.IndexOf(fname);
  if (lIdx< 0) or (lIdx >= Length(fInst.Arguments))  then exit Undefined.Instance;
  exit fInst.Arguments[lIdx];
end;


constructor ScriptScopeParamInfo(aInst: EcmaScriptScope; aName: String);
begin
  self.fInst := aInst;
  fName := aName;
end;

end.

