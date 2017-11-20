//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.PascalScript.Internal;

interface
uses
  System.Collections,
  RemObjects.Script,
  RemObjects.Script.PascalScript,
  RemObjects.Script.Properties,
  System.Collections.ObjectModel,
  System.Collections.Generic;

type
  ParserErrorKind = public enum (Custom, 
    UnknownCharacter,
    CommentError,
    ErrorInChar,
    EOFInString,
    UnexpectedEndOfFile,
    IdentifierExpected,
    SemicolonExpected,
    BeginExpected,
    EndExpected,
    InterfaceExpected,
    ImplementationExpected,
    SyntaxError,
    DotExpected,
    ColonExpected,
    EqualExpected,
    CloseRoundExpected,
    OfExpected,
    CloseBlockExpected,
    UntilExpected,
    DoExpected,
    ThenExpected,
    ToDowntoExpected,
    FinallyExceptExpected,
    OpeningParenthesisExpected);
  
  ParserError = public class(ParserMessage)
  private
    fMessage: String;
    fError: ParserErrorKind;
  public
    constructor(aPosition: Position; anError: ParserErrorKind; aMessage: String);
    property Error: ParserErrorKind read fError;
    property Message: String read fMessage;
    method IntToString: String; override;
    property Code: Integer read Integer(fError); override;
    property IsError: Boolean read true; override;
  end;

  RemObjects.Script.PascalScript.ParserOptions  = public flags (None = 0, AllowUnit = 1, AllowNoBegin = 2, AllowNoEnd = 8);
  Parser = public class
  private
    fTok: ITokenizer;
    fMessages: List<ParserMessage>;
    fMessagesWrapper: ReadOnlyCollection<ParserMessage>;
    method Tok_Error(Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String);
    method ExpectToken(aToken: TokenKind; aError: ParserErrorKind): Boolean;
    method ExpectToken(aToken: array of TokenKind; aError: ParserErrorKind): Boolean;
    method Error(aError: ParserErrorKind; aParam: String);
  protected
    method ParseParameters(aParenthesis: Boolean): IList<Expression>;
    method ParseUses: UsesBlock;
    method ParseBegin: BlockStatement;
    method ParseStatement: Statement;
    method ParseGoto: GotoStatement;
    method ParseWith: WithStatement;
    method ParseTry: TryStatement;
    method ParseRepeat: RepeatStatement;
    method ParseFor: ForStatement;
    method ParseWhile: WhileStatement;
    method ParseCase: CaseStatement;
    method ParseExit: ExitStatement;
    method ParseIf: IfStatement;
    method ParseBreak: BreakStatement;
    method ParseContinue: ContinueStatement;
    method ParseAssignment: AssignmentStatement;
    method ParseTypes: TypeBlock;
    method ParseFunction(aInterface: Boolean): FunctionBlock;
    method ParseLabels: LabelBlock;
    method ParseVars: VariableBlock;
    method ParseTypeRef(aNamed: Boolean): TypeReference;
    method ParseConsts: ConstantBlock;
    method ParseExpression: Expression;
    method ParseSimpleExpression: Expression;
    method ParseTerm: Expression;
    method ParseFactor: Expression;
    method ParseRest(aSelf: Expression): Expression;
    method ParseString: StringExpression;
    method ParseVariableDeclaration: VariableDeclaration;
    method ParseRecordDeclaration: RecordDeclaration;
    method ParseEnumDeclaration: EnumDeclaration;
    method ParseFunctionDeclaration: FunctionPointerDeclaration;
    method ParseArrayDeclaration: ArrayDeclaration;
    method ParseSetDeclaration: SetDeclaration;
    method ParseParameterDeclarations: List<ParameterDeclaration>;
    method ParseBodyBlock(aItems: List<BodyBlock>; aInterface: Boolean);
  public
    constructor;
    
    property Options: ParserOptions;
    method Parse(aTokenizer: ITokenizer): ProgramBlock;

    property Messages: ReadOnlyCollection<ParserMessage> read fMessagesWrapper;
  end;
  
implementation


constructor ParserError(aPosition: Position; anError: ParserErrorKind; aMessage: String);
begin
  inherited constructor(aPosition);
  fError := anError;
  fMessage := aMessage;
end;

method ParserError.IntToString: String;
begin
  case fError of
    ParserErrorKind.Custom: result := fMessage;
    ParserErrorKind.UnknownCharacter: result := Resources.eUnknownCharacter;
    ParserErrorKind.CommentError: result := Resources.eCommentError;
    ParserErrorKind.ErrorInChar: result := Resources.eErrorInCharacter;
    ParserErrorKind.EOFInString: result := Resources.eEOFInString;
    ParserErrorKind.UnexpectedEndOfFile: result := Resources.eUnexpectedEndOfFile;
    ParserErrorKind.IdentifierExpected: result := Resources.eIdentifierExpected;
    ParserErrorKind.SemicolonExpected: result := Resources.eSemicolonExpected;
    ParserErrorKind.EndExpected: result := Resources.eEndExpected;
    ParserErrorKind.BeginExpected: result := Resources.eBeginExpected;
    ParserErrorKind.InterfaceExpected: result := Resources.eInterfaceExpected;
    ParserErrorKind.ImplementationExpected: result := Resources.eImplementationExpected;
    ParserErrorKind.SyntaxError: result := Resources.eSyntaxError;
    ParserErrorKind.DotExpected: result := Resources.eDotExpected;
    ParserErrorKind.ColonExpected: result := Resources.eColonExpected;
    ParserErrorKind.EqualExpected: result := Resources.eEqualExpected;
    ParserErrorKind.CloseRoundExpected: result := Resources.eClosingParenthesisExpected;
    ParserErrorKind.OfExpected: result := Resources.eOfExpected;
    ParserErrorKind.CloseBlockExpected: result := Resources.eClosingBracketExpected;
    ParserErrorKind.UntilExpected: result := Resources.eUntilExpected;
    ParserErrorKind.DoExpected: result := Resources.eDoExpected;
    ParserErrorKind.ThenExpected: result := Resources.eThenExpected;
    ParserErrorKind.ToDowntoExpected: result := Resources.eToDowntoExpected;
    ParserErrorKind.FinallyExceptExpected: result := Resources.eFinallyExceptExpected;
    ParserErrorKind.OpeningParenthesisExpected: result := Resources.eOpeningParenthesisExpected;
  else
    result := 'Unknown error';
  end; // case
