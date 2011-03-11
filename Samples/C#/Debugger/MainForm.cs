using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace Debugger
{
	public partial class MainForm : Form
	{
        public delegate object MyDelegate(params object[] args);
		public MainForm ()
		{
			InitializeComponent ();
			tbMain.Document.HighlightingStrategy = ICSharpCode.TextEditor.Document.HighlightingManager.Manager.FindHighlighterForFile("file.js");
			tbMain.TextChanged += new EventHandler (tbMain_TextChanged);
            ScriptEngine.RunInThread = true;
			ScriptEngine.Debug = true;
            ScriptEngine.StatusChanged += new EventHandler(ScriptEngine_StatusChanged);
            ScriptEngine.DebugTracePoint += new EventHandler<RemObjects.Script.ScriptDebugEventArgs>(ScriptEngine_DebugTracePoint);
            ScriptEngine.DebugThreadExit += new EventHandler<RemObjects.Script.ScriptDebugEventArgs>(ScriptEngine_DebugThreadExit);
            ScriptEngine.Globals.SetVariable("writeln", new MyDelegate(delegate (object[] args) {
                Invoke(new MyDelegate(delegate(object[] args2) {
                    string s = "";
                    if (args2 != null) {
                        s = String.Join(" ",(from x in args2 select x == null?"":x.ToString()).ToArray());
                    }
                    s+= "\r\n";
                    edOutput.AppendText(s);
					this.tabs.SelectedTab = tbOutput;
                    return null;
                }),  new object[] {args});
                return null;
            }));
		}

        void ScriptEngine_StatusChanged(object sender, EventArgs e)
        {
            RemObjects.Script.ScriptStatus lStatus = ScriptEngine.Status;
            BeginInvoke(new Action(delegate
            {
                switch (lStatus) {
                    case RemObjects.Script.ScriptStatus.Paused: Text = "Script Editor [Paused]"; break;
                    case RemObjects.Script.ScriptStatus.Pausing: Text = "Script Editor [Pausing]"; break;
                    case RemObjects.Script.ScriptStatus.Running:
                        edOutput.Clear();
                        Text = "Script Editor [Running]"; break;
                    case RemObjects.Script.ScriptStatus.StepInto: Text = "Script Editor [Running (Step Into)]"; break;
                    case RemObjects.Script.ScriptStatus.StepOut: Text = "Script Editor [Running (Step Out)]"; break;
                    case RemObjects.Script.ScriptStatus.StepOver: Text = "Script Editor [Running (Step Over)]"; break;
                    case RemObjects.Script.ScriptStatus.Stopping: Text = "Script Editor [Stopping]"; break;
                    default:
                        if (ScriptEngine.RunException != null)
                        {
                            edOutput.AppendText("\r\nException: \r\n" + ScriptEngine.RunException.ToString());
                            this.tabs.SelectedTab = tbOutput;
                        }
                        else
                            edOutput.AppendText("\r\nResult: \r\n" + ScriptEngine.RunResult);
                        Text = "Script Editor"; // done running
						break;
                   
                }
            }));
        }

        void ScriptEngine_DebugThreadExit(object sender, RemObjects.Script.ScriptDebugEventArgs e)
        {
            Invoke(new Action(delegate
                {
            tbMain.Document.MarkerStrategy.RemoveAll(a => (a.TextMarkerType == ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock && a.Color == Color.Red));
            tbMain.Refresh();
                }));
        }

        void ScriptEngine_DebugTracePoint(object sender, RemObjects.Script.ScriptDebugEventArgs e)
        {
            if (e.SourceSpan.IsValid)
            {
                Invoke(new Action(delegate
                {
                    tbMain.Document.MarkerStrategy.RemoveAll(a => (a.TextMarkerType == ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock && a.Color == Color.Red));
                    int lStart = tbMain.Document.PositionToOffset(new ICSharpCode.TextEditor.TextLocation(e.SourceSpan.Start.Column - 1, e.SourceSpan.Start.Line - 1));
                    int lEnd = tbMain.Document.PositionToOffset(new ICSharpCode.TextEditor.TextLocation(e.SourceSpan.End.Column - 1, e.SourceSpan.End.Line - 1));
                    tbMain.Document.MarkerStrategy.AddMarker(new ICSharpCode.TextEditor.Document.TextMarker(lStart, lEnd - lStart + 1, ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock, Color.Red));
                    tbMain.Refresh();
                }));
            }
            else
            {
                Invoke(new Action(delegate
                {
                    tbMain.Document.MarkerStrategy.RemoveAll(a => (a.TextMarkerType == ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock && a.Color == Color.Red));
                    tbMain.Refresh();
                }));
            }
            Invoke(new Action(delegate
            {
                lvLocals.Items.Clear();
                foreach (var el in ScriptEngine.Locals)
                {
                    if (!el.Internal)
                    {
                        ListViewItem item = new ListViewItem(el.Name);
                        item.SubItems.Add(el.Value == null ? "(null)" : el.Value.ToString());
                        lvLocals.Items.Add(item);
                    }
                }
            }));
        }

        

		void tbMain_TextChanged (object sender, EventArgs e)
		{
			Changed ();
		}

		private void stepIntoToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdStepInto ();
		}

		private void stopToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdStop ();
		}

		private void setClearBreakpointToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdSetBreakpoint ();
		}

		private void stepOutToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdStepOut ();
		}

		private void stepOverToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdStepOver ();
		}

		private void runToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdRun ();
		}

		private void debugToolStripMenuItem_Click (object sender, EventArgs e)
		{
			runToolStripMenuItem.Enabled = IsPaused () || !IsDebugging ();
			stepIntoToolStripMenuItem.Enabled = runToolStripMenuItem.Enabled;
			stepOutToolStripMenuItem.Enabled = IsPaused ();
            stepOverToolStripMenuItem.Enabled = runToolStripMenuItem.Enabled;
			setClearBreakpointToolStripMenuItem.Enabled = true;
			stopToolStripMenuItem.Enabled = IsDebugging ();
		}

		private void newToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdNew ();
		}

		private void openToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdOpen ();
		}

		private void saveToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdSave ();
		}

		private void saveAsToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdSaveAs ();
		}

		private void exitToolStripMenuItem_Click (object sender, EventArgs e)
		{
			cmdQuit ();
		}

		private void fileToolStripMenuItem_Click (object sender, EventArgs e)
		{
			newToolStripMenuItem.Enabled = CanFileCommands ();
			openToolStripMenuItem.Enabled = CanFileCommands ();
			saveAsToolStripMenuItem.Enabled = CanFileCommands ();
			saveToolStripMenuItem.Enabled = CanFileCommands ();
			exitToolStripMenuItem.Enabled = CanFileCommands ();
		}

		private void MainForm_FormClosing (object sender, FormClosingEventArgs e)
		{
			if(!CanQuit ())
				e.Cancel = true;
		}

		private void aboutToolStripMenuItem_Click (object sender, EventArgs e)
		{
			CmdAbout ();
		}

	}
}
