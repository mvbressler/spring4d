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

unit Spring.Tests.Collections;

{$I Spring.inc}

interface

uses
  Classes,
  Generics.Collections,
  TestFramework,
  Spring.TestUtils,
  Spring,
  Spring.Collections,
  Spring.Collections.LinkedLists,
  Spring.Collections.Lists;

type
  TTestEmptyHashSet = class(TTestCase)
  private
    fSet: ISet<Integer>;
    fEmpty: ISet<Integer>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestEmpty;
    procedure TestAddDuplications;
    procedure TestExceptWith;
    procedure TestIntersectWith;
    procedure TestUnionWith;
    procedure TestSetEquals;
  end;

  TTestNormalHashSet = class(TTestCase)
  private
    fSet1: ISet<Integer>;
    fSet2: ISet<Integer>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure CheckSet(const collection: ISet<Integer>; const values: array of Integer);
  published
    procedure TestExceptWith;
    procedure TestIntersectWith;
    procedure TestIntersectWithList;
    procedure TestUnionWith;
    procedure TestSetEquals;
    procedure TestSetEqualsList;
    procedure TestIsSubsetOf;
    procedure TestIsSupersetOf;
    procedure TestOverlaps;
    procedure TestExtract;
  end;

  TTestIntegerList = class(TTestCase)
  private
    SUT: IList<integer>;
    procedure SimpleFillList;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure TestListRemove;  // Empty
  published
    procedure TestListIsInitializedEmpty;
    procedure TestListCountWithAdd;
    procedure TestListCountWithInsert;
    procedure TestListInsertBetween;
    procedure TestListInsertBeginning;
    procedure TestListSimpleDelete;
    procedure TestListMultipleDelete;
    procedure TestListSimpleExchange;
    procedure TestListReverse;
    procedure TestListSort;
    procedure TestListIndexOf;
    procedure TestLastIndexOf;
    procedure TestListMove;
    procedure TestListClear;
    procedure TestListLargeDelete;
    procedure TestQueryInterface;
    procedure TestIssue67;
    procedure TestCopyTo;
    procedure TestArrayAccess;
    procedure TestIssue53;

    procedure GetCapacity;
    procedure SetCapacity;

    procedure TestExtract_ItemNotInList;

    procedure TestEnumeratorMoveNext_VersionMismatch;
    procedure TestEnumeratorReset;
    procedure TestEnumeratorReset_VersionMismatch;
  end;

  TTestEmptyStringIntegerDictionary = class(TTestCase)
  private
    SUT: IDictionary<string, integer>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestDictionaryIsInitializedEmpty;
    procedure TestDictionaryKeysAreEmpty;
    procedure TestDictionaryValuesAreEmpty;
    procedure TestDictionaryContainsReturnsFalse;
    procedure TestDictionaryValuesReferenceCounting;
  end;

  TTestStringIntegerDictionary = class(TTestCase)
  private
    SUT: IDictionary<string, integer>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestDictionaryCountWithAdd;
    procedure TestDictionarySimpleValues;
    procedure TestDictionaryKeys;
    procedure TestDictionaryValues;
    procedure TestDictionaryContainsValue;
    procedure TestDictionaryContainsKey;
  end;

  TTestEmptyStackofStrings = class(TTestCase)
  private
    SUT: IStack<string>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestStackInitializesEmpty;
    procedure TestEmptyPopPeek;
  end;

  TTestStackOfInteger = class(TTestCase)
  private
    const MaxStackItems = 1000;
  private
    SUT: IStack<integer>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure FillStack;
  published
    procedure TestStackCreate;
    procedure TestStackCreate2;
    procedure TestStackInitializesEmpty;
    procedure TestStackPopPushBalances;
    procedure TestStackClear;
    procedure TestStackPeek;
    procedure TestStackPeekOrDefault;
    procedure TestStackTryPeek;
{$IFDEF DELPHIXE_UP}
    procedure TestStackTrimExcess;
{$ENDIF}
  end;

  TTestStackOfIntegerChangedEvent = class(TTestCase)
  private
    SUT: IStack<Integer>;
    fAInvoked, fBInvoked: Boolean;
    fAItem, fBItem: Integer;
    fAAction, fBAction: TCollectionChangedAction;
    procedure HandlerA(Sender: TObject; const Item: Integer; Action: TCollectionChangedAction);
    procedure HandlerB(Sender: TObject; const Item: Integer; Action: TCollectionChangedAction);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestEmpty;
    procedure TestOneHandler;
    procedure TestTwoHandlers;
    procedure TestNonGenericChangedEvent;
  end;

  TTestEmptyQueueOfInteger = class(TTestCase)
  private
    SUT: IQueue<integer>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestEmptyQueueIsEmpty;
    procedure TestClearOnEmptyQueue;
    procedure TestPeekRaisesException;
    procedure TestDequeueRaisesException;
  end;

  TTestQueueOfInteger = class(TTestCase)
  private
    SUT: IQueue<integer>;
    procedure FillQueue;  // Will test Enqueue method
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestQueueCreate;
    procedure TestQueueCreate2;
    procedure TestQueueClear;
    procedure TestQueueDequeue;
    procedure TestQueuePeek;
    procedure TestQueuePeekOrDefault;
    procedure TestQueueTryPeek;
{$IFDEF DELPHIXE_UP}
    procedure TestQueueTrimExcess;
{$ENDIF}
  end;

  TTestQueueOfIntegerChangedEvent = class(TTestCase)
  private
    SUT: IQueue<Integer>;
    fAInvoked, fBInvoked: Boolean;
    fAItem, fBItem: Integer;
    fAAction, fBAction: TCollectionChangedAction;
    procedure HandlerA(Sender: TObject; const Item: Integer; Action: TCollectionChangedAction);
    procedure HandlerB(Sender: TObject; const Item: Integer; Action: TCollectionChangedAction);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestEmpty;
    procedure TestOneHandler;
    procedure TestTwoHandlers;
    procedure TestNonGenericChangedEvent;
  end;

  TTestListOfIntegerAsIEnumerable = class(TTestCase)
  private
    InternalList: IList<integer>;
    SUT: IEnumerable<integer>;
    procedure FillList;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestEnumerableIsEmpty;
    procedure TestEnumerableHasCorrectCountAfterFill;
    procedure TestEnumerableFirst;
    procedure TestEnumerableLast;
    procedure TestSingle;
    procedure TestMin;
    procedure TestMax;
    procedure TestContains;
    procedure TestCheckSingleRaisedExceptionWhenHasMultipleItems;
    procedure TestCheckSingleRaisedExceptionWhenEmpty;
    procedure TestElementAt;
    procedure TestToArray;
  end;

  TTestLinkedList = class(TTestCase)
  private
    SUT: ILinkedList<integer>;
    fItem: Integer;
    fAction: TCollectionChangedAction;
  protected
    procedure ListChanged(Sender: TObject; const Item: Integer;
      Action: TCollectionChangedAction);
    procedure SetUp; override;
    procedure TearDown; override;

    procedure CheckCount(expectedCount: Integer);
    procedure CheckEvent(expectedItem: Integer;
      expectedAction: TCollectionChangedAction);
    procedure CheckNode(node: TLinkedListNode<Integer>;
      expectedValue: Integer;
      expectedNext: TLinkedListNode<Integer>;
      expectedPrevious: TLinkedListNode<Integer>);
  published
    procedure TestAddFirstNode_EmptyList;
    procedure TestAddFirstValue_EmptyList;

    procedure TestAddFirstNode_ListContainsTwoItems;
    procedure TestAddFirstValue_ListContainsTwoItems;

    procedure TestAddLastNode_EmptyList;
    procedure TestAddLastValue_EmptyList;

    procedure TestAddLastNode_ListContainsTwoItems;
    procedure TestAddLastValue_ListContainsTwoItems;
  end;

  TTestObjectList = class(TTestCase)
  private
    SUT: IList<TPersistent>;
  protected
    procedure SetUp; override;
  published
    procedure TestQueryInterface;
    procedure TestObjectListCreate;
    procedure TestSetOwnsObjects;
    procedure TestGetElementType;
  end;

  TTestInterfaceList = class(TTestCase)
  private
    SUT: IList<IInvokable>;
  protected
    procedure SetUp; override;
  published
    procedure TestInterfaceListCreate;
    procedure TestGetElementType;
    procedure TestCopyTo;
  end;

  TMyCollectionItem = class(TCollectionItem);
  TMyOtherCollectionItem = class(TCollectionItem);

  TTestCollectionList = class(TTestCase)
  private
    SUT: IList<TCollectionItem>;
    Coll: TCollection;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestElementType;
    procedure TestAdd;
    procedure TestDelete;
    procedure TestDeleteRange;
    procedure TestExtract;
    procedure TestExtract_ItemNotInList;

    procedure TestExchange;
    procedure TestMove;

    procedure TestEnumeratorMoveNext_VersionMismatch;
    procedure TestEnumeratorReset;
    procedure TestEnumeratorReset_VersionMismatch;
  end;

  TTestEnumerable = class(TTestCase)
  private
    SUT: IEnumerable<Integer>;
  protected
    procedure SetUp; override;
  published
    procedure TestToArray;
  end;

  TTestListAdapter = class(TTestCase)
  private
    InternalList: IList<Integer>;
    SUT: IList;
    procedure ListChanged(Sender: TObject; const Item: Integer;
      Action: TCollectionChangedAction);
  protected
    procedure SetUp; override;
  published
    procedure TestListAdd;
    procedure TestListAddRangeArray;
    procedure TestListAddRangeIEnumerable;

    procedure TestListAsReadOnlyList;

    procedure TestListClear;

    procedure TestListDelete;
    procedure TestListDeleteRange;
    procedure TestListDeleteRange2;

    procedure TestListExchange;

    procedure TestListExtract;
    procedure TestListExtractRangeArray;
    procedure TestListExtractRangeIEnumerable;

    procedure TestListGetCount;
    procedure TestListGetElementType;
    procedure TestListGetEnumerator;
    procedure TestListGetIsReadOnly;
    procedure TestListGetOnChanged;

    procedure TestListGetItem;
    procedure TestListSetItem;

    procedure TestListIndexOf;

    procedure TestListInsert;
    procedure TestListInsertRangeArray;
    procedure TestListInsertRangeIEnumerable;

    procedure TestListLastIndexOf;

    procedure TestListMove;

    procedure TestListQueryInterface;

    procedure TestListRemove;
    procedure TestListRemoveRangeArray;
    procedure TestListRemoveRangeIEnumerable;

    procedure TestListReverse;
    procedure TestListReverse2;

    procedure TestListSort;
  end;

