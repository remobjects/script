{

  Copyright (c) 2009-2010 RemObjects Software. See LICENSE.txt for more details.

}
namespace RemObjects.Script.EcmaScript.Internal;

interface
uses
  RemObjects.Script,
  System.Reflection.Emit,
  System.Collections.ObjectModel,
  System.Collections.Generic;

type

  ElementType = public enum  (
    Program,
    FunctionDeclaration,
    BlockStatement,
    VariableStatement,
    EmptyStatement,
    ExpressionStatement,
    IfStatement,
    ForStatement, 
    ForInStatement, 
    WhileStatement, 
    DoStatement,
    ContinueStatement,
    BreakStatement,
    ReturnStatement,
    WithStatement,
    LabelledStatement,
    SwitchStatement,
    ThrowStatement,
    TryStatement,
    DebuggerStatement,
    VariableDeclaration,
    CaseClause,
    CatchBlock,
    BinaryExpression,
    UnaryExpression,
    ConditionalExpression,
    NewExpression,
    CallExpression,
    SubExpression,
    ArrayAccessExpression,
    ThisExpression,
    IdentifierExpression,
    NullExpression,
    IntegerExpression,
    DecimalExpression,
    StringExpression,
    BooleanExpression,
    ArrayLiteralExpression,
    ObjectLiteralExpression,
    FunctionExpression,
    ParameterDeclaration,
    PropertyAssignment,
    RegExExpression,
    CommaSeparatedExpression
  );

  
  LanguageElement = public abstract class
  private
    fPositionPair: PositionPair;
  public
    constructor (aPositionPair: PositionPair);
    property PositionPair: PositionPair read fPositionPair;
    property &Type: ElementType read; abstract;
  end;

  SourceElement = public abstract class(LanguageElement); // FunctionDeclaration OR a Statement
  Statement = public abstract class(SourceElement);

  ParameterDeclaration = public class(SourceElement)
  private
    fName: String;
  public
    constructor(aPositionPair: PositionPair; aName: String);
    property Name: String read fName;
    property &Type: ElementType read ElementType.ParameterDeclaration; override;
  end;

  FunctionDeclarationType = public enum (None, &Set, &Get);
  FunctionDeclarationElement = public class(SourceElement, IList<SourceElement>)
  private
    fMode: FunctionDeclarationType;
    fIdentifier: String;
    fParameters: List<ParameterDeclaration>;
    fItems: List<SourceElement>;
  public
    constructor(aPositionPair: PositionPair; aMode: FunctionDeclarationType := FunctionDeclarationType.None; anIdentifier: String; aParameters: Array of ParameterDeclaration; params aItems: Array of SourceElement);
    constructor(aPositionPair: PositionPair; aMode: FunctionDeclarationType := FunctionDeclarationType.None; anIdentifier: String; aParameters: sequence of ParameterDeclaration; aItems: sequence of SourceElement);
    constructor(aPositionPair: PositionPair; aMode: FunctionDeclarationType := FunctionDeclarationType.None; anIdentifier: String; aParameters: List<ParameterDeclaration>; aItems: List<SourceElement>);
    property Items: List<SourceElement> read fItems; implements IList<SourceElement>;
    property Identifier: String read fIdentifier;
    property Parameters: List<ParameterDeclaration> read fParameters;
    property Mode: FunctionDeclarationType read fMode;
    property &Type: ElementType read ElementType.FunctionDeclaration; override;
  end;

  BlockStatement = public class(Statement, IList<SourceElement>)
  private
    fItems: List<SourceElement>;
  public
    constructor(aPositionPair: PositionPair; params aStatements: array of SourceElement);
    constructor(aPositionPair: PositionPair; aStatements: sequence of SourceElement);
    constructor(aPositionPair: PositionPair; aStatements: List<SourceElement>);
    property Items: List<SourceElement> read fItems; implements IList<SourceElement>;
    property &Type: ElementType read ElementType.BlockStatement; override;
  end;

  VariableStatement = public class(Statement, IList<VariableDeclaration>)
  private
    fVariables: List<VariableDeclaration>;
  public
    constructor(aPositionPair: PositionPair; params aVariables: array of VariableDeclaration);
    constructor(aPositionPair: PositionPair; aVariables: sequence of VariableDeclaration);
    constructor(aPositionPair: PositionPair; aVariables: List<VariableDeclaration>);

    property Items: List<VariableDeclaration> read fVariables; implements IList<VariableDeclaration>;
    property &Type: ElementType read ElementType.VariableStatement; override;
  end;

  VariableDeclaration = public class(SourceElement)
  private
    fInitializer: ExpressionElement;
    fIdentifier: String;
  public
    constructor (aPositionPair: PositionPair; aIdentifier: String; aInitializer: ExpressionElement := nil);
    property Identifier: String read fIdentifier;
    property Initializer: ExpressionElement read fInitializer;
    property &Type: ElementType read ElementType.VariableDeclaration; override;
  end;

  EmptyStatement = public class(Statement)
  private
  public
    property &Type: ElementType read ElementType.EmptyStatement; override;
  end;

  IfStatement = public class(Statement)
  private
    fFalse: Statement;
    fTrue: Statement;
    fExpression: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; aExpression: ExpressionElement; aTrue: Statement; aFalse: Statement := nil);
    property ExpressionElement: ExpressionElement read fExpression;
    property &True: Statement read fTrue;
    property &False: Statement read fFalse;

    property &Type: ElementType read ElementType.IfStatement; override;
  end;
  IterationStatement  = public abstract class(Statement)
  private
  public
    property &Break: nullable Label;
    property &Continue: nullable Label;
  end;

  ForStatement  = public class(IterationStatement)
  private
    fBody: Statement;
    fIncrement: ExpressionElement;
    fComparison: ExpressionElement;
    fInitializer: ExpressionElement;
    fInitializers: List<VariableDeclaration>;
  public
    constructor(aPositionPair: PositionPair; aInitializer: ExpressionElement; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);
    constructor(aPositionPair: PositionPair; aInitializers: array of VariableDeclaration; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);
    constructor(aPositionPair: PositionPair; aInitializers: sequence of VariableDeclaration; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);
    constructor(aPositionPair: PositionPair; aInitializers: List<VariableDeclaration>; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);

    property Initializers: List<VariableDeclaration> read fInitializers;
    property Initializer: ExpressionElement read fInitializer;
    property Comparison: ExpressionElement read fComparison;
    property Increment: ExpressionElement read fIncrement;
    property Body: Statement read fBody;

    property &Type: ElementType read ElementType.ForStatement; override;
  end;

  ForInStatement = public class(IterationStatement)
  private
    fInitializer: VariableDeclaration;
    fLeftExpression: ExpressionElement;
    fExpression: ExpressionElement;
    fBody: Statement;
  public
    constructor(aPositionPair: PositionPair; aLeftExpression, anExpression: ExpressionElement; aBody: Statement);
    constructor(aPositionPair: PositionPair; anInitializer: VariableDeclaration; anExpression: ExpressionElement; aBody: Statement);

    property Body: Statement read fBody;
    property Initializer: VariableDeclaration read fInitializer;
    property LeftExpression: ExpressionElement read fLeftExpression;
    property ExpressionElement: ExpressionElement read fExpression;
    property &Type: ElementType read ElementType.ForInStatement; override;
  end;

  WhileStatement  = public class(IterationStatement)
  private
    fExpression: ExpressionElement;
    fBody: Statement;
  public
    constructor(aPositionPair: PositionPair; anExpression: ExpressionElement; aBody: Statement);

    property Body: Statement read fBody;
    property ExpressionElement: ExpressionElement read fExpression;
    property &Type: ElementType read ElementType.WhileStatement; override;
  end;

  DoStatement = public class(IterationStatement)
  private
    fExpression: ExpressionElement;
    fBody: Statement;
  public
    constructor(aPositionPair: PositionPair; aBody: Statement; anExpression: ExpressionElement);

    property Body: Statement read fBody;
    property ExpressionElement: ExpressionElement read fExpression;
    property &Type: ElementType read ElementType.DoStatement; override;
  end;

  ContinueStatement  = public class(Statement)
  private
    fIdentifier: String;
  public
    constructor (aPositionPair: PositionPair; aIdentifier: String := nil);
    property Identifier: String read fIdentifier;
    property &Type: ElementType read ElementType.ContinueStatement; override;
  end;

  BreakStatement  = public class(Statement)
  private
    fIdentifier: String;
  public
    constructor (aPositionPair: PositionPair; aIdentifier: String := nil);
    property Identifier: String read fIdentifier;
    property &Type: ElementType read ElementType.BreakStatement; override;
  end;

  ReturnStatement  = public class(Statement)
  private
    fExpression: ExpressionElement;
  public
    constructor (aPositionPair: PositionPair; aExpression: ExpressionElement := nil);
    property ExpressionElement: ExpressionElement read fExpression;
    property &Type: ElementType read ElementType.ReturnStatement; override;
  end;

  WithStatement  = public class(Statement)
  private
    fBody: Statement;
    fExpression: ExpressionElement;
  public
    constructor (aPositionPair: PositionPair; aExpression: ExpressionElement; aBody: Statement);
    property ExpressionElement: ExpressionElement read fExpression;
    property Body: Statement read fBody;
    property &Type: ElementType read ElementType.WithStatement; override;  
  end;

  LabelledStatement  = public class(IterationStatement)
  private
    fStatement: Statement;
    fIdentifier: String;
  public
    constructor (aPositionPair: PositionPair; anIdentifier: String; aStatement: Statement);
    property Identifier: String read fIdentifier;
    property Statement: Statement read fStatement;
    property &Type: ElementType read ElementType.LabelledStatement; override;
  end;

  CaseClause = public class(SourceElement, IList<Statement>)
  private
    fBody: List<Statement>;
    fExpression: ExpressionElement;
  public
    constructor (aPositionPair: PositionPair; anExpression: ExpressionElement := nil; params aBody: Array of Statement);
    constructor (aPositionPair: PositionPair; anExpression: ExpressionElement := nil; aBody: sequence of Statement);
    constructor (aPositionPair: PositionPair; anExpression: ExpressionElement := nil; aBody: List<Statement>);

    property ExpressionElement: ExpressionElement read fExpression;
    property Body: List<Statement> read fBody; implements IList<Statement>;
    property IsDefault: Boolean read fExpression = nil;

    property &Type: ElementType read ElementType.CaseClause; override;
  end;

  SwitchStatement  = public class(IterationStatement, IList<CaseClause>)
  private
    fClauses: List<CaseClause>;
    fExpression: ExpressionElement;
  public
    constructor (aPositionPair: PositionPair; anExpression: ExpressionElement; params aClauses: Array of CaseClause);
    constructor (aPositionPair: PositionPair; anExpression: ExpressionElement; aClauses: sequence of CaseClause);
    constructor (aPositionPair: PositionPair; anExpression: ExpressionElement; aClauses: List<CaseClause>);

    property ExpressionElement: ExpressionElement read fExpression;
    property Clauses: List<CaseClause> read fClauses; implements IList<CaseClause>;

    property &Type: ElementType read ElementType.SwitchStatement; override;
  end;

  ThrowStatement  = public class(Statement)
  private
    fExpression: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; anExpression: ExpressionElement);
    property ExpressionElement: ExpressionElement read fExpression;

    property &Type: ElementType read ElementType.ThrowStatement; override;
  end;

  CatchBlock = public class(SourceElement)
  private
    fBody: Statement;
    fIdentifier: String;
  public
    constructor(aPositionPair: PositionPair; anIdentifier: String; aBody: Statement);
    property Identifier: String read fIdentifier;
    property Body: Statement read fBody;

    property &Type: ElementType read ElementType.CatchBlock; override;
  end;

  TryStatement  = public class(Statement)
  private
    fCatch: CatchBlock;
    fFinally: Statement;
    fBody: Statement;
  public
    constructor (aPositionPair: PositionPair; aBody: Statement; aFinally: Statement);
    constructor (aPositionPair: PositionPair; aBody: Statement; aCatch: CatchBlock; aFinally: Statement);
    constructor (aPositionPair: PositionPair; aBody: Statement; aCatch: CatchBlock);
    property Body: Statement read fBody;
    property &Finally: Statement read fFinally;
    property Catch: CatchBlock read fCatch;

    property FinallyData: RemObjects.Script.EcmaScript.FinallyInfo;

    property &Type: ElementType read ElementType.TryStatement; override;
  end;

  DebuggerStatement = public class(Statement)
  private
  public
    property &Type: ElementType read ElementType.DebuggerStatement; override;
  end;


  ExpressionStatement = public class(Statement)
  private
    fExpression: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; anExpression: ExpressionElement);
    property ExpressionElement: ExpressionElement read fExpression;
    property &Type: ElementType read ElementType.ExpressionStatement; override;
  end;

  ExpressionElement = public abstract class(SourceElement)
  private
  public
  end;

  BinaryOperator = public enum (    
  Equal,
    NotEqual,
    Assign,
    Less,
    Greater,
    LessOrEqual,
    GreaterOrEqual,
    Multiply,
    Divide,
    Modulus,
    &And,
    &Or,
    DoubleAnd,
    DoubleOr,
    &Xor,
    DoubleXor,
    BitwiseNot,
    Plus,
    Minus,
    ShiftLeft, // <<
    ShiftRightSigned, // >>
    ShiftRightUnsigned, // >>>
    StrictEqual, // ===
    StrictNotEqual, // !==
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
    &In,
    InstanceOf
    );
  BinaryExpression = public class(ExpressionElement)
  private
    fRightSide: ExpressionElement;
    fLeftSide: ExpressionElement;
    fOperator: BinaryOperator;
  public
    constructor(aPositionPair: PositionPair; aLeft, aRight: ExpressionElement; anOperator: BinaryOperator);
    property LeftSide: ExpressionElement read fLeftSide;
    property RightSide: ExpressionElement read fRightSide;
    property &Operator: BinaryOperator read fOperator;

    property &Type: ElementType read ElementType.BinaryExpression; override;
  end;

  CommaSeparatedExpression = public class(ExpressionElement)
  private
    fParameters: List<ExpressionElement>;
  public
    constructor(aPositionPair: PositionPair; params aParameters: Array of ExpressionElement);
    constructor(aPositionPair: PositionPair; aParameters: sequence of ExpressionElement);
    constructor(aPositionPair: PositionPair; aParameters: List<ExpressionElement>);

    property Parameters: List<ExpressionElement> read fParameters;

    property &Type: ElementType read ElementType.CommaSeparatedExpression; override;
  end;


  ConditionalExpression = public class(ExpressionElement)
  private
    fCondition,
    fTrue,
    fFalse: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; aCondition, aTrue, aFalse: ExpressionElement);
    property Condition: ExpressionElement read fCondition;
    property &True: ExpressionElement read fTrue;
    property &False: ExpressionElement read fFalse;

    property &Type: ElementType read ElementType.ConditionalExpression; override;
  end;

  FunctionExpression = public class(ExpressionElement)
  private
    fFunction: FunctionDeclarationElement;
  public
    constructor(aPositionPair: PositionPair; aFunction: FunctionDeclarationElement);
    
    property &Function: FunctionDeclarationElement read fFunction;
    
    property &Type: ElementType read ElementType.FunctionExpression; override;
  end;

  UnaryOperator = public enum (BoolNot, BinaryNot, Minus, Plus, TypeOf, Void, Delete, PreIncrement, PreDecrement, PostIncrement, PostDecrement);
  UnaryExpression = public class(ExpressionElement)
  private
    fOperator: UnaryOperator;
    fValue: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; aValue: ExpressionElement; anOperator: UnaryOperator);
    property Value: ExpressionElement read fValue;
    property &Operator: UnaryOperator read fOperator;

    property &Type: ElementType read ElementType.UnaryExpression; override;
  end;

  NewExpression = public class(CallExpression)
  private
  public
    property &Type: ElementType read ElementType.NewExpression; override;
  end;

  SubExpression = public class(ExpressionElement)
  private
    fIdentifier: String;
    fMember: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; aMember: ExpressionElement; anIdentifier: String);
    property Member: ExpressionElement read fMember;
    property Identifier: String read fIdentifier;

    property &Type: ElementType read ElementType.SubExpression; override;
  end;

  ArrayAccessExpression = public class(ExpressionElement)
  private
    fParameter: ExpressionElement;
    fMember: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; aMember: ExpressionElement; aParameter: ExpressionElement);
    property Member: ExpressionElement read fMember;
    property Parameter: ExpressionElement read fParameter;

    property &Type: ElementType read ElementType.ArrayAccessExpression; override;
  end;

  CallExpression = public class(ExpressionElement)
  private
    fParameters: List<ExpressionElement>;
    fMember: ExpressionElement;
  public
    constructor(aPositionPair: PositionPair; aMember: ExpressionElement; params aParameters: Array of ExpressionElement);
    constructor(aPositionPair: PositionPair; aMember: ExpressionElement; aParameters: sequence of ExpressionElement);
    constructor(aPositionPair: PositionPair; aMember: ExpressionElement; aParameters: List<ExpressionElement>);

    property Member: ExpressionElement read fMember;
    property Parameters: List<ExpressionElement> read fParameters;

    property &Type: ElementType read ElementType.CallExpression; override;
  end;

  ThisExpression = public class(ExpressionElement)
  private
  public
    property &Type: ElementType read ElementType.ThisExpression; override;
  end;

  PropertyBaseExpression = public abstract class(ExpressionElement)
  private
  public
    property ObjectValue: Object read; abstract;
  end;

  IdentifierExpression = public class(PropertyBaseExpression)
  private
    fIdentifier: String;
  public
    constructor (aPositionPair: PositionPair; anIdentifier: String);
    property Identifier: String read fIdentifier;
    property ObjectValue: Object read fIdentifier; override;
    property &Type: ElementType read ElementType.IdentifierExpression; override;
  end;

  ArrayLiteralExpression = public class(ExpressionElement)
  private
    fItems: List<ExpressionElement>;
  public
    constructor(aPositionPair: PositionPair; aItems: sequence of ExpressionElement);
    constructor(aPositionPair: PositionPair; params aItems: array of ExpressionElement);
    constructor(aPositionPair: PositionPair; aItems: List<ExpressionElement>);

    property Items: List<ExpressionElement> read fItems;
    property &Type: ElementType read ElementType.ArrayLiteralExpression; override;
  end;
  
  LiteralExpression = public abstract class(PropertyBaseExpression);
  NullExpression = public class(LiteralExpression)
  private
  public
    property &Type: ElementType read ElementType.NullExpression; override;
    property ObjectValue: Object read nil; override;
  end;

  BooleanExpression = public class(LiteralExpression)
  private
    fValue: Boolean;
  public
    constructor (aPositionPair: PositionPair; aValue: Boolean);
    property ObjectValue: Object read fValue; override;
    property Value: Boolean read fValue;
    property &Type: ElementType read ElementType.BooleanExpression; override;
  end;

  IntegerExpression = public class(LiteralExpression)
  private
    fValue: Int64;
  public
    constructor (aPositionPair: PositionPair; aValue: Int64);
    property ObjectValue: Object read fValue; override;
    property Value: Int64 read fValue;
    property &Type: ElementType read ElementType.IntegerExpression; override;
  end;

  RegExExpression = public class(ExpressionElement)
  private
    fString,
    fModifier: String;
  public
    constructor (aPositionPair: PositionPair; aString, aModifier:String);
    property String: String read fString;
    property Modifier: String read fModifier;
    property &Type: ElementType read ElementType.RegExExpression; override;
  end;

  DecimalExpression = public class(LiteralExpression)
  private
    fValue: Double;
  public
    constructor (aPositionPair: PositionPair; aValue: Double);
    property Value: Double read fValue;
    property ObjectValue: Object read fValue; override;
    property &Type: ElementType read ElementType.DecimalExpression; override;
  end;
  
  StringExpression = public class(LiteralExpression)
  private
    fValue: String;
  public
    constructor (aPositionPair: PositionPair; aValue: String);
    property Value: String read fValue;
    property ObjectValue: Object read fValue; override;
    property &Type: ElementType read ElementType.StringExpression; override;
  end;
  
  PropertyAssignment = public class(ExpressionElement)
  private
    fMode: FunctionDeclarationType;
    fValue: ExpressionElement;
    fName: PropertyBaseExpression;
  public
    constructor (aPositionPair: PositionPair; aMode: FunctionDeclarationType; aName: PropertyBaseExpression; aValue: ExpressionElement);
    property Name: PropertyBaseExpression read fName;
    property Value: ExpressionElement read fValue;

    property Mode: FunctionDeclarationType read fMode;
    property &Type: ElementType read ElementType.PropertyAssignment; override;
  end;

  ObjectLiteralExpression = public class(ExpressionElement, IList<PropertyAssignment>)
  private
    fItems: List<PropertyAssignment>;
  public
    constructor (aPositionPair: PositionPair; aItems: sequence of PropertyAssignment);
    constructor (aPositionPair: PositionPair; params aItems: array of PropertyAssignment);
    constructor (aPositionPair: PositionPair; aItems: List<PropertyAssignment>);
    property Items: List<PropertyAssignment> read fItems; implements IList<PropertyAssignment>;
    property &Type: ElementType read ElementType.ObjectLiteralExpression; override;
  end;


  ProgramElement = public class(LanguageElement, IList<SourceElement>)
  private
    fItems: List<SourceElement>;
  public
    constructor(aPositionPair: PositionPair);
    constructor(aPositionPair: PositionPair; aItem: SourceElement);
    constructor(aPositionPair: PositionPair; params aItems: Array of SourceElement);
    constructor(aPositionPair: PositionPair; aItems: sequence of SourceElement);
    constructor(aPositionPair: PositionPair; aItems: List<SourceElement>);

    property Items: List<SourceElement> read fItems; implements IList<SourceElement>;
    property &Type: ElementType read ElementType.Program; override;
  end;


