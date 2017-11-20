//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.PascalScript.Internal;

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
    /// <summary>invalid string</summary>
    ErrorInChar,
    EnterInString,
    EOFInString);  

  /// <summary>contains all tokens the tokenizersupports</summary>
  TokenKind = public enum(    
    EOF,

    Error,
    Comment,
    WhiteSpace,

    Identifier,
    SemiColon,
    Comma,
    Period,
    Colon,
    OpenRound,
    CloseRound,
    OpenBlock,
    CloseBlock,
    Assignment,
    Equal,
    NotEqual,
    Greater,
    GreaterEqual,
    Less,
    LessEqual,
    Plus,
    Minus,
    Divide,
    Multiply,
    Integer,
    Real,
    String,
    Char,
    HexInt,
    AddressOf,
    Dereference,
    TwoDots,

    K_and,
    K_array,
    K_begin,
    K_case,
    K_const,
    K_div,
    K_do,
    K_downto,
    K_else,
    K_end,
    K_for,
    K_function,
    K_if,
    K_in,
    K_mod,
    K_not,
    K_of,
    K_or,
    K_procedure,
    K_program,
    K_repeat,
    K_record,
    K_set,
    K_shl,
    K_shr,
    K_then,
    K_to,
    K_type,
    K_until,
    K_uses,
    K_var,
    K_while,
    K_with,
    K_xor,
    K_exit,
    K_class,
    K_constructor,
    K_destructor,
    K_inherited,
    K_private,
    K_public,
    K_published,
    K_protected,
    K_property,
    K_virtual,
    K_override,
    K_As,
    K_Is,
    K_Unit,
    K_Try,
    K_Except,
    K_Finally,
    K_External,
    K_Forward,
    K_Export,
    K_Label,
    K_Goto,
    K_Chr,
    K_Ord,
    K_Interface,
    K_Implementation,
    K_out,
    K_nil,
    K_break,
    K_continue,
    K_true,
    K_false,
    K_result
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
      FCharMap: Array[Byte] of Char;
    var     
    FInput: array of Char;
    FPos, FRow, FLastEnterPos, FLen: Integer;
    FToken: TokenKind;
    FTokenStr: array of Char;
    FPosition: Position := new Position();
    FEndPosition: Position := new Position();
    FLastEndPosition: Position := new Position();
    
    method IdentCompare(aPos: Integer; len: Integer; Data: array of Char): Integer;
    method IsIdentifier(aPos: Integer; len: Integer): TokenKind;
    method IntNext(): Boolean;
    
    class constructor;
  public
    constructor; empty;

    method SaveState: Object;
    method RestoreState(o: Object);

    method SetData(Input: String; Filename: String);
    method Next();

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
  FEndPosition.Col := 1;
  FEndPosition.Row := 1;
  FPosition.&Module := Filename;
  Next()
end;

method Tokenizer.IdentCompare(aPos: Integer; len: Integer; Data: array of Char): Integer;
begin
  for i: Integer := 0 to iif(len > Data.Length, Data.Length, len) -1 do begin
    if Data[i] > FCharMap[ord(FInput[aPos + i])] then exit 1;
    if Data[i] < FCharMap[ord(FInput[aPos + i])] then exit -1;
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
      TokenKind.Comment, 
      TokenKind.WhiteSpace: ;
      else begin
        Stop := true;
        FPosition.Col := lStartRow;
        FPosition.Row := lStartColumn;
        FEndPosition.Col := (FPos + FLen) - FLastEnterPos;
        FEndPosition.Row := Row;
      end;
    end;
  end
end;


method Tokenizer.IntNext(): Boolean;
begin
  var curroffset: Integer := FPos;
  if (FInput[curroffset] in ['$','A'..'Z', 'a'..'z', '_']) then begin
    inc(curroffset);
    while (FInput[curroffset] in ['$','A'..'Z', 'a'..'z', '_', '0'..'9']) do
      inc(curroffset);
    FLen := curroffset - FPos;
    FToken := IsIdentifier(FPos, FLen);
    if FToken = TokenKind.Identifier then
    begin
      FTokenStr := new Char[FLen];
      &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);
    end;
  end else begin // end of "identifier"
    FTokenStr := nil;
    case FInput[curroffset] of
      '/':
      begin
        if FInput[curroffset + 1] = '/' then begin // single line commment
          inc(curroffset);
          while FInput[curroffset] not in [#0, #10, #13] do 
            inc(curroffset);
          FLen := curroffset - FPos;
          FToken := TokenKind.Comment
        end else if FInput[curroffset + 1] = '*' then begin
          curroffset := curroffset + 2;
          //var lHadEnters: Boolean := false;
          while (FInput[curroffset] <> '*') and (FInput[curroffset] <> '/') and (FInput[curroffset] <> #0) do begin
            if FInput[curroffset] in [#13, #10] then begin
              if (FInput[curroffset +1] = #10) and (FInput[curroffset] = #13) then inc(curroffset);
              FLastEnterPos := curroffset;
              //lHadEnters := true;
              inc(FRow);
            end;
            inc(curroffset);
          end;
          
          if FInput[curroffset] = #0 then begin
            if Error <> nil then Error(self, TokenizerErrorKind.CommentError, '');
            FLen := 0;
            exit false;
          end else begin
            FLen := curroffset - FPos + 2;
            FToken := TokenKind.Comment;
          end;
        end else begin
          FLen := 1;
          FToken := TokenKind.Divide
        end;
      end;
      #13,#10:
      begin
        if FInput[curroffset] in [#13, #10] then begin
          if (FInput[curroffset +1] = #10) and (FInput[curroffset] = #13) then inc(curroffset);
          FLastEnterPos := curroffset;
          inc(FRow);
        end;
        inc(curroffset);
        FLen := curroffset - FPos;
        FToken := TokenKind.WhiteSpace;
      end;

      #9, #32:
      begin //whitespace
        inc(curroffset); // 4
        while FInput[curroffset] in [#9, #32] do
        begin
          inc(curroffset);
        end;
        FLen := curroffset - FPos;
        FToken := TokenKind.WhiteSpace;
      end;
      #0:begin
        FLen := 0;
        FToken := TokenKind.EOF;
      end;
      '$':
        begin
          inc(curroffset);

          while (FInput[curroffset] in ['0'..'9', 'a'..'f', 'A'..'F'])
            do inc(curroffset);

          FToken := TokenKind.HexInt;
          FLen := curroffset - FPos;
        end;
      '0'..'9', '.': 
        begin
          if (FInput[curroffset] = '.') and (FInput[curroffset+1] not in ['0'..'9']) then begin
            if FInput[curroffset + 1] = '.' then
            begin
              FLen := 2;
              FToken := TokenKind.TwoDots;
            end else begin 
              FLen := 1;
              FToken := TokenKind.Period;
            end;
          end else begin
            if (FInput[curroffset] = '0') and (FInput[curroffset+1] in['x','X']) then begin
              curroffset := curroffset + 2;
              while FInput[curroffset] in ['0' .. '9', 'A' .. 'F', 'a' ..'f'] do inc(curroffset);
              FToken := TokenKind.HexInt
            end else begin
              var lHasDot: Boolean := FInput[curroffset] = '.';
              inc(curroffset);
              while (FInput[curroffset] in ['0' .. '9']) or ((FInput[curroffset] = '.') and not lHasDot) do begin 
                if FInput[curroffset] = '.' then lHasDot := true;
                inc(curroffset);
              end;
              if FInput[curroffset] in ['e', 'E'] then begin
                inc(curroffset);
                lHasDot := true;
                if FInput[curroffset] in ['+', '-']  then inc(curroffset);
                while (FInput[curroffset] in ['0' .. '9']) do inc(curroffset);
              end;

              if lHasDot then
                FToken := TokenKind.Real
              else
                FToken := TokenKind.Integer;
            end;
            FLen := curroffset - FPos;
            FTokenStr := new Char[FLen];
            &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);
          end;
        end;
      #39:
        begin
          inc(curroffset);
          while true do
          begin
            if (FInput[curroffset] = #0) or (FInput[curroffset] = #13) or (FInput[curroffset] = #10) then Break;
            if (FInput[curroffset] = #39) then
            begin
              if FInput[curroffset+1] = #39 then
                inc(curroffset)
              else
                Break;
            end;
            inc(curroffset);
          end;
          if FInput[curroffset] = #39 then
            FToken := TokenKind.String
          else if FInput[curroffset] = #0 then begin
            if Error <> nil then Error(self, TokenizerErrorKind.EOFInString, '');
            FLen := 0;
            exit false;
          end else begin
              if Error <> nil then Error(self, TokenizerErrorKind.EnterInString, '');
              FLen := 0;
              exit false;
          end;
          FLen := curroffset - FPos + 1;
          FTokenStr := new Char[FLen];
          &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);

        end;

      '#':
        begin
          inc(curroffset);
          if FInput[curroffset] = '$' then
          begin
            inc(curroffset);
            while (FInput[curroffset] in ['A'..'F', 'a'..'f', '0'..'9']) do begin
              inc(curroffset);
            end;
            FToken := TokenKind.Char;
            FLen := curroffset - FPos;
          end else
          begin
            while (FInput[curroffset] in ['0'..'9']) do begin
              inc(curroffset);
            end;
            if FInput[curroffset] in ['A'..'Z', 'a'..'z', '_'] then
            begin
              if Error <> nil then Error(self, TokenizerErrorKind.ErrorInChar, '');
              FLen := 0;
              FToken := TokenKind.Error;
              exit false;
            end else
              FToken := TokenKind.Char;
            FLen := curroffset - FPos;
          end;
          FTokenStr := new Char[FLen];
          &Array.Copy(FInput, FPos, FTokenStr, 0, FLen);
        end;
      '=':
        begin
          FToken := TokenKind.Equal;
          FLen := 1;
        end;
      '>':
        begin
          if FInput[FPos + 1] = '=' then
          begin
            FToken := TokenKind.GreaterEqual;
            FLen := 2;
          end else
          begin
            FToken := TokenKind.Greater;
            FLen := 1;
          end;
        end;
      '<':
        begin
          if FInput[FPos + 1] = '=' then
          begin
            FToken := TokenKind.LessEqual;
            FLen := 2;
          end else
            if FInput[FPos + 1] = '>' then
            begin
              FToken := TokenKind.NotEqual;
              FLen := 2;
            end else
            begin
              FToken := TokenKind.Less;
              FLen := 1;
            end;
        end;
      ')':
        begin
          FToken := TokenKind.CloseRound;
          FLen := 1;
        end;
      '(':
        begin
          if FInput[FPos + 1] = '*' then
          begin
            inc(curroffset);
            while (FInput[curroffset] <> #0) do begin
              if (FInput[curroffset] = '*') and (FInput[curroffset + 1] = ')') then
                Break;
              if FInput[curroffset] = #13 then
              begin
                inc(FRow);
                if FInput[curroffset+1] = #10 then
                  inc(curroffset);
                FLastEnterPos := curroffset +1;
              end else if FInput[curroffset] = #10 then
              begin
                inc(FRow);
                FLastEnterPos := curroffset +1;
              end;
              inc(curroffset);
            end;
            if (FInput[curroffset] = #0) then
            begin
              FToken := TokenKind.Error;
              if Error <> nil then Error(self, TokenizerErrorKind.CommentError, '');
              FLen := 0;
              exit false;
            end else
            begin
              FToken := TokenKind.Comment;
              inc(curroffset, 2);
            end;
            FLen := curroffset - FPos;
          end
          else
          begin
            FToken := TokenKind.OpenRound;
            FLen := 1;
          end;
        end;
      '[':
        begin
          FToken := TokenKind.OpenBlock;
          FLen := 1;
        end;
      ']':
        begin
          FToken := TokenKind.CloseBlock;
          FLen := 1;
        end;
      ',':
        begin
          FToken := TokenKind.Comma;
          FLen := 1;
        end;
      '@':
        begin
          FToken := TokenKind.AddressOf;
          FLen := 1;
        end;
      '^':
        begin
          FToken := TokenKind.Dereference;
          FLen := 1;
        end;
      ';':
        begin
          FToken := TokenKind.SemiColon;
          FLen := 1;
        end;
      ':':
        begin
          if FInput[FPos + 1] = '=' then
          begin
            FToken := TokenKind.Assignment;
            FLen := 2;
          end else
          begin
            FToken := TokenKind.Colon;
            FLen := 1;
          end;
        end;
      '+':
        begin
          FToken := TokenKind.Plus;
          FLen := 1;
        end;
      '-':
        begin
          FToken := TokenKind.Minus;
          FLen := 1;
        end;
      '*':
        begin
          FToken := TokenKind.Multiply;
          FLen := 1;
        end;
      '{':
        begin
          inc(curroffset);
          while (FInput[curroffset] <> #0) and (FInput[curroffset] <> '}') do begin
            if FInput[curroffset] = #13 then
            begin
              inc(FRow);
              if FInput[curroffset+1] = #10 then
                inc(curroffset);
              FLastEnterPos := curroffset + 1;
            end else if FInput[curroffset] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := curroffset + 1;
            end;
            inc(curroffset);
          end;
          if (FInput[curroffset] = #0) then
          begin
            FToken := TokenKind.Error;
            if Error <> nil then Error(self, TokenizerErrorKind.CommentError, '');
            exit false;
          end else
            FToken := TokenKind.Comment;
          FLen := curroffset - FPos + 1;
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

  lItems.Add(new KeywordMap('AND', TokenKind.K_and));
  lItems.Add(new KeywordMap('ARRAY', TokenKind.K_array));
  lItems.Add(new KeywordMap('BEGIN', TokenKind.K_begin));
  lItems.Add(new KeywordMap('CASE', TokenKind.K_case));
  lItems.Add(new KeywordMap('CONST', TokenKind.K_const));
  lItems.Add(new KeywordMap('DIV', TokenKind.K_div));
  lItems.Add(new KeywordMap('DO', TokenKind.K_do));
  lItems.Add(new KeywordMap('DOWNTO', TokenKind.K_downto));
  lItems.Add(new KeywordMap('ELSE', TokenKind.K_else));
  lItems.Add(new KeywordMap('END', TokenKind.K_end));
  lItems.Add(new KeywordMap('FOR', TokenKind.K_for));
  lItems.Add(new KeywordMap('FUNCTION', TokenKind.K_function));
  lItems.Add(new KeywordMap('IF', TokenKind.K_if));
  lItems.Add(new KeywordMap('IN', TokenKind.K_in));
  lItems.Add(new KeywordMap('MOD', TokenKind.K_mod));
  lItems.Add(new KeywordMap('NOT', TokenKind.K_not));
  lItems.Add(new KeywordMap('OF', TokenKind.K_of));
  lItems.Add(new KeywordMap('OR', TokenKind.K_or));
  lItems.Add(new KeywordMap('PROCEDURE', TokenKind.K_procedure));
  lItems.Add(new KeywordMap('PROGRAM', TokenKind.K_program));
  lItems.Add(new KeywordMap('REPEAT', TokenKind.K_repeat));
  lItems.Add(new KeywordMap('RECORD', TokenKind.K_record));
  lItems.Add(new KeywordMap('SET', TokenKind.K_set));
  lItems.Add(new KeywordMap('SHL', TokenKind.K_shl));
  lItems.Add(new KeywordMap('SHR', TokenKind.K_shr));
  lItems.Add(new KeywordMap('THEN', TokenKind.K_then));
  lItems.Add(new KeywordMap('TO', TokenKind.K_to));
  lItems.Add(new KeywordMap('TYPE', TokenKind.K_type));
  lItems.Add(new KeywordMap('UNTIL', TokenKind.K_until));
  lItems.Add(new KeywordMap('USES', TokenKind.K_uses));
  lItems.Add(new KeywordMap('VAR', TokenKind.K_var));
  lItems.Add(new KeywordMap('WHILE', TokenKind.K_while));
  lItems.Add(new KeywordMap('WITH', TokenKind.K_with));
  lItems.Add(new KeywordMap('XOR', TokenKind.K_xor));
  lItems.Add(new KeywordMap('EXIT', TokenKind.K_exit));
  lItems.Add(new KeywordMap('CLASS', TokenKind.K_class));
  lItems.Add(new KeywordMap('CONSTRUCTOR', TokenKind.K_constructor));
  lItems.Add(new KeywordMap('DESTRUCTOR', TokenKind.K_destructor));
  lItems.Add(new KeywordMap('INHERITED', TokenKind.K_inherited));
  lItems.Add(new KeywordMap('PRIVATE', TokenKind.K_private));
  lItems.Add(new KeywordMap('PUBLIC', TokenKind.K_public));
  lItems.Add(new KeywordMap('PUBLISHED', TokenKind.K_published));
  lItems.Add(new KeywordMap('PROTECTED', TokenKind.K_protected));
  lItems.Add(new KeywordMap('PROPERTY', TokenKind.K_property));
  lItems.Add(new KeywordMap('VIRTUAL', TokenKind.K_virtual));
  lItems.Add(new KeywordMap('OVERRIDE', TokenKind.K_override));
  lItems.Add(new KeywordMap('AS', TokenKind.K_As));
  lItems.Add(new KeywordMap('IS', TokenKind.K_Is));
  lItems.Add(new KeywordMap('UNIT', TokenKind.K_Unit));
  lItems.Add(new KeywordMap('TRY', TokenKind.K_Try));
  lItems.Add(new KeywordMap('EXCEPT', TokenKind.K_Except));
  lItems.Add(new KeywordMap('FINALLY', TokenKind.K_Finally));
  lItems.Add(new KeywordMap('EXTERNAL', TokenKind.K_External));
  lItems.Add(new KeywordMap('FORWARD', TokenKind.K_Forward));
  lItems.Add(new KeywordMap('EXPORT', TokenKind.K_Export));
  lItems.Add(new KeywordMap('LABEL', TokenKind.K_Label));
  lItems.Add(new KeywordMap('GOTO', TokenKind.K_Goto));
  lItems.Add(new KeywordMap('CHR', TokenKind.K_Chr));
  lItems.Add(new KeywordMap('ORD', TokenKind.K_Ord));
  lItems.Add(new KeywordMap('INTERFACE', TokenKind.K_Interface));
  lItems.Add(new KeywordMap('IMPLEMENTATION', TokenKind.K_Implementation));
  lItems.Add(new KeywordMap('OUT', TokenKind.K_out));
  lItems.Add(new KeywordMap('NIL', TokenKind.K_nil));
  lItems.Add(new KeywordMap('TRUE', TokenKind.K_true));
  lItems.Add(new KeywordMap('FALSE', TokenKind.K_false));
  lItems.Add(new KeywordMap('BREAK', TokenKind.K_break));
  lItems.Add(new KeywordMap('CONTINUE', TokenKind.K_continue));
  lItems.Add(new KeywordMap('RESULT', TokenKind.K_result));

  lItems.Sort((a, b) -> a.Original.CompareTo(b.Original));
  FIdentifiers := lItems.ToArray;

 FCharMap := new array[Byte] of Char();
 for i: Integer := low(FCharMap) to high(FCharMap) do begin
   FCharMap[i] := Char.ToUpperInvariant(Char(i));
 end;
end;


constructor Tokenizer.KeywordMap(aOriginal: String; aToken: TokenKind);
begin
  Original := aOriginal;
  Chars := Original.ToCharArray();
  Token := aToken;
end;


method Tokenizer.SaveState: Object;
begin
  var lResult := new Object[7];
  lResult[0] := FPos;
  lResult[1] := FRow;
  lResult[2] := FLastEnterPos;
  lResult[3] := FLen;
  lResult[4] := FToken;
  lResult[5] := FTokenStr;
  lResult[6] := FPosition;
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
end;

end.