end;


constructor Parser;
begin
  fMessages := new List<ParserMessage>;
  fMessagesWrapper := new ReadOnlyCollection<ParserMessage>(fMessages);
end;

method Parser.Parse(aTokenizer: ITokenizer): ProgramBlock;
begin
  fTok := aTokenizer;
  fTok.Error += Tok_Error;
  fMessages.Clear;
  var lPos := fTok.Position;
  try
    var lIsUnit := false;
    var lName: String;
    var lItems: List<BodyBlock> := new List<BodyBlock>;
    if ((ParserOptions.AllowUnit in Options) and (fTok.Token = TokenKind.K_Unit)) or (fTok.Token = TokenKind.K_program) then begin
      lIsUnit := fTok.Token = TokenKind.K_Unit;
      fTok.Next;
      if ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then begin
        lName := fTok.TokenStr;
        fTok.Next;
      end;
      if ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then begin
        fTok.Next;
      end;
    end;
    if lIsUnit then begin
      if not ExpectToken(TokenKind.K_Interface, ParserErrorKind.InterfaceExpected) then exit;
      var lNewPos := fTok.Position;
      fTok.Next;
      var lNewItems := new List<BodyBlock>;
      if fTok.Token = TokenKind.K_uses then lNewItems.Add(ParseUses);
      ParseBodyBlock(lNewItems, true);
      lItems.Add(new InterfaceBlock(new PositionPair(lNewPos, fTok.LastEndPosition), lNewItems));
      if not ExpectToken(TokenKind.K_Implementation, ParserErrorKind.InterfaceExpected) then exit;
      lNewPos := fTok.Position;
      fTok.Next;
      lNewItems := new List<BodyBlock>;
      if fTok.Token = TokenKind.K_uses then lNewItems.Add(ParseUses);
      ParseBodyBlock(lNewItems, false);
      lItems.Add(new ImplementationBlock(new PositionPair(lNewPos, fTok.LastEndPosition), lNewItems));

      if fTok.Token = TokenKind.K_begin then begin
        var lItem := ParseBegin;
        if lItem = nil then exit;
        lItems.Add(new MainBeginBlock(lItem.PositionPair, lItem));
        if fTok.Token = TokenKind.Period then begin
          fTok.Next;
          // Done!
        end else Error(ParserErrorKind.DotExpected, '');
      end else if ParserOptions.AllowNoBegin not in Options then begin
        Error(ParserErrorKind.BeginExpected, '');
        exit;
      end else if fTok.Token = TokenKind.K_end then begin
        fTok.Next;
        if fTok.Token <> TokenKind.Period then Error(ParserErrorKind.DotExpected, '');
      end else if ParserOptions.AllowNoEnd not in Options then
        Error(ParserErrorKind.EndExpected, '')
      else if fTok.Token <> TokenKind.EOF then
        Error(ParserErrorKind.SyntaxError, '');
    end else begin
      ParseBodyBlock(lItems, false);
      if fTok.Token = TokenKind.K_begin then begin
        var lItem := ParseBegin;
        if lItem = nil then exit;
        lItems.Add(new MainBeginBlock(lItem.PositionPair, lItem));
        if fTok.Token = TokenKind.Period then begin
          fTok.Next;
          // Done!
        end else Error(ParserErrorKind.DotExpected, '');
      end else if ParserOptions.AllowNoBegin not in Options then begin
        Error(ParserErrorKind.BeginExpected, '');
        exit;
      end else if fTok.Token = TokenKind.K_end then begin
        fTok.Next;
        if fTok.Token <> TokenKind.Period then Error(ParserErrorKind.DotExpected, '');
      end else if ParserOptions.AllowNoEnd not in Options then
        Error(ParserErrorKind.EndExpected, '')
      else if fTok.Token <> TokenKind.EOF then
        Error(ParserErrorKind.SyntaxError, '');
    end;
    result := new ProgramBlock(new PositionPair(lPos, fTok.LastEndPosition), lIsUnit, lName, lItems);
  finally
    fTok.Error -= Tok_Error;
  end;
end;

method Parser.Tok_Error(Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String);
begin
  case Kind of 
    TokenizerErrorKind.CommentError: Error(ParserErrorKind.CommentError, '');
    TokenizerErrorKind.EOFInString: Error(ParserErrorKind.EOFInString, '');
    TokenizerErrorKind.ErrorInChar: Error(ParserErrorKind.ErrorInChar, '');
    TokenizerErrorKind.UnknownCharacter: Error(ParserErrorKind.UnknownCharacter, '');
  else
    Error(ParserErrorKind(Int32.MaxValue), '');
  end; // case
end;

method Parser.ExpectToken(aToken: TokenKind; aError: ParserErrorKind): Boolean;
begin
  if fTok.Token = aToken then begin
    result := true;
  end else begin
    Error(aError, '');
    result := false;
  end;
end;

method Parser.ExpectToken(aToken: array of TokenKind; aError: ParserErrorKind): Boolean;
begin
  if Array.IndexOf<TokenKind>(aToken, fTok.Token) >= 0 then begin
    result := true;
  end else begin
    Error(aError, '');
    result := false;
  end;
end;


method Parser.Error(aError: ParserErrorKind; aParam: String);
begin
  fMessages.Add(new ParserError(fTok.Position, aError, aParam));
end;

method Parser.ParseBodyBlock(aItems: List<BodyBlock>; aInterface: Boolean);
begin
  loop begin
    case fTok.Token of
      TokenKind.K_Label: aItems.Add(ParseLabels);// LabelBlock
      TokenKind.K_var: aItems.Add(ParseVars); // VariableBlock
      TokenKind.K_const: aItems.Add(ParseConsts); // ConstBlock
      TokenKind.K_type: aItems.Add(ParseTypes); 
      TokenKind.K_function,
      TokenKind.K_procedure: aItems.Add(ParseFunction(aInterface));
      else Break;
    end;
  end;