implementation

constructor LanguageElement(aPositionPair: PositionPair);
begin
  fPositionPair := aPositionPair;
end;

constructor ProgramElement(aPositionPair: PositionPair);
begin
  inherited constructor(aPositionPair);
  fItems := new List<SourceElement>(array of SourceElement([]));
end;

constructor ProgramElement(aPositionPair: PositionPair; aItem: SourceElement);
begin
  inherited constructor(aPositionPair);
  fItems := new List<SourceElement>(array of SourceElement([aItem]));
end;

constructor ProgramElement(aPositionPair: PositionPair; params aItems: Array of SourceElement);
begin
  inherited constructor(aPositionPair);
  fItems := new List<SourceElement>(aItems);
end;

constructor ProgramElement(aPositionPair: PositionPair; aItems: sequence of SourceElement);
begin
  inherited constructor(aPositionPair);
  fItems := new List<SourceElement>(new List<SourceElement>(aItems));
end;

constructor ProgramElement(aPositionPair: PositionPair; aItems: List<SourceElement>);
begin
  inherited constructor(aPositionPair);
  fItems := aItems;
end;

constructor FunctionDeclarationElement(aPositionPair: PositionPair;  aMode: FunctionDeclarationType; anIdentifier: String; aParameters: Array of ParameterDeclaration; params aItems: Array of SourceElement);
begin
  inherited constructor(aPositionPair);
  fIdentifier := anIdentifier;
  fParameters := new List<ParameterDeclaration>(aParameters);
  fItems := new List<SourceElement>(aItems);
  fMode := aMode;
