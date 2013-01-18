namespace ROEcmaScript.Test;

interface

uses
  Xunit.*,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  MyDelegate = method(params args: Array of object): Object;  

  Scripts = public class
  assembly
    fResult: String;
    method ExecuteJS(s: String): Object;
  public
    [Fact]
    method Error;
    [Fact]
    method UnicodeIdentifier;
    [Fact]
    method Arguments;
    [Fact]
    method TestProto;
    [Fact]
    method RegexData;
    [Fact]
    method EvalTest;
    [Fact]
    method SimpleEvalTest;
    [Fact]
    method PropertyTest;
    [Fact]
    method FunctionTest;
    [Fact]
    method SimpleFunctionTest;
    [Fact]
    method AndOrElse;

    [Fact]
    method MinMax();

    [Fact]
    method DateTimeToJSON();

    [Fact]
    method UnknownCall1;
    [Fact]
    method UnknownCall2;
    [Fact]
    method NativeMethodCall;

    [Theory]
    [InlineData('var x = new JSType(); writeln(x.A);',        'JSType', '42')]
    [InlineData('var x = new JSType(); writeln(x.B);',        'JSType', 'Foo')]
    [InlineData('writeln(JSType.Foo());',                     'JSType', 'Bar')]
    [InlineData('var x = new SimpleCLRType(); writeln(x.A);', '',       '42')]
    method ExposeType(aScript: String;  aTypeName: String;  aExpectedResult: String);

    [Fact]
    method RunFunction_Exception_IsNotLost();
  end;


  LDA = public class
  private
    fScripts: Scripts;
  public
    constructor(aScripts: Scripts);
    method Call;
  end;

  SimpleCLRType = class
  public
    constructor();

    property A: Int32 read write;
    property B: String read write;

    class method Foo(): String;
  end;


implementation

