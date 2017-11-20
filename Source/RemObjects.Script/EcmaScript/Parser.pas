//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.EcmaScript.Internal;

interface

uses
  RemObjects.Script,
  RemObjects.Script.Properties,
  System.Collections.ObjectModel,
  System.Collections.Generic;

{$HIDE W27}

type
  ParserErrorKind = RemObjects.Script.EcmaScript.EcmaScriptErrorKind;


  ParserError = public class(ParserMessage)
  private
    var fMessage: String; readonly;
    var fError: ParserErrorKind; readonly;

    method get_Message(): String;
  public
    constructor(position: Position;  error: ParserErrorKind;  message: String);

    property Code: Int32 read Int32(fError); override;
    property Error: ParserErrorKind read fError;
    property Message: String read get_Message;
    property IsError: Boolean read true; override;

    method IntToString(): String; override;
    method ToString(): String; override;
  end;


  ParseStatementFlags nested in Parser = assembly flags (None = 0, AllowFunction = 1, AllowGetSet = 2);
  Parser = public class
  private
    fTok: ITokenizer;
    fMessages: List<ParserMessage>;
    fMessagesWrapper: ReadOnlyCollection<ParserMessage>;
    method LookAheadGetSetWasName: Boolean;
  assembly
    method fTok_Error(Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String);
    method Error(aCode: ParserErrorKind; aParameter: String);
    method ParseStatement(aFlags: ParseStatementFlags): SourceElement;
    method ParseBlockStatement(): BlockStatement;
    method ParseVarStatement(aAllowIn, aParseSemicolon: Boolean): VariableStatement;
    method ParseEmptyStatement: EmptyStatement;
    method ParseIfStatement: IfStatement;
    method ParseDoStatement: DoStatement;
    method ParseWhileStatement: WhileStatement;
    method ParseForStatement: Statement;
    method ParseContinueStatement: ContinueStatement;
    method ParseBreakStatement: BreakStatement;
    method ParseReturnStatement: ReturnStatement;
    method ParseWithStatement: WithStatement;
    method ParseSwitchStatement: SwitchStatement;
    method ParseThrowStatement: ThrowStatement;
    method ParseTryStatement: TryStatement;
    method ParseDebuggerStatement: DebuggerStatement;
    method ParseExpression(aAllowIn: Boolean): ExpressionElement;
    method ParseCommaExpression(aAllowIn: Boolean): ExpressionElement;
    method ParseConditionalExpression(aAllowIn: Boolean): ExpressionElement;
    method ParseLogicalOrExpression(aAllowIn: Boolean): ExpressionElement;
    method ParseBitwiseOrExpression(aAllowIn: Boolean): ExpressionElement;
    method ParseEqualityExpression(aAllowIn: Boolean): ExpressionElement;
    method ParseRelationalExpression(aAllowIn: Boolean): ExpressionElement;
    method ParseShiftExpression: ExpressionElement;
    method ParseAdditiveExpression: ExpressionElement;
    method ParseMultiplicativeExpression: ExpressionElement;
    method ParseUnaryExpression: ExpressionElement; 
    method ParsePostfixExpression: ExpressionElement; 
    method ParseLeftHandSideExpression(aParseParameters: Boolean): ExpressionElement;
  public
    constructor;
    
    method Parse(aTokenizer: ITokenizer): ProgramElement;

    property Messages: ReadOnlyCollection<ParserMessage> read fMessagesWrapper;
  end;

implementation

method Parser.ParseStatement(aFlags: ParseStatementFlags): SourceElement;
begin
  if ((ParseStatementFlags.AllowFunction in aFlags) and (fTok.Token = TokenKind.K_function)) or
  ((ParseStatementFlags.AllowGetSet in aFlags) and (fTok.Token in [TokenKind.K_set, TokenKind.K_get])) then begin
    var lPos := fTok.Position;
    var lMode := FunctionDeclarationType.None;
    if fTok.Token = TokenKind.K_set then begin 
      lMode := FunctionDeclarationType.Set;
      fTok.Next;
    end else 
    if fTok.Token = TokenKind.K_get then begin 
      lMode := FunctionDeclarationType.Get;
      fTok.Next;
    end;

    fTok.Next;
    var lName: String := nil;
    if fTok.Token in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier] then begin
      lName := fTok.TokenStr;
      fTok.Next;
    end;
    if fTok.Token <> TokenKind.OpeningParenthesis then begin
      Error(ParserErrorKind.OpeningParenthesisExpected, '');
      exit nil;
    end;
    fTok.Next;
    var lParams: List<ParameterDeclaration> := new List<ParameterDeclaration>;
    if fTok.Token = TokenKind.ClosingParenthesis then
      fTok.Next
    else 
    loop begin
      if fTok.Token not in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier] then begin
        Error(ParserErrorKind.IdentifierExpected, '');
        exit nil;
      end;
      lParams.Add(new ParameterDeclaration(fTok.PositionPair, fTok.TokenStr));
      fTok.Next;
      if fTok.Token = TokenKind.Comma then begin
        fTok.Next;
      end else if fTok.Token = TokenKind.ClosingParenthesis then begin
        fTok.Next;
        break;
      end else begin
        Error(ParserErrorKind.ClosingParenthesisExpected, '');
        exit nil;
      end;
    end;
    if fTok.Token <> TokenKind.CurlyOpen then begin
      Error(ParserErrorKind.OpeningBraceExpected, '');
      exit nil;
    end;
    var lItems: List<SourceElement> := new List<SourceElement>;

    fTok.Next;
    while fTok.Token <> TokenKind.CurlyClose do begin
      if fTok.Token = TokenKind.EOF then begin
        Error(ParserErrorKind.ClosingBraceExpected, '');
        exit nil;
      end;
      var lState := ParseStatement(ParseStatementFlags.AllowFunction);
      if lState = nil then exit nil;
      lItems.Add(lState);
    end;
    fTok.Next;
    exit new FunctionDeclarationElement(new PositionPair(lPos, fTok.LastEndPosition), lMode, lName, lParams, lItems);
  end else begin
    if fTok.Token in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier] then begin
      var lObj := fTok.SaveState;
      var lPos := fTok.Position;
      var lIdent := fTok.TokenStr;
      fTok.Next;
      if fTok.Token = TokenKind.Colon then begin
        fTok.Next;
        var lSt := ParseStatement(ParseStatementFlags.None);
        if lSt = nil then exit nil;
        exit new LabelledStatement(new PositionPair(lPos, fTok.LastEndPosition), lIdent, Statement(lSt));
      end else 
        fTok.RestoreState(lObj);
    end;

    case fTok.Token of
      TokenKind.CurlyOpen: exit ParseBlockStatement();
      TokenKind.K_var: exit ParseVarStatement(true, true);
      TokenKind.Semicolon: exit ParseEmptyStatement;
      TokenKind.K_if: exit ParseIfStatement;
      TokenKind.K_do: exit ParseDoStatement;
      TokenKind.K_while: exit ParseWhileStatement;
      TokenKind.K_for: exit ParseForStatement;
      TokenKind.K_continue: exit ParseContinueStatement;
      TokenKind.K_break: exit ParseBreakStatement;
      TokenKind.K_return: exit ParseReturnStatement;
      TokenKind.K_with: exit ParseWithStatement;
      TokenKind.K_switch: exit ParseSwitchStatement;
      TokenKind.K_throw: exit ParseThrowStatement;
      TokenKind.K_try: exit ParseTryStatement;
      TokenKind.K_debugger: exit ParseDebuggerStatement;
      else begin
        var lPos := fTok.Position;
        var lExpr := ParseExpression(true);
        if lExpr = nil then exit;
        if fTok.Token = TokenKind.Comma then begin
          var lItems := new List<SourceElement>;
          lItems.Add(new ExpressionStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr));
          while fTok.Token = TokenKind.Comma do begin
            fTok.Next();
            var lSp := fTok.Position;
            lExpr := ParseExpression(true);
            if lExpr = nil then exit;
            lItems.Add(new ExpressionStatement(new PositionPair(lSp, fTok.LastEndPosition), lExpr));
          end;
          if fTok.Token = TokenKind.Semicolon then fTok.Next;
          result := new BlockStatement(new PositionPair(lPos, fTok.LastEndPosition), lItems);
        end else begin
          if fTok.Token = TokenKind.Semicolon then fTok.Next;
          result := new ExpressionStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr);
        end;
      end;
    end; // case
  end;
