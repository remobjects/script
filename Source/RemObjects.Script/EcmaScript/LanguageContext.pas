{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text,
  System.Reflection.Emit,
  RemObjects.Script,
  RemObjects.Script.Properties,
  RemObjects.Script.EcmaScript.Internal;

type
  
  InternalDelegate = public delegate (aScope: ExecutionContext; aSelf: Object; params args: Array of Object): Object;
  InternalFunctionDelegate = public delegate(aScope: ExecutionContext; aSelf: Object; params args: array of Object; aFunc: EcmaScriptInternalFunctionObject): Object;
  EcmaScriptErrorKind = public enum
  (
    FatalErrorWhileCompiling,
    OpeningParenthesisExpected,
    ClosingParenthesisExpected,
    OpeningBraceExpected,
    IdentifierExpected,
    ClosingBraceExpected,
    WhileExpected,
    SemicolonExpected,
    ColonExpected,
    CatchOrFinallyExpected,
    ClosingBracketExpected,
    SyntaxError,
    CommentError,
    EOFInRegex,
    EOFInString,
    InvalidEscapeSequence,
    UnknownCharacter,
    OnlyOneVariableAllowed,

    EInternalError = 10001,
    WithNotAllowedInStrict,
    CannotBreakHere,
    DuplicateIdentifier,
    CannotContinueHere,
    CannotReturnHere,
    OnlyOneDefaultAllowed,
    CannotAssignValueToExpression,
    UnknownLabelTarget,
    DuplicateLabel
  );
  ScriptParsingException = public class(ScriptException)
  private
  public
    class method ErrorToString(anError: EcmaScriptErrorKind; aMsg: string): string;
    constructor (aFilename: String; aPosition: PositionPair; anError: EcmaScriptErrorKind; aMsg: String := '');
    property Position: PositionPair; readonly;
    property Error: EcmaScriptErrorKind; readonly;
    property Msg: String; readonly;
  end;

  EcmaScriptException = public ScriptParsingException;
  
  EcmaScriptCompilerOptions = public class
  private
  public
    constructor; empty;
    property StackOverflowProtect: Boolean := true;
    property EmitDebugCalls: Boolean;
    property Context: EnvironmentRecord;
    property GlobalObject: GlobalObject;
  end;

  FinallyInfo = public class
  private
  public
    property FinallyLabel: Label;
    property FinallyState: LocalBuilder;
    method AddUnique(aLabel: Label): Integer;
    property JumpTable: List<Label> := new List<Label>; readonly;
  end;

  EcmaScriptCompiler = public class
  assembly
    fRoot: EnvironmentRecord;
  private
    fGlobal: GlobalObject;
    fUseStrict: Boolean;
    fStackProtect, fDebug: Boolean;
    fExitLabel: Label;
    fResultVar: LocalBuilder;
    fExecutionContext: LocalBuilder;
    fILG: ILGenerator;
    fLocals: List<LocalBuilder>;
    fStatementStack: List<Statement>;
    fBreak,
    fContinue: nullable Label;
    method Parse(aFilename, aData: string; aEval: Boolean := false): List<SourceElement>; // eval throws different exception
    method MarkLabelled(aBreak, aContinue: nullable Label);
    method WriteDebugStack;
    method WriteStatement(El: SourceElement);
    method AllocateLocal(aType: &Type): LocalBuilder;
    method ReleaseLocal(aLocal: LocalBuilder);
    method CallGetValue(aFromElement: ElementType);
    method CallSetValue;
    method WriteExpression(aExpression: ExpressionElement);
    method RecursiveFindFuncAndVars(aElements: sequence of SourceElement): sequence of SourceElement; iterator;
    method WriteIfStatement(el: IfStatement);
    method WriteDoStatement(el: DoStatement);
    method WriteWhileStatement(el: WhileStatement);
    method WriteForStatement(el: ForStatement);
    method WriteForInstatement(el: ForInStatement);
    method WriteContinue(el: ContinueStatement);
    method WriteBreak(el: BreakStatement);
    method WriteWithStatement(el: WithStatement);
    method WriteFunction(el: FunctionDeclarationElement; aRegister: Boolean);
    method WriteTryStatement(el: TryStatement);
    method WriteSwitchstatement(el: SwitchStatement);
    method DefineInScope(aEval: Boolean; aElements: sequence of SourceElement);
  public
    constructor(aOptions: EcmaScriptCompilerOptions);


    property GlobalObject: GlobalObject read fGlobal;
    
    method EvalParse(aStrict: Boolean; aData: string): InternalDelegate;
    method Parse(aFilename, aData: string): InternalDelegate;
    method Parse(aFunction: FunctionDeclarationElement; aEval: Boolean; aScopeName: string; aElements: List<SourceElement>): Object;
  end;

  DynamicMethods = public static class
  private
  public

  end;

  CodeDelegate = public delegate (aScope: ExecutionContext; Args: array of Object): Object;

implementation


constructor ScriptParsingException(aFilename: String; aPosition: PositionPair; anError: EcmaScriptErrorKind; aMsg: String := '');
begin
  inherited constructor(String.Format('{0}({1}:{2}) E{3} {4}', aFilename, 
    aPosition.StartRow, aPosition.StartCol, Integer(anError), ErrorToString(anError, aMsg)));
  Position := aPosition;
  Error := anError;
  Msg := aMsg;

end;

class method ScriptParsingException.ErrorToString(anError: EcmaScriptErrorKind; aMsg: string): string;
begin
  case anError of
    ParserErrorKind.OpeningParenthesisExpected:  result := Resources.eOpeningParenthesisExpected;
    ParserErrorKind.OpeningBraceExpected: result := Resources.eOpeningBraceExpected;
    ParserErrorKind.ClosingParenthesisExpected: result := Resources.eClosingParenthesisExpected;
    ParserErrorKind.IdentifierExpected: result := Resources.eIdentifierExpected;
    ParserErrorKind.ClosingBraceExpected: result := Resources.eClosingBraceExpected;
    ParserErrorKind.WhileExpected: result := Resources.eWhileExpected;
    ParserErrorKind.SemicolonExpected: result := Resources.eSemicolonExpected;
    ParserErrorKind.ColonExpected: result := Resources.eColonExpected;
    ParserErrorKind.CatchOrFinallyExpected: result := Resources.eCatchOrFinallyExpected;
    ParserErrorKind.ClosingBracketExpected: result := Resources.eClosingBracketExpected;
    ParserErrorKind.SyntaxError: Result := Resources.eSyntaxError;
    ParserErrorKind.CommentError: Result := Resources.eCommentError;
    ParserErrorKind.EOFInRegex: Result := Resources.eEOFInRegex;
    ParserErrorKind.EOFInString: Result := Resources.eEOFInString;
    ParserErrorKind.InvalidEscapeSequence: Result := Resources.eInvalidEscapeSequence;
    ParserErrorKind.UnknownCharacter: Result := Resources.eUnknownCharacter;
    ParserErrorKind.OnlyOneVariableAllowed: result := Resources.eOnlyOneVariableAllowed;
    EcmaScriptErrorKind.WithNotAllowedInStrict: result := Resources.eWithNotAllowedInStrict;
    EcmaScriptErrorKind.CannotBreakHere: result := String.Format(Resources.eCannotBreakHere, aMsg);
    EcmaScriptErrorKind.CannotContinueHere: result := String.Format(Resources.eCannotBreakHere, aMsg);
    EcmaScriptErrorKind.DuplicateIdentifier: result := String.Format(Resources.eDuplicateIdentifier, aMsg);
    EcmaScriptErrorKind.EInternalError: result := String.Format(Resources.eInternalError, aMsg);
    EcmaScriptErrorKind.CannotReturnHere: result := String.Format(Resources.eCannotReturnHere, aMsg);
    EcmaScriptErrorKind.OnlyOneDefaultAllowed: result := string.Format(Resources.eOnlyOneDefaultAllowed, aMsg);
    EcmaScriptErrorKind.CannotAssignValueToExpression: result := String.Format(Resources.eCannotAssignValueToExpression, aMsg);
    EcmaScriptErrorKind.UnknownLabelTarget:result := String.Format(Resources.eUnknownLabelTarget, aMsg);
    EcmaScriptErrorKind.DuplicateLabel: result := String.Format(Resources.eDuplicateIdentifier, aMsg);
  else
    result := Resources.eSyntaxError;
  end; // case
end;


method EcmaScriptCompiler.Parse(aFilename, aData: string; aEval: Boolean := false): List<SourceElement>;
begin
  var lTokenizer := new Tokenizer;
  var lParser := new Parser;
  lTokenizer.Error += lParser.fTok_Error;
  lTokenizer.SetData(aData, aFilename);
  lTokenizer.Error -= lParser.fTok_Error;
  var lElement := lParser.Parse(lTokenizer);
  for each el in lParser.Messages do begin
    if el.IsError then
    raise new ScriptParsingException(aFilename, new PositionPair(el.Position, el.Position), EcmaScriptErrorKind(el.Code));
  end;
  exit lElement.Items;
end;

constructor EcmaScriptCompiler(aOptions: EcmaScriptCompilerOptions);
begin
  fGlobal := aOptions:GlobalObject;
  if assigned(aOptions) then begin
    fDebug := aOptions.EmitDebugCalls;
    fStackProtect := aOptions.StackOverflowProtect;
  end else fStackProtect := true;
  if fGlobal = nil then fGlobal := new GlobalObject(self);
  fRoot := new ObjectEnvironmentRecord(aOptions:Context, fGlobal, false);
end;


method EcmaScriptCompiler.EvalParse(aStrict: Boolean; aData: string): InternalDelegate;
begin
  fUseStrict := aStrict;
  exit InternalDelegate(Parse(nil, true, '<eval>', Parse('<eval>', aData, true)));
end;

method EcmaScriptCompiler.Parse(aFilename, aData: string): InternalDelegate;
begin
  exit InternalDelegate(Parse(nil, false, aFilename, Parse( aFilename, aData, false)));
end;

method EcmaScriptCompiler.Parse(aFunction: FunctionDeclarationElement; aEval: Boolean; aScopeName: string; aElements: List<SourceElement>): Object;
begin
  if aSCopeName = nil then aScopeName := '<anonymous>';
  var lUseStrict := fUseStrict;
  var lLoops := fStatementStack;
  fStatementStack := new List<Statement>;
  try
    if aElements.Count <> 0 then begin
      if aElements[aElements.Count-1].Type <> ElementType.ExpressionStatement then
        aElements.Add(new ReturnStatement(new PositionPair(), new IdentifierExpression(new PositionPair, 'undefined')))
      else if aElements[aElements.Count-1].Type <> ElementType.ReturnStatement then  begin
        var lEl := ExpressionStatement(aElements[aElements.Count-1]).ExpressionElement;
        aElements[aElements.Count-1] := new ReturnStatement(lEl.PositionPair, lEl);
      end;
      if aElements.Count > 1 then begin
        if (aElements[0].Type = ElementType.ExpressionStatement) and (ExpressionStatement(aElements[0]).ExpressionElement.Type = ElementType.StringExpression) then begin
          if StringExpression(ExpressionStatement(aElements[0]).ExpressionElement).Value = 'use strict' then begin
            fUseStrict := true;
            aElements.RemoveAt(0);
          end;
        end;
      end;
    end else
      aElements.Add(new ReturnStatement(new PositionPair(), new IdentifierExpression(new PositionPair, 'undefined')));

    var lOldLocals := fLocals;
    fLocals := new List<LocalBuilder>;
    var lMethod: DynamicMethod;
    {$IFDEF SILVERLIGHT} 
    if aFunction <> nil then
      lMethod := new System.Reflection.Emit.DynamicMethod(aSCopeName, typeof(Object), [typeof(ExecutionContext), typeof(object), Typeof(array of Object), typeof(EcmaScriptInternalFunctionObject)])
    else
      lMethod := new System.Reflection.Emit.DynamicMethod(aSCopeName, typeof(Object), [typeof(ExecutionContext), typeof(object), Typeof(array of Object)]);
    {$ELSE}
    if aFunction <> nil then
      lMethod := new System.Reflection.Emit.DynamicMethod(aSCopeName, typeof(Object), [typeof(ExecutionContext), typeof(object), Typeof(array of Object), typeof(EcmaScriptInternalFunctionObject)], typeof(DynamicMethods), true)
    else
      lMethod := new System.Reflection.Emit.DynamicMethod(aSCopeName, typeof(Object), [typeof(ExecutionContext), typeof(object), Typeof(array of Object)], typeof(DynamicMethods), true);
    {$ENDIF}
    var lOldBreak := fBreak;
    var lOldContinue := fContinue;
    fBreak := nil;
    fContinue := nil;
    var lOldILG := fIlg;
    fILG := lMethod.GetILGenerator();
    var lOldExecutionContext := fExecutionContext;
    fExecutionContext := fILG.DeclareLocal(typeof(ExecutionContext));
    
    if aFunction <> nil then begin
      fILG.Emit(OpCodes.Ldarg_0);
      Filg.Emit(Opcodes.Call, ExecutionContext.Method_get_LexicalScope);
      fILG.Emit(OpCodes.Ldarg_0);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Newobj, DeclarativeEnvironmentRecord.Constructor);
      filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 1 else 0);
      filg.Emit(Opcodes.Newobj, ExecutionContext.Constructor);
      filg.Emit(Opcodes.Stloc, fExecutionContext);

      for i: Integer := aFunction.Parameters.Count -1 downto 0 do begin
        filg.Emit(Opcodes.Ldloc, fExecutionContext);
        filg.Emit(Opcodes.Ldarg_2);
        filg.Emit(opcodes.Ldc_I4, i);
        filg.Emit(Opcodes.Ldstr, aFunction.Parameters[i].Name);
        filg.Emit(opcodes.Ldc_I4, if fUseStrict then 1 else 0);
        filg.Emit(Opcodes.Call, ExecutionContext.Method_StoreParameter);
      end;
      
      // public delegate(aScope: ExecutionContext; aSelf: Object; params args: array of Object; aFunc: EcmaScriptInternalFunctionObject): Object;
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_VariableScope);
      filg.Emit(Opcodes.Ldstr, 'arguments');
      filg.emit(Opcodes.Callvirt, EnvironmentRecord.Method_HasBinding);
      var lAlreadyHaveArguments := filg.DefineLabel;
      filg.Emit(Opcodes.Brtrue, lAlreadyHaveArguments);
      
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.ldarg_2);
      filg.Emit(Opcodes.Ldc_I4, aFunction.Parameters.Count);
      filg.Emit(Opcodes.Newarr, typeof(String));
      for i: Integer := 0 to aFunction.Parameters.Count -1 do begin
        filg.Emit(Opcodes.Dup);
        filg.Emit(Opcodes.Ldc_I4, i);
        filg.Emit(Opcodes.Ldstr, aFunction.Parameters[i].Name);
        filg.Emit(Opcodes.Stelem_Ref);
      end;

      filg.Emit(Opcodes.ldarg, 3);
      //eecution context, object[], function
      filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 1 else 0);
      filg.Emit(Opcodes.Newobj, EcmaScriptArgumentObject.Constructor);
      
      filg.Emit(Opcodes.Ldstr, 'arguments');
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_VariableScope);
      
      filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 11 else 0);
      filg.Emit(Opcodes.Ldc_I4_0);
      filg.Emit(Opcodes.Call, EnvironmentRecord.Method_CreateAndSetMutableBindingNoFail);

      filg.MarkLabel(lAlreadyHaveArguments);

      var lHaveThis := filg.DefineLabel;
      var lHaveNoThis := filg.DefineLabel;
      filg.Emit(Opcodes.Ldarg_1);
      filg.Emit(Opcodes.Call, Undefined.Method_Instance);
      filg.Emit(Opcodes.Beq, lHaveNoThis);
      filg.Emit(Opcodes.Ldarg_1);
      filg.Emit(Opcodes.Brfalse, lHaveNoThis);
      filg.Emit(Opcodes.Br, lHavethis);
      filg.MarkLabel(lHaveNoThis);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Starg, 1);
      filg.MarkLabel(lHaveThis);
    end else begin
      fILG.Emit(OpCodes.Ldarg_0);  // first execution context
      fILG.Emit(Opcodes.Stloc, fExecutionContext);
      if not aEval then begin
        filg.Emit(opcodes.Ldloc, fExecutionContext);
        filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 1 else 0);
        filg.Emit(Opcodes.Call, ExecutionContext.method_SetStrict);
      end;
    end;

    if fDebug then begin
      WriteDebugStack;
      filg.Emit(OpCodes.Ldstr, aScopeName);
      filg.Emit(Opcodes.Ldarg, 1); // this
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Callvirt, DebugSink.Method_EnterScope);
    end;
    if fStackProtect then begin
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Call, GlobalObject.Method_IncreaseFrame);
    end;
    fILG.BeginExceptionBlock; // finally
    
    if fDebug and not aEval and (aFunction = nil) then
      fILG.BeginExceptionBlock; // except
    var lOldExitLabel := fExitLabel;
    var lOldResultVar := fResultVar;
    fExitLabel := filg.DefineLabel;
    fResultVar := filg.DeclareLocal(typeof(Object));
    filg.Emit(Opcodes.Call, Undefined.Method_Instance);
    filg.Emit(Opcodes.Stloc, fResultVar);

    if not aEval and (aFunction = nil) then begin
      filg.Emit(Opcodes.Ldarg_1); // this
      var lIsNull := filg.DefineLabel;
      filg.Emit(Opcodes.Brfalse, lIsNull);
      filg.Emit(Opcodes.Ldarg_1); // this
      filg.Emit(OpCodes.Call, Undefined.Method_Instance);
      filg.Emit(opcodes.Beq, lIsnull);
      var lGotThis := filg.DefineLabel;
      filg.Emit(Opcodes.Br, lGotThis);
      filg.MarkLabel(lIsNull);
      filg.Emit(OpCodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Starg, 1); // this
      filg.MarkLabel(lGotThis);
    end;

    DefineInScope(aEval, aElements);

    for i: Integer := 0 to aElements.Count -1 do
      WriteStatement(aElements[i]);

    filg.BeginFinallyBlock();
    if fStackProtect then begin
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Call, GlobalObject.Method_DecreaseFrame);
    end;

    if fDebug then begin
      WriteDebugStack;
      filg.Emit(OpCodes.Ldstr, aScopeName);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Callvirt, DebugSink.Method_ExitScope);
    end;
    filg.EndExceptionBlock();
    if fDebug then begin
      if not aEval and (aFunction = nil) then begin
        filg.BeginCatchBlock(typeof(Exception));
        var lTemp := AllocateLocal(typeof(Exception));
        filg.Emit(Opcodes.Stloc, lTemp);
        WriteDebugStack;
        filg.Emit(Opcodes.Ldloc, lTemp);
        filg.Emit(Opcodes.Callvirt, Debugsink.Method_UncaughtException);
        filg.Emit(Opcodes.Rethrow);
        ReleaseLocal(lTemp);
        filg.EndExceptionBlock();
      end;
    end;
    filg.MarkLabel(fExitLabel);
    filg.Emit(Opcodes.Ldloc, fResultVar);
    filg.Emit(Opcodes.Ret);
  
    fExitLabel := lOldExitLabel;
    fResultVar := lOldResultVar;
    fIlg := lOldILG;
    fExecutionContext := lOldExecutionContext;
    fLocals := lOldLocals;
    fBreak := lOldBreak;
    fContinue := lOldContinue;
    if aFunction <> nil then 
    exit lMethod.CreateDelegate(typeof(InternalFunctionDelegate));
    exit lMethod.CreateDelegate(typeof(InternalDelegate));
  finally
    fUseStrict := lUseStrict;
    fStatementStack := lLoops;
  end;