end;

method Parser.ParseUses: UsesBlock;
begin
  var lPos := fTok.Position;
  var lUses: List<String> := new List<String>;
  fTok.Next;
  loop begin
    if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then break;
    lUses.Add(fTok.TokenStr);
    fTok.Next;
    if fTok.Token = TokenKind.SemiColon then begin
      fTok.Next;
      break;
    end;
    if not ExpectToken(TokenKind.Comma, ParserErrorKind.SemicolonExpected) then break;
    fTok.Next;
  end;
  exit new UsesBlock(new PositionPair(lPos, fTok.LastEndPosition), lUses);
end;

method Parser.ParseLabels: LabelBlock;
begin
  var lPos := fTok.Position;
  var lLabels: List<String> := new List<String>;
  fTok.Next;
  loop begin
    if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then break;
    lLabels.Add(fTok.TokenStr);
    fTok.Next;
    if fTok.Token = TokenKind.SemiColon then begin
      fTok.Next;
      break;
    end;
    if not ExpectToken(TokenKind.Comma, ParserErrorKind.SemicolonExpected) then break;
    fTok.Next;
  end;
  exit new LabelBlock(new PositionPair(lPos, fTok.LastEndPosition), lLabels);
end;

method Parser.ParseVars: VariableBlock;
begin
  var lPos := fTok.Position;
  var lVars: List<VariableDeclaration> := new List<VariableDeclaration>;
  var lNames: List<String> := new List<String>;
  fTok.Next;


  repeat
    var lPositem := fTok.Position;
    if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then break;
    lNames.Add(fTok.TokenStr);
    fTok.Next;
    while fTok.Token = TokenKind.Comma do begin
      fTok.Next;
      if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then break;
      lNames.Add(fTok.TokenStr);
      fTok.Next;
    end;
    if not ExpectToken(TokenKind.Colon, ParserErrorKind.ColonExpected) then break;
    fTok.Next;
    var lType := ParseTypeRef(false);
    for each el in lNames do 
      lVars.Add(new VariableDeclaration(new PositionPair(lPositem, fTok.LastEndPosition), el, lType));
    lNames.Clear;
    
    if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then break;
    fTok.Next;
    
  until fTok.Token <> TokenKind.Identifier;

  exit new VariableBlock(new PositionPair(lPos, fTok.LastEndPosition), lVars);
end;

method Parser.ParseConsts: ConstantBlock;
begin
  var lPos := fTok.Position;
  var lConsts: List<ConstantDeclaration> := new List<ConstantDeclaration>;
  fTok.Next;


  repeat
    var lPositem := fTok.Position;
    if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then break;
    var lName := fTok.TokenStr;
    var lType: TypeReference;
    fTok.Next;
    if fTok.Token = TokenKind.Colon then begin
      fTok.Next;
      lType := ParseTypeRef(false);
    end else 
      lType := nil;
    if not ExpectToken(TokenKind.Equal, ParserErrorKind.EqualExpected) then break;
    fTok.Next;
    var lValue := ParseExpression;
    
    lConsts.Add(new ConstantDeclaration(new PositionPair(lPositem, fTok.LastEndPosition), lName, lType, lValue));
    
    if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then break;
    fTok.Next;
    
  until fTok.Token <> TokenKind.Identifier;

  exit new ConstantBlock(new PositionPair(lPos, fTok.LastEndPosition), lConsts);
end;

method Parser.ParseTypes: TypeBlock;
begin
  var lPos := fTok.Position;
  var lTypes: List<TypeDeclaration> := new List<TypeDeclaration>;
  fTok.Next;


  repeat
    var lPositem := fTok.Position;
    if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then break;
    var lName := fTok.TokenStr;
    //var lType: TypeReference;
    fTok.Next;
    if not ExpectToken(TokenKind.Equal, ParserErrorKind.EqualExpected) then break;
    fTok.Next;
    var lValue := ParseTypeRef(true);
    
    lTypes.Add(new TypeDeclaration(new PositionPair(lPositem, fTok.LastEndPosition), lName, lValue));
    
    if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then break;
    fTok.Next;
    
  until fTok.Token <> TokenKind.Identifier;

  exit new TypeBlock(new PositionPair(lPos, fTok.LastEndPosition), lTypes);
end;

method Parser.ParseTypeRef(aNamed: Boolean): TypeReference;
begin
  case fTok.Token of
    TokenKind.K_record: 
      if aNamed then
        exit ParseRecordDeclaration
      else Error(ParserErrorKind.SyntaxError,'');
    TokenKind.K_set:
      if aNamed then
        exit ParseSetDeclaration
      else Error(ParserErrorKind.SyntaxError,'');
    TokenKind.OpenRound:
      if aNamed then
        exit ParseEnumDeclaration
      else Error(ParserErrorKind.SyntaxError,'');
    TokenKind.K_function,
    TokenKind.K_procedure: 
      if aNamed then
        exit ParseFunctionDeclaration
      else Error(ParserErrorKind.SyntaxError,'');
    TokenKind.K_array: exit ParseArrayDeclaration;
    TokenKind.Identifier: begin
      result := new TypeNameReference(fTok.PositionPair, fTok.TokenStr);
      fTok.Next;
    end
  else
    Error(ParserErrorKind.SyntaxError,'');
  end;
end;
method Parser.ParseRecordDeclaration: RecordDeclaration;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lList := new List<VariableDeclaration>;
  loop begin
    var lVar := ParseVariableDeclaration;
    if lVar = nil then break;
    lList.Add(lVar);
    if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then break;
    if fTok.Token = TokenKind.K_end then begin
      fTok.Next;
      break;
    end;
  end;
  result := new RecordDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lList);
end;

method Parser.ParseVariableDeclaration: VariableDeclaration;
begin
  var lPos := fTok.Position;
  if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then exit nil;
  var lName := fTok.TokenStr;
  fTok.Next;
  if not ExpectToken(TokenKind.Colon, ParserErrorKind.ColonExpected) then exit nil;
  fTok.Next;
  var lType := ParseTypeRef(false);
  if lType = nil then exit nil;
  result := new VariableDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lName, lType);
