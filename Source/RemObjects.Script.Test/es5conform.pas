namespace ROEcmaScript.Test;

interface

uses
  System,
  System.IO,
  System.Collections.Generic,
  System.Linq,
  System.Text,
  Xunit.Sdk;
  [assembly:System.Runtime.CompilerServices.RuntimeCompatibility(WrapNonExceptionThrows := true)]

type
  [Xunit.RunWith(typeof(Es5ConformTests))]
  Es5ConformTest = public class(Xunit.Sdk.ITestCommand, Xunit.Sdk.IMethodInfo)
  private
  public
    property Owner: Es5ConformTests;
    property Name: string;

    property TypeName: System.String read 'ROEcmaScript.Test.Es5ConformTest';
    property ReturnType: System.String read 'System.Void';
    property MethodInfo: System.Reflection.MethodInfo read typeof(Es5ConformTest).GetMethod('Run');
    property IsStatic: System.Boolean read false;
    property IsAbstract: System.Boolean read false;
    method Invoke(testClass: System.Object; params parameters: array of System.Object); empty;
    method HasAttribute(attributeType: System.Type): System.Boolean; empty;
    method GetCustomAttributes(attributeType: System.Type): sequence of Xunit.Sdk.IAttributeInfo;
    method CreateInstance: System.Object; empty;
    method ToStartXml: System.Xml.XmlNode; empty;
    property Timeout: System.Int32 read 20000;
    property ShouldCreateInstance: System.Boolean read false;
    method Execute(testClass: System.Object): Xunit.Sdk.MethodResult;
    property DisplayName: System.String read Name;
    method GetHashCode: Int32; override;
    method Equals(obj: Object): Boolean; override;

    method Run(Data: Es5ConformTest);
  end;

  Es5Exception = public class(Exception)

  private
  public
    method ToString: String; override;
  end;

  Es5ConformTests = public class(ITestClassCommand)
  private
    fTests: List<Es5ConformTest> := new List<Es5ConformTest>;
    fE5Root: string;
    fTestRoot: string;
    fFramework: Es5ConformanceFramework;

    class var fLibrary: string;
    method ScanJS(aScan: String);
  public
    constructor;


    method RunTest(aName: string);
    property TypeUnderTest: Xunit.Sdk.ITypeInfo;
    property ObjectUnderTest: System.Object read nil;
    method IsTestMethod(testMethod: Xunit.Sdk.IMethodInfo): System.Boolean;
    method EnumerateTestMethods: sequence of Xunit.Sdk.IMethodInfo;
    method EnumerateTestCommands(testMethod: Xunit.Sdk.IMethodInfo): sequence of Xunit.Sdk.ITestCommand;
    method ClassStart: System.Exception; empty;
    method ClassFinish: System.Exception;empty;
    method ChooseNextTest(testsLeftToRun: System.Collections.Generic.ICollection<Xunit.Sdk.IMethodInfo>): System.Int32;empty;
  end;

  Es5ConformanceFramework = public class
  private
    fContext: RemObjects.Script.EcmaScript.ExecutionContext;
  public
    constructor(aContext: RemObjects.Script.EcmaScript.ExecutionContext);
    property Context: RemObjects.Script.EcmaScript.ExecutionContext read fContext  write fContext;
    method registerTest(o: RemObjects.Script.EcmaScript.EcmaScriptObject);
  end;
implementation

method Es5ConformTests.IsTestMethod(testMethod: Xunit.Sdk.IMethodInfo): System.Boolean;
begin
  exit true;
end;

method Es5ConformTests.EnumerateTestMethods: sequence of Xunit.Sdk.IMethodInfo;
begin
  exit fTests.Cast<Xunit.Sdk.IMethodInfo>();
end;

method Es5ConformTests.EnumerateTestCommands(testMethod: Xunit.Sdk.IMethodInfo): sequence of Xunit.Sdk.ITestCommand;
begin
  exit [testMethod as Xunit.Sdk.ITestCommand];
end;

constructor Es5ConformTests;
begin
  var lPath := new Uri(typeOf(Es5ConformTests).Assembly.EscapedCodeBase).LocalPath;
  
  fE5Root := Path.GetFullPath(Path.Combine(Path.Combine(Path.Combine(Path.GetDirectoryName(lPath), '..'), 'Test'), 'es5conform'));
  fTestRoot := Path.Combine(fE5Root, 'TestCases');

  try
    fLibrary := File.ReadAllText(Path.Combine(fTestRoot, 'lib.js'));
    ScanJS(fTestRoot);
  except

  end;