end;

method EcmaScriptCompiler.WriteDebugStack;
begin
  fILG.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.Call, ExecutionContext.Method_GetDebugSink);
end;

method EcmaScriptCompiler.WriteStatement(El: SourceElement);
begin
  if el = nil then exit;
  if fDebug and (el.PositionPair.StartRow> 0) then begin
    WriteDebugStack;
    var lPos := el.PositionPair;
    filg.Emit(opcodes.Ldstr, lPos.File);
    filg.Emit(Opcodes.Ldc_I4, lPos.StartRow);
    filg.Emit(Opcodes.Ldc_I4, lPos.StartCol);
    filg.Emit(Opcodes.Ldc_I4, lPos.EndRow);
    filg.Emit(Opcodes.Ldc_I4, lPos.EndCol);
    filg.Emit(Opcodes.Callvirt, DebugSink.Method_DebugLine);
  end;
  if el is Statement then fStatementStack.Add(Statement(el));
  case el.Type of
    ElementType.EmptyStatement: begin
      filg.Emit(Opcodes.Nop);
    end;

    ElementType.ReturnStatement: begin
      if ReturnStatement(el).ExpressionElement = nil then 
        filg.Emit(Opcodes.Call, Undefined.Method_Instance)
      else begin
        WriteExpression(ReturnStatement(el).ExpressionElement);
        CallGetValue(ReturnStatement(el).ExpressionElement.Type);
      end;
      filg.Emit(Opcodes.Stloc, fResultVar);
      var lFinallyInfo := Enumerable.Reverse(fStatementStack).Where(a-> (a.Type = ElementType.TryStatement) and (TryStatement(a).FinallyData <> nil)).Select(a->TryStatement(a).FinallyData).ToArray;
      if lFinallyInfo.Length > 0 then begin
        for i: Integer := 0 to lFinallyInfo.length -1 do begin
          filg.Emit(Opcodes.Ldc_I4,  lFinallyInfo[i].AddUnique(if i < lFinallyInfo.length -1 then lFinallyInfo[i+1].FinallyLabel else fExitLabel));
          filg.Emit(Opcodes.Stloc, lFinallyInfo[i].FinallyState);
        end;
        if TryStatement(Enumerable.Reverse(fStatementStack).FirstOrDefault(a->a.Type = ElementType.TryStatement)).Catch <> nil then
          filg.Emit(Opcodes.Leave, lFinallyInfo[0].FinallyLabel) 
        else
          filg.Emit(Opcodes.Br, lFinallyInfo[0].FinallyLabel);
      end else
        filg.Emit(Opcodes.Leave, fExitLabel); // there's always an outside finally
    end;
    ElementType.ExpressionStatement: begin
      WriteExpression(ExpressionStatement(el).ExpressionElement);
      filg.Emit(Opcodes.Pop);
    end;
    ElementType.DebuggerStatement: begin
      WriteDebugStack;
      filg.Emit(opcodes.Callvirt, DebugSink.Method_Debugger);
    end;
    ElementType.VariableStatement: begin
      for i: Integer := 0 to VariableStatement(El).Items.Count- 1 do begin
        var lItem := VariableStatement(el).Items[i];
        if lItem.Initializer <> nil then begin
          WriteExpression(new BinaryExpression(lItem.PositionPair, new IdentifierExpression(lItem.PositionPair, lItem.Identifier), lItem.Initializer, BinaryOperator.Assign));
          filg.Emit(Opcodes.Pop);
        end;
      end;
    end;
    ElementType.BlockStatement: begin
      for each subitem in BlockStatement(el).Items do WriteStatement(subitem);
    end;
    ElementType.IfStatement: WriteIfStatement(IfStatement(El));
    ElementType.BreakStatement: WriteBreak(BreakStatement(El));
    ElementType.ContinueStatement: WriteContinue(ContinueStatement(el));
    ElementType.DoStatement: WriteDoStatement(DoStatement(el));
    ElementType.ForInStatement: WriteForInstatement(ForInStatement(el));
    ElementType.ForStatement: WriteForStatement(ForStatement(el));
    ElementType.WhileStatement: WriteWhileStatement(WhileStatement(el));
    ElementType.LabelledStatement: begin
      var lWas := fILG.DefineLabel;
      LabelledStatement(el).Break := lWas;
      WriteStatement(LabelledStatement(el).Statement);
      if lWas = Label(LabelledStatement(el).Break) then
        filg.MarkLabel(ValueOrDefault(LabelledStatement(el).Break));
    end;
    ElementType.FunctionDeclaration: begin
      // Do nothing here; this is done elsewhere
    end;
    ElementType.ThrowStatement: begin
      WriteExpression(ThrowStatement(el).ExpressionElement);
      CallGetValue(ThrowStatement(el).ExpressionElement.Type);
      filg.Emit(Opcodes.Call, ScriptRuntimeException.Method_Wrap);
      filg.Emit(Opcodes.Throw);
    end;
    ElementType.WithStatement: begin
      if fUseStrict then raise new ScriptParsingException(El.PositionPair.File, el.PositionPair, EcmaScriptErrorKind.WithNotAllowedInStrict);
      WriteWithStatement(WithStatement(el));
    end;
    ElementType.TryStatement: WriteTryStatement(TryStatement(el));
    ElementType.SwitchStatement: WriteSwitchstatement(SwitchStatement(el));
  else
    raise new EcmascriptException(El.PositionPair.File, el.PositionPair, EcmaScriptErrorKind.EInternalError, 'Unkwown type: '+el.Type);
  end; // case
  fStatementStack.Remove(Statement(el));
