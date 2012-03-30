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
    EnterInRegex,
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
    class method ErrorToString(anError: EcmaScriptErrorKind; aMsg: String): String;
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
    property JustFunctions: Boolean;
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
    fLastData: String;
  private
    fGlobal: GlobalObject;
    fUseStrict: Boolean;
    fStackProtect, fDebug: Boolean;
    fExitLabel: Label;
    fExcept: LocalBuilder;
    fResultVar: LocalBuilder;
    fExecutionContext: LocalBuilder;
    fILG: ILGenerator;
    fLocals: List<LocalBuilder>;
    fJustFunctions, fDisableResult: Boolean;
    fStatementStack: List<Statement>;
    fBreak,
    fContinue: nullable Label;
    method Parse(aFilename, aData: String; aEval: Boolean := false): List<SourceElement>; // eval throws different exception
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
    method GetOriginalBody(el: SourceElement): String;
    method WriteTryStatement(el: TryStatement);
    method WriteSwitchstatement(el: SwitchStatement);
    method DefineInScope(aEval: Boolean; aElements: sequence of SourceElement);
  public
    constructor(aOptions: EcmaScriptCompilerOptions);


    property GlobalObject: GlobalObject read fGlobal;
    
    method EvalParse(aStrict: Boolean; aData: String): InternalDelegate;
    method Parse(aFilename, aData: String): InternalDelegate;
    method Parse(aFunction: FunctionDeclarationElement; aEval: Boolean; aScopeName: String; aElements: List<SourceElement>): Object;
    property JustFunctions: Boolean read fJustFunctions write fJustFunctions;
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

class method ScriptParsingException.ErrorToString(anError: EcmaScriptErrorKind; aMsg: String): String;
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
    EcmaScriptErrorKind.OnlyOneDefaultAllowed: result := String.Format(Resources.eOnlyOneDefaultAllowed, aMsg);
    EcmaScriptErrorKind.CannotAssignValueToExpression: result := String.Format(Resources.eCannotAssignValueToExpression, aMsg);
    EcmaScriptErrorKind.UnknownLabelTarget:result := String.Format(Resources.eUnknownLabelTarget, aMsg);
    EcmaScriptErrorKind.DuplicateLabel: result := String.Format(Resources.eDuplicateIdentifier, aMsg);
  else
    result := Resources.eSyntaxError;
  end; // case
end;


method EcmaScriptCompiler.Parse(aFilename, aData: String; aEval: Boolean := false): List<SourceElement>;
begin
  var lTokenizer := new Tokenizer;
  var lParser := new Parser;
  lTokenizer.Error += lParser.fTok_Error;
  lTokenizer.SetData(aData, aFilename);
  lTokenizer.Error -= lParser.fTok_Error;
  fLastData := aData;
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
    fJustFunctions := aOptions.JustFunctions;
    fStackProtect := aOptions.StackOverflowProtect;
  end else fStackProtect := true;
  if fGlobal = nil then fGlobal := new GlobalObject(self);
  fRoot := new ObjectEnvironmentRecord(aOptions:Context, fGlobal, false);
end;


method EcmaScriptCompiler.EvalParse(aStrict: Boolean; aData: String): InternalDelegate;
begin
  fUseStrict := aStrict;
  var lSave := fLastData;
  try
    exit InternalDelegate(Parse(nil, true, '<eval>', Parse('<eval>', aData, true)));
  finally
    fLastData := lSave;
  end;
end;

method EcmaScriptCompiler.Parse(aFilename, aData: String): InternalDelegate;
begin
  var lSave := fLastData;
  try
    exit InternalDelegate(Parse(nil, false, aFilename, Parse( aFilename, aData, false)));
  finally
    fLastData := lSave;
  end;
end;

