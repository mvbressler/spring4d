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

unit Spring.Persistence.SQL.Generators.ASA;

{$I Spring.inc}

interface

uses
  Spring.Persistence.Mapping.Attributes,
  Spring.Persistence.SQL.Generators.Ansi,
  Spring.Persistence.SQL.Interfaces,
  Spring.Persistence.SQL.Types;

type
  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Represents <b>Sybase ASA</b> SQL generator.
  ///	</summary>
  {$ENDREGION}
  TASASQLGenerator = class(TAnsiSQLGenerator)
  public
    function GetQueryLanguage: TQueryLanguage; override;
    function GenerateGetLastInsertId(AIdentityColumn: ColumnAttribute): string; override;
    function GeneratePagedQuery(const ASql: string; const ALimit, AOffset: Integer): string; override;
    function GetSQLDataTypeName(AField: TSQLCreateField): string; override;
  end;

implementation

uses
  StrUtils,
  SysUtils,
  Spring.Persistence.SQL.Register;

{ TASASQLGenerator }

function TASASQLGenerator.GenerateGetLastInsertId(AIdentityColumn: ColumnAttribute): string;
begin
  Result := 'SELECT @@IDENTITY;';
end;

function TASASQLGenerator.GeneratePagedQuery(const ASql: string; const ALimit,
  AOffset: Integer): string;
var
  LBuilder: TStringBuilder;
  LSQL: string;
begin
  LBuilder := TStringBuilder.Create;
  LSQL := ASql;
  try
    if EndsStr(';', LSQL) then
      SetLength(LSQL, Length(LSQL)-1);

    LBuilder.Append('SELECT * FROM (')
      .AppendLine
      .Append('  SELECT *, ROW_NUMBER OVER (ORDER BY (NULL)) AS ORM_ROW_NUM FROM (')
      .AppendLine.Append('    ')
      .Append(LSQL)
      .Append(') AS ORM_TOTAL_1')
      .AppendLine
      .Append('  ) AS ORM_TOTAL_2')
      .AppendLine
      .AppendFormat(' WHERE (ORM_ROW_NUM>=%0:D) AND (ORM_ROW_NUM < %0:D+%1:D);', [AOffset, ALimit]);

    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TASASQLGenerator.GetQueryLanguage: TQueryLanguage;
begin
  Result := qlASA;
end;


function TASASQLGenerator.GetSQLDataTypeName(AField: TSQLCreateField): string;
begin
  Result := inherited GetSQLDataTypeName(AField);
  if Result = 'BLOB' then
    Result := 'IMAGE'
  else if Result = 'TIMESTAMP' then
    Result := 'DATETIME';
end;

initialization
  TSQLGeneratorRegister.RegisterGenerator(TASASQLGenerator.Create);

end.