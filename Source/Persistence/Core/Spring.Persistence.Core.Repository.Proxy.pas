unit Spring.Persistence.Core.Repository.Proxy;

{$I Spring.inc}

interface

{$IFNDEF DelphiXE_UP}
  {$Message Fatal 'Proxy repository supports XE or higher'}
{$ENDIF}

uses
  Rtti,
  TypInfo,
  Spring.Collections,
  Spring.Persistence.Core.Interfaces,
  Spring.Persistence.Core.Session,
  Spring.Persistence.Core.Repository.Simple,
  Spring.Reflection.Compatibility;

type
  TMethodReference = reference to function(const Args: TArray<TValue>): TValue;

  TProxyRepository<T: class, constructor; TID> = class(Spring.Reflection.Compatibility.TVirtualInterface)
  private
    fRepository: IPagedRepository<T,TID>;
    fSession: TSession;
    fDefaultMethods: IDictionary<string,TMethodReference>;
    fTypeName: string;
    fQualifiedTypeName: string;
    fIdTypeName: string;
    fQualifiedIdTypeName: string;
  protected
    function DoOnInvoke(Method: TRttiMethod; const Args: TArray<TValue>): TValue;
    procedure RegisterDefaultMethods;
    procedure RegisterMethod(const AMethodSignature: string; AMethodRef: TMethodReference);
  public
    constructor Create(ASession: TSession; AInterfaceTypeInfo: PTypeInfo;
      ARepositoryClass: TClass = nil); reintroduce;
  end;

function FromArgsToConstArray(const args: TArray<TValue>): TArray<TVarRec>;
procedure FinalizeVarRec(var item: TVarRec);
procedure FinalizeVarRecArray(var values: TArray<TVarRec>);
function GetPageArgs(const args: TArray<TValue>; out page: Integer; out pageSize: Integer): TArray<TValue>;

implementation

uses
  Math,
  SysUtils,
  Variants,
  Spring,
  Spring.Persistence.Core.Exceptions,
  Spring.Persistence.Core.Utils,
  Spring.Persistence.Mapping.RttiExplorer,
  Spring.Reflection;

function FromArgsToConstArray(const args: TArray<TValue>): TArray<TVarRec>;
var
  i: Integer;
  item: TVarRec;
  value: TValue;
begin
  SetLength(Result, Max(0, Length(args) - 1));
  for i := Low(args) + 1 to High(args) do
  begin
    value := args[i];
    item := Default(TVarRec);
    case value.Kind of
      tkInteger:
      begin
        item.VInteger := value.AsInteger;
        item.VType := vtInteger;
      end;
      tkEnumeration:
      begin
        item.VBoolean := value.AsBoolean;
        item.VType := vtBoolean;
      end;
      tkString, tkUString, tkLString, tkWString:
      begin
        item.VUnicodeString := nil;
        string(item.VUnicodeString) := value.AsString;
        item.VType := vtUnicodeString;
      end;
      tkFloat:
      begin
        New(item.VExtended);
        item.VExtended^ := value.AsExtended;
        item.VType := vtExtended;
      end;
      tkRecord:
      begin
        //empty TVarRec
      end;
      tkInt64:
      begin
        New(item.VInt64);
        item.VInt64^ := value.AsInt64;
        item.VType := vtInt64;
      end
      else
        raise EORMUnsupportedType.CreateFmt('Unknown open argument type (%s)', [value.ToString]);
    end;
    Result[i - 1] := item;
  end;
end;

procedure FinalizeVarRec(var item: TVarRec);
begin
  case item.VType of
    vtExtended: Dispose(item.VExtended);
    vtString: Dispose(item.VString);
    vtPWideChar: FreeMem(item.VPWideChar);
    vtAnsiString: string(item.VAnsiString) := '';
    vtCurrency: Dispose(item.VCurrency);
    vtVariant: Dispose(item.VVariant);
    vtInterface: IInterface(item.VInterface) := nil;
    vtWideString: WideString(item.VWideString) := '';
    vtUnicodeString: string(item.VUnicodeString) := '';
    vtInt64: Dispose(item.VInt64);
  end;
  item.VInteger := 0;