end;

method EcmaScriptCompiler.AllocateLocal(aType: &Type): LocalBuilder;
begin
  for i: Integer := 0 to fLocals.Count -1 do begin
    if fLocals[i].LocalType = aType then begin
      var lItem := fLocals[i];
      fLocals.RemoveAt(i);
      exit lItem;
    end;
  end;
  result := filg.DeclareLocal(aType);
end;

method EcmaScriptCompiler.ReleaseLocal(aLocal: LocalBuilder);
begin
  fLocals.Add(aLocal);
end;
{$REGION write expression}
method EcmaScriptCompiler.WriteExpression(aExpression: ExpressionElement);
begin
  case aExpression.Type of
    ElementType.ThisExpression: begin
      filg.Emit(Opcodes.Ldarg_1); // this is arg nr 1
    end;
    ElementType.NullExpression: filg.Emit(Opcodes.Ldnull);
    ElementType.StringExpression: begin
      filg.Emit(Opcodes.Ldstr, StringExpression(aExpression).Value);
    end;

    ElementType.BooleanExpression: begin
      if BooleanExpression(aExpression).Value then
        filg.Emit(Opcodes.Ldc_I4_1)
      else
        filg.Emit(Opcodes.Ldc_I4_0);
      filg.Emit(Opcodes.Box, typeof(Boolean));
    end;
    ElementType.IntegerExpression: begin
      if (IntegerExpression(aExpression).Value < Int64(Int32.MinValue)) or (IntegerExpression(aExpression).Value > Int64(Int32.MaxValue)) then begin
        filg.Emit(Opcodes.Ldc_R8, Double(IntegerExpression(aExpression).Value));
        filg.Emit(Opcodes.Box, typeof(Double));
      end else begin
        filg.Emit(Opcodes.Ldc_I4, IntegerExpression(aExpression).Value);
        filg.Emit(Opcodes.Box, typeof(Integer));
      end;
    end;
    ElementType.DecimalExpression: begin
      filg.Emit(Opcodes.Ldc_R8, DecimalExpression(aExpression).Value);
      filg.Emit(Opcodes.Box, typeof(Double));
    end;
    ElementType.RegExExpression: begin
      fILG.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Ldstr, RegExExpression(aExpression).String);
      filg.Emit(Opcodes.Ldstr, RegExExpression(aExpression).Modifier);
      filg.Emit(Opcodes.Newobj,typeof(EcmaScriptRegexpObject).GetConstructor([typeof(GlobalObject), typeof(String), typeof(String)]));
    end;
    ElementType.UnaryExpression: begin
      case UnaryExpression(aExpression).Operator of
        UnaryOperator.BinaryNot: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          CallGetValue(UnaryExpression(aExpressioN).Value.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_BitwiseNot);
        end;
        UnaryOperator.BoolNot: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          CallGetValue(UnaryExpression(aExpressioN).Value.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_LogicalNot);
        end;

        UnaryOperator.Delete: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Reference.Method_Delete);
          filg.Emit(Opcodes.Box, typeof(Boolean));
        end;

        UnaryOperator.Minus: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          CallGetValue(UnaryExpression(aExpressioN).Value.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Minus);
        end;

        UnaryOperator.Plus: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          CallGetValue(UnaryExpression(aExpressioN).Value.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Plus);
        end;
        UnaryOperator.PostDecrement: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.call, Operators.Method_PostDecrement);
        end;

        UnaryOperator.PostIncrement: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.call, Operators.Method_PostIncrement);
        end;
        UnaryOperator.PreDecrement: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.call, Operators.Method_PreDecrement);
        end;
        UnaryOperator.PreIncrement: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.call, Operators.Method_PreIncrement);
        end;
        UnaryOperator.TypeOf: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          //CallGetValue(UnaryExpression(aExpressioN).Value.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_TypeOf);
        end;
        UnaryOperator.Void: begin
          WriteExpression(UnaryExpression(aExpressioN).Value);
          CallGetValue(UnaryExpression(aExpressioN).Value.Type);
          filg.Emit(Opcodes.Pop);
          filg.Emit(OpCodes.Call, Undefined.Method_Instance);
        end;
        else raise new EcmaScriptException(aExpression.PositionPair.File, aExpression.PositionPair, EcmaScriptErrorKind.EInternalError, 'Unknown type: '+aExpression.Type);
      end; // case
    end;
    ElementType.IdentifierExpression: begin
      filg.Emit(OpCodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_LexicalScope);
      filg.Emit(Opcodes.Ldstr, IdentifierExpression(aExpression).Identifier);
      if fUseStrict then
        filg.Emit(Opcodes.Ldc_I4_1)
      else
        filg.Emit(Opcodes.Ldc_I4_0);
      filg.Emit(Opcodes.Call, EnvironmentRecord.Method_GetIdentifier);
    end;
    ElementType.BinaryExpression: begin
      case BinaryExpression(aExpression).Operator of
        BinaryOperator.Assign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call,  Reference.Method_SetValue);
        end;
        BinaryOperator.Plus: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Add);
        end;
        BinaryOperator.PlusAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Add);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Divide: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Divide);
        end;
        BinaryOperator.DivideAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Divide);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Minus: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Subtract);
        end;
        BinaryOperator.MinusAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Subtract);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.Modulus: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Modulus);
        end;
        BinaryOperator.ModulusAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Modulus);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.Multiply: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Multiply);
        end;
        BinaryOperator.MultiplyAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Multiply);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.ShiftLeft: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_ShiftLeft);
        end;
        BinaryOperator.ShiftLeftAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_ShiftLeft);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.ShiftRightSigned: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_ShiftRight);
        end;
        BinaryOperator.ShiftRightSignedAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_ShiftRight);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.ShiftRightUnsigned: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_ShiftRightUnsigned);
        end;
        BinaryOperator.ShiftRightUnsignedAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_ShiftRightUnsigned);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.And: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_And);
        end;
        BinaryOperator.AndAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_And);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Or: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Or);
        end;
        BinaryOperator.OrAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_OR);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Xor, BinaryOperator.DoubleXor: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_XOr);
        end;
        BinaryOperator.XorAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          filg.Emit(Opcodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_XOr);
          filg.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(Opcodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.Equal: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_Equal);
        end;

        BinaryOperator.NotEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_NotEqual);
        end;

        BinaryOperator.StrictEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_StrictEqual);
        end;

        BinaryOperator.StrictNotEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_StrictNotEqual);
        end;

        BinaryOperator.Less: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_LessThan);
        end;
        BinaryOperator.Greater: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_GreaterThan);
        end;
        BinaryOperator.LessOrEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_LessThanOrEqual);
        end;
        BinaryOperator.GreaterOrEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_GreaterThanOrEqual);
        end;        
        BinaryOperator.InstanceOf: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_InstanceOf);
        end;
        BinaryOperator.In: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Operators.Method_In);
        end;
        BinaryOperator.DoubleAnd: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          filg.Emit(Opcodes.Dup);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
          var lGotIt := filg.DefineLabel;
          filg.Emit(OpCodes.Brfalse, lGotIt);
          filg.Emit(Opcodes.Pop);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.MarkLabel(lGotIt);
        end;
        BinaryOperator.DoubleOr: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          filg.Emit(Opcodes.Dup);
          filg.Emit(Opcodes.Ldloc, fExecutionContext);
          filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
          var lGotIt := filg.DefineLabel;
          filg.Emit(OpCodes.Brtrue, lGotIt);
          filg.Emit(Opcodes.Pop);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          filg.MarkLabel(lGotIt);
        end;
      else
        raise new EcmaScriptException(aExpression.PositionPair.File, aExpression.PositionPair, EcmaScriptErrorKind.EInternalError, 'Unknown type: '+aExpression.Type);
      end; // case
    end;
    ElementType.ConditionalExpression: begin
      WriteExpression(ConditionalExpression(aExpression).Condition);
      CallGetValue(ConditionalExpression(aExpression).Condition.Type);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
      var lFalse := filg.DefineLabel;
      var lExit := filg.DefineLabel;
      filg.Emit(Opcodes.Brfalse, lFalse);
      WriteExpression(ConditionalExpression(aExpression).True);
      CallGetValue(ConditionalExpression(aExpression).True.Type);
      filg.Emit(Opcodes.Br, lExit);
      filg.MarkLabel(lFAlse);
      WriteExpression(ConditionalExpression(aExpression).False);
      CallGetValue(ConditionalExpression(aExpression).false.Type);
      filg.MarkLabel(lExit);
    end;
    ElementType.ArrayLiteralExpression: begin
      filg.Emit(Opcodes.Ldc_I4, ArrayLiteralExpression(aExpression).Items.Count);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Newobj, EcmaScriptArrayObject.Constructor);
      for each el in ArrayLiteralExpression(aExpression).Items do begin
        filg.Emit(Opcodes.Dup);
        if el = nil then  begin
          filg.Emit(Opcodes.Call, Undefined.Method_Instance);
        end else begin
          WriteExpression(el);
          CallGetValue(el.Type);
        end;
        filg.Emit(Opcodes.Call, EcmaScriptArrayObject.Method_AddValue);
      end;
    end;
    ElementType.ObjectLiteralExpression: begin
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Newobj, EcmaScriptObject.Constructor);
      for each el in ObjectLiteralExpression(aExpression).Items do begin
        case el.Name.Type of 
          ElementType.IdentifierExpression: filg.Emit(Opcodes.Ldstr, IdentifierExpression(el.Name).Identifier);
        else
          WriteExpression(el.Name);
        end; // case
        filg.Emit(Opcodes.Ldloc, fExecutionContext);
        filg.Emit(Opcodes.Call, Utilities.Method_GetObjAsString);
        filg.Emit(OpCodes.Ldc_I4, Integer(el.Mode));
        WriteExpression(el.Value);
        CallGetValue(El.Value.Type);
        filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 1 else 0);
        filg.Emit(Opcodes.Call, EcmaScriptObject.Method_ObjectLiteralSet);
      end;
    end;
    ElementType.SubExpression: begin
      WriteExpression(SubExpression(aExpression).Member);
      CallGetValue(SubExpression(aExpression).Member.Type);
      filg.emit(Opcodes.Ldstr, SubExpression(aExpression).Identifier);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 1 else 0);
      filg.Emit(Opcodes.Call, Reference.Method_Create);
    end;
    ElementType.ArrayAccessExpression: begin
      WriteExpression(ArrayAccessExpression(aExpression).Member);
      CallGetValue(ArrayAccessExpression(aExpression).Member.Type);
      
      WriteExpression(ArrayAccessExpression(aExpression).Parameter);
      CallGetValue(ArrayAccessExpression(aExpression).Parameter.Type);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 3 else 2);
      filg.Emit(Opcodes.Call, Reference.Method_Create);
    end;
    ElementType.NewExpression: begin
      WriteExpression(NewExpression(aExpression).Member);
      CallGetValue(NewExpression(aExpression).Member.Type);
      filg.Emit(Opcodes.Isinst, typeof(EcmaScriptObject));
      filg.Emit(Opcodes.Dup);
      var lIsObject := filg.DefineLabel;
      filg.Emit(Opcodes.Brtrue, lIsObject);
      filg.Emit(OpCodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Ldc_I4, Integer(NativeErrorType.TypeError));
      filg.Emit(Opcodes.Ldstr, 'Cannot instantiate non-object value');
      filg.Emit(Opcodes.Call, GlobalObject.Method_RaiseNativeError);
      filg.MarkLabel(lIsObject);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Ldc_I4, NewExpression(aExpression).Parameters.Count);
      filg.Emit(Opcodes.Newarr, typeof(Object));
      for each el in NewExpression(aExpression).Parameters index n do begin
        filg.Emit(OpCodes.Dup);
        filg.Emit(Opcodes.Ldc_I4, n);
        WriteExpression(el);
        CallGetValue(el.Type);
        filg.Emit(Opcodes.Stelem_Ref);
      end;

      filg.Emit(Opcodes.Callvirt, EcmaScriptObject.Method_Construct);
    end;

    ElementType.CallExpression: begin
      WriteExpression(CallExpression(aExpression).Member);
      filg.Emit(Opcodes.Ldarg_1); // self
      
      filg.Emit(Opcodes.Ldc_I4, CallExpression(aExpression).Parameters.Count);
      filg.Emit(Opcodes.Newarr, typeof(Object));
      for each el in CallExpression(aExpression).Parameters index n do begin
        filg.Emit(OpCodes.Dup);
        filg.Emit(Opcodes.Ldc_I4, n);
        WriteExpression(el);
        CallGetValue(el.Type);
        filg.Emit(Opcodes.Stelem_Ref);
      end;
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, EcmaScriptObject.Method_CallHelper);
    end;
    ElementType.CommaSeparatedExpression: // only for for
    begin
      for i: Integer := 0 to CommaSeparatedExpression(aExpression).Parameters.Count -1 do begin
        if i <> 0 then filg.Emit(Opcodes.Pop);
        WriteExpression(CommaSeparatedExpression(aExpression).Parameters[i]);
      end;
    end;

    ElementType.FunctionExpression: WriteFunction(FunctionExpression(aExpression).Function, false);
  else
    raise new EcmaScriptException(aExpression.PositionPair.File, aExpression.PositionPair, EcmaScriptErrorKind.EInternalError, 'Unknown type: '+aExpression.Type);
  end; // case
