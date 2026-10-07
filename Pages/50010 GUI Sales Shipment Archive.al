page 50010 "GUI Sales Shipment Archive"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "GUI-to-BC Sales Line Arch";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Variant Code field.', Comment = '%';
                }
                field("GUI Description"; Rec."GUI Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Description field.', Comment = '%';
                }
                field("GUI Type"; Rec."GUI Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Type field.', Comment = '%';
                }
                field("GUI Time of Action"; Rec."GUI Time of Action")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Time of Action field.', Comment = '%';
                }

                field("GUI Pallet"; Rec."GUI Pallet")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Pallet field.', Comment = '%';
                }

                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.', Comment = '%';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document No. field.', Comment = '%';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Date field.', Comment = '%';
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Line No. field.', Comment = '%';
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Type field.', Comment = '%';
                }

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.', Comment = '%';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity field.', Comment = '%';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Unit of Measure Code field.', Comment = '%';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Lot No. field.', Comment = '%';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Expiration Date field.', Comment = '%';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Transaction No. field.', Comment = '%';
                }
                field("Posted Document Type"; Rec."Posted Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Posted Document Type field.', Comment = '%';
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Posted Document No. field.', Comment = '%';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Entry No. field.', Comment = '%';
                }
                field("GUI User ID"; Rec."GUI User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI User ID field.', Comment = '%';
                }
                field("Item-Lot No."; Rec."Item-Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item-Lot No. field.', Comment = '%';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        myInt: Integer;
}