end;

constructor Parser;
begin
  fMessages := new List<ParserMessage>;
  fMessagesWrapper := new ReadOnlyCollection<ParserMessage>(fMessages);
end;


method Parser.Parse(aTokenizer: ITokenizer): ProgramElement;
begin
  fTok := aTokenizer;
  fTok.Error += fTok_Error;
  fMessages.Clear;

  if fTok.Token = TokenKind.EOF then exit new ProgramElement(new PositionPair(fTok.Position, fTok.Position));
  var lPos := fTok.Position;
  var lItems := new List<SourceElement>();

  while fTok.Token <> TokenKind.EOF do begin
    var lItem := ParseStatement(ParseStatementFlags.AllowFunction);
    if lItem = nil then break;
    if lItem.Type = ElementType.BlockStatement then
      lItems.AddRange(BlockStatement(lItem).Items)
    else
      lItems.Add(lItem);
  end;

  fTok.Error -= fTok_Error;
  result := new ProgramElement(new PositionPair(lPos, fTok.LastEndPosition), lItems);
end;

method Parser.Error(aCode: ParserErrorKind; aParameter: String);
begin
  fMessages.Add(new ParserError(fTok.Position, aCode, aParameter));
end;

method Parser.ParseBlockStatement(): BlockStatement;
begin
  var lPos := fTok.Position;
  var lItems := new List<SourceElement>;
  fTok.Next;
  while fTok.Token <> TokenKind.CurlyClose do begin
    if fTok.Token = TokenKind.EOF then begin
      Error(ParserErrorKind.ClosingBraceExpected, '');
      exit nil;
    end;
    var lState := ParseStatement(ParseStatementFlags.AllowFunction);
    if lState = nil then break;
    lItems.Add(lState);
  end;
  fTok.Next;
  result := new BlockStatement(new PositionPair(lPos, fTok.LastEndPosition), lItems);
end;

method Parser.ParseVarStatement(aAllowIn, aParseSemicolon: Boolean): VariableStatement;
begin
  var lPos := fTok.Position;
  var lItems: List<VariableDeclaration> := new List<VariableDeclaration>;
  fTok.Next;
  loop begin
    var lPosVar := fTok.Position;
    if fTok.Token not in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier] then begin
      Error(ParserErrorKind.IdentifierExpected, '');
      exit nil;
    end;
    var lName: String := fTok.TokenStr;
    fTok.Next;
    var lValue: ExpressionElement;
    if fTok.Token = TokenKind.Assign then begin
      fTok.Next;
      lValue := ParseExpression(aAllowIn);
      if lValue = nil then exit nil;
    end else 
      lValue := nil;
    lItems.Add(new VariableDeclaration(new PositionPair(lPosVar, fTok.LastEndPosition), lName, lValue));
    if fTok.Token = TokenKind.Comma then begin
      fTok.Next;
    end else if fTok.Token = TokenKind.Semicolon then begin
      if aParseSemicolon then 
        fTok.Next;
      break;
    end else begin
      break; // implicit semi
    end;
  end;
  result := new VariableStatement(new PositionPair(lPos, fTok.LastEndPosition), lItems);
end;

method Parser.ParseEmptyStatement: EmptyStatement;
begin
  result := new EmptyStatement(fTok.PositionPair);
  fTok.Next;
end;

