{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2014 Spring4D Team                           }
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

unit Spring.Persistence.Core.Relation.ManyToOne;

interface

uses
  Spring.Persistence.Core.EntityCache,
  Spring.Persistence.Core.Interfaces,
  Spring.Persistence.Core.Relation.Abstract,
  Spring.Persistence.Mapping.Attributes;

type
  TManyToOneRelation = class(TAbstractRelation)
  private
    fNewColumns: TColumnDataList;
    fNewTableName: string;
  protected
    procedure ResolveColumns(const resultSet: IDBResultSet); virtual;
  public
    NewEntity: TObject;

    constructor Create; virtual;
    destructor Destroy; override;

    class function BuildColumnName(const tableName, columnName: string): string;

    procedure SetAssociation(const entity: TObject;
      const association: AssociationAttribute;
      const resultSet: IDBResultSet); override;

    property NewColumns: TColumnDataList read fNewColumns;
  end;

implementation

uses
  SysUtils,
  Spring,
  Spring.Reflection,
  Spring.Persistence.Core.Exceptions,
  Spring.Persistence.SQL.Types;


{$REGION 'TManyToOneRelation'}

constructor TManyToOneRelation.Create;
begin
  inherited Create;
  fNewColumns := nil;
end;

destructor TManyToOneRelation.Destroy;
begin
  if Assigned(fNewColumns) then
    fNewColumns.Free;
  inherited Destroy;
end;

class function TManyToOneRelation.BuildColumnName(const tableName, columnName: string): string;
begin
  Result := TSQLAliasGenerator.GetAlias(tableName) + '$' + columnName;
end;

procedure TManyToOneRelation.ResolveColumns(const resultSet: IDBResultSet);
var
  i: Integer;
  columnData: TColumnData;
  columnName: string;
begin
  for i := fNewColumns.Count - 1 downto 0 do
  begin
    // dealing with records here so assignments necessary (cannot just set members)
    columnData := fNewColumns[i];

    columnName := BuildColumnName(fNewTableName, columnData.ColumnName);
    if not resultSet.FieldExists(columnName) then
    begin
      fNewColumns.Delete(i);
      Continue;
    end;
    columnData.ColumnName := columnName;
    fNewColumns[i] := columnData;
    if columnData.IsPrimaryKey then
      fNewColumns.PrimaryKeyColumn := columnData;
  end;
end;

procedure TManyToOneRelation.SetAssociation(const entity: TObject;
  const association: AssociationAttribute; const resultSet: IDBResultSet);
var
  newEntityClass: TClass;
  entityData: TEntityData;
begin
  newEntityClass := association.Member.MemberType.AsInstance.MetaclassType;
  entityData := TEntityCache.Get(newEntityClass);
  fNewTableName := entityData.EntityTable.TableName;
  NewEntity := TActivator.CreateInstance(newEntityClass);
  if Assigned(fNewColumns) then
    fNewColumns.Free;
  fNewColumns := TEntityCache.CreateColumnsData(newEntityClass);
  ResolveColumns(resultSet);
  association.Member.SetValue(entity, NewEntity);
end;

{$ENDREGION}


end.
