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

unit Spring.Container.AutoMockExtension;

interface

uses
  Rtti,
  TypInfo,
  Spring.Container.Core,
  Spring.Container.Extensions;

type
  TAutoMockExtension = class(TContainerExtension)
  protected
    procedure Initialize; override;
  end;

  TAutoMockResolver = class(TInterfacedObject, ISubDependencyResolver)
  private
    fKernel: IKernel;
    procedure EnsureMockRegistered(const mockedType: TRttiType);
  public
    constructor Create(const kernel: IKernel);

    function CanResolve(const context: ICreationContext;
      const model: TComponentModel; const dependency: TDependencyModel;
      const argument: TValue): Boolean;
    function Resolve(const context: ICreationContext;
      const model: TComponentModel; const dependency: TDependencyModel;
      const argument: TValue): TValue;
  end;

implementation

uses
  SysUtils,
  Spring,
  Spring.Container.Common,
  Spring.Reflection,
  Spring.Helpers,
  Spring.Mocking,
  Spring.Mocking.Core;


{$REGION 'TAutoMockExtension'}

procedure TAutoMockExtension.Initialize;
begin
  Kernel.Resolver.AddSubResolver(
    TAutoMockResolver.Create(Kernel) as ISubDependencyResolver);
end;

{$ENDREGION}


{$REGION 'TAutoMockResolver'}

constructor TAutoMockResolver.Create(const kernel: IKernel);
begin
  inherited Create;
  fKernel := kernel;
end;

function TAutoMockResolver.CanResolve(const context: ICreationContext;
  const model: TComponentModel; const dependency: TDependencyModel;
  const argument: TValue): Boolean;
var
  mockedType: TRttiType;
begin
  if dependency.TargetType.IsGenericType
    and SameText(dependency.TargetType.GetGenericTypeDefinition, 'IMock<>') then
  begin
    mockedType := dependency.TargetType.GetGenericArguments[0];
    if mockedType.IsInterface and not mockedType.IsType<IInterface> then
      Exit(True);
  end;

  if dependency.TargetType.IsInterface
    and not fKernel.Registry.HasService(dependency.TypeInfo) then
    Exit(True);

  Result := False;
end;

procedure TAutoMockResolver.EnsureMockRegistered(const mockedType: TRttiType);
var
  mockName: string;
  mockModel: TComponentModel;
begin
  mockName := 'IMock<' + mockedType.DefaultName + '>';
  if not fKernel.Registry.HasService(mockName) then
  begin
    // only for interfaces
    mockModel := fKernel.Registry.RegisterComponent(TMock<IInterface>.ClassInfo);
    fKernel.Registry.RegisterService(mockModel, TypeInfo(IMock<IInterface>), mockName);
    mockModel.ActivatorDelegate :=
      function: TValue
      var
        mock: TMock;
      begin
        mock := TMock<IInterface>.NewInstance as TMock;
        mock.Create(mockedType.Handle);
        Result := mock;
      end;
    mockModel.LifetimeType := TLifetimeType.Singleton;
    fKernel.Builder.Build(mockModel);
  end;
end;

function TAutoMockResolver.Resolve(const context: ICreationContext;
  const model: TComponentModel; const dependency: TDependencyModel;
  const argument: TValue): TValue;
var
  mockDirectly: Boolean;
  mockType: TRttiType;
  mockName: string;
begin
  mockDirectly := dependency.TargetType.IsGenericType
    and SameText(dependency.TargetType.GetGenericTypeDefinition, 'IMock<>');
  if mockDirectly then
  begin
    mockType := dependency.TargetType.GetGenericArguments[0];
    mockName := dependency.Name;
  end
  else
  begin
    mockType := dependency.TargetType;
    mockName := 'IMock<' + dependency.TargetType.DefaultName + '>';
  end;
  EnsureMockRegistered(mockType);
  Result := (fKernel as IKernelInternal).Resolve(mockName);
  if mockDirectly then
  begin
    TValueData(Result).FTypeInfo := dependency.TargetType.Handle;
    Exit;
  end
  else
    Result := (Result.AsType<IMock<IInterface>> as IMock).Instance;
end;

{$ENDREGION}


end.