method Parser.ParseIfStatement: IfStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if fTok.Token <> TokenKind.OpeningParenthesis then begin
    Error(ParserErrorKind.OpeningParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lExpr := ParseCommaExpression(true);
  if lExpr = nil then exit;
  if fTok.Token <> TokenKind.ClosingParenthesis then begin
    Error(ParserErrorKind.ClosingParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lTrue := Statement(ParseStatement(ParseStatementFlags.None));
  if lTrue = nil then exit;
  var lFalse : Statement := nil;
  if fTok.Token = TokenKind.K_else then begin
    fTok.Next;
    lFalse := Statement(ParseStatement(ParseStatementFlags.None));
    if lFalse = nil then exit;
  end;
  result := new IfStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr, lTrue, lFalse);
end;

method Parser.ParseDoStatement: DoStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;

  var lStatement := Statement(ParseStatement(ParseStatementFlags.None));

  if fTok.Token <> TokenKind.K_while then begin
    Error(ParserErrorKind.WhileExpected, '');
    exit nil;
  end;

  fTok.Next;

  if fTok.Token <> TokenKind.OpeningParenthesis then begin
    Error(ParserErrorKind.OpeningParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lExpr := ParseCommaExpression(true);
  if lExpr = nil then exit;
  if fTok.Token <> TokenKind.ClosingParenthesis then begin
    Error(ParserErrorKind.ClosingParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new DoStatement(new PositionPair(lPos, fTok.LastEndPosition), lStatement, lExpr);
end;

method Parser.ParseWhileStatement: WhileStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if fTok.Token <> TokenKind.OpeningParenthesis then begin
    Error(ParserErrorKind.OpeningParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lExpr := ParseCommaExpression(true);
  if lExpr = nil then exit;
  if fTok.Token <> TokenKind.ClosingParenthesis then begin
    Error(ParserErrorKind.ClosingParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;


  var lStatement := Statement(ParseStatement(ParseStatementFlags.None));

  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new WhileStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr, lStatement);
end;

method Parser.ParseContinueStatement: ContinueStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lIdent: String := nil;
  if not fTok.LastWasEnter and (fTok.Token in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier]) then begin
    lIdent := fTok.TokenStr;
    fTok.Next;
  end;

  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new ContinueStatement(new PositionPair(lPos, fTok.LastEndPosition), lIdent);
end;

method Parser.ParseBreakStatement: BreakStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lIdent: String := nil;
  if not fTok.LastWasEnter and (fTok.Token in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier]) then begin
    lIdent := fTok.TokenStr;
    fTok.Next;
  end;

  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new BreakStatement(new PositionPair(lPos, fTok.LastEndPosition), lIdent);
end;

method Parser.ParseReturnStatement: ReturnStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lExpr: ExpressionElement := nil;
  if not fTok.LastWasEnter and (fTok.Token not in [TokenKind.Semicolon, TokenKind.K_else, TokenKind.K_default, TokenKind.CurlyClose]) then begin
    lExpr := ParseCommaExpression(true);
    if lExpr = nil then exit nil;
  end;

  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new ReturnStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr);
end;

method Parser.ParseWithStatement: WithStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if fTok.Token <> TokenKind.OpeningParenthesis then begin
    Error(ParserErrorKind.OpeningParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lExpr := ParseCommaExpression(true);
  if lExpr = nil then exit;
  if fTok.Token <> TokenKind.ClosingParenthesis then begin
    Error(ParserErrorKind.ClosingParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;


  var lStatement := Statement(ParseStatement(ParseStatementFlags.None));

  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new WithStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr, lStatement);
end;

method Parser.ParseThrowStatement: ThrowStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  var lExpr: ExpressionElement := nil;
  lExpr := ParseCommaExpression(true);
  if lExpr = nil then exit nil;
  

  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new ThrowStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr);
end;


method Parser.ParseDebuggerStatement: DebuggerStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if fTok.Token = TokenKind.Semicolon then fTok.Next;
  result := new DebuggerStatement(new PositionPair(lPos, fTok.LastEndPosition));
end;

method Parser.ParseForStatement: Statement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if fTok.Token <> TokenKind.OpeningParenthesis then begin
    Error(ParserErrorKind.OpeningParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lVars: VariableStatement := nil;
  var lInit: ExpressionElement := nil;
  if fTok.Token = TokenKind.K_var then begin
    lVars := ParseVarStatement(false, false);  
    if lVars = nil then exit nil;
    //if lVars.Items.Count <> 1 then begin
//      Error(ParserErrorKind.OnlyOneVariableAllowed, "");
  //  end;
  end else if fTok.Token <> TokenKind.Semicolon then begin
    lInit := ParseCommaExpression(false);
    if lInit = nil then exit nil;
  end;

  if fTok.Token = TokenKind.K_in then begin
    fTok.Next;
    var lIn := ParseCommaExpression(true);
    if fTok.Token <> TokenKind.ClosingParenthesis then begin
      Error(ParserErrorKind.ClosingParenthesisExpected, '');
      exit nil;
    end;
    fTok.Next;
    var lSt := Statement(ParseStatement(ParseStatementFlags.None));
    if lSt = nil then exit nil;
    if lVars <> nil then 
      exit new ForInStatement(new PositionPair(lPos, fTok.LastEndPosition), lVars.Items[0], lIn, lSt) 
    else
      exit new ForInStatement(new PositionPair(lPos, fTok.LastEndPosition), lInit, lIn, lSt);
  end else begin
    if fTok.Token <> TokenKind.Semicolon then begin
      Error(ParserErrorKind.SemicolonExpected, '');
      exit nil;
    end;
    fTok.Next;
    var lCondition: ExpressionElement := nil;
    if fTok.Token <> TokenKind.Semicolon then begin
      lCondition := ParseCommaExpression(true);
      if lCondition = nil then exit;
    end;
    if fTok.Token <> TokenKind.Semicolon then begin
      Error(ParserErrorKind.SemicolonExpected, '');
      exit nil;
    end;
    fTok.Next;
    var lIncrement: ExpressionElement := nil;
    if fTok.Token <> TokenKind.ClosingParenthesis then begin
      lIncrement := ParseCommaExpression(true);
      if lIncrement = nil then exit;
    end;
    if fTok.Token <> TokenKind.ClosingParenthesis then begin
      Error(ParserErrorKind.ClosingBraceExpected, '');
      exit nil;
    end;
    fTok.Next;
    var lSt := Statement(ParseStatement(ParseStatementFlags.None));
    if lSt = nil then exit nil;
    if lVars <> nil then 
      exit new ForStatement(new PositionPair(lPos, fTok.LastEndPosition), lVars.Items, lCondition, lIncrement, lSt) 
    else
      exit new ForStatement(new PositionPair(lPos, fTok.LastEndPosition), lInit, lCondition, lIncrement, lSt);
  end;
end;


method Parser.ParseSwitchStatement: SwitchStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if fTok.Token <> TokenKind.OpeningParenthesis then begin
    Error(ParserErrorKind.OpeningParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lExpr := ParseCommaExpression(true);
  if lExpr = nil then exit;
  if fTok.Token <> TokenKind.ClosingParenthesis then begin
    Error(ParserErrorKind.ClosingParenthesisExpected, '');
    exit nil;
  end;
  fTok.Next;

  if fTok.Token <> TokenKind.CurlyOpen then begin
    Error(ParserErrorKind.OpeningBraceExpected, '');
    exit nil;
  end;
  fTok.Next;
  var lClauses: List<CaseClause> := new List<CaseClause>;
  loop begin
    if fTok.Token = TokenKind.CurlyClose then 
      break;
    var lCaseExpr: ExpressionElement := nil;
    var lItemPos := fTok.Position;
    if fTok.Token = TokenKind.K_case then begin
      fTok.Next;
      lCaseExpr := ParseCommaExpression(true);
      if lCaseExpr = nil then exit;
    end else if fTok.Token = TokenKind.K_default then begin
      fTok.Next;
    end else begin
      Error(ParserErrorKind.ClosingBraceExpected, '');
      exit nil;
    end;
    if fTok.Token <> TokenKind.Colon then begin
      Error(ParserErrorKind.ColonExpected, '');
      exit nil;
    end;
    fTok.Next;
    var lStatements: List<Statement> := new List<Statement>;
    while (fTok.Token not in [TokenKind.K_case, TokenKind.K_default, TokenKind.CurlyClose]) do begin
      var lSt := Statement(ParseStatement(ParseStatementFlags.None));
      if lSt = nil then exit nil;
      lStatements.Add(lSt);
    end;
    lClauses.Add(new CaseClause(new PositionPair(lItemPos, fTok.LastEndPosition), lCaseExpr, lStatements));
  end;
  fTok.Next;
  result := new SwitchStatement(new PositionPair(lPos, fTok.LastEndPosition), lExpr, lClauses);
end;

method Parser.ParseTryStatement: TryStatement;
begin
  var lPos := fTok.Position;
  fTok.Next;
  if fTok.Token <> TokenKind.CurlyOpen then begin
    Error(ParserErrorKind.OpeningBraceExpected, '');
    exit nil;
  end;

  var lBody := ParseBlockStatement();
  if lBody = nil then exit nil;
  var lCatch: CatchBlock := nil;
  var lFinally: BlockStatement := nil;
  if fTok.Token = TokenKind.K_catch then begin
    var lCp := fTok.Position;
    fTok.Next;
    if fTok.Token <> TokenKind.OpeningParenthesis then begin
      Error(ParserErrorKind.OpeningParenthesisExpected, '');
      exit nil;
    end;
    fTok.Next;
    if fTok.Token not in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier] then begin
      Error(ParserErrorKind.IdentifierExpected, '');
      exit nil;
    end;
    
    var lIdent := fTok.TokenStr;
    fTok.Next;
    if fTok.Token <> TokenKind.ClosingParenthesis then begin
      Error(ParserErrorKind.ClosingParenthesisExpected, '');
      exit nil;
    end;
    fTok.Next;
    if fTok.Token <> TokenKind.CurlyOpen then begin
      Error(ParserErrorKind.OpeningBraceExpected, '');
      exit nil;
    end;

    var lCatchBody := ParseBlockStatement();
    if lCatchBody = nil then exit nil;
    lCatch := new CatchBlock(new PositionPair(lCp, fTok.LastEndPosition), lIdent, lCatchBody);
  end;
  if fTok.Token = TokenKind.K_finally then begin
    fTok.Next;
    if fTok.Token <> TokenKind.CurlyOpen then begin
      Error(ParserErrorKind.OpeningBraceExpected, '');
      exit nil;
    end;

    lFinally := ParseBlockStatement();
    if lFinally = nil then exit nil;
  end;

  if (lCatch = nil) and (lFinally = nil) then begin
    Error(ParserErrorKind.CatchOrFinallyExpected, '');
    exit;
  end;
  result := new TryStatement(new PositionPair(lPos, fTok.LastEndPosition), lBody, lCatch, lFinally);
end;

method Parser.ParseExpression(aAllowIn: Boolean): ExpressionElement;
begin
  var lLeft := ParseConditionalExpression(aAllowIn);
  if lLeft = nil then exit nil;
  while fTok.Token in [TokenKind.Assign,
      TokenKind.PlusAssign, // +=
    TokenKind.MinusAssign,// -=
    TokenKind.MultiplyAssign, // *=
    TokenKind.ModulusAssign, // %=
    TokenKind.ShiftLeftAssign, // <<=
    TokenKind.ShiftRightSignedAssign,// >>=
    TokenKind.ShiftRightUnsignedAssign, // >>>=
    TokenKind.AndAssign, // &=
    TokenKind.OrAssign, // |=
    TokenKind.XorAssign, // ^=
    TokenKind.DivideAssign] do begin // /=
    var lOp: BinaryOperator;
    case fTok.Token of
      TokenKind.Assign: lOp := BinaryOperator.Assign;
      TokenKind.PlusAssign: lOp := BinaryOperator.PlusAssign;
      TokenKind.MinusAssign: lOp := BinaryOperator.MinusAssign;
      TokenKind.MultiplyAssign: lOp := BinaryOperator.MultiplyAssign;
      TokenKind.ModulusAssign: lOp := BinaryOperator.ModulusAssign;
      TokenKind.ShiftLeftAssign: lOp := BinaryOperator.ShiftLeftAssign;
      TokenKind.ShiftRightSignedAssign: lOp := BinaryOperator.ShiftRightSignedAssign;
      TokenKind.ShiftRightUnsignedAssign: lOp := BinaryOperator.ShiftRightUnsignedAssign;
      TokenKind.AndAssign: lOp := BinaryOperator.AndAssign;
      TokenKind.OrAssign: lOp := BinaryOperator.OrAssign;
      TokenKind.XorAssign: lOp := BinaryOperator.XorAssign;
      else lOp := BinaryOperator.DivideAssign; // TokenKind.DivideAssign
    end;
    fTok.Next;
    var lRight := ParseExpression(aAllowIn);
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, lOp);
  end;
  result := lLeft;
end;

method Parser.ParseLogicalOrExpression(aAllowIn: Boolean): ExpressionElement;
begin
  var lLeft := ParseBitwiseOrExpression(aAllowIn);
  if lLeft = nil then exit nil;
  while fTok.Token = TokenKind.DoubleAnd do begin
    fTok.Next;
    var lRight := ParseBitwiseOrExpression(aAllowIn);
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, BinaryOperator.DoubleAnd);
  end;

  while fTok.Token = TokenKind.DoubleOr do begin
    fTok.Next;
    var lRight := ParseBitwiseOrExpression(aAllowIn);
    if lRight = nil then exit nil;
    while fTok.Token = TokenKind.DoubleAnd do begin
      fTok.Next;
      var lRight2 := ParseBitwiseOrExpression(aAllowIn);
      if lRight2 = nil then exit nil;
      lRight := new BinaryExpression(lRight.PositionPair, lRight, lRight2, BinaryOperator.DoubleAnd);
    end;

    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, BinaryOperator.DoubleOr);
  end;
  exit lLeft;
