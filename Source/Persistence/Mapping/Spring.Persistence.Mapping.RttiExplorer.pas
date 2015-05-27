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

unit Spring.Persistence.Mapping.RttiExplorer;

interface

uses
  Rtti,
  SyncObjs,
  SysUtils,
  Spring,
  Spring.Collections,
  Spring.Persistence.Core.EntityCache,
  Spring.Persistence.Core.Interfaces,
  Spring.Persistence.Mapping.Attributes;

type
  /// <summary>
  ///   Caches RTTI information for faster access - internal use only.
  /// </summary>
  TRttiCache = class
  private
    fFields: IDictionary<string,TRttiField>;
    fProperties: IDictionary<string,TRttiProperty>;
    fTypes: IDictionary<PTypeInfo,TRttiType>;
    fTypeFields: IMultiMap<PTypeInfo,TRttiField>;
  protected
    function GetKey(classType: TClass; const name: string): string;
  public
    constructor Create;

    procedure Clear;
    procedure RebuildCache; virtual;

    function GetField(classType: TClass; const fieldName: string): TRttiField;
    function GetProperty(classType: TClass; const propertyName: string): TRttiProperty;
    function GetNamedObject(classType: TClass; const memberName: string): TRttiNamedObject;
    function GetType(typeInfo: PTypeInfo): TRttiType; overload;
    function GetType(classType: TClass): TRttiType; overload;
    function GetFieldsOfType(typeInfo: PTypeInfo): IEnumerable<TRttiField>;
  end;

  /// <summary>
  ///   Provides methods to access certain RTTI related information from entity
  ///   classes - internal use only.
  /// </summary>
  TRttiExplorer = record
  private
    class var fRttiCache: TRttiCache;
    class var fLock: TCriticalSection;
    class constructor Create;
    class destructor Destroy;

    class function GetEntityRttiType(typeInfo: PTypeInfo): TRttiType; static;
    class function GetMemberValue(const entity: TObject;
      const member: TRttiNamedObject): TValue; overload; static;
    class function GetNamedObject(classType: TClass;
      const propertyName: string): TRttiNamedObject; static;
  public
    class function Clone(entity: TObject): TObject; static;
    class procedure CopyFieldValues(const source, target: TObject); static;

    class function GetClassMembers<T: TORMAttribute>(classType: TClass): IList<T>; static;
    class function GetColumnIsIdentity(classType: TClass; const column: ColumnAttribute): Boolean; static;
    class function GetColumns(classType: TClass): IList<ColumnAttribute>; static;
    class function GetEntities: IList<TClass>; static;
    class function GetEntityClass(classInfo: PTypeInfo): TClass; static;
    class function GetForeignKeyColumn(classType: TClass; const baseTable: TableAttribute;
      const baseTablePrimaryKeyColumn: ColumnAttribute): ForeignJoinColumnAttribute; static;
    class function GetLastGenericArgumentType(typeInfo: PTypeInfo): TRttiType; static;

    class function GetMemberValue(const entity: TObject;
      const memberName: string): TValue; overload; static;
    class function GetMemberValueDeep(const entity: TObject;
      const memberName: string): TValue; overload; static;
    class function GetMemberValueDeep(const initialValue: TValue): TValue; overload; static;
    class function GetPrimaryKeyColumn(classType: TClass): ColumnAttribute; static;
    class function GetQueryTextFromMethod(const method: TRttiMethod): string; static;
    class function GetRelationsOf(const entity: TObject;
      const relationAttributeClass: TAttributeClass): IList<TObject>; static;
    class function GetSequence(classType: TClass): SequenceAttribute; static;
    class function GetSubEntityFromMemberDeep(const entity: TObject;
      const rttiMember: TRttiNamedObject): IList<TObject>; static;

    class function GetTable(classType: TClass): TableAttribute; overload; static;
    class function GetTable(typeInfo: PTypeInfo): TableAttribute; overload; static;
    class function GetUniqueConstraints(classType: TClass): IList<UniqueConstraint>; static;
    class function HasColumns(classType: TClass): Boolean; static;
    class function HasInstanceField(classType: TClass): Boolean; static;
    class function HasSequence(classType: TClass): Boolean; static;
    class function TryGetColumnAsForeignKey(const column: ColumnAttribute;
      out foreignKeyColumn: ForeignJoinColumnAttribute): Boolean; static;

    class property RttiCache: TRttiCache read fRttiCache;
  end;

