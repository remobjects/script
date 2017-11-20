//  Copyright RemObjects Software 2002-2017. All rights reserved.
//  See LICENSE.txt for more details.

namespace RemObjects.Script.PascalScript;

interface

uses
  System.Collections.Generic,
  Microsoft.Scripting.Ast,
  System.Text,
  Microsoft.Scripting,
  Microsoft.Scripting.Actions,
  Microsoft.Scripting.Generation,
  Microsoft.Scripting.Runtime,
  Microsoft.Scripting.Ast,
  System.Dynamic,
  RemObjects.Script,
  RemObjects.Script.Properties,
  RemObjects.Script.PascalScript.Internal;


type
  PascalScriptErrorKind = public enum
  (
    EInternalError = 10001  );
  PascalScriptException = public class(Exception)
  private
  public
    class method ErrorToString(anError: PascalScriptErrorKind; aMsg: String): String;
    constructor (aFilename: String; aPosition: PositionPair; anError: PascalScriptErrorKind; aMsg: String := '');
    property Position: PositionPair; readonly;
    property Error: PascalScriptErrorKind; readonly;
    property Msg: String; readonly;
  end;
[Serializable]
  PascalScriptCompilerOptions = public class(CompilerOptions)
  private
  public
    constructor; empty;
  end;
  PascalScriptLanguageContext = public class(LanguageContext)
  private
    class var fLanguageGuid: Guid := new Guid('9F2FBA2C-A286-451b-9A12-01688E69C22B');readonly;
    class var fVendorGuid: Guid := new Guid('5133A728-E83E-4C0D-BCB9-AB02B9C172C0');readonly;
  protected
  public
    constructor(manager: ScriptDomainManager; options: IDictionary<String, object>); 

    property LanguageGuid: Guid read fLanguageGuid; override;
    property VendorGuid: Guid read fVendorGuid; override;
    property LanguageVersion: System.Version read typeOf(PascalScriptLanguageContext).Assembly.GetName(false).Version; override;

    method CompileSourceCode(sourceUnit: SourceUnit; options: CompilerOptions; errorSink: ErrorSink): ScriptCode; override;
  end;
  PascalScriptCompiler = public class
  private
    fLanguage: PascalScriptLanguageContext;
    fContext: SourceUnit;
    fOptions: PascalScriptCompilerOptions;
  public
    constructor(aLanguage: PascalScriptLanguageContext; aContext: SourceUnit; aOptions: PascalScriptCompilerOptions);

    method Parse(aElements: ProgramBlock): LambdaExpression;
  end;

  EcmaScriptCompiledScriptCode =  public class(CompiledScriptCode)
  private
    fCompiler: PascalScriptCompiler;
  public
    constructor (aCode: LambdaExpression; aSource: SourceUnit; aCompiler: PascalScriptCompiler);

    property Compiler: PascalScriptCompiler read fCompiler;
  end;
  
implementation

constructor PascalScriptLanguageContext(manager: ScriptDomainManager; options: IDictionary<String, object>);
begin
  inherited constructor(manager);
end;

method PascalScriptLanguageContext.CompileSourceCode(sourceUnit: SourceUnit; options: CompilerOptions; errorSink: ErrorSink): ScriptCode;
begin
  var lTokenizer := new Tokenizer;
  lTokenizer.SetData(sourceUnit.GetCode(), sourceUnit.Path);
  var lParser := new Parser;
  var lElement := lParser.Parse(lTokenizer);
  for each el in lParser.Messages do begin
    errorSink.Add(sourceUnit, el.IntToString, new SourceSpan(new SourceLocation(0, el.Position.Row, el.Position.Col), new SourceLocation(0, el.Position.Row, el.Position.Col)), el.Code, iif(el.IsError, Severity.Error, Severity.Warning));
  end;
  if lElement = nil then begin
    errorSink.Add(sourceUnit, Resources.eFatalErrorWhileCompiling, 
    SourceSpan.None, 0, Severity.FatalError);
  end else begin
    try
      var lOpt := PascalScriptCompilerOptions(Options);
      var lCompiler := new PascalScriptCompiler(self, sourceUnit, lOpt);
      var lResult := lCompiler.Parse(lElement);
      exit new EcmaScriptCompiledScriptCode(lResult, sourceUnit, lCompiler);
    except
      on e: PascalScriptException do begin
        errorSink.Add(sourceUnit, PascalScriptException.ErrorToString(e.Error, e.Msg), new SourceSpan(
          new SourceLocation(0, e.Position.StartRow, e.Position.StartCol), 
          new SourceLocation(0, e.Position.EndRow, e.Position.EndCol)), Integer(e.Error), Severity.FatalError);
      end;
    end;
  end;
end;

constructor EcmaScriptCompiledScriptCode(aCode: LambdaExpression; aSource: SourceUnit; aCompiler: PascalScriptCompiler);
begin
  inherited constructor(aCode, aSource);
  fCompiler := aCompiler;
end;

constructor PascalScriptCompiler(aLanguage: PascalScriptLanguageContext; aContext: SourceUnit; aOptions: PascalScriptCompilerOptions);
begin
  fLanguage := aLanguage;
  fContext := aContext;
	fOptions := aOptions;
end;

method PascalScriptCompiler.Parse(aElements: ProgramBlock): LambdaExpression;
begin
(*  fOutside := Utils.Lambda(typeOf(Object), 'EcmaScript');
  fOutside.Visible := false;

  var lScopeParam := fOutside.ClosedOverParameter(typeOf(Scope), '$scope');
  var lLanguageContextParam := fOutside.ClosedOverParameter(typeOf(LanguageContext), '$languagecontext');
  fGlobalObject := fOutside.ClosedOverVariable(typeOf(GlobalObject), '$global') as ParameterExpression;

  var lInside: LambdaExpression := IntParse(aElements);
*)
  (*if fContext.EmitDebugSymbols then begin
	  if fOptions.GlobalObject.DebugCtx = nil then 
  	  fOptions.GlobalObject.DebugCtx := Microsoft.Scripting.Debugging.CompilerServices.DebugContext.CreateInstance();
		lInside := fOptions.GlobalObject.DebugCtx.TransformLambda(lInside);
  end;*)

   //new RuntimeScope(lang, scope, self)
  (*fOutside.Body := Utils.AddDebugInfo(
  Expression.Block(
    Expression.Assign(fGlobalObject, Expression.Constant(fGlobalObjectValue)),
    Expression.Call(fGlobalObject, fGlobalObject.Type.GetMethod('SetScope'), lScopeParam), 
  Expression.Invoke(lInside, 
    fGlobalObject,
    Expression.NewArrayInit(typeOf(object), []))),
      fContext.Document, 
        aElements.PositionPair.StartRow, aElements.PositionPair.StartCol,
        aElements.PositionPair.EndRow, aElements.PositionPair.EndCol);
  result := foutside.MakeLambda;
  if fContext.EmitDebugSymbols then begin
	  if fOptions.GlobalObject.DebugCtx = nil then 
  	  fOptions.GlobalObject.DebugCtx := Microsoft.Scripting.Debugging.CompilerServices.DebugContext.CreateInstance();
		result := fOptions.GlobalObject.DebugCtx.TransformLambda(result);
  end;*)
end;



class method PascalScriptException.ErrorToString(anError: PascalScriptErrorKind; aMsg: String): String;
begin

end;

constructor PascalScriptException(aFilename: String; aPosition: PositionPair; anError: PascalScriptErrorKind; aMsg: String := '');
begin
end;

end.