end;

method Parser.ParseConditionalExpression(aAllowIn: Boolean): ExpressionElement;
begin
  var lLeft := ParseLogicalOrExpression(aAllowIn);
  if lLeft = nil then exit nil;
  while fTok.Token = TokenKind.ConditionalOperator do begin
    fTok.Next;
    var lMiddle := ParseExpression(aAllowIn);
    if lMiddle = nil then exit nil;
    if fTok.Token <> TokenKind.Colon then begin
      Error(ParserErrorKind.ColonExpected, '');
      exit nil;
    end;
    fTok.Next;
    var lRight := ParseExpression(aAllowIn);
    if lRight = nil then exit nil;
    lLeft := new ConditionalExpression(lLeft.PositionPair, lLeft, lMiddle, lRight);
  end;

  result := lLeft;
end;

method Parser.ParseBitwiseOrExpression(aAllowIn: Boolean): ExpressionElement;
begin
  var lLeft := ParseEqualityExpression(aAllowIn);
  if lLeft = nil then exit nil;

  while fTok.Token = TokenKind.And do begin
    fTok.Next;
    var lRight := ParseEqualityExpression(aAllowIn);
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, BinaryOperator.And);
  end;

  while fTok.Token = TokenKind.Xor do begin
    fTok.Next;
    var lRight := ParseEqualityExpression(aAllowIn);
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, BinaryOperator.Xor);
  end;

  while fTok.Token = TokenKind.Or do begin
    fTok.Next;
    var lRight := ParseEqualityExpression(aAllowIn);
    if lRight = nil then exit nil;
    while fTok.Token = TokenKind.And do begin
      fTok.Next;
      var lRight2 := ParseEqualityExpression(aAllowIn);
      if lRight2 = nil then exit nil;
      lRight := new BinaryExpression(lRight.PositionPair, lRight, lRight2, BinaryOperator.And);
    end;
    while fTok.Token = TokenKind.Xor do begin
      fTok.Next;
      var lRight2 := ParseEqualityExpression(aAllowIn);
      if lRight2 = nil then exit nil;
      lRight := new BinaryExpression(lRight.PositionPair, lRight, lRight2, BinaryOperator.Xor);
    end;

    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, BinaryOperator.Or);
  end;
  exit lLeft;