end;

constructor FunctionDeclarationElement(aPositionPair: PositionPair; aMode: FunctionDeclarationType;  anIdentifier: String; aParameters: sequence of ParameterDeclaration; aItems: sequence of SourceElement);
begin
  inherited constructor(aPositionPair);
  fIdentifier := anIdentifier;
  fParameters := new List<ParameterDeclaration>(new List<ParameterDeclaration>(aParameters));
  fItems := new List<SourceElement>(new List<SourceElement>(aItems));
  fMode := aMode;
end;

constructor FunctionDeclarationElement(aPositionPair: PositionPair; aMode: FunctionDeclarationType := FunctionDeclarationType.None; anIdentifier: String; aParameters: List<ParameterDeclaration>; aItems: List<SourceElement>);
begin
  inherited constructor(aPositionPair);
  fIdentifier := anIdentifier;
  fParameters := aParameters;
  fItems := aItems;
  fMode := aMode;
end;

constructor BlockStatement(aPositionPair: PositionPair; params aStatements: array of SourceElement);
begin
  inherited constructor(aPositionPair);
  fItems := new List<SourceElement>(aStatements);
end;

constructor BlockStatement(aPositionPair: PositionPair; aStatements: sequence of SourceElement);
begin
  inherited constructor(aPositionPair);
  fItems := new List<SourceElement>(aStatements);
