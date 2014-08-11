(*
* Copyright (c) 2012, Linas Naginionis
* Contacts: lnaginionis@gmail.com or support@soundvibe.net
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the <organization> nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)
unit Core.DatabaseManager;

interface

uses
  Core.AbstractManager, Core.Interfaces, SysUtils, Spring.Collections;

type
  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Responsible for building database structure from annotated entities.
  ///	</summary>
  {$ENDREGION}
  TDatabaseManager = class(TAbstractManager)
  private
    FEntities: IList<TClass>;
  protected
    procedure BuildTables(AEntities: IList<TClass>); virtual;
    procedure BuildForeignKeys(AEntities: IList<TClass>); virtual;
    procedure BuildSequences(AEntities: IList<TClass>); virtual;
  public
    constructor Create(AConnection: IDBConnection); override;
    destructor Destroy; override;

    procedure BuildDatabase();

    procedure RegisterEntity(AEntityClass: TClass);
    procedure ClearEntities();

    function EntityExists(AEntityClass: TClass): Boolean;

  end;

  EODBCException = class(Exception);

  TBaseODBC = class(TInterfacedObject, IODBC)
  private
    FHandle: THandle;
    SQLAllocEnv: function(var phenv: Pointer): SmallInt; stdcall;
    SQLAllocConnect: function(henv: Pointer; var phdbc: Pointer): Smallint; stdcall;
    SQLDataSourcesW: function(henv: Pointer; direction:word; szDSN: PWideChar; cbDSN: Word; var pbDSN: Word;
      szDescr: PWideChar; cbDescr: Word; var pbDescr: Word): Smallint; stdcall;
  protected
    function GetDatasources: TArray<string>; virtual;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

  end;

implementation

uses
  Core.Exceptions
  ,SQL.Commands.Factory
  ,SQL.Commands.TableCreator
  ,SQL.Commands.FKCreator
  ,SQL.Commands.SeqCreator
  ,Mapping.RttiExplorer
  ,Classes
  {$IFDEF MSWINDOWS}
  ,Windows
  {$ENDIF}
  ;

const
  DLL_ODBC_32 = 'ODBC32.DLL';
  DLL_ODBC_64 = 'ODBC32.DLL';

  SQL_ERROR = -1;
  SQL_SUCCESS = 0;
  SQL_FETCH_NEXT = 1;
  SQL_FETCH_FIRST = 2;

function GetTableCreateExecutor(AClass: TClass; AConnection: IDBConnection): TTableCreateExecutor;
begin
  Result := CommandFactory.GetCommand<TTableCreateExecutor>(AClass, AConnection);
end;

function GetFKCreateExecutor(AClass: TClass; AConnection: IDBConnection): TForeignKeyCreateExecutor;
begin
  Result := CommandFactory.GetCommand<TForeignKeyCreateExecutor>(AClass, AConnection);
end;

function GetSequenceCreateExecutor(AClass: TClass; AConnection: IDBConnection): TSequenceCreateExecutor;
begin
  Result := CommandFactory.GetCommand<TSequenceCreateExecutor>(AClass, AConnection);
end;

{ TDatabaseManager }

procedure TDatabaseManager.BuildDatabase;
var
  LTran: IDBTransaction;
begin
  if (FEntities.Count < 1) then
    Exit;

  LTran := Connection.BeginTransaction;

  BuildTables(FEntities);

  BuildForeignKeys(FEntities);

  BuildSequences(FEntities);

  LTran.Commit;
end;

procedure TDatabaseManager.BuildForeignKeys(AEntities: IList<TClass>);
var
  LFkCreator: TForeignKeyCreateExecutor;
  LEntityClass: TClass;
begin
  for LEntityClass in AEntities do
  begin
    LFkCreator := GetFKCreateExecutor(LEntityClass, Connection);
    try
      LFkCreator.EntityClass := LEntityClass;
      LFkCreator.CreateForeignKeys(LEntityClass);
    finally
      LFkCreator.Free;
    end;
  end;
end;

procedure TDatabaseManager.BuildSequences(AEntities: IList<TClass>);
var
  LSequenceCreator: TSequenceCreateExecutor;
  LEntityClass: TClass;