end;

procedure FinalizeVarRecArray(var values: TArray<TVarRec>);
var
  i: Integer;
begin
  for i := Low(values) to High(values) do
    FinalizeVarRec(values[i]);
  values := nil;
end;

function GetPageArgs(const args: TArray<TValue>; out page: Integer; out pageSize: Integer): TArray<TValue>;
var
  i: Integer;
begin
  try
    pageSize := args[High(args)].AsInteger;
    page := args[High(args) - 1].AsInteger;
  except
    raise EORMInvalidArguments.Create('Last 2 arguments for paged requests should be page(Integer) and pageSize(Integer).');
  end;
  SetLength(Result, Length(args) - 2);
  for i := Low(Result) to High(Result) do
    Result[i] := args[i];
end;

{ TProxyRepository<T, TID> }

constructor TProxyRepository<T, TID>.Create(ASession: TSession;
  AInterfaceTypeInfo: PTypeInfo; ARepositoryClass: TClass);
begin
  inherited Create(AInterfaceTypeInfo);
  fSession := ASession;
  fDefaultMethods := TCollections.CreateDictionary<string, TMethodReference>(
    TStringComparer.OrdinalIgnoreCase);
  if not Assigned(ARepositoryClass) then
    fRepository := TSimpleRepository<T,TID>.Create(ASession)
  else
    fRepository := TRttiExplorer.CreateExternalType(ARepositoryClass, [ASession]) as TSimpleRepository<T,TID>;
  fTypeName := PTypeInfo(TypeInfo(T)).TypeName;
  fIdTypeName := PTypeInfo(TypeInfo(TID)).TypeName;
  fQualifiedTypeName := TType.GetType(TypeInfo(T)).QualifiedName;
  fQualifiedIdTypeName := TType.GetType(TypeInfo(TID)).QualifiedName;
  RegisterDefaultMethods;
  OnInvoke :=
    procedure(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue)
    begin
      Result := DoOnInvoke(Method, Args);
    end;
end;

function TProxyRepository<T, TID>.DoOnInvoke(Method: TRttiMethod;
  const Args: TArray<TValue>): TValue;
var
  LMethodRef: TMethodReference;
  LMethodSignature: string;
  LItems: IList<T>;
  LConstArray: TArray<TVarRec>;
  LArgs: TArray<TValue>;
  LPage, LPageSize: Integer;
begin
  LMethodSignature := TRttiExplorer.GetMethodSignature(Method);
  if fDefaultMethods.TryGetValue(LMethodSignature, LMethodRef) then
    Result := LMethodRef(Args)
  else
  begin
    case Method.ReturnType.TypeKind of
      tkInteger, tkInt64: Result := fRepository.Count;
      tkClass, tkClassRef, tkPointer:
      begin
        LConstArray := FromArgsToConstArray(Args);
        try
          LItems := fRepository.Query(TRttiExplorer.GetQueryTextFromMethod(Method), LConstArray);
          (LItems as ICollectionOwnership).OwnsObjects := False;
          Result := LItems.FirstOrDefault;
        finally
          FinalizeVarRecArray(LConstArray);
        end;
      end;
      tkInterface:
      begin
        if TUtils.IsPageType(Method.ReturnType.Handle) then
        begin
          // last two arguments should be page and pagesize
          LArgs := GetPageArgs(Args, LPage, LPageSize);
          LConstArray := FromArgsToConstArray(LArgs);
          try
            Result := TValue.From<IDBPage<T>>(fSession.Page<T>(LPage, LPageSize, TRttiExplorer.GetQueryTextFromMethod(Method), LConstArray));
          finally
            FinalizeVarRecArray(LConstArray);
          end;
        end
        else
        begin
          LConstArray := FromArgsToConstArray(Args);
          try
            Result := TValue.From<IList<T>>(fRepository.Query(TRttiExplorer.GetQueryTextFromMethod(Method), LConstArray));
          finally
            FinalizeVarRecArray(LConstArray);
          end;
        end;
      end
      else
        raise EORMUnsupportedType.CreateFmt('Unknown method (%s) return type: %s', [Method.ToString, Method.ReturnType.ToString]);
    end;
  end;
