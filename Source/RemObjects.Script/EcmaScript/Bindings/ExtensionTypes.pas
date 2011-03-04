{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Text,
  System.Runtime.CompilerServices,
  RemObjects.Script;

type

  ObjectExtensions = public class 
  private
    class method DoubleCompare(aLeft, aRight: Double): Boolean;
  public
    class method SameValue(aLeft, aright: Object): Boolean;
    class method GetEnumerator(anObject: Object): IEnumerator<String>;
  end;

implementation




end.