end;

method Parser.ParseEqualityExpression(aAllowIn: Boolean): ExpressionElement;
begin
  var lLeft := ParseRelationalExpression(aAllowIn);
  if lLeft = nil then exit nil;
  while fTok.Token in [TokenKind.Equal,
      TokenKind.NotEqual,
    TokenKind.StrictEqual,
    TokenKind.StrictNotEqual] do begin // /=
    var lOp: BinaryOperator;
    case fTok.Token of
      TokenKind.Equal: lOp := BinaryOperator.Equal;
      TokenKind.NotEqual: lOp := BinaryOperator.NotEqual;
      TokenKind.StrictEqual: lOp := BinaryOperator.StrictEqual;
      else lOp := BinaryOperator.StrictNotEqual; //TokenKind.StrictNotEqual
    end;
    fTok.Next;
    var lRight := ParseRelationalExpression(aAllowIn);
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, lOp);
  end;
  result := lLeft;
end;

method Parser.ParseRelationalExpression(aAllowIn: Boolean): ExpressionElement;
begin
  var lLeft := ParseShiftExpression;
  if lLeft = nil then exit nil;
  while (fTok.Token in [TokenKind.Less,
      TokenKind.Greater,
    TokenKind.LessOrEqual,
    TokenKind.GreaterOrEqual,
    TokenKind.K_instanceof]) or (aAllowIn and (fTok.Token = TokenKind.K_in)) do begin 
    var lOp: BinaryOperator;
    case fTok.Token of
      TokenKind.Less: lOp := BinaryOperator.Less;
      TokenKind.Greater: lOp := BinaryOperator.Greater;
      TokenKind.LessOrEqual: lOp := BinaryOperator.LessOrEqual;
      TokenKind.GreaterOrEqual: lOp := BinaryOperator.GreaterOrEqual;
      TokenKind.K_instanceof: lOp := BinaryOperator.InstanceOf;
      else lOp := BinaryOperator.In; //TokenKind.In
    end;
    fTok.Next;
    var lRight := ParseShiftExpression;
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, lOp);
  end;
  result := lLeft;
end;

method Parser.ParseShiftExpression: ExpressionElement;
begin
  var lLeft := ParseAdditiveExpression;
  if lLeft = nil then exit nil;
  while fTok.Token in [TokenKind.ShiftLeft,
      TokenKind.ShiftRightSigned,
    TokenKind.ShiftRightUnsigned] do begin 
    var lOp: BinaryOperator;
    case fTok.Token of
      TokenKind.ShiftLeft: lOp := BinaryOperator.ShiftLeft;
      TokenKind.ShiftRightSigned: lOp := BinaryOperator.ShiftRightSigned;
      else lOp := BinaryOperator.ShiftRightUnsigned; //TokenKind.ShiftRightUnsigned
    end;
    fTok.Next;
    var lRight := ParseAdditiveExpression;
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, lOp);
  end;
  result := lLeft;
