unit Customer_Orders_Model;

interface

uses
  Mapping.Attributes, Core.Types, Graphics;

type
  [Entity]   
  [Table('Customer_Orders', '')]
  TCustomer_Orders = class
  private   
    FOrder_Status_Code: Integer; 
    FDate_Order_Placed: TDateTime; 
    FTotal_Order_Price: Double; 
    FORDER_ID: Nullable<Integer>; 
    FCustomer_ID: Nullable<Integer>; 
    FCustomer_Payment_Method_Id: Integer; 
  public
    [Column('Order_Status_Code', [], -1, -1, -1, '')]
    property Order_Status_Code: Integer read FOrder_Status_Code write FOrder_Status_Code; 
    [Column('Date_Order_Placed', [], -1, -1, -1, '')]
    property Date_Order_Placed: TDateTime read FDate_Order_Placed write FDate_Order_Placed; 
    [Column('Total_Order_Price', [], -1, -1, -1, '')]
    property Total_Order_Price: Double read FTotal_Order_Price write FTotal_Order_Price; 
    [AutoGenerated]
    [Column('ORDER_ID', [cpPrimaryKey], -1, -1, -1, '')]
    property ORDER_ID: Nullable<Integer> read FORDER_ID write FORDER_ID; 
    [Column('Customer_ID', [], -1, -1, -1, '')]
    property Customer_ID: Nullable<Integer> read FCustomer_ID write FCustomer_ID; 
    [Column('Customer_Payment_Method_Id', [], -1, -1, -1, '')]
    property Customer_Payment_Method_Id: Integer read FCustomer_Payment_Method_Id write FCustomer_Payment_Method_Id; 
  
  end;
  
implementation    
  
end.

