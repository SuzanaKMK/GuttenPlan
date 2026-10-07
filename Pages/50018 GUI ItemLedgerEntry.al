pageextension 50018 GUI_ItemLedEntryExt extends "Item Ledger Entries"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("GUI-to-BC Entry No"; Rec."GUI-to-BC Entry No")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the GUI-to-BC Entry No field.', Comment = '%';
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
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}