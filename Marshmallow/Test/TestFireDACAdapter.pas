unit TestFireDACAdapter;

interface

uses
  TestFramework, Spring.Persistence.Adapters.FireDAC, Spring.Persistence.Core.Base, SysUtils,
  Spring.Persistence.SQL.Params, Spring.Persistence.Core.Interfaces
  , Spring.Persistence.SQL.Generators.Ansi, Spring.Persistence.Core.Session
  ,uModels, Classes, FireDAC.Comp.Client, Spring.Persistence.Mapping.Attributes;

type
  [Table('CUSTOMERS')]
  TFDCustomer = class
  private
    FId: Integer;
    FAge: Integer;
    FName: string;
    FHeight: Double;
  public
    [Column('ID', [cpPrimaryKey])] [AutoGenerated] property Id: Integer read FId write FId;
    [Column] property Age: Integer read FAge write FAge;
    [Column] property Name: string read FName write FName;
    [Column] property Height: Double read FHeight write FHeight;
  end;

  TestFireDACSession = class(TTestCase)
  private
    FConnection: IDBConnection;
    FSession: TSession;
    FDACConnection: TFDConnection;
  protected
    procedure CreateTables();
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Save();

  end;

implementation

uses
  Spring.Persistence.Core.ConnectionFactory
  ,FireDAC.Phys.SQLite
  ,Spring.Persistence.SQL.Interfaces
  ;

{ TestFireDACSession }

procedure TestFireDACSession.CreateTables;
begin
  FDACConnection.ExecSQL('CREATE TABLE IF NOT EXISTS CUSTOMERS ([ID] INTEGER PRIMARY KEY, [AGE] INTEGER NULL,'+
    '[NAME] VARCHAR (255), [HEIGHT] FLOAT, [PICTURE] BLOB); ');
end;

procedure TestFireDACSession.Save;
var
  LCustomer: TFDCustomer;
begin
  LCustomer := TFDCustomer.Create;
  LCustomer.Age := 25;
  LCustomer.Name := 'Foo';

  FSession.Save(LCustomer);

  CheckEquals('Foo', FSession.FindAll<TFDCustomer>.First.Name);
  LCustomer.Free;
end;

procedure TestFireDACSession.SetUp;
begin
  inherited;
  FDACConnection := TFDConnection.Create(nil);
  FDACConnection.DriverName := 'SQLite';
  FConnection := TConnectionFactory.GetInstance(dtFireDAC, FDACConnection);
  FConnection.SetQueryLanguage(qlSQLite);
  FSession := TSession.Create(FConnection);
  CreateTables;
end;

procedure TestFireDACSession.TearDown;
begin
  inherited;
  FDACConnection.Free;
  FSession.Free;
end;

initialization
  RegisterTest(TestFireDACSession.Suite);

end.