implementation

uses
  Classes,
  TypInfo,
  Spring.Persistence.Core.Exceptions,
  Spring.Reflection;


{$REGION 'TRttiCache'}

constructor TRttiCache.Create;
begin
  inherited Create;
  fFields := TCollections.CreateDictionary<string,TRttiField>;
  fProperties := TCollections.CreateDictionary<string,TRttiProperty>;
  fTypes := TCollections.CreateDictionary<PTypeInfo,TRttiType>;
  fTypeFields := TCollections.CreateMultiMap<PTypeInfo,TRttiField>;
end;

procedure TRttiCache.Clear;
begin
  fFields.Clear;
  fProperties.Clear;
  fTypes.Clear;
  fTypeFields.Clear;
end;

function TRttiCache.GetField(classType: TClass; const fieldName: string): TRttiField;
begin
  if not fFields.TryGetValue(GetKey(classType, fieldName), Result) then
    Result := nil;
end;

function TRttiCache.GetFieldsOfType(typeInfo: PTypeInfo): IEnumerable<TRttiField>;
begin
  Result := fTypeFields[typeInfo];
end;

function TRttiCache.GetKey(classType: TClass; const name: string): string;
begin
  Result := classType.UnitName + '.' + classType.ClassName + '$' + name;
end;

function TRttiCache.GetNamedObject(classType: TClass; const memberName: string): TRttiNamedObject;
begin
  Result := GetProperty(classType, memberName);
  if Result <> nil then
    Exit;
  Result := GetField(classType, memberName);
  if Result <> nil then
    Exit;
  Result := TRttiExplorer.GetNamedObject(classType, memberName);
end;

function TRttiCache.GetProperty(classType: TClass; const propertyName: string): TRttiProperty;
begin
  if not fProperties.TryGetValue(GetKey(classType, propertyName), Result) then
    Result := nil;
end;

function TRttiCache.GetType(classType: TClass): TRttiType;
begin
  Result := nil;
  if Assigned(classType) then
  begin
    Result := GetType(classType.ClassInfo);
    if Result = nil then
      Result := TType.GetType(classType);
  end;
end;

function TRttiCache.GetType(typeInfo: PTypeInfo): TRttiType;
begin
  if not fTypes.TryGetValue(typeInfo, Result) then
    Result := TType.GetType(typeInfo);
end;

procedure TRttiCache.RebuildCache;
var
  rttiType: TRttiType;
  classType: TClass;
  field: TRttiField;
  prop: TRttiProperty;
begin
  Clear;

  for rttiType in TType.GetTypes do
  begin
    // Honza: For some reason one PTypeInfo can map to multiple types on mobile
    //        we'll use the later. (Types like IEvent, TAction, TEnumerator etc.
    //        have the same TypeInfo but are defined per unit multiple times
    //        in extended RTTI.)
    fTypes.AddOrSetValue(rttiType.Handle, rttiType);

    if rttiType.IsInstance then
    begin
      classType := rttiType.AsInstance.MetaclassType;

      if TRttiExplorer.HasColumns(classType) then
      begin
        for field in rttiType.GetFields do
        begin
          fFields.Add(GetKey(classType, field.Name), field);
          fTypeFields.Add(rttiType.Handle, field);
        end;

        for prop in rttiType.GetProperties do
          fProperties.Add(GetKey(classType, prop.Name), prop);
      end;
    end;
  end;
end;

{$ENDREGION}


{$REGION 'TRttiExplorer'}

class constructor TRttiExplorer.Create;
begin
  fLock := TCriticalSection.Create;
  fRttiCache := TRttiCache.Create;
  fRttiCache.RebuildCache;
end;

class destructor TRttiExplorer.Destroy;
begin
  fRttiCache.Free;
  fLock.Free;
