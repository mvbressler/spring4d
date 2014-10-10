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

unit Spring.Persistence.SQL.Commands.BulkInsert.MongoDB;

interface

uses
  Spring.Collections,
  Spring.Persistence.SQL.Commands.Insert;

type
  TMongoDBBulkInsertExecutor = class(TInsertExecutor)
  public
    procedure BulkExecute<T: class, constructor>(const entities: ICollection<T>);
  end;

implementation

uses
  Rtti,
  MongoBson,
  Spring.Persistence.Adapters.MongoDB,
  Spring.Persistence.Mapping.RttiExplorer;


{$REGION 'TMongoDBBulkInsertExecutor'}

procedure TMongoDBBulkInsertExecutor.BulkExecute<T>(const entities: ICollection<T>);
var
  LEntity: T;
  LQuery: string;
  LStatement: TMongoStatementAdapter;
  LConn: TMongoDBConnection;
  LDocs: array of IBSONDocument;
  LCollection: string;
  i: Integer;
begin
  LConn := (Connection as TMongoConnectionAdapter).Connection;
  LStatement := TMongoStatementAdapter.Create(nil);
  try
    SetLength(LDocs, entities.Count);
    i := 0;
    for LEntity in entities do
    begin
      if CanClientAutogenerateValue then
      begin
        TRttiExplorer.SetMemberValue(nil, LEntity, GetPrimaryKeyColumn, TValue.FromVariant(Generator.GenerateUniqueId));
      end;

      GetInsertCommand.Entity := LEntity;
      Command.Entity := LEntity;
      LQuery := Generator.GenerateInsert(GetInsertCommand);
      LStatement.SetSQLCommand(LQuery);
      if (LCollection = '') then
        LCollection := LStatement.GetFullCollectionName;
      LDocs[i] := JsonToBson(LStatement.GetQueryText);
      Inc(i);
    end;

    LConn.Insert(LCollection, LDocs);
  finally
    LStatement.Free;
  end;
end;

{$ENDREGION}


end.
