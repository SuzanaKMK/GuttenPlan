codeunit 50018 KMK_ProdOrderBatchChange
{
    TableNo = "Production Order";

    trigger OnRun()
    var
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(NewFinishOrderWithoutOutput);
        ProdOrderStatusMgt.ChangeProdOrderStatus(Rec, NewProductionOrderStatus, NewPostingDate, NewUpdateUnitCost);
    end;

    procedure SetParameters(Status: Enum "Production Order Status"; PostingDate: Date; UpdateUnitCost: Boolean; FinishOrderWithoutOutput: Boolean)
    begin
        NewProductionOrderStatus := Status;
        NewPostingDate := PostingDate;
        NewUpdateUnitCost := UpdateUnitCost;
        NewFinishOrderWithoutOutput := FinishOrderWithoutOutput;
    end;

    var
        NewProductionOrderStatus: Enum "Production Order Status";
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
        NewFinishOrderWithoutOutput: Boolean;
}