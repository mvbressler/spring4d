unit TestAdaptersASA;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit 
  being tested.

}

interface

uses
  TestFramework, Spring.Persistence.Adapters.ASA, SysUtils
  , Spring.Persistence.Adapters.ADO, ADODB, Spring.Persistence.Core.Interfaces, uModels
  ,Generics.Collections, Spring.Persistence.Core.Session, Spring.Persistence.SQL.Generators.ASA;

type
  // Test methods for class TASAConnectionAdapter

  TestTASAConnectionAdapter = class(TTestCase)
  strict private
    FASAConnectionAdapter: TASAConnectionAdapter;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGetDriverName;
  end;
  // Test methods for class TASASQLGenerator

  TestTASASQLGenerator = class(TTestCase)
  strict private
    FASASQLGenerator: TASASQLGenerator;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGenerateGetLastInsertId;
  end;

  TestASAAdapter = class(TTestCase)
  private
    FConnection: IDBConnection;
    FManager: TSession;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestFirst();
    procedure TestSave();
  end;

implementation

uses
  Spring.Persistence.Core.ConnectionFactory
  ,Spring.Persistence.Core.DatabaseManager
  ,SvDesignPatterns
  ,TestADOAdapter
  ;

var
  TestDB: TADOConnection = nil;

const
  SQL_SELECT_ALL = 'SELECT * FROM VIKARINA.IMONES;';

function GetSQLCount(const ACountSQL: string): Integer;
var
  LTable: _Recordset;
begin
  LTable := TestDB.Execute(ACountSQL);
  Result := LTable.Fields[0].Value;
end;

function GetSQLFirstFieldValue(const ASQL: string): Variant;
var
  LTable: _Recordset;
begin
  LTable := TestDB.Execute(ASQL);
  Result := LTable.Fields[0].Value;
end;

procedure TestTASAConnectionAdapter.SetUp;
begin
  FASAConnectionAdapter := TASAConnectionAdapter.Create(TestDB);
end;

procedure TestTASAConnectionAdapter.TearDown;
begin
  FASAConnectionAdapter.Free;
  FASAConnectionAdapter := nil;
end;

procedure TestTASAConnectionAdapter.TestGetDriverName;
var
  ReturnValue: string;
begin
  ReturnValue := FASAConnectionAdapter.GetDriverName;
  CheckEqualsString('ASA', ReturnValue);
end;

procedure TestTASASQLGenerator.SetUp;
begin
  FASASQLGenerator := TASASQLGenerator.Create();
end;

procedure TestTASASQLGenerator.TearDown;
begin
  FASASQLGenerator.Free;
  FASASQLGenerator := nil;
end;

procedure TestTASASQLGenerator.TestGenerateGetLastInsertId;
var
  ReturnValue: string;
begin
  ReturnValue := FASASQLGenerator.GenerateGetLastInsertId(nil);
  CheckEqualsString('SELECT @@IDENTITY;', ReturnValue);
end;



var
  ODBC: IODBC;
  ODBCSources: TArray<string>;
  fIndex: Integer;


{ TestASAAdapter }

procedure TestASAAdapter.SetUp;
begin
  inherited;
  FConnection := TConnectionFactory.GetInstance(dtASA, TestDB);
  FManager := TSession.Create(FConnection);
end;

procedure TestASAAdapter.TearDown;
begin
  FManager.Free;
  inherited;
end;

procedure TestASAAdapter.TestFirst;
var
  LCompany: TCompany;
begin
  LCompany := FManager.FirstOrDefault<TCompany>(SQL_SELECT_ALL, []);
  try
    CheckTrue(Assigned(LCompany));
    CheckEquals(1, LCompany.ID);
  finally
    LCompany.Free;
  end;
end;

procedure TestASAAdapter.TestSave;
var
  LCompany: TCompany;
  LTran: IDBTransaction;
  iCount: Integer;
begin
  LCompany := TCompany.Create;
  try
    iCount := GetSQLCount('select count(*) from vikarina.imones;');
    LCompany.Name := 'ORM';
    LCompany.Address := 'ORM street';
    LCompany.Telephone := '+37068569854';
    LCompany.ID := 7;

    LTran := FManager.Connection.BeginTransaction;

    FManager.Save(LCompany);

    CheckEquals(iCount + 1, GetSQLCount('select count(*) from vikarina.imones;'));

    LCompany.Name := 'ORM Name changed';
    FManager.Save(LCompany);
    CheckEquals(iCount + 1, GetSQLCount('select count(*) from vikarina.imones;'));
    CheckEqualsString(LCompany.Name,string(GetSQLFirstFieldValue('select IMPAV from vikarina.imones where imone = 7;')));

  finally
    LCompany.Free;
  end;
end;

initialization
  ODBC := TBaseODBC.Create;
  ODBCSources := ODBC.GetDatasources();
  TArray.Sort<string>(ODBCSources);
  if not TArray.BinarySearch<string>(ODBCSources, 'demo_syb', fIndex) then
  begin
    fIndex := -1;
    Exit;
  end;


 { TestDB := TADOConnection.Create(nil);
  TestDB.LoginPrompt := False;
  //
  TestDB.ConnectionString := 'Provider=MSDASQL;Data Source=demo_syb;Password=master;Persist Security Info=True;User ID=VIKARINA';
  try
    TestDB.Open();
    if TestDB.Connected then
    begin
      RegisterTest(TestTASAConnectionAdapter.Suite);
      RegisterTest(TestTASASQLGenerator.Suite);
      RegisterTest(TestASAAdapter.Suite);
    end;
  except
    //raise;
  end;     }

finalization
 { if fIndex <> -1 then
  begin
    TestDB.Free;
  end; }

  ODBC := nil;


end.