method EcmaScriptCompiler.Parse(aFunction: FunctionDeclarationElement; aEval: Boolean; aScopeName: String; aElements: List<SourceElement>): Object;
begin
  if aScopeName = nil then aScopeName := '<anonymous>';
  var lUseStrict := fUseStrict;
  var lLoops := fStatementStack;
  fStatementStack := new List<Statement>;
  var lOldDisableResults := fDisableResult;
  fDisableResult := aFunction <> nil;
  try
    if aElements.Count <> 0 then begin
      if aElements.Count > 1 then begin
        if (aElements[0].Type = ElementType.ExpressionStatement) and (ExpressionStatement(aElements[0]).ExpressionElement.Type = ElementType.StringExpression) then begin
          if StringExpression(ExpressionStatement(aElements[0]).ExpressionElement).Value = 'use strict' then begin
            fUseStrict := true;
            aElements.RemoveAt(0);
          end;
        end;
      end;
    end; 

    var lOldLocals := fLocals;
    fLocals := new List<LocalBuilder>;
    var lMethod: DynamicMethod;
    {$IFDEF SILVERLIGHT} 
    if aFunction <> nil then
      lMethod := new System.Reflection.Emit.DynamicMethod(aSCopeName, typeOf(Object), [typeOf(ExecutionContext), typeOf(object), Typeof(array of Object), typeOf(EcmaScriptInternalFunctionObject)])
    else
      lMethod := new System.Reflection.Emit.DynamicMethod(aSCopeName, typeOf(Object), [typeOf(ExecutionContext), typeOf(object), Typeof(array of Object)]);
    {$ELSE}
    if aFunction <> nil then
      lMethod := new System.Reflection.Emit.DynamicMethod(aScopeName, typeOf(Object), [typeOf(ExecutionContext), typeOf(Object), typeOf(array of Object), typeOf(EcmaScriptInternalFunctionObject)], typeOf(DynamicMethods), true)
    else
      lMethod := new System.Reflection.Emit.DynamicMethod(aScopeName, typeOf(Object), [typeOf(ExecutionContext), typeOf(Object), typeOf(array of Object)], typeOf(DynamicMethods), true);
    {$ENDIF}
    var lOldBreak := fBreak;
    var lOldContinue := fContinue;
    fBreak := nil;
    fContinue := nil;
    var lOldILG := fILG;
    fILG := lMethod.GetILGenerator();
    var lOldExecutionContext := fExecutionContext;
    fExecutionContext := fILG.DeclareLocal(typeOf(ExecutionContext));
    
    if aFunction <> nil then begin
      fILG.Emit(OpCodes.Ldarg_0);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_LexicalScope);
      fILG.Emit(OpCodes.Ldarg_0);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Newobj, DeclarativeEnvironmentRecord.Constructor);
      fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 1 else 0);
      fILG.Emit(OpCodes.Newobj, ExecutionContext.Constructor);
      fILG.Emit(OpCodes.Stloc, fExecutionContext);

      for i: Integer := aFunction.Parameters.Count -1 downto 0 do begin
        fILG.Emit(OpCodes.Ldloc, fExecutionContext);
        fILG.Emit(OpCodes.Ldarg_2);
        fILG.Emit(OpCodes.Ldc_I4, i);
        fILG.Emit(OpCodes.Ldstr, aFunction.Parameters[i].Name);
        fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 1 else 0);
        fILG.Emit(OpCodes.Call, ExecutionContext.Method_StoreParameter);
      end;
      
      // public delegate(aScope: ExecutionContext; aSelf: Object; params args: array of Object; aFunc: EcmaScriptInternalFunctionObject): Object;
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_VariableScope);
      fILG.Emit(OpCodes.Ldstr, 'arguments');
      fILG.Emit(OpCodes.Callvirt, EnvironmentRecord.Method_HasBinding);
      var lAlreadyHaveArguments := fILG.DefineLabel;
      fILG.Emit(OpCodes.Brtrue, lAlreadyHaveArguments);
      
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Ldarg_2);
      fILG.Emit(OpCodes.Ldc_I4, aFunction.Parameters.Count);
      fILG.Emit(OpCodes.Newarr, typeOf(String));
      for i: Integer := 0 to aFunction.Parameters.Count -1 do begin
        fILG.Emit(OpCodes.Dup);
        fILG.Emit(OpCodes.Ldc_I4, i);
        fILG.Emit(OpCodes.Ldstr, aFunction.Parameters[i].Name);
        fILG.Emit(OpCodes.Stelem_Ref);
      end;

      fILG.Emit(OpCodes.Ldarg, 3);
      //eecution context, object[], function
      fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 1 else 0);
      fILG.Emit(OpCodes.Newobj, EcmaScriptArgumentObject.Constructor);
      
      fILG.Emit(OpCodes.Ldstr, 'arguments');
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_VariableScope);
      
      fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 11 else 0);
      fILG.Emit(OpCodes.Ldc_I4_0);
      fILG.Emit(OpCodes.Call, EnvironmentRecord.Method_CreateAndSetMutableBindingNoFail);

      fILG.MarkLabel(lAlreadyHaveArguments);

      var lHaveThis := fILG.DefineLabel;
      var lHaveNoThis := fILG.DefineLabel;
      fILG.Emit(OpCodes.Ldarg_1);
      fILG.Emit(OpCodes.Call, Undefined.Method_Instance);
      fILG.Emit(OpCodes.Beq, lHaveNoThis);
      fILG.Emit(OpCodes.Ldarg_1);
      fILG.Emit(OpCodes.Brfalse, lHaveNoThis);
      fILG.Emit(OpCodes.Br, lHaveThis);
      fILG.MarkLabel(lHaveNoThis);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Starg, 1);
      fILG.MarkLabel(lHaveThis);
    end else begin
      fILG.Emit(OpCodes.Ldarg_0);  // first execution context
      fILG.Emit(OpCodes.Stloc, fExecutionContext);
      if not aEval then begin
        fILG.Emit(OpCodes.Ldloc, fExecutionContext);
        fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 1 else 0);
        fILG.Emit(OpCodes.Call, ExecutionContext.method_SetStrict);
      end;
    end;

    if fDebug then begin
      WriteDebugStack;
      fILG.Emit(OpCodes.Ldstr, aScopeName);
      fILG.Emit(OpCodes.Ldarg, 1); // this
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Callvirt, DebugSink.Method_EnterScope);
    end;
    if fStackProtect then begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Call, GlobalObject.Method_IncreaseFrame);
    end;
    if fDebug then fILG.BeginExceptionBlock; // filter
    fILG.BeginExceptionBlock; // finally
    
    if fDebug and not aEval and (aFunction = nil) then
      fILG.BeginExceptionBlock; // except
    var lOldExitLabel := fExitLabel;
    var lOldResultVar := fResultVar;
    var lOldExcept := fExcept;
    if fDebug then begin
      fExcept := fILG.DeclareLocal(typeOf(Boolean));
      fILG.Emit(OpCodes.Ldc_I4_0);
      fILG.Emit(OpCodes.Stloc, fExcept);
    end;
    fExitLabel := fILG.DefineLabel;
    fResultVar := fILG.DeclareLocal(typeOf(Object));
    fILG.Emit(OpCodes.Call, Undefined.Method_Instance);
    fILG.Emit(OpCodes.Stloc, fResultVar);

    if not aEval and (aFunction = nil) then begin
      fILG.Emit(OpCodes.Ldarg_1); // this
      var lIsNull := fILG.DefineLabel;
      fILG.Emit(OpCodes.Brfalse, lIsNull);
      fILG.Emit(OpCodes.Ldarg_1); // this
      fILG.Emit(OpCodes.Call, Undefined.Method_Instance);
      fILG.Emit(OpCodes.Beq, lIsNull);
      var lGotThis := fILG.DefineLabel;
      fILG.Emit(OpCodes.Br, lGotThis);
      fILG.MarkLabel(lIsNull);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Starg, 1); // this
      fILG.MarkLabel(lGotThis);
    end;

    DefineInScope(aEval, aElements);
    var lJustFunction := fJustFunctions and (aFunction = nil) and not aEval;

    for i: Integer := 0 to aElements.Count -1 do begin
      if not lJustFunction or (aElements[i].Type = ElementType.FunctionDeclaration) then 
        WriteStatement(aElements[i]);
    end;

    if fDebug then begin // filter
      fILG.BeginCatchBlock(typeOf(Object));
      fILG.Emit(OpCodes.Stloc, fResultVar);
      fILG.Emit(OpCodes.Ldc_I4_1);
      fILG.Emit(OpCodes.Stloc, fExcept);
      fILG.Emit(OpCodes.Rethrow);
      fILG.EndExceptionBlock;
    end;

    fILG.BeginFinallyBlock();
    if fStackProtect then begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Call, GlobalObject.Method_DecreaseFrame);
    end;

    if fDebug then begin
      WriteDebugStack;
      fILG.Emit(OpCodes.Ldstr, aScopeName);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Ldloc, fResultVar);
      fILG.Emit(OpCodes.Ldloc, fExcept);
      fILG.Emit(OpCodes.Callvirt, DebugSink.Method_ExitScope);
    end;
    fILG.EndExceptionBlock();
    if fDebug then begin 
      if not aEval and (aFunction = nil) then begin
        fILG.BeginCatchBlock(typeOf(Exception));
        var lTemp := AllocateLocal(typeOf(Exception));
        fILG.Emit(OpCodes.Stloc, lTemp);
        WriteDebugStack;
        fILG.Emit(OpCodes.Ldloc, lTemp);
        fILG.Emit(OpCodes.Callvirt, DebugSink.Method_UncaughtException);
        fILG.Emit(OpCodes.Rethrow);
        ReleaseLocal(lTemp);
        fILG.EndExceptionBlock();
      end;
    end;
    fILG.MarkLabel(fExitLabel);
    fILG.Emit(OpCodes.Ldloc, fResultVar);
    fILG.Emit(OpCodes.Ret);
  
    
    fExcept := lOldExcept;
    fExitLabel := lOldExitLabel;
    fResultVar := lOldResultVar;
    fILG := lOldILG;
    fExecutionContext := lOldExecutionContext;
    fLocals := lOldLocals;
    fBreak := lOldBreak;
    fContinue := lOldContinue; 
    if aFunction <> nil then 
    exit lMethod.CreateDelegate(typeOf(InternalFunctionDelegate));
    exit lMethod.CreateDelegate(typeOf(InternalDelegate));
  finally
    fDisableResult := lOldDisableResults;
    fUseStrict := lUseStrict;
    fStatementStack := lLoops;
  end;
