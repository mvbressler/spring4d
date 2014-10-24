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

unit Spring.Container.ProxyFactory;

interface

uses
  Spring,
  Spring.Collections,
  Spring.Container.Core,
  Spring.Interception;

type
  TProxyFactory = class(TInterfacedObject, IProxyFactory)
  private
    fKernel: IKernel;
    fGenerator: TProxyGenerator;
    fSelectors: IList<IModelInterceptorsSelector>;
  protected
    function GetInterceptorsFor(const model: TComponentModel): TArray<TInterceptorReference>;
    function ObtainInterceptors(const model: TComponentModel): TArray<IInterceptor>;
  public
    constructor Create(const kernel: IKernel);
    destructor Destroy; override;

    procedure AddInterceptorSelector(const selector: IModelInterceptorsSelector);

    function CreateInstance(const context: ICreationContext;
      const instance: TValue; const model: TComponentModel;
      const constructorArguments: array of TValue): TValue;
  end;

implementation

uses     
  SysUtils;


{$REGION 'TProxyFactory'}

constructor TProxyFactory.Create(const kernel: IKernel);
begin
  inherited Create;
  fKernel := kernel;
  fGenerator := TProxyGenerator.Create;
  fSelectors := TCollections.CreateList<IModelInterceptorsSelector>;
end;

destructor TProxyFactory.Destroy;
begin
  fGenerator.Free;
  inherited;
end;

procedure TProxyFactory.AddInterceptorSelector(
  const selector: IModelInterceptorsSelector);
begin
  fSelectors.Add(selector);
end;

function TProxyFactory.CreateInstance(const context: ICreationContext;
  const instance: TValue; const model: TComponentModel;
  const constructorArguments: array of TValue): TValue;
var
  interceptors: TArray<IInterceptor>;
  intf: IInterface;
begin
  interceptors := ObtainInterceptors(model);
  if Assigned(interceptors) then
  begin
    Supports(fGenerator.CreateInterfaceProxyWithTarget(
      instance.TypeInfo, instance.AsInterface, interceptors),
      instance.TypeData.Guid, intf);
    TValue.Make(@intf, instance.TypeInfo, Result);
  end
  else
    Result := instance;
end;

function TProxyFactory.GetInterceptorsFor(
  const model: TComponentModel): TArray<TInterceptorReference>;
var
  interceptors: TArray<TInterceptorReference>;
  selector: IModelInterceptorsSelector;
begin
  interceptors := model.Interceptors.ToArray;
  for selector in fSelectors do
    if selector.HasInterceptors(model) then
      interceptors := selector.SelectInterceptors(model, interceptors);
  Result := interceptors;
end;

function TProxyFactory.ObtainInterceptors(
  const model: TComponentModel): TArray<IInterceptor>;
var
  interceptorRef: TInterceptorReference;
  interceptors: IList<IInterceptor>;
  interceptor: TValue;
begin
  interceptors := TCollections.CreateList<IInterceptor>;
  for interceptorRef in GetInterceptorsFor(model) do
  begin
    if Assigned(interceptorRef.TypeInfo) then
      interceptor := (fKernel as IKernelInternal).Resolve(interceptorRef.TypeInfo)
    else
      interceptor := (fKernel as IKernelInternal).Resolve(interceptorRef.Name);
    interceptors.Add(interceptor.AsInterface as IInterceptor);
  end;
  Result := interceptors.ToArray;
end;

{$ENDREGION}


end.
