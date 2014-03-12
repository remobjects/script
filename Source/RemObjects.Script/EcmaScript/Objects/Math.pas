{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)
  private
    fRandom: Random;
  public
    method CreateMath: EcmaScriptObject;

    method Mathabs(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathacos(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathasin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathatan(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathatan2(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathceil(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathcos(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathexp(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathfloor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathlog(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method MathMax(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method MathMin(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
    method Mathpow(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathrandom(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathround(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathsin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathsqrt(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathtan(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
  end;


implementation


method GlobalObject.CreateMath: EcmaScriptObject;
begin
  result := new EcmaScriptObject(self, nil, &Class := 'Math');
  Values['Math'] := PropertyValue.NotEnum(Result);
  
  
  result.Values.Add('E', PropertyValue.NotAllFlags(Math.E));
  result.Values.Add('PI', PropertyValue.NotAllFlags(Math.PI));
  result.Values.Add('SQRT1_2', PropertyValue.NotAllFlags(Math.Sqrt(0.5)));
  result.Values.Add('SQRT2', PropertyValue.NotAllFlags(Math.Sqrt(2)));

  result.Values.Add('LN10', PropertyValue.NotAllFlags(Math.Log(10)));
  result.Values.Add('LN2', PropertyValue.NotAllFlags(Math.Log(2)));
  result.Values.Add('LOG2E', PropertyValue.NotAllFlags(Math.Log(Math.E, 2)));
  result.Values.Add('LOG10E', PropertyValue.NotAllFlags(Math.Log(Math.E, 10)));

  result.Values.Add('abs', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'abs', @Mathabs, 1)));
  result.Values.Add('acos', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'acos', @Mathacos, 1)));
  result.Values.Add('asin', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'asin', @Mathasin, 1)));
  result.Values.Add('atan', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'atin', @Mathatan, 1)));
  result.Values.Add('atan2', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'atin2', @Mathatan2,2)));
  result.Values.Add('ceil', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'ceil', @Mathceil, 1)));
  result.Values.Add('cos', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'cos', @Mathcos, 1)));
  result.Values.Add('exp', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'exp', @Mathexp, 1)));
  result.Values.Add('floor', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'floor', @Mathfloor, 1)));
  result.Values.Add('log', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'log', @Mathlog, 1)));
  result.Values.Add('max', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'max',@MathMax, 2)));
  result.Values.Add('min', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'min', @MathMin, 2)));
  result.Values.Add('pow', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'pow', @Mathpow, 1)));
  result.Values.Add('random', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'random', @Mathrandom, 0)));
  result.Values.Add('round', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'round', @Mathround, 1)));
  result.Values.Add('sin', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'sin', @Mathsin, 1)));
  result.Values.Add('sqrt', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'sqrt', @Mathsqrt, 1)));
  result.Values.Add('tan', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'tan', @Mathtan, 1)));
end;

method GlobalObject.Mathabs(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Abs(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathacos(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Acos(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathasin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Asin(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathatan(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Atan(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathatan2(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Atan2(Utilities.GetArgAsDouble(Args, 0, aCaller), Utilities.GetArgAsDouble(Args, 1, aCaller));
end;

method GlobalObject.Mathceil(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Ceiling(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathcos(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Cos(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathexp(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Exp(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathfloor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Floor(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathlog(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Log(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;


method GlobalObject.MathMax(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  if  (length(args) = 0)  then
    exit  (Double.NegativeInfinity);

  if  (args.Length = 1)  then
    exit  (args[0]);

  var lMaxValue: Double := Utilities.GetArgAsDouble(args, 0, caller);
  if  (Double.IsNaN(lMaxValue))  then
    exit  (Double.NaN);

  for  i: Int32  :=  1  to  args.Length-1  do  begin
    var lValue: Double := Utilities.GetArgAsDouble(args, i, caller);
    if  (Double.IsNaN(lValue))  then
      exit  (Double.NaN);

    lMaxValue := Math.Max(lMaxValue, lValue);
  end;

  exit  (lMaxValue);
end;


method GlobalObject.MathMin(caller: ExecutionContext;  &self: Object;  params args: array of Object): Object;
begin
  if  (length(args) = 0)  then
    exit  (Double.PositiveInfinity);

  if  (args.Length = 1)  then
    exit   (args[0]);

  var lMinValue: Double := Utilities.GetArgAsDouble(args, 0, caller);

  if  (Double.IsNaN(lMinValue))  then
    exit  (Double.NaN);

  for  i: Int32  :=  1 to  args.Length-1  do  begin
    var lValue: Double := Utilities.GetArgAsDouble(args, i, caller);
    if  (Double.IsNaN(lValue))  then
      exit  (Double.NaN);

    lMinValue := Math.Min(lMinValue, lValue);
  end;

  exit  (lMinValue);
end;


method GlobalObject.Mathpow(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Pow(Utilities.GetArgAsDouble(Args, 0, aCaller), Utilities.GetArgAsDouble(Args, 1, aCaller));
end;

method GlobalObject.Mathrandom(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if fRandom = nil then fRandom := new Random;
  exit fRandom.NextDouble;
end;

method GlobalObject.Mathsin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Sin(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathsqrt(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Sqrt(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathtan(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Tan(Utilities.GetArgAsDouble(Args, 0, aCaller));
end;

method GlobalObject.Mathround(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lVal := Utilities.GetArgAsDouble(Args, 0, aCaller);
  // Javascript has a weird kind of rounding
  if (lVal < 0) and (lVal > -0.5) then exit 0;
  exit Math.Floor(lVal + 0.5);
end;

end.