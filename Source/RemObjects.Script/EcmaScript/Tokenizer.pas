//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript.Internal;

interface
uses
  System,
  System.Collections,
  System.Collections.Generic,
  RemObjects.Script;

type
  /// <summary>Error type</summary>
  TokenizerErrorKind = public enum(
     /// <summary>unknown character</summary>
    UnknownCharacter,
    /// <summary>comment not closed</summary>
    CommentError,
    InvalidEscapeSequence,
    /// <summary>invalid String</summary>
    EOFInString,
    EOFInRegex,
    EnterInRegex);  

  /// <summary>contains all tokens the tokenizersupports</summary>
  TokenKind = public enum(    
    /// <summary>
    /// end of file
    /// </summary>
    EOF,
    /// <summary>An enter</summary>
    LineFeed,
    /// <summary>
    /// tab, space, enter
    /// </summary>
    Whitespace,
    /// <summary>Linecomment</summary>
    LineComment,
    // internal token, will never be returned
    /// <summary>
    /// comments
    /// </summary>
    MultilineComment,
    /// <summary>A comment without any enter in it</summary>
    Comment,
    // internal token, will never be returned
    /// <summary>
    /// error token
    /// </summary>
    
    Error,
    /// <summary>
    /// identifier
    /// </summary>
    
    Identifier,
    /// <summary>
    /// hex number // 0x123abcdefABCDEF
    /// </summary>
    HexNumber,

    /// <summary>
    /// regular number // 0123456789
    /// </summary>
    Number,

    /// <summary>
    /// a String
    /// </summary>
    String,
    SingleQuoteString,

    /// <summary>
    /// Float // 0.2394834
    /// </summary>
    Float,

    /// <summary>
    /// colon
    /// </summary>
    Colon,

    /// <summary>
    /// comma
    /// </summary>
    Comma,

    /// <summary>
    /// semicolon
    /// </summary>    
    Semicolon,
    
    /// <summary>
    /// dot
    /// </summary>
    Dot,
    
    /// <summary>
    /// equal
    /// </summary>
    Equal,
    
    /// <summary>
    /// not equal
    /// </summary>
    NotEqual,
    
    /// <summary>
    /// assign (=)
    /// </summary>
    Assign,
    
    /// <summary>
    /// less
    /// </summary>
    Less,
    
    /// <summary>
    /// greater
    /// </summary>
    Greater,
    
    /// <summary>
    /// less or equal
    /// </summary>
    
    LessOrEqual,
    
    /// <summary>
    /// greater or equal
    /// </summary>
    GreaterOrEqual,
    
    /// <summary>
    /// star *
    /// </summary>
    Multiply,

    /// <summary>
    /// curly open
    /// </summary>
    CurlyOpen,

    /// <summary>
    /// curly close
    /// </summary>
    CurlyClose,

    /// <summary>
    /// opening parenthesis
    /// </summary>
    OpeningParenthesis,

    /// <summary>
    /// closing parenthesis
    /// </summary>
    ClosingParenthesis,

    /// <summary>
    /// opening bracket
    /// </summary>
    OpeningBracket,

    /// <summary>
    /// closing bracket
    /// </summary>
    ClosingBracket,

    /// <summary>
    /// a divide operator /
    /// </summary>
    Divide,

    /// <summary>
    /// a modulus % sign
    /// </summary>
    Modulus,

    /// <summary>
    /// an and sign &amp;
    /// </summary>
    &And,

    /// <summary>
    /// an or sign
    /// </summary>
    &Or,

    /// <summary>
    /// &amp;&amp; logical and
    /// </summary>
    DoubleAnd,

    /// <summary>
    /// || logical or
    /// </summary>
    DoubleOr,

    /// <summary>
    /// a caret ^ (xor)
    /// </summary>
    &Xor,

    /// <summary>
    /// ^^ logical xor
    /// </summary>
    DoubleXor,

    /// <summary>
    /// Tilde ~ (not)
    /// </summary>
    BitwiseNot,

    /// <summary>
    /// plus +
    /// </summary>
    Plus,

    /// <summary>
    /// minus -
    /// </summary>
    Minus,

    /// <summary>
    /// logical not !
    /// </summary>
    &Not,
    

    /// <summary> &lt;&lt; </summary>
    ShiftLeft, // <<
    /// <summary>&gt;&gt;</summary>
    ShiftRightSigned, // >>
    /// <summary>&gt;&gt;&gt;</summary>
    ShiftRightUnsigned, // >>>
    /// <summary>++</summary>
    Increment, // ++
    /// <summary>--</summary>
    Decrement, // --
    /// <summary>===</summary>
    StrictEqual, // ===
    /// <summary>!==</summary>
    StrictNotEqual, // !==
    /// <summary>?</summary>
    ConditionalOperator, // ?
    PlusAssign, // +=
    MinusAssign,// -=
    MultiplyAssign, // *=
    ModulusAssign, // %=
    ShiftLeftAssign, // <<=
    ShiftRightSignedAssign,// >>=
    ShiftRightUnsignedAssign, // >>>=
    AndAssign, // &=
    OrAssign, // |=
    XorAssign, // ^=
    DivideAssign, // /=



    // Following are all Keywords
    K_break,
    K_do,
    K_instanceof,
    K_typeof,
    K_case,
    K_else,
    K_new,
    K_var,
    K_catch,
    K_finally,
    K_return,
    K_void,
    K_continue,
    K_for,
    K_switch,
    K_while,
    K_debugger,
    K_function,
    K_this,
    K_with,
    K_default,
    K_if,
    K_throw,
    K_delete,
    K_in,
    K_try,
    K_null,
    K_true,
    K_false,
    K_get,
    K_set
  );  

  KeywordMap nested in Tokenizer = private class
  private
  public
    constructor(aOriginal: String; aToken: TokenKind);
    Chars: Array of Char; readonly;
    Token: TokenKind; readonly;
    Original: String; readonly;
  end;

  ITokenizer = public interface
    method SetData(Input: String; Filename: String);
    method Next();
    method NextAsRegularExpression(out aString, aModifiers: String); // sets the position after the regex

    property LastWasEnter: Boolean read;
    property Pos: Integer read;
    property Row: Integer read;
    property Col: Integer read;
    property Token: TokenKind read;
    property TokenStr: String read;
    property Position: Position read;
    property EndPosition: Position read;
    property LastEndPosition: Position read;
    property PositionPair: PositionPair read;

    method SaveState: Object;
    method RestoreState(o: Object);
    
    event Error: TokenizerError;
  end;

  Tokenizer = public class(ITokenizer)
  private
    class var     
      FIdentifiers: array of KeywordMap;
    var     
    FInput: array of Char;
    FPos, FRow, FLastEnterPos, FLen: Integer;
    FToken: TokenKind;
    FTokenStr: array of Char;
    FPosition: Position := new Position();
    FEndPosition: Position := new Position();
    FLastEndPosition: Position := new Position();
    fLastWasEnter: Boolean;
    fJSON: Boolean := false;
    method IdentCompare(aPos: Integer; len: Integer; Data: array of Char): Integer;
    method IsIdentifier(aPos: Integer; len: Integer): TokenKind;
    method IntNext(): Boolean;
    
    class constructor;
  public
    constructor; empty;

    class method DecodeString(aString: String): String;

    property JSON: Boolean read fJSON write fJSON;
    method SaveState: Object;
    method RestoreState(o: Object);

    method SetData(Input: String; Filename: String);
    method Next();
    method NextAsRegularExpression(out aString, aModifiers: String); // sets the position after the regex

    property LastWasEnter: Boolean read fLastWasEnter;
    property Pos: Integer read FPos;
    property Row: Integer read FRow;
    property Col: Integer read FPos - FLastEnterPos;
    property Token: TokenKind read FToken;
    property TokenStr: String read iif(FTokenStr = nil, String.Empty, new String(FTokenStr));
    property Position: Position read FPosition;
    property EndPosition: Position read FEndPosition;
    property LastEndPosition: Position read FLastEndPosition;
    property PositionPair: PositionPair read new PositionPair(Position, EndPosition);
    
    event Error: TokenizerError;
  end;

  /// <summary>
  /// Delegate called when the tokenizer
  /// </summary>
  /// <param name="Caller">the tokenizer that caused this</param>
  /// <param name="Kind">the error kind</param>
  /// <param name="Parameter">optional parameter</param>
  
  TokenizerError = public delegate(Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String);