implementation

uses
  Generics.Defaults,
  Spring.Collections.Queues,
  Spring.Collections.Stacks,
  SysUtils;

const
  MaxItems = 1000;
  ListCountLimit = 1000;//0000;

{ TTestEmptyHashSet }

procedure TTestEmptyHashSet.SetUp;
begin
  inherited;
  fSet := TCollections.CreateSet<Integer>;
  fEmpty := TCollections.CreateSet<Integer>;
end;

procedure TTestEmptyHashSet.TearDown;
begin
  inherited;
  fSet := nil;
end;

procedure TTestEmptyHashSet.TestEmpty;
begin
  CheckEquals(0, fSet.Count);
  CheckTrue(fSet.IsEmpty);
end;

procedure TTestEmptyHashSet.TestExceptWith;
begin
  fSet.ExceptWith(fEmpty);
  CheckEquals(0, fSet.Count);
end;

procedure TTestEmptyHashSet.TestIntersectWith;
begin
  fSet.IntersectWith(fEmpty);
  CheckEquals(0, fSet.Count);
end;

procedure TTestEmptyHashSet.TestUnionWith;
begin
  fSet.UnionWith(fEmpty);
  CheckEquals(0, fSet.Count);
end;

procedure TTestEmptyHashSet.TestAddDuplications;
begin
  CheckTrue(fSet.Add(2));
  CheckEquals(1, fSet.Count);

  CheckFalse(fSet.Add(2));
  CheckEquals(1, fSet.Count);
end;

procedure TTestEmptyHashSet.TestSetEquals;
begin
  CheckTrue(fSet.SetEquals(fEmpty));
end;

{ TTestNormalHashSet }

procedure TTestNormalHashSet.CheckSet(const collection: ISet<Integer>; const values: array of Integer);
var
  value: Integer;
begin
  CheckEquals(Length(values), collection.Count);
  for value in values do
    CheckTrue(collection.Contains(value));
end;

procedure TTestNormalHashSet.SetUp;
begin
  inherited;
  fSet1 := TCollections.CreateSet<Integer>;
  fSet2 := TCollections.CreateSet<Integer>;
  fSet1.AddRange([1, 2, 3]);
  fSet2.AddRange([3, 1, 4, 5]);
end;

procedure TTestNormalHashSet.TearDown;
begin
  inherited;
  fSet1 := nil;
  fSet2 := nil;
end;

procedure TTestNormalHashSet.TestExceptWith;
begin
  fSet1.ExceptWith(fSet2);
  CheckSet(fSet1, [2]);
end;

procedure TTestNormalHashSet.TestExtract;
begin
  CheckEquals(3, fSet1.Extract(3));
  CheckEquals(0, fSet1.Extract(6));
  fSet2.Clear;
  fSet2.AddRange([1, 2]);
  CheckTrue(fSet1.SetEquals(fSet2));
end;

procedure TTestNormalHashSet.TestIntersectWith;
begin
  fSet1.IntersectWith(fSet2);
  CheckSet(fSet1, [1, 3]);
end;

procedure TTestNormalHashSet.TestIntersectWithList;
var
  list: IList<Integer>;
begin
  list := TCollections.CreateList<Integer>;
  list.AddRange([3, 1, 4, 5]);
  fSet1.IntersectWith(list);
  CheckSet(fSet1, [1, 3]);
end;

procedure TTestNormalHashSet.TestIsSubsetOf;
begin
  CheckFalse(fSet1.IsSubsetOf(fSet2));
  fSet2.Add(2);
  CheckTrue(fSet1.IsSubsetOf(fSet2));
end;

procedure TTestNormalHashSet.TestIsSupersetOf;
begin
  CheckFalse(fSet2.IsSupersetOf(fSet1));
  fSet2.Add(2);
  CheckTrue(fSet2.IsSupersetOf(fSet1));
end;

procedure TTestNormalHashSet.TestOverlaps;
begin
  CheckTrue(fSet1.Overlaps(fSet2));
  fSet2.Clear;
  CheckFalse(fSet1.Overlaps(fSet2));
  fSet2.AddRange([4, 5]);
  CheckFalse(fSet1.Overlaps(fSet2));
end;

procedure TTestNormalHashSet.TestUnionWith;
begin
  fSet1.UnionWith(fSet2);
  CheckSet(fSet1, [1, 2, 3, 4, 5]);
end;

procedure TTestNormalHashSet.TestSetEquals;
begin
  CheckFalse(fSet1.SetEquals(fSet2));
  CheckTrue(fSet1.SetEquals(fSet1));
  CheckTrue(fSet2.SetEquals(fSet2));
end;

procedure TTestNormalHashSet.TestSetEqualsList;
var
  list: IList<Integer>;
begin
  list := TCollections.CreateList<Integer>;
  list.AddRange([3, 2, 1]);
  CheckTrue(fSet1.SetEquals(list));
  CheckFalse(fSet2.SetEquals(list));
end;

{ TTestIntegerList }

procedure TTestIntegerList.GetCapacity;
begin
  SimpleFillList;
  CheckEquals(4, TList<Integer>(SUT).Capacity);
end;

procedure TTestIntegerList.SetCapacity;
begin
  SimpleFillList;
  TList<Integer>(SUT).Capacity := 2;
  CheckTrue(SUT.EqualsTo([1, 2]));
end;

procedure TTestIntegerList.SetUp;
begin
  inherited;
  SUT := TCollections.CreateList<integer>;
end;

procedure TTestIntegerList.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestIntegerList.TestArrayAccess;
var
  arrayAccess: IArrayAccess<Integer>;
  values: TArray<Integer>;
begin
  SimpleFillList;
  arrayAccess := SUT as IArrayAccess<Integer>;
  values := arrayAccess.Items;
  CheckEquals(4, Length(values));
  CheckEquals(3, arrayAccess.Count);
  CheckEquals(SUT[0], values[0]);
  CheckEquals(SUT[1], values[1]);
  CheckEquals(SUT[2], values[2]);
  values[1] := 4;
  CheckEquals(SUT[1], values[1]);
end;