end;

method EcmaScriptCompiler.WriteDebugStack;
begin
  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  fILG.Emit(OpCodes.Call, ExecutionContext.Method_GetDebugSink);
end;

method EcmaScriptCompiler.WriteStatement(El: SourceElement);
begin
  if El = nil then exit;
  if fDebug and (El.PositionPair.StartRow> 0) then begin
    WriteDebugStack;
    var lPos := El.PositionPair;
    fILG.Emit(OpCodes.Ldstr, lPos.File);
    fILG.Emit(OpCodes.Ldc_I4, lPos.StartRow);
    fILG.Emit(OpCodes.Ldc_I4, lPos.StartCol);
    fILG.Emit(OpCodes.Ldc_I4, lPos.EndRow);
    fILG.Emit(OpCodes.Ldc_I4, lPos.EndCol);
    fILG.Emit(OpCodes.Callvirt, DebugSink.Method_DebugLine);
  end;
  if El is Statement then fStatementStack.Add(Statement(El));
  case El.Type of
    ElementType.EmptyStatement: begin
      fILG.Emit(OpCodes.Nop);
    end;

    ElementType.ReturnStatement: begin
      if not fDisableResult then raise new ScriptParsingException(El.PositionPair.File, El.PositionPair, EcmaScriptErrorKind.CannotReturnHere);
      if ReturnStatement(El).ExpressionElement = nil then 
        fILG.Emit(OpCodes.Call, Undefined.Method_Instance)
      else begin
        WriteExpression(ReturnStatement(El).ExpressionElement);
        CallGetValue(ReturnStatement(El).ExpressionElement.Type);
      end;
      fILG.Emit(OpCodes.Stloc, fResultVar);
      var lFinallyInfo := Enumerable.Reverse(fStatementStack).Where(a-> (a.Type = ElementType.TryStatement) and (TryStatement(a).FinallyData <> nil)).Select(a->TryStatement(a).FinallyData).ToArray;
      if lFinallyInfo.Length > 0 then begin
        for i: Integer := 0 to lFinallyInfo.Length -1 do begin
          fILG.Emit(OpCodes.Ldc_I4,  lFinallyInfo[i].AddUnique(if i < lFinallyInfo.Length -1 then lFinallyInfo[i+1].FinallyLabel else fExitLabel));
          fILG.Emit(OpCodes.Stloc, lFinallyInfo[i].FinallyState);
        end;
        if TryStatement(Enumerable.Reverse(fStatementStack).FirstOrDefault(a->a.Type = ElementType.TryStatement)).Catch <> nil then
          fILG.Emit(OpCodes.Leave, lFinallyInfo[0].FinallyLabel) 
        else
          fILG.Emit(OpCodes.Br, lFinallyInfo[0].FinallyLabel);
      end else
        fILG.Emit(OpCodes.Leave, fExitLabel); // there's always an outside finally
    end;
    ElementType.ExpressionStatement: begin
      WriteExpression(ExpressionStatement(El).ExpressionElement);
      CallGetValue(ExpressionStatement(El).ExpressionElement.Type);
      if fDisableResult then
        fILG.Emit(OpCodes.Pop)
      else
        fILG.Emit(OpCodes.Stloc, fResultVar);
    end;
    ElementType.DebuggerStatement: begin
      WriteDebugStack;
      fILG.Emit(OpCodes.Callvirt, DebugSink.Method_Debugger);
    end;
    ElementType.VariableStatement: begin
      for i: Integer := 0 to VariableStatement(El).Items.Count- 1 do begin
        var lItem := VariableStatement(El).Items[i];
        if lItem.Initializer <> nil then begin
          WriteExpression(new BinaryExpression(lItem.PositionPair, new IdentifierExpression(lItem.PositionPair, lItem.Identifier), lItem.Initializer, BinaryOperator.Assign));
          fILG.Emit(OpCodes.Pop);
        end;
      end;
    end;
    ElementType.BlockStatement: begin
      for each subitem in BlockStatement(El).Items do WriteStatement(subitem);
    end;
    ElementType.IfStatement: WriteIfStatement(IfStatement(El));
    ElementType.BreakStatement: WriteBreak(BreakStatement(El));
    ElementType.ContinueStatement: WriteContinue(ContinueStatement(El));
    ElementType.DoStatement: WriteDoStatement(DoStatement(El));
    ElementType.ForInStatement: WriteForInstatement(ForInStatement(El));
    ElementType.ForStatement: WriteForStatement(ForStatement(El));
    ElementType.WhileStatement: WriteWhileStatement(WhileStatement(El));
    ElementType.LabelledStatement: begin
      var lWas := fILG.DefineLabel;
      LabelledStatement(El).Break := lWas;
      WriteStatement(LabelledStatement(El).Statement);
      if lWas = Label(LabelledStatement(El).Break) then
        fILG.MarkLabel(valueOrDefault(LabelledStatement(El).Break));
    end;
    ElementType.FunctionDeclaration: begin
      if FunctionDeclarationElement(El).Identifier = nil then begin
        WriteFunction(FunctionDeclarationElement(El), false);
        if fDisableResult then
          fILG.Emit(OpCodes.Pop)
        else
          fILG.Emit(OpCodes.Stloc, fResultVar);
      end;
    end;
    ElementType.ThrowStatement: begin
      WriteExpression(ThrowStatement(El).ExpressionElement);
      CallGetValue(ThrowStatement(El).ExpressionElement.Type);
      fILG.Emit(OpCodes.Call, ScriptRuntimeException.Method_Wrap);
      fILG.Emit(OpCodes.Throw);
    end;
    ElementType.WithStatement: begin
      if fUseStrict then raise new ScriptParsingException(El.PositionPair.File, El.PositionPair, EcmaScriptErrorKind.WithNotAllowedInStrict);
      WriteWithStatement(WithStatement(El));
    end;
    ElementType.TryStatement: WriteTryStatement(TryStatement(El));
    ElementType.SwitchStatement: WriteSwitchstatement(SwitchStatement(El));
  else
    raise new EcmaScriptException(El.PositionPair.File, El.PositionPair, EcmaScriptErrorKind.EInternalError, 'Unkwown type: '+El.Type);
  end; // case
  fStatementStack.Remove(Statement(El));
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
  result := fILG.DeclareLocal(aType);
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
      fILG.Emit(OpCodes.Ldarg_1); // this is arg nr 1
    end;
    ElementType.NullExpression: fILG.Emit(OpCodes.Ldnull);
    ElementType.StringExpression: begin
      fILG.Emit(OpCodes.Ldstr, StringExpression(aExpression).Value);
    end;

    ElementType.BooleanExpression: begin
      if BooleanExpression(aExpression).Value then
        fILG.Emit(OpCodes.Ldc_I4_1)
      else
        fILG.Emit(OpCodes.Ldc_I4_0);
      fILG.Emit(OpCodes.Box, typeOf(Boolean));
    end;
    ElementType.IntegerExpression: begin
      if (IntegerExpression(aExpression).Value < Int64(Int32.MinValue)) or (IntegerExpression(aExpression).Value > Int64(Int32.MaxValue)) then begin
        fILG.Emit(OpCodes.Ldc_R8, Double(IntegerExpression(aExpression).Value));
        fILG.Emit(OpCodes.Box, typeOf(Double));
      end else begin
        fILG.Emit(OpCodes.Ldc_I4, IntegerExpression(aExpression).Value);
        fILG.Emit(OpCodes.Box, typeOf(Integer));
      end;
    end;
    ElementType.DecimalExpression: begin
      fILG.Emit(OpCodes.Ldc_R8, DecimalExpression(aExpression).Value);
      fILG.Emit(OpCodes.Box, typeOf(Double));
    end;
    ElementType.RegExExpression: begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Ldstr, RegExExpression(aExpression).String);
      fILG.Emit(OpCodes.Ldstr, RegExExpression(aExpression).Modifier);
      fILG.Emit(OpCodes.Newobj,typeOf(EcmaScriptRegexpObject).GetConstructor([typeOf(GlobalObject), typeOf(String), typeOf(String)]));
    end;
    ElementType.UnaryExpression: begin
      case UnaryExpression(aExpression).Operator of
        UnaryOperator.BinaryNot: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          CallGetValue(UnaryExpression(aExpression).Value.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_BitwiseNot);
        end;
        UnaryOperator.BoolNot: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          CallGetValue(UnaryExpression(aExpression).Value.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_LogicalNot);
        end;

        UnaryOperator.Delete: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_Delete);
          fILG.Emit(OpCodes.Box, typeOf(Boolean));
        end;

        UnaryOperator.Minus: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          CallGetValue(UnaryExpression(aExpression).Value.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Minus);
        end;

        UnaryOperator.Plus: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          CallGetValue(UnaryExpression(aExpression).Value.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Plus);
        end;
        UnaryOperator.PostDecrement: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_PostDecrement);
        end;

        UnaryOperator.PostIncrement: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_PostIncrement);
        end;
        UnaryOperator.PreDecrement: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_PreDecrement);
        end;
        UnaryOperator.PreIncrement: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_PreIncrement);
        end;
        UnaryOperator.TypeOf: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          //CallGetValue(UnaryExpression(aExpressioN).Value.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_TypeOf);
        end;
        UnaryOperator.Void: begin
          WriteExpression(UnaryExpression(aExpression).Value);
          CallGetValue(UnaryExpression(aExpression).Value.Type);
          fILG.Emit(OpCodes.Pop);
          fILG.Emit(OpCodes.Call, Undefined.Method_Instance);
        end;
        else raise new EcmaScriptException(aExpression.PositionPair.File, aExpression.PositionPair, EcmaScriptErrorKind.EInternalError, 'Unknown type: '+aExpression.Type);
      end; // case
    end;
    ElementType.IdentifierExpression: begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_LexicalScope);
      fILG.Emit(OpCodes.Ldstr, IdentifierExpression(aExpression).Identifier);
      if fUseStrict then
        fILG.Emit(OpCodes.Ldc_I4_1)
      else
        fILG.Emit(OpCodes.Ldc_I4_0);
      fILG.Emit(OpCodes.Call, EnvironmentRecord.Method_GetIdentifier);
    end;
    ElementType.BinaryExpression: begin
      case BinaryExpression(aExpression).Operator of
        BinaryOperator.Assign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call,  Reference.Method_SetValue);
        end;
        BinaryOperator.Plus: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Add);
        end;
        BinaryOperator.PlusAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Add);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Divide: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Divide);
        end;
        BinaryOperator.DivideAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Divide);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Minus: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Subtract);
        end;
        BinaryOperator.MinusAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Subtract);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.Modulus: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Modulus);
        end;
        BinaryOperator.ModulusAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Modulus);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.Multiply: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Multiply);
        end;
        BinaryOperator.MultiplyAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Multiply);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.ShiftLeft: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_ShiftLeft);
        end;
        BinaryOperator.ShiftLeftAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_ShiftLeft);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.ShiftRightSigned: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_ShiftRight);
        end;
        BinaryOperator.ShiftRightSignedAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_ShiftRight);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.ShiftRightUnsigned: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_ShiftRightUnsigned);
        end;
        BinaryOperator.ShiftRightUnsignedAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_ShiftRightUnsigned);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.And: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_And);
        end;
        BinaryOperator.AndAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_And);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Or: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Or);
        end;
        BinaryOperator.OrAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Or);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;
        BinaryOperator.Xor, BinaryOperator.DoubleXor: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_XOr);
        end;
        BinaryOperator.XorAssign: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          fILG.Emit(OpCodes.Dup);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_XOr);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
        end;

        BinaryOperator.Equal: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_Equal);
        end;

        BinaryOperator.NotEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_NotEqual);
        end;

        BinaryOperator.StrictEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_StrictEqual);
        end;

        BinaryOperator.StrictNotEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_StrictNotEqual);
        end;

        BinaryOperator.Less: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_LessThan);
        end;
        BinaryOperator.Greater: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_GreaterThan);
        end;
        BinaryOperator.LessOrEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_LessThanOrEqual);
        end;
        BinaryOperator.GreaterOrEqual: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_GreaterThanOrEqual);
        end;        
        BinaryOperator.InstanceOf: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_InstanceOf);
        end;
        BinaryOperator.In: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Operators.Method_In);
        end;
        BinaryOperator.DoubleAnd: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          fILG.Emit(OpCodes.Dup);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
          var lGotIt := fILG.DefineLabel;
          fILG.Emit(OpCodes.Brfalse, lGotIt);
          fILG.Emit(OpCodes.Pop);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.MarkLabel(lGotIt);
        end;
        BinaryOperator.DoubleOr: begin
          WriteExpression(BinaryExpression(aExpression).LeftSide);
          CallGetValue(BinaryExpression(aExpression).LeftSide.Type);
          fILG.Emit(OpCodes.Dup);
          fILG.Emit(OpCodes.Ldloc, fExecutionContext);
          fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
          var lGotIt := fILG.DefineLabel;
          fILG.Emit(OpCodes.Brtrue, lGotIt);
          fILG.Emit(OpCodes.Pop);
          WriteExpression(BinaryExpression(aExpression).RightSide);
          CallGetValue(BinaryExpression(aExpression).RightSide.Type);
          fILG.MarkLabel(lGotIt);
        end;
      else
        raise new EcmaScriptException(aExpression.PositionPair.File, aExpression.PositionPair, EcmaScriptErrorKind.EInternalError, 'Unknown type: '+aExpression.Type);
      end; // case
    end;
    ElementType.ConditionalExpression: begin
      WriteExpression(ConditionalExpression(aExpression).Condition);
      CallGetValue(ConditionalExpression(aExpression).Condition.Type);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
      var lFalse := fILG.DefineLabel;
      var lExit := fILG.DefineLabel;
      fILG.Emit(OpCodes.Brfalse, lFalse);
      WriteExpression(ConditionalExpression(aExpression).True);
      CallGetValue(ConditionalExpression(aExpression).True.Type);
      fILG.Emit(OpCodes.Br, lExit);
      fILG.MarkLabel(lFalse);
      WriteExpression(ConditionalExpression(aExpression).False);
      CallGetValue(ConditionalExpression(aExpression).False.Type);
      fILG.MarkLabel(lExit);
    end;
    ElementType.ArrayLiteralExpression: begin
      fILG.Emit(OpCodes.Ldc_I4, ArrayLiteralExpression(aExpression).Items.Count);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Newobj, EcmaScriptArrayObject.Constructor);
      for each el in ArrayLiteralExpression(aExpression).Items do begin
        fILG.Emit(OpCodes.Dup);
        if el = nil then  begin
          fILG.Emit(OpCodes.Call, Undefined.Method_Instance);
        end else begin
          WriteExpression(el);
          CallGetValue(el.Type);
        end;
        fILG.Emit(OpCodes.Call, EcmaScriptArrayObject.Method_AddValue);
      end;
    end;
    ElementType.ObjectLiteralExpression: begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Newobj, EcmaScriptObject.Constructor);
      for each el in ObjectLiteralExpression(aExpression).Items do begin
        case el.Name.Type of 
          ElementType.IdentifierExpression: fILG.Emit(OpCodes.Ldstr, IdentifierExpression(el.Name).Identifier);
        else
          WriteExpression(el.Name);
        end; // case
        fILG.Emit(OpCodes.Ldloc, fExecutionContext);
        fILG.Emit(OpCodes.Call, Utilities.Method_GetObjAsString);
        fILG.Emit(OpCodes.Ldc_I4, Integer(el.Mode));
        WriteExpression(el.Value);
        CallGetValue(el.Value.Type);
        fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 1 else 0);
        fILG.Emit(OpCodes.Call, EcmaScriptObject.Method_ObjectLiteralSet);
      end;
    end;
    ElementType.SubExpression: begin
      WriteExpression(SubExpression(aExpression).Member);
      CallGetValue(SubExpression(aExpression).Member.Type);
      fILG.Emit(OpCodes.Ldstr, SubExpression(aExpression).Identifier);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 1 else 0);
      fILG.Emit(OpCodes.Call, Reference.Method_Create);
    end;
    ElementType.ArrayAccessExpression: begin
      WriteExpression(ArrayAccessExpression(aExpression).Member);
      CallGetValue(ArrayAccessExpression(aExpression).Member.Type);
      
      WriteExpression(ArrayAccessExpression(aExpression).Parameter);
      CallGetValue(ArrayAccessExpression(aExpression).Parameter.Type);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 3 else 2);
      fILG.Emit(OpCodes.Call, Reference.Method_Create);
    end;
    ElementType.NewExpression: begin
      WriteExpression(NewExpression(aExpression).Member);
      CallGetValue(NewExpression(aExpression).Member.Type);
      fILG.Emit(OpCodes.Isinst, typeOf(EcmaScriptObject));
      fILG.Emit(OpCodes.Dup);
      var lIsObject := fILG.DefineLabel;
      fILG.Emit(OpCodes.Brtrue, lIsObject);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Ldc_I4, Integer(NativeErrorType.TypeError));
      fILG.Emit(OpCodes.Ldstr, 'Cannot instantiate non-object value');
      fILG.Emit(OpCodes.Call, GlobalObject.Method_RaiseNativeError);
      fILG.MarkLabel(lIsObject);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Ldc_I4, NewExpression(aExpression).Parameters.Count);
      fILG.Emit(OpCodes.Newarr, typeOf(Object));
      for each el in NewExpression(aExpression).Parameters index n do begin
        fILG.Emit(OpCodes.Dup);
        fILG.Emit(OpCodes.Ldc_I4, n);
        WriteExpression(el);
        CallGetValue(el.Type);
        fILG.Emit(OpCodes.Stelem_Ref);
      end;

      fILG.Emit(OpCodes.Callvirt, EcmaScriptObject.Method_Construct);
    end;

    ElementType.CallExpression: begin
      WriteExpression(CallExpression(aExpression).Member);
      fILG.Emit(OpCodes.Ldarg_1); // self
      
      fILG.Emit(OpCodes.Ldc_I4, CallExpression(aExpression).Parameters.Count);
      fILG.Emit(OpCodes.Newarr, typeOf(Object));
      for each el in CallExpression(aExpression).Parameters index n do begin
        fILG.Emit(OpCodes.Dup);
        fILG.Emit(OpCodes.Ldc_I4, n);
        WriteExpression(el);
        CallGetValue(el.Type);
        fILG.Emit(OpCodes.Stelem_Ref);
      end;
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, EcmaScriptObject.Method_CallHelper);
    end;
    ElementType.CommaSeparatedExpression: // only for for
    begin
      for i: Integer := 0 to CommaSeparatedExpression(aExpression).Parameters.Count -1 do begin
        if i <> 0 then fILG.Emit(OpCodes.Pop);
        WriteExpression(CommaSeparatedExpression(aExpression).Parameters[i]);
        CallGetValue(CommaSeparatedExpression(aExpression).Parameters[i].Type);
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
  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  fILG.Emit(OpCodes.Call, Reference.Method_GetValue);

