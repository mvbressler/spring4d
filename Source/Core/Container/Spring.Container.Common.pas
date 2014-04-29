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

unit Spring.Container.Common;

interface

uses
  SysUtils,
  Spring;


{$SCOPEDENUMS ON}

type

  {$REGION 'Factory interfaces'}

  {$M+}
  IFactory<TResult> = interface(TFunc<TResult>)
    function Invoke: TResult;
  end;

  IFactory<T,TResult> = interface(TFunc<T,TResult>)
    function Invoke(Arg: T): TResult;
  end;

  IFactory<T1,T2,TResult> = interface(TFunc<T1,T2,TResult>)
    function Invoke(Arg1: T1; Arg2: T2): TResult;
  end;

  IFactory<T1,T2,T3,TResult> = interface(TFunc<T1,T2,T3,TResult>)
    function Invoke(Arg1: T1; Arg2: T2; Arg3: T3): TResult;
  end;

  IFactory<T1,T2,T3,T4,TResult> = interface(TFunc<T1,T2,T3,T4,TResult>)
    function Invoke(Arg1: T1; Arg2: T2; Arg3: T3; Arg4: T4): TResult;
  end;
  {$M-}

  {$ENDREGION}


  {$REGION 'Lifetime Type & Attributes'}

  ///	<summary>
  ///	  Lifetime Type Enumeration.
  ///	</summary>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="PooledAttribute" />
  TLifetimeType = (
    ///	<summary>
    ///	  Unknown lifetime type.
    ///	</summary>
    Unknown,

    ///	<summary>
    ///	  Single instance.
    ///	</summary>
    Singleton,

    ///	<summary>
    ///	  Different instances.
    ///	</summary>
    Transient,

    ///	<summary>
    ///	  Every thread has a single instance.
    ///	</summary>
    SingletonPerThread,

    ///	<summary>
    ///	  Instances are transient except that they are recyclable.
    ///	</summary>
    Pooled,

    ///	<summary>
    ///	  Customized lifetime type.
    ///	</summary>
    Custom
  );

  ///	<summary>
  ///	  Defines if type is using reference counting
  ///	</summary>
  TRefCounting = (
    ///	<summary>
    ///	  Container decides (Yes for TInterfacedObject descendants, No for others)
    ///	</summary>
    Unknown,

    ///	<summary>
    ///	  Type is using reference counting
    ///	</summary>
    True,

    ///	<summary>
    ///	  Type is not using reference counting
    ///	</summary>
    False
  );

  ///	<summary>
  ///	  Represents an abstract lifetime attribute class base.
  ///	</summary>
  LifetimeAttributeBase = class abstract(TCustomAttribute)
  private
    fLifetimeType: TLifetimeType;
  public
    constructor Create(lifetimeType: TLifetimeType);
    property LifetimeType: TLifetimeType read fLifetimeType;
  end;

  ///	<summary>
  ///	  Applies this attribute when a component shares the single instance.
  ///	</summary>
  ///	<remarks>
  ///	  When this attribute is applied to a component, the shared instance will
  ///	  be returned whenever get the implementation of a service.
  ///	</remarks>
  ///	<example>
  ///	  <code lang="Delphi">
  ///	[Singleton]
  ///	TEmailSender = class(TInterfacedObject, IEmailSender)
  ///	//...
  ///	end;
  ///	  </code>
  ///	</example>
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="PooledAttribute" />
  ///	<seealso cref="TLifetimeType" />
  SingletonAttribute = class(LifetimeAttributeBase)
  public
    constructor Create;
  end;

  ///	<summary>
  ///	  Represents that a new instance of the component will be created when
  ///	  requested.
  ///	</summary>
  ///	<remarks>
  ///	  <note type="note">
  ///	    This attribute is the default option.
  ///	  </note>
  ///	</remarks>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="PooledAttribute" />
  ///	<seealso cref="TLifetimeType" />
  TransientAttribute = class(LifetimeAttributeBase)
  public
    constructor Create;
  end;

  ///	<summary>
  ///	  Applies this attribute when a component shares the single instance per
  ///	  thread.
  ///	</summary>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="PooledAttribute" />
  ///	<seealso cref="TLifetimeType" />
  SingletonPerThreadAttribute = class(LifetimeAttributeBase)
  public
    constructor Create;
  end;

  ///	<summary>
  ///	  Represents that the target component can be pooled.
  ///	</summary>
  ///	<seealso cref="SingletonAttribute" />
  ///	<seealso cref="TransientAttribute" />
  ///	<seealso cref="SingletonPerThreadAttribute" />
  ///	<seealso cref="TLifetimeType" />
  PooledAttribute = class(LifetimeAttributeBase)
  private
    fMinPoolsize: Integer;
    fMaxPoolsize: Integer;
  public
    constructor Create(minPoolSize, maxPoolSize: Integer);
    property MinPoolsize: Integer read fMinPoolsize;
    property MaxPoolsize: Integer read fMaxPoolsize;
  end {$IFDEF CPUARM}experimental{$ENDIF};

  ///	<summary>
  ///	  Applies the <c>InjectAttribute</c> to injectable instance members of a
  ///	  class. e.g. constructors, methods, properties and even fields. Also
  ///	  works on parameters of a method.
  ///	</summary>
  ///	<seealso cref="ImplementsAttribute" />
  InjectAttribute = class(TCustomAttribute)
  private
    fValue: TValue;
    function GetHasValue: Boolean;
  public
    constructor Create; overload;
    constructor Create(const value: string); overload;
    constructor Create(value: Integer); overload;
    constructor Create(value: Extended); overload;
    constructor Create(value: Int64); overload;
    constructor Create(value: Boolean); overload;
    property Value: TValue read fValue;
    property HasValue: Boolean read GetHasValue;
  end;

  ///	<summary>
  ///	  Applies this attribute to tell the IoC container which service is
  ///	  implemented by the target component. In addition, a service name can be
  ///	  specified.
  ///	</summary>
  ///	<remarks>
  ///	  <note type="note">
  ///	    This attribute can be specified more than once.
  ///	  </note>
  ///	</remarks>
  ///	<example>
  ///	  <code lang="Delphi">
  ///	[Implements(TypeInfo(IEmailSender))]
  ///	TRegularEmailSender = class(TInterfacedObject, IEmailSender)
  ///	end;
  ///	[Implements(TypeInfo(IEmailSender), 'mock-email-sender')]
  ///	TMockEmailSender = class(TInterfacedObject, IEmailSender)
  ///	end;
  ///	  </code>
  ///	</example>
  ///	<seealso cref="InjectAttribute" />
  ImplementsAttribute = class(TCustomAttribute)
  private
    fServiceType: PTypeInfo;
    fName: string;
  public
    constructor Create(serviceType: PTypeInfo); overload;
    constructor Create(serviceType: PTypeInfo; const name: string); overload;
    property ServiceType: PTypeInfo read fServiceType;
    property Name: string read fName;
  end;

  {$ENDREGION}


  {$REGION 'Lifecycle Interfaces'}

  ///	<summary>
  ///	  Lifecycle interface. If a component implements this interface, the
  ///	  dependency injection container will invoke the <c>Initialize</c> method
  ///	  when initiating an instance of the component.
  ///	</summary>
  ///	<seealso cref="IStartable" />
  ///	<seealso cref="IRecyclable" />
  ///	<seealso cref="IDisposable" />
  IInitializable = interface
    ['{A36BB399-E592-4DFB-A091-EDBA3BE0648B}']

    ///	<summary>
    ///	  Initializes the component.
    ///	</summary>
    procedure Initialize;
  end;

  ///	<summary>
  ///	  Lifecycle interface. Represents that the component can be started and
  ///	  stopped.
  ///	</summary>
  ///	<seealso cref="IInitializable" />
  ///	<seealso cref="IRecyclable" />
  ///	<seealso cref="IDisposable" />
  IStartable = interface
    ['{8D0252A1-7993-44AA-B0D9-326019B58E78}']
    procedure Start;
    procedure Stop;
  end;

  ///	<summary>
  ///	  Lifecycle interface. Only called for components that belongs to a pool
  ///	  when the component comes back to the pool.
  ///	</summary>
  ///	<seealso cref="IInitializable" />
  ///	<seealso cref="IStartable" />
  ///	<seealso cref="IDisposable" />
  IRecyclable = interface
    ['{85114F41-70E5-4AF4-A375-E445D4619E4D}']
    procedure Recycle;
  end;

  ///	<summary>
  ///	  Lifecycle interface. If the component implements this interface, all
  ///	  resources will be deallocate by calling the <c>Dispose</c> method.
  ///	</summary>
  ///	<seealso cref="IInitializable" />
  ///	<seealso cref="IStartable" />
  ///	<seealso cref="IRecyclable" />
  IDisposable = interface
    ['{6708F9BF-0237-462F-AFA2-DF8EF21939EB}']
    procedure Dispose;
  end;

  ///	<summary>
  ///	  Lifecycle interface. Implement this interface on a class that does not
  ///	  inherit from TInterfacedObject to make it compatible with pooling.
  ///	</summary>
  IRefCounted = interface
    ['{8779F9E7-2311-44AB-94A6-6BADE93551FF}']
    function GetRefCount: Integer;
    property RefCount: Integer read GetRefCount;
  end;

  {$ENDREGION}