end;

method Es5ConformTests.RunTest(aName: string); 
begin
  if fFramework = nil then
    fFramework := new Es5ConformanceFramework(nil);
  var lScriptFilename := Path.Combine(fTestRoot, aName);
  var lScript := fLibrary + File.ReadAllText(lScriptFilename, Encoding.UTF8).Replace(#65533, ' ');
  using se := new RemObjects.Script.EcmaScriptComponent() do begin
    se.RunInThread := false;
    se.Debug := false;
    se.SourceFileName := aName;
    se.Source := lScript;
    se.Globals.SetVariable('ES5Harness', fFramework);
    fFramework.Context := se.RootContext;
    se.Run;
  end;
end;

method Es5ConformTests.ScanJS(aScan: String);
begin
  var lItems :=new DirectoryInfo(aScan).GetFileSystemInfos();
  for each el in lItems do begin
    if el is DirectoryInfo then continue;
    if el.FullName.EndsWith('.js') and (el.Name <> 'lib.js') then begin
      fTests.Add(new Es5ConformTest(Owner := self, Name := el.FullName.Substring(fTestRoot.Length+1)));
    end; 
  end;
  for each el in lItems do begin
    if el.Name = '.svn' then continue;
    if el is not DirectoryInfo then continue;
    ScanJS(el.FullName);
  end;
end;


method Es5ConformTest.GetCustomAttributes(attributeType: System.Type): sequence of Xunit.Sdk.IAttributeInfo;
begin
  exit [];
end;

method Es5ConformTest.Execute(testClass: System.Object): Xunit.Sdk.MethodResult;
begin
  try
   Run(self);
  except
    on e: exception do exit new Xunit.Sdk.FailedResult(self, e, DisplayName);
  end;
  exit new Xunit.Sdk.PassedResult(self, DisplayName);
end;

method Es5ConformTest.GetHashCode: Int32;
begin
  exit inherited;
end;

method Es5ConformTest.Equals(obj: Object): Boolean;
begin
  exit Es5ConformTest(obj):Name = Name;
end;

method Es5ConformTest.Run(Data: Es5ConformTest);
begin
  Owner.RunTest(Name);
end;


method Es5Exception.ToString: String;
begin
  exit Message;
end;

method Es5ConformanceFramework.registerTest(o: RemObjects.Script.EcmaScript.EcmaScriptObject);
begin
  var lName := o.Get('path');
  var lDescription := o.Get('description');
  var lTest := o.Get('test');
  var lPrecondition := o.Get('precondition');

  if (lPrecondition <> nil) and (lPrecondition <> RemObjects.Script.EcmaScript.Undefined.Instance) then begin
    var lRes := RemObjects.Script.EcmaScript.EcmaScriptObject(lPrecondition).CallEx(fContext, o.Root);
    Xunit.Assert.True(RemObjects.Script.EcmaScript.Utilities.GetObjAsBoolean(lRes, fContext), 'Precondition for '+RemObjects.Script.EcmaScript.Utilities.GetObjAsString(lName, fContext) +' failed. Description: '+RemObjects.Script.EcmaScript.Utilities.GetObjAsString(lDescription, fContext));
  end;
  var lRes := RemObjects.Script.EcmaScript.EcmaScriptObject(lTest).Call(fContext, o.Root);
  Xunit.Assert.True(RemObjects.Script.EcmaScript.Utilities.GetObjAsBoolean(lRes, fContext), 'Testcase '+RemObjects.Script.EcmaScript.Utilities.GetObjAsString(lName, fContext) +' failed. Description: '+RemObjects.Script.EcmaScript.Utilities.GetObjAsString(lDescription, fContext));

  //lName.ToString();
  //test: A function that performs the actual test. The test harness will call this function to execute the test.  It must return true if the test passes. Any other return value indicates a failed test. The test function is called as a method with its this value set to its defining test case object.
  //precondition: (Optional) A function that is called before the test function to see if it is ok to run the test.  If all preconditions necessary to run the test are established it should return true. If it returns false, the test will not be run.  The precondition function is called as a method with its this value set to its defining test case object. This property is optional. If it is not present, the test function will always be executed.
end;

constructor Es5ConformanceFramework(aContext: RemObjects.Script.EcmaScript.ExecutionContext);
begin
  fContext := aContext;
end;

end.