end;

method EcmaScriptCompiler.CallSetValue;
begin
  // Expect: POSSIBLE reference on stack (always typed object)
  // Expect: NON reference as second item on the stack
  // Returns: Object value
  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  fILG.Emit(OpCodes.Call, Reference.Method_SetValue);
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
      ElementType.ForStatement: 
        begin
          if ForStatement(el).Initializers <> nil then
            yield RecursiveFindFuncAndVars(ForStatement(el).Initializers.Cast<SourceElement>);
          yield RecursiveFindFuncAndVars([ForStatement(el).Initializer, ForStatement(el).Increment, ForStatement(el).Comparison, ForStatement(el).Body]);
        end;
      ElementType.ForInStatement:
        begin
          yield RecursiveFindFuncAndVars([ForInStatement(el).Initializer, ForInStatement(el).LeftExpression, ForInStatement(el).ExpressionElement, ForInStatement(el).Body]);
        end;
      ElementType.TryStatement: yield RecursiveFindFuncAndVars([TryStatement(el).Body, TryStatement(el).Finally, TryStatement(el).Catch:Body]);
      ElementType.VariableStatement: yield el;
      ElementType.VariableDeclaration: yield new VariableStatement(el.PositionPair, VariableDeclaration(el));
      ElementType.WithStatement: yield RecursiveFindFuncAndVars([WithStatement(el).Body]);
      ElementType.DoStatement: yield RecursiveFindFuncAndVars([DoStatement(el).Body]);
      ElementType.WhileStatement: yield RecursiveFindFuncAndVars([WhileStatement(el).Body]);
    end; // case
  end;