end;

class function TRttiExplorer.Clone(entity: TObject): TObject;
begin
  Assert(Assigned(entity));
  Result := TActivator.CreateInstance(entity.ClassType);
  if Result is TPersistent then
    TPersistent(Result).Assign(entity as TPersistent)
  else
    CopyFieldValues(entity, Result);
end;

class procedure TRttiExplorer.CopyFieldValues(const source, target: TObject);
var
  field: TRttiField;
  value: TValue;
  sourceObject, targetObject: TObject;
begin
  Assert(Assigned(source) and Assigned(target));
  Assert(source.ClassType = target.ClassType);

  for field in TType.GetType(source.ClassInfo).GetFields do
  begin
    if field.FieldType.IsInstance then
    begin
      sourceObject := field.GetValue(source).AsObject;
      if not Assigned(sourceObject) then
        Continue;
      targetObject := field.GetValue(target).AsObject;
      if not Assigned(targetObject) then
        targetObject := TActivator.CreateInstance(sourceObject.ClassType);
      if targetObject is TPersistent then
        TPersistent(targetObject).Assign(sourceObject as TPersistent)
      else
        CopyFieldValues(sourceObject, targetObject);
      value := targetObject;
    end
    else
      value := field.GetValue(source);

    field.SetValue(target, value);
  end;
end;

class function TRttiExplorer.GetClassMembers<T>(classType: TClass): IList<T>;
var
  rttiType: TRttiType;
  rttiField: TRttiField;
  rttiProperty: TRttiProperty;
  attribute: TORMAttribute;
  attribute2: T;
begin
  Result := TCollections.CreateList<T>;
  rttiType := TType.GetType(classType);

  fLock.Enter;
  try
    for attribute in rttiType.GetCustomAttributes<TORMAttribute>(True) do
    begin
      attribute.EntityType := rttiType.Handle;
      attribute.MemberKind := mkClass;
      attribute.MemberName := rttiType.Name;
    end;

    for rttiField in rttiType.GetFields do
    begin
      for attribute2 in rttiField.GetCustomAttributes<T>(True) do
      begin
        attribute2.EntityType := rttiType.Handle;
        attribute2.MemberKind := mkField;
        attribute2.MemberName := rttiField.Name;
        attribute2.RttiMember := rttiField;
        Result.Add(attribute2);
      end;
    end;

    for rttiProperty in rttiType.GetProperties do
    begin
      for attribute2 in rttiProperty.GetCustomAttributes<T>(True) do
      begin
        attribute2.EntityType := rttiType.Handle;
        attribute2.MemberKind := mkProperty;
        attribute2.MemberName := rttiProperty.Name;
        attribute2.RttiMember := rttiProperty;
        Result.Add(attribute2);
      end;
    end;
  finally
    fLock.Leave;
  end;
end;

class function TRttiExplorer.GetColumnIsIdentity(classType: TClass;
  const column: ColumnAttribute): Boolean;
var
  member: AutoGenerated;
begin
  if GetClassMembers<AutoGenerated>(classType).TryGetFirst(member) then
    Result := SameText(member.MemberName, column.MemberName)
  else
    Result := False;
end;

class function TRttiExplorer.GetColumns(classType: TClass): IList<ColumnAttribute>;
begin
  Result := GetClassMembers<ColumnAttribute>(classType);
end;

class function TRttiExplorer.TryGetColumnAsForeignKey(
  const column: ColumnAttribute;
  out foreignKeyColumn: ForeignJoinColumnAttribute): Boolean;
var
  namedObject: TRttiNamedObject;
  attribute: TCustomAttribute;
begin
  Result := False;
  attribute := nil;

  namedObject := fRttiCache.GetNamedObject(column.BaseEntityClass, column.MemberName);
  if Assigned(namedObject) then
  begin
    attribute := namedObject.GetCustomAttribute(ForeignJoinColumnAttribute);
    Result := Assigned(attribute);
  end;

  if Result then
    foreignKeyColumn := attribute as ForeignJoinColumnAttribute;
end;

class function TRttiExplorer.GetEntities: IList<TClass>;
var
  rttiType: TRttiType;
