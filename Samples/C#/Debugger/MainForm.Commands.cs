using System;
using System.Windows.Forms;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace Debugger
{
	public partial class MainForm
	{
		bool fChanged;
		string fFilename;

		bool CanFileCommands ()
		{
			return ScriptEngine.Status == RemObjects.Script.ScriptStatus.Stopped;
		}

		bool IsDebugging ()
		{
			return ScriptEngine.Status != RemObjects.Script.ScriptStatus.Stopped;
		}

		bool IsPaused ()
		{
			return ScriptEngine.Status == RemObjects.Script.ScriptStatus.Paused;
		}
		#region File menu handling
		DialogResult CheckModified ()
		{
			return MessageBox.Show ("File Not Saved, save now?", "SingleFileEcmaScript", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question, MessageBoxDefaultButton.Button1);
		}

		bool IsChanged ()
		{
			return fChanged;
		}

		void Changed ()
		{
			fChanged = true;
		}

        new void Load(string fn)
		{
			tbMain.Text = File.ReadAllText (fn);
			fFilename = fn;
			fChanged = false;
		}

		void Save (string fn)
		{
			File.WriteAllText (fn, tbMain.Text);
			fChanged = false;
			fFilename = fn;
		}

		bool CanQuit ()
		{
			if(IsChanged ()) {
				switch(CheckModified ()) {
					case DialogResult.Yes:  
						if (cmdSave()) 
							return true; 
						return false;
					case DialogResult.No: return true;
					default:
						return false;
				}
			}
			return true;
		}

		void cmdQuit ()
		{
			if(CanQuit ())
				Close ();
		}

		void cmdOpen ()
		{
			if(CanQuit ()) {
				if(dlgOpen.ShowDialog () == DialogResult.OK)
					Load (dlgOpen.FileName);
			}
		}

		void cmdSaveAs ()
		{
			if(dlgSave.ShowDialog () == DialogResult.OK) {
				Save (dlgSave.FileName);
				fChanged = false;
			}
		}

		bool cmdSave ()
		{
			if(fFilename == null) {
				if(dlgSave.ShowDialog () == DialogResult.OK) {
					Save (dlgSave.FileName);
					fChanged = false;
					return true;
				}
				return false;
			}
			else {
				Save (fFilename);
				return true;
			}
		}

		void cmdNew ()
		{
			if(CanQuit ()) {
				fFilename = null;
				tbMain.Text = "";
				fChanged = false;
			}
		}
		#endregion

		#region Debug handling
		void cmdRun ()
		{
            tabs.TabIndex = 1;
            ScriptEngine.Source = tbMain.Text;
            try
            {
                ScriptEngine.Run();
            }
            catch(Exception e)
            {
                MessageBox.Show("Error while running: "+e.Message);
            }
		}

		void cmdStepInto ()
		{
            if (!IsDebugging())
            {
                tabs.TabIndex = 1;
                ScriptEngine.Source = tbMain.Text;
            }
            ScriptEngine.StepInto();
		}

		void cmdStepOut ()
		{
            ScriptEngine.StepOut();
		}

		void cmdStepOver ()
		{
            ScriptEngine.StepOver();
		}

		void cmdSetBreakpoint ()
		{
		}

		void cmdStop ()
		{
            ScriptEngine.Stop();
		}
		#endregion

		#region Help commands
		void CmdAbout ()
		{
			MessageBox.Show ("RemObjects Ecmascript DLR engine.\r\n\r\nCopyright (c) 2009 by RemObjects Software\r\nhttp://www.remobjects.com");
		}
		#endregion
	}
}
