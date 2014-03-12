namespace Debugger;

interface

{$HIDE H7}

uses
  System.Drawing,
  System.Collections,
  System.Windows.Forms,
  System.ComponentModel;

type
  MainForm = partial class
  {$REGION Windows Form Designer generated fields}
  private
    var components: System.ComponentModel.Container := nil;
    ScriptEngine: RemObjects.Script.EcmaScriptComponent;
    mainsplit: System.Windows.Forms.SplitContainer;
    tabs: System.Windows.Forms.TabControl;
    tbOutput: System.Windows.Forms.TabPage;
    edOutput: System.Windows.Forms.TextBox;
    tbLocals: System.Windows.Forms.TabPage;
    menuStrip1: System.Windows.Forms.MenuStrip;
    fileToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    newToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    toolStripMenuItem1: System.Windows.Forms.ToolStripSeparator;
    openToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    saveToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    saveAsToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    toolStripMenuItem2: System.Windows.Forms.ToolStripSeparator;
    exitToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    debugToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    runToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    toolStripMenuItem3: System.Windows.Forms.ToolStripSeparator;
    stepIntoToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    stepOverToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    stepOutToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    toolStripMenuItem4: System.Windows.Forms.ToolStripSeparator;
    setClearBreakpointToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    toolStripMenuItem5: System.Windows.Forms.ToolStripSeparator;
    stopToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    tbMain: ICSharpCode.TextEditor.TextEditorControl;
    lvLocals: System.Windows.Forms.ListView;
    columnHeader1: System.Windows.Forms.ColumnHeader;
    columnHeader2: System.Windows.Forms.ColumnHeader;
    dlgOpen: System.Windows.Forms.OpenFileDialog;
    dlgSave: System.Windows.Forms.SaveFileDialog;
    helpToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    aboutToolStripMenuItem: System.Windows.Forms.ToolStripMenuItem;
    method InitializeComponent;
  {$ENDREGION}
  end;

implementation