method Scripts.EvalTest;
begin
  ExecuteJS(
"var i = 12;
writeln('t1: '+i);
eval('i = 10;');
writeln('t2: '+i);
function test() {
  eval('var i = 15;');
  writeln('t3: '+i);
}
writeln('t4: '+i);
test();
writeln('t5: '+i);
");
var lExpected := "t1: 12
t2: 10
t4: 10
t3: 15
t5: 10
";
  Assert.Equal(lExpected.Replace(#13#10, #10), fresult.Replace(#13#10, #10));
end;

method Scripts.PropertyTest;
begin
  ExecuteJS("
var myObj = function() { 
 
    var value = 0; 
 
    return { 
        getValue: function() { 
            return value;  
        }, 
        setValue: function(v) { 
            value = v; 
        } 
    } 
 
}(); 
writeln(myObj.getValue());
 myObj.setValue('test');
 writeln(myObj.getValue());
");
  var lExpected := "0
test
";

  Assert.Equal(lExpected.Replace(#13#10, #10), fresult.Replace(#13#10, #10));
end;

method Scripts.ExecuteJS(s: String): Object;
begin
  var lComp := new RemObjects.Script.EcmaScriptComponent;
  lComp.Debug := false;
  lComp.RunInThread := false;
  lComp.Source := s;
  fResult := '';
  var lDel: MyDelegate :=  method (params args: Array of object): Object begin
    for each el in args do fResult := fResult + RemObjects.Script.EcmaScript.Utilities.GetObjAsString(el, lComp.GlobalObject.ExecutionContext) + #13#10;
  end;
  lComp.Globals.SetVariable("writeln", lDel);
  lComp.Globals.SetVariable('lda', new RemObjects.Script.EcmaScript.EcmaScriptObjectWrapper(new LDA(self), typeof(LDA), lComp.GlobalObject));
  lComp.Run();
  exit lComp.RunResult;
end;

method Scripts.SimpleEvalTest;
begin
  var lScript := "
  eval('var x = 1');
  y = 2;
  x + y;";
  assert.Equal(Object(3), ExecuteJS(lScript));
end;

method Scripts.FunctionTest;
begin
  var lScript := "
var test = function(x) { return 'testthis' + x; }        
writeln(test(15));
writeln('test');                              
";
  ExecuteJS(lScript);
  var lExpected := "testthis15
test
";
  assert.Equal(lExpected, fResult);
end;

method Scripts.SimpleFunctionTest;
begin
  var lScript := "
function test(x) { return 'testthis' + x; }        
writeln(test(15));
writeln('test');                              
";
  ExecuteJS(lScript);
  var lExpected := "testthis15
test
";
  assert.Equal(lExpected, fResult);
end;

method Scripts.RegexData;
begin
  ExecuteJS("
function twitterCallback2(twitters) {
	var statusHTML = [];
	for (var i=0; i<twitters.length; i++){
		var username = twitters[i].user.screen_name;
		var status = twitters[i].text.replace(/((https?|s?ftp|ssh)\:\/\/[^""\s\<\>]*[^.,;'"">\:\s\<\>\)\]\!])/g, function(url) {
			return '<a href=""'+url+'"">'+url+'</a>';
		}).replace(/\B@([_a-z0-9]+)/ig, function(reply) {
			return  reply.charAt(0)+'<a href=""http://www.twitter.com/'+reply.substring(1)+'"">'+reply.substring(1)+'</a>';
		});
		statusHTML.push('<li><span>'+status+'</span> <a style=""font-size:85%"" href=""http://twitter.com/'+username+'/statuses/'+twitters[i].id+'"">'+relative_time(twitters[i].created_at)+'</a></li>');
	}
	document.getElementById('twitter_update_list_'+username).innerHTML = statusHTML.join('');
}
 
function relative_time(time_value) {
  var values = time_value.split("" "");
  time_value = values[1] + "" "" + values[2] + "", "" + values[5] + "" "" + values[3];
  var parsed_date = Date.parse(time_value);
  var relative_to = (arguments.length > 1) ? arguments[1] : new Date();
  var delta = parseInt((relative_to.getTime() - parsed_date) / 1000);
  delta = delta + (relative_to.getTimezoneOffset() * 60);
 
  if (delta < 60) {
    return 'less than a minute ago';
  } else if(delta < 120) {
    return 'about a minute ago';
  } else if(delta < (60*60)) {
    return (parseInt(delta / 60)).toString() + ' minutes ago';
  } else if(delta < (120*60)) {
    return 'about an hour ago';
  } else if(delta < (24*60*60)) {
    return 'about ' + (parseInt(delta / 3600)).toString() + ' hours ago';
  } else if(delta < (48*60*60)) {
    return '1 day ago';
  } else {
    return (parseInt(delta / 86400)).toString() + ' days ago';
  }
}
");
end;

method Scripts.AndOrElse;
begin
  ExecuteJS("var x = ""test"";
writeln('string');
writeln(x || ""test2"");
writeln(x && ""test2"");
 x = false;
writeln('bool');
writeln(x || ""test2"");
writeln(x && ""test2"");
 x = null;
writeln('null');
writeln(x || ""test2"");
writeln(x && ""test2"");

 x = undefined;
writeln('undefined');
writeln(x || ""test2"");
writeln(x && ""test2"");");
var lExpected := "string
test
test2
bool
test2
false
null
test2
null
undefined
test2
null";
  Assert.Equal(lExpected.Replace(#13#10, #10).Trim([#13, #9, #32, #10]), fresult.Replace(#13#10, #10).Trim([#13, #9, #32, #10]));
end;


method Scripts.MinMax();
begin
  self.ExecuteJS(
      "var x = 1;
       var y = 2;
       writeln(Math.min(x,y) + ""--"" + Math.max(x,y));
      ");
  var lExpected: String := "1--2"+Environment.NewLine;

  Assert.Equal(lExpected, self.fResult);
end;


method Scripts.TestProto;
begin
  ExecuteJS(" function Test(x) { this.x = x; }
Test.prototype.hello = function() { writeln('x = ' + this.x); };
var t = new Test(42);
t.hello();");
var lExpected:= 'x = 42';
  Assert.Equal(lExpected.Replace(#13#10, #10).Trim([#13, #9, #32, #10]), fresult.Replace(#13#10, #10).Trim([#13, #9, #32, #10]));
end;


method Scripts.Arguments();
begin
  ExecuteJS("var f = function(a,b) {
  writeln(arguments);
};

f();");
  var lExpected:= '[object Arguments]';
  Assert.Equal(lExpected.Replace(#13#10, #10).Trim([#13, #9, #32, #10]), fresult.Replace(#13#10, #10).Trim([#13, #9, #32, #10]));
end;


method Scripts.UnicodeIdentifier;
begin
  ExecuteJS("var abc = 15;
  writeln(a\u0062c);
  writeln(\u0061bc);
  ");

var lExpected:= "15
15";
  Assert.Equal(lExpected.Replace(#13#10, #10).Trim([#13, #9, #32, #10]), fresult.Replace(#13#10, #10).Trim([#13, #9, #32, #10]));

end;

method Scripts.Error;
begin
  ExecuteJS("try {
  n = 15;
  n = n / 0;
  writeln(n.toString());
 eval('(');	
 } catch(n){
   writeln(n);
   writeln(typeof(n));
   writeln(n instanceof Error);
   writeln(n instanceof SyntaxError);
   writeln(n.message);
 }
var x = new Error('test');
writeln(x);
writeln(x.message);
writeln(Error.prototype.name);
writeln(Error.prototype.message);
writeln(Error.prototype.toString());");
var lExpected :="Infinity
SyntaxError: Syntax error
object
true
true
Syntax error
Error: test
test
Error

Error
";
 Assert.Equal(lExpected.Replace(#13#10, #10).Trim([#13, #9, #32, #10]), fresult.Replace(#13#10, #10).Trim([#13, #9, #32, #10]));
end;

method Scripts.UnknownCall1;
begin
  try
  ExecuteJS("
    var x = {};
    x.name();
  ");
    Assert.False(true, 'Should not be here');
  except
    on e: RemObjects.Script.ScriptRuntimeException where e.ToString() = 'TypeError: Object [object Object] has no method ''name''' do;
  end;
end;

method Scripts.UnknownCall2;
begin
    try
  ExecuteJS("
    var x = {};
    x.name = {};
    x.name();
  ");
    Assert.False(true, 'Should not be here');
  except
    on e: RemObjects.Script.ScriptRuntimeException where e.ToString() = 'TypeError: Property ''name'' of object [object Object] is not callable' do;
  end;
end;

method Scripts.NativeMethodCall;
begin
  ExecuteJS("
    lda.Call();
  ");
Assert.Equal(fResult, 'LDA.CALL CALLED'#13#10);
end;


method Scripts.ExposeType(aScript: String;  aTypeName: String;  aExpectedResult: String);
begin
  var lScriptEngine := new RemObjects.Script.EcmaScriptComponent();
  lScriptEngine.Debug := false;
  lScriptEngine.RunInThread := false;

  lScriptEngine.Source := aScript;
  self.fResult := String.Empty;

  var lWriteLn: MyDelegate :=
                   method (params args: array of Object): Object
                   begin
                     for each  el  in  args  do
                       self.fResult := self.fResult + RemObjects.Script.EcmaScript.Utilities.GetObjAsString(el, lScriptEngine.GlobalObject.ExecutionContext);
                   end;
  lScriptEngine.Globals.SetVariable("writeln", lWriteLn);

  lScriptEngine.ExposeType(typeOf(SimpleCLRType), aTypeName);
  lScriptEngine.Run();

  Assert.Equal(aExpectedResult, self.fResult);
end;


method Scripts.DateTimeToJSON();
begin
  // This call shouldn't fail
  self.ExecuteJS(
      "
      JSON.stringify(new Date());
      ");
end;


method Scripts.RunFunction_Exception_IsNotLost();
begin
  var lScriptEngine := new RemObjects.Script.EcmaScriptComponent();
  lScriptEngine.Debug := false;
  lScriptEngine.RunInThread := false;

  var lWasExceptionRaised: Boolean := false;
  try
    lScriptEngine.RunFunction('eval', "throw new Error('test error...');");
  except
    lWasExceptionRaised := true;
  end;

  Assert.True(lWasExceptionRaised, 'Exception was not raised in the .NET code');
  Assert.NotNull(lScriptEngine.RunException);
end;


constructor LDA(aScripts: Scripts);
begin
  fScripts := aScripts;
end;


method LDA.Call;
begin
  fScripts.fResult := fScripts.fResult + 'LDA.CALL CALLED'#13#10;
end;


constructor SimpleCLRType();
begin
  self.A := 42;
  self.B := 'Foo';
end;


class method SimpleCLRType.Foo(): String;
begin
  exit  ('Bar');
end;


end.