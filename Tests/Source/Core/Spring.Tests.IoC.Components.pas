{***************************************************************************}
{                                                                           }
{           Delphi Spring Framework                                         }
{                                                                           }
{           Copyright (C) 2009-2010 Delphi Spring Framework                 }
{                                                                           }
{           http://delphi-spring-framework.googlecode.com                   }
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

unit Spring.Tests.IoC.Components;

interface

uses
  SysUtils,
  TestFramework,
  Spring,
  Spring.IoC.Core;

type
  {$REGION 'INameService, TNameService and TAnotherNameService'}

  INameService = interface
    ['{96163ACB-E3FD-412E-A9A6-5084CE1BC25A}']
    function GetName: string;
    property Name: string read GetName;
  end;

  TNameService = class(TInterfacedObject, INameService, IInterface)
  private
    fName: string;
    function GetName: string;
  public
    constructor Create;
    property Name: string read GetName;
  public
    const NameString: string = 'Name';
  end;

  TAnotherNameService = class(TInterfacedObject, INameService, IInterface)
  private
    fName: string;
    function GetName: string;
  public
    constructor Create;
    property Name: string read GetName;
  public
    const NameString: string = 'Another Name';
  end;

  {$ENDREGION}


  {$REGION 'TAgeServiceBase and TAgeServiceImpl'}

  TAgeServiceBase = class abstract
  protected
    function GetAge: Integer; virtual; abstract;
  public
    property Age: Integer read GetAge;
  end;

  TAgeServiceImpl = class(TAgeServiceBase)
  private
    fAge: Integer;
  protected
    function GetAge: Integer; override;
  public
    constructor Create;
    const DefaultAge: Integer = 28;
  end;

  {$ENDREGION}


  IAgeService = interface
    ['{E859410D-9980-47A9-8EA7-120C35F6BDCC}']
    function GetAge: Integer;
    property Age: Integer read GetAge;
  end;

  TNameAgeComponent = class(TInterfacedObject, INameService, IAgeService)
  private
    function GetName: string;
    function GetAge: Integer;
  public
    property Name: string read GetName;
    property Age: Integer read GetAge;
    const NameString: string = 'Complex';
    const DefaultAge: Integer = 100;
  end;

  IAnotherService = interface
    ['{6BE967C9-C4EE-40FD-805D-B48320A0F510}']
  end;

  TInitializableComponent = class(TInterfacedObject, IInitializable, IAnotherService)
  private
    fIsInitialized: Boolean;
  public
    procedure Initialize;
    property IsInitialized: Boolean read fIsInitialized;
  end;


  {$REGION 'TBootstrapComponent'}

  TBootstrapComponent = class
  private
    fNameService: INameService;
    fAgeService: TAgeServiceBase;
  public
    constructor Create(const nameService: INameService); overload;
    constructor Create(const nameService: INameService; ageService: TAgeServiceBase); overload;
    property NameService: INameService read fNameService;
    property AgeService: TAgeServiceBase read fAgeService;
  end;

  {$ENDREGION}


  {$REGION 'TPrimitiveComponent'}

  IPrimitive = interface
    ['{827709E0-7B09-43E7-A438-055E9800B4CA}']
    function GetNameService: INameService;
    function GetIntegerArg: Integer;
    function GetStringArg: string;
    property NameService: INameService read GetNameService;
    property IntegerArg: Integer read GetIntegerArg;
    property StringArg: string read GetStringArg;
  end;

  TPrimitiveComponent = class(TInterfacedObject, IPrimitive, IInterface)
  private
    fNameService: INameService;
    fIntegerArg: Integer;
    fStringArg: string;
    fIntegerProperty: Integer;
    fStringProperty: string;
  protected
    { IPrimitive }
    function GetNameService: INameService;
    function GetIntegerArg: Integer;
    function GetStringArg: string;
  public
    constructor Create(const nameService: INameService; integerArg: Integer;
      const stringArg: string);
    property NameService: INameService read fNameService;
    property IntegerArg: Integer read fIntegerArg;
    property StringArg: string read fStringArg;
    property IntegerProperty: Integer read fIntegerProperty;
    property StringProperty: string read fStringProperty;
  end;

  {$ENDREGION}


  {$REGION 'IInjectionExplorer and TInjectionServiceImpl'}

  IInjectionExplorer = interface
    ['{47439E73-A21E-48DB-A1C9-0A14639FFC01}']
    {$REGION 'Property Getters and Setters'}

    function GetConstructorInjection: INameService;
    function GetPropertyInjection: INameService;
    function GetMethodInjection: INameService;
    function GetFieldInjection: INameService;

    {$ENDREGION}

    property ConstructorInjection: INameService read GetConstructorInjection;
    property PropertyInjection: INameService read GetPropertyInjection;
    property MethodInjection: INameService read GetMethodInjection;
    property FieldInjection: INameService read GetFieldInjection;
  end;

  TInjectionExplorer = class(TInterfacedObject, IInjectionExplorer)
  private
    fConstructorInjection: INameService;
    fPropertyInjection: INameService;
    fMethodInjection: INameService;
    fFieldInjection: INameService;
  protected
    { Implements IInjectionService }
    function GetConstructorInjection: INameService;
    function GetPropertyInjection: INameService;
    function GetMethodInjection: INameService;
    function GetFieldInjection: INameService;
  public
    constructor Create(const service: INameService); overload;
    constructor Create(const nameService: INameService; const anotherService: INameService); overload;
    procedure SetMethodInjection(const value: INameService);
    property PropertyInjection: INameService read fPropertyInjection write fPropertyInjection;
  end;

  TInjectionExplorerComponent = class(TInterfacedObject, IInjectionExplorer)
  private
    fConstructorInjection: INameService;
    fPropertyInjection: INameService;
    fMethodInjection: INameService;
    [Injection]
    fFieldInjection: INameService;
  protected
    { Implements IInjectionService }
    function GetConstructorInjection: INameService;
    function GetPropertyInjection: INameService;
    function GetMethodInjection: INameService;
    function GetFieldInjection: INameService;
  public
    [Injection]
    constructor Create(const service: INameService); overload;
    constructor Create(const nameService: INameService; const anotherService: INameService); overload;
    [Injection]
    procedure SetMethodInjection(const value: INameService);
    [Injection]
    property PropertyInjection: INameService read fPropertyInjection write fPropertyInjection;
  end;

  TInjectionComponent = class(TInterfacedObject, IInjectionExplorer)
  private
    fConstructorInjection: INameService;
    fPropertyInjection: INameService;
    fMethodInjection: INameService;
    [Injection('default')]
    fFieldInjection: INameService;
  protected
    { Implements IInjectionService }
    function GetConstructorInjection: INameService;
    function GetPropertyInjection: INameService;
    function GetMethodInjection: INameService;
    function GetFieldInjection: INameService;
  public
    [Injection]
    constructor Create([Injection('default')] const service: INameService); overload;
    constructor Create(const nameService: INameService; const anotherService: INameService); overload;
    [Injection]
    procedure SetMethodInjection([Injection('another')]const value: INameService);
    [Injection('another')]
    property PropertyInjection: INameService read fPropertyInjection write fPropertyInjection;
  end;

  {$ENDREGION}


  {$REGION 'Non-Guid Interface Services and Implementations'}

  INonGuid = interface
  end;

  TNonGuid = class(TInterfacedObject, INonGuid)
  end;

  INonGuid<T> = interface
  end;

  TNonGuid<T> = class(TInterfacedObject, INonGuid<T>, IInterface)
  end;

  {$ENDREGION}


  {$REGION 'Circular Dependency Services & Implementations ("Chicken-Egg")'}

  // IChicken <== TChicken --> IEgg <== TEgg --> IChicken

  IChicken = interface
    ['{88C4F5E9-85B4-43D4-9265-0A9FAD099055}']
  end;

  IEgg = interface
    ['{9BFC513F-635C-42CD-B29D-9E66D47882A6}']
  end;

  TChicken = class(TInterfacedObject, IChicken)
  private
    fEgg: IEgg;
  public
    constructor Create(const egg: IEgg);
  end;

  TEgg = class(TInterfacedObject, IEgg)
  private
    fChicken: IChicken;
  public
    constructor Create(const chicken: IChicken);
  end;

  TCircularDependencyChicken = class(TInterfacedObject, IChicken)
  private
    fChicken: IChicken;
  public
    constructor Create(const chicken: IChicken);
  end;

  {$ENDREGION}


implementation

{ TNameService }

constructor TNameService.Create;
begin
  inherited Create;
  fName := NameString;
end;

function TNameService.GetName: string;
begin
  Result := fName;
end;

{ TAnotherNameService }

constructor TAnotherNameService.Create;
begin
  inherited Create;
  fName := NameString;
end;

function TAnotherNameService.GetName: string;
begin
  Result := fName;
end;

{ TAgeServiceImpl }

constructor TAgeServiceImpl.Create;
begin
  inherited Create;
  fAge := DefaultAge;
end;

function TAgeServiceImpl.GetAge: Integer;
begin
  Result := fAge;
end;

{ TBootstrapComponent }

constructor TBootstrapComponent.Create(const nameService: INameService);
begin
  TArgument.CheckNotNull(nameService, 'nameService');
  inherited Create;
  fNameService := nameService;
end;

constructor TBootstrapComponent.Create(const nameService: INameService;
  ageService: TAgeServiceBase);
begin
  TArgument.CheckNotNull(nameService, 'nameService');
  TArgument.CheckNotNull(ageService, 'ageService');
  inherited Create;
  fNameService := nameService;
  fAgeService := ageService;
end;

{ TPrimitiveComponent }

constructor TPrimitiveComponent.Create(const nameService: INameService;
  integerArg: Integer; const stringArg: string);
begin
  TArgument.CheckNotNull(nameService, 'nameService');
  inherited Create;
  fNameService := nameService;
  fIntegerArg := integerArg;
  fStringArg := stringArg;
end;

function TPrimitiveComponent.GetNameService: INameService;
begin
  Result := fNameService;
end;

function TPrimitiveComponent.GetIntegerArg: Integer;
begin
  Result := fIntegerArg;
end;

function TPrimitiveComponent.GetStringArg: string;
begin
  Result := fStringArg;
end;

{ TInjectionExplorer }

constructor TInjectionExplorer.Create(const service: INameService);
begin
  inherited Create;
  fConstructorInjection := service;
end;

constructor TInjectionExplorer.Create(const nameService: INameService;
  const anotherService: INameService);
begin
  raise Exception.Create('This constructor should not be called.');
end;

function TInjectionExplorer.GetConstructorInjection: INameService;
begin
  Result := fConstructorInjection;
end;

function TInjectionExplorer.GetPropertyInjection: INameService;
begin
  Result := fPropertyInjection;
end;

function TInjectionExplorer.GetMethodInjection: INameService;
begin
  Result := fMethodInjection;
end;

function TInjectionExplorer.GetFieldInjection: INameService;
begin
  Result := fFieldInjection;
end;

procedure TInjectionExplorer.SetMethodInjection(const value: INameService);
begin
  fMethodInjection := value;
end;

{ TInjectionExplorerComponent }

constructor TInjectionExplorerComponent.Create(const service: INameService);
begin
  inherited Create;
  fConstructorInjection := service;
end;

constructor TInjectionExplorerComponent.Create(const nameService: INameService;
  const anotherService: INameService);
begin
  raise Exception.Create('This constructor should not be called.');
end;

function TInjectionExplorerComponent.GetConstructorInjection: INameService;
begin
  Result := fConstructorInjection;
end;

function TInjectionExplorerComponent.GetPropertyInjection: INameService;
begin
  Result := fPropertyInjection;
end;

function TInjectionExplorerComponent.GetMethodInjection: INameService;
begin
  Result := fMethodInjection;
end;

function TInjectionExplorerComponent.GetFieldInjection: INameService;
begin
  Result := fFieldInjection;
end;

procedure TInjectionExplorerComponent.SetMethodInjection(const value: INameService);
begin
  fMethodInjection := value;
end;

{ TCircularDependencyChicken }

constructor TCircularDependencyChicken.Create(const chicken: IChicken);
begin
  inherited Create;
  fChicken := chicken;
end;

{ TChicken }

constructor TChicken.Create(const egg: IEgg);
begin
  inherited Create;
  fEgg := egg;
end;

{ TEgg }

constructor TEgg.Create(const chicken: IChicken);
begin
  inherited Create;
  fChicken := chicken;
end;

{ TNameAgeComponent }

function TNameAgeComponent.GetAge: Integer;
begin
  Result := TNameAgeComponent.DefaultAge;
end;

function TNameAgeComponent.GetName: string;
begin
  Result := TNameAgeComponent.NameString;
end;

{ TInjectionComponent }

constructor TInjectionComponent.Create(const service: INameService);
begin
  inherited Create;
  fConstructorInjection := service;
end;

constructor TInjectionComponent.Create(const nameService,
  anotherService: INameService);
begin
  raise Exception.Create('The constructor should not be called.');
end;

function TInjectionComponent.GetConstructorInjection: INameService;
begin
  Result := fConstructorInjection;
end;

function TInjectionComponent.GetFieldInjection: INameService;
begin
  Result := fFieldInjection;
end;

function TInjectionComponent.GetMethodInjection: INameService;
begin
  Result := fMethodInjection;
end;

function TInjectionComponent.GetPropertyInjection: INameService;
begin
  Result := fPropertyInjection;
end;

procedure TInjectionComponent.SetMethodInjection(const value: INameService);
begin
  fMethodInjection := value;
end;

{ TInitializableComponent }

procedure TInitializableComponent.Initialize;
begin
  fIsInitialized := True;
end;

end.