procedure TTestIntegerList.TestCopyTo;
var
  values: TArray<Integer>;
  i: Integer;
begin
  for i := 0 to MaxItems - 1 do
    SUT.Add(i);
  SetLength(values, MaxItems);
  SUT.CopyTo(values, 0);
  CheckEquals(MaxItems, Length(values));
  CheckEquals(SUT.First, values[0]);
  CheckEquals(SUT.Last, values[MaxItems-1]);
  SUT[0] := MaxItems;
  CheckNotEquals(SUT.First, values[0]);
end;

procedure TTestIntegerList.TestEnumeratorMoveNext_VersionMismatch;
var
  e: IEnumerator<Integer>;
begin
  SimpleFillList;
  ExpectedException := EInvalidOperationException;
  e := SUT.GetEnumerator;
  while e.MoveNext do
    SUT.Add(4);
  ExpectedException := nil;
end;

procedure TTestIntegerList.TestEnumeratorReset;
var
  e: IEnumerator<Integer>;
begin
  SimpleFillList;
  e := SUT.GetEnumerator;
  while e.MoveNext do;
  e.Reset;
  CheckTrue(e.MoveNext);
  CheckEquals(1, e.Current);
end;

procedure TTestIntegerList.TestEnumeratorReset_VersionMismatch;
var
  e: IEnumerator<Integer>;
begin
  SimpleFillList;
  e := SUT.GetEnumerator;
  while e.MoveNext do;
  SUT.Add(4);
  ExpectedException := EInvalidOperationException;
  e.Reset;
  ExpectedException := nil;
end;

procedure TTestIntegerList.TestExtract_ItemNotInList;
begin
  SimpleFillList;
  CheckEquals(0, SUT.Extract(4));
end;

type
  TIntegerList = class(TList<Integer>)
  public
    procedure Clear; override;
  end;

procedure TIntegerList.Clear;
var
  i: Integer;
begin
  for i in Self do
    if i = 0 then;
  inherited;
end;

procedure TTestIntegerList.TestIssue53;
begin
  SUT := TIntegerList.Create;
end;

procedure TTestIntegerList.TestIssue67;
var
  i: Integer;
begin
  SUT := TCollections.CreateList<Integer>(TComparer<Integer>.Construct(
    function(const left, right: Integer): Integer
    begin
      Result := right - left; // decending
    end));
  SUT.AddRange([1, 3, 5, 7, 9, 2, 4, 6, 8]);
  i := SUT.Where(
    function(const i: Integer): Boolean
    begin
      Result := Odd(i);
    end)
    .Max;
  CheckEquals(1, i);
end;

procedure TTestIntegerList.TestLastIndexOf;
begin
  SUT.Add(1);
  SUT.Add(1);
  SUT.Add(1);
  SUT.Add(2);
  SUT.Add(3);

  CheckEquals(2, SUT.LastIndexOf(1));
end;

procedure TTestIntegerList.TestListClear;
var
  i: Integer;
begin
  for i := 0 to ListCountLimit do
    SUT.Add(i);

  SUT.Clear;

  CheckEquals(0, SUT.Count, 'List not empty after call to Clear');
end;

procedure TTestIntegerList.TestListCountWithAdd;
var
  i: Integer;
begin
  (SUT as TList<Integer>).Capacity := ListCountLimit;
  for i := 1 to ListCountLimit do
  begin
    SUT.Add(i);
    CheckEquals(i, SUT.Count);
  end;
end;

procedure TTestIntegerList.TestListCountWithInsert;
var
  i: Integer;
begin
  for i := 1 to ListCountLimit do
  begin
    SUT.Insert(0, i);
    CheckEquals(i, SUT.Count);
  end;
end;

procedure TTestIntegerList.TestListSimpleDelete;
begin
  SUT.Add(1);
  CheckEquals(1, SUT.Count);
  SUT.Delete(0);
  CheckEquals(0, SUT.Count);
end;

procedure TTestIntegerList.TestListReverse;
var
  i: Integer;
begin
  for i := 0 to ListCountLimit do
    SUT.Add(i);
  CheckEquals(ListCountLimit + 1, SUT.Count, 'TestReverse: List count incorrect after initial adds');

  SUT.Reverse;

  for i := ListCountLimit downto 0 do
    CheckEquals(i, SUT[ListCountLimit - i]);
end;

procedure TTestIntegerList.TestListSimpleExchange;
begin
  SUT.Add(0);
  SUT.Add(1);
  CheckEquals(2, SUT.Count);
  SUT.Exchange(0, 1);
  CheckEquals(2, SUT.Count, 'Count wrong after exchange');
  CheckEquals(1, SUT[0]);
  CheckEquals(0, SUT[1]);
end;

procedure TTestIntegerList.TestListSort;
var
  i: Integer;
begin
  SUT.Add(6);
  SUT.Add(0);
  SUT.Add(2);
  SUT.Add(5);
  SUT.Add(7);
  SUT.Add(1);
  SUT.Add(8);
  SUT.Add(3);
  SUT.Add(4);
  SUT.Add(9);
  CheckEquals(10, SUT.Count, 'Test');
  SUT.Sort;
  for i := 0 to 9 do
    CheckEquals(i, SUT[i], Format('%s: Items not properly sorted at Index %d', ['TestlistSort', i]));
end;

procedure TTestIntegerList.TestQueryInterface;
var
  list: IObjectList;
begin
  CheckException(EIntfCastError,
    procedure
    begin
      list := SUT as IObjectList;
    end);
end;

procedure TTestIntegerList.TestListIndexOf;
var
  i: Integer;
begin
  for i := 0 to ListCountLimit - 1 do
    SUT.Add(i);
  CheckEquals(ListCountLimit, SUT.Count, 'TestLimitIndexOf: List count not correct after adding items.');

  for i := 0 to ListCountLimit - 1 do
    CheckEquals(i, SUT.IndexOf(i));

  CheckEquals(-1, SUT.IndexOf(ListCountLimit + 100), 'Index of item not in list was not -1');
end;

procedure TTestIntegerList.TestListInsertBeginning;
begin
  SUT.Add(0);
  SUT.Add(1);
  SUT.Insert(0, 42);
  CheckEquals(3, SUT.Count);
  CheckEquals(42, SUT[0]);
  CheckEquals(0, SUT[1]);
  CheckEquals(1, SUT[2]);
end;

procedure TTestIntegerList.TestListInsertBetween;
begin
  SUT.Add(0);
  SUT.Add(1);
  SUT.Insert(1, 42);
  CheckEquals(3, SUT.Count);
  CheckEquals(0, SUT[0]);
  CheckEquals(42, SUT[1]);
  CheckEquals(1, SUT[2]);
end;


procedure TTestIntegerList.TestListIsInitializedEmpty;
begin
  CheckEquals(SUT.Count, 0);
end;

procedure TTestIntegerList.TestListLargeDelete;
var
  i: Integer;
begin
  for i := 0 to ListCountLimit do
    SUT.Add(i);

  for i := 0 to ListCountLimit do
    SUT.Delete(0);

  CheckEquals(0, SUT.Count, 'Not all items properly deleted from large delete');
end;

procedure TTestIntegerList.TestListMove;
begin
  SimpleFillList;
  CheckEquals(3, SUT.Count);

  SUT.Move(0, 2);
  CheckEquals(3, SUT.Count, 'List count is wrong after call to Move');

  CheckEquals(2, SUT[0]);
  CheckEquals(3, SUT[1]);
  CheckEquals(1, SUT[2]);
end;

procedure TTestIntegerList.TestListMultipleDelete;
begin
  SimpleFillList;
  CheckEquals(3, SUT.Count);
  SUT.Delete(0);
  CheckEquals(2, SUT.Count);
  SUT.Delete(0);
  CheckEquals(1, SUT.Count);
  SUT.Delete(0);
  CheckEquals(0, SUT.Count);
end;

procedure TTestIntegerList.TestListRemove;
begin

end;

procedure TTestIntegerList.SimpleFillList;
begin
  CheckNotNull(SUT, 'SUT is nil');
  SUT.Add(1);
  SUT.Add(2);
  SUT.Add(3);
end;

{ TTestStringIntegerDictionary }

procedure TTestStringIntegerDictionary.SetUp;
begin
  inherited;
  SUT := TCollections.CreateDictionary<string, integer>;
  SUT.Add('one', 1);
  SUT.Add('two', 2);
  SUT.Add('three', 3);
