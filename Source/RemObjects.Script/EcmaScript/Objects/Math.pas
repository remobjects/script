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
    method Mathmax(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathmin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathpow(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method Mathrandom(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
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
  result.Values.Add('LOG2E', PropertyValue.NotAllFlags(Math.Log(Math.e, 2)));
  result.Values.Add('LOG10E', PropertyValue.NotAllFlags(Math.Log(Math.e, 10)));

  result.Values.Add('abs', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'abs', @MathAbs, 1)));
  result.Values.Add('acos', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'acos', @MathACos, 1)));
  result.Values.Add('asin', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'asin', @MathASin, 1)));
  result.Values.Add('atan', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'atin', @MathATan, 1)));
  result.Values.Add('atan2', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'atin2', @MathATan2,2)));
  result.Values.Add('ceil', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'ceil', @MathCeil, 1)));
  result.Values.Add('cos', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'cos', @MathCos, 1)));
  result.Values.Add('exp', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'exp', @MathExp, 1)));
  result.Values.Add('floor', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'floor', @MathFloor, 1)));
  result.Values.Add('log', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'log', @MathLog, 1)));
  result.Values.Add('max', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'max',@MathMax, 2)));
  result.Values.Add('min', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'min', @MathMin, 2)));
  result.Values.Add('pow', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'pow', @MathPow, 1)));
  result.Values.Add('random', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'random', @MathRandom, 0)));
  result.Values.Add('sin', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'sin', @MathSin, 1)));
  result.Values.Add('sqrt', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'sqrt', @MathSQRT, 1)));
  result.Values.Add('tan', PropertyValue.NotAllFlags(new EcmaScriptFunctionObject(self, 'tan', @MathTan, 1)));
end;

method GlobalObject.Mathabs(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Abs(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathacos(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Acos(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathasin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Asin(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathatan(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Atan(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathatan2(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Atan2(Utilities.GetArgAsDouble(Args, 0), Utilities.GetArgAsDouble(Args, 1));
end;

method GlobalObject.Mathceil(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Ceiling(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathcos(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Cos(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathexp(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Exp(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathfloor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Floor(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathlog(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Log(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathmax(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if Length(args) = 0 then exit Double.NegativeInfinity;
  if args.Length = 1 then exit args[0];
  var lMaxValue := Utilities.GetArgAsDouble(Args, 0);
  if Double.IsNaN(lMaxValue) then exit Double.NaN;
  for i: Integer := 1 to args.Length -1 do begin
    var lValue := Utilities.GetArgAsDouble(args, i);
    if Double.IsNaN(lMaxValue) then exit Double.NaN;
    lMaxValue := Math.Max(lMaxValue, lValue);
  end;

  exit lMaxValue;
end;

method GlobalObject.Mathmin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if Length(args) = 0 then exit Double.PositiveInfinity;
  if args.Length = 1 then exit args[0];
  var lMaxValue := Utilities.GetArgAsDouble(Args, 0);
  if Double.IsNaN(lMaxValue) then exit Double.NaN;
  for i: Integer := 1 to args.Length -1 do begin
    var lValue := Utilities.GetArgAsDouble(args, i);
    if Double.IsNaN(lMaxValue) then exit Double.NaN;
    lMaxValue := Math.Max(lMaxValue, lValue);
  end;

  exit lMaxValue;
end;

method GlobalObject.Mathpow(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Pow(Utilities.GetArgAsDouble(Args, 0), Utilities.GetArgAsDouble(Args, 1));
end;

method GlobalObject.Mathrandom(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if fRandom = nil then fRandom := new Random;
  exit fRandom.NextDouble;
end;

method GlobalObject.Mathsin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Sin(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathsqrt(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Sqrt(Utilities.GetArgAsDouble(Args, 0));
end;

method GlobalObject.Mathtan(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  exit Math.Tan(Utilities.GetArgAsDouble(Args, 0));
end;

end.