end;
{$ENDREGION write expression}

method EcmaScriptCompiler.CallGetValue(aFromElement: ElementType);
begin
  case aFromElement of
    ElementType.SubExpression,
    ElementType.CallExpression,
    ElementType.ArrayAccessExpression,
    ElementType.IdentifierExpression: ;
  else
    exit; // not needed
  end; // case
  // Expect: POSSIBLE reference on stack (always typed object)
  // Returns: Object value
  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.Call, Reference.Method_GetValue);

end;

method EcmaScriptCompiler.CallSetValue;
begin
  // Expect: POSSIBLE reference on stack (always typed object)
  // Expect: NON reference as second item on the stack
  // Returns: Object value
  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.Call, Reference.Method_SetValue);
end;

method EcmaScriptCompiler.RecursiveFindFuncAndVars(aElements: sequence of SourceElement): sequence of SourceElement;
begin
  for each el in aElements do begin
    if el = nil then continue;
    case el.Type of
      ElementType.FunctionDeclaration: yield el;
      ElementType.BlockStatement: yield RecursiveFindFuncAndVars(BlockStatement(el).Items.Cast<SourceElement>);
      ElementType.IfStatement: yield RecursiveFindFuncAndVars([IfStatement(el).True, IfStatement(el).False]);
      ElementType.LabelledStatement: yield RecursiveFindFuncAndVars([LabelledStatement(el).Statement]);
      ElementType.SwitchStatement: 
        begin
          for each els in SwitchStatement(el).Clauses do begin
            if els.Body <> nil then
              yield RecursiveFindFuncAndVars(els.Body.Cast<SourceElement>);
          end;
        end;
      ElementType.TryStatement: yield RecursiveFindFuncAndVars([TryStatement(el).Body, TryStatement(el).Finally, TryStatement(el).Catch:Body]);
      ElementType.VariableStatement: yield el;
      ElementType.VariableDeclaration: yield new VariableStatement(el.PositionPair, VariableDeclaration(el));
      ElementType.WithStatement: yield RecursiveFindFuncAndVars([WithStatement(el).Body]);
      ElementType.DoStatement: yield RecursiveFindFuncAndVars([DoStatement(el).Body]);
      ElementType.ForInStatement: yield RecursiveFindFuncAndVars([ForInStatement(el).Initializer, ForInStatement(el).ExpressionElement, ForInStatement(el).Body]);
      ElementType.ForStatement: yield RecursiveFindFuncAndVars([ForStatement(el).Initializer, ForStatement(el).Increment, ForStatement(el).Comparison, ForStatement(el).Body]);
      ElementType.WhileStatement: yield RecursiveFindFuncAndVars([WhileStatement(el).Body]);
    end; // case
  end;
