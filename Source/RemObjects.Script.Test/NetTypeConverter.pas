namespace ROEcmaScript.Test;

interface

uses
  System.Text,
  Xunit,
  Xunit.Extensions,
  RemObjects.Script;

type
  ScriptTestConsole = class
  private
    var fStringBuffer: StringBuilder;
    //var     bag: Dictionary<System.Object, System.Object> := new Dictionary<System.Object, System.Object>();
//
  //public
    //constructor ;
//
    //property propDouble: System.Double read 1.2 write set_propDouble;
    //method set_propDouble(value: System.Double);
    //method getDouble: System.Double;
    //method writeDouble(value: System.Double);
    //method getDateAsDouble: System.Double;
    //method getDateAsInt: System.Int32;
//
    //property propInt: System.Int32 read 150 write set_propInt;
    //method set_propInt(value: System.Int32);
    //method getInt: System.Int32;
    //method writeInt(value: System.Int32);
//
    //property propString: System.String read 'string.value' write set_propString;
    //method set_propString(value: System.String);
    //method writeString(value: System.String);
    //method getString: System.String;
//
    //property propBoolean: System.Boolean read true write set_propBoolean;
    //method set_propBoolean(value: System.Boolean);
    //method writeBoolean(value: System.Boolean);
    //method getBoolean: System.Boolean;
//
    //property propDate: DateTime read new DateTime(1974, 1, 1) write set_propDate;
    //method set_propDate(value: DateTime);
    //method writeDate(value: DateTime);
    //method getDate: DateTime;
//
    //property propObject: System.Object read self write set_propObject;
    //method set_propObject(value: System.Object);
//
    //method writeObject(value: System.Object);
//
    //method ToString: System.String; override;
//
    //method load(commandText: System.String; params parameters: array of System.Object);
//
    //method load2(commandText: System.String; parameters: array of System.Object);
//
    //method loadStrings(params parameters: array of System.String);
    //method loadDoubles(params parameters: array of System.Double);
    //method loadStrings2(parameters: array of System.String);
//
    //property Item[name: System.String]: System.Object read get_Item write bag[name]; default;
    //method get_Item(name: System.String): System.Object;
//
    //property Item[&index: System.Int32]: System.Object read get_Item write bag[&index.ToString()]; default;
    //method get_Item(&index: System.Int32): System.Object;
//
    //method ThrowException;
  public
    constructor();

    property propObject: Object read write;
    property propBoolean: Boolean read write;
    property propDate: DateTime read write;
    property propDouble: Double read write;
    property propString: String read write;

    method writeString(s: String);
    method writeObject(o: Object);
    method throwException();

    method ToString(): String; override;
    method GetStringBuffer(): String;
  end;


  NetTypeConverter = public class
  public
    [Fact]
    method DateConstructorCreatesValidDate();

    [Fact]
    method DateConstructorCreatesValidDateForDatesPriorTo1970();

    [Fact]
    method DatePropertyAcceptsDouble();

    [Fact]
    method DatePropertyAcceptsNumber();

    [Fact]
    method BooleanValuesAreConvertedToStringProperly();

    [Fact]
    method _ToString_IsCalledWhenScriptCalls_toString_();

    [Theory]
    [InlineData("{}",         true)]
    [InlineData("0",          false)]
    [InlineData("-0",         false)]
    [InlineData("1",          true)]
    [InlineData("-1",         true)]
    [InlineData("-0.1",       true)]
    [InlineData("null",       false)]
    [InlineData("''",         false)]
    [InlineData("'true'",     true)]
    [InlineData("'false'",    true)]
    [InlineData("true",       true)]
    [InlineData("false",      false)]
    [InlineData("'AAAA'",     true)]
    [InlineData("undefined",  false)]
    [InlineData("Number.NaN", false)]
    method JsObjectsAreconvertedToBooleanProperly(script: String;  expectedResult: Boolean);

    [Fact]
    method NullToDouble_Equals_0();

    [Fact]
    method UndefinedToDouble_Equals_NaN();

    [Fact]
    method Double_valueOf_DoesntFail();

    [Fact]
    method ExceptionMessage_Is_Not_Empty();

    [Fact]
    method UnefinedToObject_Equals_Undefined();
  end;


implementation


method NetTypeConverter.DateConstructorCreatesValidDate();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
  cc.propDate = new Date(2013,1,17,1,2,3,4);
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<DateTime>(new DateTime(2013, 2, 17, 1, 2, 3, 4), lConsole.propDate);
  end;
end;


