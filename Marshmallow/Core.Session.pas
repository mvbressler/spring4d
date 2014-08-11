﻿(*
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
unit Core.Session;

{$I sv.inc}
interface

uses
  Core.AbstractManager, Core.EntityMap, Core.Interfaces, Rtti, TypInfo
  ,Core.EntityCache
  ,Spring.Collections
  ,SQL.Params
  ,Mapping.Attributes;

const
  IID_GETIMPLEMENTOR: TGUID = '{4C12C697-6FE2-4263-A2D8-85034F0D0E01}';

type
  {$REGION 'Documentation'}
  ///	<summary>
  ///	  The main runtime class between an application and ORM. This is the
  ///	  central API class abstracting the notion of a persistence service. The
  ///	  main function of the Session is to offer create, read and delete
  ///	  operations for instances of mapped entity classes. <c>Insert()</c>
  ///	  results in an <c>SQL INSERT</c>, <c>delete()</c> in an <c>SQL DELETE</c>
  ///	   and <c>update() </c>in an <c>SQL UPDATE</c>. Changes to persistent
  ///	  instances are detected at flush time and also result in an
  ///	  <c>SQL UPDATE</c>. <c>save()</c> results in either an <c>INSERT</c> or
  ///	  an <c>UPDATE</c>. It is not intended that implementors be threadsafe.
  ///	  Instead each thread/transaction should obtain its own instance from a
  ///	  SessionFactory.
  ///	</summary>
  {$ENDREGION}
  TSession = class(TAbstractManager)
  private
    FOldStateEntities: TEntityMap;
    FStartedTransaction: IDBTransaction;
  protected
    function GetPager(APage, AItemsInPage: Integer): TObject;
  protected
    procedure SetEntityColumns(AEntity: TObject; AColumns: TColumnDataList; AResultset: IDBResultset); overload; virtual;
    procedure SetEntityColumns(AEntity: TObject; AColumns: IList<ManyValuedAssociation>; AResultset: IDBResultset); overload; virtual;
    procedure SetLazyColumns(AEntity: TObject; AEntityData: TEntityData);
    procedure SetAssociations(AEntity: TObject; AResultset: IDBResultset; AEntityData: TEntityData); virtual;

    procedure DoSetEntity(var AEntityToCreate: TObject; AResultset: IDBResultset; ARealEntity: TObject); virtual;
    procedure DoSetEntityValues(var AEntityToCreate: TObject; AResultset: IDBResultset; AColumns: TColumnDataList; AEntityData: TEntityData); virtual;
    procedure DoFetch<T: class, constructor>(AResultset: IDBResultset; const ACollection: TValue);

    function GetOne<T: class, constructor>(AResultset: IDBResultset; AEntity: TObject): T; overload;
    function GetOne(AResultset: IDBResultset; AClass: TClass): TObject; overload;
    function GetObjectList<T: class, constructor>(AResultset: IDBResultset): T;
    procedure SetInterfaceList<T>(var AValue: T; AResultset: IDBResultset); overload;
    procedure SetInterfaceList(var AValue: IInterface; AResultset: IDBResultset; AClassInfo: PTypeInfo); overload;
    procedure SetSimpleInterfaceList(var AValue: IInterface; AResultset: IDBResultset; AClassInfo: PTypeInfo);
    procedure SetOne<T>(var AValue: T; AResultset: IDBResultset; AEntity: TObject);
    function DoGetLazy<T>(const AID: TValue; AEntity: TObject; AColumn: ColumnAttribute; out AIsEnumerable: Boolean): IDBResultset;

    function GetSelector(AClass: TClass): TObject;

    function GetQueryCountSql(const ASql: string): string;
    function GetQueryCount(const ASql: string; const AParams: array of const): Int64; overload;
    function GetQueryCount(const ASql: string; AParams:IList<TDBParam>): Int64; overload;
  public
    constructor Create(AConnection: IDBConnection); override;
    destructor Destroy; override;

    function GetLazyValueClass<T: class, constructor>(const AID: TValue; AEntity: TObject; AColumn: ColumnAttribute): T;
    procedure SetLazyValue<T>(var AValue: T; const AID: TValue; AEntity: TObject; AColumn: ColumnAttribute);

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Gets the <c>Resultset</c> from SQL statement.
    ///	</summary>
    {$ENDREGION}
    function GetResultset(const ASql: string; const AParams: array of const): IDBResultset; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Gets the <c>Resultset</c> from SQL statement.
    ///	</summary>
    {$ENDREGION}
    function GetResultset(const ASql: string; AParams: IList<TDBParam>): IDBResultset; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Starts a new List Session. ListSession monitors changes in the specified list and can commit or rollback these changes to the database
    ///	</summary>
    ///	<remarks>
    ///	  Can return newly started list transaction interface which controls how changes will be reflected in the database.
    ///	</remarks>
    {$ENDREGION}
    function BeginListSession<T: class, constructor>(AList: IList<T>): IListSession<T>;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Starts a new transaction.
    ///	</summary>
    ///	<remarks>
    ///	  Can optionally return newly started transaction interface.
    ///	</remarks>
    {$ENDREGION}
    function BeginTransaction(): IDBTransaction;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Commits currently active transaction.
    ///	</summary>
    ///	<remarks>
    ///	  <para>
    ///	    In order for this to work, transaction at first must be started by
    ///	    calling BeginTransaction() and ReleaseCurrentTransaction() must not
    ///	    be called after this.
    ///	  </para>
    ///	  <para>
    ///	    After CommitTransaction() call there is no need to
    ///	    ReleaseCurrentTransaction because it is done automatically. 
    ///	  </para>
    ///	</remarks>
    {$ENDREGION}
    procedure CommitTransaction();

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Rollbacks currently active transaction.
    ///	</summary>
    ///	<remarks>
    ///	  <para>
    ///	    After the rollback is performed, all the changes are not reflected
    ///	    in session entity classes. They need to be reloaded manually if
    ///	    this is required.
    ///	  </para>
    ///	  <para>
    ///	    After RollbackTransaction() call there is no need to
    ///	    ReleaseCurrentTransaction because it is done automatically.
    ///	  </para>
    ///	</remarks>
    {$ENDREGION}
    procedure RollbackTransaction();
    procedure ReleaseCurrentTransaction();

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Create a new ICriteria&lt;T&gt; instance, for the given entity class,
    ///	  or a superclass of an entity class.
    ///	</summary>
    {$ENDREGION}
    function CreateCriteria<T: class, constructor>(): ICriteria<T>;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Executes sql statement which does not return resultset.
    ///	</summary>
    {$ENDREGION}
    function Execute(const ASql: string; const AParams: array of const): NativeUInt;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  <para>
    ///	    Executes given sql statement and returns first column value. SQL
    ///	    statement should be like this:
    ///	  </para>
    ///	  <code lang="Delphi">
    ///	SELECT COUNT(*) FROM TABLE;</code>
    ///	</summary>
    {$ENDREGION}
    function ExecuteScalar<T>(const ASql: string; const AParams: array of const): T;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Tries to retrieves first and only model from the sql statement. If
    ///	  not succeeds, returns false.
    ///	</summary>
    {$ENDREGION}
    function TryFirst<T: class, constructor>(const ASql: string; const AParams: array of const; out AValue: T): Boolean;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves first and only model from the sql statement.  Raises an
    ///	  <c>exception</c> if model does not exist.
    ///	</summary>
    {$ENDREGION}
    function First<T: class, constructor>(const ASql: string; const AParams: array of const): T;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves first and only model or the default value if model does not
    ///	  exist.
    ///	</summary>
    {$ENDREGION}
    function FirstOrDefault<T: class, constructor>(const ASql: string; const AParams: array of const): T;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves only one entity model from the database. Raises an
    ///	  <c>exception</c> if model does not exist.
    ///	</summary>
    {$ENDREGION}
    function Single<T: class, constructor>(const ASql: string; const AParams: array of const): T; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves only one entity model from the database. Returns default
    ///	  value if model does not exist.
    ///	</summary>
    {$ENDREGION}
    function SingleOrDefault<T: class, constructor>(const ASql: string; const AParams: array of const): T;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves multiple models from the sql statement into the Collection (
    ///	  <c>TObjectList&lt;T&gt;</c> or Spring <c>ICollection&lt;T&gt;</c>).
    ///	</summary>
    {$ENDREGION}
    procedure Fetch<T: class, constructor>(const ASql: string;
      const AParams: array of const; ACollection: ICollection<T>); overload;
    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves multiple models from the <c>Resultset</c> into the
    ///	  Collection (<c>TObjectList&lt;T&gt;</c> or Spring
    ///	  <c>ICollection&lt;T&gt;).</c>
    ///	</summary>
    {$ENDREGION}
    procedure Fetch<T: class, constructor>(AResultset: IDBResultset; ACollection: ICollection<T>); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves multiple models from the <c>Resultset</c> into the any
    ///	  Collection. Collection must contain <c>Add</c> method with single
    ///	  parameter.
    ///	</summary>
    {$ENDREGION}
    procedure Fetch<T: class, constructor>(AResultset: IDBResultset; const ACollection: TValue); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves multiple models from the <c>resultset</c>.
    ///	</summary>
    {$ENDREGION}
    function GetList<T: class, constructor>(AResultset: IDBResultset): IList<T>; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves multiple models from the sql statement.
    ///	</summary>
    {$ENDREGION}
    function GetList<T: class, constructor>(const ASql: string;
      const AParams: array of const): IList<T>; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves single model from the database based on its primary key
    ///	  value. If record not found, nil is returned.
    ///	</summary>
    {$ENDREGION}
    function FindOne<T: class, constructor>(const AID: TValue): T;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Retrieves all models from PODO database table.
    ///	</summary>
    {$ENDREGION}
    function FindAll<T: class, constructor>(): IList<T>;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Inserts model to the database .
    ///	</summary>
    {$ENDREGION}
    procedure Insert(AEntity: TObject); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Inserts models to the database.
    ///	</summary>
    {$ENDREGION}
    procedure InsertList<T: class, constructor>(ACollection: ICollection<T>); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Checks if given entity is newly created (does not exist in the
    ///	  database yet).
    ///	</summary>
    {$ENDREGION}
    function IsNew(AEntity: TObject): Boolean;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Updates model in a database.
    ///	</summary>
    {$ENDREGION}
    procedure Update(AEntity: TObject); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Updates multiple models in a database.
    ///	</summary>
    {$ENDREGION}
    procedure UpdateList<T: class, constructor>(ACollection: ICollection<T>); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Removes model from the database.
    ///	</summary>
    {$ENDREGION}
    procedure Delete(AEntity: TObject); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Removes models from the database.
    ///	</summary>
    {$ENDREGION}
    procedure DeleteList<T: class, constructor>(ACollection: ICollection<T>); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Fetches data in pages. Pages are 1-indexed.
    ///	</summary>
    {$ENDREGION}
    function Page<T: class, constructor>(APage: Integer; AItemsPerPage: Integer): IDBPage<T>; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Fetches data in pages. You do not need to write custom sql for this,
    ///	  just use ordinary sql. All the work will be done for you.  Pages are
    ///	  1-indexed.
    ///	</summary>
    {$ENDREGION}
    function Page<T: class, constructor>(APage: Integer; AItemsPerPage: Integer;
      const ASql: string; const AParams: array of const): IDBPage<T>; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Fetches data in pages. You do not need to write custom sql for this,
    ///	  just use ordinary sql. All the work will be done for you. Pages are
    ///	  1-indexed.
    ///	</summary>
    {$ENDREGION}
    function Page<T: class, constructor>(APage: Integer; AItemsPerPage: Integer;
      const ASql: string; AParams: IList<TDBParam>): IDBPage<T>; overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Saves the entity to the database. It will do update or the insert
    ///	  based on the entity state.
    ///	</summary>
    {$ENDREGION}
    procedure Save(AEntity: TObject); overload;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Saves the entity and all entities it contains to the database. It
    ///	  will do update or the insert based on the entity state.
    ///	</summary>
    ///	<remarks>
    ///	  <para>
    ///	    Use with caution when inserting new entities containing identity
    ///	    primary keys. If both base (main) and sub entities are newly
    ///	    created then framework won't be able to resolve their relationships
    ///	    because their primary keys aren't known at save time.
    ///	  </para>
    ///	  <para>
    ///	    Works best when entities are updated.
    ///	  </para>
    ///	</remarks>
    {$ENDREGION}
    procedure SaveAll(AEntity: TObject);

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Saves entities to the database. It will do update or the insert based
    ///	  on the entity state.
    ///	</summary>
    {$ENDREGION}
    procedure SaveList<T: class, constructor>(ACollection: ICollection<T>); overload;

    property OldStateEntities: TEntityMap read FOldStateEntities;
  end;


implementation

uses
  SQL.Commands.Insert
  ,SQL.Commands.Select
  ,SQL.Commands.Update
  ,SQL.Commands.Delete
  ,SQL.Commands.Page
  ,SQL.Register
  ,SQL.Interfaces
  ,Core.Exceptions
  ,SQL.Commands.Factory
  ,Mapping.RttiExplorer
  ,Core.Reflection
  ,Core.Utils
  ,Core.Base
  ,SysUtils
  ,Core.Relation.ManyToOne
  ,Core.Consts
  ,Core.Criteria
  ,Core.Collections
  ,Core.ListSession
  ;

{ TEntityManager }

function TSession.BeginListSession<T>(AList: IList<T>): IListSession<T>;
begin
  Result := TListSession<T>.Create(Self, AList);
end;

function TSession.BeginTransaction: IDBTransaction;
begin
  Result := Connection.BeginTransaction;
  FStartedTransaction := Result;
end;

procedure TSession.CommitTransaction;
begin
  if not Assigned(FStartedTransaction) then
    raise EORMTransactionNotStarted.Create(EXCEPTION_CANNOT_COMMIT);

  FStartedTransaction.Commit;
  ReleaseCurrentTransaction();
end;

constructor TSession.Create(AConnection: IDBConnection);
begin
  inherited Create(AConnection);
  FOldStateEntities := TEntityMap.Create(True);
end;

function TSession.CreateCriteria<T>: ICriteria<T>;
begin
  Result := TCriteria<T>.Create(Self);
end;

procedure TSession.Delete(AEntity: TObject);
var
  LDeleter: TDeleteExecutor;
begin
  LDeleter := CommandFactory.GetCommand<TDeleteExecutor>(AEntity.ClassType, Connection);
  try
    LDeleter.EntityClass := AEntity.ClassType;
    LDeleter.Execute(AEntity);
  finally
    LDeleter.Free;
  end;

  FOldStateEntities.Remove(AEntity);
end;

procedure TSession.DeleteList<T>(ACollection: ICollection<T>);
var
  LEntity: T;
begin
  for LEntity in ACollection do
  begin
    Delete(LEntity);
  end;
end;

destructor TSession.Destroy;
begin
  FOldStateEntities.Free;
  inherited Destroy;
end;

procedure TSession.DoFetch<T>(AResultset: IDBResultset; const ACollection: TValue);
var
  LCurrent: T;
  LCollectionAdapter: ICollectionAdapter<T>;
begin
  LCollectionAdapter := TCollectionAdapter<T>.Wrap(ACollection);
  if not LCollectionAdapter.IsAddSupported then
    raise EORMContainerDoesNotHaveAddMethod.Create('Container does not have "Add" method.');

  while not AResultset.IsEmpty do
  begin
    LCurrent := GetOne<T>(AResultset, nil);
    LCollectionAdapter.Add(LCurrent);
    AResultset.Next;
  end;
end;

function TSession.DoGetLazy<T>(const AID: TValue; AEntity: TObject; AColumn: ColumnAttribute; out AIsEnumerable: Boolean): IDBResultset;
var
  LSelecter: TSelectExecutor;
  LBaseEntityClass, LEntityClass: TClass;
  LEnumMethod: TRttiMethod;
begin
  LBaseEntityClass := AEntity.ClassType;
  if not TRttiExplorer.TryGetEntityClass(TypeInfo(T), LEntityClass) then
  begin
    //we are fetching from the same table - AEntity
    LEntityClass := LBaseEntityClass;
  end;

  LSelecter := GetSelector(LEntityClass) as TSelectExecutor;
  try
    LSelecter.EntityClass := LEntityClass;
   // LSelecter.Connection := Connection;
    LSelecter.ID := AID;
    LSelecter.LazyColumn := AColumn;
    AIsEnumerable := TUtils.IsEnumerable(TypeInfo(T), LEnumMethod);
    Result := LSelecter.Select(AEntity, LBaseEntityClass);
  finally
    LSelecter.Free;
  end;
end;

procedure TSession.DoSetEntity(var AEntityToCreate: TObject; AResultset: IDBResultset; ARealEntity: TObject);
var
  LEntityData: TEntityData;
  LResult, LValue: TValue;
  LVal: Variant;
begin
  LEntityData := TEntityCache.Get(AEntityToCreate.ClassType);
  {TODO -oLinas -cGeneral : if AEntity class type is not our real Entity type, simply just set value}
  if not LEntityData.IsTableEntity and Assigned(ARealEntity) then
  begin
    if not AResultset.IsEmpty then
    begin
      LVal := AResultset.GetFieldValue(0);
      LValue := TUtils.FromVariant(LVal);

      if TUtils.TryConvert(LValue, Self,
        TRttiExplorer.GetRttiType(AEntityToCreate.ClassType), ARealEntity, LResult) then
      begin
        if AEntityToCreate <> nil then
          FreeAndNil(AEntityToCreate);
        AEntityToCreate := LResult.AsObject;
        FreeValueObject(LValue);
      end;
    end;
  end
  else
  begin
    DoSetEntityValues(AEntityToCreate, AResultset, LEntityData.ColumnsData, LEntityData);
  end;
end;

procedure TSession.DoSetEntityValues(var AEntityToCreate: TObject; AResultset: IDBResultset;
  AColumns: TColumnDataList; AEntityData: TEntityData);
var
  LEntityData: TEntityData;
  LClonedObject: TObject;
begin
  SetEntityColumns(AEntityToCreate, AColumns, AResultset);
  //we need to set internal values for the lazy type field
  LEntityData := AEntityData;
  if (AEntityToCreate.ClassType <> AEntityData.EntityClass) then
    LEntityData := TEntityCache.Get(AEntityToCreate.ClassType);

  SetLazyColumns(AEntityToCreate, LEntityData);

  SetAssociations(AEntityToCreate, AResultset, LEntityData);

  LClonedObject := TRttiExplorer.Clone(AEntityToCreate);
  FOldStateEntities.AddOrReplace(LClonedObject);
end;

function TSession.Execute(const ASql: string; const AParams: array of const): NativeUInt;
var
  LStatement: IDBStatement;
begin
  LStatement := Connection.CreateStatement;
  LStatement.SetSQLCommand(ASql);
  if Length(AParams) > 0 then
    LStatement.SetParams(AParams);

  Result := LStatement.Execute;
end;

function TSession.ExecuteScalar<T>(const ASql: string; const AParams: array of const): T;
var
  LResults: IDBResultset;
  LVal: Variant;
  LValue, LConvertedValue: TValue;
  LMustFree: Boolean;
begin
  Result := System.Default(T);
  LResults := GetResultset(ASql, AParams);
  if not LResults.IsEmpty then
  begin
    LVal := LResults.GetFieldValue(0);

    LValue := TUtils.FromVariant(LVal);
    if not LValue.TryConvert(TypeInfo(T), LConvertedValue, LMustFree) then
      raise EORMCannotConvertValue.CreateFmt(EXCEPTION_CANNOT_CONVERT_TYPE
        , [LValue.TypeInfo.Name, PTypeInfo(TypeInfo(T)).Name]);
    Result := LConvertedValue.AsType<T>;
  end;
end;

procedure TSession.Fetch<T>(const ASql: string; const AParams: array of const;
  ACollection: ICollection<T>);
var
  LResults: IDBResultset;
begin
  LResults := GetResultset(ASql, AParams);

  Fetch<T>(LResults, ACollection);
end;

function TSession.GetList<T>(const ASql: string; const AParams: array of const): IList<T>;
begin
  Result := TCollections.CreateList<T>(True);
  Fetch<T>(ASql, AParams, Result);
end;

procedure TSession.Fetch<T>(AResultset: IDBResultset; ACollection: ICollection<T>);
var
  LCollection: TValue;
begin
  LCollection := TValue.From(ACollection);
  DoFetch<T>(AResultset, LCollection);
end;

function TSession.GetList<T>(AResultset: IDBResultset): IList<T>;
begin
  Result := TCollections.CreateList<T>(True);
  Fetch<T>(AResultset, Result);
end;

procedure TSession.Fetch<T>(AResultset: IDBResultset; const ACollection: TValue);
begin
  DoFetch<T>(AResultset, ACollection);
end;

function TSession.FindAll<T>: IList<T>;
var
  LEntityClass: TClass;
  LSelecter: TSelectExecutor;
  LResults: IDBResultset;
begin
  if not TRttiExplorer.TryGetEntityClass(TypeInfo(T), LEntityClass) then
  begin
    //we are fetching from the same table - AEntity
    LEntityClass := T;
  end;

  LSelecter := GetSelector(LEntityClass) as TSelectExecutor;
  try
    LSelecter.EntityClass := LEntityClass;
    LSelecter.LazyColumn := nil;
    LResults := LSelecter.SelectAll(nil, LEntityClass);
    Result := GetList<T>(LResults);
  finally
    LSelecter.Free;
  end;
end;

function TSession.FindOne<T>(const AID: TValue): T;
var
  LSelecter: TSelectExecutor;
  LEntityClass: TClass;
  LResults: IDBResultset;
begin
  Result := System.Default(T);
  if not TRttiExplorer.TryGetEntityClass(TypeInfo(T), LEntityClass) then
  begin
    //we are fetching from the same table - AEntity
    LEntityClass := T;
  end;

  LSelecter := GetSelector(LEntityClass) as TSelectExecutor;
  try
    LSelecter.EntityClass := LEntityClass;
    LSelecter.ID := AID;
    LSelecter.LazyColumn := nil;
    LResults := LSelecter.Select(nil, LEntityClass);
    if not LResults.IsEmpty then
    begin
      Result := GetOne<T>(LResults, nil);
    end;
  finally
    LSelecter.Free;
  end;
end;

function TSession.First<T>(const ASql: string; const AParams: array of const): T;
begin
  if not TryFirst<T>(ASql, AParams, Result) then
    raise EORMRecordNotFoundException.Create(EXCEPTION_QUERY_NO_RECORDS);
end;

function TSession.FirstOrDefault<T>(const ASql: string; const AParams: array of const): T;
begin
  if not TryFirst<T>(ASql, AParams, Result) then
    Result := System.Default(T);
end;

procedure TSession.SetSimpleInterfaceList(var AValue: IInterface; AResultset: IDBResultset; AClassInfo: PTypeInfo);
var
  LAddMethod: TRttiMethod;
  LValue, LCurrent: TValue;
  LIndex: Integer;
begin
  if not TRttiExplorer.TryGetBasicMethod(METHODNAME_CONTAINER_ADD, AClassInfo, LAddMethod) then
    raise EORMContainerDoesNotHaveAddMethod.Create(EXCEPTION_CONTAINER_DOESNOTHAVE_ADD);

  LValue := TValue.From(AValue);
  LIndex := 0;
  while not AResultset.IsEmpty do
  begin
    LCurrent := TUtils.FromVariant( AResultset.GetFieldValue(LIndex) );
    LAddMethod.Invoke(LValue, [LCurrent]);
    AResultset.Next;
    Inc(LIndex);
  end;
end;

procedure TSession.SetInterfaceList(var AValue: IInterface; AResultset: IDBResultset; AClassInfo: PTypeInfo);
var
  LCurrent: TObject;
  LEntityClass: TClass;
  LAddMethod: TRttiMethod;
  LAddParameters: TArray<TRttiParameter>;
  LValue: TValue;
begin
  if not (AClassInfo.Kind = tkInterface) then
    raise EORMUnsupportedType.Create(EXCEPTION_UNSUPPORTED_CONTAINER_TYPE);

  if not TRttiExplorer.TryGetEntityClass(AClassInfo, LEntityClass) then
    raise EORMUnsupportedType.Create(EXCEPTION_UNSUPPORTED_CONTAINER_TYPE);

  if not TRttiExplorer.TryGetBasicMethod(METHODNAME_CONTAINER_ADD, AClassInfo, LAddMethod) then
    raise EORMContainerDoesNotHaveAddMethod.Create(EXCEPTION_CONTAINER_DOESNOTHAVE_ADD);


  LAddParameters := LAddMethod.GetParameters;
  if (Length(LAddParameters) <> 1) then
    raise EORMContainerAddMustHaveOneParameter.Create(EXCEPTION_CONTAINER_ADD_ONE_PARAM);

  case LAddParameters[0].ParamType.TypeKind of
    tkClass, tkClassRef, tkInterface, tkPointer, tkRecord:
    else
      raise EORMContainerItemTypeNotSupported.Create(EXCEPTION_CONTAINER_ITEM_TYPE_NOTSUPPORTED);
  end;

  LValue := TValue.From(AValue);

  while not AResultset.IsEmpty do
  begin
    LCurrent := GetOne(AResultset, LEntityClass);

    LAddMethod.Invoke(LValue, [LCurrent]);

    AResultset.Next;
  end;
end;

procedure TSession.SetInterfaceList<T>(var AValue: T; AResultset: IDBResultset);
var
  LCurrent: TObject;
  LEntityClass: TClass;
  LAddMethod: TRttiMethod;
  LAddParameters: TArray<TRttiParameter>;
  LValue: TValue;
begin
  if not (PTypeInfo(TypeInfo(T)).Kind = tkInterface) then
    raise EORMUnsupportedType.Create(EXCEPTION_UNSUPPORTED_CONTAINER_TYPE);

  if not TRttiExplorer.TryGetEntityClass(TypeInfo(T), LEntityClass) then
    raise EORMUnsupportedType.Create(EXCEPTION_UNSUPPORTED_CONTAINER_TYPE);

  if not TRttiExplorer.TryGetBasicMethod(METHODNAME_CONTAINER_ADD, TypeInfo(T), LAddMethod) then
    raise EORMContainerDoesNotHaveAddMethod.Create(EXCEPTION_CONTAINER_DOESNOTHAVE_ADD);


  LAddParameters := LAddMethod.GetParameters;
  if (Length(LAddParameters) <> 1) then
    raise EORMContainerAddMustHaveOneParameter.Create(EXCEPTION_CONTAINER_ADD_ONE_PARAM);

  case LAddParameters[0].ParamType.TypeKind of
    tkClass, tkClassRef, tkInterface, tkPointer, tkRecord:
    else
      raise EORMContainerItemTypeNotSupported.Create(EXCEPTION_CONTAINER_ITEM_TYPE_NOTSUPPORTED);
  end;

  LValue := TValue.From<T>(AValue);

  while not AResultset.IsEmpty do
  begin
    LCurrent := GetOne(AResultset, LEntityClass);

    LAddMethod.Invoke(LValue, [LCurrent]);

    AResultset.Next;
  end;
end;

procedure TSession.SetLazyValue<T>(var AValue: T; const AID: TValue; AEntity: TObject; AColumn: ColumnAttribute);
var
  IsEnumerable: Boolean;
  LResults: IDBResultset;
begin
  if not Assigned(AEntity) or AID.IsEmpty then
  begin
    Exit();
  end;

  case PTypeInfo(TypeInfo(T)).Kind of
    tkClass, tkClassRef, tkPointer, tkRecord, tkUnknown:
    begin
      raise EORMUnsupportedType.CreateFmt(EXCEPTION_UNSUPPORTED_LAZY_TYPE, [string(PTypeInfo(TypeInfo(T)).Name)]);
    end;
  end;

  LResults := DoGetLazy<T>(AID, AEntity, AColumn, IsEnumerable);

  if IsEnumerable then
    SetInterfaceList<T>(AValue, LResults)
  else
    SetOne<T>(AValue, LResults, AEntity);
end;

procedure TSession.SetOne<T>(var AValue: T; AResultset: IDBResultset; AEntity: TObject);
var
  LValue, LConverted: TValue;
  LType: TRttiType;
  LColumn: ColumnAttribute;
  LVal: Variant;
begin
  LType := TRttiExplorer.GetEntityRttiType(TypeInfo(T));
  //{TODO -oLinas -cGeneral : maybe introduce new attribute for specifying simple lazy types. Maybe with SQL parameter}

  if TRttiExplorer.TryGetColumnByMemberName(AEntity.ClassType, LType.Name, LColumn) then
  begin
    if not AResultset.IsEmpty then
    begin
      LVal := AResultset.GetFieldValue(LColumn.Name);
      LValue := TUtils.FromVariant(LVal);
      TRttiExplorer.SetMemberValue(Self, AEntity, LColumn, LValue);
    end;
  end;
end;

function TSession.GetLazyValueClass<T>(const AID: TValue; AEntity: TObject; AColumn: ColumnAttribute): T;
var
  IsEnumerable: Boolean;
  LResults: IDBResultset;
begin
  if not Assigned(AEntity) or AID.IsEmpty then
    Exit(System.Default(T));

  LResults := DoGetLazy<T>(AID, AEntity, AColumn, IsEnumerable);

  if IsEnumerable then
    Result := GetObjectList<T>(LResults)
  else
    Result := GetOne<T>(LResults, AEntity);
end;

function TSession.GetPager(APage, AItemsInPage: Integer): TObject;
var
  LPager: TPager;
begin
  Result := TPager.Create(Connection);
  LPager := TPager(Result);
  LPager.Page := APage;
  LPager.ItemsPerPage := AItemsInPage;
end;

function TSession.GetObjectList<T>(AResultset: IDBResultset): T;
var
  LCurrent: TObject;
  LEntityClass: TClass;
  LAddMethod: TRttiMethod;
  LProp: TRttiProperty;
  LAddParameters: TArray<TRttiParameter>;
begin
  Result := T.Create;

  if not TRttiExplorer.TryGetEntityClass(TypeInfo(T), LEntityClass) then
    LEntityClass := T;

  if not TRttiExplorer.TryGetBasicMethod(METHODNAME_CONTAINER_ADD, TypeInfo(T), LAddMethod) then
    raise EORMContainerDoesNotHaveAddMethod.Create(EXCEPTION_CONTAINER_DOESNOTHAVE_ADD);

  LAddParameters := LAddMethod.GetParameters;
  if (Length(LAddParameters) <> 1) then
    raise EORMContainerAddMustHaveOneParameter.Create(EXCEPTION_CONTAINER_ADD_ONE_PARAM);

  if Result.TryGetProperty(METHODNAME_CONTAINER_OWNSOBJECTS, LProp) then
    LProp.SetValue(TObject(Result), True);

  case LAddParameters[0].ParamType.TypeKind of
    tkClass, tkClassRef, tkInterface, tkPointer, tkRecord:
    else
      raise EORMContainerItemTypeNotSupported.Create(EXCEPTION_CONTAINER_ITEM_TYPE_NOTSUPPORTED);
  end;

  while not AResultset.IsEmpty do
  begin
    LCurrent := GetOne(AResultset, LEntityClass);

    LAddMethod.Invoke(Result, [LCurrent]);

    AResultset.Next;
  end;
end;

function TSession.GetOne(AResultset: IDBResultset; AClass: TClass): TObject;
begin
  Result := AClass.Create;
  DoSetEntity(Result, AResultset, nil);
end;

function TSession.GetOne<T>(AResultset: IDBResultset; AEntity: TObject): T;
begin
  Result := T.Create;
  DoSetEntity(TObject(Result), AResultset, AEntity);
end;

function TSession.GetQueryCount(const ASql: string; const AParams: array of const): Int64;
var
  LSQL: string;
  LResults: IDBResultset;
begin
  Result := 0;
  LSQL := GetQueryCountSql(ASql);
  LResults := GetResultset(LSQL, AParams);
  if not LResults.IsEmpty then
  begin
    Result := LResults.GetFieldValue(0);
  end;
end;

function TSession.GetQueryCount(const ASql: string; AParams:IList<TDBParam>): Int64;
var
  LSQL: string;
  LResults: IDBResultset;
begin
  Result := 0;
  LSQL := GetQueryCountSql(ASql);
  LResults := GetResultset(LSQL, AParams);
  if not LResults.IsEmpty then
  begin
    Result := LResults.GetFieldValue(0);
  end;
end;

function TSession.GetQueryCountSql(const ASql: string): string;
var
  LGenerator: ISQLGenerator;
begin
  LGenerator := TSQLGeneratorRegister.GetGenerator(Connection.GetQueryLanguage);
  Result := LGenerator.GenerateGetQueryCount(ASql);
end;

function TSession.GetResultset(const ASql: string;
  const AParams: array of const): IDBResultset;
var
  LParams: IList<TDBParam>;
begin
  LParams := TCollections.CreateObjectList<TDBParam>();
  if (Length(AParams) > 0) then
  begin
    ConvertParams(AParams, LParams);
  end;
  Result := GetResultset(ASql, LParams);
end;

function TSession.GetResultset(const ASql: string;
  AParams: IList<TDBParam>): IDBResultset;
var
  LStmt: IDBStatement;
begin
  Assert(Assigned(AParams), 'Parameters must be assigned');
  LStmt := Connection.CreateStatement();
  LStmt.SetSQLCommand(ASql);

  if (AParams.Count > 0) then
  begin
    LStmt.SetParams(AParams);
  end;
  Result := LStmt.ExecuteQuery();
end;

function TSession.GetSelector(AClass: TClass): TObject;
begin
  Result := CommandFactory.GetCommand<TSelectExecutor>(AClass, Connection);
end;

procedure TSession.Insert(AEntity: TObject);
var
  LInserter: TInsertExecutor;
begin
  LInserter := CommandFactory.GetCommand<TInsertExecutor>(AEntity.ClassType, Connection);
  try
    LInserter.EntityClass := AEntity.ClassType;
    LInserter.Execute(AEntity);

    SetLazyColumns(AEntity, TEntityCache.Get(AEntity.ClassType));
    FOldStateEntities.AddOrReplace(TRttiExplorer.Clone(AEntity));
  finally
    LInserter.Free;
  end;
end;

procedure TSession.InsertList<T>(ACollection: ICollection<T>);
var
  LEntity: T;
begin
  for LEntity in ACollection do
  begin
    Insert(LEntity);
  end;
end;

function TSession.IsNew(AEntity: TObject): Boolean;
begin
  Result := not FOldStateEntities.IsMapped(AEntity);
end;

function TSession.Page<T>(APage, AItemsPerPage: Integer): IDBPage<T>;
begin
  Result := CreateCriteria<T>.Page(APage, AItemsPerPage);
end;

function TSession.Page<T>(APage, AItemsPerPage: Integer; const ASql: string;
  AParams: IList<TDBParam>): IDBPage<T>;
var
  LPager: TPager;
  LSQL: string;
  LResultset: IDBResultset;
begin
  LPager := GetPager(APage, AItemsPerPage) as TPager;
  Result := TDriverPageAdapter<T>.Create(LPager);
  LPager.TotalItems := GetQueryCount(ASql, AParams);
  LSQL := LPager.BuildSQL(ASql);

  LResultset := GetResultset(LSQL, AParams);
  Fetch<T>(LResultset, Result.Items);
end;

function TSession.Page<T>(APage, AItemsPerPage: Integer; const ASql: string;
  const AParams: array of const): IDBPage<T>;
var
  LPager: TPager;
  LSQL: string;
begin
  LPager := GetPager(APage, AItemsPerPage) as TPager;
  Result := TDriverPageAdapter<T>.Create(LPager);
  LPager.TotalItems := GetQueryCount(ASql, AParams);
  LSQL := LPager.BuildSQL(ASql);

  Fetch<T>(LSQL, AParams, Result.Items);
end;

procedure TSession.ReleaseCurrentTransaction;
begin
  FStartedTransaction := nil;
end;

procedure TSession.RollbackTransaction;
begin
  if not Assigned(FStartedTransaction) then
    raise EORMTransactionNotStarted.Create(EXCEPTION_CANNOT_ROLLBACK);

  FStartedTransaction.Rollback();
  ReleaseCurrentTransaction();
end;

procedure TSession.Save(AEntity: TObject);
begin
  if IsNew(AEntity) then
    Insert(AEntity)
  else
    Update(AEntity);
end;

procedure TSession.SaveAll(AEntity: TObject);
var
  LRelations: IList<TObject>;
  i: Integer;
begin
  LRelations := TRttiExplorer.GetRelationsOf(AEntity);
  for i := 0 to LRelations.Count - 1 do
  begin
    SaveAll(LRelations[i]);
  end;
  Save(AEntity);
end;

procedure TSession.SaveList<T>(ACollection: ICollection<T>);
var
  LEntity: T;
begin
  for LEntity in ACollection do
  begin
    Save(LEntity);
  end;
end;

procedure TSession.SetAssociations(AEntity: TObject; AResultset: IDBResultset; AEntityData: TEntityData);
var
  LCol: TORMAttribute;
  LManyToOne: TManyToOneRelation;
begin
  if AEntityData.HasManyToOneRelations then
  begin
    LManyToOne := TManyToOneRelation.Create;
    try
      for LCol in AEntityData.ManyToOneColumns do
      begin
        LManyToOne.SetAssociation(LCol, AEntity, AResultset);
        DoSetEntityValues(LManyToOne.NewEntity, AResultset, LManyToOne.NewColumns, AEntityData);
      end;
    finally
      LManyToOne.Free;
    end;
  end;
end;

procedure TSession.SetEntityColumns(AEntity: TObject; AColumns: IList<ManyValuedAssociation>;
  AResultset: IDBResultset);
var
  LCol: ManyValuedAssociation;
  LVal: Variant;
  LValue: TValue;
begin
  for LCol in AColumns do
  begin
    LVal := AResultset.GetFieldValue(LCol.MappedBy);
    LValue := TUtils.FromVariant(LVal);
    TRttiExplorer.SetMemberValue(Self, AEntity, LCol.ClassMemberName, LValue);
  end;
end;

procedure TSession.SetLazyColumns(AEntity: TObject; AEntityData: TEntityData);
var
  LCol: ManyValuedAssociation;
  LValue: TValue;
  LColumns: IList<OneToManyAttribute>;
begin
  if not AEntityData.HasOneToManyRelations then
    Exit;
  LColumns := AEntityData.OneToManyColumns;
  for LCol in LColumns do
  begin
    LValue := TRttiExplorer.GetMemberValue(AEntity, LCol.MappedBy); //get foreign key value
    TRttiExplorer.SetMemberValue(Self, AEntity, LCol.ClassMemberName, LValue);
  end;
end;

procedure TSession.SetEntityColumns(AEntity: TObject; AColumns: TColumnDataList; AResultset: IDBResultset);
var
  LCol: TColumnData;
  LVal: Variant;
  LValue, LPrimaryKey: TValue;
  LTypeInfo: PTypeInfo;
  i: Integer;
begin
  if AColumns.TryGetPrimaryKeyColumn(LCol) then
  begin
    try
      LVal := AResultset.GetFieldValue(LCol.Name);
    except
      raise EORMColumnNotFound.CreateFmt(EXCEPTION_PRIMARYKEY_NOTFOUND, [LCol.Name]);
    end;
    LPrimaryKey := TUtils.FromVariant(LVal);
    TRttiExplorer.SetMemberValue(Self, AEntity, LCol.ClassMemberName, LPrimaryKey);
  end;

  for i := 0 to AColumns.Count - 1 do
  begin
    LCol := AColumns[i];
    if LCol.IsPrimaryKey then
    begin
      Continue;
    end;

    LTypeInfo := LCol.ColTypeInfo; //  GetTypeInfo(AEntity.ClassInfo);
    if (LTypeInfo <> nil) and (TUtils.IsLazyType(LTypeInfo)) then
    begin
      LValue := LPrimaryKey; //assign primary key value to lazy type, later convert procedure will assign it to lazy type's private field
    end
    else
    begin
      try
        LVal := AResultset.GetFieldValue(LCol.Name);
      except
        raise EORMColumnNotFound.CreateFmt(EXCEPTION_COLUMN_NOTFOUND, [LCol.Name]);
      end;
      LValue := TUtils.ColumnFromVariant(LVal, LCol, Self, AEntity);
    end;

    TRttiExplorer.SetMemberValue(Self, AEntity, LCol.ClassMemberName, LValue);
  end;
end;

function TSession.Single<T>(const ASql: string; const AParams: array of const): T;
begin
  Result := First<T>(ASql, AParams);
end;

function TSession.SingleOrDefault<T>(const ASql: string; const AParams: array of const): T;
begin
  Result := FirstOrDefault<T>(ASql, AParams);
end;

function TSession.TryFirst<T>(const ASql: string; const AParams: array of const; out AValue: T): Boolean;
var
  LResults: IDBResultset;
begin
  LResults := GetResultset(ASql, AParams);
  Result := not LResults.IsEmpty;
  if Result then
    AValue := GetOne<T>(LResults, nil);
end;

procedure TSession.Update(AEntity: TObject);
var
  LUpdater: TUpdateExecutor;
begin
  LUpdater := CommandFactory.GetCommand<TUpdateExecutor>(AEntity.ClassType, Connection);
  try
    LUpdater.EntityClass := AEntity.ClassType;
    LUpdater.EntityMap := FOldStateEntities;
    LUpdater.Execute(AEntity);

    SetLazyColumns(AEntity, TEntityCache.Get(AEntity.ClassType));
    FOldStateEntities.AddOrReplace(TRttiExplorer.Clone(AEntity));
  finally
    LUpdater.Free;
  end;
end;

procedure TSession.UpdateList<T>(ACollection: ICollection<T>);
var
  LEntity: T;
begin
  for LEntity in ACollection do
  begin
    Update(LEntity);
  end;
end;

end.