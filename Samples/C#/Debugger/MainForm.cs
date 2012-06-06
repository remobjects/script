using System;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace Debugger
{
    public partial class MainForm : Form
    {
        public delegate Object MyDelegate(params Object[] args);

        public MainForm()
        {
            InitializeComponent();
            tbMain.Document.HighlightingStrategy = ICSharpCode.TextEditor.Document.HighlightingManager.Manager.FindHighlighterForFile("file.js");
            tbMain.TextChanged += new EventHandler(tbMain_TextChanged);
            ScriptEngine.RunInThread = true;
            ScriptEngine.Debug = true;
            ScriptEngine.StatusChanged += new EventHandler(ScriptEngine_StatusChanged);
            ScriptEngine.DebugTracePoint += new EventHandler<RemObjects.Script.ScriptDebugEventArgs>(ScriptEngine_DebugTracePoint);
            ScriptEngine.DebugThreadExit += new EventHandler<RemObjects.Script.ScriptDebugEventArgs>(ScriptEngine_DebugThreadExit);
            ScriptEngine.Globals.SetVariable("writeln", new MyDelegate(delegate(Object[] args)
            {
                Invoke(new MyDelegate(delegate(Object[] args2)
                {
                    String s = "";
                    if (args2 != null)
                        s = String.Join(" ", (from x in args2 select x == null ? "" : x.ToString()).ToArray());

                    s += "\r\n";
                    edOutput.AppendText(s);
                    this.tabs.SelectedTab = tbOutput;
                    return null;
                }), new Object[] { args });
                return null;
            }));
        }

        void ScriptEngine_StatusChanged(Object sender, EventArgs e)
        {
            RemObjects.Script.ScriptStatus lStatus = ScriptEngine.Status;
            BeginInvoke(new Action(delegate
            {
                switch (lStatus)
                {
                    case RemObjects.Script.ScriptStatus.Paused:
                        Text = "Script Editor [Paused]";
                        break;

                    case RemObjects.Script.ScriptStatus.Pausing:
                        Text = "Script Editor [Pausing]";
                        break;

                    case RemObjects.Script.ScriptStatus.Running:
                        edOutput.Clear();
                        Text = "Script Editor [Running]";
                        break;

                    case RemObjects.Script.ScriptStatus.StepInto:
                        Text = "Script Editor [Running (Step Into)]";
                        break;

                    case RemObjects.Script.ScriptStatus.StepOut:
                        Text = "Script Editor [Running (Step Out)]";
                        break;

                    case RemObjects.Script.ScriptStatus.StepOver:
                        Text = "Script Editor [Running (Step Over)]";
                        break;

                    case RemObjects.Script.ScriptStatus.Stopping:
                        Text = "Script Editor [Stopping]";
                        break;

                    default:
                        if (ScriptEngine.RunException != null)
                        {
                            edOutput.AppendText("\r\nException: \r\n" + ScriptEngine.RunException.ToString());
                            this.tabs.SelectedTab = tbOutput;
                        }
                        else
                        {
                            edOutput.AppendText("\r\nResult: \r\n" + ScriptEngine.RunResult);
                        }
                        tbMain.Document.MarkerStrategy.RemoveAll(a => (a.TextMarkerType == ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock && a.Color == Color.Red));
                        tbMain.Refresh();
                        Text = "Script Editor"; // done running
                        break;
                }
            }));
        }

        void ScriptEngine_DebugThreadExit(Object sender, RemObjects.Script.ScriptDebugEventArgs e)
        {
            Invoke(new Action(delegate
                {
                    tbMain.Document.MarkerStrategy.RemoveAll(a => (a.TextMarkerType == ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock && a.Color == Color.Red));
                    tbMain.Refresh();
                }));
        }

        void ScriptEngine_DebugTracePoint(Object sender, RemObjects.Script.ScriptDebugEventArgs e)
        {
            if (e.SourceSpan.IsValid)
            {
                Invoke(new Action(delegate
                {
                    tbMain.Document.MarkerStrategy.RemoveAll(a => (a.TextMarkerType == ICSharpCode.TextEditor.Document.TextMarkerType.SolidBlock && a.Color == Color.Red));
                    Int32 lStart = tbMain.Document.PositionToOffset(new ICSharpCode.TextEditor.TextLocation(e.SourceSpan.Start.Column - 1, e.SourceSpan.Start.Line - 1));
                    Int32 lEnd = tbMain.Document.PositionToOffset(new ICSharpCode.TextEditor.TextLocation(e.SourceSpan.End.Column - 1, e.SourceSpan.End.Line - 1));
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
                for (Int32 i = ScriptEngine.CallStack.Count - 1; i >= 0; i--)
                {
                    var el = ScriptEngine.CallStack[i];
                    ListViewItem item = new ListViewItem("[METHOD]");
                    item.SubItems.Add(el.Method ?? null);
                    lvLocals.Items.Add(item);
                    item = new ListViewItem("this");
                    item.SubItems.Add(el.This == null ? "this" : el.This.ToString());
                    lvLocals.Items.Add(item);

                    foreach (var name in el.Frame.Names())
                    {
                        item = new ListViewItem(name);
                        var val = el.Frame.GetBindingValue(name, false);
                        item.SubItems.Add(val == null ? "(null)" : val.ToString());
                        lvLocals.Items.Add(item);
                    }
                }
            }));
        }

        void tbMain_TextChanged(Object sender, EventArgs e)
        {
            Changed();
        }

        private void stepIntoToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdStepInto();
        }

        private void stopToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdStop();
        }

        private void setClearBreakpointToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdSetBreakpoint();
        }

        private void stepOutToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdStepOut();
        }

        private void stepOverToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdStepOver();
        }

        private void runToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdRun();
        }

        private void debugToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            runToolStripMenuItem.Enabled = IsPaused() || !IsDebugging();
            stepIntoToolStripMenuItem.Enabled = runToolStripMenuItem.Enabled;
            stepOutToolStripMenuItem.Enabled = IsPaused();
            stepOverToolStripMenuItem.Enabled = runToolStripMenuItem.Enabled;
            setClearBreakpointToolStripMenuItem.Enabled = true;
            stopToolStripMenuItem.Enabled = IsDebugging();
        }

        private void newToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdNew();
        }

        private void openToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdOpen();
        }

        private void saveToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdSave();
        }

        private void saveAsToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdSaveAs();
        }

        private void exitToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            cmdQuit();
        }

        private void fileToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            newToolStripMenuItem.Enabled = CanFileCommands();
            openToolStripMenuItem.Enabled = CanFileCommands();
            saveAsToolStripMenuItem.Enabled = CanFileCommands();
            saveToolStripMenuItem.Enabled = CanFileCommands();
            exitToolStripMenuItem.Enabled = CanFileCommands();
        }

        private void MainForm_FormClosing(Object sender, FormClosingEventArgs e)
        {
            if (!CanQuit())
                e.Cancel = true;
        }

        private void aboutToolStripMenuItem_Click(Object sender, EventArgs e)
        {
            CmdAbout();
        }

    }
}
