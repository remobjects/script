{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.PascalScript.Internal;

interface

uses
  System.Collections.Generic,
  System.Text,
  System.Collections.ObjectModel,
  RemObjects.Script;

type
  ElementType = public enum (
    ProgramBlock,
    UsesBlock,
    InterfaceBlock,
    ImplementationBlock,
    FunctionBlock,
    LabelBlock,
    VariableBlock,
    ConstantBlock,
    TypeBlock,
    MainBeginBlock,
    BlockStatement,
    EmptyStatement,
    GotoStatement,
    WithStatement,
    TryStatement,
    RepeatStatement,
    ForStatement,
    WhileStatement,
    CaseStatement,
    CaseElement,
    ExitStatement,
    IfStatement,
    AssignmentStatement,
    BreakStatement,
    ContinueStatement,
    VariableDeclaration,
    ConstantDeclaration,
    ParameterDeclaration,
    TypeDeclaration,
    IdentifierExpression,
    CallExpression,
    ArrayElementExpression,
    FloatExpression,
    IntegerExpression,
    UnaryExpression,
    BinaryExpression,
    NilExpression,
    TrueExpression,
    FalseExpression,
    StringExpression,
    ResultExpression,
    ArrayExpression,
    RangeExpression,
    OrdExpression,
    ChrExpression,
    MemberExpression,
    EnumValue,

    RecordDeclaration,
    EnumDeclaration,
    FunctionPointerDeclaration,
    ArrayDeclaration,
    StaticArrayDeclaration,
    SetDeclaration,
    TypeNameReference
  );

  LanguageElement = public abstract class
  private
    fPositionPair: PositionPair;
  public
    constructor (aPositionPair: PositionPair);
    property PositionPair: PositionPair read fPositionPair;
    property &Type: ElementType read; abstract;
  end;

  ProgramBlock = public class(LanguageElement)
  private
    fIsUnit: Boolean;
    fName: String;
    fItems: ReadOnlyCollection<BodyBlock>;
  public
    property &Type: ElementType read ElementType.ProgramBlock; override;
    constructor (aPosition: PositionPair; aIsUnit: Boolean; aName: String; aItems: sequence of BodyBlock);
    constructor (aPosition: PositionPair; aIsUnit: Boolean; aName: String; aItems: array of BodyBlock);
    constructor (aPosition: PositionPair; aIsUnit: Boolean; aName: String; aItems: IList<BodyBlock>);

    property Items: ReadOnlyCollection<BodyBlock> read fItems;
    property Name: String read fName;
    property IsUnit: Boolean read fIsUnit;
  end;
  BodyBlock = public abstract class(LanguageElement);

  UsesBlock = public class(BodyBlock)
  private
    //fItems: ReadOnlyCollection<String>;
  public
    property &Type: ElementType read ElementType.UsesBlock; override;
    constructor (aPosition: PositionPair; aItems: sequence of String);
    constructor (aPosition: PositionPair; aItems: array of String);
    constructor (aPosition: PositionPair; aItems: IList<String>);
  end;
  
  InterfaceBlock = public class(BodyBlock)
  private
    fItems: ReadOnlyCollection<BodyBlock>;
  public
    property &Type: ElementType read ElementType.InterfaceBlock; override;
    constructor (aPosition: PositionPair; aItems: sequence of BodyBlock);
    constructor (aPosition: PositionPair; aItems: array of BodyBlock);
    constructor (aPosition: PositionPair; aItems: IList<BodyBlock>);

    property Items: ReadOnlyCollection<BodyBlock> read fItems;  
  end;

  ImplementationBlock = public class(BodyBlock)
  private
    fItems: ReadOnlyCollection<BodyBlock>;
  public
    property &Type: ElementType read ElementType.ImplementationBlock; override;
    constructor (aPosition: PositionPair; aItems: sequence of BodyBlock);
    constructor (aPosition: PositionPair; aItems: array of BodyBlock);
    constructor (aPosition: PositionPair; aItems: IList<BodyBlock>);

    property Items: ReadOnlyCollection<BodyBlock> read fItems;  
  end;

  LabelBlock = public class(BodyBlock)
  private
    //fItems: ReadOnlyCollection<String>;
  public
    property &Type: ElementType read ElementType.LabelBlock; override;
    constructor (aPosition: PositionPair; aItems: sequence of String);
    constructor (aPosition: PositionPair; aItems: array of String);
    constructor (aPosition: PositionPair; aItems: IList<String>);
  end;

  VariableBlock = public class(BodyBlock)
  private
    fItems: ReadOnlyCollection<VariableDeclaration>;
  public
    property &Type: ElementType read ElementType.VariableBlock; override;
    constructor (aPosition: PositionPair; aItems: sequence of VariableDeclaration);
    constructor (aPosition: PositionPair; aItems: array of VariableDeclaration);
    constructor (aPosition: PositionPair; aItems: IList<VariableDeclaration>);

    property Items: ReadOnlyCollection<VariableDeclaration> read fItems;  
  end;

  ConstantBlock = public class(BodyBlock)
  private
    fItems: ReadOnlyCollection<ConstantDeclaration>;
  public
    property &Type: ElementType read ElementType.ConstantBlock; override;
    constructor (aPosition: PositionPair; aItems: sequence of ConstantDeclaration);
    constructor (aPosition: PositionPair; aItems: array of ConstantDeclaration);
    constructor (aPosition: PositionPair; aItems: IList<ConstantDeclaration>);

    property Items: ReadOnlyCollection<ConstantDeclaration> read fItems;  
  end;
  
  TypeBlock = public class(BodyBlock)
  private
    fItems: ReadOnlyCollection<TypeDeclaration>;
  public
    property &Type: ElementType read ElementType.TypeBlock; override;
    constructor (aPosition: PositionPair; aItems: sequence of TypeDeclaration);
    constructor (aPosition: PositionPair; aItems: array of TypeDeclaration);
    constructor (aPosition: PositionPair; aItems: IList<TypeDeclaration>);

    property Items: ReadOnlyCollection<TypeDeclaration> read fItems;  
  end;
  FunctionBlock = public class(BodyBlock)
  private
    fParameters: ReadOnlyCollection<ParameterDeclaration>;
    fItems: ReadOnlyCollection<BodyBlock>;
    fName: String;
    fResult: TypeReference;
    fBody: BlockStatement;
  public
    property &Type: ElementType read ElementType.FunctionBlock; override;
    constructor (aPosition: PositionPair; aName: String; aType: TypeReference; aParameters: sequence of ParameterDeclaration; aItems: sequence of BodyBlock; aBody: BlockStatement);
    constructor (aPosition: PositionPair; aName: String; aType: TypeReference; aParameters: array of ParameterDeclaration; aItems: array of BodyBlock; aBody: BlockStatement);
    constructor (aPosition: PositionPair; aName: String; aType: TypeReference; aParameters: IList<ParameterDeclaration>; aItems: IList<BodyBlock>; aBody: BlockStatement);

    property Parameters: ReadOnlyCollection<ParameterDeclaration> read fParameters;  
    property Items: ReadOnlyCollection<BodyBlock> read fItems; 
    property Name: String read fName;
    property &Result: TypeReference read fResult;
    property Body: BlockStatement read fBody;
  end;
  MainBeginBlock = public class(BodyBlock)
  private
    fBody: BlockStatement;
  public
    property &Type: ElementType read ElementType.MainBeginBlock; override;
    constructor (aPosition: PositionPair; aBody: BlockStatement);

    property Body: BlockStatement read fBody;
  end;
  TypeReference = public abstract class(LanguageElement);
  Expression = public abstract class(LanguageElement);
  Statement = public abstract class(LanguageElement);
  BlockStatement = public class(Statement)
  private
    fItems: ReadOnlyCollection<Statement>;
  public
    property &Type: ElementType read ElementType.BlockStatement; override;
    constructor (aPosition: PositionPair; aItems: sequence of Statement);
    constructor (aPosition: PositionPair; aItems: array of Statement);
    constructor (aPosition: PositionPair; aItems: IList<Statement>);

    property Items: ReadOnlyCollection<Statement> read fItems;  
  end;

  BreakStatement = public class(Statement)
  private
  public
    property &Type: ElementType read ElementType.BreakStatement; override;
  end;

  ContinueStatement = public class(Statement)
  private
  public
    property &Type: ElementType read ElementType.ContinueStatement; override;
  end;

  ExitStatement = public class(Statement)
  private
    fValue: Expression;
  public
    constructor(aPosition: PositionPair; aValue: Expression := nil);
    property Value: Expression read fValue;
    property &Type: ElementType read ElementType.ExitStatement; override;
  end;

  GotoStatement = public class(Statement)
  private
    fTarget: String;
  public
    constructor(aPosition: PositionPair; aTarget: String);
    property Target: String read fTarget;
    property &Type: ElementType read ElementType.GotoStatement; override;
  end;

  WithStatement = public class(Statement)
  private
    fValues: ReadOnlyCollection<Expression>;
    fBody: Statement;
  public
    constructor (aPosition: PositionPair; aValues: Array of Expression; aBody: Statement);
    constructor (aPosition: PositionPair; aValues: sequence of Expression; aBody: Statement);
    constructor (aPosition: PositionPair; aValues: IList<Expression>; aBody: Statement);
    property &Type: ElementType read ElementType.WithStatement; override;

    property Body: Statement read fBody;
    property Values: ReadOnlyCollection<Expression> read fValues;
  end;

  AssignmentStatement = public class(Statement)
  private
    fDest: Expression;
    fSource: Expression;
  public
    constructor (aPosition: PositionPair; aDest: Expression := nil; aSource: Expression);
    property Source: Expression read fSource;
    property Dest: Expression read fDest;
    property &Type: ElementType read ElementType.AssignmentStatement; override;
  end;

  EmptyStatement = public class(Statement)
  private
  public
    property &Type: ElementType read ElementType.EmptyStatement; override;
  end;

  RepeatStatement = public class(Statement)
  private
    fBody: Statement;
    fCondition: Expression;
  public
    constructor(aPosition: PositionPair; aCondition: Expression; aBody: Statement);
    property Condition: Expression read fCondition;
    property Body: Statement read fBody;
    property &Type: ElementType read ElementType.RepeatStatement; override;
  end;
  ForStatement = public class(Statement)
  private
    fBody: Statement;
    fDownto: Boolean;
    fEnd: Expression;
    fStart: Expression;
  public
    constructor (aPosition: PositionPair; aStart, aEnd: Expression; aBody: Statement; aDownto: Boolean);
    property Start: Expression read fStart;
    property &End: Expression read fEnd;
    property &Downto: Boolean read fDownto;
    property Body: Statement read fBody;
    property &Type: ElementType read ElementType.ForStatement; override;
  end;
  WhileStatement = public class(Statement)
  private
    fBody: Statement;
    fCondition: Expression;
  public
    constructor(aPosition: PositionPair; aCondition: Expression; aBody: Statement);
    property Condition: Expression read fCondition;
    property Body: Statement read fBody;
    property &Type: ElementType read ElementType.WhileStatement; override;  
  end;
  
  IfStatement = public class(Statement)
  private
    fFalse: Statement;
    fTrue: Statement;
    fCondition: Expression;
  public
    constructor (aPosition: PositionPair; aCondition: Expression; aTrue, aFalse: Statement);
    property Condition: Expression read fCondition;
    property &True: Statement read fTrue;
    property &False: Statement read fFalse;

    property &Type: ElementType read ElementType.IfStatement; override;
  end;

  TryStatement = public class(Statement)
  private
    fFinallyBeforeExcept: Boolean;
    fFinally: Statement;
    fExcept: Statement;
    fBody: Statement;
  public
    constructor(aPosition: PositionPair; aBody, aFinally, aExcept: Statement; aFinallyBeforeExcept: Boolean);
    property Body: Statement read fBody;
    property &Except: Statement read fExcept;
    property &Finally: Statement read fFinally;
    property FinallyBeforeExcept: Boolean read fFinallyBeforeExcept;

    property &Type: ElementType read ElementType.TryStatement; override;
  end;
  
  CaseElement = public class(LanguageElement)
  private
    fBody: Statement;
    fItems: ReadOnlyCollection<Expression>;
  public
    constructor (aPosition: PositionPair; aValues: Array of Expression; aBody: Statement);
    constructor (aPosition: PositionPair; aValues: sequence of Expression; aBody: Statement);
    constructor (aPosition: PositionPair; aValues: IList<Expression>; aBody: Statement);
    property &Type: ElementType read ElementType.CaseElement; override;

    property Items: ReadOnlyCollection<Expression> read fItems;
    property Body: Statement read fBody;
  end;

  CaseStatement = public class(Statement)
  private
    fElse: Statement;
    fItems: ReadOnlyCollection<CaseElement>;
    fValue: Expression;   
  public
    constructor (aPosition: PositionPair; aValue: Expression; aItems: Array of CaseElement; aElse: Statement);
    constructor (aPosition: PositionPair; aValue: Expression; aItems: sequence of CaseElement; aElse: Statement);
    constructor (aPosition: PositionPair; aValue: Expression; aItems: IList<CaseElement>; aElse: Statement);
    property Value: Expression read fValue;
    property Items: ReadOnlyCollection<CaseElement> read fItems;
    property &Else: Statement read fElse;
    property &Type: ElementType read ElementType.CaseStatement; override;
  end;
  VariableDeclaration = public class(LanguageElement)
  private
    fVarType: TypeReference;
    fName: String;
  public
    constructor (aPosition: PositionPair; aName: String; aType: TypeReference);
    property Name: String read fName;
    property VarType: TypeReference read fVarType;
    property &Type: ElementType read ElementType.VariableDeclaration; override;
  end;

  ConstantDeclaration = public class(LanguageElement)
  private
    fValue: Expression;
    fName: String;
    fconstType: TypeReference;
  public
    constructor(aPosition: PositionPair; aName: String; aType: TypeReference; aValue: Expression);
    property Name: String read fName;
    property ConstType: TypeReference read fconstType;
    property Value: Expression read fValue;
    property &Type: ElementType read ElementType.ConstantDeclaration; override;
  end;

  ParameterModifier = public enum(&In, &Out, &Var, &Const);
  ParameterDeclaration = public class(LanguageElement)
  private
    fModifier: ParameterModifier;
    fParamType: TypeReference;
    fName: String;
  public
    constructor(aPosition: PositionPair; aName: String; aType: TypeReference; aModifier: ParameterModifier);
    property Name:String read fName;
    property ParamType: TypeReference read fParamType;
    property Modifier: ParameterModifier read fModifier;
    property &Type: ElementType read ElementType.ParameterDeclaration; override;
  end;

  TypeDeclaration = public class(LanguageElement)
  private
    fTypeRef: TypeReference;
    fName: String;
  public
    constructor(aPosition: PositionPair; aName: String; aType: TypeReference);
    property Name: String read fName;
    property TypeRef: TypeReference read fTypeRef;
    property &Type: ElementType read ElementType.TypeDeclaration; override;
  end;
  IdentifierExpression = public class(Expression)
  private
    fValue: String;
  public
    constructor(aPosition: PositionPair; aValue: String);
    property Value: String read fValue;
    property &Type: ElementType read ElementType.IdentifierExpression; override;
  end;
  CallExpression = public class(Expression)
  private
    fArguments: ReadOnlyCollection<Expression>;
    fSelf: Expression;
  public
    constructor (aPosition: PositionPair; aSelf: Expression; aArguments: Array of Expression);
    constructor (aPosition: PositionPair; aSelf: Expression; aArguments: sequence of Expression);
    constructor (aPosition: PositionPair; aSelf: Expression; aArguments: IList<Expression>);
    property &Self: Expression read fSelf;
    property Arguments: ReadOnlyCollection<Expression> read fArguments;
    property &Type: ElementType read ElementType.CallExpression; override;
  end;
  OrdExpression = public class(Expression)
  private
    fValue: Expression;
  public
    constructor (aPosition: PositionPair; aValue: Expression);
    property Value: Expression read fValue;
    property &Type: ElementType read ElementType.OrdExpression; override;
  end;
  ChrExpression = public class(Expression)
  private
    fValue: Expression;
  public
    constructor (aPosition: PositionPair; aValue: Expression);
    property Value: Expression read fValue;
    property &Type: ElementType read ElementType.OrdExpression; override;
  end;
  ArrayElementExpression = public class(CallExpression)
  public
    property &Type: ElementType read ElementType.ArrayElementExpression; override;
  end;
  FloatExpression = public class(Expression)
  private
    fValue: Double;
  public
    constructor (aPosition: PositionPair; aValue: Double);
    property Value: Double read fValue;
    property &Type: ElementType read ElementType.FloatExpression; override;
  end;
  IntegerExpression = public class(Expression)
  private
    fValue: Int64;
  public
    constructor (aPosition: PositionPair; aValue: Int64);
    property Value: Int64 read fValue;
    property &Type: ElementType read ElementType.IntegerExpression; override;
  end;
  UnaryOperator = public enum (&Not, &Minus, AdressOf, Dereference);
  UnaryExpression = public class(Expression)
  private
    fOperator: UnaryOperator;
    fValue: Expression;
  public
    constructor (aPosition: PositionPair; aValue: Expression; anOperator: UnaryOperator);
    property Value: Expression read fValue;
    property &Operator: UnaryOperator read fOperator;
    property &Type: ElementType read ElementType.UnaryExpression; override;
  end;
  BinaryOperator = public enum (&Add,&Sub,&Mul,&Div,&Mod,&Shl,&Shr,&And,&Or,&Xor,&As,&GreaterEqual,&LessEqual,&Greater,&Less,&Equal,&NotEqual,&Is,&In);
  BinaryExpression = public class(Expression)
  private
    fOperator: BinaryOperator;
    fLeft, fRight: Expression;
  public
    constructor (aPosition: PositionPair; aLeft, aRight: Expression; anOperator: BinaryOperator);
    constructor (aLeft, aRight: Expression; anOperator: BinaryOperator);
    property Left: Expression read fLeft;
    property Right: Expression read fRight;
    property &Operator: BinaryOperator read fOperator;
    property &Type: ElementType read ElementType.BinaryExpression; override;
  end;
  NilExpression = public class(Expression)
  private
  public
    property &Type: ElementType read ElementType.NilExpression; override;
  end;
  TrueExpression = public class(Expression)
  private
  public
    property &Type: ElementType read ElementType.TrueExpression; override;
  end;
  FalseExpression = public class(Expression)
  private
  public
    property &Type: ElementType read ElementType.FalseExpression; override;
  end;
  StringExpression = public class(Expression)
  private
    fValue: String;
  public
    constructor (aPosition: PositionPair; aValue: String);
    property Value: String read fValue;
    property &Type: ElementType read ElementType.StringExpression; override;
  end;
  ResultExpression = public class(Expression)
  private
  public
    property &Type: ElementType read ElementType.ResultExpression; override;
  end;
  ArrayExpression = public class(Expression)
  private
    fArguments: ReadOnlyCollection<Expression>;
  public
    constructor (aPosition: PositionPair; aArguments: Array of Expression);
    constructor (aPosition: PositionPair; aArguments: sequence of Expression);
    constructor (aPosition: PositionPair; aArguments: IList<Expression>);
    property Arguments: ReadOnlyCollection<Expression> read fArguments;   
    property &Type: ElementType read ElementType.ArrayElementExpression; override;
  end;
  RangeExpression = public class(Expression)
  private
    fLeft,
    fRight: Expression;
  public
    constructor (aPosition: PositionPair; aLeft, aRight: Expression);
    property Left: Expression read fLeft;
    property Right: Expression read fRight;
    property &Type: ElementType read ElementType.RangeExpression; override;
  end;
  MemberExpression = public class(Expression)
  private
    fMember: String;
    fSelf: Expression;
  public
    constructor(aPosition: PositionPair; aSelf: Expression; aMember: String);

    property Member: String read fMember;
    property &Self: Expression read fSelf; 
    property &Type: ElementType read ElementType.MemberExpression; override;
  end;

  RecordDeclaration = public class(TypeReference)
  private
    fVariables: ReadOnlyCollection<VariableDeclaration>;
  public
    constructor(aPosition: PositionPair; aVariables: sequence of VariableDeclaration);
    constructor(aPosition: PositionPair; aVariables: array of VariableDeclaration);
    constructor(aPosition: PositionPair; aVariables: IList<VariableDeclaration>);
    property Variables: ReadOnlyCollection<VariableDeclaration> read fVariables;
    property &Type: ElementType read ElementType.RecordDeclaration; override;
  end;

  EnumValue = public class(LanguageElement)
  private
    fName: String;
    fValue: Expression;
  public
    constructor (aPosition: PositionPair; aName: String; aValue: Expression := nil);
    property Name: String read fName;
    property Value: Expression read fValue;
    property &Type: ElementType read ElementType.EnumValue;  override;
  end;

  EnumDeclaration = public class(TypeReference)
  private
    fValues: ReadOnlyCollection<EnumValue>;
  public
    constructor(aPosition: PositionPair; aVariables: sequence of EnumValue);
    constructor(aPosition: PositionPair; aVariables: array of EnumValue);
    constructor(aPosition: PositionPair; aVariables: IList<EnumValue>);
    property Values: ReadOnlyCollection<EnumValue> read fValues;
    property &Type: ElementType read ElementType.EnumDeclaration; override;
  end;
  FunctionPointerDeclaration = public class(TypeReference)
  private 
    fParameters: ReadOnlyCollection<ParameterDeclaration>;
    fResult: TypeReference;
  public
    constructor (aPosition: PositionPair; aType: TypeReference; aParameters: sequence of ParameterDeclaration);
    constructor (aPosition: PositionPair; aType: TypeReference; aParameters: array of ParameterDeclaration);
    constructor (aPosition: PositionPair; aType: TypeReference; aParameters: IList<ParameterDeclaration>);

    property Parameters: ReadOnlyCollection<ParameterDeclaration> read fParameters;  
    property &Result: TypeReference read fResult;
    property &Type: ElementType read ElementType.FunctionPointerDeclaration; override;
  end;
  ArrayDeclaration = public class(TypeReference)
  private
    fSubType: TypeReference;
  public
    constructor(aPosition: PositionPair; aSubType: TypeReference);
    property SubType: TypeReference read fSubType;
    property &Type: ElementType read ElementType.ArrayDeclaration; override;
  end;
  StaticArrayDeclaration = public class(ArrayDeclaration)
  private
    fStartRange,
    fendRange: Expression;
  public
    constructor(aPosition: PositionPair; aSubType: TypeReference; aStartRange, aEndRange: Expression);
    property StartRange: Expression read fStartRange;
    property EndRange: Expression read fendRange;
    property &Type: ElementType read ElementType.StaticArrayDeclaration; override;
  end;
  SetDeclaration = public class(EnumDeclaration)
  private
    fSetOf: TypeReference;
  public
    constructor(aPosition: PositionPair; aVariables: sequence of EnumValue);
    constructor(aPosition: PositionPair; aVariables: array of EnumValue);
    constructor(aPosition: PositionPair; aVariables: IList<EnumValue>);
    constructor(aPosition: PositionPair; aSetOf: TypeReference);

    property SetOf: TypeReference read fSetOf;
    
    property &Type: ElementType read ElementType.SetDeclaration; override;
  end;
  TypeNameReference = public class(TypeReference)
  private
    fName: String;
  public
    constructor(aPosition: PositionPair; aName: String);
    property Name: String read fName;
    property &Type: ElementType read ElementType.TypeNameReference; override;
  end;

implementation

constructor LanguageElement(aPositionPair: PositionPair);
begin
  fPositionPair := aPositionPair;
end;


constructor ProgramBlock(aPosition: PositionPair; aIsUnit: Boolean; aName: String; aItems: sequence of BodyBlock);
begin
  inherited constructor(aPosition);
  fIsUnit := aIsUnit;
  fName := aName;
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
end;

constructor ProgramBlock(aPosition: PositionPair; aIsUnit: Boolean; aName: String; aItems: array of BodyBlock);
begin
  inherited constructor(aPosition);
  fIsUnit := aIsUnit;
  fName := aName;
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
end;

constructor ProgramBlock(aPosition: PositionPair; aIsUnit: Boolean; aName: String; aItems: IList<BodyBlock>);
begin
  inherited constructor(aPosition);
  fIsUnit := aIsUnit;
  fName := aName;
  fItems := new ReadOnlyCollection<BodyBlock>(aItems);
end;

constructor UsesBlock(aPosition: PositionPair; aItems: sequence of String);
begin
  inherited constructor(aPosition);
  //fItems := new ReadOnlyCollection<String>(new List<String>(aItems));
end;

constructor UsesBlock(aPosition: PositionPair; aItems: array of String);
begin
  inherited constructor(aPosition);
  //fItems := new ReadOnlyCollection<String>(new List<String>(aItems));
end;

constructor UsesBlock(aPosition: PositionPair; aItems: IList<String>);
begin
  inherited constructor(aPosition);
  //fItems := new ReadOnlyCollection<String>(aItems);
end;

constructor InterfaceBlock(aPosition: PositionPair; aItems: sequence of BodyBlock);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
end;

constructor InterfaceBlock(aPosition: PositionPair; aItems: array of BodyBlock);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
end;

constructor InterfaceBlock(aPosition: PositionPair; aItems: IList<BodyBlock>);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<BodyBlock>(aItems);
end;

constructor ImplementationBlock(aPosition: PositionPair; aItems: sequence of BodyBlock);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
end;

constructor ImplementationBlock(aPosition: PositionPair; aItems: array of BodyBlock);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
end;

constructor ImplementationBlock(aPosition: PositionPair; aItems: IList<BodyBlock>);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<BodyBlock>(aItems);
end;

constructor LabelBlock(aPosition: PositionPair; aItems: sequence of String);
begin
  inherited constructor(aPosition);
  //fItems := new ReadOnlyCollection<String>(new List<String>(aItems));
end;

constructor LabelBlock(aPosition: PositionPair; aItems: array of String);
begin
  inherited constructor(aPosition);
  //fItems := new ReadOnlyCollection<String>(new List<String>(aItems));
end;

constructor LabelBlock(aPosition: PositionPair; aItems: IList<String>);
begin
  inherited constructor(aPosition);
  //fItems := new ReadOnlyCollection<String>(aItems);
end;

constructor VariableBlock(aPosition: PositionPair; aItems: sequence of VariableDeclaration);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<VariableDeclaration>(new List<VariableDeclaration>(aItems));
end;

constructor VariableBlock(aPosition: PositionPair; aItems: array of VariableDeclaration);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<VariableDeclaration>(new List<VariableDeclaration>(aItems));
end;

constructor VariableBlock(aPosition: PositionPair; aItems: IList<VariableDeclaration>);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<VariableDeclaration>((aItems));
end;

constructor ConstantBlock(aPosition: PositionPair; aItems: sequence of ConstantDeclaration);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<ConstantDeclaration>(new List<ConstantDeclaration>(aItems));
end;

constructor ConstantBlock(aPosition: PositionPair; aItems: array of ConstantDeclaration);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<ConstantDeclaration>(new List<ConstantDeclaration>(aItems));
end;

constructor ConstantBlock(aPosition: PositionPair; aItems: IList<ConstantDeclaration>);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<ConstantDeclaration>(aItems);
end;

constructor TypeBlock(aPosition: PositionPair; aItems: sequence of TypeDeclaration);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<TypeDeclaration>(new List<TypeDeclaration>(aItems));
end;

constructor TypeBlock(aPosition: PositionPair; aItems: array of TypeDeclaration);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<TypeDeclaration>(new List<TypeDeclaration>(aItems));
end;

constructor TypeBlock(aPosition: PositionPair; aItems: IList<TypeDeclaration>);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<TypeDeclaration>(aItems);
end;

constructor FunctionBlock(aPosition: PositionPair; aName: String; aType: TypeReference; aParameters: sequence of ParameterDeclaration; aItems: sequence of BodyBlock; aBody: BlockStatement);
begin
  inherited constructor(aPosition);
  fName := aName;
  fResult := aType;
  fParameters := new ReadOnlyCollection<ParameterDeclaration>(new List<ParameterDeclaration>(aParameters));
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
  fBody := aBody;
end;

constructor FunctionBlock(aPosition: PositionPair; aName: String; aType: TypeReference; aParameters: array of ParameterDeclaration; aItems: array of BodyBlock; aBody: BlockStatement);
begin
  inherited constructor(aPosition);
  fName := aName;
  fResult := aType;
  fParameters := new ReadOnlyCollection<ParameterDeclaration>(new List<ParameterDeclaration>(aParameters));
  fItems := new ReadOnlyCollection<BodyBlock>(new List<BodyBlock>(aItems));
  fBody := aBody;
end;

constructor FunctionBlock(aPosition: PositionPair; aName: String; aType: TypeReference; aParameters: IList<ParameterDeclaration>; aItems: IList<BodyBlock>; aBody: BlockStatement);
begin
  inherited constructor(aPosition);
  fName := aName;
  fResult := aType;
  fParameters := new ReadOnlyCollection<ParameterDeclaration>(aParameters);
  fItems := new ReadOnlyCollection<BodyBlock>(aItems);
  fBody := aBody;
end;

constructor BlockStatement(aPosition: PositionPair; aItems: sequence of Statement);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<Statement>(new List<Statement>(aItems));
end;

constructor BlockStatement(aPosition: PositionPair; aItems: array of Statement);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<Statement>(new List<Statement>(aItems));
end;

constructor BlockStatement(aPosition: PositionPair; aItems: IList<Statement>);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<Statement>(aItems);
end;

constructor ExitStatement(aPosition: PositionPair; aValue: Expression := nil);
begin
  inherited constructor(aPosition);
  fValue := aValue;
end;

constructor GotoStatement(aPosition: PositionPair; aTarget: String);
begin
  inherited constructor(aPosition);
  fTarget := aTarget;
end;


constructor WithStatement(aPosition: PositionPair; aValues: Array of Expression; aBody: Statement);
begin
  inherited constructor(aPosition);
  fBody := aBody;
  fValues := new ReadOnlyCollection<Expression>(new List<Expression>(aValues));
end;

constructor WithStatement(aPosition: PositionPair; aValues: sequence of Expression; aBody: Statement);
begin
  inherited constructor(aPosition);
  fBody := aBody;
  fValues := new ReadOnlyCollection<Expression>(new List<Expression>(aValues));
end;

constructor WithStatement(aPosition: PositionPair; aValues: IList<Expression>; aBody: Statement);
begin
  inherited constructor(aPosition);
  fBody := aBody;
  fValues := new ReadOnlyCollection<Expression>(aValues);
end;

constructor AssignmentStatement(aPosition: PositionPair; aDest: Expression := nil; aSource: Expression);
begin
  inherited constructor(aPosition);
  fDest := aDest;
  fSource := aSource;
end;

constructor RepeatStatement(aPosition: PositionPair; aCondition: Expression; aBody: Statement);
begin
  inherited constructor(aPosition);
  fCondition := aCondition;
  fBody := aBody;
end;

constructor WhileStatement(aPosition: PositionPair; aCondition: Expression; aBody: Statement);
begin
  inherited constructor(aPosition);
  fCondition := aCondition;
  fBody := aBody;
end;

constructor ForStatement(aPosition: PositionPair; aStart, aEnd: Expression; aBody: Statement; aDownto: Boolean);
begin
  inherited constructor(aPosition);
  fStart := aStart;
  fEnd := aEnd;
  fDownto := aDownto;
  fBody := aBody;
end;

constructor IfStatement(aPosition: PositionPair; aCondition: Expression; aTrue, aFalse: Statement);
begin
  inherited constructor(aPosition);
  fCondition := aCondition;
  fTrue := aTrue;
  fFalse := aFalse;
end;

constructor TryStatement(aPosition: PositionPair; aBody, aFinally, aExcept: Statement; aFinallyBeforeExcept: Boolean);
begin
  inherited constructor(aPosition);
  fBody := aBody;
  fFinally := aFinally;
  fExcept := aExcept;
  fFinallyBeforeExcept := aFinallyBeforeExcept;
end;

constructor CaseElement(aPosition: PositionPair; aValues: Array of Expression; aBody: Statement);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<Expression>(new List<Expression>(aValues));
  fBody := aBody;
end;

constructor CaseElement(aPosition: PositionPair; aValues: sequence of Expression; aBody: Statement);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<Expression>(new List<Expression>(aValues));
  fBody := aBody;
end;

constructor CaseElement(aPosition: PositionPair; aValues: IList<Expression>; aBody: Statement);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<Expression>(aValues);
  fBody := aBody;
end;

constructor CaseStatement(aPosition: PositionPair; aValue: Expression; aItems: Array of CaseElement; aElse: Statement);
begin
  inherited constructor(aPosition);
  fItems := new ReadOnlyCollection<CaseElement>(new List<CaseElement>(aItems));
  fElse := aElse;
  fValue := aValue;
end;

constructor CaseStatement(aPosition: PositionPair; aValue: Expression; aItems: sequence of CaseElement; aElse: Statement);
begin
  inherited constructor(aPosition);
  fValue := aValue;
  fItems := new ReadOnlyCollection<CaseElement>(new List<CaseElement>(aItems));
  fElse := aElse;
end;

constructor CaseStatement(aPosition: PositionPair; aValue: Expression; aItems: IList<CaseElement>; aElse: Statement);
begin
  inherited constructor(aPosition);
  fValue := aValue;
  fItems := new ReadOnlyCollection<CaseElement>(aItems);
  fElse := aElse;
end;

constructor VariableDeclaration(aPosition: PositionPair; aName: String; aType: TypeReference);
begin
  inherited constructor(aPosition);
  fName := aName;
  fVarType := aType;
end;

constructor ConstantDeclaration(aPosition: PositionPair; aName: String; aType: TypeReference; aValue: Expression);
begin
  inherited constructor(aPosition);
  fName := aName;
  fconstType := aType;
  fValue := aValue;
end;

constructor ParameterDeclaration(aPosition: PositionPair; aName: String; aType: TypeReference; aModifier: ParameterModifier);
begin
  inherited constructor(aPosition);
  fName := aName;
  fParamType := aType;
  fModifier := aModifier;
end;

constructor TypeDeclaration(aPosition: PositionPair; aName: String; aType: TypeReference);
begin
  inherited constructor(aPosition);
  fName := aName;
  fTypeRef := aType;
end;

constructor IdentifierExpression(aPosition: PositionPair; aValue: String);
begin
  inherited constructor(aPosition);
  fValue := aValue;
end;

constructor FloatExpression(aPosition: PositionPair; aValue: Double);
begin
  inherited constructor(aPosition);
  fValue := aValue;
end;

constructor IntegerExpression(aPosition: PositionPair; aValue: Int64);
begin
  inherited constructor(aPosition);
  fValue := aValue;
end;

constructor StringExpression(aPosition: PositionPair; aValue: String);
begin
  inherited constructor(aPosition);
  fValue := aValue;
end;

constructor CallExpression(aPosition: PositionPair; aSelf: Expression; aArguments: Array of Expression);
begin
  inherited constructor(aPosition);
  fSelf := aSelf;
  fArguments := new ReadOnlyCollection<Expression>(new List<Expression>(aArguments));
end;

constructor CallExpression(aPosition: PositionPair; aSelf: Expression; aArguments: sequence of Expression);
begin
  inherited constructor(aPosition);
  fSelf := aSelf;
  fArguments:= new ReadOnlyCollection<Expression>(new List<Expression>(aArguments));
end;

constructor CallExpression(aPosition: PositionPair; aSelf: Expression; aArguments: IList<Expression>);
begin
  inherited constructor(aPosition);
  fSelf := aSelf;
  fArguments:= new ReadOnlyCollection<Expression>(aArguments);
end;

constructor UnaryExpression(aPosition: PositionPair; aValue: Expression; anOperator: UnaryOperator);
begin
  inherited constructor(aPosition);
  fValue := aValue;
  fOperator := anOperator;
end;

constructor BinaryExpression(aPosition: PositionPair; aLeft, aRight: Expression; anOperator: BinaryOperator);
begin
  inherited constructor(aPosition);
  fLeft := aLeft;
  fRight := aRight;
  fOperator := anOperator;
end;

constructor BinaryExpression(aLeft, aRight: Expression; anOperator: BinaryOperator);
begin
  constructor(new PositionPair(aLeft.PositionPair.StartPos,aLeft.PositionPair.StartRow, aLeft.PositionPair.StartCol, aRight.PositionPair.EndPos,aRight.PositionPair.EndRow, aRight.PositionPair.EndCol, aLeft.PositionPair.File), aLeft, aRight, anOperator);
end;

constructor ArrayExpression(aPosition: PositionPair; aArguments: Array of Expression);
begin
  inherited constructor(aPosition);
  fArguments := new ReadOnlyCollection<Expression>(new List<Expression>(aArguments));
end;

constructor ArrayExpression(aPosition: PositionPair; aArguments: sequence of Expression);
begin
  inherited constructor(aPosition);
  fArguments := new ReadOnlyCollection<Expression>(new List<Expression>(aArguments));
end;

constructor ArrayExpression(aPosition: PositionPair; aArguments: IList<Expression>);
begin
  inherited constructor(aPosition);
  fArguments := new ReadOnlyCollection<Expression>(aArguments);
end;

constructor RangeExpression(aPosition: PositionPair; aLeft, aRight: Expression);
begin
  inherited constructor(aPosition);
  fLeft := aLeft;
  fRight := aRight;
end;

constructor RecordDeclaration(aPosition: PositionPair; aVariables: sequence of VariableDeclaration);
begin
  inherited constructor(aPosition);
  fVariables:= new ReadOnlyCollection<VariableDeclaration>(new List<VariableDeclaration>(aVariables));
end;

constructor RecordDeclaration(aPosition: PositionPair; aVariables: array of VariableDeclaration);
begin
  inherited constructor(aPosition);
  fVariables:= new ReadOnlyCollection<VariableDeclaration>(new List<VariableDeclaration>(aVariables));
end;

constructor RecordDeclaration(aPosition: PositionPair; aVariables: IList<VariableDeclaration>);
begin
  inherited constructor(aPosition);
  fVariables:= new ReadOnlyCollection<VariableDeclaration>(aVariables);
end;

constructor EnumValue(aPosition: PositionPair; aName: String; aValue: Expression := nil);
begin
  inherited constructor(aPosition);
  fName := aName;
  fValue := aValue;
end;

constructor EnumDeclaration(aPosition: PositionPair; aVariables: sequence of EnumValue);
begin
  inherited constructor(aPosition);
  fValues:= new ReadOnlyCollection<EnumValue>(new List<EnumValue>(aVariables));
end;

constructor EnumDeclaration(aPosition: PositionPair; aVariables: array of EnumValue);
begin
  inherited constructor(aPosition);
  fValues:= new ReadOnlyCollection<EnumValue>(new List<EnumValue>(aVariables));
end;

constructor EnumDeclaration(aPosition: PositionPair; aVariables: IList<EnumValue>);
begin
  inherited constructor(aPosition);
  fValues:= new ReadOnlyCollection<EnumValue>(aVariables);
end;

constructor FunctionPointerDeclaration(aPosition: PositionPair; aType: TypeReference; aParameters: sequence of ParameterDeclaration);
begin
  inherited constructor(aPosition);
  fResult := aType;
  fParameters:= new ReadOnlyCollection<ParameterDeclaration>(new List<ParameterDeclaration>(aParameters));
end;

constructor FunctionPointerDeclaration(aPosition: PositionPair; aType: TypeReference; aParameters: array of ParameterDeclaration);
begin
  inherited constructor(aPosition);
  fResult := aType;
  fParameters:= new ReadOnlyCollection<ParameterDeclaration>(new List<ParameterDeclaration>(aParameters));
end;

constructor FunctionPointerDeclaration(aPosition: PositionPair; aType: TypeReference; aParameters: IList<ParameterDeclaration>);
begin
  inherited constructor(aPosition);
  fResult := aType;
  fParameters:= new ReadOnlyCollection<ParameterDeclaration>(aParameters);
end;

constructor ArrayDeclaration(aPosition: PositionPair; aSubType: TypeReference);
begin
  inherited constructor(aPosition);
  fSubType := aSubType;
end;

constructor StaticArrayDeclaration(aPosition: PositionPair; aSubType: TypeReference; aStartRange, aEndRange: Expression);
begin
  inherited constructor(aPosition, aSubType);
  fStartRange := aStartRange;
  fendRange := aEndRange;
end;

constructor TypeNameReference(aPosition: PositionPair; aName: String);
begin
  inherited constructor(aPosition);
  fName := aName;
end;

constructor MainBeginBlock(aPosition: PositionPair; aBody: BlockStatement);
begin
  inherited constructor(aPosition);
  fBody := aBody;
end;


constructor SetDeclaration(aPosition: PositionPair; aVariables: sequence of EnumValue);
begin
  inherited constructor(aPosition, aVariables);
end;

constructor SetDeclaration(aPosition: PositionPair; aVariables: array of EnumValue);
begin
  inherited constructor(aPosition, aVariables);
end;

constructor SetDeclaration(aPosition: PositionPair; aVariables: IList<EnumValue>);
begin
  inherited constructor(aPosition, aVariables);
end;

constructor SetDeclaration(aPosition: PositionPair; aSetOf: TypeReference);
begin
  inherited constructor(aPosition, []);
  fSetOf := aSetOf;
end;

constructor ChrExpression(aPosition: PositionPair; aValue: Expression);
begin
  inherited constructor(aPosition);
  fValue := aValue;
end;

constructor OrdExpression(aPosition: PositionPair; aValue: Expression);
begin
  inherited constructor(aPosition);
  fValue := aValue;
end;

constructor MemberExpression(aPosition: PositionPair; aSelf: Expression; aMember: String);
begin
  inherited constructor(aPosition);
  fSelf := aSelf;
  fMember := aMember;
end;

end.