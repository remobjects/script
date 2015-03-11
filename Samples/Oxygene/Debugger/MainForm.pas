namespace Debugger;

interface

uses
  System.Drawing,
  System.Collections,
  System.Collections.Generic,
  System.Linq,
  System.Windows.Forms,
  System.ComponentModel;

type
  /// <summary>
  /// Summary description for MainForm.
  /// </summary>
  MainForm = partial class(System.Windows.Forms.Form)
  private
    method MainForm_FormClosing(sender: Object; e: FormClosingEventArgs);
    method ScriptEngine_DebugThreadExit(sender: Object; e: RemObjects.Script.ScriptDebugEventArgs);
    method ScriptEngine_DebugTracePoint(sender: Object; e: RemObjects.Script.ScriptDebugEventArgs);
    method ScriptEngine_StatusChanged(sender: Object; e: EventArgs);
    method aboutToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method debugToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method exitToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method fileToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method newToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method openToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method runToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method saveAsToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method saveToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method setClearBreakpointToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method stepIntoToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method stepOutToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method stepOverToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method stopToolStripMenuItem_Click(sender: Object; e: EventArgs);
    method tbMain_TextChanged(sender: Object; e: EventArgs);
  protected
    method Dispose(aDisposing: Boolean); override;
  public
    constructor;
  end;

  MyDelegate = public block(params args: array of Object);

implementation

{$REGION Construction and Disposition}
constructor MainForm;
begin
  //
  // Required for Windows Form Designer support
  //
  InitializeComponent();

  tbMain.Document.HighlightingStrategy := ICSharpCode.TextEditor.Document.HighlightingManager.Manager.FindHighlighterForFile('file.js');
  tbMain.TextChanged += new EventHandler(tbMain_TextChanged);
  ScriptEngine.RunInThread := true;
  ScriptEngine.Debug := true;
  ScriptEngine.StatusChanged += new EventHandler(ScriptEngine_StatusChanged);
  ScriptEngine.DebugTracePoint += new EventHandler<RemObjects.Script.ScriptDebugEventArgs>(ScriptEngine_DebugTracePoint);
  ScriptEngine.DebugThreadExit += new EventHandler<RemObjects.Script.ScriptDebugEventArgs>(ScriptEngine_DebugThreadExit);
  ScriptEngine.Globals.SetVariable('writeln', new MyDelegate(method (args: array of Object) begin
    Invoke(new MyDelegate(method (args2: array of Object) begin
      var s: String := '';
      if args2 <> nil then      
        s := String.Join(' ', ( from x in args2 select iif(x = nil, '', x.ToString())).ToArray());
      s := s + #13#10;
      edOutput.AppendText(s);
      self.tabs.SelectedTab := tbOutput;
      exit ;
    end), array of Object([args]));
    exit nil;
  end));
end;

method MainForm.Dispose(aDisposing: Boolean);
begin
  if aDisposing then begin
    if assigned(components) then
      components.Dispose();

    //
    // TODO: Add custom disposition code here
    //
  end;
  inherited Dispose(aDisposing);
end;
{$ENDREGION}