begin
  Result := TCollections.CreateList<TClass>;

  for rttiType in TType.Types.Where(
    TTypeFilters.IsClass and TTypeFilters.HasAttribute(EntityAttribute)) do
    Result.Add(rttiType.AsInstance.MetaclassType);
end;

class function TRttiExplorer.GetEntityClass(classInfo: PTypeInfo): TClass;
var
  rttiType: TRttiType;
begin
  rttiType := GetEntityRttiType(classInfo);
  if not Assigned(rttiType) then
    raise EORMUnsupportedType.CreateFmt('Unsupported type %s', [classInfo.TypeName]);

  Result := rttiType.AsInstance.MetaclassType;
end;

class function TRttiExplorer.GetEntityRttiType(typeInfo: PTypeInfo): TRttiType;
var
  rttiType, currType: TRttiType;
  entityData: TEntityData;
begin
  rttiType := fRttiCache.GetType(typeInfo);
  if rttiType = nil then
    raise EORMUnsupportedType.CreateFmt('Cannot get type information from %s', [typeInfo.TypeName]);

  for currType in rttiType.GetGenericArguments do
    if currType.IsInstance then
      Exit(currType);

  if not rttiType.IsInstance then
    raise EORMUnsupportedType.CreateFmt('%s is not an instance type.', [typeInfo.TypeName]);

  entityData := TEntityCache.Get(rttiType.AsInstance.MetaclassType);
  if not entityData.IsTableEntity then
    raise EORMUnsupportedType.CreateFmt('Type %s lacks [Table] attribute', [typeInfo.TypeName]);

  if not entityData.HasPrimaryKey then
    raise EORMUnsupportedType.CreateFmt('Type %s lacks primary key [Column]', [typeInfo.TypeName]);

  Result := rttiType;
end;

class function TRttiExplorer.GetForeignKeyColumn(classType: TClass;
  const baseTable: TableAttribute;
  const baseTablePrimaryKeyColumn: ColumnAttribute): ForeignJoinColumnAttribute;
var
  foreignColumn: ForeignJoinColumnAttribute;
begin
  for foreignColumn in TEntityCache.Get(classType).ForeignColumns do
    if SameText(baseTablePrimaryKeyColumn.ColumnName, foreignColumn.ReferencedColumnName)
      and SameText(baseTable.TableName, foreignColumn.ReferencedTableName) then
      Exit(foreignColumn);
  Result := nil;
end;

class function TRttiExplorer.GetLastGenericArgumentType(typeInfo: PTypeInfo): TRttiType;
var
  args: TArray<TRttiType>;
begin
  Result := TType.GetType(typeInfo);
  args := Result.GetGenericArguments;
  if Length(args) > 0 then
    Result := args[High(args)];
end;

class function TRttiExplorer.GetPrimaryKeyColumn(classType: TClass): ColumnAttribute;
var
  column: ColumnAttribute;
begin
  for column in GetColumns(classType) do
    if cpPrimaryKey in column.Properties then
      Exit(column);
  Result := nil;
end;

class function TRttiExplorer.GetQueryTextFromMethod(
  const method: TRttiMethod): string;
var
  attribute: QueryAttribute;
begin
  for attribute in method.GetCustomAttributes<QueryAttribute> do
    Exit(attribute.QueryText);
  Result := '';
end;

class function TRttiExplorer.GetRelationsOf(const entity: TObject;
  const relationAttributeClass: TAttributeClass): IList<TObject>;
var
  rttiType: TRttiType;
  field: TRttiField;
  prop: TRttiProperty;
begin
  Result := TCollections.CreateList<TObject>;

  rttiType := fRttiCache.GetType(entity.ClassType);
  for field in rttiType.GetFields do
    if field.HasCustomAttribute(relationAttributeClass)
      and not field.HasCustomAttribute(TransientAttribute) then
      Result.AddRange(GetSubEntityFromMemberDeep(entity, field));

  for prop in rttiType.GetProperties do
    if prop.HasCustomAttribute(relationAttributeClass)
      and not prop.HasCustomAttribute(TransientAttribute) then
      Result.AddRange(GetSubEntityFromMemberDeep(entity, prop));
