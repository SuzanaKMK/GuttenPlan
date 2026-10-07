pageextension 50020 GUI_ProdOrderCard extends "Released Production Order"
{
    layout
    {
        // Add changes to page layout here
        addafter("Last Date Modified")
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
            field(Mixes; Rec.Mixes)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Mixes field.', Comment = '%';
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