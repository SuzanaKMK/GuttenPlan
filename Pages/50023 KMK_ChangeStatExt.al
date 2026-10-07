pageextension 50023 KMK_ProdOrderChangeStat extends "Change Production Order Status"
{
    Editable = true;



    layout
    {
        // Add changes to page layout here
        addbefore("No.")
        {

            field("Accept Change Status"; Rec."Accept Change Status")
            {
                ApplicationArea = All;


            }
        }

        addbefore("Finished Date")
        {

            field(KMK_FinishedQty; Rec.KMK_FinishedQty)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the KMK_FinishedQty field.', Comment = '%';
            }
        }




    }

    actions
    {
        // Add changes to page actions here
        addlast(processing)


        // addafter("Change &Status")
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
        NewProductionOrderStatus: Enum "Production Order Status";
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
        NewFinishOrderWithoutOutput: Boolean;



    local procedure ChangeToggleSelectionFilter()
    var
        ProductionOrder: Record "Production Order";

    begin
        CurrPage.SetSelectionFilter(ProductionOrder);

        if ProductionOrder.FindSet() then
            repeat
                ProductionOrder."Accept Change Status" := true;
                ProductionOrder.Modify();
            until ProductionOrder.Next() = 0;
    end;




    local procedure ChangeStatusWithToggle()
    var
        ProductionOrder: Record "Production Order";
        ProdUpdateBatch: Codeunit KMK_ProdOrderChangeStat;
    begin
        CurrPage.SetSelectionFilter(ProductionOrder);

        if ProductionOrder.FindSet() then begin
            ProdUpdateBatch.CarryOutBatchAction(ProductionOrder);

        end;
    end;


}