end;

method EcmaScriptCompiler.WriteIfStatement(el: IfStatement);
begin
  if el.False = nil then begin
    WriteExpression(el.ExpressionElement);
    CallGetValue(el.ExpressionElement.Type);
    fILG.Emit(OpCodes.Ldloc, fExecutionContext);
    fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
    var lFalse := fILG.DefineLabel;
    fILG.Emit(OpCodes.Brfalse, lFalse);
    WriteStatement(el.True);
    fILG.MarkLabel(lFalse);
  end else if el.True = nil then begin
    WriteExpression(el.ExpressionElement);
    CallGetValue(el.ExpressionElement.Type);
    fILG.Emit(OpCodes.Ldloc, fExecutionContext);
    fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
    var lTrue := fILG.DefineLabel;
    fILG.Emit(OpCodes.Brtrue, lTrue);
    WriteStatement(el.False);
    fILG.MarkLabel(lTrue);
  end else begin
    WriteExpression(el.ExpressionElement);
    CallGetValue(el.ExpressionElement.Type);
    fILG.Emit(OpCodes.Ldloc, fExecutionContext);
    fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
    var lFalse := fILG.DefineLabel;
    fILG.Emit(OpCodes.Brfalse, lFalse);
    WriteStatement(el.True);
    var lExit := fILG.DefineLabel;
    fILG.Emit(OpCodes.Br, lExit);
    fILG.MarkLabel(lFalse);
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
          fILG.Emit(OpCodes.Ldc_I4,  lFinallyInfo[i].AddUnique(if i < lFinallyInfo.Count -1 then lFinallyInfo[i+1].FinallyLabel else Label(fContinue)));
          fILG.Emit(OpCodes.Stloc, lFinallyInfo[i].FinallyState);
        end;
        if TryStatement(Enumerable.Reverse(fStatementStack).FirstOrDefault(a->a.Type = ElementType.TryStatement)).Catch <> nil then
          fILG.Emit(OpCodes.Leave, lFinallyInfo[0].FinallyLabel) 
        else
          fILG.Emit(OpCodes.Br, lFinallyInfo[0].FinallyLabel);
      end else
        fILG.Emit(OpCodes.Leave, Label(fContinue));
    end else
      fILG.Emit(OpCodes.Br, Label(fContinue));
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
              fILG.Emit(OpCodes.Ldc_I4,  lFinallyInfo[j].AddUnique(if j < lFinallyInfo.Count -1 then lFinallyInfo[j+1].FinallyLabel else Label(lIt.Continue)));
              fILG.Emit(OpCodes.Stloc, lFinallyInfo[j].FinallyState);
            end;
            if TryStatement(Enumerable.Reverse(fStatementStack).FirstOrDefault(a->a.Type = ElementType.TryStatement)).Catch <> nil then
              fILG.Emit(OpCodes.Leave, lFinallyInfo[0].FinallyLabel) 
            else
            fILG.Emit(OpCodes.Br, lFinallyInfo[0].FinallyLabel);
          end else
            fILG.Emit(OpCodes.Leave, Label(lIt.Continue));
        end else begin
          if lIt.Continue = nil then 
            fILG.Emit(OpCodes.Leave, fExitLabel) else 
          fILG.Emit(OpCodes.Leave, Label(lIt.Continue));
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
          fILG.Emit(OpCodes.Ldc_I4,  lFinallyInfo[i].AddUnique(if i < lFinallyInfo.Count -1 then lFinallyInfo[i+1].FinallyLabel else Label(fBreak)));
          fILG.Emit(OpCodes.Stloc, lFinallyInfo[i].FinallyState);
        end;
        fILG.Emit(OpCodes.Br, lFinallyInfo[0].FinallyLabel);
      end else
        fILG.Emit(OpCodes.Leave, Label(fBreak));
    end else
      fILG.Emit(OpCodes.Br, Label(fBreak));
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
              fILG.Emit(OpCodes.Ldc_I4,  lFinallyInfo[j].AddUnique(if j < lFinallyInfo.Count -1 then lFinallyInfo[j+1].FinallyLabel else Label(lIt.Break)));
              fILG.Emit(OpCodes.Stloc, lFinallyInfo[j].FinallyState);
            end;
            fILG.Emit(OpCodes.Br, lFinallyInfo[0].FinallyLabel);
          end else
            fILG.Emit(OpCodes.Leave, Label(lIt.Break));
        end else begin
          fILG.Emit(OpCodes.Leave, Label(lIt.Break));
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
  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
  if el.Identifier = nil then begin
    fILG.Emit(OpCodes.Ldloc, fExecutionContext);
    fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_LexicalScope);
  end else begin
    if aRegister then begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_VariableScope);
    end else begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_LexicalScope);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
      fILG.Emit(OpCodes.Newobj, DeclarativeEnvironmentRecord.Constructor);
    end;
  end;
  if el.Identifier = nil then 
    fILG.Emit(OpCodes.Ldnull)
  else
    fILG.Emit(OpCodes.Ldstr, el.Identifier);
  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_Global);
  fILG.Emit(OpCodes.Ldc_I4, fGlobal.StoreFunction(lDelegate));
  fILG.Emit(OpCodes.Call, GlobalObject.Method_GetFunction);
  
  fILG.Emit(OpCodes.Ldc_I4, el.Parameters.Count);
  var ob := GetOriginalBody(el);
  fILG.Emit(OpCodes.Ldstr, ob);
  fILG.Emit(OpCodes.Ldc_I4, if fUseStrict then 1 else 0);
  fILG.Emit(OpCodes.Newobj, EcmaScriptInternalFunctionObject.Constructor);

  
  if (el.Identifier<> nil) and not aRegister then begin
    //class method SetAndInitializeImmutable(val: EcmaScriptFunctionObject; aName: String): EcmaScriptFunctionObject;
    fILG.Emit(OpCodes.Ldstr, el.Identifier);
    fILG.Emit(OpCodes.Call, DeclarativeEnvironmentRecord.Method_SetAndInitializeImmutable);
  end;
    
  