end;

method Parser.ParseAdditiveExpression: ExpressionElement;
begin
  var lLeft := ParseMultiplicativeExpression;
  if lLeft = nil then exit nil;
  while fTok.Token in [TokenKind.Plus,
      TokenKind.Minus] do begin 
    var lOp: BinaryOperator;
    if fTok.Token  = TokenKind.Plus then lOp := BinaryOperator.Plus else lOp := BinaryOperator.Minus;
    fTok.Next;
    var lRight := ParseMultiplicativeExpression;
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, lOp);
  end;
  result := lLeft;
end;

method Parser.ParseMultiplicativeExpression: ExpressionElement;
begin
  var lLeft := ParseUnaryExpression;
  if lLeft = nil then exit nil;
  while fTok.Token in [TokenKind.Multiply, TokenKind.Divide,
      TokenKind.Modulus] do begin 
    var lOp: BinaryOperator;
    case fTok.Token of
      TokenKind.Multiply: lOp := BinaryOperator.Multiply;
      TokenKind.Divide: lOp := BinaryOperator.Divide;
      else lOp := BinaryOperator.Modulus;
    end;
    fTok.Next;
    var lRight := ParseUnaryExpression;
    if lRight = nil then exit nil;
    lLeft := new BinaryExpression(lLeft.PositionPair, lLeft, lRight, lOp);
  end;
  result := lLeft;
end;

method Parser.ParseUnaryExpression: ExpressionElement;
begin
  var lUnaryOp: UnaryOperator;
  case fTok.Token of
    TokenKind.K_delete: lUnaryOp := UnaryOperator.Delete;
    TokenKind.K_void: lUnaryOp := UnaryOperator.Void;
    TokenKind.K_typeof: lUnaryOp := UnaryOperator.TypeOf;
    TokenKind.Increment: lUnaryOp := UnaryOperator.PreIncrement;
    TokenKind.Decrement: lUnaryOp := UnaryOperator.PreDecrement;
    TokenKind.Plus: lUnaryOp := UnaryOperator.Plus;
    TokenKind.Minus: lUnaryOp := UnaryOperator.Minus;
    TokenKind.Not: lUnaryOp := UnaryOperator.BoolNot;
    TokenKind.BitwiseNot: lUnaryOp := UnaryOperator.BinaryNot;
  else exit ParsePostfixExpression;
  end;
  var lPos := fTok.Position;
  fTok.Next;
  var lVal := ParseUnaryExpression;
  if lVal = nil then exit;
  result := new UnaryExpression(new PositionPair(lPos, fTok.LastEndPosition), lVal, lUnaryOp);
end;