end;

method Parser.ParseEnumDeclaration: EnumDeclaration;
begin
  var lPos := fTok.Position;
  var lNames := new List<EnumValue>();
  fTok.Next;
  loop begin
    if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then exit nil;
    var lItemPos := fTok.Position;
    var lName := fTok.TokenStr;
    fTok.Next;
    var lValue:Expression;
    if fTok.Token = TokenKind.Equal then begin
      fTok.Next;
      lValue := ParseExpression;
    end else lValue := nil;
    lNames.Add(new EnumValue(new PositionPair(lItemPos, fTok.LastEndPosition), lName, lValue));


    if fTok.Token = TokenKind.CloseRound then begin
      fTok.Next;
      break;
    end;
    if not ExpectToken(TokenKind.Comma, ParserErrorKind.CloseRoundExpected) then exit nil;
  end;
  result := new EnumDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lNames);
end;

method Parser.ParseSetDeclaration: SetDeclaration;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if not ExpectToken(TokenKind.K_of, ParserErrorKind.OfExpected) then exit nil;
  if fTok.Token = TokenKind.OpenRound then begin
    var lNames := new List<EnumValue>();
    fTok.Next;
    loop begin
      if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then exit nil;
      var lItemPos := fTok.Position;
      var lName := fTok.TokenStr;
      fTok.Next;
      var lValue:Expression;
      if fTok.Token = TokenKind.Equal then begin
        fTok.Next;
        lValue := ParseExpression;
      end else lValue := nil;
      lNames.Add(new EnumValue(new PositionPair(lItemPos, fTok.LastEndPosition), lName, lValue));


      if fTok.Token = TokenKind.CloseRound then begin
        fTok.Next;
        break;
      end;
      if not ExpectToken(TokenKind.Comma, ParserErrorKind.CloseRoundExpected) then exit nil;
    end;
    result := new SetDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lNames);
  end else begin

    var lRef := ParseTypeRef(false);
    result := new  SetDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lRef);
  end;
end;

method Parser.ParseFunctionDeclaration: FunctionPointerDeclaration;
begin
  var lPos := fTok.Position;
  var lWantResult := fTok.Token = TokenKind.K_function;
  var lPars: List<ParameterDeclaration>;
  fTok.Next;
  if fTok.Token = TokenKind.OpenRound then 
    lPars := ParseParameterDeclarations()
  else
    lPars := new List<ParameterDeclaration>;
  var lRes: TypeReference;
  if lWantResult then begin
    if not ExpectToken(TokenKind.Colon, ParserErrorKind.ColonExpected) then exit nil;
    lRes := ParseTypeRef(false);
    if lRes = nil then exit nil;
  end else lRes := nil;

  result := new FunctionPointerDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lRes, lPars);
end;

method Parser.ParseParameterDeclarations: List<ParameterDeclaration>;
begin
  fTok.Next; // presume openparen is there
  result := new List<ParameterDeclaration>;
  if fTok.Token = TokenKind.CloseRound then begin
    fTok.Next;
    exit;
  end;
  var lNames: List<String> := new List<String>;
  loop begin

    var lPos := fTok.Position;
    var lMod:= ParameterModifier.In;
    if fTok.Token = TokenKind.K_const then begin
      lMod := ParameterModifier.Const;
      fTok.Next;
    end else 
    if fTok.Token = TokenKind.K_var then begin
      lMod := ParameterModifier.Var;
      fTok.Next;
    end else 
    if fTok.Token = TokenKind.K_out then begin
      lMod := ParameterModifier.Out;
      fTok.Next;
    end;
    loop begin

      if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then exit nil;
      lNames.Add(fTok.TokenStr);
      fTok.Next;
      if fTok.Token <> TokenKind.Comma then 
        break;
      fTok.Next;
    end;

    if not ExpectToken(TokenKind.Colon, ParserErrorKind.ColonExpected) then exit nil;
    fTok.Next;
    var lRef: TypeReference := ParseTypeRef(false);
    if lRef = nil then exit nil;
    for i: Integer := 0 to lNames.Count -1 do begin
      result.Add(new ParameterDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lNames[i], lRef, lMod));
    end;
    lNames.Clear;
    if fTok.Token = TokenKind.CloseRound then begin
      fTok.Next;
      break;
    end;
    if not ExpectToken(TokenKind.CloseRound, ParserErrorKind.CloseRoundExpected) then exit nil;
  end;
end;

method Parser.ParseArrayDeclaration: ArrayDeclaration;
begin
  var lPos := fTok.Position;
  fTok.Next; // expect array to be here
  var lStart: Expression := nil; 
  var lEnd: Expression := nil;
  if fTok.Token = TokenKind.OpenBlock then begin
    fTok.Next;
    lStart := ParseExpression;
    if lStart = nil then exit nil;
    if fTok.Token = TokenKind.TwoDots then begin
      fTok.Next;
      lEnd := ParseExpression;
      if lEnd = nil then exit nil;
    end;
    if not ExpectToken(TokenKind.CloseBlock, ParserErrorKind.CloseBlockExpected) then exit nil;
    fTok.Next;
  end;
  if not ExpectToken(TokenKind.K_of, ParserErrorKind.OfExpected) then exit nil;
  fTok.Next;

  var lType := ParseTypeRef(false);
  if lType = nil then exit;
  if lStart <> nil then
    exit new StaticArrayDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lType, lStart, lEnd)
  else
    exit new ArrayDeclaration(new PositionPair(lPos, fTok.LastEndPosition), lType);
end;

