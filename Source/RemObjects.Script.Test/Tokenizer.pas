{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace ROEcmaScript.Test;

interface

uses
  RemObjects.Script.EcmaScript.Internal,
  XUnit.*;

type
  TokenizerTest = public class
  private
  protected
  public
    [Fact]
    method SetTextSkipsFirstWhitespace;
    [Fact]
    method SetTextProperlyParsesTheFirstToken;
    [Fact]
    method NextMovesToTheNextToken;
    [Fact]
    method NextMovesToRightColumn;
    [Fact]
    method NextMovesToRightNewRow;
    [Fact]
    method DoubleNextEndsUpAtEOF;
    [Fact]
    method TokenizerFailsAtWrongChar;
  end;
  
implementation

method TokenizerTest.SetTextSkipsFirstWhitespace;
begin
  var lScript := "   Test";
  var lTok: ITokenizer := new Tokenizer;
  lTok.SetData(lScript, '');
  assert.Equal(lTok.Token, TokenKind.Identifier);
  assert.Equal(lTok.TokenStr, 'Test');
end;

method TokenizerTest.SetTextProperlyParsesTheFirstToken;
begin
  var lScript := "Test";
  var lTok: ITokenizer := new Tokenizer;
  lTok.SetData(lScript, '');
  assert.Equal(lTok.Token, TokenKind.Identifier);
  assert.Equal(lTok.TokenStr, 'Test');
end;

method TokenizerTest.NextMovesToTheNextToken;
begin
  var lScript := "Test Test";
  var lTok: ITokenizer := new Tokenizer;
  lTok.SetData(lScript, '');
  assert.Equal(lTok.Token, TokenKind.Identifier);
  assert.Equal(lTok.TokenStr, 'Test');
  lTok.Next;
  assert.Equal(lTok.Token, TokenKind.Identifier);
  assert.Equal(lTok.TokenStr, 'Test');
  lTok.Next;
  assert.Equal(lTok.Token, TokenKind.EOF);
end;

method TokenizerTest.NextMovesToRightColumn;
begin
  var lScript := "   Test";
  var lTok: ITokenizer := new Tokenizer;
  lTok.SetData(lScript, '');
  assert.Equal(lTok.Col,4);
end;

method TokenizerTest.NextMovesToRightNewRow;
begin
  var lScript := "Test"#13#10'Test';
  var lTok: ITokenizer := new Tokenizer;
  lTok.SetData(lScript, '');
  assert.Equal(lTok.Col,1);
  assert.Equal(lTok.Row,1);
  ltok.Next;
  assert.Equal(lTok.Col,1);
  assert.Equal(lTok.Row,2);
end;

method TokenizerTest.DoubleNextEndsUpAtEOF;
begin
  var lScript := "   Test";
  var lTok: ITokenizer := new Tokenizer;
  lTok.SetData(lScript, '');
  lTok.Next;
  assert.Equal(lTok.Token, TokenKind.EOF);
end;

method TokenizerTest.TokenizerFailsAtWrongChar;
begin
  var lFailed := false;
  var lTok: ITokenizer := new Tokenizer;
  lTok.Error+= method (Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String); 
    begin
      if Kind = TokenizerErrorKind.UnknownCharacter then lFailed := true;
    end;
  var lScript := #1;
  lTok.SetData(lScript, '');
  Assert.Equal(lTok.Token, TokenKind.Error);
  Assert.Equal(lFailed, true);
end;

end.