method Parser.ParseLeftHandSideExpression(aParseParameters: Boolean): ExpressionElement;
begin
  var lVal: ExpressionElement;

  case fTok.Token of
    TokenKind.K_function:
      begin
        var lFunc := ParseStatement(ParseStatementFlags.AllowFunction);
        if lFunc = nil then exit;
        lVal := new FunctionExpression(lFunc.PositionPair, lFunc as FunctionDeclarationElement);
      end;
    TokenKind.K_this: begin
      lVal := new ThisExpression(fTok.PositionPair);
      fTok.Next;
    end;

    TokenKind.K_set,TokenKind.K_get, TokenKind.Identifier:begin
      lVal := new IdentifierExpression(fTok.PositionPair, fTok.TokenStr);
      fTok.Next;
    end;

    TokenKind.OpeningBracket: begin
      var lPos := fTok.Position;
      fTok.Next;
      var lArgs: List<ExpressionElement> := new List<ExpressionElement>;

      if fTok.Token <> TokenKind.ClosingBracket then begin
        //if fTok.Token = TokenKind.Comma then begin
          //fTok.Next;
        //end;
        loop begin
          var lSub: ExpressionElement;
          if fTok.Token in [TokenKind.Comma, TokenKind.ClosingBracket] then
            lSub := nil
          else begin
            lSub := ParseExpression(true);
            if lSub = nil then exit nil;
          end;
          
          lArgs.Add(lSub);
          if fTok.Token = TokenKind.Comma then begin
            fTok.Next ;
            //if fTok.Token = TokenKind.ClosingBracket then
              //lArgs.RemoveAt(lArgs.Count-1);
          end else 
          if fTok.Token = TokenKind.ClosingBracket then break else
          begin
            Error(ParserErrorKind.ClosingBracketExpected, '');
            exit nil;
          end;
        end;
      end;
      fTok.Next;
      lVal := new ArrayLiteralExpression(new PositionPair(lPos, fTok.LastEndPosition), lArgs);
    end;
    TokenKind.CurlyOpen: begin
      var lPos := fTok.Position;
      fTok.Next;
      var lArgs: List<PropertyAssignment> := new List<PropertyAssignment>;
      if fTok.Token <> TokenKind.CurlyClose then begin
        loop begin
          var lSub: PropertyAssignment;
          if fTok.Token in [TokenKind.Comma, TokenKind.CurlyClose] then
            lSub := nil
          else begin
            var lName: ExpressionElement;
            var lValue: ExpressionElement;
            var lMode: FunctionDeclarationType := FunctionDeclarationType.None;
            if (fTok.Token in [TokenKind.K_set, TokenKind.K_get]) and not LookAheadGetSetWasName then begin
              lName := nil;
              lMode := if fTok.Token = TokenKind.K_set then FunctionDeclarationType.Set else FunctionDeclarationType.Get;
              var lTmp := FunctionDeclarationElement(ParseStatement(ParseStatementFlags.AllowGetSet));
              if lTmp = nil then exit;
              lName := new StringExpression(lTmp.PositionPair, lTmp.Identifier);
              lValue := new FunctionExpression(lTmp.PositionPair, lTmp);
            end else begin
              lName := ParseLeftHandSideExpression(false);
              if lName = nil then exit;
              if lName is not PropertyBaseExpression then begin
                Error(ParserErrorKind.SyntaxError, '');
                exit;
              end;
              if fTok.Token <> TokenKind.Colon then begin
                Error(ParserErrorKind.ColonExpected, '');
                exit;
              end;
              fTok.Next;
              lValue := ParseExpression(true);
              if lValue = nil then exit;
            end;
            lSub := new PropertyAssignment(
            iif(lName = nil, lValue.PositionPair, 
            new PositionPair(lName.PositionPair.StartPos, lName.PositionPair.StartRow, lName.PositionPair.StartCol, fTok.LastEndPosition.Pos, fTok.LastEndPosition.Row, fTok.LastEndPosition.Col, lName.PositionPair.File)), lMode, PropertyBaseExpression(lName), lValue);
          end;
          lArgs.Add(lSub);
          if fTok.Token = TokenKind.Comma then begin
            fTok.Next;
            if fTok.Token = TokenKind.CurlyClose then break;
          end else 
          if fTok.Token = TokenKind.CurlyClose then break else
          begin
            Error(ParserErrorKind.ClosingBraceExpected, '');
            exit nil;
          end;
        end;
      end;
      fTok.Next;
      lVal := new ObjectLiteralExpression(new PositionPair(lPos, fTok.LastEndPosition), lArgs);
    end;
    // Object Literal
    
    TokenKind.Divide: begin
      var lStr, lMod: String;
      fTok.NextAsRegularExpression(out lStr, out lMod);
      lVal := new RegExExpression(fTok.PositionPair, lStr, lMod);
    end;
    TokenKind.DivideAssign: begin
      var lStr, lMod: String;
      fTok.NextAsRegularExpression(out lStr, out lMod);
      lVal := new RegExExpression(fTok.PositionPair, '='+lStr, lMod);
    end;

    TokenKind.K_null: begin
      lVal := new NullExpression(fTok.PositionPair);
      fTok.Next;
    end;
    TokenKind.K_true: begin
      lVal := new BooleanExpression(fTok.PositionPair, true);
      fTok.Next;
    end;
    TokenKind.K_false: begin
      lVal := new BooleanExpression(fTok.PositionPair, false);
      fTok.Next;
    end;
    TokenKind.SingleQuoteString,
    TokenKind.String: begin
      lVal := new StringExpression(fTok.PositionPair, Tokenizer.DecodeString(fTok.TokenStr));
      fTok.Next();
    end;
    TokenKind.Float: begin
      var lValue := RemObjects.Script.EcmaScript.Utilities.ParseDouble(fTok.TokenStr); 
      
      if Double.IsNaN(lValue) then begin
        Error(ParserErrorKind.SyntaxError, '');
        exit nil;
      end;
      lVal := new DecimalExpression(fTok.PositionPair, lValue);
      fTok.Next;
    end;

    TokenKind.Number:begin
      var lValue: Int64;
      if not Int64.TryParse(fTok.TokenStr, out lValue) then begin
        var lDValue := RemObjects.Script.EcmaScript.Utilities.ParseDouble(fTok.TokenStr); 
      
        if Double.IsNaN(lValue) then begin
          Error(ParserErrorKind.SyntaxError, '');
          exit nil;
        end;
        lVal := new DecimalExpression(fTok.PositionPair, lDValue);
        fTok.Next;
      end else begin
        lVal := new IntegerExpression(fTok.PositionPair, lValue);
        fTok.Next;
      end;
    end;
    TokenKind.HexNumber:begin
      var lValue: Int64;
      if not Int64.TryParse(fTok.TokenStr.Substring(2), System.Globalization.NumberStyles.HexNumber, System.Globalization.NumberFormatInfo.InvariantInfo, out lValue) then begin
        Error(ParserErrorKind.SyntaxError, '');
        exit nil;
      end;
      lVal := new IntegerExpression(fTok.PositionPair, lValue);
      fTok.Next;
    end;


    TokenKind.OpeningParenthesis: begin
      fTok.Next;
      lVal := ParseCommaExpression(true);
      if fTok.Token <> TokenKind.ClosingParenthesis then begin
        Error(ParserErrorKind.ClosingParenthesisExpected, '');
        exit nil;
      end;
      fTok.Next;
    end;

    TokenKind.K_new: begin
      var lPos := fTok.Position;
      fTok.Next;
      lVal := ParseLeftHandSideExpression(false);
      if lVal = nil then exit;
      var lArgs: List<ExpressionElement> := new List<ExpressionElement>;
      if fTok.Token = TokenKind.OpeningParenthesis then begin
        fTok.Next;
        if fTok.Token <> TokenKind.ClosingParenthesis then begin
          loop begin
            var lSub := ParseExpression(true);
            if lSub = nil then exit nil;
            lArgs.Add(lSub);
            if fTok.Token = TokenKind.Comma then fTok.Next else 
            if fTok.Token = TokenKind.ClosingParenthesis then break else
            begin
              Error(ParserErrorKind.ClosingParenthesisExpected, '');
              exit nil;
            end;
          end;
        end;
        fTok.Next;
      end;
      lVal := new NewExpression(new PositionPair(lPos, fTok.LastEndPosition), lVal, lArgs);
    end;
  else
    begin
      Error(ParserErrorKind.SyntaxError, '');
      exit nil;
    end;
  end;

  while fTok.Token in [TokenKind.Dot, TokenKind.OpeningBracket, TokenKind.OpeningParenthesis] do begin
    if fTok.Token = TokenKind.Dot then begin
      fTok.Next;
      if fTok.Token not in [TokenKind.K_set, TokenKind.K_get, TokenKind.Identifier] then begin
        Error(ParserErrorKind.IdentifierExpected, '');
        exit nil;
      end;
      lVal := new SubExpression(new PositionPair(lVal.PositionPair.StartPos, lVal.PositionPair.StartRow, lVal.PositionPair.StartCol, fTok.LastEndPosition.Pos, fTok.LastEndPosition.Row, fTok.LastEndPosition.Col, lVal.PositionPair.File), lVal, fTok.TokenStr);
      fTok.Next;
    end else if fTok.Token = TokenKind.OpeningBracket then begin
      fTok.Next;
      var lSub := ParseExpression(true);
      if lSub = nil then exit nil;
      if fTok.Token <> TokenKind.ClosingBracket then begin
        Error(ParserErrorKind.ClosingBracketExpected, '');
        exit nil;
      end;
      fTok.Next;
      lVal := new ArrayAccessExpression(new PositionPair(lVal.PositionPair.StartPos, lVal.PositionPair.StartRow, lVal.PositionPair.StartCol, fTok.LastEndPosition.Row, fTok.LastEndPosition.Pos, fTok.LastEndPosition.Col, lVal.PositionPair.File), lVal, lSub);
    end else begin // opening parenthesis
      if not aParseParameters then break;
      fTok.Next;
      var lArgs: List<ExpressionElement> := new List<ExpressionElement>;
      if fTok.Token <> TokenKind.ClosingParenthesis then begin
        loop begin
          var lSub := ParseExpression(true);
          if lSub = nil then exit nil;
          lArgs.Add(lSub);
          if fTok.Token = TokenKind.Comma then fTok.Next else 
          if fTok.Token = TokenKind.ClosingParenthesis then break else
          begin
            Error(ParserErrorKind.ClosingParenthesisExpected, '');
            exit nil;
          end;
        end;
      end;
      fTok.Next;
      lVal := new CallExpression(new PositionPair(lVal.PositionPair.StartPos, lVal.PositionPair.StartRow, lVal.PositionPair.StartCol, fTok.LastEndPosition.Pos, fTok.LastEndPosition.Row, fTok.LastEndPosition.Col, lVal.PositionPair.File), lVal, lArgs);
    end;
  end;
  result := lVal;
