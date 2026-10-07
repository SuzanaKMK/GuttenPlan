pageextension 50019 KMK_ProdOrder extends "Released Production Orders"
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

        addafter("Change &Status")
        {
            action(BatchChangeStatus)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Change &Status Batch (Std.)';
                Ellipsis = true;
                Image = ChangeStatus;
                ToolTip = 'Change the status of the selected production order(s) to a new one.';

                trigger OnAction()
                var
                begin
                    ChangeStatusWithToggle();
                end;

            }


        }


        addlast(Category_Process)
        {

            actionref(KMK_BatchChangeStatus; BatchChangeStatus)
            {
            }


        }


    }

    var
        myInt: Integer;

    procedure ChangeStatusWithToggle()
    var
        ProductionOrder: Record "Production Order";
        ProdUpdateBatch: Codeunit KMK_Prod_OrderChangeStatusMgt;
        ProdUpdateStatus: Codeunit KMK_Prod_OrderChangeStatusMgt;
    begin
        CurrPage.SetSelectionFilter(ProductionOrder);
        if ProductionOrder.FindSet() then begin
            ProdUpdateBatch.code(ProductionOrder);
        end;
    end;

}