method Parser.ParseFunction(aInterface: Boolean): FunctionBlock;
begin
  var lPos := fTok.Position;
  var lWantResult := fTok.Token = TokenKind.K_function;
  var lPars: List<ParameterDeclaration>;
  fTok.Next;
  if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then exit nil;
  var lName := fTok.TokenStr;
  fTok.Next;
  if fTok.Token = TokenKind.OpenRound then 
    lPars := ParseParameterDeclarations()
  else
    lPars := new List<ParameterDeclaration>;
  var lRes: TypeReference;
  if lWantResult then begin
    if not ExpectToken(TokenKind.Colon, ParserErrorKind.ColonExpected) then exit nil;
    lRes := ParseTypeRef(false);
    if lRes = nil then exit nil;
  end else lRes := nil;

  if aInterface then
    exit new FunctionBlock(new PositionPair(lPos, fTok.LastEndPosition), lName, lRes, lPars, [], nil);

  var lBodyItems := new List<BodyBlock>;
  ParseBodyBlock(lBodyItems, false);

  if not ExpectToken(TokenKind.K_begin, ParserErrorKind.BeginExpected) then exit nil;
  var lBlock := ParseBegin;


  exit new FunctionBlock(new PositionPair(lPos, fTok.LastEndPosition), lName, lRes, lPars, lBodyItems, lBlock);
end;

method Parser.ParseBegin: BlockStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lStatements := new List<Statement>;
  loop begin
    if fTok.Token = TokenKind.EOF then begin
      Error(ParserErrorKind.UnexpectedEndOfFile, '');
      exit;
    end;
    var lItem := ParseStatement;
    if lItem = nil then begin
      if not ExpectToken(TokenKind.K_end, ParserErrorKind.EndExpected) then exit nil;
      break;
    end else begin
      lStatements.Add(lItem);
      if fTok.Token <> TokenKind.K_end then begin
        if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then exit nil;
        fTok.Next; // statement separator
      end else break;
    end;
  end;
  fTok.Next;
  result := new BlockStatement(new PositionPair(lPos, fTok.LastEndPosition), lStatements);
end;

method Parser.ParseStatement: Statement;
begin
  case fTok.Token of
    TokenKind.K_begin: exit ParseBegin;
    TokenKind.K_Goto: exit ParseGoto;
    TokenKind.K_with: exit ParseWith;
    TokenKind.K_Try: exit ParseTry;
    TokenKind.K_repeat: exit ParseRepeat;
    TokenKind.K_for: exit ParseFor;
    TokenKind.K_while: exit ParseWhile;
    TokenKind.K_case: exit ParseCase;
    TokenKind.K_exit: exit ParseExit;
    TokenKind.K_if: exit ParseIf;
    TokenKind.K_break: exit ParseBreak;
    TokenKind.K_continue: exit ParseContinue;
    TokenKind.K_end,
    TokenKind.K_until,
    TokenKind.K_Finally,
    TokenKind.K_Except,
    TokenKind.K_else: exit nil;
    TokenKind.SemiColon: begin
      result := new EmptyStatement(fTok.PositionPair);
      fTok.Next;
      exit;
    end

    else exit ParseAssignment;
  end;    
end;

method Parser.ParseBreak: BreakStatement;
begin
  result := new BreakStatement(fTok.PositionPair);
  fTok.Next;
end;

method Parser.ParseContinue: ContinueStatement;
begin
  result := new ContinueStatement(fTok.PositionPair);
  fTok.Next;
end;

method Parser.ParseGoto: GotoStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then exit nil;
  var lTarget := fTok.TokenStr;
  fTok.Next;
  exit new GotoStatement(new PositionPair(lPos, fTok.LastEndPosition), lTarget);
end;

method Parser.ParseExit: ExitStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lVal: Expression;
  if fTok.Token not in [TokenKind.SemiColon, TokenKind.K_end,
    TokenKind.K_until,
    TokenKind.K_else] then
    lVal := ParseExpression
  else
    lVal := nil;
  exit new ExitStatement(new PositionPair(lPos, fTok.LastEndPosition), lVal);
end;

method Parser.ParseRepeat: RepeatStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lBlockPos := fTok.Position;
  var lStatements := new List<Statement>;
  loop begin
    if fTok.Token = TokenKind.EOF then begin
      Error(ParserErrorKind.UnexpectedEndOfFile, '');
      exit;
    end;
    var lItem := ParseStatement;
    if lItem = nil then begin
      if not ExpectToken(TokenKind.K_until, ParserErrorKind.UntilExpected) then exit nil;
      break;
    end else begin
      lStatements.Add(lItem);
      if fTok.Token <> TokenKind.K_until then begin
        if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then exit nil;
        fTok.Next; // statement separator
      end else break;
    end;
  end;
  var lBody := new BlockStatement(new PositionPair(lBlockPos, fTok.LastEndPosition), lStatements);
  fTok.Next;
  var lCondition := ParseExpression;
  result := new RepeatStatement(new PositionPair(lPos, fTok.LastEndPosition), lCondition, lBody);
end;

method Parser.ParseWhile: WhileStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lCondition := ParseExpression;
  if not ExpectToken(TokenKind.K_do, ParserErrorKind.DoExpected) then exit nil;
  fTok.Next;
  var lBlock := ParseStatement;

  exit new WhileStatement(new PositionPair(lPos, fTok.LastEndPosition), lCondition, lBlock);
end;

method Parser.ParseIf: IfStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lCondition := ParseExpression;
  if not ExpectToken(TokenKind.K_then, ParserErrorKind.ThenExpected) then exit nil;
  fTok.Next;
  var lTrue := ParseStatement;
  var lFalse: Statement;
  if fTok.Token = TokenKind.K_else then begin
    fTok.Next;
    lFalse := ParseStatement;
  end else lFalse := nil;
  exit new IfStatement(new PositionPair(lPos, fTok.LastEndPosition), lCondition, lTrue, lFalse);
end;

method Parser.ParseAssignment: AssignmentStatement;
begin
  var lPos := fTok.Position;
  var lDest := ParseExpression;
  if lDest = nil then exit nil;
  if fTok.Token = TokenKind.Assignment then begin
    fTok.Next;
    var lSrc := ParseExpression;
    exit new AssignmentStatement(new PositionPair(lPos, fTok.LastEndPosition), lDest, lSrc);
  end else exit new AssignmentStatement(new PositionPair(lPos, fTok.LastEndPosition), nil, lDest);
end;