end;

method EcmaScriptCompiler.WriteDoStatement(el: DoStatement);
begin
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;
  fBreak := fILG.DefineLabel;
  MarkLabelled(fBreak, fContinue);
  var fRestart := fILG.DefineLabel;

  fILG.MarkLabel(fRestart);

  WriteStatement(el.Body);

  fILG.MarkLabel(Label(fContinue));

  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
  fILG.Emit(OpCodes.Brtrue, Label(fRestart));
  fILG.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;

method EcmaScriptCompiler.WriteWhileStatement(el: WhileStatement);
begin
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;
  fBreak := fILG.DefineLabel;
  MarkLabelled(fBreak, fContinue);
  fILG.MarkLabel(Label(fContinue));
  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
  fILG.Emit(OpCodes.Brfalse, Label(fBreak));


  WriteStatement(el.Body);

  fILG.Emit(OpCodes.Br, Label(fContinue));
  fILG.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;

method EcmaScriptCompiler.WriteForInstatement(el: ForInStatement);
begin
  var lLocal := AllocateLocal(typeOf(IEnumerator<String>));
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;

  var lCurrent := lLocal.LocalType.GetMethod('get_Current');
  var lMoveNext :=  typeOf(System.Collections.IEnumerator).GetMethod('MoveNext');
  fBreak := fILG.DefineLabel;
  
  var lWork := if assigned(el.Initializer:Identifier) then new IdentifierExpression(el.Initializer.PositionPair, el.Initializer.Identifier) else el.LeftExpression;

  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  fILG.Emit(OpCodes.Isinst, typeOf(EcmaScriptObject));
  fILG.Emit(OpCodes.Dup);
  var lPopAndBreak := fILG.DefineLabel;
  fILG.Emit(OpCodes.Brfalse, lPopAndBreak);
  fILG.Emit(OpCodes.Callvirt, EcmaScriptObject.Method_GetNames);
  fILG.Emit(OpCodes.Stloc, lLocal);
 
   MarkLabelled(fBreak, fContinue);

  fILG.MarkLabel(Label(fContinue));
  fILG.Emit(OpCodes.Ldloc, lLocal);
  fILG.Emit(OpCodes.Callvirt, lMoveNext);
  fILG.Emit(OpCodes.Brfalse, Label(fBreak));

  WriteExpression(lWork);
  fILG.Emit(OpCodes.Ldloc, lLocal);
  fILG.Emit(OpCodes.Callvirt, lCurrent);
  CallSetValue();
  fILG.Emit(OpCodes.Pop); // set value returns something

  WriteStatement(el.Body);

  fILG.Emit(OpCodes.Br, Label(fContinue));
  fILG.MarkLabel(lPopAndBreak);
  fILG.Emit(OpCodes.Pop);
  fILG.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;

  ReleaseLocal(lLocal);
