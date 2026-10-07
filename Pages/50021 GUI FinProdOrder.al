pageextension 50021 GUI_FinProdOrder extends "Finished Production Orders"
{
    layout
    {
        // Add changes to page layout here
        addafter(Quantity)
        {

            field(KMK_FinishedQty; Rec.KMK_FinishedQty)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the KMK_FinishedQty field.', Comment = '%';
            }
        }

        addafter("ending Date-Time")
        {

            field("GUI Order Shift"; Rec."GUI Order Shift")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the GUI Order Shift field.', Comment = '%';
            }
            field("GUI Production Line No."; Rec."GUI Production Line No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the GUI Production Line No. field.', Comment = '%';
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