end;

procedure TTestStringIntegerDictionary.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestStringIntegerDictionary.TestDictionaryContainsKey;
begin
  CheckTrue(SUT.ContainsKey('one'), '"one" not found by ContainsKey');
  CheckTrue(SUT.ContainsKey('two'), '"two" not found by ContainsKey');
  CheckTrue(SUT.ContainsKey('three'), '"three" not found by ContainsKey');
end;

procedure TTestStringIntegerDictionary.TestDictionaryContainsValue;
begin
  CheckTrue(SUT.ContainsValue(1), '1 not found by ContainsValue');
  CheckTrue(SUT.ContainsValue(2), '2 not found by ContainsValue');
  CheckTrue(SUT.ContainsValue(3), '3 not found by ContainsValue');
end;

procedure TTestStringIntegerDictionary.TestDictionaryCountWithAdd;
begin
  CheckEquals(3, SUT.Count, 'TestDictionaryCountWithAdd: Count is not correct');
end;

procedure TTestStringIntegerDictionary.TestDictionaryKeys;
var
  Result: IReadOnlyCollection<string>;
begin
  Result := SUT.Keys;
  CheckEquals(3, Result.Count, 'TestDictionaryKeys: Keys call returns wrong count');

  CheckTrue(Result.Contains('one'), 'TestDictionaryKeys: Keys doesn''t contain "one"');
  CheckTrue(Result.Contains('two'), 'TestDictionaryKeys: Keys doesn''t contain "two"');
  CheckTrue(Result.Contains('three'), 'TestDictionaryKeys: Keys doesn''t contain "three"');
end;

procedure TTestStringIntegerDictionary.TestDictionarySimpleValues;
begin
  CheckEquals(3, SUT.Count, 'TestDictionarySimpleValues: Count is not correct');

  CheckEquals(1, SUT['one']);
  CheckEquals(2, SUT['two']);
  CheckEquals(3, SUT['three']);
end;

procedure TTestStringIntegerDictionary.TestDictionaryValues;
var
  Result: IReadOnlyCollection<Integer>;
begin
  Result := SUT.Values;
  CheckEquals(3, Result.Count, 'TestDictionaryKeys: Values call returns wrong count');

  CheckTrue(Result.Contains(1), 'TestDictionaryKeys: Values doesn''t contain "one"');
  CheckTrue(Result.Contains(2), 'TestDictionaryKeys: Values doesn''t contain "two"');
  CheckTrue(Result.Contains(3), 'TestDictionaryKeys: Values doesn''t contain "three"');
end;

{ TTestEmptyStringIntegerDictionary }

procedure TTestEmptyStringIntegerDictionary.SetUp;
begin
  inherited;
  SUT := TCollections.CreateDictionary<string, integer>;
end;

procedure TTestEmptyStringIntegerDictionary.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestEmptyStringIntegerDictionary.TestDictionaryContainsReturnsFalse;
begin
  CheckFalse(SUT.ContainsKey('blah'));
  CheckFalse(SUT.ContainsValue(42));
end;

procedure TTestEmptyStringIntegerDictionary.TestDictionaryIsInitializedEmpty;
begin
  CheckEquals(0, SUT.Count);
end;

procedure TTestEmptyStringIntegerDictionary.TestDictionaryKeysAreEmpty;
var
  Result: IReadOnlyCollection<string>;
begin
  Result := SUT.Keys;
  CheckEquals(0, Result.Count);
end;

procedure TTestEmptyStringIntegerDictionary.TestDictionaryValuesAreEmpty;
var
  Result: IReadOnlyCollection<Integer>;
begin
  Result := SUT.Values;
  CheckEquals(0, Result.Count);
end;

procedure TTestEmptyStringIntegerDictionary.TestDictionaryValuesReferenceCounting;
var
  query: IEnumerable<Integer>;
begin
  query := SUT.Values.Skip(1);
  CheckNotNull(query);
end;

{ TTestEmptyStackofStrings }

procedure TTestEmptyStackofStrings.SetUp;
begin
  inherited;
  SUT := TCollections.CreateStack<string>;
end;

procedure TTestEmptyStackofStrings.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestEmptyStackofStrings.TestEmptyPopPeek;
begin
  CheckException(EListError, procedure begin SUT.Pop end, 'EListError not raised');
  CheckException(EListError, procedure begin SUT.Peek end, 'EListError not raised');
end;

procedure TTestEmptyStackofStrings.TestStackInitializesEmpty;
begin
  CheckEquals(0, SUT.Count);
end;

{ TTestStackOfInteger }

procedure TTestStackOfInteger.FillStack;
var
  i: Integer;
begin
  Check(SUT <> nil);
  for i := 0 to MaxStackItems do
    SUT.Push(i);
end;

procedure TTestStackOfInteger.SetUp;
begin
  inherited;
  SUT := TCollections.CreateStack<integer>;
end;

procedure TTestStackOfInteger.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestStackOfInteger.TestStackClear;
begin
  FillStack;
  SUT.Clear;
  CheckEquals(0, SUT.Count, 'Stack failed to empty after call to Clear');
end;

procedure TTestStackOfInteger.TestStackCreate;
const
  values: array[0..9] of Integer = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
begin
  SUT := TStack<Integer>.Create(values);
  CheckTrue(SUT.EqualsTo(values));
  SUT := TStack<Integer>.Create(TCollections.Range(0, 10));
  CheckTrue(SUT.EqualsTo(values));
end;

procedure TTestStackOfInteger.TestStackCreate2;
var
  stack: Generics.Collections.TStack<Integer>;
begin
  stack := Generics.Collections.TStack<Integer>.Create;
  try
    SUT := TStack<Integer>.Create(stack, otReference);
  finally
    SUT := nil;
    stack.Free;
  end;
  FCheckCalled := True;
end;

procedure TTestStackOfInteger.TestStackInitializesEmpty;
begin
  CheckEquals(0, SUT.Count);
end;

procedure TTestStackOfInteger.TestStackPeek;
var
  Expected: Integer;
  Actual: integer;
begin
  FillStack;
  Expected := MaxStackItems;
  Actual := SUT.Peek;
  CheckEquals(Expected, Actual, 'Stack.Peek failed');
end;

procedure TTestStackOfInteger.TestStackPeekOrDefault;
var
  Expected: Integer;
  Actual: integer;
begin
  FillStack;
  Expected := MaxStackItems;
  Actual := SUT.PeekOrDefault;
  CheckEquals(Expected, Actual, 'Stack.Peek failed');

  SUT.Clear;
  Expected := Default(Integer);
  Actual := SUT.PeekOrDefault;
  CheckEquals(Expected, Actual, 'Stack.Peek failed');
end;

procedure TTestStackOfInteger.TestStackPopPushBalances;
var
  i: Integer;
begin
  FillStack;

  for i := 0 to MaxStackItems do
    SUT.Pop;

  // Should be empty
  CheckEquals(0, SUT.Count);
end;

{$IFDEF DELPHIXE_UP}
procedure TTestStackOfInteger.TestStackTrimExcess;
var
  stack: TStack<Integer>;
begin
  stack := SUT as TStack<Integer>;
  CheckEquals(0, stack.Capacity);
  stack.Capacity := MaxItems;
  CheckEquals(MaxItems, stack.Capacity);
  stack.TrimExcess;
  CheckEquals(0, stack.Capacity);
end;
{$ENDIF}

procedure TTestStackOfInteger.TestStackTryPeek;
var
  Expected: Integer;
  Actual: Integer;
begin
  CheckFalse(SUT.TryPeek(Actual));
  Expected := 0;
  CheckEquals(Expected, Actual);
  SUT.Push(MaxItems);
  CheckTrue(SUT.TryPeek(Actual));
  Expected := MaxItems;
  CheckEquals(Expected, Actual);
end;

{ TTestStackOfIntegerChangedEvent }

procedure TTestStackOfIntegerChangedEvent.SetUp;
begin
  inherited;
  SUT := TCollections.CreateStack<Integer>;
end;

procedure TTestStackOfIntegerChangedEvent.TearDown;
begin
  inherited;
  SUT := nil;
  fAInvoked := False;
  fBInvoked := False;
end;

procedure TTestStackOfIntegerChangedEvent.HandlerA(Sender: TObject;
  const Item: Integer; Action: TCollectionChangedAction);