begin
  for LEntityClass in AEntities do
  begin
    LSequenceCreator := GetSequenceCreateExecutor(LEntityClass, Connection);
    try
      LSequenceCreator.EntityClass := LEntityClass;
      LSequenceCreator.CreateSequence(LEntityClass);
    finally
      LSequenceCreator.Free;
    end;
  end;
end;

procedure TDatabaseManager.BuildTables(AEntities: IList<TClass>);
var
  LTableCreator: TTableCreateExecutor;
  LEntityClass: TClass;
begin
  for LEntityClass in AEntities do
  begin
    LTableCreator := GetTableCreateExecutor(LEntityClass, Connection);
    try
      LTableCreator.EntityClass := LEntityClass;
      LTableCreator.CreateTables(LEntityClass);
    finally
      LTableCreator.Free;
    end;
  end;
end;

procedure TDatabaseManager.ClearEntities;
begin
  FEntities.Clear;
end;

constructor TDatabaseManager.Create(AConnection: IDBConnection);
begin
  inherited Create(AConnection);
  FEntities := TRttiExplorer.GetEntities;
end;

destructor TDatabaseManager.Destroy;
begin
  inherited Destroy;
end;

function TDatabaseManager.EntityExists(AEntityClass: TClass): Boolean;
var
  LTableCreator: TTableCreateExecutor;
begin
  LTableCreator := GetTableCreateExecutor(AEntityClass, Connection);
  try
    Result := LTableCreator.TableExists(LTableCreator.Table.Name);
  finally
    LTableCreator.Free;
  end;
end;

procedure TDatabaseManager.RegisterEntity(AEntityClass: TClass);
begin
  FEntities.Add(AEntityClass);
end;

{ TBaseODBC }

constructor TBaseODBC.Create;
begin
  inherited Create;
  FHandle := 0;
  SQLAllocEnv := nil;
  SQLAllocConnect := nil;
  SQLDataSourcesW := nil;
  {$IFDEF MSWINDOWS}
  FHandle := LoadLibrary(PChar(DLL_ODBC_32));
  if FHandle <> 0 then
  begin
    SQLAllocEnv := GetProcAddress(FHandle, 'SQLAllocEnv');
    SQLAllocConnect := GetProcAddress(FHandle, 'SQLAllocConnect');
    SQLDataSourcesW := GetProcAddress(FHandle, 'SQLDataSourcesW');
  end;
  {$ENDIF}
end;

destructor TBaseODBC.Destroy;
begin
  {$IFDEF MSWINDOWS}
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  {$ENDIF}
  inherited Destroy;
end;

function TBaseODBC.GetDatasources: TArray<string>;
{$IFDEF MSWINDOWS}
var
  LHandle: Pointer;
  LConnection: Pointer;
  LDSN, LDescr: array[0..255] of WideChar;
  LcbDsn, LcbDescr: Word;
  LList: TStrings;
{$ENDIF}
begin
  SetLength(Result, 0);

  LList := TStringList.Create;
  try
    {$IFDEF MSWINDOWS}
    if not Assigned(SQLDataSourcesW) then
      Exit;

    if (SQLAllocEnv(LHandle) <> SQL_SUCCESS) then
      raise EODBCException.Create('Cannot allocate ODBC handle');

    if (SQLAllocConnect(LHandle,LConnection) <> SQL_SUCCESS) then
      raise EODBCException.Create('Cannot allocate ODBC connection');

    if SQLDataSourcesW(LHandle, SQL_FETCH_FIRST, LDSN, SizeOf(LDSN),
        LcbDsn, LDescr, SizeOf(LDescr), LcbDescr) = SQL_SUCCESS then
      LList.Add(StrPas(LDSN))
    else
      Exit;

    while SQLDataSourcesW(LHandle, SQL_FETCH_NEXT, LDSN, SizeOf(LDSN),
        LcbDsn, LDescr, SizeOf(LDescr), LcbDescr) = SQL_SUCCESS do
    begin
      LList.Add(StrPas(LDSN));
    end;

    Result := LList.ToStringArray;

    {$ENDIF}
  finally
    LList.Free;
  end;
end;

end.