method Parser.ParseCase: CaseStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var Val := ParseExpression;
  var lElse: Statement := nil;
  var lElements: List<CaseElement> := new List<CaseElement>;
  if not ExpectToken(TokenKind.K_of, ParserErrorKind.OfExpected) then exit nil;
  fTok.Next;
  loop begin
    if fTok.Token = TokenKind.K_end then begin
      fTok.Next;
      break;
    end;
    if fTok.Token = TokenKind.K_else then begin
      var lSt: List<Statement> := new List<Statement>;
      loop begin
        var lStatement := ParseStatement;
        if lStatement = nil then begin
          if fTok.Token = TokenKind.K_end then begin
            if lSt.Count = 0 then lElse := new EmptyStatement(fTok.PositionPair) else
            if lSt.Count = 1 then lElse := lSt[0] else
            lElse := new BlockStatement(new PositionPair(new Position(lSt[0].PositionPair.StartPos,lSt[0].PositionPair.StartRow, lSt[0].PositionPair.StartCol, lSt[0].PositionPair.File), fTok.LastEndPosition), lSt);
            fTok.Next;
            break;
          end else begin
            Error(ParserErrorKind.EndExpected, '');
            break;
          end;
        end else lSt.Add(lStatement);
      end;
      break;
    end;
    var lPosStart := fTok.Position;
    var lValues: List<Expression> := new List<Expression>;
    loop begin
      var lValue := ParseExpression;
      if fTok.Token = TokenKind.TwoDots then begin
        fTok.Next;
        lValue := new RangeExpression(new PositionPair(lValue.PositionPair.StartPos, lValue.PositionPair.StartRow,lValue.PositionPair.StartCol, fTok.LastEndPosition.Pos, fTok.LastEndPosition.Row, fTok.LastEndPosition.Col, fTok.LastEndPosition.Module), lValue, ParseExpression);
      end;
      lValues.Add(lValue);
      if fTok.Token = TokenKind.Colon then begin
        fTok.Next;
        break;
      end;
      if fTok.Token <> TokenKind.Comma then begin
        Error(ParserErrorKind.ColonExpected, '');
        break;
      end;
      fTok.Next;
    end;
    var lSt := ParseStatement();
    lElements.Add(new CaseElement(new PositionPair(lPosStart, fTok.LastEndPosition), lValues, lSt));
  end;
  result := new CaseStatement(new PositionPair(lPos, fTok.LastEndPosition), Val, lElements, lElse);
end;


method Parser.ParseFor: ForStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lStart := ParseExpression;
  var lDownto: Boolean;
  if fTok.Token = TokenKind.K_downto then begin
    lDownto := true;
    fTok.Next;
  end else if fTok.Token = TokenKind.K_to then begin
    lDownto := false;
    fTok.Next;
  end else begin
    Error(ParserErrorKind.ToDowntoExpected, '');
    exit nil;
  end;
  var lEnd := ParseExpression;
  if not ExpectToken(TokenKind.K_do, ParserErrorKind.DoExpected) then exit nil;
  fTok.Next;
  var lSt := ParseStatement;

  exit new ForStatement(new PositionPair(lPos, fTok.LastEndPosition), lStart, lEnd, lSt, lDownto);
end;


method Parser.ParseTry: TryStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var 
  lStatements := new List<Statement>;
  loop begin
    if fTok.Token = TokenKind.EOF then begin
      Error(ParserErrorKind.UnexpectedEndOfFile, '');
      exit;
    end;
    var lItem := ParseStatement;
    if lItem = nil then begin
      if not ExpectToken([TokenKind.K_Except, TokenKind.K_Finally], ParserErrorKind.FinallyExceptExpected) then exit nil;
      break;
    end else begin
      lStatements.Add(lItem);
      if fTok.Token not in [TokenKind.K_Except, TokenKind.K_Finally] then begin
        if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then exit nil;
        fTok.Next; // statement separator
      end else break;
    end;
  end;
  var lTryBody := new BlockStatement(new PositionPair(lPos, fTok.LastEndPosition), lStatements);
  lStatements := new List<Statement>;
  var lFinally1: Statement := nil;
  var lExcept: Statement := nil;
  var lFinally2: Statement := nil;
  
  if fTok.Token = TokenKind.K_Finally then begin 
    var lPos2 := fTok.Position;
    lStatements := new List<Statement>;
    loop begin
      if fTok.Token = TokenKind.EOF then begin
        Error(ParserErrorKind.UnexpectedEndOfFile, '');
        exit;
      end;
      var lItem := ParseStatement;
      if lItem = nil then begin
        if not ExpectToken([TokenKind.K_Except, TokenKind.K_end], ParserErrorKind.EndExpected) then exit nil;
        break;
      end else begin
        lStatements.Add(lItem);
        if fTok.Token not in [TokenKind.K_Except, TokenKind.K_end] then begin
          if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then exit nil;
          fTok.Next; // statement separator
        end else break;
      end;
    end;
    lFinally1 := new BlockStatement(new PositionPair(lPos2, fTok.LastEndPosition), lStatements);
  end;
  if fTok.Token = TokenKind.K_Except then begin 
    var lPos2 := fTok.Position;
    lStatements := new List<Statement>;
    loop begin
      if fTok.Token = TokenKind.EOF then begin
        Error(ParserErrorKind.UnexpectedEndOfFile, '');
        exit;
      end;
      var lItem := ParseStatement;
      if lItem = nil then begin
        if (lFinally1 = nil) and (fTok.Token = TokenKind.K_Finally) then break;

        if not ExpectToken([TokenKind.K_end], ParserErrorKind.EndExpected) then exit nil;
        break;
      end else begin
        lStatements.Add(lItem);
        if fTok.Token not in [TokenKind.K_end, TokenKind.K_Finally] then begin
          if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then exit nil;
          fTok.Next; // statement separator
        end;
      end;
    end;
    lExcept := new BlockStatement(new PositionPair(lPos2, fTok.LastEndPosition), lStatements);
  end;

  if (lFinally1 = nil) and (fTok.Token = TokenKind.K_Finally) then begin 
    var lPos2 := fTok.Position;
    lStatements := new List<Statement>;
    loop begin
      if fTok.Token = TokenKind.EOF then begin
        Error(ParserErrorKind.UnexpectedEndOfFile, '');
        exit;
      end;
      var lItem := ParseStatement;
      if lItem = nil then begin
        if not ExpectToken([TokenKind.K_Except, TokenKind.K_Finally], ParserErrorKind.FinallyExceptExpected) then exit nil;
        break;
      end else begin
        lStatements.Add(lItem);
        if fTok.Token not in [TokenKind.K_Except, TokenKind.K_Finally] then begin
          if not ExpectToken(TokenKind.SemiColon, ParserErrorKind.SemicolonExpected) then exit nil;
          fTok.Next; // statement separator
        end else break;
      end;
    end;
    lFinally2 := new BlockStatement(new PositionPair(lPos2, fTok.LastEndPosition), lStatements);
  end;

  if not ExpectToken(TokenKind.K_end, ParserErrorKind.EndExpected) then exit;
  fTok.Next;
  
  exit new TryStatement(new PositionPair(lPos, fTok.LastEndPosition), lTryBody, coalesce(lFinally1, lFinally2), lExcept, lFinally1 <> nil);