begin
  fAItem := Item;
  fAAction := Action;
  fAInvoked := True;
end;

procedure TTestStackOfIntegerChangedEvent.HandlerB(Sender: TObject;
  const Item: Integer; Action: TCollectionChangedAction);
begin
  fBitem := Item;
  fBAction := Action;
  fBInvoked := True;
end;

procedure TTestStackOfIntegerChangedEvent.TestEmpty;
begin
  CheckEquals(0, SUT.OnChanged.Count);
  CheckTrue(SUT.OnChanged.IsEmpty);

  SUT.Push(0);

  CheckFalse(fAInvoked);
  CheckFalse(fBInvoked);
end;

procedure TTestStackOfIntegerChangedEvent.TestOneHandler;
begin
  SUT.OnChanged.Add(HandlerA);

  SUT.Push(0);

  CheckTrue(fAInvoked, 'handler A not invoked');
  CheckTrue(fAAction = caAdded, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');

  CheckFalse(fBInvoked, 'handler B not registered as callback');

  SUT.Pop;

  CheckTrue(fAAction = caRemoved, 'different collection notifications');

  SUT.OnChanged.Remove(HandlerA);
  CheckEquals(0, SUT.OnChanged.Count);
  CheckTrue(SUT.OnChanged.IsEmpty);
end;

procedure TTestStackOfIntegerChangedEvent.TestTwoHandlers;
begin
  SUT.OnChanged.Add(HandlerA);
  SUT.OnChanged.Add(HandlerB);

  SUT.Push(0);

  CheckTrue(fAInvoked, 'handler A not invoked');
  CheckTrue(fAAction = caAdded, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');
  CheckTrue(fBInvoked, 'handler B not invoked');
  CheckTrue(fBAction = caAdded, 'handler B: different collection notifications');
  CheckEquals(0, fBItem, 'handler B: different item');

  SUT.Pop;

  CheckTrue(fAAction = caRemoved, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');
  CheckTrue(fBAction = caRemoved, 'handler B: different collection notifications');
  CheckEquals(0, fBItem, 'handler B: different item');

  SUT.OnChanged.Remove(HandlerA);
  CheckEquals(1, SUT.OnChanged.Count);
  CheckFalse(SUT.OnChanged.IsEmpty);
  SUT.OnChanged.Remove(HandlerB);
  CheckTrue(SUT.OnChanged.IsEmpty);
end;

procedure TTestStackOfIntegerChangedEvent.TestNonGenericChangedEvent;
var
  event: IEvent;
  method: TMethod;
begin
  event := SUT.OnChanged;

  CheckTrue(event.IsEmpty);
  CheckTrue(event.Enabled);

  method.Code := @TTestStackOfIntegerChangedEvent.HandlerA;
  method.Data := Pointer(Self);

  event.Add(method);

  CheckEquals(1, event.Count);
  CheckEquals(1, SUT.OnChanged.Count);

  SUT.Push(0);

  CheckTrue(fAInvoked, 'handler A not invoked');
  CheckTrue(fAAction = caAdded, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');
end;

{ TTestEmptyQueueofTObject }

procedure TTestEmptyQueueOfInteger.SetUp;
begin
  inherited;
  SUT := TCollections.CreateQueue<integer>
end;

procedure TTestEmptyQueueOfInteger.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestEmptyQueueOfInteger.TestClearOnEmptyQueue;
begin
  CheckEquals(0, SUT.Count, 'Queue not empty before call to clear');
  SUT.Clear;
  CheckEquals(0, SUT.Count, 'Queue not empty after call to clear');
end;

procedure TTestEmptyQueueOfInteger.TestEmptyQueueIsEmpty;
begin
  CheckEquals(0, SUT.Count);
end;

procedure TTestEmptyQueueOfInteger.TestPeekRaisesException;
begin
  CheckException(EListError, procedure begin SUT.Peek end, 'EListError was not raised on Peek call with empty Queue');
end;

procedure TTestEmptyQueueOfInteger.TestDequeueRaisesException;
begin
  CheckException(EListError, procedure begin SUT.Dequeue end, 'EListError was not raised on Peek call with empty Queue');
end;

{ TTestQueueOfInteger }

procedure TTestQueueOfInteger.FillQueue;
var
  i: Integer;
begin
  Check(SUT <> nil);
  for i := 0 to MaxItems - 1  do
    SUT.Enqueue(i);
  CheckEquals(MaxItems, SUT.Count, 'Call to FillQueue did not properly fill the queue');
end;

procedure TTestQueueOfInteger.SetUp;
begin
  inherited;
  SUT := TCollections.CreateQueue<integer>;
end;

procedure TTestQueueOfInteger.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestQueueOfInteger.TestQueueClear;
begin
  FillQueue;
  SUT.Clear;
  CheckEquals(0, SUT.Count, 'Clear call failed to empty the queue');
end;

procedure TTestQueueOfInteger.TestQueueCreate;
const
  values: array[0..9] of Integer = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
begin
  SUT := TQueue<Integer>.Create(values);
  CheckTrue(SUT.EqualsTo(values));
  SUT := TQueue<Integer>.Create(TCollections.Range(0, 10));
  CheckTrue(SUT.EqualsTo(values));
end;

procedure TTestQueueOfInteger.TestQueueCreate2;
var
  queue: Generics.Collections.TQueue<Integer>;
begin
  queue := Generics.Collections.TQueue<Integer>.Create;
  try
    SUT := TQueue<Integer>.Create(queue, otReference);
  finally
    SUT := nil;
    queue.Free;
  end;
  FCheckCalled := True;
end;

procedure TTestQueueOfInteger.TestQueueDequeue;
var
  i: Integer;
begin
  FillQueue;
  for i := 1 to MaxItems do
    SUT.Dequeue;

  CheckEquals(0, SUT.Count, 'Dequeue did not remove all the items');
end;

procedure TTestQueueOfInteger.TestQueuePeek;
var
  Expected: Integer;
  Actual: Integer;
begin
  FillQueue;
  Expected := 0;
  Actual := SUT.Peek;
  CheckEquals(Expected, Actual);
  ExpectedException := EListError;
  SUT.Clear;
  SUT.Peek;
  ExpectedException := nil;
end;

procedure TTestQueueOfInteger.TestQueuePeekOrDefault;
var
  Expected: Integer;
  Actual: Integer;
begin
  Actual := SUT.PeekOrDefault;
  Expected := 0;
  CheckEquals(Expected, Actual);
  SUT.Enqueue(MaxItems);
  Actual := SUT.PeekOrDefault;
  Expected := MaxItems;
  CheckEquals(Expected, Actual);
end;

{$IFDEF DELPHIXE_UP}
procedure TTestQueueOfInteger.TestQueueTrimExcess;
var
  queue: TQueue<Integer>;
begin
  queue := SUT as TQueue<Integer>;
  CheckEquals(0, queue.Capacity);
  queue.Capacity := MaxItems;
  CheckEquals(MaxItems, queue.Capacity);
  queue.TrimExcess;
  CheckEquals(0, queue.Capacity);
end;
{$ENDIF}

procedure TTestQueueOfInteger.TestQueueTryPeek;
var
  Expected: Integer;
  Actual: Integer;
begin
  CheckFalse(SUT.TryPeek(Actual));
  Expected := 0;
  CheckEquals(Expected, Actual);
  SUT.Enqueue(MaxItems);
  CheckTrue(SUT.TryPeek(Actual));
  Expected := MaxItems;
  CheckEquals(Expected, Actual);
end;

{ TTestQueueOfIntegerChangedEvent }

procedure TTestQueueOfIntegerChangedEvent.SetUp;
begin
  inherited;
  SUT := TCollections.CreateQueue<Integer>;
end;

procedure TTestQueueOfIntegerChangedEvent.TearDown;
begin
  inherited;
  SUT := nil;
  fAInvoked := False;
  fBInvoked := False;
end;

procedure TTestQueueOfIntegerChangedEvent.HandlerA(Sender: TObject;
  const Item: Integer; Action: TCollectionChangedAction);
begin
  fAItem := Item;
  fAAction := Action;
  fAInvoked := True;
end;

procedure TTestQueueOfIntegerChangedEvent.HandlerB(Sender: TObject;
  const Item: Integer; Action: TCollectionChangedAction);
begin
  fBitem := Item;
  fBAction := Action;
  fBInvoked := True;
end;

procedure TTestQueueOfIntegerChangedEvent.TestEmpty;
begin
  CheckEquals(0, SUT.OnChanged.Count);
  CheckTrue(SUT.OnChanged.IsEmpty);

  SUT.Enqueue(0);

  CheckFalse(fAInvoked);
  CheckFalse(fBInvoked);
end;

procedure TTestQueueOfIntegerChangedEvent.TestOneHandler;
begin
  SUT.OnChanged.Add(HandlerA);

  SUT.Enqueue(0);

  CheckTrue(fAInvoked, 'handler A not invoked');
  CheckTrue(fAAction = caAdded, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');

  CheckFalse(fBInvoked, 'handler B not registered as callback');

  SUT.Dequeue;

  CheckTrue(fAAction = caRemoved, 'different collection notifications');

  SUT.OnChanged.Remove(HandlerA);
  CheckEquals(0, SUT.OnChanged.Count);
  CheckTrue(SUT.OnChanged.IsEmpty);
end;

procedure TTestQueueOfIntegerChangedEvent.TestTwoHandlers;
begin
  SUT.OnChanged.Add(HandlerA);
  SUT.OnChanged.Add(HandlerB);

  SUT.Enqueue(0);

  CheckTrue(fAInvoked, 'handler A not invoked');
  CheckTrue(fAAction = caAdded, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');
  CheckTrue(fBInvoked, 'handler B not invoked');
  CheckTrue(fBAction = caAdded, 'handler B: different collection notifications');
  CheckEquals(0, fBItem, 'handler B: different item');

  SUT.Dequeue;

  CheckTrue(fAAction = caRemoved, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');
  CheckTrue(fBAction = caRemoved, 'handler B: different collection notifications');
  CheckEquals(0, fBItem, 'handler B: different item');

  SUT.OnChanged.Remove(HandlerA);
  CheckEquals(1, SUT.OnChanged.Count);
  CheckFalse(SUT.OnChanged.IsEmpty);
  SUT.OnChanged.Remove(HandlerB);
  CheckTrue(SUT.OnChanged.IsEmpty);
end;

procedure TTestQueueOfIntegerChangedEvent.TestNonGenericChangedEvent;
var
  event: IEvent;
  method: TMethod;
begin
  event := SUT.OnChanged;

  CheckTrue(event.IsEmpty);
  CheckTrue(event.Enabled);

  method.Code := @TTestStackOfIntegerChangedEvent.HandlerA;
  method.Data := Pointer(Self);

  event.Add(method);

  CheckEquals(1, event.Count);
  CheckEquals(1, SUT.OnChanged.Count);

  SUT.Enqueue(0);

  CheckTrue(fAInvoked, 'handler A not invoked');
  CheckTrue(fAAction = caAdded, 'handler A: different collection notifications');
  CheckEquals(0, fAItem, 'handler A: different item');
end;

{ TTestListOfIntegerAsIEnumerable }

procedure TTestListOfIntegerAsIEnumerable.FillList;
var
  i: integer;
begin
  for i := 0 to MaxItems - 1 do
    InternalList.Add(i);
end;

procedure TTestListOfIntegerAsIEnumerable.SetUp;
begin
  inherited;
  InternalList := TCollections.CreateList<integer>;
  SUT := InternalList;
end;

procedure TTestListOfIntegerAsIEnumerable.TearDown;
begin
  inherited;
  SUT := nil;
end;

procedure TTestListOfIntegerAsIEnumerable.TestEnumerableIsEmpty;
begin
  CheckEquals(0, SUT.Count);
  CheckTrue(SUT.IsEmpty);
end;

procedure TTestListOfIntegerAsIEnumerable.TestEnumerableLast;
begin
  FillList;
  CheckEquals(MaxItems - 1, SUT.Last);
end;

procedure TTestListOfIntegerAsIEnumerable.TestMax;
begin
  FillList;
  CheckEquals(MaxItems - 1, SUT.Max);
end;

procedure TTestListOfIntegerAsIEnumerable.TestMin;
begin
  FillList;
  CheckEquals(0, SUT.Min);
end;

procedure TTestListOfIntegerAsIEnumerable.TestSingle;
var
  ExpectedResult, ActualResult: integer;
begin
  InternalList.Add(1);
  ExpectedResult := 1;
  ActualResult := SUT.Single;
  CheckEquals(ExpectedResult, ActualResult);
end;

procedure TTestListOfIntegerAsIEnumerable.TestToArray;
var
  values: TArray<Integer>;
begin
  FillList;
  values := SUT.ToArray;
  CheckEquals(MaxItems, Length(values));
  CheckEquals(InternalList.First, values[0]);
  CheckEquals(InternalList.Last, values[MaxItems-1]);
  InternalList[0] := MaxItems;
  CheckNotEquals(InternalList.First, values[0]);
end;

procedure TTestListOfIntegerAsIEnumerable.TestCheckSingleRaisedExceptionWhenEmpty;
begin
  CheckException(EInvalidOperationException, procedure begin SUT.Single(function(const i: Integer): Boolean begin Result := i = 2 end) end,
    'SUT is empty, but failed to raise the EInvalidOperationException when the Single method was called');
end;

procedure TTestListOfIntegerAsIEnumerable.TestCheckSingleRaisedExceptionWhenHasMultipleItems;
begin
  FillList;
  CheckException(EInvalidOperationException, procedure begin SUT.Single end,
    'SUT has more thann one item, but failed to raise the EInvalidOperationException when the Single method was called.');
end;

procedure TTestListOfIntegerAsIEnumerable.TestContains;
begin
  FillList;
  CheckTrue(SUT.Contains(50));
  CheckFalse(SUT.Contains(MaxItems + 50));
end;

procedure TTestListOfIntegerAsIEnumerable.TestElementAt;
var
  i: integer;
begin
  FillList;
  for i := 0 to MaxItems - 1 do
    CheckEquals(i, SUT.ElementAt(i));
end;

procedure TTestListOfIntegerAsIEnumerable.TestEnumerableFirst;
begin
  FillList;
  CheckEquals(0, SUT.First);
end;

procedure TTestListOfIntegerAsIEnumerable.TestEnumerableHasCorrectCountAfterFill;
begin
  FillList;
  CheckEquals(MaxItems, SUT.Count);
end;

{ TTestLinkedList }

procedure TTestLinkedList.CheckEvent(expectedItem: Integer;
  expectedAction: TCollectionChangedAction);
begin
  CheckEquals(expectedItem, fItem, 'expectedItem');
  CheckTrue(expectedAction = fAction, 'expectedAction');
end;

procedure TTestLinkedList.CheckCount(expectedCount: Integer);
begin
  CheckEquals(expectedCount, SUT.Count, 'expectedCount');
end;

procedure TTestLinkedList.CheckNode(node: TLinkedListNode<Integer>;
  expectedValue: Integer; expectedNext,
  expectedPrevious: TLinkedListNode<Integer>);
begin
  CheckNotNull(node, 'node');
  CheckEquals(expectedValue, node.Value, 'node.Value');
  CheckSame(SUT, node.List, 'node.List');
  CheckSame(expectedNext, node.Next, 'node.Next');
  CheckSame(expectedPrevious, node.Previous, 'node.Previous');
end;

procedure TTestLinkedList.ListChanged(Sender: TObject; const Item: Integer;
  Action: TCollectionChangedAction);
begin
  fItem := Item;
  fAction := Action;
end;

procedure TTestLinkedList.SetUp;
begin
  SUT := TLinkedList<Integer>.Create;
  SUT.OnChanged.Add(ListChanged);
  fItem := 0;
  fAction := caChanged;
end;

procedure TTestLinkedList.TearDown;
begin
  SUT := nil;
end;

procedure TTestLinkedList.TestAddFirstNode_EmptyList;
var
  node: TLinkedListNode<Integer>;
begin
  node := TLinkedListNode<Integer>.Create(1);
  SUT.AddFirst(node);

  CheckCount(1);
  CheckEvent(1, caAdded);
  CheckNode(node, 1, nil, nil);
end;

procedure TTestLinkedList.TestAddFirstNode_ListContainsTwoItems;
var
  node, nextNode: TLinkedListNode<Integer>;
begin
  nextNode := SUT.AddFirst(1);
  SUT.Add(2);

  node := TLinkedListNode<Integer>.Create(3);
  SUT.AddFirst(node);

  CheckCount(3);
  CheckEvent(3, caAdded);
  CheckNode(node, 3, nextNode, nil);
end;

procedure TTestLinkedList.TestAddFirstValue_EmptyList;
var
  node: TLinkedListNode<Integer>;
begin
  node := SUT.AddFirst(1);

  CheckCount(1);
  CheckEvent(1, caAdded);
  CheckNode(node, 1, nil, nil);
end;

procedure TTestLinkedList.TestAddFirstValue_ListContainsTwoItems;
var
  node, nextNode: TLinkedListNode<Integer>;
begin
  nextNode := SUT.AddFirst(1);
  SUT.Add(2);

  node := SUT.AddFirst(3);

  CheckCount(3);
  CheckEvent(3, caAdded);
  CheckNode(node, 3, nextNode, nil);
end;

procedure TTestLinkedList.TestAddLastNode_EmptyList;
var
  node: TLinkedListNode<Integer>;
begin
  node := TLinkedListNode<Integer>.Create(1);
  SUT.AddLast(node);

  CheckCount(1);
  CheckEvent(1, caAdded);
  CheckNode(node, 1, nil, nil);
end;

procedure TTestLinkedList.TestAddLastNode_ListContainsTwoItems;
var
  node, prevNode: TLinkedListNode<Integer>;
begin
  SUT.Add(1);
  prevNode := SUT.AddLast(2);

  node := TLinkedListNode<Integer>.Create(3);
  SUT.AddLast(node);

  CheckCount(3);
  CheckEvent(3, caAdded);
  CheckNode(node, 3, nil, prevNode);
end;

procedure TTestLinkedList.TestAddLastValue_EmptyList;
var
  node: TLinkedListNode<Integer>;
begin
  node := SUT.AddLast(1);

  CheckCount(1);
  CheckEvent(1, caAdded);
  CheckNode(node, 1, nil, nil);
end;

procedure TTestLinkedList.TestAddLastValue_ListContainsTwoItems;
var
  node, prevNode: TLinkedListNode<Integer>;
begin
  SUT.Add(1);
  prevNode := SUT.AddLast(2);

  node := SUT.AddLast(3);

  CheckCount(3);
  CheckEvent(3, caAdded);
  CheckNode(node, 3, nil, prevNode);
end;

{ TTestObjectList }

procedure TTestObjectList.SetUp;
begin
  SUT := TObjectList<TPersistent>.Create as IList<TPersistent>;
end;

procedure TTestObjectList.TestGetElementType;
begin
  Check(TypeInfo(TPersistent) = SUT.ElementType);
end;

procedure TTestObjectList.TestObjectListCreate;
begin
  SUT := TObjectList<TPersistent>.Create(nil) as IList<TPersistent>;
  CheckNotNull(SUT.Comparer);
end;

procedure TTestObjectList.TestQueryInterface;
var
  list: IObjectList;
  obj: TObject;
begin
  SUT.Add(TPersistent.Create);
  SUT.Add(TPersistent.Create);
  SUT.Add(TPersistent.Create);
  list := SUT as IObjectList;
  CheckEquals(3, list.Count);
  list.Delete(1);
  CheckEquals(2, list.Count);
  list.Add(TPersistent.Create);
  CheckEquals(3, list.Count);
  for obj in list do
    CheckIs(obj, TPersistent);
  CheckTrue(list.ElementType = TPersistent.ClassInfo);
end;

procedure TTestObjectList.TestSetOwnsObjects;
begin
  CheckTrue(TObjectList<TPersistent>(SUT).OwnsObjects);
  TObjectList<TPersistent>(SUT).OwnsObjects := False;
  CheckFalse(TObjectList<TPersistent>(SUT).OwnsObjects);
end;

{ TTestInterfaceList }

procedure TTestInterfaceList.SetUp;
begin
  SUT := TInterfaceList<IInvokable>.Create as IList<IInvokable>;
end;

type
  TInvokable = class(TInterfacedObject, IInvokable);

procedure TTestInterfaceList.TestCopyTo;
var
  values: TArray<IInvokable>;
  i: Integer;
begin
  for i := 0 to MaxItems - 1 do
    SUT.Add(IInvokable(TInvokable.Create));
  SetLength(values, MaxItems);
  SUT.CopyTo(values, 0);
  CheckEquals(MaxItems, Length(values));
  CheckSame(SUT.First, values[0]);
  CheckSame(SUT.Last, values[MaxItems-1]);
end;

procedure TTestInterfaceList.TestGetElementType;
begin
  Check(TypeInfo(IInvokable) = SUT.ElementType);
end;

procedure TTestInterfaceList.TestInterfaceListCreate;
begin
  SUT := TInterfaceList<IInvokable>.Create(nil) as IList<IInvokable>;
  CheckNotNull(SUT.Comparer);
end;

{ TTestCollectionList }

procedure TTestCollectionList.SetUp;
begin
  Coll := TCollection.Create(TMyCollectionItem);
  SUT := Coll.AsList;
end;

procedure TTestCollectionList.TearDown;
begin
  SUT := nil;
  Coll.Free;
end;

procedure TTestCollectionList.TestAdd;
begin
  SUT.Add(TMyCollectionItem.Create(nil));
  TMyCollectionItem.Create(Coll);
  CheckEquals(2, SUT.Count);
  CheckException(Exception,
    procedure
    var
      item: TCollectionItem;
    begin
      item := TMyOtherCollectionItem.Create(nil);
      try
        SUT.Add(item);
      except
        item.Free;
        raise;
      end;
    end);
end;

procedure TTestCollectionList.TestDelete;
var
  item: TMyCollectionItem;
begin
  TMyCollectionItem.Create(Coll);
  item := TMyCollectionItem.Create(Coll);
  CheckEquals(2, SUT.Count);
  SUT.Delete(0);
  CheckEquals(1, SUT.Count);
  CheckSame(item, SUT[0]);
end;

procedure TTestCollectionList.TestDeleteRange;
var
  item: TMyCollectionItem;
begin
  item := TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  CheckEquals(3, SUT.Count);
  SUT.DeleteRange(1, 2);
  CheckEquals(1, SUT.Count);
  CheckSame(item, SUT[0]);
end;

procedure TTestCollectionList.TestElementType;
var
  list: IList<TMyCollectionItem>;
begin
  list := Coll.AsList<TMyCollectionItem>;
  CheckTrue(SUT.ElementType = TMyCollectionItem.ClassInfo);
  CheckTrue(list.ElementType = TMyCollectionItem.ClassInfo);
  CheckException(EArgumentException,
    procedure
    begin
      Coll.AsList<TMyOtherCollectionItem>;
    end);
end;

procedure TTestCollectionList.TestEnumeratorMoveNext_VersionMismatch;
var
  e: IEnumerator<TCollectionItem>;
begin
  TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  ExpectedException := EInvalidOperationException;
  e := SUT.GetEnumerator;
  while e.MoveNext do
    SUT.Add(TMyCollectionItem.Create(nil));
  ExpectedException := nil;
end;

procedure TTestCollectionList.TestEnumeratorReset;
var
  item: TCollectionItem;
  e: IEnumerator<TCollectionItem>;
begin
  item := TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  e := SUT.GetEnumerator;
  while e.MoveNext do;
  e.Reset;
  CheckTrue(e.MoveNext);
  CheckSame(item, e.Current);
end;

procedure TTestCollectionList.TestEnumeratorReset_VersionMismatch;
var
  e: IEnumerator<TCollectionItem>;
begin
  TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  e := SUT.GetEnumerator;
  while e.MoveNext do;
  SUT.Add(TMyCollectionItem.Create(nil));
  ExpectedException := EInvalidOperationException;
  e.Reset;
  ExpectedException := nil;
end;

procedure TTestCollectionList.TestExchange;
var
  item1, item2: TMyCollectionItem;
begin
  item1 := TMyCollectionItem.Create(Coll);
  TMyCollectionItem.Create(Coll);
  item2 := TMyCollectionItem.Create(Coll);
  SUT.Exchange(0, 2);
  CheckSame(item1, SUT[2]);
  CheckSame(item2, SUT[0]);
end;

procedure TTestCollectionList.TestExtract;
var
  item: TMyCollectionItem;
begin
  TMyCollectionItem.Create(Coll);
  item := TMyCollectionItem.Create(Coll);
  CheckEquals(2, SUT.Count);
  SUT.Extract(item);
  CheckEquals(1, SUT.Count);
  CheckNull(item.Collection);
  item.Free;
end;

procedure TTestCollectionList.TestExtract_ItemNotInList;
var
  item1: TMyCollectionItem;
  item2: TCollectionItem;
begin
  item1 := TMyCollectionItem.Create(nil);
  item2 := SUT.Extract(item1);
  CheckNull(item2);
  item1.Free;
end;

procedure TTestCollectionList.TestMove;
var
  item1, item2, item3: TMyCollectionItem;
begin
  item1 := TMyCollectionItem.Create(Coll);
  item2 := TMyCollectionItem.Create(Coll);
  item3 := TMyCollectionItem.Create(Coll);
  SUT.Move(0, 2);
  CheckSame(item1, SUT[2]);
  CheckSame(item2, SUT[0]);
  CheckSame(item3, SUT[1]);
end;

{ TTestEnumerable }

procedure TTestEnumerable.SetUp;
begin
  SUT := TCollections.Range(0, MaxItems);
end;

procedure TTestEnumerable.TestToArray;
var
  values: TArray<Integer>;
  i: Integer;
begin
  values := SUT.ToArray;
  CheckEquals(MaxItems, Length(values));
  for i in SUT do
    CheckEquals(i, values[i]);
end;

{ TTestListAdapter }

procedure TTestListAdapter.ListChanged(Sender: TObject; const Item: Integer;
  Action: TCollectionChangedAction);
begin
  Check(True);
end;

procedure TTestListAdapter.SetUp;
begin
  InternalList := TCollections.CreateList<Integer>([1, 2, 3]);
  SUT := InternalList.AsList;
end;

procedure TTestListAdapter.TestListAdd;
begin
  SUT.Add(4);
  CheckTrue(InternalList.EqualsTo([1, 2, 3, 4]));
end;

procedure TTestListAdapter.TestListAddRangeArray;
begin
  SUT.AddRange([4, 5]);
  CheckTrue(InternalList.EqualsTo([1, 2, 3, 4, 5]));
end;

procedure TTestListAdapter.TestListAddRangeIEnumerable;
begin
  SUT.AddRange(TCollections.Range(4, 2));
  CheckTrue(InternalList.EqualsTo([1, 2, 3, 4, 5]));
end;

procedure TTestListAdapter.TestListAsReadOnlyList;
var
  readOnlyList: IReadOnlyList;
  i: Integer;
begin
  readOnlyList := SUT.AsReadOnlyList;
  for i := 0 to readOnlyList.Count - 1 do
    CheckEquals(i + 1, readOnlyList[i].AsInteger);
end;

procedure TTestListAdapter.TestListClear;
begin
  SUT.Clear;
  CheckTrue(InternalList.IsEmpty)
end;

procedure TTestListAdapter.TestListDelete;
begin
  SUT.Delete(1);
  CheckTrue(InternalList.EqualsTo([1, 3]));
end;

procedure TTestListAdapter.TestListDeleteRange;
begin
  SUT.DeleteRange(1, 2);
  CheckTrue(InternalList.EqualsTo([1]));
end;

procedure TTestListAdapter.TestListDeleteRange2;
begin
  SUT.DeleteRange(0, 2);
  CheckTrue(InternalList.EqualsTo([3]));
end;

procedure TTestListAdapter.TestListExchange;
begin
  SUT.Exchange(0, 2);
  CheckTrue(InternalList.EqualsTo([3, 2, 1]));
end;

procedure TTestListAdapter.TestListExtract;
begin
  SUT.Extract(2);
  CheckTrue(InternalList.EqualsTo([1, 3]));
end;

procedure TTestListAdapter.TestListExtractRangeArray;
begin
  SUT.ExtractRange([3, 1]);
  CheckTrue(InternalList.EqualsTo([2]));
end;

procedure TTestListAdapter.TestListExtractRangeIEnumerable;
begin
  SUT.ExtractRange(TCollections.Range(1, 2));
  CheckTrue(InternalList.EqualsTo([3]));
end;

procedure TTestListAdapter.TestListGetCount;
begin
  CheckEquals(3, SUT.Count);
end;

procedure TTestListAdapter.TestListGetElementType;
begin
  Check(SUT.ElementType = TypeInfo(Integer));
end;

procedure TTestListAdapter.TestListGetEnumerator;
var
  v: TValue;
  i: Integer;
begin
  i := 0;
  for v in SUT do
  begin
    CheckEquals(InternalList[i], v.AsInteger);
    Inc(i);
  end;
  CheckEquals(i, 3);
end;

procedure TTestListAdapter.TestListGetIsReadOnly;
begin
  CheckFalse(SUT.IsReadOnly);
end;

procedure TTestListAdapter.TestListGetItem;
begin
  CheckEquals(2, SUT[1].AsInteger);
end;

procedure TTestListAdapter.TestListGetOnChanged;
var
  m: TMethod;
begin
  TCollectionChangedEvent<Integer>(m) := ListChanged;
  SUT.OnChanged.Add(m);
  SUT.Clear;
end;

procedure TTestListAdapter.TestListIndexOf;
begin
  CheckEquals(1, SUT.IndexOf(2));
  SUT.Add(1);
  CheckEquals(3, SUT.IndexOf(1, 1));
  CheckEquals(-1, SUT.IndexOf(3, 0, 2));
end;

procedure TTestListAdapter.TestListInsert;
begin
  SUT.Insert(0, 3);
  CheckTrue(InternalList.EqualsTo([3, 1, 2, 3]));
end;

procedure TTestListAdapter.TestListInsertRangeArray;
begin
  SUT.InsertRange(0, [3, 2]);
  CheckTrue(InternalList.EqualsTo([3, 2, 1, 2, 3]));
end;

procedure TTestListAdapter.TestListInsertRangeIEnumerable;
begin
  SUT.InsertRange(0, TCollections.Range(3, 2));
  CheckTrue(InternalList.EqualsTo([3, 4, 1, 2, 3]));
end;

procedure TTestListAdapter.TestListLastIndexOf;
begin
  SUT.AddRange([1, 3, 1]);
  CheckEquals(5, SUT.LastIndexOf(1));
  CheckEquals(3, SUT.LastIndexOf(1, 4));
  CheckEquals(-1, SUT.LastIndexOf(2, 5, 3));
end;

procedure TTestListAdapter.TestListMove;
begin
  SUT.Move(2, 0);
  CheckTrue(InternalList.EqualsTo([3, 1, 2]));
end;

procedure TTestListAdapter.TestListQueryInterface;
var
  list: IList<Integer>;
  collection: ICollection<Integer>;
  enumerable: IEnumerable<Integer>;
begin
  list := SUT as IList<Integer>;
  CheckSame(InternalList, list);
  collection := SUT as ICollection<Integer>;
  CheckSame(InternalList, collection);
  enumerable := SUT as IEnumerable<Integer>;
  CheckSame(enumerable as TObject, SUT as TObject);
end;

procedure TTestListAdapter.TestListRemove;
begin
  SUT.Remove(2);
  CheckTrue(InternalList.EqualsTo([1, 3]));
end;

procedure TTestListAdapter.TestListRemoveRangeArray;
begin
  SUT.RemoveRange([3, 1]);
  CheckTrue(InternalList.EqualsTo([2]));
end;

procedure TTestListAdapter.TestListRemoveRangeIEnumerable;
begin
  SUT.RemoveRange(TCollections.Range(1, 2));
  CheckTrue(InternalList.EqualsTo([3]));
end;

procedure TTestListAdapter.TestListReverse;
begin
  SUT.Reverse;
  CheckTrue(InternalList.EqualsTo([3, 2, 1]));
end;

procedure TTestListAdapter.TestListReverse2;
begin
  SUT.Reverse(1, 2);
  CheckTrue(InternalList.EqualsTo([1, 3, 2]));
end;

procedure TTestListAdapter.TestListSetItem;
begin
  SUT[2] := 4;
  CheckTrue(InternalList.EqualsTo([1, 2, 4]));
end;

procedure TTestListAdapter.TestListSort;
begin
  SUT.AddRange([9, 7, 5, 4, 6, 8]);
  SUT.Sort;
  CheckTrue(InternalList.EqualsTo([1, 2, 3, 4, 5, 6, 7, 8, 9]));
end;

end.
