namespace RemObjects.Script.EcmaScript;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  DebugSink = public class
  public
    method DebugLine(aFilename: string; aStartRow, aStartCol, aEndRow, aEndCol: Integer); virtual; empty;
    method EnterScope(aName: string; aContext: ExecutionContext); virtual; empty;// enter method
    method ExitScope(aName: string; aContext: ExecutionContext); virtual; empty;// exit method
    method CaughtException(e: Exception); virtual; empty;// triggers on a CATCH before the js code itself
    method UncaughtException(e: Exception); virtual; empty;// triggers when an exception escapes the main method
    method Debugger; virtual; empty;

    class var Method_Debugger: System.Reflection.MethodInfo := typeOf(DebugSink).GetMethod('Debugger'); readonly;
    class var Method_DebugLine: System.Reflection.MethodInfo := typeOf(DebugSink).GetMethod('DebugLine'); readonly;
    class var Method_EnterScope: System.Reflection.MethodInfo := typeOf(DebugSink).GetMethod('EnterScope'); readonly;
    class var Method_ExitScope: System.Reflection.MethodInfo := typeOf(DebugSink).GetMethod('ExitScope'); readonly;
    class var Method_CaughtException: System.Reflection.MethodInfo := typeOf(DebugSink).GetMethod('CaughtException'); readonly;
    class var Method_UncaughtException: System.Reflection.MethodInfo := typeOf(DebugSink).GetMethod('UncaughtException'); readonly;
  end;
  
implementation

end.