end;

method Parser.ParseWith: WithStatement;
begin
  var lPos := fTok.Position;

  var lItems: List<Expression> := new List<Expression>;

  fTok.Next;
  loop begin
    lItems.Add(ParseExpression);
    if fTok.Token = TokenKind.K_do then begin fTok.Next; break; end;
    if not ExpectToken(TokenKind.Comma, ParserErrorKind.DoExpected) then exit nil;
  end;

  var lBody := ParseStatement;

  exit new WithStatement(new PositionPair(lPos, fTok.LastEndPosition), lItems, lBody);
end;

method Parser.ParseExpression: Expression;
begin
  Result := ParseSimpleExpression;
  if Result = nil then exit;
  while fTok.Token in [ TokenKind.GreaterEqual, 
    TokenKind.LessEqual, 
    TokenKind.Greater, 
    TokenKind.Less, 
    TokenKind.Equal, 
    TokenKind.NotEqual, 
    TokenKind.K_in, 
    TokenKind.K_Is] do
  begin
    var lToken := fTok.Token;
    fTok.Next;
    var F2 := ParseSimpleExpression;
    if F2 = nil then exit nil;
    var lOp: BinaryOperator;
    case lToken of
      TokenKind.GreaterEqual: lOp := BinaryOperator.GreaterEqual;
      TokenKind.LessEqual: lOp := BinaryOperator.LessEqual;
      TokenKind.Greater: lOp := BinaryOperator.Greater;
      TokenKind.Less: lOp := BinaryOperator.Less;
      TokenKind.Equal: lOp := BinaryOperator.Equal;
      TokenKind.NotEqual: lOp := BinaryOperator.NotEqual;
      TokenKind.K_in: lOp := BinaryOperator.In;
      TokenKind.K_Is: lOp := BinaryOperator.Is;
    else
      lOp := BinaryOperator.Add;
    end;
    result := new BinaryExpression(Result, F2, lOp);
  end;
end;


method Parser.ParseSimpleExpression: Expression;
begin
  Result := ParseTerm;
  if Result = nil then exit;
  while fTok.Token in [ TokenKind.Plus, 
    TokenKind.Minus, 
    TokenKind.K_or, 
    TokenKind.K_xor] do
  begin
    var lToken := fTok.Token;
    fTok.Next;
    var F2 := ParseTerm;
    if F2 = nil then exit nil;
    var lOp: BinaryOperator;
    case lToken of
      TokenKind.Minus: lOp := BinaryOperator.Sub;
      TokenKind.K_or: lOp := BinaryOperator.Or;
      TokenKind.K_xor: lOp := BinaryOperator.Xor;
    else
      lOp := BinaryOperator.Add;
    end;
    result := new BinaryExpression(Result, F2, lOp);
  end;
end;

method Parser.ParseTerm: Expression;
begin
  Result := ParseFactor;
  if Result = nil then exit;
  while fTok.Token in [TokenKind.Multiply,TokenKind.Divide, TokenKind.K_div, TokenKind.K_mod, TokenKind.K_and, TokenKind.K_shl,TokenKind.K_shr, TokenKind.K_As] do
  begin
    var lToken := fTok.Token;
    fTok.Next;
    var F2 := ParseFactor;
    if F2 = nil then exit nil;
    var lOp: BinaryOperator;
    case lToken of
      TokenKind.Multiply: lOp := BinaryOperator.Mul;
      TokenKind.Divide:lOp := BinaryOperator.Div;
      TokenKind.K_div:lOp := BinaryOperator.Div;
      TokenKind.K_mod:lOp := BinaryOperator.Mod;
      TokenKind.K_and:lOp := BinaryOperator.And;
      TokenKind.K_shl:lOp := BinaryOperator.Shl;
      TokenKind.K_shr:lOp := BinaryOperator.Shr;
      TokenKind.K_As:lOp := BinaryOperator.As;
    else
      lOp := BinaryOperator.Add;
    end;
    result := new BinaryExpression(Result, F2, lOp);
  end;
end;