implementation


{$REGION 'Attributes'}

{ LifetimeAttributeBase }

constructor LifetimeAttributeBase.Create(lifetimeType: TLifetimeType);
begin
  inherited Create;
  fLifetimeType := lifetimeType;
end;

{ SingletonAttribute }

constructor SingletonAttribute.Create;
begin
  inherited Create(TLifetimeType.Singleton);
end;

{ TransientAttribute }

constructor TransientAttribute.Create;
begin
  inherited Create(TLifetimeType.Transient);
end;

{ SingletonPerThreadAttribute }

constructor SingletonPerThreadAttribute.Create;
begin
  inherited Create(TLifetimeType.SingletonPerThread);
end;

{ PooledAttribute }

constructor PooledAttribute.Create(minPoolSize, maxPoolSize: Integer);
begin
  inherited Create(TLifetimeType.Pooled);
  fMinPoolsize := minPoolSize;
  fMaxPoolsize := maxPoolsize;
end;

{ InjectAttribute }

constructor InjectAttribute.Create;
begin
  inherited Create;
  fValue := TValue.Empty;
end;

constructor InjectAttribute.Create(const value: string);
begin
  inherited Create;
  fValue := value;
end;

constructor InjectAttribute.Create(value: Integer);
begin
  inherited Create;
  fValue := value;
end;

constructor InjectAttribute.Create(value: Extended);
begin
  inherited Create;
  fValue := value;
end;

constructor InjectAttribute.Create(value: Int64);
begin
  inherited Create;
  fValue := value;
end;

constructor InjectAttribute.Create(value: Boolean);
begin
  inherited Create;
  fValue := value;
end;

function InjectAttribute.GetHasValue: Boolean;
begin
  Result := not fValue.IsEmpty;
end;

{ ImplementsAttribute }

constructor ImplementsAttribute.Create(serviceType: PTypeInfo);
begin
  Create(serviceType, '');
end;

constructor ImplementsAttribute.Create(serviceType: PTypeInfo;
  const name: string);
begin
  inherited Create;
  fServiceType := serviceType;
  fName := name;
end;

{$ENDREGION}


end.