end;

method EcmaScriptCompiler.WriteIfStatement(el: IfStatement);
begin
  if el.False = nil then begin
    WriteExpression(el.ExpressionElement);
    CallGetValue(el.ExpressionElement.Type);
    filg.Emit(Opcodes.Ldloc, fExecutionContext);
    filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
    var lFalse := filg.DefineLabel;
    filg.Emit(Opcodes.Brfalse, lFalse);
    WriteStatement(el.True);
    filg.MarkLabel(lFalse);
  end else if el.True = nil then begin
    WriteExpression(el.ExpressionElement);
    CallGetValue(el.ExpressionElement.Type);
    filg.Emit(Opcodes.Ldloc, fExecutionContext);
    filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
    var lTrue := filg.DefineLabel;
    filg.Emit(Opcodes.Brtrue, lTrue);
    WriteStatement(el.FAlse);
    filg.MarkLabel(lTrue);
  end else begin
    WriteExpression(el.ExpressionElement);
    CallGetValue(el.ExpressionElement.Type);
    filg.Emit(Opcodes.Ldloc, fExecutionContext);
    filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
    var lFalse := filg.DefineLabel;
    filg.Emit(Opcodes.Brfalse, lFalse);
    WriteStatement(el.True);
    var lExit := filg.DefineLabel;
    filg.Emit(Opcodes.Br, lExit);
    filg.MarkLabel(lFalse);
    WriteStatement(el.False);
    fILG.MarkLabel(lExit);
  end;