{$REGION Windows Form Designer generated code}
method MainForm.InitializeComponent;
begin
  self.mainsplit := new System.Windows.Forms.SplitContainer();
  self.tbMain := new ICSharpCode.TextEditor.TextEditorControl();
  self.tabs := new System.Windows.Forms.TabControl();
  self.tbOutput := new System.Windows.Forms.TabPage();
  self.edOutput := new System.Windows.Forms.TextBox();
  self.tbLocals := new System.Windows.Forms.TabPage();
  self.lvLocals := new System.Windows.Forms.ListView();
  self.columnHeader1 := new System.Windows.Forms.ColumnHeader();
  self.columnHeader2 := new System.Windows.Forms.ColumnHeader();
  self.menuStrip1 := new System.Windows.Forms.MenuStrip();
  self.fileToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.newToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.toolStripMenuItem1 := new System.Windows.Forms.ToolStripSeparator();
  self.openToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.saveToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.saveAsToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.toolStripMenuItem2 := new System.Windows.Forms.ToolStripSeparator();
  self.exitToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.debugToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.runToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.toolStripMenuItem3 := new System.Windows.Forms.ToolStripSeparator();
  self.stepIntoToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.stepOverToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.stepOutToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.toolStripMenuItem4 := new System.Windows.Forms.ToolStripSeparator();
  self.setClearBreakpointToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.toolStripMenuItem5 := new System.Windows.Forms.ToolStripSeparator();
  self.stopToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.helpToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.aboutToolStripMenuItem := new System.Windows.Forms.ToolStripMenuItem();
  self.dlgOpen := new System.Windows.Forms.OpenFileDialog();
  self.dlgSave := new System.Windows.Forms.SaveFileDialog();
  self.ScriptEngine := new RemObjects.Script.EcmaScriptComponent();
  self.mainsplit.Panel1.SuspendLayout();
  self.mainsplit.Panel2.SuspendLayout();
  self.mainsplit.SuspendLayout();
  self.tabs.SuspendLayout();
  self.tbOutput.SuspendLayout();
  self.tbLocals.SuspendLayout();
  self.menuStrip1.SuspendLayout();
  self.SuspendLayout();
  //  mainsplit
  self.mainsplit.Dock := System.Windows.Forms.DockStyle.Fill;
  self.mainsplit.FixedPanel := System.Windows.Forms.FixedPanel.Panel2;
  self.mainsplit.Location := new System.Drawing.Point(0, 24);
  self.mainsplit.Name := 'mainsplit';
  self.mainsplit.Orientation := System.Windows.Forms.Orientation.Horizontal;
  //  mainsplit.Panel1
  self.mainsplit.Panel1.Controls.Add(self.tbMain);
  //  mainsplit.Panel2
  self.mainsplit.Panel2.Controls.Add(self.tabs);
  self.mainsplit.Size := new System.Drawing.Size(811, 521);
  self.mainsplit.SplitterDistance := 347;
  self.mainsplit.TabIndex := 0;
  //  tbMain
  self.tbMain.Dock := System.Windows.Forms.DockStyle.Fill;
  self.tbMain.IsReadOnly := false;
  self.tbMain.Location := new System.Drawing.Point(0, 0);
  self.tbMain.Name := 'tbMain';
  self.tbMain.Size := new System.Drawing.Size(811, 347);
  self.tbMain.TabIndex := 0;
  //  tabs
  self.tabs.Controls.Add(self.tbOutput);
  self.tabs.Controls.Add(self.tbLocals);
  self.tabs.Dock := System.Windows.Forms.DockStyle.Fill;
  self.tabs.Location := new System.Drawing.Point(0, 0);
  self.tabs.Name := 'tabs';
  self.tabs.SelectedIndex := 0;
  self.tabs.Size := new System.Drawing.Size(811, 170);
  self.tabs.TabIndex := 0;
  //  tbOutput
  self.tbOutput.Controls.Add(self.edOutput);
  self.tbOutput.Location := new System.Drawing.Point(4, 22);
  self.tbOutput.Name := 'tbOutput';
  self.tbOutput.Padding := new System.Windows.Forms.Padding(3);
  self.tbOutput.Size := new System.Drawing.Size(803, 144);
  self.tbOutput.TabIndex := 0;
  self.tbOutput.Text := 'Output';
  //  edOutput
  self.edOutput.Dock := System.Windows.Forms.DockStyle.Fill;
  self.edOutput.Location := new System.Drawing.Point(3, 3);
  self.edOutput.Multiline := true;
  self.edOutput.Name := 'edOutput';
  self.edOutput.ScrollBars := System.Windows.Forms.ScrollBars.Vertical;
  self.edOutput.Size := new System.Drawing.Size(797, 20);
  self.edOutput.TabIndex := 0;
  //  tbLocals
  self.tbLocals.Controls.Add(self.lvLocals);
  self.tbLocals.Location := new System.Drawing.Point(4, 22);
  self.tbLocals.Name := 'tbLocals';
  self.tbLocals.Padding := new System.Windows.Forms.Padding(3);
  self.tbLocals.Size := new System.Drawing.Size(803, 144);
  self.tbLocals.TabIndex := 1;
  self.tbLocals.Text := 'Locals';
  //  lvLocals
  self.lvLocals.Columns.AddRange(array of System.Windows.Forms.ColumnHeader([self.columnHeader1, self.columnHeader2]));
  self.lvLocals.Dock := System.Windows.Forms.DockStyle.Fill;
  self.lvLocals.Location := new System.Drawing.Point(3, 3);
  self.lvLocals.Name := 'lvLocals';
  self.lvLocals.Size := new System.Drawing.Size(797, 138);
  self.lvLocals.TabIndex := 0;
  self.lvLocals.UseCompatibleStateImageBehavior := false;
  self.lvLocals.View := System.Windows.Forms.View.Details;
  //  columnHeader1
  self.columnHeader1.Text := 'Name';
  self.columnHeader1.Width := 100;
  //  columnHeader2
  self.columnHeader2.Text := 'Value';
  self.columnHeader2.Width := 400;
  //  menuStrip1
  self.menuStrip1.Items.AddRange(array of System.Windows.Forms.ToolStripItem([self.fileToolStripMenuItem, self.debugToolStripMenuItem, self.helpToolStripMenuItem]));
  self.menuStrip1.Location := new System.Drawing.Point(0, 0);
  self.menuStrip1.Name := 'menuStrip1';
  self.menuStrip1.Size := new System.Drawing.Size(811, 24);
  self.menuStrip1.TabIndex := 1;
  self.menuStrip1.Text := 'menuStrip1';
  //  fileToolStripMenuItem
  self.fileToolStripMenuItem.DropDownItems.AddRange(array of System.Windows.Forms.ToolStripItem([self.newToolStripMenuItem, self.toolStripMenuItem1, self.openToolStripMenuItem, self.saveToolStripMenuItem, self.saveAsToolStripMenuItem, self.toolStripMenuItem2, self.exitToolStripMenuItem]));
  self.fileToolStripMenuItem.Name := 'fileToolStripMenuItem';
  self.fileToolStripMenuItem.Size := new System.Drawing.Size(37, 20);
  self.fileToolStripMenuItem.Text := '&File';
  self.fileToolStripMenuItem.Click += new System.EventHandler(@self.fileToolStripMenuItem_Click);
  //  newToolStripMenuItem
  self.newToolStripMenuItem.Name := 'newToolStripMenuItem';
  self.newToolStripMenuItem.Size := new System.Drawing.Size(114, 22);
  self.newToolStripMenuItem.Text := '&New';
  self.newToolStripMenuItem.Click += new System.EventHandler(@self.newToolStripMenuItem_Click);
  //  toolStripMenuItem1
  self.toolStripMenuItem1.Name := 'toolStripMenuItem1';
  self.toolStripMenuItem1.Size := new System.Drawing.Size(111, 6);
  //  openToolStripMenuItem
  self.openToolStripMenuItem.Name := 'openToolStripMenuItem';
  self.openToolStripMenuItem.Size := new System.Drawing.Size(114, 22);
  self.openToolStripMenuItem.Text := '&Open';
  self.openToolStripMenuItem.Click += new System.EventHandler(@self.openToolStripMenuItem_Click);
  //  saveToolStripMenuItem
  self.saveToolStripMenuItem.Name := 'saveToolStripMenuItem';
  self.saveToolStripMenuItem.Size := new System.Drawing.Size(114, 22);
  self.saveToolStripMenuItem.Text := '&Save';
  self.saveToolStripMenuItem.Click += new System.EventHandler(@self.saveToolStripMenuItem_Click);
  //  saveAsToolStripMenuItem
  self.saveAsToolStripMenuItem.Name := 'saveAsToolStripMenuItem';
  self.saveAsToolStripMenuItem.Size := new System.Drawing.Size(114, 22);
  self.saveAsToolStripMenuItem.Text := 'Save As';
  self.saveAsToolStripMenuItem.Click += new System.EventHandler(@self.saveAsToolStripMenuItem_Click);
  //  toolStripMenuItem2
  self.toolStripMenuItem2.Name := 'toolStripMenuItem2';
  self.toolStripMenuItem2.Size := new System.Drawing.Size(111, 6);
  //  exitToolStripMenuItem
  self.exitToolStripMenuItem.Name := 'exitToolStripMenuItem';
  self.exitToolStripMenuItem.Size := new System.Drawing.Size(114, 22);
  self.exitToolStripMenuItem.Text := 'E&xit';
  self.exitToolStripMenuItem.Click += new System.EventHandler(@self.exitToolStripMenuItem_Click);
  //  debugToolStripMenuItem
  self.debugToolStripMenuItem.DropDownItems.AddRange(array of System.Windows.Forms.ToolStripItem([self.runToolStripMenuItem, self.toolStripMenuItem3, self.stepIntoToolStripMenuItem, self.stepOverToolStripMenuItem, self.stepOutToolStripMenuItem, self.toolStripMenuItem4, self.setClearBreakpointToolStripMenuItem, self.toolStripMenuItem5, self.stopToolStripMenuItem]));
  self.debugToolStripMenuItem.Name := 'debugToolStripMenuItem';
  self.debugToolStripMenuItem.Size := new System.Drawing.Size(54, 20);
  self.debugToolStripMenuItem.Text := '&Debug';
  self.debugToolStripMenuItem.Click += new System.EventHandler(@self.debugToolStripMenuItem_Click);
  //  runToolStripMenuItem
  self.runToolStripMenuItem.Name := 'runToolStripMenuItem';
  self.runToolStripMenuItem.ShortcutKeys := System.Windows.Forms.Keys.F5;
  self.runToolStripMenuItem.Size := new System.Drawing.Size(182, 22);
  self.runToolStripMenuItem.Text := '&Run';
  self.runToolStripMenuItem.Click += new System.EventHandler(@self.runToolStripMenuItem_Click);
  //  toolStripMenuItem3
  self.toolStripMenuItem3.Name := 'toolStripMenuItem3';
  self.toolStripMenuItem3.Size := new System.Drawing.Size(179, 6);
  //  stepIntoToolStripMenuItem
  self.stepIntoToolStripMenuItem.Name := 'stepIntoToolStripMenuItem';
  self.stepIntoToolStripMenuItem.ShortcutKeys := System.Windows.Forms.Keys.F11;
  self.stepIntoToolStripMenuItem.Size := new System.Drawing.Size(182, 22);
  self.stepIntoToolStripMenuItem.Text := 'Step &Into';
  self.stepIntoToolStripMenuItem.Click += new System.EventHandler(@self.stepIntoToolStripMenuItem_Click);
  //  stepOverToolStripMenuItem
  self.stepOverToolStripMenuItem.Name := 'stepOverToolStripMenuItem';
  self.stepOverToolStripMenuItem.ShortcutKeys := System.Windows.Forms.Keys.F10;
  self.stepOverToolStripMenuItem.Size := new System.Drawing.Size(182, 22);
  self.stepOverToolStripMenuItem.Text := 'Step &Over';
  self.stepOverToolStripMenuItem.Click += new System.EventHandler(@self.stepOverToolStripMenuItem_Click);
  //  stepOutToolStripMenuItem
  self.stepOutToolStripMenuItem.Name := 'stepOutToolStripMenuItem';
  self.stepOutToolStripMenuItem.Size := new System.Drawing.Size(182, 22);
  self.stepOutToolStripMenuItem.Text := 'Step O&ut';
  self.stepOutToolStripMenuItem.Click += new System.EventHandler(@self.stepOutToolStripMenuItem_Click);
  //  toolStripMenuItem4
  self.toolStripMenuItem4.Name := 'toolStripMenuItem4';
  self.toolStripMenuItem4.Size := new System.Drawing.Size(179, 6);
  //  setClearBreakpointToolStripMenuItem
  self.setClearBreakpointToolStripMenuItem.Name := 'setClearBreakpointToolStripMenuItem';
  self.setClearBreakpointToolStripMenuItem.Size := new System.Drawing.Size(182, 22);
  self.setClearBreakpointToolStripMenuItem.Text := 'S&et/Clear Breakpoint';
  self.setClearBreakpointToolStripMenuItem.Click += new System.EventHandler(@self.setClearBreakpointToolStripMenuItem_Click);
  //  toolStripMenuItem5
  self.toolStripMenuItem5.Name := 'toolStripMenuItem5';
  self.toolStripMenuItem5.Size := new System.Drawing.Size(179, 6);
  //  stopToolStripMenuItem
  self.stopToolStripMenuItem.Name := 'stopToolStripMenuItem';
  self.stopToolStripMenuItem.Size := new System.Drawing.Size(182, 22);
  self.stopToolStripMenuItem.Text := '&Stop';
  self.stopToolStripMenuItem.Click += new System.EventHandler(@self.stopToolStripMenuItem_Click);
  //  helpToolStripMenuItem
  self.helpToolStripMenuItem.DropDownItems.AddRange(array of System.Windows.Forms.ToolStripItem([self.aboutToolStripMenuItem]));
  self.helpToolStripMenuItem.Name := 'helpToolStripMenuItem';
  self.helpToolStripMenuItem.Size := new System.Drawing.Size(44, 20);
  self.helpToolStripMenuItem.Text := '&Help';
  //  aboutToolStripMenuItem
  self.aboutToolStripMenuItem.Name := 'aboutToolStripMenuItem';
  self.aboutToolStripMenuItem.Size := new System.Drawing.Size(107, 22);
  self.aboutToolStripMenuItem.Text := '&About';
  self.aboutToolStripMenuItem.Click += new System.EventHandler(@self.aboutToolStripMenuItem_Click);
  //  dlgOpen
  self.dlgOpen.DefaultExt := 'js';
  self.dlgOpen.Filter := 'JS Files|*.js';
  //  dlgSave
  self.dlgSave.DefaultExt := 'js';
  self.dlgSave.Filter := 'JS Files|*.js';
  //  ScriptEngine
  self.ScriptEngine.Debug := false;
  self.ScriptEngine.JustFunctions := false;
  self.ScriptEngine.RootContext := nil;
  self.ScriptEngine.RunInThread := false;
  self.ScriptEngine.Source := nil;
  self.ScriptEngine.SourceFileName := nil;
  //  MainForm
  self.AutoScaleDimensions := new System.Drawing.SizeF(6, 13);
  self.AutoScaleMode := System.Windows.Forms.AutoScaleMode.Font;
  self.ClientSize := new System.Drawing.Size(811, 545);
  self.Controls.Add(self.mainsplit);
  self.Controls.Add(self.menuStrip1);
  self.MainMenuStrip := self.menuStrip1;
  self.Name := 'MainForm';
  self.Text := 'Debugger';
  self.FormClosing += new System.Windows.Forms.FormClosingEventHandler(@self.MainForm_FormClosing);
  self.mainsplit.Panel1.ResumeLayout(false);
  self.mainsplit.Panel2.ResumeLayout(false);
  self.mainsplit.ResumeLayout(false);
  self.tabs.ResumeLayout(false);
  self.tbOutput.ResumeLayout(false);
  self.tbOutput.PerformLayout();
  self.tbLocals.ResumeLayout(false);
  self.menuStrip1.ResumeLayout(false);
  self.menuStrip1.PerformLayout();
  self.ResumeLayout(false);
  self.PerformLayout();
end;
{$ENDREGION}

end.