end;

constructor BlockStatement(aPositionPair: PositionPair; aStatements: List<SourceElement>);
begin
  inherited constructor(aPositionPair);
  fItems := aStatements;
end;

constructor VariableStatement(aPositionPair: PositionPair; params aVariables: array of VariableDeclaration);
begin
  inherited constructor(aPositionPair);
  fVariables := new List<VariableDeclaration>(aVariables);
end;

constructor VariableStatement(aPositionPair: PositionPair; aVariables: sequence of VariableDeclaration);
begin
  inherited constructor(aPositionPair);
  fVariables := new List<VariableDeclaration>(new List<VariableDeclaration>(aVariables));
end;

constructor VariableStatement(aPositionPair: PositionPair; aVariables: List<VariableDeclaration>);
begin
  inherited constructor(aPositionPair);
  fVariables := aVariables;
end;

constructor VariableDeclaration(aPositionPair: PositionPair; aIdentifier: String; aInitializer: ExpressionElement := nil);
begin
  inherited constructor(aPositionPair);
  fIdentifier := aIdentifier;
  fInitializer := aInitializer;
end;

constructor IfStatement(aPositionPair: PositionPair; aExpression: ExpressionElement; aTrue: Statement; aFalse: Statement := nil);
begin
  inherited constructor(aPositionPair);
  fExpression := aExpression;
  fTrue := aTrue;
  fFalse := aFalse;
