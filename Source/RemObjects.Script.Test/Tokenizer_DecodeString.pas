{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace ROEcmaScript.Test;

interface
uses
  RemObjects.Script.EcmaScript.Internal,
  xUnit.*;

type
  Tokenizer_DecodeString = public class
  private
  protected
  public
    [Fact]
    method TestDecodeCharWithEscapedAsciiChar_ReturnsAsciiChar;
    [Fact]
    method TestDecodeCharWithEscapedUnicodeChar_ReturnsUnicodeChar;  
    [Fact]
    method TestDecodeCharWithChr0InIt_ReturnsChr0WithoutQuotes;
    [Fact]
    method TestDecodeSimpleChar_ReturnsWithoutQuotes;
    [Fact]
    method TestDecideSimpleCharWithEscapedSingleQuote_ReturnsSingleQuote;
    [Fact]
    method TestDecodeStringWithChr0InIt_ReturnsChr0WithoutQuotes;
    [Fact]
    method TestDecodeSimpleString_ReturnsWithoutQuotes;
    [Fact]
    method TestDecodeStringWithEscapedQuote_ReturnsStringWithOneQuote;
    [Fact]
    method TestDecodeStringWithEscapedAsciiChar_ReturnsAsciiChar;
    [Fact]
    method TestDecodeStringWithEscapedUnicodeChar_ReturnsUnicodeChar;  
  end;
  
implementation

method Tokenizer_DecodeString.TestDecodeCharWithChr0InIt_ReturnsChr0WithoutQuotes;
begin
  assert.Equal(Tokenizer.DecodeString('''\0'''), ''+#0);
end;

method Tokenizer_DecodeString.TestDecodeSimpleString_ReturnsWithoutQuotes;
begin
  assert.Equal(Tokenizer.DecodeString('"User Name"'), 'User Name');
end;

method Tokenizer_DecodeString.TestDecodeStringWithEscapedQuote_ReturnsStringWithOneQuote;
begin
  assert.Equal(Tokenizer.DecodeString('"My \"String"'), 'My "String');
end;

method Tokenizer_DecodeString.TestDecodeStringWithEscapedAsciiChar_ReturnsAsciiChar;
begin
  assert.Equal(Tokenizer.DecodeString('"\xbb"'), ''+#$bb);
end;

method Tokenizer_DecodeString.TestDecodeStringWithEscapedUnicodeChar_ReturnsUnicodeChar;
begin
  assert.Equal(Tokenizer.DecodeString('"\ubbbb"'), ''+#$bbbb);
end;

method Tokenizer_DecodeString.TestDecodeStringWithChr0InIt_ReturnsChr0WithoutQuotes;
begin
  assert.Equal(Tokenizer.DecodeString('"\0"'), ''+#0);
end;

method Tokenizer_DecodeString.TestDecodeSimpleChar_ReturnsWithoutQuotes;
begin
  assert.Equal(Tokenizer.DecodeString(#39'c'#39), ''+'c');
end;

method Tokenizer_DecodeString.TestDecideSimpleCharWithEscapedSingleQuote_ReturnsSingleQuote;
begin
  assert.Equal(Tokenizer.DecodeString(#39'\'#39#39), ''+#39);
end;

method Tokenizer_DecodeString.TestDecodeCharWithEscapedAsciiChar_ReturnsAsciiChar;
begin
  assert.Equal(Tokenizer.DecodeString('''\xbb'''), ''+#$bb);
end;

method Tokenizer_DecodeString.TestDecodeCharWithEscapedUnicodeChar_ReturnsUnicodeChar;
begin
  assert.Equal(Tokenizer.DecodeString('''\ubbbb'''), ''+#$bbbb);
end;

end.