end;

method EcmaScriptCompiler.WriteContinue(el: ContinueStatement);
var
  lPassedTry: Boolean := false;
begin
  var lFinallyInfo: List<FinallyInfo> := nil;
  if el.Identifier = nil then begin
    if fContinue = nil then 
     raise new ScriptParsingException(el.PositionPair.File, el.PositionPair, EcmaScriptErrorKind.CannotContinueHere);
    for i: Integer := fStatementStack.Count -1 downto 0 do begin
      if fStatementStack[i].Type = ElementType.TryStatement then begin
        lPassedTry := true;
        if TryStatement(fStatementStack[i]).FinallyData <> nil then begin
          if  lFinallyInfo = nil then lFinallyInfo := new List<FinallyInfo>;
          lFinallyInfo.Add(TryStatement(fStatementStack[i]).FinallyData);
        end;
      end else if IterationStatement(fStatementStack[i]):&Continue = fContinue then begin
        break;
      end;
    end;
    if lPassedTry then begin
      if lFinallyInfo <> nil then begin
        for i: Integer := 0 to lFinallyInfo.Count -1 do begin
          filg.Emit(Opcodes.Ldc_I4,  lFinallyInfo[i].AddUnique(if i < lFinallyInfo.Count -1 then lFinallyInfo[i+1].FinallyLabel else Label(fContinue)));
          filg.Emit(Opcodes.Stloc, lFinallyInfo[i].FinallyState);
        end;
        if TryStatement(Enumerable.Reverse(fStatementStack).FirstOrDefault(a->a.Type = ElementType.TryStatement)).Catch <> nil then
          filg.Emit(Opcodes.Leave, lFinallyInfo[0].FinallyLabel) 
        else
          filg.Emit(Opcodes.Br, lFinallyInfo[0].FinallyLabel);
      end else
        filg.Emit(Opcodes.Leave, Label(fContinue));
    end else
      filg.Emit(Opcodes.br, Label(fContinue));
  end else begin
    for i: Integer := fStatementStack.Count -1 downto 0 do begin
      var lIt := LabelledStatement(fStatementStack[i]);
      if fStatementStack[i].Type = ElementType.TryStatement then begin
        lPassedTry := true;
        if TryStatement(fStatementStack[i]).Finally <> nil then begin
          if  lFinallyInfo = nil then lFinallyInfo := new List<FinallyInfo>;
          lFinallyInfo.Add(TryStatement(fStatementStack[i]).FinallyData);
        end;
      end else if (lIt <> nil) and (lIt.Identifier = el.Identifier) then begin
        if lPassedTry then begin
          if lFinallyInfo <> nil then begin
            for j: Integer := 0 to lFinallyInfo.Count -1 do begin
              filg.Emit(Opcodes.Ldc_I4,  lFinallyInfo[j].AddUnique(if j < lFinallyInfo.Count -1 then lFinallyInfo[j+1].FinallyLabel else Label(lIt.Continue)));
              filg.Emit(Opcodes.Stloc, lFinallyInfo[j].FinallyState);
            end;
            if TryStatement(Enumerable.Reverse(fStatementStack).FirstOrDefault(a->a.Type = ElementType.TryStatement)).Catch <> nil then
              filg.Emit(Opcodes.Leave, lFinallyInfo[0].FinallyLabel) 
            else
            filg.Emit(Opcodes.Br, lFinallyInfo[0].FinallyLabel);
          end else
            filg.Emit(Opcodes.Leave, Label(lIt.Continue));
        end else begin
          if lIt.Continue = nil then 
            filg.Emit(Opcodes.Leave, fExitLabel) else 
          filg.Emit(Opcodes.leave, Label(lIt.Continue));
        end;
        exit;
       end;
    end;
    raise new ScriptParsingException(el.PositionPair.File, el.PositionPair, EcmaScriptErrorKind.UnknownLabelTarget, el.Identifier);
  end;
end;

method EcmaScriptCompiler.WriteBreak(el: BreakStatement);
var
  lPassedTry: Boolean := false;
