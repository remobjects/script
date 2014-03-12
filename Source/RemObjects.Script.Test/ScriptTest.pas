namespace ROEcmaScript.Test;

interface

uses
  Xunit,
  RemObjects.Script;

type
  ScriptTest = public abstract class
  protected
    var fResult: String;

    method ExecuteJS(script: String): Object;
  end;


  ScriptDelegate nested in ScriptTest = protected method(params args: Array of object): Object;  


implementation


method ScriptTest.ExecuteJS(script: String): Object;
begin
  var lEngine: EcmaScriptComponent := new EcmaScriptComponent();
  lEngine.Debug := false;
  lEngine.RunInThread := false;

  lEngine.Source := script;

  self.fResult := String.Empty;

  var lWriteLn: ScriptDelegate :=
      method(params args: array of object): Object
      begin
        for each el in args do
          self.fResult := self.fResult + RemObjects.Script.EcmaScript.Utilities.GetObjAsString(el, lEngine.GlobalObject.ExecutionContext) + #13#10;
      end;

  lEngine.Globals.SetVariable("writeln", lWriteLn);
  lEngine.Run();

  exit lEngine.RunResult;
end;


end.