end;

class function TRttiExplorer.GetMemberValue(const entity: TObject;
  const member: TRttiNamedObject): TValue;
begin
  if member is TRttiProperty then
    Result := TRttiProperty(member).GetValue(entity)
  else if member is TRttiField then
    Result := TRttiField(member).GetValue(entity)
  else
    Result := TValue.Empty;
end;

class function TRttiExplorer.GetMemberValue(const entity: TObject;
  const memberName: string): TValue;
var
  member: TRttiNamedObject;
begin
  member := fRttiCache.GetNamedObject(entity.ClassType, memberName);
  Result := GetMemberValue(entity, member);
end;

class function TRttiExplorer.GetMemberValueDeep(
  const initialValue: TValue): TValue;
begin
  Result := initialValue;
  if IsNullable(Result.TypeInfo) then
  begin
    if not initialValue.TryGetNullableValue(Result) then
      Result := TValue.Empty;
  end
  else if IsLazyType(Result.TypeInfo) then
    if not initialValue.TryGetLazyValue(Result) then
      Result := TValue.Empty;
end;

class function TRttiExplorer.GetMemberValueDeep(const entity: TObject;
  const memberName: string): TValue;
begin
  Result := GetMemberValue(entity, memberName);

  if not Result.IsEmpty then
    Result := GetMemberValueDeep(Result);
end;

class function TRttiExplorer.GetNamedObject(classType: TClass;
  const propertyName: string): TRttiNamedObject;
var
  rttiType: TRttiType;
begin
  rttiType := TType.GetType(classType);
  Result := rttiType.GetField(propertyName);
  if not Assigned(Result) then
    Result := rttiType.GetProperty(propertyName);
end;

class function TRttiExplorer.HasInstanceField(classType: TClass): Boolean;
var
  field: TRttiField;
  prop: TRttiProperty;
begin
  //enumerate fields
  for field in TType.GetType(classType).GetFields do
    if field.FieldType.IsInstance then
      Exit(True);

  for prop in TType.GetType(classType).GetProperties do
    if prop.PropertyType.IsInstance then
      Exit(True);

  Result := False;
end;

class function TRttiExplorer.GetSequence(classType: TClass): SequenceAttribute;
begin
  Result := TType.GetType(classType).GetCustomAttribute<SequenceAttribute>(True);
end;

class function TRttiExplorer.GetSubEntityFromMemberDeep(const entity: TObject;
  const rttiMember: TRttiNamedObject): IList<TObject>;
var
  memberValue: TValue;
  value: TValue;
  objects: IObjectList;
  current: TObject;
begin
  Result := TCollections.CreateList<TObject>;

  memberValue := GetMemberValue(entity, rttiMember);
  if memberValue.IsEmpty then
    Exit;
    
  value := GetMemberValueDeep(memberValue);
  if value.IsEmpty then
    Exit;
  
  if value.IsInterface and Supports(value.AsInterface, IObjectList, objects) then
  begin
    for current in objects do
      Result.Add(current);
    value := TValue.Empty;
  end;

  if value.IsObject and (value.AsObject <> nil) then
    Result.Add(value.AsObject);
end;

class function TRttiExplorer.GetTable(typeInfo: PTypeInfo): TableAttribute;
begin
  Result := GetTable(TType.GetClass(typeInfo));
end;

class function TRttiExplorer.GetTable(classType: TClass): TableAttribute;
begin
  Result := TType.GetType(classType).GetCustomAttribute<TableAttribute>(True);
end;

class function TRttiExplorer.GetUniqueConstraints(classType: TClass): IList<UniqueConstraint>;
begin
  Result := GetClassMembers<UniqueConstraint>(classType);
end;

class function TRttiExplorer.HasColumns(classType: TClass): Boolean;
begin
  Result := GetColumns(classType).Any;
end;

class function TRttiExplorer.HasSequence(classType: TClass): Boolean;
begin
  Result := Assigned(GetSequence(classType));
end;

{$ENDREGION}


end.