end;

constructor DoStatement(aPositionPair: PositionPair; aBody: Statement; anExpression: ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fExpression := anExpression;
end;

constructor WhileStatement(aPositionPair: PositionPair; anExpression: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fExpression := anExpression;
end;

constructor ForInStatement(aPositionPair: PositionPair; aLeftExpression, anExpression: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fExpression := anExpression;
  fLeftExpression := aLeftExpression;
end;

constructor ForInStatement(aPositionPair: PositionPair; anInitializer: VariableDeclaration; anExpression: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fExpression := anExpression;
  fInitializer := anInitializer;
end;

constructor ForStatement(aPositionPair: PositionPair; aInitializer: ExpressionElement; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fComparison := aComparison;
  fIncrement := aIncrement;
  fInitializer := aInitializer;
end;

constructor ForStatement(aPositionPair: PositionPair; aInitializers: array of VariableDeclaration; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fComparison := aComparison;
  fIncrement := aIncrement;
  fInitializers := new List<VariableDeclaration>(aInitializers);
end;

constructor ForStatement(aPositionPair: PositionPair; aInitializers: sequence of VariableDeclaration; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fComparison := aComparison;
  fIncrement := aIncrement;
  fInitializers := new List<VariableDeclaration>(new List<VariableDeclaration>(aInitializers));
end;

constructor ForStatement(aPositionPair: PositionPair; aInitializers: List<VariableDeclaration>; aComparison: ExpressionElement; aIncrement: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fComparison := aComparison;
  fIncrement := aIncrement;
  fInitializers := aInitializers;
end;

constructor ContinueStatement(aPositionPair: PositionPair; aIdentifier: String := nil);
begin
  inherited constructor(aPositionPair);
  fIdentifier := aIdentifier;
end;

constructor BreakStatement(aPositionPair: PositionPair; aIdentifier: String := nil);
begin
  inherited constructor(aPositionPair);
  fIdentifier := aIdentifier;
end;

constructor ReturnStatement(aPositionPair: PositionPair; aExpression: ExpressionElement := nil);
begin
  inherited constructor(aPositionPair);
  fExpression := aExpression;
end;

constructor WithStatement(aPositionPair: PositionPair; aExpression: ExpressionElement; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fExpression := aExpression;
  fBody := aBody;
end;

constructor LabelledStatement(aPositionPair: PositionPair; anIdentifier: String; aStatement: Statement);
begin
  inherited constructor(aPositionPair);
  fIdentifier := anIdentifier;
  fStatement := aStatement;
end;

constructor CaseClause(aPositionPair: PositionPair; anExpression: ExpressionElement := nil; params aBody: Array of Statement);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
  fBody := new List<Statement>(aBody);
end;

constructor CaseClause(aPositionPair: PositionPair; anExpression: ExpressionElement := nil; aBody: sequence of Statement);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
  fBody := new List<Statement>(new List<Statement>(aBody));
end;

constructor CaseClause(aPositionPair: PositionPair; anExpression: ExpressionElement := nil; aBody: List<Statement>);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
  fBody := aBody;
end;

constructor SwitchStatement(aPositionPair: PositionPair; anExpression: ExpressionElement; params aClauses: Array of CaseClause);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
  fClauses := new List<CaseClause>(aClauses);
end;

constructor SwitchStatement(aPositionPair: PositionPair; anExpression: ExpressionElement; aClauses: sequence of CaseClause);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
  fClauses := new List<CaseClause>(new List<CaseClause>(aClauses));
end;

constructor SwitchStatement(aPositionPair: PositionPair; anExpression: ExpressionElement; aClauses: List<CaseClause>);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
  fClauses := aClauses;
end;

constructor ThrowStatement(aPositionPair: PositionPair; anExpression: ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
end;

constructor CatchBlock(aPositionPair: PositionPair; anIdentifier: String; aBody: Statement);
begin
  inherited constructor(aPositionPair);
  fIdentifier := anIdentifier;
  fBody := aBody;
end;

constructor TryStatement(aPositionPair: PositionPair; aBody: Statement; aFinally: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fFinally := aFinally;
end;

constructor TryStatement(aPositionPair: PositionPair; aBody: Statement; aCatch: CatchBlock; aFinally: Statement);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fFinally := aFinally;
  fCatch := aCatch;
end;

constructor TryStatement(aPositionPair: PositionPair; aBody: Statement; aCatch: CatchBlock);
begin
  inherited constructor(aPositionPair);
  fBody := aBody;
  fCatch := aCatch;
end;

constructor ExpressionStatement(aPositionPair: PositionPair; anExpression: ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fExpression := anExpression;
end;


constructor BinaryExpression(aPositionPair: PositionPair; aLeft, aRight: ExpressionElement; anOperator: BinaryOperator);
begin
  inherited constructor(aPositionPair);
  fLeftSide := aLeft;
  fRightSide := aRight;
  fOperator := anOperator;
end;

constructor ConditionalExpression(aPositionPair: PositionPair; aCondition, aTrue, aFalse: ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fCondition := aCondition;
  fTrue := aTrue;
  fFalse := aFalse;
end;

constructor UnaryExpression(aPositionPair: PositionPair; aValue: ExpressionElement; anOperator: UnaryOperator);
begin
  inherited constructor(aPositionPair);
  fValue := aValue;
  fOperator := anOperator;
end;

constructor SubExpression(aPositionPair: PositionPair; aMember: ExpressionElement; anIdentifier: String);
begin
  inherited constructor(aPositionPair);
  fMember := aMember;
  fIdentifier := anIdentifier;  
end;

constructor ArrayAccessExpression(aPositionPair: PositionPair; aMember: ExpressionElement; aParameter: ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fMember := aMember;
  fParameter := aParameter;
end;

constructor CallExpression(aPositionPair: PositionPair; aMember: ExpressionElement; params aParameters: Array of ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fMember := aMember;
  fParameters := new List<ExpressionElement>(aParameters);
end;

constructor CallExpression(aPositionPair: PositionPair; aMember: ExpressionElement; aParameters: sequence of ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fMember := aMember;
  fParameters := new List<ExpressionElement>(new List<ExpressionElement>(aParameters));
end;

constructor CallExpression(aPositionPair: PositionPair; aMember: ExpressionElement; aParameters: List<ExpressionElement>);
begin
  inherited constructor(aPositionPair);
  fMember := aMember;
  fParameters := aParameters;
end;

constructor IdentifierExpression(aPositionPair: PositionPair; anIdentifier: String);
begin
  inherited constructor(aPositionPair);
  fIdentifier := anIdentifier;
end;

constructor ArrayLiteralExpression(aPositionPair: PositionPair; aItems: sequence of ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fItems := new List<ExpressionElement>(new List<ExpressionElement>(aItems));
end;

constructor ArrayLiteralExpression(aPositionPair: PositionPair; params aItems: array of ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fItems := new List<ExpressionElement>(aItems);
end;

constructor ArrayLiteralExpression(aPositionPair: PositionPair; aItems: List<ExpressionElement>);
begin
  inherited constructor(aPositionPair);
  fItems := aItems;
end;

constructor BooleanExpression(aPositionPair: PositionPair; aValue: Boolean);
begin
  inherited constructor(aPositionPair);
  fValue := aValue;
end;

constructor IntegerExpression(aPositionPair: PositionPair; aValue: Int64);
begin
  inherited constructor(aPositionPair);
  fValue := aValue;
end;

constructor DecimalExpression(aPositionPair: PositionPair; aValue: Double);
begin
  inherited constructor(aPositionPair);
  fValue := aValue;
end;

constructor StringExpression(aPositionPair: PositionPair; aValue: String);
begin
  inherited constructor(aPositionPair);
  fValue := aValue;
end;

constructor ParameterDeclaration(aPositionPair: PositionPair; aName: String);
begin
  inherited constructor(aPositionPair);
  fName := aName;
end;

constructor FunctionExpression(aPositionPair: PositionPair; aFunction: FunctionDeclarationElement);
begin
  inherited constructor(aPositionPair);
  fFunction := aFunction;
end;

constructor PropertyAssignment(aPositionPair: PositionPair; aMode: FunctionDeclarationType; aName: PropertyBaseExpression; aValue: ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fName := aName;
  fMode := aMode;
  fValue := aValue;
end;

constructor ObjectLiteralExpression(aPositionPair: PositionPair; aItems: sequence of PropertyAssignment);
begin
  inherited constructor(aPositionPair);
  fItems := new List<PropertyAssignment>(new List<PropertyAssignment>(aItems));
end;

constructor ObjectLiteralExpression(aPositionPair: PositionPair; params aItems: array of PropertyAssignment);
begin
  inherited constructor(aPositionPair);
  fItems := new List<PropertyAssignment>(aItems);
end;

constructor ObjectLiteralExpression(aPositionPair: PositionPair; aItems: List<PropertyAssignment>);
begin
  inherited constructor(aPositionPair);
  fItems := aItems;
end;

constructor RegExExpression(aPositionPair: PositionPair; aString, aModifier:String);
begin
  inherited constructor(aPositionPair);
  fString := aString;
  fModifier := aModifier;
end;

constructor CommaSeparatedExpression(aPositionPair: PositionPair; params aParameters: Array of ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fParameters := new List<ExpressionElement>(aParameters);
end;

constructor CommaSeparatedExpression(aPositionPair: PositionPair; aParameters: sequence of ExpressionElement);
begin
  inherited constructor(aPositionPair);
  fParameters := new List<ExpressionElement>(new List<ExpressionElement>(aParameters));
end;

constructor CommaSeparatedExpression(aPositionPair: PositionPair; aParameters: List<ExpressionElement>);
begin
  inherited constructor(aPositionPair);
  fParameters := aParameters;
end;

end.