end;

method EcmaScriptCompiler.WriteForStatement(el: ForStatement);
begin
  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fContinue := fILG.DefineLabel;
  fBreak := fILG.DefineLabel;
  MarkLabelled(fBreak, fContinue);

  if el.Initializer <> nil then begin
    WriteExpression(el.Initializer);
    fILG.Emit(OpCodes.Pop);
  end;
  for each eli in el.Initializers do begin
    if eli.Initializer <> nil then begin
      WriteExpression(new BinaryExpression(eli.PositionPair, new IdentifierExpression(eli.PositionPair, eli.Identifier), eli.Initializer, BinaryOperator.Assign));
      fILG.Emit(OpCodes.Pop);
    end;
  end;
  var lLoopStart := fILG.DefineLabel;
  fILG.MarkLabel(lLoopStart);
  if el.Comparison <> nil then begin
    WriteExpression(el.Comparison);
    CallGetValue(el.Comparison.Type);
    fILG.Emit(OpCodes.Ldloc, fExecutionContext);
    fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
    fILG.Emit(OpCodes.Brfalse, Label(fBreak));
  end;

  WriteStatement(el.Body);

  fILG.MarkLabel(Label(fContinue));
  
  if assigned(el.Increment) then begin
    WriteExpression(el.Increment);
    fILG.Emit(OpCodes.Pop);
  end;

  fILG.Emit(OpCodes.Br, lLoopStart);

  fILG.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;

method EcmaScriptCompiler.WriteWithStatement(el: WithStatement);
begin
  var lNew := AllocateLocal(typeOf(ExecutionContext));
  var lOld := fExecutionContext;

  fILG.Emit(OpCodes.Ldloc, fExecutionContext);
  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  fILG.Emit(OpCodes.Call, ExecutionContext.Method_With);
  fILG.Emit(OpCodes.Stloc, lNew);
  fExecutionContext := lNew;

  WriteStatement(el.Body);

  fExecutionContext := lOld;

  ReleaseLocal(lOld);
end;