end;

procedure TProxyRepository<T, TID>.RegisterDefaultMethods;
begin
  RegisterMethod('function Count: Int64', function(const Args: TArray<TValue>): TValue
    begin
      Result := fRepository.Count;
    end);
  RegisterMethod(Format('function Page(APage: Integer; AItemsPerPage: Integer): IDBPage<%s>', [fQualifiedTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      Result := TValue.From<IDBPage<T>>(fRepository.Page(Args[1].AsInteger, Args[2].AsInteger));
    end);
  RegisterMethod(Format('function FindOne(const AID: %s): %s', [fIdTypeName, fTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      Result := fRepository.FindOne(Args[1].AsType<TID>);
    end);
  RegisterMethod(Format('function FindAll: IList<%s>', [fQualifiedTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      Result := TValue.From<IList<T>>(fRepository.FindAll);
    end);
  RegisterMethod(Format('function Exists(const AId: %s): Boolean', [fIdTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      Result := fRepository.Exists(Args[1].AsType<TID>);
    end);
  RegisterMethod(Format('procedure Insert(AEntity: %s)', [fTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      fRepository.Insert(Args[1].AsType<T>);
    end);
  RegisterMethod(Format('procedure Insert(AEntities: ICollection<%s>)', [fQualifiedTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      fRepository.Insert(Args[1].AsInterface as ICollection<T>);
    end);
  RegisterMethod(Format('function Save(AEntity: %0:S): %0:S', [fTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      Result := fRepository.Save(Args[1].AsType<T>);
    end);
  RegisterMethod(Format('function Save(AEntities: ICollection<%0:S>): ICollection<%0:S>', [fQualifiedTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      Result := TValue.From<ICollection<T>>(fRepository.Save(Args[1].AsInterface as ICollection<T>));
    end);
  RegisterMethod(Format('procedure SaveCascade(AEntity: %s)', [fTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      fRepository.SaveCascade(Args[1].AsType<T>);
    end);
  RegisterMethod(Format('procedure Delete(AEntity: %s)', [fTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      fRepository.Delete(Args[1].AsType<T>);
    end);
  RegisterMethod(Format('procedure Delete(AEntities: ICollection<%s>)', [fQualifiedTypeName]),
    function(const Args: TArray<TValue>): TValue
    begin
      fRepository.Delete(Args[1].AsInterface as ICollection<T>);
    end);
  RegisterMethod('procedure DeleteAll',
    function(const Args: TArray<TValue>): TValue
    begin
      fRepository.DeleteAll;
    end);
  RegisterMethod(Format('function Query(const AQuery: string; const AParams: TVarRec): IList<%s>', [fQualifiedTypeName]),
    function(const Args: TArray<TValue>): TValue
    var
      LConstArray: TArray<TVarRec>;
    begin
      LConstArray := FromArgsToConstArray(Copy(Args, 1));
      try
        Result := TValue.From<IList<T>>(fRepository.Query(Args[1].AsString, LConstArray));
      finally
        FinalizeVarRecArray(LConstArray);
      end;
    end);
  RegisterMethod('function Execute(const AQuery: string; const AParams: TVarRec): NativeUInt',
    function(const Args: TArray<TValue>): TValue
    var
      LConstArray: TArray<TVarRec>;
    begin
      LConstArray := FromArgsToConstArray(Copy(Args, 1));
      try
        Result := fRepository.Execute(Args[1].AsString, LConstArray);
      finally
        FinalizeVarRecArray(LConstArray);
      end;
    end);
end;

procedure TProxyRepository<T, TID>.RegisterMethod(
  const AMethodSignature: string; AMethodRef: TMethodReference);
begin
  fDefaultMethods.AddOrSetValue(AMethodSignature, AMethodRef);
end;

end.