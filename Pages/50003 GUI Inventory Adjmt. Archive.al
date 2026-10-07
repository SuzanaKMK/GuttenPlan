page 50003 "GUI Inventory Adjmt. Archive"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "GUI-to-BC Invt. Adjmt. Arch.";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Entry Type field.', Comment = '%';
                }

                field("Item-Lot No."; Rec."Item-Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item-Lot No. field.', Comment = '%';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item No. field.', Comment = '%';
                }
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
                field("GUI User ID"; Rec."GUI User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI User ID field.', Comment = '%';
                }
                field("GUI Pallet"; Rec."GUI Pallet")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Pallet field.', Comment = '%';
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Location Code field.', Comment = '%';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Bin Code field.', Comment = '%';
                    Visible = false;
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
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity (Base) field.', Comment = '%';
                    Visible = false;
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
                field("New Location Code"; Rec."New Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the New Location Code field.', Comment = '%';
                    Visible = false;
                }

                field("Journal Posted"; Rec."Journal Posted")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Posted field.', Comment = '%';
                }
                field("Journal Document No."; Rec."Journal Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Document No. field.', Comment = '%';
                }
                field("Journal Line No."; Rec."Journal Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Line No. field.', Comment = '%';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Batch Name field.', Comment = '%';
                }
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Template Name field.', Comment = '%';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Entry No. field.', Comment = '%';
                }
                field("Last DateTime Modified"; Rec."Last DateTime Modified")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Last DateTime Modified field.', Comment = '%';
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