end;

method Parser.ParsePostfixExpression: ExpressionElement;
begin
  var lVal := ParseLeftHandSideExpression(true);
  if lVal = nil then exit nil;
  if fTok.LastWasEnter then exit lVal;
  if fTok.Token = TokenKind.Decrement then begin
    lVal := new UnaryExpression(new PositionPair(lVal.PositionPair.StartPos, lVal.PositionPair.StartRow, lVal.PositionPair.StartCol, fTok.LastEndPosition.Pos, fTok.LastEndPosition.Row, fTok.LastEndPosition.Col, lVal.PositionPair.File), lVal, UnaryOperator.PostDecrement);
    fTok.Next;
  end else if fTok.Token = TokenKind.Increment then begin
    lVal := new UnaryExpression(new PositionPair(lVal.PositionPair.StartPos, lVal.PositionPair.StartRow, lVal.PositionPair.StartCol, fTok.LastEndPosition.Pos, fTok.LastEndPosition.Row, fTok.LastEndPosition.Col, lVal.PositionPair.File), lVal, UnaryOperator.PostIncrement);
    fTok.Next;
  end;
  exit lVal;
end;

method Parser.fTok_Error(Caller: Tokenizer; Kind: TokenizerErrorKind; Parameter: String);
begin
  fTok := Caller;
  case Kind of
    TokenizerErrorKind.CommentError: Error(ParserErrorKind.CommentError, '');
    TokenizerErrorKind.EOFInRegex: Error(ParserErrorKind.EOFInRegex, '');
    TokenizerErrorKind.EOFInString: Error(ParserErrorKind.EOFInString, '');
    TokenizerErrorKind.InvalidEscapeSequence: Error(ParserErrorKind.InvalidEscapeSequence, '');
    TokenizerErrorKind.UnknownCharacter: Error(ParserErrorKind.UnknownCharacter, '');
    TokenizerErrorKind.EnterInRegex: Error(ParserErrorKind.EnterInRegex, '');
  else
    Error(ParserErrorKind(Int32.MaxValue), '');
  end; // case
end;


method Parser.ParseCommaExpression(aAllowIn: Boolean): ExpressionElement;
begin
  var lPos := fTok.Position;
  result := ParseExpression(aAllowIn);
  if fTok.Token = TokenKind.Comma then begin
    var lItems := new List<ExpressionElement>;
    lItems.Add(result);
    while fTok.Token = TokenKind.Comma  do begin
      fTok.Next();
      lItems.Add(ParseExpression(aAllowIn));
    end;
    
    exit new CommaSeparatedExpression(new PositionPair(lPos, fTok.EndPosition), lItems);
  end;
end;

method Parser.LookAheadGetSetWasName: Boolean;
begin
  // current token is SET/GEt
  var lSave := fTok.SaveState;
  fTok.Next;
  result := fTok.Token = TokenKind.Colon;

  fTok.RestoreState(lSave);
end;


constructor ParserError(position: Position;  error: ParserErrorKind;  message: String);
begin
  inherited constructor(position);
  fError := error;
  fMessage := message;
end;


method ParserError.get_Message(): String;
begin
  if String.IsNullOrEmpty(fMessage)  then
    exit inherited ToString();

  exit fMessage + " " + inherited ToString();
end;


method ParserError.ToString(): String;
begin
  exit self.Message;
end;


method ParserError.IntToString(): String;
begin
  case fError of
    ParserErrorKind.OpeningParenthesisExpected:  exit Resources.eOpeningParenthesisExpected;
    ParserErrorKind.OpeningBraceExpected:        exit Resources.eOpeningBraceExpected;
    ParserErrorKind.ClosingParenthesisExpected:  exit Resources.eClosingParenthesisExpected;
    ParserErrorKind.IdentifierExpected:          exit Resources.eIdentifierExpected;
    ParserErrorKind.ClosingBraceExpected:        exit Resources.eClosingBraceExpected;
    ParserErrorKind.WhileExpected:               exit Resources.eWhileExpected;
    ParserErrorKind.SemicolonExpected:           exit Resources.eSemicolonExpected;
    ParserErrorKind.ColonExpected:               exit Resources.eColonExpected;
    ParserErrorKind.CatchOrFinallyExpected:      exit Resources.eCatchOrFinallyExpected;
    ParserErrorKind.ClosingBracketExpected:      exit Resources.eClosingBracketExpected;
    ParserErrorKind.SyntaxError:                 exit Resources.eSyntaxError;
    ParserErrorKind.CommentError:                exit Resources.eCommentError;
    ParserErrorKind.EOFInRegex:                  exit Resources.eEOFInRegex;
    ParserErrorKind.EOFInString:                 exit Resources.eEOFInString;
    ParserErrorKind.InvalidEscapeSequence:       exit Resources.eInvalidEscapeSequence;
    ParserErrorKind.UnknownCharacter:            exit Resources.eUnknownCharacter;
    ParserErrorKind.OnlyOneVariableAllowed:      exit Resources.eOnlyOneVariableAllowed;
  end; // case

  exit 'Unknown error';
end;


end.