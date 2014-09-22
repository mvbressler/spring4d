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

unit Spring.Persistence.Criteria;

{$I Spring.inc}

interface

uses
  Spring.Persistence.Core.Interfaces,
  Spring.Persistence.Core.Session,
  Spring.Persistence.Criteria.Abstract;

type
  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Implementation of <c>ICriteria&lt;T&gt;</c> interface.
  ///	</summary>
  {$ENDREGION}
  TCriteria<T: class, constructor> = class(TAbstractCriteria<T>)
  public
    constructor Create(ASession: TSession); reintroduce;
    destructor Destroy; override;
  end;

implementation

{ TCriteria }

constructor TCriteria<T>.Create(ASession: TSession);
begin
  inherited Create(ASession);
end;

destructor TCriteria<T>.Destroy;
begin
  inherited Destroy;
end;

end.
