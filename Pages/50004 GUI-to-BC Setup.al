page 50004 "GUI-to-BC Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "GUI-to-BC Setup";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';



                group(Archive)
                {
                    Caption = 'Archive';
                    field("Enable Auto Archive"; Rec."Enable Auto Archive")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Enable Auto Archive field.', Comment = '%';
                    }

                }

                group(Inbound)
                {

                    Caption = 'Inbound';
                    field("Auto Archive Invt. Adjustment"; Rec."Auto Archive Invt. Adjustment")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Auto Archive Invt. Adjustment field.', Comment = '%';
                    }
                    field("Auto Archive Master Work Order"; Rec."Auto Archive Master Work Order")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Auto Archive Master Work Order field.', Comment = '%';
                    }
                    field("Auto Archive Output"; Rec."Auto Archive Output")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Auto Archive Output field.', Comment = '%';
                    }
                    field("Auto Archive Purchase"; Rec."Auto Archive Purchase")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Auto Archive Purchase field.', Comment = '%';
                    }
                    field("Auto Archive Sales"; Rec."Auto Archive Sales")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Auto Archive Sales field.', Comment = '%';
                    }
                }
            }

            group(Documents)
            {
                Caption = 'Documents';

                group(Purchase)
                {
                    Caption = 'Purchase';

                    field("Enable Auto Purch. Post"; Rec."Enable Auto Purch. Post")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Enable Auto Purch. Post field.', Comment = '%';
                    }
                    field("Purchase Post Action"; Rec."Purchase Post Action")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Purchase Post Action field.', Comment = '%';
                    }
                }

                group(Sales)
                {
                    Caption = 'Sales';

                    field("Enable Auto Sales Post"; Rec."Enable Auto Sales Post")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Enable Auto Sales Post field.', Comment = '%';
                    }
                    field("Sales Post Action"; Rec."Sales Post Action")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Sales Post Action field.', Comment = '%';
                    }
                    field("Print BOL on Shipment Post"; Rec."Print BOL on Shipment Post")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Print BOL on Shipment Post field.', Comment = '%';
                    }


                }

                group(Inventory)
                {
                    Caption = 'Inventory';
                    field("Enable Auto Invt. Adjmt. Post"; Rec."Enable Auto Invt. Adjmt. Post")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Enable Auto Invt. Adjmt. Post field.', Comment = '%';
                    }

                    field("Item Jnl Batch Name"; Rec."Item Jnl Batch Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Item Jnl Batch Name field for Positive and negative Adjmt. ', Comment = '%';
                    }
                }

                group("Prod. Output")
                {
                    Caption = 'Prod. Output';
                    field("Enable Auto Prod. Output Post"; Rec."Enable Auto Prod. Output Post")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Enable Auto Prod. Output Post field.', Comment = '%';
                    }
                    field("Output Batch Name"; Rec."Output Batch Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Output Batch Name field.', Comment = '%';

                    }
                }
                group("Production Order")
                {
                    Caption = 'Production';
                    field("Prod. Change Status Set Qty"; Rec."Prod. Change Status Set Qty")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Prod. Change Status Set Qty field.', Comment = '%';
                    }

                }
            }


        }
    }

    actions
    {

    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        xGUIBCSetup := Rec;

    end;

    var
        myInt: Integer;
        xGUIBCSetup: Record "GUI-to-BC Setup";
}