method MainForm.ScriptEngine_StatusChanged(sender: Object; e: EventArgs);
begin
  var lStatus: RemObjects.Script.ScriptStatus := ScriptEngine.Status;
  BeginInvoke(new Action(method begin
    case lStatus of 
      RemObjects.Script.ScriptStatus.Paused: begin
        Text := 'Script Editor [Paused]';
      end;
      
      RemObjects.Script.ScriptStatus.Pausing: begin
        Text := 'Script Editor [Pausing]';
      end;
      
      RemObjects.Script.ScriptStatus.Running: begin
        edOutput.Clear();
        Text := 'Script Editor [Running]';
      end;
      
      RemObjects.Script.ScriptStatus.StepInto: begin
        Text := 'Script Editor [Running (Step Into)]';
      end;
      
      RemObjects.Script.ScriptStatus.StepOut: begin
        Text := 'Script Editor [Running (Step Out)]';
      end;
      
      RemObjects.Script.ScriptStatus.StepOver: begin
        Text := 'Script Editor [Running (Step Over)]';
      end;
      
      RemObjects.Script.ScriptStatus.Stopping: begin
        Text := 'Script Editor [Stopping]';
      end
      else begin
        if ScriptEngine.RunException <> nil then begin
          edOutput.AppendText(#13#10'Exception: '#13#10 + ScriptEngine.RunException.ToString);
          self.tabs.SelectedTab := tbOutput;
        end
        else begin
          edOutput.AppendText(#13#10'Result: '#13#10 + ScriptEngine.RunResult);
        end;
        tbMain.Document.MarkerStrategy.RemoveAll(a -> ((a.TextMarkerType = ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock) and (a.Color = Color.Red)));
        tbMain.Refresh;
        Text := 'Script Editor';
      end;
    end;    // done running

  end));
end;

method MainForm.ScriptEngine_DebugThreadExit(sender: Object; e: RemObjects.Script.ScriptDebugEventArgs);
begin
  Invoke(new Action(method begin
    tbMain.Document.MarkerStrategy.RemoveAll(a -> ((a.TextMarkerType = ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock) and (a.Color = Color.Red)));
    tbMain.Refresh;
  end));
end;

method MainForm.ScriptEngine_DebugTracePoint(sender: Object; e: RemObjects.Script.ScriptDebugEventArgs);
begin
  if e.SourceSpan.IsValid then begin
    Invoke(new Action(method begin
      tbMain.Document.MarkerStrategy.RemoveAll(a -> ((a.TextMarkerType = ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock) and (a.Color = Color.Red)));
      var lStart: Int32 := tbMain.Document.PositionToOffset(new ICSharpCode.TextEditor.TextLocation(e.SourceSpan.Start.Column - 1, e.SourceSpan.Start.Line - 1));
      var lEnd: Int32 := tbMain.Document.PositionToOffset(new ICSharpCode.TextEditor.TextLocation(e.SourceSpan.End.Column - 1, e.SourceSpan.End.Line - 1));
      tbMain.Document.MarkerStrategy.AddMarker(new ICSharpCode.TextEditor.Document.TextMarker(lStart, lEnd - lStart + 1, ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock, Color.Red));
      tbMain.Refresh;
    end));
  end
  else begin
    Invoke(new Action(method begin
      tbMain.Document.MarkerStrategy.RemoveAll(a -> ((a.TextMarkerType = ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock) and (a.Color = Color.Red)));
      tbMain.Refresh;
    end))
  end;
  Invoke(new Action(method begin
    lvLocals.Items.Clear;
    begin
      var i: Int32 := ScriptEngine.CallStack.Count - 1;
      while i >= 0 do begin begin
          var el := ScriptEngine.CallStack[i];
          var item: ListViewItem := new ListViewItem('[METHOD]');
          //item.SubItems.Add(coalesce(el.Method, nil)); <-- Type mismatch
          item.SubItems.Add(el.Method);
          lvLocals.Items.Add(item);
          item := new ListViewItem('this');
          item.SubItems.Add(iif(el.This = nil, 'this', el.This.ToString()));
          lvLocals.Items.Add(item);

          for each name in el.Frame.Names() do begin
            item := new ListViewItem(name);
            var val := el.Frame.GetBindingValue(name, false);
            item.SubItems.Add(iif(val = nil, '(null)', val.ToString()));
            lvLocals.Items.Add(item);
          end
        end;
// TODO: not supported Increment might not get called when using continue
        {POST}dec(i);
      end;
    end;
  end));
end;

method MainForm.tbMain_TextChanged(sender: Object; e: EventArgs);
begin
  Changed;
end;

method MainForm.stepIntoToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdStepInto;
end;

method MainForm.stopToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdStop;
end;

method MainForm.setClearBreakpointToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdSetBreakpoint;
end;

method MainForm.stepOutToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdStepOut;
end;

method MainForm.stepOverToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdStepOver;
end;

method MainForm.runToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdRun;
end;

method MainForm.debugToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  runToolStripMenuItem.Enabled := (IsPaused()) or (not IsDebugging());
  stepIntoToolStripMenuItem.Enabled := runToolStripMenuItem.Enabled;
  stepOutToolStripMenuItem.Enabled := IsPaused;
  stepOverToolStripMenuItem.Enabled := runToolStripMenuItem.Enabled;
  setClearBreakpointToolStripMenuItem.Enabled := true;
  stopToolStripMenuItem.Enabled := IsDebugging;
end;

method MainForm.newToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdNew;
end;

method MainForm.openToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdOpen;
end;

method MainForm.saveToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdSave;
end;

method MainForm.saveAsToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdSaveAs;
end;

method MainForm.exitToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  cmdQuit;
end;

method MainForm.fileToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  newToolStripMenuItem.Enabled := CanFileCommands;
  openToolStripMenuItem.Enabled := CanFileCommands;
  saveAsToolStripMenuItem.Enabled := CanFileCommands;
  saveToolStripMenuItem.Enabled := CanFileCommands;
  exitToolStripMenuItem.Enabled := CanFileCommands;
end;

method MainForm.MainForm_FormClosing(sender: Object; e: FormClosingEventArgs);
begin
  if not CanQuit then    
    e.Cancel := true;
end;

method MainForm.aboutToolStripMenuItem_Click(sender: Object; e: EventArgs);
begin
  CmdAbout;
end;

end.
