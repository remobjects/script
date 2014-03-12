namespace ROEcmaScript.Test;

interface

uses
  Xunit.*,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  Scripts = public class(ScriptTest)
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
    method UnknownCall1;
    [Fact]
    method UnknownCall2;

    [Theory]
    [InlineData('var x = new JSType(); writeln(x.A);',        'JSType', '42')]
    [InlineData('var x = new JSType(); writeln(x.B);',        'JSType', 'Foo')]
    [InlineData('writeln(JSType.Foo());',                     'JSType', 'Bar')]
    [InlineData('var x = new SimpleCLRType(); writeln(x.A);', '',       '42')]
    [InlineData('writeln(lda.Bar());',                        '',       'LDA.CALL CALLED')]
    method ExposeType(aScript: String;  aTypeName: String;  aExpectedResult: String);

    [Fact]
    method RunFunction_Exception_IsNotLost();

    [Fact]
    method StingSlice();

    [Fact]
    method StingSubstring();

    [Fact]
    method StingSubStr();
  end;


  SimpleCLRType = class
  public
    constructor();

    property A: Int32 read write;
    property B: String read write;

    class method Foo(): String;
    method Bar(): String;
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
undefined";
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
SyntaxError: <eval>(1:2): Syntax error
object
true
true
<eval>(1:2): Syntax error
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


method Scripts.ExposeType(aScript: String;  aTypeName: String;  aExpectedResult: String);
begin
  var lScriptEngine := new RemObjects.Script.EcmaScriptComponent();
  lScriptEngine.Debug := false;
  lScriptEngine.RunInThread := false;

  lScriptEngine.Source := aScript;
  self.fResult := String.Empty;

  var lWriteLn: ScriptDelegate :=
      method (params args: array of Object): Object
      begin
        for each  el  in  args  do
          self.fResult := self.fResult + RemObjects.Script.EcmaScript.Utilities.GetObjAsString(el, lScriptEngine.GlobalObject.ExecutionContext);
      end;
  lScriptEngine.Globals.SetVariable("writeln", lWriteLn);

  lScriptEngine.ExposeType(typeOf(SimpleCLRType), aTypeName);
  lScriptEngine.Globals.SetVariable('lda', new RemObjects.Script.EcmaScript.EcmaScriptObjectWrapper(new SimpleCLRType(), typeof(SimpleCLRType), lScriptEngine.GlobalObject));
  lScriptEngine.Run();

  Assert.Equal(aExpectedResult, self.fResult);
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


method Scripts.StingSlice();
begin
  // Samples were taken from the https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/String/slice specification
  ExecuteJS(
"var str1 = ""1234567890ABCDEFGH"";
writeln(str1.slice(4, -2));
writeln(str1.slice(-3));
writeln(str1.slice(-3, -1));
writeln(str1.slice(0, -1));
");

var lExpected:= "567890ABCDEF
FGH
FG
1234567890ABCDEFG
";

  Assert.Equal(lExpected, fResult);
end;


method Scripts.StingSubstring();
begin
  // Samples were taken from the https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/String/substring specification
  ExecuteJS(
"var anyString = ""1234567"";

writeln(anyString.substring(0,3));
writeln(anyString.substring(3,0));
 
writeln(anyString.substring(4,7));
writeln(anyString.substring(7,4));

writeln(anyString.substring(0,6));

writeln(anyString.substring(0,7));
writeln(anyString.substring(0,10))
");

var lExpected:= "123
123
567
567
123456
1234567
1234567
";

  Assert.Equal(lExpected, fResult);
end;


method Scripts.StingSubStr();
begin
  // Samples were taken from the https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/String/substr specification
  ExecuteJS(
"var str = ""1234567890"";
writeln(str.substr(1,2));
writeln(str.substr(-3,2));
writeln(str.substr(-3));
writeln(str.substr(1));
writeln(str.substr(-20,2));
writeln(str.substr(20,2));
");

var lExpected:= "23
89
890
234567890
12

";

  Assert.Equal(lExpected, fResult);
end;


constructor SimpleCLRType();
begin
  self.A := 42;
  self.B := 'Foo';
end;


class method SimpleCLRType.Foo(): String;
begin
  exit 'Bar';
end;


method SimpleCLRType.Bar(): String;
begin
  exit 'LDA.CALL CALLED';
end;


end.