begin
  var lFinallyInfo: List<FinallyInfo> := nil;
  if el.Identifier = nil then begin
    if fBreak = nil then 
     raise new ScriptParsingException(el.PositionPair.File, el.PositionPair, EcmaScriptErrorKind.CannotBreakHere);
    for i: Integer := fStatementStack.Count -1 downto 0 do begin
      if fStatementStack[i].Type = ElementType.TryStatement then begin
        lPassedTry := true;
        if TryStatement(fStatementStack[i]).FinallyData <> nil then begin
          if  lFinallyInfo = nil then lFinallyInfo := new List<FinallyInfo>;
          lFinallyInfo.Add(TryStatement(fStatementStack[i]).FinallyData);
        end;
      end else if IterationStatement(fStatementStack[i]):&Break = fBreak then begin
        break;
      end;
    end;
    if lPassedTry then begin
      if lFinallyInfo <> nil then begin
        for i: Integer := 0 to lFinallyInfo.Count -1 do begin
          filg.Emit(Opcodes.Ldc_I4,  lFinallyInfo[i].AddUnique(if i < lFinallyInfo.Count -1 then lFinallyInfo[i+1].FinallyLabel else Label(fBreak)));
          filg.Emit(Opcodes.Stloc, lFinallyInfo[i].FinallyState);
        end;
        filg.Emit(Opcodes.Br, lFinallyInfo[0].FinallyLabel);
      end else
        filg.Emit(Opcodes.Leave, Label(fBreak));
    end else
      filg.Emit(Opcodes.br, Label(fBreak));
  end else begin
    for i: Integer := fStatementStack.Count -1 downto 0 do begin
      var lIt := LabelledStatement(fStatementStack[i]);
      if fStatementStack[i].Type = ElementType.TryStatement then begin
        lPassedTry := true;
        if TryStatement(fStatementStack[i]).Finally <> nil then begin
          if  lFinallyInfo = nil then lFinallyInfo := new List<FinallyInfo>;
          lFinallyInfo.Add(TryStatement(fStatementStack[i]).FinallyData);
        end;
      end else if (lIt <> nil) and (lIt.Identifier = el.Identifier) then begin
        if lPassedTry then begin
          if lFinallyInfo <> nil then begin
            for j: Integer := 0 to lFinallyInfo.Count -1 do begin
              filg.Emit(Opcodes.Ldc_I4,  lFinallyInfo[j].AddUnique(if j < lFinallyInfo.Count -1 then lFinallyInfo[j+1].FinallyLabel else Label(lIt.Break)));
              filg.Emit(Opcodes.Stloc, lFinallyInfo[j].FinallyState);
            end;
            filg.Emit(Opcodes.Br, lFinallyInfo[0].FinallyLabel);
          end else
            filg.Emit(Opcodes.Leave, Label(lIt.Break));
        end else begin
          filg.Emit(Opcodes.leave, Label(lIt.Break));
        end;
        exit;
       end;
    end;
    raise new ScriptParsingException(el.PositionPair.File, el.PositionPair, EcmaScriptErrorKind.UnknownLabelTarget, el.Identifier);
  end;
end;


method EcmaScriptCompiler.MarkLabelled(aBreak, aContinue: nullable Label);
begin
  var lLoopItem := IterationStatement(fStatementStack[fStatementStack.Count -1]);
  if lLoopItem <> nil then begin
    lLoopItem.Break := aBreak;
    lLoopItem.Continue := aContinue;
  end;

  for i: Integer := fStatementStack.Count -2 downto 0 do begin // -1 = current
    var lItem := LabelledStatement(fStatementStack[i]);
    if lItem = nil then exit;
    lItem.Break := coalesce(aBreak, lItem.Break);
    lItem.Continue := coalesce(aContinue, lItem.Continue)
  end;
end;

method EcmaScriptCompiler.WriteFunction(el: FunctionDeclarationElement; aRegister: Boolean);
begin
  var lDelegate: InternalFunctionDelegate := InternalFunctionDelegate(Parse(el, false, el.Identifier, el.Items));
  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.call, ExecutionContext.Method_get_Global);
  if el.Identifier = nil then begin
    filg.Emit(Opcodes.Ldloc, fExecutionContext);
    filg.Emit(Opcodes.Call, ExecutionContext.Method_get_LexicalScope);
  end else begin
    if aRegister then begin
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_VariableScope);
    end else begin
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_LexicalScope);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_Global);
      filg.Emit(Opcodes.Newobj, DeclarativeEnvironmentRecord.Constructor);
    end;
  end;
  if el.Identifier = nil then 
    filg.Emit(Opcodes.Ldnull)
  else
    filg.Emit(Opcodes.Ldstr, el.Identifier);
  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.call, ExecutionContext.Method_get_Global);
  filg.Emit(Opcodes.Ldc_I4, fGlobal.StoreFunction(lDelegate));
  filg.Emit(Opcodes.Call, GlobalObject.Method_GetFunction);
  
  filg.Emit(Opcodes.Ldc_I4, el.Parameters.Count);
  filg.Emit(Opcodes.Ldc_I4, if fUseStrict then 1 else 0);
  filg.Emit(Opcodes.Newobj, EcmaScriptInternalFunctionObject.Constructor);

  
  if (el.Identifier<> nil) and not aRegister then begin
    //class method SetAndInitializeImmutable(val: EcmaScriptFunctionObject; aName: string): EcmaScriptFunctionObject;
    filg.Emit(opcodes.Ldstr, el.Identifier);
    filg.Emit(Opcodes.Call, DeclarativeEnvironmentRecord.Method_SetAndInitializeImmutable);
  end;
    
  
end;

method EcmaScriptCompiler.WriteDoStatement(el: DoStatement);
begin
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;
  fBreak := filg.DefineLabel;
  MarkLabelled(fBreak, fContinue);
  filg.MarkLabel(Label(fContinue));

  WriteStatement(el.Body);

  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
  filg.Emit(Opcodes.Brtrue, Label(fContinue));
  filg.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;

method EcmaScriptCompiler.WriteWhileStatement(el: WhileStatement);
begin
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;
  fBreak := filg.DefineLabel;
  MarkLabelled(fBreak, fContinue);
  filg.MarkLabel(Label(fContinue));
  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
  filg.Emit(Opcodes.Brfalse, Label(fBreak));


  WriteStatement(el.Body);

  filg.Emit(Opcodes.Br, Label(fContinue));
  filg.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;

method EcmaScriptCompiler.WriteForInstatement(el: ForInStatement);
begin
  var lLocal := AllocateLocal(typeof(IEnumerator<string>));
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;

  var lCurrent := lLocal.LocalType.GetMethod('get_Current');
  var lMoveNext :=  typeof(System.Collections.IEnumerator).GetMethod('MoveNext');
  fBreak := filg.DefineLabel;
  
  var lWork := if assigned(el.Initializer:Identifier) then new IdentifierExpression(el.Initializer.PositionPair, el.Initializer.Identifier) else el.LeftExpression;

  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  filg.Emit(Opcodes.Isinst, typeOf(EcmaScriptObject));
  filg.Emit(Opcodes.dup);
  var lPopAndBreak := filg.DefineLabel;
  filg.Emit(Opcodes.Brfalse, lPopAndBreak);
  filg.Emit(Opcodes.CallVirt, EcmaScriptObject.Method_GetNames);
  filg.Emit(Opcodes.Stloc, lLocal);
 
   MarkLabelled(fBreak, fContinue);

  filg.MarkLabel(Label(fContinue));
  filg.Emit(Opcodes.ldloc, lLocal);
  filg.Emit(Opcodes.CallVirt, lMoveNext);
  filg.Emit(Opcodes.Brfalse, Label(fBreak));

  WriteExpression(lWork);
  filg.Emit(Opcodes.Ldloc, lLocal);
  filg.Emit(Opcodes.callVirt, lCurrent);
  CallSetValue();
  filg.Emit(Opcodes.Pop); // set value returns something

  WriteStatement(el.Body);

  filg.Emit(Opcodes.Br, Label(fContinue));
  filg.MarkLabel(lPopAndBreak);
  filg.Emit(Opcodes.Pop);
  filg.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;

  ReleaseLocal(lLocal);
end;

