{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2016 Spring4D Team                           }
{                                                                           }
{           http://www.spring4d.org                                         }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

{$I Spring.inc}

unit Spring.Testing;

interface

uses
  TestFramework,
  Classes,
  Rtti,
  Spring;

const
  DefaultDelimiters = ';';

type
  TValue = Rtti.TValue;

  TTestingAttribute = class(TCustomAttribute)
  private
    function GetValue(index: Integer): TValue;
  protected
    fValues: TArray<TValue>;
    constructor Create(const values: string; const delimiters: string = DefaultDelimiters);
    property Values[index: Integer]: TValue read GetValue;
  end;

  /// <summary>
  ///   This attribute is one way of marking a method inside a TTestCase class
  ///   as a test.
  /// </summary>
  TestAttribute = class(TCustomAttribute);

  /// <summary>
  ///   This attributes serves the dual purpose of marking a method with
  ///   parameters as a test method and providing inline data to be used when
  ///   invoking that method.
  /// </summary>
  TestCaseAttribute = class(TTestingAttribute)
  public
    constructor Create(const values: string; const delimiters: string = DefaultDelimiters);
  end;

  TestCaseSourceAttribute = class(TBaseAttribute)
  private
    fSourceType: TClass;
    fSourceName: string;
  public
    constructor Create(sourceType: TClass; const sourceName: string); overload;
    constructor Create(const sourceName: string); overload;
    property SourceType: TClass read fSourceType;
    property SourceName: string read fSourceName;
  end;

  /// <summary>
  ///   This attribute is used to specify a set of values to be provided for an
  ///   individual parameter of a parameterized test method.
  /// </summary>
  ValuesAttribute = class(TTestingAttribute)
  public
    constructor Create; overload;
    constructor Create(const values: string; const delimiters: string = DefaultDelimiters); overload;
  end;

  /// <summary>
  ///   This attribute is used to specify a range of values to be provided for
  ///   an individual parameter of a parameterized test method.
  /// </summary>
  RangeAttribute = class(TTestingAttribute)
  public
    constructor Create(const low, high: Integer; const step: Integer = 1); overload;
    constructor Create(const low, high: Extended; const step: Extended = 1); overload;
  end;

  /// <summary>
  ///   This attribute is used on a test to specify that test cases should be
  ///   generated by selecting individual data items provided for the
  ///   parameters of the test, without generating additional combinations.
  /// </summary>
  SequentialAttribute = class(TestAttribute);

  /// <summary>
  ///   This is the way to specify that the execution of a test will raise an
  ///   exception.
  /// </summary>
  ExpectedExceptionAttribute = class(TestAttribute)
  private
    fExceptionType: ExceptionClass;
    fUserMessage: string;
  public
    constructor Create(exceptionType: ExceptionClass;
      const userMessage: string = '');
  end;

  TTestCase = class(TestFramework.TTestCase)
  private
    fMethod: TRttiMethod;
    fArgs: TArray<TValue>;
    fExpectedException: ExceptionClass;
    fUserMessage: string;
    fName: string;
  protected
    procedure Invoke(AMethod: TTestMethod); override;

    class procedure SetUpFixture; virtual;
    class procedure TearDownFixture; virtual;
  public
    constructor Create(const method: TRttiMethod; const args: TArray<TValue>); reintroduce;
    function GetName: string; override;

    property Name: string read fName write fName;
    class function Suite: ITestSuite; override;

    class procedure Register; overload;
    class procedure Register(const suitePath: string); overload;
  end;
  TTestCaseClass = class of TTestCase;

  TTestSuite = class(TestFramework.TTestSuite)
  private
    fTestClass: TTestCaseClass;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  public
    constructor Create(testClass: TTestCaseClass); overload;
    procedure AddTests(testClass: TTestCaseClass); reintroduce;
  end;

  TTestCaseData = record
  private
    fValues: TArray<TValue>;
    fExceptionType: ExceptionClass;
    fUserMessage: string;
    fName: string;
  public
    constructor Create(const values: array of TValue);
    function Raises(exceptionType: ExceptionClass;
      const userMessage: string = ''): TTestCaseData;
    function Returns(const value: TValue): TTestCaseData;
    function SetName(const name: string): TTestCaseData;
  end;

implementation

uses
  StrUtils,
  SysUtils,
  TypInfo,
  Spring.Reflection;

type
  TRttiMethodHelper = class helper for TRttiMethod
    procedure ConvertValues(const values: TArray<TValue>;
      const arguments: TArray<TValue>);
  end;

{$REGION 'TRttiMethodHelper'}

procedure TRttiMethodHelper.ConvertValues(const values: TArray<TValue>;
  const arguments: TArray<TValue>);
var
  parameters: TArray<TRttiParameter>;
  i: Integer;
  value: TValue;
  retType: TRttiType;
begin
  parameters := GetParameters;
  for i := 0 to High(parameters) do
  begin
    if i < Length(values) then
      value := values[i]
    else
      value := TValue.Empty;
    value.TryConvert(parameters[i].ParamType.Handle, arguments[i]);
  end;
  retType := ReturnType;
  if retType <> nil then
  begin
    i := Length(parameters);
    if i < Length(values) then
      value := values[i]
    else
      value := TValue.Empty;
    value.TryConvert(retType.Handle, arguments[i]);
  end;
end;

{$ENDREGION}


function IsTestMethod(const method: TRttiMethod;
  const parameters: TArray<TRttiParameter>): Boolean;
var
  parameter: TRttiParameter;
begin
  if method.HasCustomAttribute<TestAttribute> then
    Exit(True)
  else
    for parameter in parameters do
      if parameter.HasCustomAttribute<TTestingAttribute> then
        Exit(True);
  Result := False;
end;


{$REGION 'TTestingAttribute'}

constructor TTestingAttribute.Create(const values, delimiters: string);
var
  tempValues: TStringDynArray;
  i: Integer;
begin
  inherited Create;
  tempValues := SplitString(values, delimiters);
  SetLength(fValues, Length(tempValues));
  for i := 0 to High(tempValues) do
    fValues[i] := tempValues[i];
end;

function TTestingAttribute.GetValue(index: Integer): TValue;
begin
  if index < Length(fValues) then
    Result := fValues[index]
  else
    Result := TValue.Empty;
end;

{$ENDREGION}


{$REGION 'TestCaseAttribute'}

constructor TestCaseAttribute.Create(const values, delimiters: string);
begin
  inherited Create(values, delimiters);
end;

{$ENDREGION}


{$REGION 'TestCaseSourceAttribute'}

constructor TestCaseSourceAttribute.Create(sourceType: TClass;
  const sourceName: string);
begin
  inherited Create;
  fSourceType := sourceType;
  fSourceName := sourceName;
end;

constructor TestCaseSourceAttribute.Create(const sourceName: string);
begin
  inherited Create;
  fSourceName := sourceName;
end;

{$ENDREGION}


{$REGION 'ValuesAttribute'}

constructor ValuesAttribute.Create;
begin
  inherited Create('');
end;

constructor ValuesAttribute.Create(const values, delimiters: string);
begin
  inherited Create(values, delimiters);
end;

{$ENDREGION}


{$REGION 'RangeAttribute'}

constructor RangeAttribute.Create(const low, high, step: Integer);
var
  i: Integer;
begin
  SetLength(fValues, (high - low) div step + 1);
  for i := 0 to System.High(fValues) do
    fValues[i] := low + i * step;
end;

constructor RangeAttribute.Create(const low, high, step: Extended);
var
  i: Integer;
begin
  SetLength(fValues, Trunc((high - low) / step + 1));
  for i := 0 to System.High(fValues) do
    fValues[i] := low + i * step;
end;

{$ENDREGION}


{$REGION 'ExpectedExceptionAttribute'}

constructor ExpectedExceptionAttribute.Create(exceptionType: ExceptionClass;
  const userMessage: string);
begin
  Guard.CheckNotNull(exceptionType, 'exceptionType');
  inherited Create;
  fExceptionType := exceptionType;
  fUserMessage := userMessage;
end;

{$ENDREGION}


{$REGION 'TTestCase'}

constructor TTestCase.Create(const method: TRttiMethod; const args: TArray<TValue>);
var
  attribute: ExpectedExceptionAttribute;
begin
  inherited Create(method.Name);
  fMethod := method;
  if fMethod.TryGetCustomAttribute<ExpectedExceptionAttribute>(attribute) then
  begin
    fExpectedException := attribute.fExceptionType;
    fUserMessage := attribute.fUserMessage;
  end;
  fArgs := Copy(args);
end;

function TTestCase.GetName: string;

  function FormatValue(const value: TValue): string;

    function FormatArray(const value: TValue): string;
    var
      i: Integer;
    begin
      Result := '[';
      for i := 0 to value.GetArrayLength - 1 do
      begin
        if i > 0 then
          Result := Result + ', ';
        Result := Result + FormatValue(value.GetArrayElement(i));
      end;
      Result := Result + ']';
    end;

    function StripUnitName(const s: string): string;
    begin
      Result := ReplaceText(s, 'System.', '');
    end;

  var
    LInterface: IInterface;
    LObject: TObject;
  begin
    case value.Kind of
      tkFloat:
        if value.TypeInfo = TypeInfo(TDateTime) then
          Result := DateTimeToStr(value.AsType<TDateTime>)
        else if value.TypeInfo = TypeInfo(TDate) then
          Result := DateToStr(value.AsType<TDate>)
        else if value.TypeInfo = TypeInfo(TTime) then
          Result := TimeToStr(value.AsType<TTime>)
        else
          Result := value.ToString;
      tkClass:
      begin
        LObject := value.AsObject;
        Result := Format('%s($%x)', [StripUnitName(LObject.ClassName),
          NativeInt(LObject)]);
      end;
      tkInterface:
      begin
        LInterface := value.AsInterface;
        LObject := LInterface as TObject;
        Result := Format('%s($%x) as %s', [StripUnitName(LObject.ClassName),
          NativeInt(LInterface), StripUnitName(value.TypeInfo.TypeName)]);
      end;
      tkArray, tkDynArray:
        Result := FormatArray(Self);
      tkChar, tkString, tkWChar, tkLString, tkWString, tkUString:
        Result := QuotedStr(value.ToString);
    else
      Result := value.ToString;
    end;
  end;

  function FormatArgs(const values: TArray<TValue>): string;
  var
    i: Integer;
  begin
    if values = nil then
      Exit('');
    Result := '(';
    for i := 0 to Length(values) - 1 do
    begin
      if i > 0 then
        Result := Result + ', ';
      Result := Result + FormatValue(values[i]);
    end;
    Result := Result + ')';
  end;

begin
  if fName <> '' then
    Exit(fName);

  if Assigned(fMethod) then
  begin
    Result := fMethod.Name;
    if fArgs = nil then
      Exit;
    if fMethod.ReturnType = nil then
      Result := Result + FormatArgs(fArgs)
    else
      Result := Result + FormatArgs(Copy(fArgs, 0, High(fArgs))) + ' = ' +
        FormatValue(fArgs[High(fArgs)]);
  end
  else
    Result := inherited GetName;
end;

procedure TTestCase.Invoke(AMethod: TTestMethod);
var
  expected, actual: TValue;
begin
  FTestMethodInvoked := True;
  if Assigned(fExpectedException) then
    StartExpectingException(fExpectedException);
  if Assigned(fMethod) then
  begin
    if fMethod.ReturnType = nil then
      fMethod.Invoke(Self, fArgs)
    else
    begin
      expected := fArgs[High(fArgs)];
      actual := fMethod.Invoke(Self, Copy(fArgs, 0, High(fArgs)));
      FCheckCalled := True;
      if not expected.Equals(actual) then
        FailNotEquals(expected.ToString, actual.ToString, '', ReturnAddress);
    end;
  end
  else
    AMethod;
  if Assigned(fExpectedException) then
    StopExpectingException(fUserMessage);
end;

class procedure TTestCase.Register;
begin
  TestFramework.RegisterTest(Suite);
end;

class procedure TTestCase.Register(const suitePath: string);
begin
  TestFramework.RegisterTest(suitePath, Suite);
end;

class procedure TTestCase.SetUpFixture;
begin
  // do nothing
end;

class function TTestCase.Suite: ITestSuite;
begin
  Result := TTestSuite.Create(Self);
end;

class procedure TTestCase.TearDownFixture;
begin
  // do nothing
end;

{$ENDREGION}


{$REGION 'TTestSuite'}

constructor TTestSuite.Create(testClass: TTestCaseClass);
begin
  inherited Create(testClass.ClassName);
  fTestClass := testClass;
  AddTests(testClass);
end;

procedure TTestSuite.SetUp;
begin
  inherited SetUp;
  if Assigned(fTestClass) then
    fTestClass.SetUpFixture;
end;

procedure TTestSuite.TearDown;
begin
  if Assigned(fTestClass) then
    fTestClass.TearDownFixture;
  inherited TearDown;
end;

procedure TTestSuite.AddTests(testClass: TTestCaseClass);

  procedure InternalInvoke(const suite: ITestSuite; const method: TRttiMethod;
    const parameters: TArray<TRttiParameter>; const arguments: TArray<TValue>;
    argIndex: Integer = 0; paramIndex: Integer = 0);
  var
    attribute: TTestingAttribute;
    i: Integer;
    enumType: TRttiEnumerationType;
  begin
    for attribute in parameters[paramIndex].GetCustomAttributes<TTestingAttribute> do
    begin
      if attribute.fValues = nil then
        if parameters[paramIndex].ParamType.TypeKind = tkEnumeration then
        begin
          enumType := TRttiEnumerationType(parameters[paramIndex].ParamType);
          SetLength(attribute.fValues, enumType.MaxValue - enumType.MinValue + 1);
          for i := enumType.MinValue to enumType.MaxValue do
            TValue.Make(i, enumType.Handle, attribute.fValues[i])
        end;
      if (paramIndex = 0) or not method.HasCustomAttribute<SequentialAttribute> then
        for i := 0 to High(attribute.fValues) do
        begin
          attribute.Values[i].TryConvert(
            parameters[paramIndex].ParamType.Handle, arguments[paramIndex]);
          if paramIndex = Length(parameters) - 1 then
            suite.AddTest(testClass.Create(method, arguments) as ITest)
          else
            InternalInvoke(suite, method, parameters, arguments, i, paramIndex + 1);
        end
      else
      begin
        attribute.Values[argIndex].TryConvert(
          parameters[paramIndex].ParamType.Handle, arguments[paramIndex]);
        if paramIndex = Length(parameters) - 1 then
          suite.AddTest(testClass.Create(method, arguments) as ITest)
        else
          InternalInvoke(suite, method, parameters, arguments, argIndex, paramIndex + 1);
      end;
    end;
  end;

  procedure HandleSourceAttribute(const suite: ITestSuite;
    const method: TRttiMethod; const parameters: TArray<TRttiParameter>;
    const arguments: TArray<TValue>);
  var
    sourceAttribute: TestCaseSourceAttribute;
    sourceMethod: TRttiMethod;
    values: TValue;
    data: TTestCaseData;
    testCase: TTestCase;
  begin
    for sourceAttribute in method.GetCustomAttributes<TestCaseSourceAttribute> do
    begin
      if sourceAttribute.SourceType <> nil then
        sourceMethod := TType.GetType(sourceAttribute.SourceType).GetMethod(sourceAttribute.SourceName)
      else
        sourceMethod := TType.GetType(testClass).GetMethod(sourceAttribute.SourceName);
      if Assigned(sourceMethod) and sourceMethod.IsStatic then
      begin
        for values in sourceMethod.Invoke(testClass, []).GetArray do
        begin
          if values.TryAsType<TTestCaseData>(data) then
          begin
            method.ConvertValues(data.fValues, arguments);
            testCase := testClass.Create(method, arguments);
            if data.fExceptionType <> nil then
            begin
              testCase.fExpectedException := data.fExceptionType;
              testCase.fUserMessage := data.fUserMessage;
            end;
            if data.fName <> '' then
              testCase.Name := data.fName;
            suite.AddTest(testCase as ITest);
            Continue;
          end;

          if Length(parameters) > 1 then
          begin
            method.ConvertValues(values.GetArray, arguments);
            suite.AddTest(testClass.Create(method, arguments) as ITest);
          end
          else
            if values.TryConvert(parameters[0].ParamType.Handle, arguments[0]) then
              suite.AddTest(testClass.Create(method, arguments) as ITest);
        end;
      end;
    end;
  end;

var
  method: TRttiMethod;
  parameters: TArray<TRttiParameter>;
  arguments: TArray<TValue>;
  suite: ITestSuite;
  attribute: TestCaseAttribute;
begin
  for method in TType.GetType(testClass).GetMethods do
  begin
    if not method.IsPublished or method.IsStatic then
      Continue;

    parameters := method.GetParameters;
    if method.ReturnType = nil then
      SetLength(arguments, Length(parameters))
    else
      SetLength(arguments, Length(parameters) + 1);

    suite := TTestSuite.Create(method.Name);
    AddTest(suite);

    for attribute in method.GetCustomAttributes<TestCaseAttribute> do
    begin
      method.ConvertValues(attribute.fValues, arguments);
      suite.AddTest(testClass.Create(method, arguments) as ITest);
    end;

    HandleSourceAttribute(suite, method, parameters, arguments);

    if Length(parameters) = 0 then
      suite.AddTest(testClass.Create(method, nil) as ITest)
    else if IsTestMethod(method, parameters) then
      InternalInvoke(suite, method, parameters, arguments);
  end;
end;

{$ENDREGION}


{$REGION 'TTestCaseData'}

constructor TTestCaseData.Create(const values: array of TValue);
begin
  fValues := TArray.Copy<TValue>(values);
end;

function TTestCaseData.Raises(exceptionType: ExceptionClass;
  const userMessage: string): TTestCaseData;
begin
  fExceptionType := exceptionType;
  fUserMessage := userMessage;
  Result := Self;
end;

function TTestCaseData.Returns(const value: TValue): TTestCaseData;
var
  i: Integer;
begin
  i := Length(fValues);
  SetLength(fValues, i + 1);
  fValues[i] := value;
  Result := Self;
end;

function TTestCaseData.SetName(const name: string): TTestCaseData;
begin
  fName := name;
  Result := Self;
end;

{$ENDREGION}


end.
