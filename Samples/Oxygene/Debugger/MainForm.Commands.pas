namespace Debugger;

interface

uses
  System,
  System.IO,
  System.Windows.Forms;

type
  MainForm = partial class
  private
    fChanged: Boolean;
    fFilename: String;
    method CanFileCommands: Boolean;
    method IsDebugging: Boolean;
    method IsPaused: Boolean;
{$region File menu handling}
    method CheckModified: DialogResult;
    method IsChanged: Boolean;
    method Changed;
    method Load(fn: String);
    method Save(fn: String);
    method CanQuit: Boolean;
    method cmdQuit;
    method cmdOpen;
    method cmdSaveAs;
    method cmdSave: Boolean;
    method cmdNew;
{$endregion}
{$region Debug handling}
    method cmdRun;
    method cmdStepInto;
    method cmdStepOut;
    method cmdStepOver;
    method cmdSetBreakpoint;
    method cmdStop;
{$endregion}
{$region Help commands}
    method CmdAbout;
{$endregion}
  end;

implementation

method MainForm.CanFileCommands: Boolean;
begin
  exit ScriptEngine.Status = RemObjects.Script.ScriptStatus.Stopped;
end;

method MainForm.IsDebugging: Boolean;
begin
  exit ScriptEngine.Status <> RemObjects.Script.ScriptStatus.Stopped;
end;

method MainForm.IsPaused: Boolean;
begin
  exit ScriptEngine.Status = RemObjects.Script.ScriptStatus.Paused;
end;

method MainForm.CheckModified: DialogResult;
begin
  exit MessageBox.Show('File Not Saved, save now?', 'SingleFileEcmaScript', MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question, MessageBoxDefaultButton.Button1);
end;

method MainForm.IsChanged: Boolean;
begin
  exit fChanged;
end;

method MainForm.Changed;
begin
  fChanged := true;
end;

method MainForm.Load(fn: String);
begin
  tbMain.Text := File.ReadAllText(fn);
  fFilename := fn;
  fChanged := false;
end;

method MainForm.Save(fn: String);
begin
  File.WriteAllText(fn, tbMain.Text);
  fChanged := false;
  fFilename := fn;
end;

method MainForm.CanQuit: Boolean;
begin
  if IsChanged then begin
    case CheckModified of 
      DialogResult.Yes: begin
        if cmdSave then          
          exit true;
        exit false;
      end;
      DialogResult.No: exit true
      else         
        exit false;
    end;
  end;
  exit true;
end;

method MainForm.cmdQuit;
begin
  if CanQuit then    
    Close;
end;

method MainForm.cmdOpen;
begin
  if CanQuit then begin
    if dlgOpen.ShowDialog = DialogResult.OK then      
      Load(dlgOpen.FileName);
  end;
end;

method MainForm.cmdSaveAs;
begin
  if dlgSave.ShowDialog = DialogResult.OK then begin
    Save(dlgSave.FileName);
    fChanged := false;
  end;
end;

method MainForm.cmdSave: Boolean;
begin
  if fFilename = nil then begin
    if dlgSave.ShowDialog = DialogResult.OK then begin
      Save(dlgSave.FileName);
      fChanged := false;
      exit true;
    end;
    exit false;
  end
  else begin
    Save(fFilename);
    exit true;
  end;
end;

method MainForm.cmdNew;
begin
  if CanQuit then begin
    fFilename := nil;
    tbMain.Text := '';
    fChanged := false;
  end;
end;

method MainForm.cmdRun;
begin
  tabs.TabIndex := 1;
  ScriptEngine.Clear(false);
  ScriptEngine.Source := tbMain.Text;
  try
    ScriptEngine.Run;
  except    
    on e: Exception do begin
      MessageBox.Show('Error while running: ' + e.Message);
    end;
  end
end;

method MainForm.cmdStepInto;
begin
  if not IsDebugging then begin
    tabs.TabIndex := 1;
    ScriptEngine.Source := tbMain.Text
  end;
  ScriptEngine.StepInto;
end;

method MainForm.cmdStepOut;
begin
  ScriptEngine.StepOut;
end;

method MainForm.cmdStepOver;
begin
  ScriptEngine.StepOver;
end;

method MainForm.cmdSetBreakpoint;
begin
end;

method MainForm.cmdStop;
begin
  ScriptEngine.Stop;
end;

method MainForm.CmdAbout;
begin
  MessageBox.Show('RemObjects Ecmascript DLR engine.'#13#10#13#10'Copyright (c) 2009 by RemObjects Software'#13#10'http://www.remobjects.com');
end;

end.