method Parser.ParseFactor: Expression;
begin
  case fTok.Token of
    TokenKind.Plus:
      begin
        var lExpr := ParseTerm;
        if lExpr = nil then exit nil;
        exit lExpr;
     end;
    TokenKind.Minus:
      begin
        var lPos := fTok.Position;
        var lExpr := ParseTerm;
        if lExpr = nil then exit nil;
        exit new UnaryExpression(new PositionPair(lPos, fTok.LastEndPosition), lExpr, UnaryOperator.Minus);
      end;
    TokenKind.K_not:
      begin
        var lPos := fTok.Position;
        var lExpr := ParseFactor;
        if lExpr = nil then exit nil;
        exit new UnaryExpression(new PositionPair(lPos, fTok.LastEndPosition), lExpr, UnaryOperator.Minus);
      end;
    TokenKind.OpenRound:
      begin
        fTok.Next;
        result := ParseExpression;
        if not ExpectToken(TokenKind.CloseRound, ParserErrorKind.CloseRoundExpected) then exit nil
      end;
    TokenKind.K_nil:
      begin
        result := new NilExpression(fTok.PositionPair);
        fTok.Next;
      end;
    TokenKind.HexInt, TokenKind.Integer:
      begin
        var lVal := fTok.TokenStr;
        if lVal.StartsWith('$') then
          result := new IntegerExpression(fTok.PositionPair, Int64.Parse(lVal.Substring(1), System.Globalization.NumberStyles.HexNumber))
        else
          result := new IntegerExpression(fTok.PositionPair, Int64.Parse(lVal));
        fTok.Next;
      end;
    TokenKind.Real:
      begin
        result := new FloatExpression(fTok.PositionPair, Double.Parse(fTok.TokenStr, System.Globalization.NumberFormatInfo.InvariantInfo));
        fTok.Next;
      end;
    TokenKind.AddressOf:
      begin
        var lPos := fTok.Position;
        var lExpr := ParseFactor;
        if lExpr = nil then exit nil;
        result := new UnaryExpression(new PositionPair(lPos, fTok.LastEndPosition), lExpr, UnaryOperator.AdressOf);
      end;
    TokenKind.K_true:
      begin
        result := new TrueExpression(fTok.PositionPair);
        fTok.Next;
      end;
    TokenKind.K_false:
      begin
        result := new FalseExpression(fTok.PositionPair);
        fTok.Next;
      end;    
    TokenKind.Char,
    TokenKind.String: 
    begin
      result := ParseString;
    end;
    TokenKind.OpenBlock:
      begin
        var lStart := fTok.Position;
        var lArgs := ParseParameters(true);
        if lArgs = nil then exit;
        result := new ArrayExpression(new PositionPair(lStart, fTok.LastEndPosition), lArgs);
      end;
    TokenKind.K_Ord:
      begin
        var lStart := fTok.Position;
        fTok.Next;
        if not ExpectToken(TokenKind.OpenRound, ParserErrorKind.OpeningParenthesisExpected) then exit;
        fTok.Next;
        var lExpr := ParseExpression;
        if not ExpectToken(TokenKind.CloseRound, ParserErrorKind.CloseBlockExpected) then exit;
        fTok.Next;
        result := new OrdExpression(new PositionPair(lStart, fTok.LastEndPosition), lExpr);
      end;
    TokenKind.K_Chr:
      begin
        var lStart := fTok.Position;
        fTok.Next;
        if not ExpectToken(TokenKind.OpenRound, ParserErrorKind.OpeningParenthesisExpected) then exit;
        fTok.Next;
        var lExpr := ParseExpression;
        if not ExpectToken(TokenKind.CloseRound, ParserErrorKind.CloseBlockExpected) then exit;
        fTok.Next;
        result := new ChrExpression(new PositionPair(lStart, fTok.LastEndPosition), lExpr);
      end;
      TokenKind.Identifier:
        begin
          result := new IdentifierExpression(fTok.PositionPair, fTok.TokenStr);
          fTok.Next;
        end;
  else
    Error(ParserErrorKind.SyntaxError, '');
  end;
  result := ParseRest(Result);
end;

method Parser.ParseString: StringExpression;
var
  lValue: String;
begin
  lValue := '';
  var lStart := fTok.Position;
  loop begin
    case fTok.Token of
      TokenKind.Char: begin
        var lItem := fTok.TokenStr.Substring(1);
        if lItem.StartsWith('$') then
          lItem := chr(Int32.Parse(lItem.Substring(1), System.Globalization.NumberStyles.HexNumber))
        else
          lItem := chr(Int32.Parse(lItem));
        lValue := lValue+lItem;
      end;
      TokenKind.String: 
        begin
          var lItem := fTok.TokenStr;
          lItem := lItem.Substring(1, lItem.Length -2).Replace(#39#39, #39);
          lValue := lValue+lItem;
        end;
    else
      break;
    end; // case
  end;
  result := new StringExpression(new PositionPair(lStart, fTok.LastEndPosition), lValue);
end;

method Parser.ParseRest(aSelf: Expression): Expression;
begin
  while true do begin
    case fTok.Token of
      TokenKind.Period:
        begin
          fTok.Next;
          if not ExpectToken(TokenKind.Identifier, ParserErrorKind.IdentifierExpected) then  exit;
          var lPos := new Position( aSelf.PositionPair.StartPos, aSelf.PositionPair.StartRow, aSelf.PositionPair.StartCol, aSelf.PositionPair.File);
          var lIdent := fTok.TokenStr;
          result := new MemberExpression(new PositionPair(lPos, fTok.LastEndPosition), aSelf, lIdent);
        end;
      TokenKind.OpenBlock:
        begin
          var lArgs := ParseParameters(false);
          if lArgs = nil then  exit nil;
          var lPos := new Position( aSelf.PositionPair.StartPos, aSelf.PositionPair.StartRow, aSelf.PositionPair.StartCol, aSelf.PositionPair.File);
          result := new ArrayElementExpression(new PositionPair(lPos, fTok.LastEndPosition), aSelf, lArgs);
        end;
      TokenKind.OpenRound:
        begin
          var lArgs := ParseParameters(true);
          if lArgs = nil then  exit nil;
          var lPos := new Position( aSelf.PositionPair.StartPos, aSelf.PositionPair.StartRow, aSelf.PositionPair.StartCol, aSelf.PositionPair.File);
          result := new CallExpression(new PositionPair(lPos, fTok.LastEndPosition), aSelf, lArgs);
        end;
      TokenKind.Dereference:
        begin
          result := new UnaryExpression(new PositionPair(aSelf.PositionPair.StartPos, aSelf.PositionPair.StartRow, aSelf.PositionPair.StartCol, fTok.EndPosition.Pos, fTok.EndPosition.Row,fTok.EndPosition.Col, fTok.EndPosition.Module), 
            aSelf, UnaryOperator.Dereference);
          fTok.Next;
        end;
      else
        break;
    end;
  end;
    // TODO: .something [indexer], (parameters) deference^

end;

method Parser.ParseParameters(aParenthesis: Boolean): IList<Expression>;
begin
  if fTok.Token = iif(aParenthesis, TokenKind.OpenRound, TokenKind.OpenBlock) then begin
    fTok.Next;

  end else
    Error(ParserErrorKind.OpeningParenthesisExpected, '');
  exit nil;
end;

end.