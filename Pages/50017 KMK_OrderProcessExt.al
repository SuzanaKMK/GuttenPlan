pageextension 50017 KMK_OrderProcessRoleExt extends "Order Processor Role Center"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(Action61)
        {
            action(ShipToAddress)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Ship-to Address';
                Image = Customer;
                RunObject = Page "Ship-to Address List";
                ToolTip = 'View or edit detailed information for the Ship-to Address that you trade with.';
            }
        }

        addafter(Customers)
        {
            action(ShipToAdd)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Ship-to Address';
                Image = Customer;
                RunObject = Page "Ship-to Address List";
                ToolTip = 'View or edit detailed information for the Ship-to Address that you trade with.';
            }
        }

        addafter("Posted Documents")
        {
            group("GUI-to-BC")
            {
                Caption = 'GUI-to-BC';
                Image = FiledPosted;
                ToolTip = 'View the GUI Documents';
                action(MakeOrders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GUI Master Work Orders';
                    Image = PostedOrder;
                    RunObject = Page "GUI Master Work Ord. Worksheet";
                    ToolTip = 'Open GUI Master Work Orders';
                }
                action(OutputJournal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GUI Output Line Worksheet';
                    Image = PostedOrder;
                    RunObject = Page "GUI Output Line Worksheet";
                    ToolTip = 'Open GUI Output Line Worksheet';
                }
                action(InvAdjmt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GUI Inventory Adjmt. Worksheet';
                    Image = PostedReturnReceipt;
                    RunObject = Page "GUI Inventory Adjmt. Worksheet";
                    ToolTip = 'Open GUI Inventory Adjmt. Worksheet';
                }
                action(SalesShipment)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GUI Sales Shipment Worksheet';
                    Image = PostedShipment;
                    RunObject = Page "GUI Sales Shipment Worksheet";
                    ToolTip = 'Open GUI Sales Shipment Worksheet';
                }
                action(PurchaseOrder)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GUI Purchase Receipt Worksheet';
                    RunObject = page "GUI Purchase Receipt Worksheet";
                    ToolTip = 'Open GUI Purchase Receipt Worksheet';
                }

                group("GUI-to-BC Archive")
                {
                    Caption = 'GUI-to-BC Archive';
                    Image = FiledPosted;
                    ToolTip = 'View Archived GUI Documents';
                    action(MakeOrdersArch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'GUI Master Work Ord. Archive';
                        Image = PostedOrder;
                        RunObject = Page "GUI Master Work Ord. Archive";
                        ToolTip = 'Open GUI Master Work Ord. Archive';
                    }
                    action(OutputJournalArch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'GUI Output Line Archive';
                        Image = PostedOrder;
                        RunObject = Page "GUI Output Line Archive";
                        ToolTip = 'Open GUI Output Line Archive';
                    }
                    action(InvAdjmtArch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'GUI Inventory Adjmt. Archive';
                        Image = PostedReturnReceipt;
                        RunObject = Page "GUI Inventory Adjmt. Archive";
                        ToolTip = 'Open GUI Inventory Adjmt. Archive';
                    }
                    action(SalesShipmentArch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'GUI Sales Shipment Archive';
                        Image = PostedShipment;
                        RunObject = Page "GUI Sales Shipment Archive";
                        ToolTip = 'Open GUI Sales Shipment Archive';
                    }
                    action(PurchaseOrderArch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'GUI Purchase Receipt Archive';
                        RunObject = page "GUI Purchase Receipt Archive";
                        ToolTip = 'Open GUI Purchase Receipt Archive';
                    }
                }
            }
        }
    }

    var
        myInt: Integer;
}