method EcmaScriptCompiler.WriteForStatement(el: ForStatement);
begin
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;
  fBreak := filg.DefineLabel;
  MarkLabelled(fBreak, fContinue);

  if el.Initializer <> nil then begin
    WriteExpression(el.Initializer);
    filg.Emit(Opcodes.Pop);
  end;
  for each eli in el.Initializers do begin
    if eli.Initializer <> nil then begin
      WriteExpression(new BinaryExpression(eli.PositionPair, new IdentifierExpression(eli.PositionPair, eli.Identifier), eli.Initializer, BinaryOperator.Assign));
      filg.Emit(Opcodes.Pop);
    end;
  end;
  var lLoopStart := filg.DefineLabel;
  filg.MarkLabel(lLoopStart);
  if el.Comparison <> nil then begin
    WriteExpression(el.Comparison);
    CallGetValue(el.Comparison.Type);
    filg.Emit(Opcodes.Ldloc, fExecutionContext);
    filg.Emit(Opcodes.Call, Utilities.method_GetObjAsBoolean);
    filg.Emit(Opcodes.Brfalse, Label(fBreak));
  end;

  WriteStatement(el.Body);

  filg.MarkLabel(Label(fContinue));
  
  if assigned(el.Increment) then begin
    WriteExpression(el.Increment);
    filg.Emit(Opcodes.Pop);
  end;

  filg.Emit(Opcodes.Br, lLoopStart);

  filg.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;

method EcmaScriptCompiler.WriteWithStatement(el: WithStatement);
begin
  var lOld := AllocateLocal(typeof(ExecutionContext));
  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  filg.Emit(Opcodes.Stloc, lOld);
  filg.BeginExceptionBlock;

  filg.Emit(Opcodes.Ldloc, fExecutionContext);
  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  filg.Emit(Opcodes.Call, ExecutionContext.Method_With);
  filg.Emit(Opcodes.Stloc, fExecutionContext);

  WriteStatement(el.Body);

  filg.BeginFinallyBlock();
  filg.Emit(Opcodes.Ldloc, lOld);
  filg.Emit(Opcodes.Stloc, fExecutionContext);
  filg.EndExceptionBlock();

  ReleaseLocal(lOld);
end;

method EcmaScriptCompiler.WriteTryStatement(el: TryStatement);
begin
  if el.Finally <> nil then begin
    el.FinallyData := new FinallyInfo();
    el.FinallyData.FinallyLabel := filg.DefineLabel;
    el.FinallyData.FinallyState := AllocateLocal(typeof(Integer));
    filg.BeginExceptionBlock;
  end;
  if el.Catch <> nil then filg.BeginExceptionBlock;

   if el.Body <> nil then WriteStatement(el.Body);
  
  if el.Catch <> nil then begin
    filg.BeginCatchBlock(typeof(Exception));
    filg.Emit(Opcodes.Call, ScriptRuntimeException.Method_Unwrap);
    filg.Emit(Opcodes.Ldloc, fExecutionContext);
    filg.Emit(Opcodes.Ldstr, el.Catch.Identifier);
    filg.Emit(Opcodes.Call, ExecutionContext.Method_Catch);
    var lVar := AllocateLocal(typeof(fExecutionContext));
    filg.Emit(Opcodes.Stloc,  lVar);
    var lold := fExecutionContext;
    fExecutionContext := lVar;
    //DefineInScope(false, [el.Catch.Body]);
    WriteStatement(el.Catch.Body);

    ReleaseLocal(lVar);

    fExecutionContext := lOld;
    filg.EndExceptionBlock();
  end;

  if el.Finally <> nil then begin
    var lData := el.FinallyData;
    el.FinallyData := nil;
    filg.Emit(Opcodes.Ldc_I4_M1);
    filg.Emit(Opcodes.Stloc, lData.FinallyState);
    filg.MarkLabel(lData.FinallyLabel);
    WriteStatement(el.Finally);
    filg.Emit(Opcodes.Ldloc, lData.FinallyState);
    filg.Emit(Opcodes.Switch, lData.JumpTable.ToArray);
    filg.BeginCatchBlock(typeof(Exception));
    filg.Emit(Opcodes.Pop);
    WriteStatement(el.Finally);
    filg.Emit(Opcodes.Rethrow);
    filg.EndExceptionBlock();
  end;
end;

method EcmaScriptCompiler.WriteSwitchstatement(el: SwitchStatement);
begin
  var lLabels: array of Label := new Label[el.Clauses.Count];
  for i: Integer := 0 to lLabels.length -1 do begin
    lLabels[i] := filg.DefineLabel;
  end;

  var lWork := AllocateLocal(typeof(Object));
  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  filg.Emit(Opcodes.Stloc, lWork);
  
  var lGotDefault := false;
  for I: integer := 0 to el.Clauses.Count -1 do begin
    if el.Clauses[i].ExpressionElement = nil then lGotDefault := true else begin
      filg.Emit(opcodes.Ldloc, lWork);
      WriteExpression(el.Clauses[i].ExpressionElement);
      CallGetValue(el.ExpressionElement.Type);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, Operators.Method_StrictEqual);
      filg.Emit(Opcodes.Brtrue, lLabels[i]);
    end;
  end;
  if lGotDefault then begin
    for I: integer := 0 to el.Clauses.Count -1 do begin
      if el.Clauses[i].ExpressionElement = nil then begin
        filg.Emit(Opcodes.Br, lLabels[i]);
        break;
      end;
    end;
  end;

  ReleaseLocal(lWork);

  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fBreak := filg.DefineLabel;
  MarkLabelled(fBreak, nil);
  if not lGotDefault then filg.Emit(Opcodes.Br, Label(fBreak));
  

  for i: Integer := 0 to el.Clauses.Count -1 do begin
    filg.MarkLabel(lLabels[i]);
    for each bodyelement in el.Clauses[i].Body do
      WriteStatement(bodyelement);
  end;

  filg.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;


method EcmaScriptCompiler.DefineInScope(aEval: Boolean; aElements: sequence of SourceElement);
begin
  for each el in RecursiveFindFuncAndVars(aElements) do begin
    if el.Type = ElementType.FunctionDeclaration then begin
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_VariableScope);
      filg.Emit(Opcodes.Ldstr, FunctionDeclarationElement(el).Identifier);
      if aEval then 
        filg.Emit(Opcodes.Ldc_I4_1) 
      else
        filg.Emit(Opcodes.Ldc_I4_0);
      filg.Emit(Opcodes.Call, EnvironmentRecord.Method_CreateMutableBindingNoFail);
      filg.Emit(Opcodes.Ldloc, fExecutionContext);
      filg.Emit(Opcodes.Call, ExecutionContext.Method_get_VariableScope);
      filg.Emit(Opcodes.Ldstr, FunctionDeclarationElement(el).Identifier);
      WriteFunction(FunctionDeclarationElement(el), true);
      if fUseStrict then
        filg.Emit(Opcodes.Ldc_I4_1) 
      else
        filg.Emit(Opcodes.Ldc_I4_0);
      filg.Emit(Opcodes.Callvirt, EnvironmentRecord.Method_SetMutableBinding);
    end else if el.Type = ElementType.VariableStatement then begin
      for each en in VariableStatement(el).Items do begin
        filg.Emit(Opcodes.Ldloc, fExecutionContext);
        filg.Emit(Opcodes.Call, ExecutionContext.Method_get_VariableScope);
        filg.Emit(Opcodes.Ldstr, en.Identifier);
        if aEval then
          filg.Emit(Opcodes.Ldc_I4_1) 
        else
          filg.Emit(Opcodes.Ldc_I4_0);
        filg.Emit(Opcodes.Call, EnvironmentRecord.Method_CreateMutableBindingNoFail);
      end;
    end;
  end;
end;

method FinallyInfo.AddUnique(aLabel: Label): Integer;
begin
  for i: Integer := 0 to JumpTable.Count - 1 do
    if JumpTable[i].Equals(aLabel) then exit i;
  JumpTable.Add(aLabel);
  exit JumpTable.Count -1;
end;

end.