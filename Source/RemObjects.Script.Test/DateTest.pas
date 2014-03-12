namespace ROEcmaScript.Test;

interface

uses
  Xunit,
  XUnit.Extensions,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  DateTest = public class(ScriptTest)
  public
    [Fact]
    method DateTimeToJSON();

    [Theory]
    [InlineData('Too many days',            'new Date(2012, 11, 32+31)')]
    [InlineData('Too many months',          'new Date(2012, 13, 1)')]
    [InlineData('Too many months and days', 'new Date(2011, 12+12, 32)')]
    [InlineData('Negative days',            'new Date(2013, 2, -27)')]
    [InlineData('Negative months',          'new Date(2014, -11, 1)')]
    [InlineData('Negative months and days', 'new Date(2014, -10, -27)')]
    method IncorrectConstructorArgumentsAreHandledProperly(testName: String;  constructorCall: String);

    [Theory]
    [InlineData('setTime',            'new Date(); date_actual.setTime(1332403882588); ',                        'new Date(2012, 2, 22, 10, 11, 22, 588)')]
    [InlineData('setMilliseconds',    'new Date(2013, 1, 1, 10, 0, 0); date_actual.setMilliseconds(-1000); ',    'new Date(2013, 1, 1, 9, 59, 59)')]
    [InlineData('setUTCMilliseconds', 'new Date(2013, 1, 1, 10, 0, 0); date_actual.setUTCMilliseconds(-1000); ', 'new Date(2013, 1, 1, 9, 59, 59)')]
    [InlineData('setSeconds',         'new Date(2013, 1, 1, 10, 0, 0); date_actual.setSeconds(-1); ',            'new Date(2013, 1, 1, 9, 59, 59)')]
    [InlineData('setSeconds',         'new Date(2013, 1, 1, 10, 0, 0); date_actual.setSeconds(-1, -1000); ',     'new Date(2013, 1, 1, 9, 59, 58)')]
    [InlineData('setUTCSeconds',      'new Date(2013, 1, 1, 10, 0, 0); date_actual.setUTCSeconds(-1); ',         'new Date(2013, 1, 1, 9, 59, 59)')]
    [InlineData('setUTCSeconds',      'new Date(2013, 1, 1, 10, 0, 0); date_actual.setUTCSeconds(-1, -1000); ',  'new Date(2013, 1, 1, 9, 59, 58)')]
    [InlineData('setMinutes',         'new Date(2013, 1, 1, 10, 0, 0); date_actual.setMinutes(-1); ',            'new Date(2013, 1, 1, 9, 59, 0)')]
    [InlineData('setMinutes',         'new Date(2013, 1, 1, 10, 0, 0); date_actual.setMinutes(1); ',             'new Date(2013, 1, 1, 10, 1, 0)')]
    [InlineData('setMinutes',         'new Date(2013, 1, 1, 10, 0, 0); date_actual.setMinutes(-1, 61); ',        'new Date(2013, 1, 1, 10, 0, 1)')]
    [InlineData('setUTCMinutes',      'new Date(2013, 1, 1, 10, 0, 0); date_actual.setUTCMinutes(-1); ',         'new Date(2013, 1, 1, 9, 59, 0)')]
    [InlineData('setUTCMinutes',      'new Date(2013, 1, 1, 10, 0, 0); date_actual.setUTCMinutes(1); ',          'new Date(2013, 1, 1, 10, 1, 0)')]
    [InlineData('setUTCMinutes',      'new Date(2013, 1, 1, 10, 0, 0); date_actual.setUTCMinutes(-1, 61); ',     'new Date(2013, 1, 1, 10, 0, 1)')]
    [InlineData('setHours',           'new Date(2013, 1, 1, 10, 1, 2); date_actual.setHours(1); ',               'new Date(2013, 1, 1, 1, 1, 2)')]
    [InlineData('setHours',           'new Date(2013, 1, 1, 10, 1, 2); date_actual.setHours(-1); ',              'new Date(2013, 0, 31, 23, 1, 2)')]
    [InlineData('setHours',           'new Date(2013, 1, 1, 10, 0, 0); date_actual.setHours(-1, 62); ',          'new Date(2013, 1, 1, 0, 2, 0)')]
    [InlineData('setDate',            'new Date(2013, 1, 1, 10, 1, 2); date_actual.setDate(2); ',                'new Date(2013, 1, 2, 10, 1, 2)')]
    [InlineData('setDate',            'new Date(2013, 0, 1, 10, 1, 2); date_actual.setDate(32); ',               'new Date(2013, 1, 1, 10, 1, 2)')]
    [InlineData('setDate',            'new Date(2013, 1, 1, 10, 1, 2); date_actual.setDate(0); ',                'new Date(2013, 0, 31, 10, 1, 2)')]
    [InlineData('setDate',            'new Date(2013, 0, 1, 10, 1, 2); date_actual.setDate(0); ',                'new Date(2012, 11, 31, 10, 1, 2)')]
    [InlineData('setMonth',           'new Date(2013, 1, 1, 10, 1, 2); date_actual.setMonth(0); ',               'new Date(2013, 0, 1, 10, 1, 2)')]
    [InlineData('setMonth',           'new Date(2013, 1, 1, 10, 1, 2); date_actual.setMonth(-1); ',              'new Date(2012, 11, 1, 10, 1, 2)')]
    [InlineData('setMonth',           'new Date(2013, 1, 1, 10, 1, 2); date_actual.setMonth(1, 2); ',            'new Date(2013, 1, 2, 10, 1, 2)')]
    [InlineData('setFullYear',        'new Date(2013, 1, 1, 10, 1, 2); date_actual.setFullYear(2014); ',         'new Date(2014, 1, 1, 10, 1, 2)')]
    [InlineData('setFullYear',        'new Date(2013, 1, 1, 10, 1, 2); date_actual.setFullYear(2014, 0); ',      'new Date(2014, 0, 1, 10, 1, 2)')]
    [InlineData('setFullYear',        'new Date(2013, 1, 1, 10, 1, 2); date_actual.setFullYear(2014, -1); ',     'new Date(2013, 11, 1, 10, 1, 2)')]
    [InlineData('setFullYear',        'new Date(2013, 1, 1, 10, 1, 2); date_actual.setFullYear(2014, 1, 2); ',   'new Date(2014, 1, 2, 10, 1, 2)')]
    method DateMethodCall(testName: String;  methodCall: String;  expectedValue: String);
  end;


implementation


method DateTest.DateTimeToJSON();
begin
  // This call shouldn't fail
  self.ExecuteJS(
"
JSON.stringify(new Date());
");
end;


method DateTest.IncorrectConstructorArgumentsAreHandledProperly(testName: String;  constructorCall: String);
begin
  self.ExecuteJS(
"
var date_base = new Date(2013, 1, 1);
var date_actual = " + constructorCall + ";
if (date_base*1 != date_actual*1) throw new Error(""" + testName + ": Date value is not correct: Actual: "" + date_actual + "" Expected: "" + date_base);
");
end;


method DateTest.DateMethodCall(testName: String;  methodCall: String;  expectedValue: String);
begin
  self.ExecuteJS(
"
var date_base = new Date(2013, 1, 1);
var date_expected = " + expectedValue + ";
var date_actual = " + methodCall + ";
if (date_expected*1 != date_actual*1) throw new Error(""" + testName + ": Date value is not correct: Actual: "" + date_actual + "" Expected: "" + date_expected);
");

end;


end.