implementation

method Tokenizer.SetData(Input: String; Filename: String);
begin
  FInput := (Input + #0#0#0#0).ToCharArray();
  FLen := 0;
  FPos := 0;
  FRow := 1;
  FLastEnterPos := -1;
  FEndPosition.Pos := 0;
  FEndPosition.Col := 1;
  FEndPosition.Row := 1;
  
  FPosition.&Module := Filename;
  Next()
end;

method Tokenizer.IdentCompare(aPos: Integer; len: Integer; Data: array of Char): Integer;
begin
  for i: Integer := 0 to iif(len > Data.Length, Data.Length, len) -1 do begin
    if Data[i] > FInput[aPos + i] then exit 1;
    if Data[i] < FInput[aPos + i] then exit -1;
  end;
  if len < Data.Length then exit 1;
  if len > Data.Length then exit -1;
  exit 0;
end;


method Tokenizer.IsIdentifier(aPos: Integer; len: Integer): TokenKind;
begin
  var L: Integer := 0;
  var H: Integer := FIdentifiers.Length - 1;
  while L <= H do
  begin
    var curr: Integer := (L + H) / 2;
    case IdentCompare(aPos, len, FIdentifiers[curr].Chars) of
     0:      
       exit FIdentifiers[curr].Token;
      1:begin
        H := curr - 1;
      end;
    -1:begin
        L := curr + 1;
      end;
    end
  end;
  result := TokenKind.Identifier;
end;

method Tokenizer.Next();
begin
  var Stop: Boolean := false;
  fLastWasEnter := false;
  FLastEndPosition := EndPosition;

  while not Stop do
  begin
    FPos := FPos + FLen;
    var lStartRow := Row; // Actual row
    var lStartColumn := Col; 
    if not IntNext() then
    begin
      FToken := TokenKind.Error;
      exit;
    end;
    case FToken of
      TokenKind.LineFeed,
      TokenKind.LineComment,
      TokenKind.MultilineComment: fLastWasEnter := true; 
      TokenKind.Comment, 
      TokenKind.Whitespace: ;
      else begin
        Stop := true;
        FPosition.Col := lStartColumn;
        FPosition.Row := lStartRow;
        FPosition.Pos := FPos;
        FEndPosition.Col := (FPos + FLen) - FLastEnterPos;
        FEndPosition.Row := Row;
        FEndPosition.Pos:= FPos + FLen;
      end;
    end;
  end
end;


method Tokenizer.IntNext(): Boolean;
begin
  var curroffset: Integer := FPos;
  var lHadUnicodeIdentifier := 0;
  if (FInput[curroffset] in ['$','A'..'Z', 'a'..'z', '_']) or 
    ((FInput[curroffset] > #127) and (FInput[curroffset] not in [#133, #160,#$200B,#$FEFF,#$2000 .. #$200B, #$202f, #$205f, #$3000, #$2028, #$2029]))
    or ((FInput[curroffset] = '\') and (FInput[curroffset+1] in ['u', 'U']) and 
    (FInput[curroffset+2] in ['0'..'9','a'..'f', 'A'..'F']) and
    (FInput[curroffset+3] in ['0'..'9','a'..'f', 'A'..'F']) and
    (FInput[curroffset+4] in ['0'..'9','a'..'f', 'A'..'F']) and
    (FInput[curroffset+5] in ['0'..'9','a'..'f', 'A'..'F']))
    
    then begin
    if (FInput[curroffset] = '\') then begin
      inc(curroffset, 5); 
      inc(lHadUnicodeIdentifier);
    end;
    inc(curroffset);

    while (FInput[curroffset] in ['$','A'..'Z', 'a'..'z', '_', '0'..'9']) or 
      ((FInput[curroffset] > #127) and (FInput[curroffset] not in [#133, #160,#$200B,#$FEFF,#$2000 .. #$200B, #$202f, #$205f, #$3000,#$2028, #$2029])) or ((FInput[curroffset] = '\') and (FInput[curroffset+1] in ['u', 'U']) and 
    (FInput[curroffset+2] in ['0'..'9','a'..'f', 'A'..'F']) and
    (FInput[curroffset+3] in ['0'..'9','a'..'f', 'A'..'F']) and
    (FInput[curroffset+4] in ['0'..'9','a'..'f', 'A'..'F']) and
    (FInput[curroffset+5] in ['0'..'9','a'..'f', 'A'..'F'])) do begin
      if (FInput[curroffset] = '\') then begin
        inc(curroffset, 5); 
        inc(lHadUnicodeIdentifier);
      end;
        inc(curroffset);
    end;
    FLen := curroffset - FPos;
    if lHadUnicodeIdentifier > 0 then begin
      FToken := TokenKind.Identifier;
      FTokenStr := new Char[FLen - (5 * lHadUnicodeIdentifier)];
      lHadUnicodeIdentifier := 0;
      var i := 0;
      while i < FLen do begin
        if FInput[FPos+i] = '\' then begin
          FTokenStr[lHadUnicodeIdentifier] := Char(UInt16.Parse(FInput[FPos+i+2] + FInput[FPos+i+3] + FInput[FPos+i+4] + FInput[FPos+i+5], System.Globalization.NumberStyles.HexNumber));
          inc(lHadUnicodeIdentifier);
          inc(i, 6);
        end else begin
          FTokenStr[lHadUnicodeIdentifier] := FInput[FPos+i];
          inc(lHadUnicodeIdentifier);
          inc(i);
        end;
      end;
    end else begin
    FToken := IsIdentifier(FPos, FLen);
      if FToken in [TokenKind.K_get, TokenKind.K_set, TokenKind.Identifier] then
      begin
        FTokenStr := new Char[FLen];
        &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);
      end;
    end;
  end else begin // end of "identifier"
    FTokenStr := nil;
    case FInput[curroffset] of
      '/':
      begin
        if FInput[curroffset + 1] = '/' then begin // single line commment
          inc(curroffset);
          while (FInput[curroffset] not in [#10, #13, #$2028, #$2029]) and not ((FInput[curroffset] = #0) and (curroffset >= FInput.Length - 4)) do 
            inc(curroffset);
          FLen := curroffset - FPos;
          FToken := TokenKind.LineComment
        end else if FInput[curroffset + 1] = '*' then begin
          curroffset := curroffset + 2;
          var lHadEnters: Boolean := false;
          while not ((FInput[curroffset] = '*') and (FInput[curroffset+1] = '/')) do begin
            if FInput[curroffset] in [#13, #10, #$2028, #$2029] then begin
              if (FInput[curroffset +1] = #10) and (FInput[curroffset] = #13) then inc(curroffset);
              FLastEnterPos := curroffset;
              lHadEnters := true;
              inc(FRow);
            end;
            if  (FInput[curroffset] = #0) and (curroffset >= FInput.Length - 4) then break;
            inc(curroffset);
          end;
          
          if FInput[curroffset] = #0 then begin
            if Error <> nil then Error(self, TokenizerErrorKind.CommentError, '');
            FLen := 0;
            exit false;
          end else begin
            FLen := curroffset - FPos + 2;
            if lHadEnters then 
              FToken := TokenKind.MultilineComment
            else
              FToken := TokenKind.Comment;
          end;
        end else if FInput[curroffset+1] = '=' then begin 
          FLen := 2;
          FToken := TokenKind.DivideAssign;
        end else begin
          FLen := 1;
          FToken := TokenKind.Divide
        end;
      end;
      #13,#10, #$2028, #$2029:
      begin
        if FInput[curroffset] in [#13, #10, #$2028, #$2029] then begin
          if (FInput[curroffset +1] = #10) and (FInput[curroffset] = #13) then inc(curroffset);
          FLastEnterPos := curroffset;
          inc(FRow);
        end;
        inc(curroffset);
        FLen := curroffset - FPos;
        FToken := TokenKind.LineFeed;
      end;

      #11, #9, #12, #32, #133, #160, #$FEFF, #$2000 .. #$200B, #$202f, #$205f, #$3000:
      begin //whitespace
        if fJSON and (FInput[curroffset] in [#11]) then begin
          FLen := 0;
          if Error <> nil then Error(self, TokenizerErrorKind.UnknownCharacter, FInput[curroffset].ToString);
          FToken := TokenKind.Error;
          exit false;
        end;

        inc(curroffset); // 
        while FInput[curroffset] in [#9, #12, 
          #11, #32, #133, #160,
          #$200B,
          #$FEFF,#$2000 .. #$200B, #$202f, #$205f, #$3000] do
        begin
          if fJSON and (FInput[curroffset] in [#11]) then begin
            FLen := 0;
            if Error <> nil then Error(self, TokenizerErrorKind.UnknownCharacter, FInput[curroffset].ToString);
            FToken := TokenKind.Error;
            exit false;
          end;
          inc(curroffset);
        end;
        FLen := curroffset - FPos;
        FToken := TokenKind.Whitespace;
      end;
      #0:begin
        FLen := 0;
        FToken := TokenKind.EOF;
      end;
      ':':
        begin
          FLen := 1;
          FToken := TokenKind.Colon;
        end;
      ';':
        begin
          FLen := 1;
          FToken := TokenKind.Semicolon;
        end;
      ',':
        begin
          FLen := 1;
          FToken := TokenKind.Comma;
        end;
      '=':
        begin
          if FInput[curroffset + 1] = '=' then
          begin
            if FInput[curroffset + 2] = '=' then
            begin
              FLen := 3;
              FToken := TokenKind.StrictEqual
            end
            else
            begin
              FLen := 2;
              FToken := TokenKind.Equal
            end;
          end
          else
          begin
            FLen := 1;
            FToken := TokenKind.Assign
          end;
        end;
      '!':
        begin
          if FInput[curroffset + 1] = '=' then
          begin
            if FInput[curroffset + 2] = '=' then
            begin
              FLen := 3;
              FToken := TokenKind.StrictNotEqual
            end else begin
              FLen := 2;
              FToken := TokenKind.NotEqual
            end;
          end
          else
          begin
            FLen := 1;
            FToken := TokenKind.Not
          end;
        end;
      '<':
        begin
          if FInput[curroffset + 1] = '<' then
          begin
            if FInput[curroffset + 2] = '=' then begin
              FLen := 3;
              FToken := TokenKind.ShiftLeftAssign;
            end else begin
              FLen := 2;
              FToken := TokenKind.ShiftLeft;
            end;
          end else if FInput[curroffset + 1] = '=' then
          begin
            FLen := 2;
            FToken := TokenKind.LessOrEqual
          end else begin
            FLen := 1;
            FToken := TokenKind.Less
          end;
        end;
      '>':
        begin
          if FInput[curroffset + 1] = '>' then
          begin
            if FInput[curroffset + 2] = '>' then begin
              if FInput[curroffset + 3] = '=' then begin
                FLen := 4;
                FToken := TokenKind.ShiftRightUnsignedAssign;
              end else begin
                FLen := 3;
                FToken := TokenKind.ShiftRightUnsigned;
              end;
            end else if FInput[curroffset + 2] = '=' then begin
              FLen := 3;
              FToken := TokenKind.ShiftRightSignedAssign;
            end else begin
              FLen := 2;
              FToken := TokenKind.ShiftRightSigned;
            end;
          end else if FInput[curroffset + 1] = '=' then
          begin
            FLen := 2;
            FToken := TokenKind.GreaterOrEqual
          end else begin
            FLen := 1;
            FToken := TokenKind.Greater
          end;
        end;
      '*':
        begin
          if FInput[curroffset + 1] = '=' then begin
            FLen := 2;
            FToken := TokenKind.MultiplyAssign;
          end else begin
            FLen := 1;
            FToken := TokenKind.Multiply;
          end;
        end;
      '{':
        begin
          FLen := 1;
          FToken := TokenKind.CurlyOpen;
        end;
      '}':
        begin
          FLen := 1;
          FToken := TokenKind.CurlyClose;
        end;
      '(':
        begin
          FLen := 1;
          FToken := TokenKind.OpeningParenthesis;
        end;
      ')':
        begin
          FLen := 1;
          FToken := TokenKind.ClosingParenthesis;
        end;
      '[':
        begin
          FLen := 1;
          FToken := TokenKind.OpeningBracket;
        end;
      ']':
      begin
        FLen := 1;
        FToken := TokenKind.ClosingBracket;
        end;

      '%':
        begin
          if FInput[curroffset+1] = '=' then begin
            FLen := 2;
            FToken := TokenKind.ModulusAssign;
          end else begin
            FLen := 1;
            FToken := TokenKind.Modulus;
          end;
        end;
      '&':
        begin
          if FInput[curroffset + 1] = '=' then
          begin
            FLen := 2;
            FToken := TokenKind.AndAssign
          end
          else
          if FInput[curroffset + 1] = '&' then
          begin
            FLen := 2;
            FToken := TokenKind.DoubleAnd
          end
          else
          begin
            FLen := 1;
            FToken := TokenKind.And
          end;
        end;

      '|':
        begin
          if FInput[curroffset + 1] = '=' then
          begin
            FLen := 2;
            FToken := TokenKind.OrAssign
          end
          else
          if FInput[curroffset + 1] = '|' then
          begin
            FLen := 2;
            FToken := TokenKind.DoubleOr
          end
          else
          begin
            FLen := 1;
            FToken := TokenKind.Or
          end;
        end;
      '^':
        begin
          if FInput[curroffset+1] = '=' then begin
            FLen := 2;
            FToken := TokenKind.XorAssign;
          end else begin
            FLen := 1;
            FToken := TokenKind.Xor;
          end;
        end;
      '-':
        begin
          if FInput[curroffset+1] = '-' then begin
            FLen := 2;
            FToken := TokenKind.Decrement;
          end else if FInput[curroffset+1] = '=' then begin
            FLen := 2;
            FToken := TokenKind.MinusAssign;
          end else begin
            FLen := 1;
            FToken := TokenKind.Minus;
          end;
        end;
      '~':
        begin
          FLen := 1;
          FToken := TokenKind.BitwiseNot;
        end;
      '?':
        begin
          FLen := 1;
          FToken := TokenKind.ConditionalOperator;
        end;
      '+':
        begin
          if FInput[curroffset+1] = '+' then begin
            FLen := 2;
            FToken := TokenKind.Increment;
          end else 
          if FInput[curroffset+1] = '=' then begin
            FLen := 2;
            FToken := TokenKind.PlusAssign;
          end else begin
            FLen := 1;
            FToken := TokenKind.Plus;
          end;
        end;
      '0'..'9', '.': 
        begin
          if (FInput[curroffset] = '.') and (FInput[curroffset+1] not in ['0'..'9']) then begin
            FLen := 1;
            FToken := TokenKind.Dot;
          end else begin
            if (FInput[curroffset] = '0') and (FInput[curroffset+1] in['x','X']) then begin
              curroffset := curroffset + 2;
              while FInput[curroffset] in ['0' .. '9', 'A' .. 'F', 'a' ..'f'] do inc(curroffset);
              FToken := TokenKind.HexNumber
            end else begin
              var lHasDot: Boolean := FInput[curroffset] = '.';
              inc(curroffset);
              while (FInput[curroffset] in ['0' .. '9']) or ((FInput[curroffset] = '.') and not lHasDot) do begin 
                if FInput[curroffset] = '.' then lHasDot := true;
                inc(curroffset);
              end;
              if FInput[curroffset] in ['E', 'e'] then begin
                lHasDot := true;
                inc(curroffset);
                if FInput[curroffset] in ['+','-'] then inc(curroffset);
                while FInput[curroffset] in ['0' .. '9'] do begin 
                  inc(curroffset);
                end;
              end;

              if lHasDot then
                FToken := TokenKind.Float
              else
                FToken := TokenKind.Number
            end;
            FLen := curroffset - FPos;
            FTokenStr := new Char[FLen];
            &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);
          end;
        end;
      '"':
        begin
          inc(curroffset);
          while (FInput[curroffset] <> #0) and (FInput[curroffset] <> '"') do
          begin
            
            if FInput[curroffset] = '\' then
            begin
              inc(curroffset);
              case FInput[curroffset] of
                'x': 
                  if (FInput[curroffset+1] = #0) or (FInput[curroffset +2] = #0) then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.EOFInString, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else if (FInput[curroffset+1] not in ['0'..'9', 'A'..'F', 'a'..'f']) or (FInput[curroffset +2] not in ['0'..'9', 'A'..'F', 'a'..'f'])then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.InvalidEscapeSequence, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else inc(curroffset,2);
                'u':
                  if (FInput[curroffset+1] = #0) or (FInput[curroffset +2] = #0) or (FInput[curroffset +3] = #0)or (FInput[curroffset +4] = #0)then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.EOFInString, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else if (FInput[curroffset+1] not in ['0'..'9', 'A'..'F', 'a'..'f']) or (FInput[curroffset +2] not in ['0'..'9', 'A'..'F', 'a'..'f'])or (FInput[curroffset +3] not in ['0'..'9', 'A'..'F', 'a'..'f'])or (FInput[curroffset +4] not in ['0'..'9', 'A'..'F', 'a'..'f'])then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.InvalidEscapeSequence, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else inc(curroffset,4);
                #13: begin
                  if FInput[curroffset+1] = #10 then inc(curroffset);
                end;

                #10, '''', 'b','t','n','r','v','f','"', #9, '0', '\': ;
                else begin
                  //if Error <> nil then Error(self, TokenizerErrorKind.InvalidEscapeSequence, '');
                  //FLen := curroffset - FPos;
                end;
              end; // case
            end else if fJSON and( FInput[curroffset] in [#$0 .. #$1f]) then begin
              if Error <> nil then Error(self, TokenizerErrorKind.InvalidEscapeSequence, '');
              FLen := curroffset - FPos;
              exit false;
            end;

            inc(curroffset);
          end;
          FLen := curroffset - FPos + 1;
          FToken := TokenKind.String;
          FTokenStr := new Char[FLen];
          &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);
          if FInput[curroffset] = #0 then begin
            if Error <> nil then Error(self, TokenizerErrorKind.EOFInString, '');
            FLen := curroffset - FPos;
          end;
        end;
      #39:
        begin
          inc(curroffset);
          while (FInput[curroffset] <> #0) and (FInput[curroffset] <> #39) do
          begin
            
            if FInput[curroffset] = '\' then
            begin
              inc(curroffset);
              case FInput[curroffset] of
                'x', 'X': 
                  if (FInput[curroffset+1] = #0) or (FInput[curroffset +2] = #0) then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.EOFInString, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else if (FInput[curroffset+1] not in ['0'..'9', 'A'..'F', 'a'..'f']) or (FInput[curroffset +2] not in ['0'..'9', 'A'..'F', 'a'..'f'])then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.InvalidEscapeSequence, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else inc(curroffset,2);
                'u', 'U':
                  if (FInput[curroffset+1] = #0) or (FInput[curroffset +2] = #0) or (FInput[curroffset +3] = #0)or (FInput[curroffset +4] = #0)then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.EOFInString, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else if (FInput[curroffset+1] not in ['0'..'9', 'A'..'F', 'a'..'f']) or (FInput[curroffset +2] not in ['0'..'9', 'A'..'F', 'a'..'f'])or (FInput[curroffset +3] not in ['0'..'9', 'A'..'F', 'a'..'f'])or (FInput[curroffset +4] not in ['0'..'9', 'A'..'F', 'a'..'f'])then begin
                    if Error <> nil then Error(self, TokenizerErrorKind.InvalidEscapeSequence, '');
                    FLen := curroffset - FPos;
                    exit false;
                  end else inc(curroffset,4);
                #13: begin
                  if FInput[curroffset+1] = #10 then inc(curroffset);
                end;

                #10, 'b','t','n','r','v','f','"', #9, '0', '\', '''': ;
                else begin
                  if Error <> nil then Error(self, TokenizerErrorKind.InvalidEscapeSequence, '');
                  FLen := curroffset - FPos;
                  exit false;
                end;
              end; // case
            end;
            inc(curroffset);
          end;
          FLen := curroffset - FPos + 1;
          FToken := TokenKind.SingleQuoteString; 
          FTokenStr := new Char[FLen];
          &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);
        end;
     else begin
        FLen := 0;
        if Error <> nil then Error(self, TokenizerErrorKind.UnknownCharacter, FInput[curroffset].ToString);
        FToken := TokenKind.Error;
        exit false;
      end;
    end
  end;
  result := true;
end;

class constructor Tokenizer;
begin
  var lItems: List<KeywordMap> := new List<Tokenizer.KeywordMap>;

  lItems.Add(new KeywordMap('break', TokenKind.K_break));
  lItems.Add(new KeywordMap('do', TokenKind.K_do));
  lItems.Add(new KeywordMap('instanceof', TokenKind.K_instanceof));
  lItems.Add(new KeywordMap('typeof', TokenKind.K_typeof));
  lItems.Add(new KeywordMap('case', TokenKind.K_case));
  lItems.Add(new KeywordMap('else', TokenKind.K_else));
  lItems.Add(new KeywordMap('new', TokenKind.K_new));
  lItems.Add(new KeywordMap('var', TokenKind.K_var));
  lItems.Add(new KeywordMap('catch', TokenKind.K_catch));
  lItems.Add(new KeywordMap('finally', TokenKind.K_finally));
  lItems.Add(new KeywordMap('return', TokenKind.K_return));
  lItems.Add(new KeywordMap('void', TokenKind.K_void));
  lItems.Add(new KeywordMap('continue', TokenKind.K_continue));
  lItems.Add(new KeywordMap('for', TokenKind.K_for));
  lItems.Add(new KeywordMap('switch', TokenKind.K_switch));
  lItems.Add(new KeywordMap('while', TokenKind.K_while));
  lItems.Add(new KeywordMap('debugger', TokenKind.K_debugger));
  lItems.Add(new KeywordMap('function', TokenKind.K_function));
  lItems.Add(new KeywordMap('this', TokenKind.K_this));
  lItems.Add(new KeywordMap('with', TokenKind.K_with));
  lItems.Add(new KeywordMap('default', TokenKind.K_default));
  lItems.Add(new KeywordMap('if', TokenKind.K_if));
  lItems.Add(new KeywordMap('throw', TokenKind.K_throw));
  lItems.Add(new KeywordMap('delete', TokenKind.K_delete));
  lItems.Add(new KeywordMap('in', TokenKind.K_in));
  lItems.Add(new KeywordMap('try', TokenKind.K_try));
  lItems.Add(new KeywordMap('null', TokenKind.K_null));
  lItems.Add(new KeywordMap('true', TokenKind.K_true));
  lItems.Add(new KeywordMap('false', TokenKind.K_false));
  lItems.Add(new KeywordMap('get', TokenKind.K_get));
  lItems.Add(new KeywordMap('set', TokenKind.K_set));

  lItems.Sort((a, b) -> a.Original.CompareTo(b.Original));
  FIdentifiers := lItems.ToArray;
end;


constructor Tokenizer.KeywordMap(aOriginal: String; aToken: TokenKind);
begin
  Original := aOriginal;
  Chars := Original.ToCharArray();
  Token := aToken;
end;


class method Tokenizer.DecodeString(aString: String): String;
begin
  var lRes: System.Text.StringBuilder := new System.Text.StringBuilder(aString.Length);
  var i := 1;
  while i < aString.Length -1 do begin
    case aString[i] of
      '\': begin
        inc(i);
        case aString[i] of 
          'x': begin
            lRes.Append(chr(Int32.Parse(aString.Substring(i+1, 2), System.Globalization.NumberStyles.HexNumber)));
            inc(i, 2);
          end;
          'u': begin
            lRes.Append(chr(Int32.Parse(aString.Substring(i+1, 4), System.Globalization.NumberStyles.HexNumber)));
            inc(i, 4);
          end;
          'b': lRes.Append(#8);
          't': lRes.Append(#9);
          'n': lRes.Append(#10);
          'r': lRes.Append(#13);
          'v': lRes.Append(#11);
          'f': lRes.Append(#12);
          '"': lRes.Append('"');
          #39: lRes.Append(#39);
          '\': lRes.Append('\');
          '0': lRes.Append(#0);
          #10: begin
            // do nothing
          end;
          #13: begin
            if aString[i+1] = #10 then inc(i);
          end
        else
          lRes.Append(aString[i]);
        end; // case
        inc(i);
      end
    else 
      lRes.Append(aString[i]);
      inc(i);
    end; // case
  end;
  result := lRes.ToString();
end;

method Tokenizer.NextAsRegularExpression(out aString, aModifiers: String);
begin
  FPos := FPos + FLen; // should be 1 at this point, the / 
  var curroffset := FPos;
  while FInput[curroffset] <> '/' do begin
    if FInput[curroffset] in [#13, #10, #$2028,  #$2029] then begin
      if Error <> nil then Error(self, TokenizerErrorKind.EnterInRegex, '');
      FLen := curroffset - FPos + 1;
      FToken := TokenKind.Error;
      exit;
    end;

    if (FInput[curroffset] = #0) and (curroffset >= FInput.Length - 4) then begin
      if Error <> nil then Error(self, TokenizerErrorKind.EOFInRegex, '');
      FLen := curroffset - FPos + 1;
      FToken := TokenKind.Error;
      exit;
    end;
    if FInput[curroffset] = '\' then begin
      inc(curroffset);
      if FInput[curroffset] in [#13, #10, #$2028,  #$2029] then begin
        if Error <> nil then Error(self, TokenizerErrorKind.EnterInRegex, '');
        FLen := curroffset - FPos + 1;
        FToken := TokenKind.Error;
        exit;
      end;
    end;
    inc(curroffset);
  end;
  aString := new String(FInput, FPos, curroffset - FPos);
  inc(curroffset);
  FPos := curroffset;
  FLen := 0; 
  Next;
  if FToken = TokenKind.Identifier then begin
    aModifiers := TokenStr;
    Next;
  end else aModifiers := '';
end;

method Tokenizer.SaveState: Object;
begin
  var lResult := new Object[8];
  lResult[0] := FPos;
  lResult[1] := FRow;
  lResult[2] := FLastEnterPos;
  lResult[3] := FLen;
  lResult[4] := FToken;
  lResult[5] := FTokenStr;
  lResult[6] := FPosition;
  lResult[7] := fLastWasEnter;
  result := lResult;
end;

method Tokenizer.RestoreState(o: Object);
begin
  var lArr := array of Object(o);
  FPos := Integer(lArr[0]);
  FRow := Integer(lArr[1]);
  FLastEnterPos := Integer(lArr[2]);
  FLen := Integer(lArr[3]);
  FToken := TokenKind(lArr[4]);
  FTokenStr := array of Char(lArr[5]);
  FPosition := RemObjects.Script.Position(lArr[6]);
  fLastWasEnter := Boolean(lArr[7]);
end;

end.
