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

unit Spring.Mocking;

interface

uses
  Rtti,
  SysUtils,
  TypInfo,
  Spring,
  Spring.Interception,
  Spring.Times;

{$SCOPEDENUMS ON}

type
  TMockBehavior = (Dynamic, Strict);

  Times = Spring.Times.Times;

  TValue = Rtti.TValue;

  TCallInfo = record
  private
    fInvocation: IInvocation;
    fCallCount: Integer;
    function GetMethod: TRttiMethod;
    function GetArguments: TArray<TValue>;
    function GetCallCount: Integer;
  public
    constructor Create(const invocation: IInvocation; callCount: Integer);
    property Arguments: TArray<TValue> read GetArguments;
    property CallCount: Integer read GetCallCount;
    property Method: TRttiMethod read GetMethod;
  end;

  TMockAction = reference to function(const callInfo: TCallInfo): TValue;

  IWhen = interface(IInvokable)
    ['{DAD0B65B-8CEF-4513-ADE8-38E8F9AAFA9A}']
    procedure When;
    procedure WhenForAnyArgs;
  end;

  ISetup = interface(IInvokable)
    ['{0BC12D48-41FF-46D0-93B3-773EE19D75ED}']
    function Executes: IWhen; overload;
    function Executes(const action: TMockAction): IWhen; overload;

    function Raises(const exceptionClass: ExceptClass;
      const msg: string = ''): IWhen; overload;
    function Raises(const exceptionClass: ExceptClass;
      const msg: string; const args: array of const): IWhen; overload;

    function Returns(const value: TValue): IWhen; overload;
    function Returns(const values: array of TValue): IWhen; overload;
  end;

  IMock = interface(IInvokable)
    ['{7D386664-22CF-4555-B03E-61319C39BC12}']
    function GetInstance: TValue;
    function GetTypeInfo: PTypeInfo;

    function Setup: ISetup;

    procedure Received; overload;
    procedure Received(const times: Times); overload;
    procedure ReceivedWithAnyArgs; overload;
    procedure ReceivedWithAnyArgs(const times: Times); overload;

    property Instance: TValue read GetInstance;
    property TypeInfo: PTypeInfo read GetTypeInfo;
  end;

  IWhen<T> = interface(IInvokable)
    ['{4162918E-4DE6-47D6-B609-D5A17F3FBE2B}']
    function When: T;
    function WhenForAnyArgs: T;
  end;

  ISetup<T> = interface(IInvokable)
    ['{CD661866-EB29-400C-ABC8-19FC8D59FFAD}']
    function Executes: IWhen<T>; overload;
    function Executes(const action: TMockAction): IWhen<T>; overload;

    function Raises(const exceptionClass: ExceptClass;
      const msg: string = ''): IWhen<T>; overload;
    function Raises(const exceptionClass: ExceptClass;
      const msg: string; const args: array of const): IWhen<T>; overload;

    function Returns(const value: TValue): IWhen<T>; overload;
    function Returns(const values: array of TValue): IWhen<T>; overload;
  end;

  IMock<T> = interface(IInvokable)
    ['{67AD5AD2-1C23-41BA-8F5D-5C28B3C7ABF7}']
    function GetInstance: T;
    function GetTypeInfo: PTypeInfo;

    function Setup: ISetup<T>;

    function Received: T; overload;
    function Received(const times: Times): T; overload;
    function ReceivedWithAnyArgs: T; overload;
    function ReceivedWithAnyArgs(const times: Times): T; overload;

    property Instance: T read GetInstance;
    property TypeInfo: PTypeInfo read GetTypeInfo;
  end;

  EMockException = class(Exception);

  Mock<T> = record
  private
    fMock: IMock<T>;
    function GetInstance: T;
  public
    class function Create(
      behavior: TMockBehavior = TMockBehavior.Dynamic): Mock<T>; static;

    class operator Implicit(const value: IMock): Mock<T>;
    class operator Implicit(const value: Mock<T>): IMock;
    class operator Implicit(const value: Mock<T>): IMock<T>;
    class operator Implicit(const value: Mock<T>): T;

    function Setup: ISetup<T>;

    function Received: T; overload;
    function Received(const times: Times): T; overload;
    function ReceivedWithAnyArgs: T; overload;
    function ReceivedWithAnyArgs(const times: Times): T; overload;

    property Instance: T read GetInstance;
  end;

  Mock = record
  public
    class function From<T: IInterface>(const value: T): Mock<T>; static;
  end;

implementation

uses
  Spring.Helpers,
  Spring.Mocking.Core,
  Spring.Mocking.Interceptor;


{$REGION 'TCallInfo'}

constructor TCallInfo.Create(const invocation: IInvocation; callCount: Integer);
begin
  fInvocation := invocation;
  fCallCount := callCount;
end;

function TCallInfo.GetArguments: TArray<TValue>;
begin
  Result := fInvocation.Arguments;
end;

function TCallInfo.GetCallCount: Integer;
begin
  Result := fCallCount;
end;

function TCallInfo.GetMethod: TRttiMethod;
begin
  Result := fInvocation.Method;
end;

{$ENDREGION}


{$REGION 'Mock<T>'}

class function Mock<T>.Create(behavior: TMockBehavior): Mock<T>;
begin
  Result := TMock<T>.Create(behavior);
end;

class operator Mock<T>.Implicit(const value: IMock): Mock<T>;
begin
  Assert(value.TypeInfo = System.TypeInfo(T));
  Result.fMock := value as IMock<T>;
end;

class operator Mock<T>.Implicit(const value: Mock<T>): IMock;
begin
  Result := value.fMock as IMock;
end;

class operator Mock<T>.Implicit(const value: Mock<T>): IMock<T>;
begin
  Result := value.fMock;
end;

class operator Mock<T>.Implicit(const value: Mock<T>): T;
begin
  Result := value.fMock.Instance;
end;

function Mock<T>.GetInstance: T;
begin
  Result := fMock.Instance;
end;

function Mock<T>.Setup: ISetup<T>;
begin
  Result := fMock.Setup;
end;

function Mock<T>.Received: T;
begin
  Result := fMock.Received;
end;

function Mock<T>.Received(const times: Times): T;
begin
  Result := fMock.Received(times);
end;

function Mock<T>.ReceivedWithAnyArgs: T;
begin
  Result := fMock.ReceivedWithAnyArgs;
end;

function Mock<T>.ReceivedWithAnyArgs(const times: Times): T;
begin
  Result := fMock.ReceivedWithAnyArgs(times);
end;

{$ENDREGION}


{$REGION 'Mock'}

class function Mock.From<T>(const value: T): Mock<T>;
var
  accessor: IProxyTargetAccessor;
  proxy: TValue;
  mock: TMock;
begin
  if not Supports(PInterface(@value)^, IProxyTargetAccessor, accessor) then
    raise EMockException.Create('value is not a mock');
  TValue.Make(@value, System.TypeInfo(T), proxy);
  mock := TMock<T>.NewInstance as TMock;
  mock.Create(TypeInfo(T), accessor.GetInterceptors.First(
    function(const interceptor: IInterceptor): Boolean
    begin
      Result := (interceptor as TObject) is TMockInterceptor
    end) as TMockInterceptor, proxy);
  Result.fMock := mock as IMock<T>;
end;

{$ENDREGION}


end.