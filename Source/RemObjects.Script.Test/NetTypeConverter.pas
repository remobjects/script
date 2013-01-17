namespace ROEcmaScript.Test;

interface

uses
  Xunit,
  RemObjects.Script;

type
  ScriptTestConsole = class
  private
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
    property propDate: DateTime read write;
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


//constructor RemObjectsConsole;
//begin
//
//end;
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