method EcmaScriptCompiler.WriteTryStatement(el: TryStatement);
begin
  if el.Finally <> nil then begin
    el.FinallyData := new FinallyInfo();
    el.FinallyData.FinallyLabel := fILG.DefineLabel;
    el.FinallyData.FinallyState := AllocateLocal(typeOf(Integer));
    fILG.BeginExceptionBlock;
  end;
  if el.Catch <> nil then fILG.BeginExceptionBlock;

   if el.Body <> nil then WriteStatement(el.Body);
  
  if el.Catch <> nil then begin
    fILG.BeginCatchBlock(typeOf(Exception));
    fILG.Emit(OpCodes.Call, ScriptRuntimeException.Method_Unwrap);
    fILG.Emit(OpCodes.Ldloc, fExecutionContext);
    fILG.Emit(OpCodes.Ldstr, el.Catch.Identifier);
    fILG.Emit(OpCodes.Call, ExecutionContext.Method_Catch);
    var lVar := AllocateLocal(typeOf(fExecutionContext));
    fILG.Emit(OpCodes.Stloc,  lVar);
    var lold := fExecutionContext;
    fExecutionContext := lVar;
    //DefineInScope(false, [el.Catch.Body]);
    WriteStatement(el.Catch.Body);

    ReleaseLocal(lVar);

    fExecutionContext := lold;
    fILG.EndExceptionBlock();
  end;

  if el.Finally <> nil then begin
    var lData := el.FinallyData;
    el.FinallyData := nil;
    fILG.Emit(OpCodes.Ldc_I4_M1);
    fILG.Emit(OpCodes.Stloc, lData.FinallyState);
    fILG.MarkLabel(lData.FinallyLabel);
    var lOldDisableResult := fDisableResult;
    fDisableResult := true;
    WriteStatement(el.Finally);
    fILG.Emit(OpCodes.Ldloc, lData.FinallyState);
    fILG.Emit(OpCodes.Switch, lData.JumpTable.ToArray);
    fILG.BeginCatchBlock(typeOf(Exception));
    fILG.Emit(OpCodes.Pop);
    WriteStatement(el.Finally);
    fILG.Emit(OpCodes.Rethrow);
    fILG.EndExceptionBlock();
    fDisableResult := lOldDisableResult;
  end;
end;

method EcmaScriptCompiler.WriteSwitchstatement(el: SwitchStatement);
begin
  var lLabels: array of Label := new Label[el.Clauses.Count];
  for i: Integer := 0 to lLabels.Length -1 do begin
    lLabels[i] := fILG.DefineLabel;
  end;

  var lWork := AllocateLocal(typeOf(Object));
  WriteExpression(el.ExpressionElement);
  CallGetValue(el.ExpressionElement.Type);
  fILG.Emit(OpCodes.Stloc, lWork);
  
  var lGotDefault := false;
  for i: Integer := 0 to el.Clauses.Count -1 do begin
    if el.Clauses[i].ExpressionElement = nil then lGotDefault := true else begin
      fILG.Emit(OpCodes.Ldloc, lWork);
      WriteExpression(el.Clauses[i].ExpressionElement);
      CallGetValue(el.Clauses[i].ExpressionElement.Type);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, Operators.Method_StrictEqual);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, Utilities.method_GetObjAsBoolean);
      fILG.Emit(OpCodes.Brtrue, lLabels[i]);
    end;
  end;
  ReleaseLocal(lWork);

  var lOldContinue := fContinue;
  var lOldBreak := fBreak;
  fBreak := fILG.DefineLabel;
  if lGotDefault then begin
    for i: Integer := 0 to el.Clauses.Count -1 do begin
      if el.Clauses[i].ExpressionElement = nil then begin
        fILG.Emit(OpCodes.Br, lLabels[i]);
        break;
      end;
    end;
  end else
    fILG.Emit(OpCodes.Br, Label(fBreak));

  MarkLabelled(fBreak, nil);
  if not lGotDefault then fILG.Emit(OpCodes.Br, Label(fBreak));
  

  for i: Integer := 0 to el.Clauses.Count -1 do begin
    fILG.MarkLabel(lLabels[i]);
    for each bodyelement in el.Clauses[i].Body do
      WriteStatement(bodyelement);
  end;

  fILG.MarkLabel(Label(fBreak));

  fBreak := lOldBreak;
  fContinue := lOldContinue;
end;


method EcmaScriptCompiler.DefineInScope(aEval: Boolean; aElements: sequence of SourceElement);
begin
  for each el in RecursiveFindFuncAndVars(aElements) do begin
    if (el.Type = ElementType.FunctionDeclaration) and (FunctionDeclarationElement(el).Identifier <> nil) then begin
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_VariableScope);
      fILG.Emit(OpCodes.Ldstr, FunctionDeclarationElement(el).Identifier);
      if aEval then 
        fILG.Emit(OpCodes.Ldc_I4_1) 
      else
        fILG.Emit(OpCodes.Ldc_I4_0);
      fILG.Emit(OpCodes.Call, EnvironmentRecord.Method_CreateMutableBindingNoFail);
      fILG.Emit(OpCodes.Ldloc, fExecutionContext);
      fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_VariableScope);
      fILG.Emit(OpCodes.Ldstr, FunctionDeclarationElement(el).Identifier);
      WriteFunction(FunctionDeclarationElement(el), true);
      if fUseStrict then
        fILG.Emit(OpCodes.Ldc_I4_1) 
      else
        fILG.Emit(OpCodes.Ldc_I4_0);
      fILG.Emit(OpCodes.Callvirt, EnvironmentRecord.Method_SetMutableBinding);
    end else if el.Type = ElementType.VariableStatement then begin
      for each en in VariableStatement(el).Items do begin
        fILG.Emit(OpCodes.Ldloc, fExecutionContext);
        fILG.Emit(OpCodes.Call, ExecutionContext.Method_get_VariableScope);
        fILG.Emit(OpCodes.Ldstr, en.Identifier);
        if aEval then
          fILG.Emit(OpCodes.Ldc_I4_1) 
        else
          fILG.Emit(OpCodes.Ldc_I4_0);
        fILG.Emit(OpCodes.Call, EnvironmentRecord.Method_CreateMutableBindingNoFail);
      end;
    end;
  end;
end;

method EcmaScriptCompiler.GetOriginalBody(el: SourceElement): String;
begin
  var lStart := el.PositionPair.StartPos;
  var lEnd := el.PositionPair.EndPos - lStart;
  if (lStart >= 0) and (lStart + lEnd  < fLastData.Length) then
    result := fLastData.Substring(lStart, lEnd)
  else
    result := '{}';
end;

method FinallyInfo.AddUnique(aLabel: Label): Integer;
begin
  for i: Integer := 0 to JumpTable.Count - 1 do
    if JumpTable[i].Equals(aLabel) then exit i;
  JumpTable.Add(aLabel);
  exit JumpTable.Count -1;
end;

end.