method NetTypeConverter.DateConstructorCreatesValidDateForDatesPriorTo1970();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
  cc.propDate = new Date(1968,2,4,1,1,1,1);
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<DateTime>(new DateTime(1968,3,4,1,1,1,1), lConsole.propDate);
  end;

end;


method NetTypeConverter.DatePropertyAcceptsDouble();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
  cc.propDate = 1358435880.0;
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<DateTime>(new DateTime(2013, 1,17, 17, 18, 0, 0), lConsole.propDate);
  end;
end;


method NetTypeConverter.DatePropertyAcceptsNumber();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
  cc.propDate = new Number(1358435880.0);
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<DateTime>(new DateTime(2013, 1, 17, 17, 18, 0, 0), lConsole.propDate);
  end;
end;


method NetTypeConverter._ToString_IsCalledWhenScriptCalls_toString_();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
    // Result should be the same!
    var ts0 = cc.toString();
    var ts1 = cc.ToString();
    cc.writeString(ts0);
    cc.writeString(ts1);
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<String>('Custom .ToString call result||Custom .ToString call result||', lConsole.GetStringBuffer());
  end;
end;


method NetTypeConverter.BooleanValuesAreConvertedToStringProperly();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
    cc.propString = true;// lead to 'True'
    cc.writeString(cc.propString);
    cc.writeString(true);// lead to 'True'

    cc.propString = new Boolean(true);// lead to 'true'
    cc.writeString(cc.propString);
    cc.writeString(new Boolean(true));// lead to dirfferent presentation in string format 'True' when up one is 'true'

    cc.propString = false;// lead to 'False'
    cc.writeString(cc.propString);
    cc.writeString(false);// lead to 'False'

    cc.propString = new Boolean(false);// lead to 'false'
    cc.writeString(cc.propString);
    cc.writeString(new Boolean(false));// lead to dirfferent presentation in string format 'False' when up one is 'false'
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<String>('true||true||true||true||false||false||false||false||', lConsole.GetStringBuffer());
  end;
end;


method NetTypeConverter.JsObjectsAreconvertedToBooleanProperly(script: String;  expectedResult: Boolean);
begin
// If the Boolean object has no initial value, or if the passed value is one of the following:
// 0,-0,null,'',false,undefined,NaN
// the object is set to false. For any other value it is set to true (even with the string 'false')!
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction1(cc) {
    var o = " + script + ";
    cc.propBoolean = new Boolean(o);
}

function testFunction2(cc) {
    var o = " + script + ";
    cc.propBoolean = o;
}"
);
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction1', lConsole);
    Assert.Equal<Boolean>(expectedResult, lConsole.propBoolean);

    engine.RunFunction('testFunction2', lConsole);
    Assert.Equal<Boolean>(expectedResult, lConsole.propBoolean);
  end;
end;


method NetTypeConverter.NullToDouble_Equals_0();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
    cc.propDouble = null;
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<Double>(0, lConsole.propDouble);
  end;
end;


method NetTypeConverter.UndefinedToDouble_Equals_NaN();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
    cc.propDouble = undefined;
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.True(Double.IsNaN(lConsole.propDouble));
  end;
end;


method NetTypeConverter.Double_valueOf_DoesntFail();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
    cc.propDouble = 1.2;
    cc.propDouble = cc.propDouble.valueOf() + 0.1;
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<Double>(1.3, lConsole.propDouble);
  end;
end;


method NetTypeConverter.ExceptionMessage_Is_Not_Empty();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
    try
    {
        cc.throwException();
    }
    catch(e)
    {
        cc.writeString(e.message);//is empty???, when .Net exception no message property exists, may be is need native .Net exception
    }}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    try
      engine.RunFunction('testFunction', lConsole);
    except
    end;

    Assert.Equal<String>('Test Message||', lConsole.GetStringBuffer());
  end;
end;


