{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface


uses
  System.Collections.Generic,
  System.Text,
  Microsoft,
  RemObjects.Script,
  RemObjects.Script.EcmaScript.Internal;


type
  GlobalObject = public partial class(EcmaScriptObject)
  public
    method CreateArray: EcmaScriptObject;

    method ArrayIsArray(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayToLocaleString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayConcat(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayJoin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayPop(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayPush(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayReverse(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayShift(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArraySlice(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArraySort(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArraySplice(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayUnshift(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayIndexOf(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayEvery(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayLastIndexOf(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArraySome(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayMap(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayForeach(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayFilter(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayReduce(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
    method ArrayReduceRight(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;

    method DefaultCompare(aCaller: ExecutionContext; aSelf: Object; params Args: Array of Object): Object;
  end;
  EcmaScriptArrayObject = public class(EcmaScriptObject)
  private
    fItems: List<Object> := new List<Object>;
  public
    constructor(aRoot: GlobalObject; aLength: Integer);
    constructor(aCapacity: Integer; aRoot: GlobalObject);

    class var &Constructor: System.Reflection.ConstructorInfo := typeof(EcmaScriptArrayObject).GetConstructor([typeof(Integer), typeof(GlobalObject)]); readonly; 
    class var Method_AddValue: System.Reflection.MethodInfo := typeof(EcmaScriptArrayObject).GetMethod('AddValue', [typeof(Object)]); readonly;
    method AddValues(aItems: Array of Object): EcmaScriptArrayObject;
    method AddValue(aItem: Object);
    method Put(aExecutionContext: ExecutionContext; aName: String; aValue: Object; aThrow: Boolean): Object; override;
    method Get(aExecutionContext: ExecutionContext; aFlags: Integer; aName: String): Object; override;
    method PutIndex(aName: Int32; aValue: Object): Object; override;
    method GetIndex(aName: Int32): Object; override;
    property ToArray: array of Object read fItems.ToArray;
    property Items: List<Object> read fItems;
    method GetNames: IEnumerator<String>; override;
  end;


implementation

method GlobalObject.CreateArray: EcmaScriptObject;
begin
  result := EcmaScriptObject(Get(nil, 0, 'Array'));
  if result <> nil then exit;

  result := new EcmaScriptObject(self, nil, &Class := 'Array');
  Values.Add('Array', PropertyValue.NotEnum(Result));

  ArrayPrototype := new EcmaScriptFunctionObject(self, 'Array', @ArrayCtor, 1, &Class := 'Array');
  ArrayPrototype.Prototype := ObjectPrototype;
  
  result.values['prototype'] := PropertyValue.NotAllFlags(ArrayPrototype);
  result.Values.Add('isArray', PRopertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'isArray', @ArrayIsArray, 1)));

  ArrayPrototype.Values['constructor'] := PropertyValue.NotEnum(ArrayPrototype);
  ArrayPrototype.Values.Add('toString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toString', @ArrayToString, 0)));
  ArrayPrototype.Values.Add('toLocaleString', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'toLocaleString', @ArrayToLocaleString, 0)));
  ArrayPrototype.Values.Add('concat', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'concat', @ArrayConcat, 1)));
  ArrayPrototype.Values.Add('join', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'join', @ArrayJoin, 1)));
  ArrayPrototype.Values.Add('pop', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'pop', @ArrayPop, 0)));
  ArrayPrototype.Values.Add('push', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'push', @ArrayPush, 1)));
  ArrayPrototype.Values.Add('reverse', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'reverse', @ArrayReverse, 0)));
  ArrayPrototype.Values.Add('shift', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'shift', @ArrayShift, 0)));
  ArrayPrototype.Values.Add('slice', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'slice', @ArraySlice, 2)));
  ArrayPrototype.Values.Add('sort', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'sort', @ArraySort, 1)));
  ArrayPrototype.Values.Add('splice', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'splice', @ArraySplice, 2)));
  ArrayPrototype.Values.Add('unshift', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'unshift', @ArrayUnshift, 1)));



  ArrayPrototype.Values.Add('indexOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'indexOf', @ArrayindexOf, 1)));
  ArrayPrototype.Values.Add('lastIndexOf', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'lastIndexOf', @ArraylastIndexOf, 1)));
  ArrayPrototype.Values.Add('every', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'every', @Arrayevery, 1)));
  ArrayPrototype.Values.Add('some', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'some', @Arraysome, 1)));
  ArrayPrototype.Values.Add('forEach', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'forEach', @ArrayforEach, 1)));
  ArrayPrototype.Values.Add('map', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'map', @ArrayMap, 1)));
  ArrayPrototype.Values.Add('filter', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'filter', @Arrayfilter, 1)));
  ArrayPrototype.Values.Add('reduce', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'reduce', @Arrayreduce, 1)));
  ArrayPrototype.Values.Add('reduceRight', PropertyValue.NotEnum(new EcmaScriptFunctionObject(self, 'reduceRight', @ArrayreduceRight, 1)));
end;


method GlobalObject.ArrayCtor(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  if Args.Length = 1 then begin
    result := new EcmaScriptArrayObject(self, Utilities.GetArgAsInteger(Args, 0)); // create a new array of length arg
  end else begin
    result := new EcmaScriptArrayObject(self, 0).AddValues(Args);
  end;
end;

method GlobalObject.ArrayToString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf :=  Utilities.ToObject(aCaller, aSelf);
  var lJoin := EcmaScriptBaseFunctionObject(lSelf.Get('join'));
  if lJoin = nil then exit ObjectToString(aCaller,aSelf);
  exit lJoin.CallEx(aCaller, aSelf);
end;

method GlobalObject.ArrayConcat(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := Utilities.ToObject(aCaller, aSelf);
  var lRes: EcmaScriptArrayObject;
  lRes := new EcmaScriptArrayObject(self, 0);
  for i: Integer := 0 to Utilities.GetObjAsInteger(lSelf.Get('length')) -1 do begin
    lRes.Items.Add(lSelf.Get(aCaller, 3, i.ToString()));
  end;

  for each el in Args do begin
    if el is EcmaScriptArrayObject then begin
      lRes.Items.AddRange(EcmaScriptArrayObject(el).Items);
    end else
      lRes.Items.Add(el);
  end;
  result := lRes;
end;

method GlobalObject.ArrayJoin(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSep := Utilities.GetArgAsString(Args, 0);
  if (lSep = nil) then lSep := ',';
  var lSelf := Utilities.ToObject(aCaller, aSelf);
  var lRes := new StringBuilder;
  for i: Integer := 0 to Utilities.GetObjAsInteger(lSelf.Get('length')) -1 do begin
    if i <> 0 then lRes.Append(lSep);
    var lItem := Utilities.GetObjAsString(lSelf.Get(aCaller, 3, i.ToString()));
    if (lItem = nil) then lItem := '';
    lRes.Append(lItem);
  end;
  exit lRes.ToString;
end;

method GlobalObject.ArrayPop(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  if lSelf.Items.Count = 0 then exit Undefined.Instance;
  result := lSelf.Items[lSelf.Items.Count -1];
  lSelf.Items.RemoveAt(lSelf.Items.Count -1);
end;

method GlobalObject.ArrayPush(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  //if lSelf.Items.Count = 0 then exit Undefined.Instance;
  for each el in args do 
    lSelf.Items.Add(el);
  exit lSelf.Items.Count;
end;

method GlobalObject.ArrayReverse(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  lSelf.Items.Reverse;
  exit lSelf;
end;

method GlobalObject.ArrayShift(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  if lSelf.Items.Count = 0 then exit Undefined.Instance;
  result := lSelf.Items[0];
  lSelf.Items.RemoveAt(0);
end;

method GlobalObject.ArraySlice(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  var lStart := Utilities.GetArgAsInteger(Args, 0);
  var lObj := Utilities.GetArg(Args, 1);
  var lEnd := Iif((lObj = nil) or (lObj = Undefined.Instance), Int32.MaxValue, Utilities.GetObjAsInteger(lObj));
  if lStart < 0 then begin
    lStart := lSelf.Items.Count + lStart;
    if lStart < 0 then 
      lStart := 0;
  end;

  if lEnd < 0 then begin 
    lEnd := lSelf.Items.Count + lEnd;
    if lEnd < 0 then lEnd := 0;
  end;
  if lEnd < lStart then lEnd := lStart;
  if lStart > lSelf.Items.Count then lStart := lSelf.Items.Count;
  if lEnd > lSelf.Items.Count then lEnd := lSelf.Items.Count;

  var lRes := new EcmaScriptArrayObject(self, 0);
  for i: Integer := 0 to lEnd - lStart do begin
    lRes.Items.Add(lSelf.Items[lStart+i]);
  end;
  exit lRes;
end;

method GlobalObject.ArraySort(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  var lFunc := EcmaScriptFunctionObject(Utilities.GetArg(Args, 0));
  var lDel := lFunc:&Delegate;
  if lDel = nil then begin
    lDel := @DefaultCompare;
  end;

  lSelf.Items.Sort(
    method(x, y: Object): Integer begin
      exit Utilities.GetObjAsInteger(lDel(aCaller, lSelf, x, y));
    end);
end;

method GlobalObject.ArraySplice(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  var lStart := Utilities.GetArgAsInteger(Args, 0);
  var lEnd := Utilities.GetArgAsInteger(Args, 1);
  if lStart < 0 then begin
    lStart := lSelf.Items.Count + lStart;
    if lStart < 0 then 
      lStart := 0;
  end;
  if lStart > lSelf.Items.Count then lStart := lSelf.Items.Count;
  var lRes := new EcmaScriptArrayObject(self, 0);
  for i: Integer := 0 to lStart -1 do begin
    lRes.Items.Add(lSelf.Items[i]);
  end;
  for i: Integer := 0 to Length(Args) -3 do begin
    lRes.Items.Add(Args[i+2]);
  end;
  for i: Integer := lStart + lEnd to lSelf.Items.Count -1 do begin
    lRes.Items.Add(lSelf.Items[i]);
  end;

  exit lRes;

end;

method GlobalObject.ArrayUnshift(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lSelf := EcmaScriptArrayObject(aSelf);
  if lSelf = nil then exit Undefined.Instance;
  if lSelf.Items.Count = 0 then exit Undefined.Instance;
  for each el in args index n do 
    lSelf.Items.Insert(n, el);
  exit lSelf.Items.Count;
end;

method GlobalObject.DefaultCompare(aCaller: ExecutionContext; aSelf: Object; params Args: Array of Object): Object;
begin
  var lLeft := args[0];
  var lRight := args[1];
  if lLeft = lRight then exit 0;
  if lLeft = Undefined.Instance then exit 1;
  if lRight = Undefined.Instance then exit -1;
  if lLeft = nil then exit 1;
  if lRight = nil then exit -1;

  if (lLeft is String) or (lRight is String) then 
    exit String.Compare(Utilities.GetObjAsString(lLeft), Utilities.GetObjAsString(lRight));
  if lLeft is EcmaScriptObject then 
    exit iif(lRight is EcmaScriptObject, 1, 0);
  if lRight is EcmaScriptObject then 
    exit -1;
  exit Utilities.GetObjAsDouble(lLeft).CompareTo(Utilities.GetObjAsDouble(lRight));
end;


method GlobalObject.ArrayToLocaleString(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  if lObj = nil then RaiseNativeError(NativeErrorType.ReferenceError, 'Object type expected');
  var lLen := Utilities.GetObjAsInteger(lObj.Get(aCaller, 0, 'length'));
  var lRes := new StringBuilder;
  for i: Integer := 0 to lLen -1 do begin
    var lVal := Utilities.ToObject(aCaller, lObj.Get(aCaller, 2, i.ToString));
    var lData: string;
    if lVal = nil then begin
      lData := String.Empty;
    end else begin
      var lLocale := EcmaSCriptFunctionObject(lVAl.Get('toLocaleString'));
      if lLocale = nil then RaiseNativeError(NativeErrorType.ReferenceError, 'element '+i+' in array does not have a callable toLocaleString');
      lData := Utilities.GetObjAsString(lLocale.CallEx(aCaller, lVal));
    end;
    
    if i <> 0 then lRes.Append(',');
    lREs.Append(lData);
  end;
  exit lRes.ToString;
end;

method GlobalObject.ArrayIsArray(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lEl := EcmaScriptArrayObject(Utilities.GetArg(Args, 0));
  if lEl = nil then exit false;
  exit lEl.Class = 'Array';
end;

method GlobalObject.ArrayIndexOf(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lElement := utilities.GetArg(Args, 0);
  var lStart := Utilities.GetArgAsInteger(args, 1);
  if lStart >= lLen then exit -1;
  if lStart < 0 then lStart := lLen + lStart;
  while lStart < lLen do begin
    var lIndex := lStart.ToString;
    if lObj.HasProperty(lIndex) then
      if Boolean(Operators.StrictEqual(lObj.Get(aCaller, 2, lIndex), lElement)) then exit lStart;
    lStart := lStart + 1;
  end;
  exit -1;
end;

method GlobalObject.ArrayEvery(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lCallback := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 0));
  var lCallbackThis := coalesce(UTilities.GetArg(args, 1), Undefined.Instance);
  if lCallback = nil then RaiseNativeError(nativeErrorType.TypeError, 'Delegate expected');
  for i: Integer := 0 to lLen -1 do begin
    var lIndex := i.ToString;
    if lObj.HasProperty(lIndex) then
      if not Utilities.GetObjAsBoolean(lCallback.CallEx(aCaller, lCallbackThis, lObj.Get(aCaller, 2, lIndex), i, lObj)) then exit false;
  end;
  exit true;
end;

method GlobalObject.ArrayLastIndexOf(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lElement := utilities.GetArg(Args, 0);
  var lStart := if Args.length >= 2 then Utilities.GetArgAsInteger(args, 1) else lLen;
  if lLen = 0 then exit false;
  if lStart >= lLen then lStart := lLen -1;
  if lStart < 0 then lStart := lLen + lStart;
  while lStart >= 0 do begin
    var lIndex := lStart.ToString;
    if lObj.HasProperty(lIndex) then
      if Boolean(Operators.StrictEqual(lObj.Get(aCaller, 2, lIndex), lElement)) then exit lStart;
    lStart := lStart - 1;
  end;
  exit -1;
end;

method GlobalObject.ArraySome(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lCallback := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 0));
  var lCallbackThis := coalesce(UTilities.GetArg(args, 1), Undefined.Instance);
  if lCallback = nil then RaiseNativeError(nativeErrorType.TypeError, 'Delegate expected');
  for i: Integer := 0 to lLen -1 do begin
    var lIndex := i.ToString;
    if lObj.HasProperty(lIndex) then
      if Utilities.GetObjAsBoolean(lCallback.CallEx(aCaller, lCallbackThis, lObj.Get(aCaller, 2, lIndex), i, lObj)) then exit true;
  end;
  exit false;
end;

method GlobalObject.ArrayMap(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lCallback := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 0));
  var lCallbackThis := coalesce(UTilities.GetArg(args, 1), Undefined.Instance);
  if lCallback = nil then RaiseNativeError(nativeErrorType.TypeError, 'Delegate expected');
  var lRes := new EcmaScriptArrayObject(lLen, self);
  for i: Integer := 0 to lLen -1 do begin
    var lIndex := i.ToString;
    if lObj.HasProperty(lIndex) then begin
      lRes.AddValue(lCallback.CallEx(aCaller, lCallbackThis, lObj.Get(aCaller, 2, lIndex), i, lObj));
    end;
  end;
  exit lRes;
end;

method GlobalObject.ArrayForeach(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lCallback := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 0));
  var lCallbackThis := coalesce(UTilities.GetArg(args, 1), Undefined.Instance);
  if lCallback = nil then RaiseNativeError(nativeErrorType.TypeError, 'Delegate expected');
  for i: Integer := 0 to lLen -1 do begin
    var lIndex := i.ToString;
    if lObj.HasProperty(lIndex) then
      lCallback.CallEx(aCaller, lCallbackThis, lObj.Get(aCaller, 2, lIndex), i, lObj);
  end;
  exit Undefined.Instance;
end;

method GlobalObject.ArrayFilter(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lCallback := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 0));
  var lCallbackThis := coalesce(UTilities.GetArg(args, 1), Undefined.Instance);
  if lCallback = nil then RaiseNativeError(nativeErrorType.TypeError, 'Delegate expected');
  var lRes := new EcmaScriptArrayObject(lLen, self);
  for i: Integer := 0 to lLen -1 do begin
    var lIndex := i.ToString;
    if lObj.HasProperty(lIndex) then begin
      var lGet := lObj.Get(aCaller, 2, lIndex);
      if Utilities.GetObjAsBoolean(lCallback.CallEx(aCaller, lCallbackThis, lGet, i, lObj)) then
        lRes.AddValue(lGet);
    end;
  end;
  exit lRes;
end;

method GlobalObject.ArrayReduce(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lCallback := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 0));
  if lCallback = nil then RaiseNativeError(nativeErrorType.TypeError, 'Delegate expected');
  var lInitialValue := Utilities.GetArg(args, 1);
  var lGotInitial := false;
  if args.Length >= 2 then 
    lGotInitial := true;
  var k := 0;
  if not lGotInitial then begin
    while k < lLen do begin
      var lKey := k.ToString;
      inc(k);
      if lObj.HasProperty(lKey) then begin
        lGotInitial := true;
        lInitialValue := lObj.Get(aCaller, 2, lKey);
        break;
      end;
    end;
  end;
  if not lGotInitial then
    RaiseNativeError(NativeErrorType.TypeError, 'Empty array');
  while k < lLen do begin
    var lKey := k.ToString;
    if lObj.HasProperty(lKey) then
    lInitialValue := lCallback.CallEx(aCaller, Undefined.Instance, lInitialValue, lObj.Get(aCaller, 2, lKey), k, lObj);

    inc(k);
  end;
  exit lInitialValue;
end;

method GlobalObject.ArrayReduceRight(aCaller: ExecutionContext;aSelf: Object; params Args: array of Object): Object;
begin
  var lObj := Utilities.ToObject(aCaller, aSelf);
  var lLen := UTilities.GetObjAsInteger(lObj.Get('length'));
  var lCallback := EcmaScriptBaseFunctionObject(Utilities.GetArg(args, 0));
  if lCallback = nil then RaiseNativeError(nativeErrorType.TypeError, 'Delegate expected');
  var lInitialValue := Utilities.GetArg(args, 1);
  var lGotInitial := false;
  if args.Length >= 2 then 
    lGotInitial := true;
  var k := lLen -1;
  if not lGotInitial then begin
    while k >= 0 do begin
      var lKey := k.ToString;
      dec(k);
      if lObj.HasProperty(lKey) then begin
        lGotInitial := true;
        lInitialValue := lObj.Get(aCaller, 2, lKey);
        break;
      end;
    end;
  end;
  if not lGotInitial then
    RaiseNativeError(NativeErrorType.TypeError, 'Empty array');
  while k >= 0 do begin
    var lKey := k.ToString;
    if lObj.HasProperty(lKey) then
    lInitialValue := lCallback.CallEx(aCaller, Undefined.Instance, lInitialValue, lObj.Get(aCaller, 2, lKey), k, lObj);

    dec(k);
  end;
  exit lInitialValue;
end;

constructor EcmaScriptArrayObject(aRoot: GlobalObject; aLength: Integer);
begin
  inherited constructor(aRoot, aRoot.ArrayPrototype);
  &Class := 'Array';
  if aLength > 0 then begin
    fItems.Capacity := aLength;
    while fItems.Count < aLength do fItems.Add(Undefined.Instance);
  end;
end;


method EcmaScriptArrayObject.Put(aExecutionContext: ExecutionContext; aName: String; aValue: Object; aThrow: Boolean): Object; 
begin
  if aName = 'length' then begin
    var lLength := Utilities.GetObjAsInteger(aValue);
    if lLength < 0 then lLength := 0;
    if lLength < fItems.Count then 
      fItems.RemoveRange(lLength, fItems.Count - lLength)
    else begin
      if lLength < fItems.Capacity  then fItems.Capacity := lLength;
      while fItems.Count < lLength do fItems.Add(Undefined.Instance);
    end;
    exit lLength;
  end else begin
    var lIndex: Integer;
    if Int32.TryParse(aname, out lIndex) then
      exit PutIndex(lIndex, aValue)
    else
      exit inherited Put(aExecutionContext, aName, aValue);
  end;
end;

method EcmaScriptArrayObject.Get(aExecutionContext: ExecutionContext; aFlags: Integer; aName: String): Object;
begin
  if aName = 'length' then exit fItems.Count;
  var lIndex: Integer;
  if Int32.TryParse(aname, out lIndex) then
    Result := GetIndex(lIndex)
  else
    Result := inherited Get(aExecutionContext, aFlags, aName);
end;

method EcmaScriptArrayObject.PutIndex(aName: Int32; aValue: Object): Object;
begin
  if aName < 0 then raise new IndexOutOfRangeException;
  if aName >= fItems.Count then begin
    if aName >= fItems.Capacity then fItems.Capacity := aName;
    while fItems.Count <= aName do fItems.Add(Undefined.Instance);
  end;
  fItems[aName] := aValue;
  exit aValue;
end;

method EcmaScriptArrayObject.GetIndex(aName: Int32): Object;
begin
  if (aName < 0) or (aName >= fItems.Count) then exit Undefined.Instance;
  result := fItems[aName];
end;


method EcmaScriptArrayObject.AddValues(aItems: Array of Object): EcmaScriptArrayObject;
begin
  var lNewLength  := fItems.Count + length(aItems);
  if fItems.Capacity < lNewLength then fItems.Capacity := lNewLength;
  for i: Integer := 0 to Length(aItems) -1 do fItems.Add(aItems[i]);
  result := self;
end;


constructor EcmaScriptArrayObject(aCapacity: Integer; aRoot: GlobalObject);
begin
  constructor(aRoot, 0);
  fItems.Capacity := aCapacity;
end;

method EcmaScriptArrayObject.AddValue(aITem: Object);
begin
  fItems.Add(aItem);
end;

method EcmaScriptArrayObject.GetNames: IEnumerator<String>;
begin
  var lItems := new List<string>;
  var lCurr: EcmaScriptObject := self;
  for i: Integer := 0 to Items.Count -1 do
    lItems.Add(i.ToString());
  while assigned(lCurr) do begin
    for each el in lCurr.Values do begin
      if PropertyAttributes.Enumerable in el.Value.Attributes then begin
        if not lItems.Contains(el.Key) then lItems.Add(el.Key);
      end;
    end;
    lCurr := lCurr.Prototype;
  end;
  exit System.Linq.Enumerable.Where(lItems, a-> HasProperty(a)).GetEnumerator;
end;

end.