method NetTypeConverter.UnefinedToObject_Equals_Undefined();
begin
  using engine := new EcmaScriptComponent() do begin
    engine.Include('test',
"
function testFunction(cc) {
    cc.writeObject(undefined);
}
");
    var lConsole: ScriptTestConsole := new ScriptTestConsole();
    engine.RunFunction('testFunction', lConsole);

    Assert.Equal<Object>(RemObjects.Script.EcmaScript.Undefined.Instance, lConsole.propObject);
  end;
end;


constructor ScriptTestConsole();
begin
  self.fStringBuffer := new StringBuilder();
end;


method ScriptTestConsole.writeString(s: String);
begin
  self.fStringBuffer.Append(s);
  self.fStringBuffer.Append('||');
end;


method ScriptTestConsole.writeObject(o: Object);
begin
  self.propObject := o;
end;


method ScriptTestConsole.GetStringBuffer(): String;
begin
  exit self.fStringBuffer.ToString();
end;


method ScriptTestConsole.ToString(): String;
begin
  exit 'Custom .ToString call result';
end;


method ScriptTestConsole.throwException();
begin
  raise new Exception('Test Message');
end;


//
//method RemObjectsConsole.set_propDouble(value: System.Double); begin
  //Console.WriteLine('propDouble:{0}', value)
//end;
//
//method RemObjectsConsole.getDouble: System.Double;
//begin
  //exit 1.3
//end;
//
//method RemObjectsConsole.writeDouble(value: System.Double);
//begin
  //Console.WriteLine('writeDouble:{0}', value)
//end;
//
//method RemObjectsConsole.getDateAsDouble: System.Double;
//begin
  //exit 1357908756
//end;
//
//method RemObjectsConsole.getDateAsInt: System.Int32;
//begin
  //exit 1357908756
//end;
//
//method RemObjectsConsole.set_propInt(value: System.Int32); begin
  //Console.WriteLine('propInt:{0}', value)
//end;
//
//method RemObjectsConsole.getInt: System.Int32;
//begin
  //exit 150
//end;
//
//method RemObjectsConsole.writeInt(value: System.Int32);
//begin
  //Console.WriteLine('writeInt:{0}', value)
//end;
//
//method RemObjectsConsole.set_propString(value: System.String); begin
  //Console.WriteLine('propString:{0}', (iif(value = nil, '<<null>>', value)))
//end;
//
//method RemObjectsConsole.writeString(value: System.String);
//begin
  //Console.WriteLine('writeString:{0}', (iif(value = nil, '<<null>>', value)))
//end;
//
//method RemObjectsConsole.getString: System.String;
//begin
  //exit 'My get string...'
//end;
//
//method RemObjectsConsole.set_propBoolean(value: System.Boolean); begin
  //Console.WriteLine('propBoolean:{0}', value)
//end;
//
//method RemObjectsConsole.writeBoolean(value: System.Boolean);
//begin
  //Console.WriteLine('writeBoolean:{0}', value)
//end;
//
//method RemObjectsConsole.getBoolean: System.Boolean;
//begin
  //exit true
//end;
//
//method RemObjectsConsole.set_propDate(value: DateTime); begin
  //Console.WriteLine('propDate:{0}', value)
//end;
//
//method RemObjectsConsole.writeDate(value: DateTime);
//begin
  //Console.WriteLine('writeDate:{0}', value)
//end;
//
//method RemObjectsConsole.getDate: DateTime;
//begin
  //exit new DateTime(1974, 1, 1)
//end;
//
//method RemObjectsConsole.set_propObject(value: System.Object); begin
  //Console.WriteLine('propObject:{0}:{1}', (iif(nil = value, '<<null>>', value.GetType().Name)), (iif(nil = value, '<<null>>', value)))
//end;
//
//method RemObjectsConsole.writeObject(value: System.Object);
//begin
  //Console.WriteLine('writeObject:{0}:{1}', (iif(nil = value, '<<null>>', value.GetType().Name)), (iif(nil = value, '<<null>>', value)))
//end;
//
//method RemObjectsConsole.ToString: System.String;
//begin
  //exit 'My Console.ToString to string ...'
//end;
//
//method RemObjectsConsole.load(commandText: System.String; params parameters: array of System.Object);
//begin
//// do somting...
  //var i: System.Int32 := 0
//end;
//
//method RemObjectsConsole.load2(commandText: System.String; parameters: array of System.Object);
//begin
//// do somting...
  //var i: System.Int32 := 0
//end;
//
//method RemObjectsConsole.loadStrings(params parameters: array of System.String);
//begin
//// do somting...
  //var i: System.Int32 := 0
//end;
//
//method RemObjectsConsole.loadDoubles(params parameters: array of System.Double);
//begin
//// do somting...
  //var i: System.Int32 := 0
//end;
//
//method RemObjectsConsole.loadStrings2(parameters: array of System.String);
//begin
//// do somting...
  //var i: System.Int32 := 0
//end;
//
//method RemObjectsConsole.get_Item(name: System.String): System.Object; begin
  //var value: System.Object;
  //bag.TryGetValue(name, out value);
  //exit value
//end;
//
//method RemObjectsConsole.get_Item(&index: System.Int32): System.Object; begin
  //var value: System.Object;
  //bag.TryGetValue(&index.ToString(), out value);
  //exit value
//end;
//
//method RemObjectsConsole.ThrowException;
//begin
  //raise new ApplicationException('test exception ....')
//end;

end.