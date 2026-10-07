codeunit 50017 KMK_Prod_OrderChangeStatusMgt
{
    TableNo = 5405;
    Permissions = TableData 242 = r,
                TableData 5405 = rimd,
                TableData 5410 = rid,
                TableData 5896 = rim;

    trigger OnRun()
    var
        ProdOrder: Record "Production Order";
    BEGIN

        ProdOrder.COPY(Rec);
        Code(ProdOrder);
        Rec := ProdOrder;
    END;


    var
        UseStdStatusRelease: Boolean;
        ProdOrderCheckCompleted: Boolean;

    PROCEDURE Code(VAR ProdOrder: Record 5405);
    VAR
        ChangeStatusForm: Page 99000882;
        ProdOrderStatusChgBatch: Codeunit KMK_ProdOrderChangeStat;
        NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished;
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
    BEGIN
        if ProdOrder.FindSet() then begin
            ChangeStatusForm.Set(ProdOrder);
            // IF ChangeStatusForm.RUNMODAL = ACTION::Yes THEN BEGIN
            If ChangeStatusForm.RunModal() = Action::Yes then begin
                ChangeStatusForm.ReturnPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost);

                ProdOrderStatusChgBatch.Set(NewStatus, NewPostingDate, NewUpdateUnitCost, FALSE);
                ProdOrderStatusChgBatch.SetUseStdStatusRelease(UseStdStatusRelease); //003
                ProdOrderStatusChgBatch.CarryOutBatchAction(ProdOrder);
                COMMIT;
            end;
        end;
    END;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnBeforeCheckBeforeFinishProdOrder', '', false, false)]
    local procedure OnBeforeCheckBeforeFinishProdOrder(var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    PROCEDURE SetProdOrderCheckCompleted(NewProdOrderCheckCompleted: Boolean);
    BEGIN
        //001 Start
        ProdOrderCheckCompleted := NewProdOrderCheckCompleted;
        //001 End
    END;


    /*  [EventSubscriber(ObjectType::Page, Page::"Change Production Order Status", 'OnAfterActionEvent', 'ToggleAcceptChangeStatus', false, false)]
     LOCAL PROCEDURE ReleasedProdOrdersOnAfterToggleAccept(VAR Rec: Record 5405);

     BEGIN
          WITH Rec DO BEGIN
             "Accept Change Status" := NOT "Accept Change Status";
             MODIFY;
         END; 

     END;
  

    [EventSubscriber(ObjectType::Page, Page::"Change Production Order Status", 'OnAfterActionEvent', 'UpdateAllAcceptChangeStatus', false, false)]
     LOCAL PROCEDURE ReleasedProdOrdersOnAfterUpdateAllAccept(VAR Rec: Record 5405);
     VAR
         ProdOrder: Record 5405;
     BEGIN
         WITH Rec DO BEGIN
             ProdOrder.COPY(Rec);
             ProdOrder.SETRANGE(Status, ProdOrder.Status::Released);
             ProdOrder.MODIFYALL("Accept Change Status", TRUE);
         END;
     END; 



    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]
    LOCAL PROCEDURE ReleasedProdOrdersOnAfterActionStatusChange(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
         ProdOrder := Rec;
        ProdOrder.SETRANGE(Status, ProdOrder.Status); //002
        ProdOrder.SETRANGE("No.", ProdOrder."No.");
        Code(ProdOrder); 
    END;

    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]

    LOCAL PROCEDURE ReleasedProdOrdersOnAfterActionStatusChangeBatch(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
        ProdOrder.COPY(Rec);
        //002 Start
        ProdOrder.SETRANGE(Status, ProdOrder.Status);
        ProdOrder.SETRANGE("Accept Change Status", TRUE);
        //002 End
        Code(ProdOrder); 
    END;


    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]
    LOCAL PROCEDURE ReleasedProdOrdersOnAfterActionStatusChangeBatchStd(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
        //003 Start
        SetUseStdStatusRelease(TRUE);

        ProdOrder.COPY(Rec);
        ProdOrder.SETRANGE(Status, ProdOrder.Status);
        ProdOrder.SETRANGE("Accept Change Status", TRUE);
        Code(ProdOrder); 
        //003 End
    END;


    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]
    LOCAL PROCEDURE ReleasedProdOrderOnAfterActionStatusChange(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
         ProdOrder := Rec;
        ProdOrder.SETRANGE(Status, ProdOrder.Status); //002
        ProdOrder.SETRANGE("No.", ProdOrder."No."); 
        Code(ProdOrder);
    END;

    PROCEDURE SetUseStdStatusRelease(NewUseStdStatusRelease: Boolean);
    BEGIN
        //003 Start
        UseStdStatusRelease := NewUseStdStatusRelease;
        //003 End
    END;

    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]
    LOCAL PROCEDURE ReleasedProdOrdersOnAfterActionStatusChange(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
        ProdOrder := Rec;
        ProdOrder.SETRANGE(Status, ProdOrder.Status); //002
        ProdOrder.SETRANGE("No.", ProdOrder."No.");
        Code(ProdOrder);
    END;

    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]

    LOCAL PROCEDURE ReleasedProdOrdersOnAfterActionStatusChangeBatch(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
        ProdOrder.COPY(Rec);
        //002 Start
        ProdOrder.SETRANGE(Status, ProdOrder.Status);
        ProdOrder.SETRANGE("Accept Change Status", TRUE);
        //002 End
        Code(ProdOrder);
    END;


    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]
    LOCAL PROCEDURE ReleasedProdOrdersOnAfterActionStatusChangeBatchStd(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
        //003 Start
        SetUseStdStatusRelease(TRUE);

        ProdOrder.COPY(Rec);
        ProdOrder.SETRANGE(Status, ProdOrder.Status);
        ProdOrder.SETRANGE("Accept Change Status", TRUE);
        Code(ProdOrder);
        //003 End
    END;


    [EventSubscriber(ObjectType::Page, Page::"Released production Orders", 'OnAfterActionEvent', 'BatchChangeStatus', false, false)]
    LOCAL PROCEDURE ReleasedProdOrderOnAfterActionStatusChange(VAR Rec: Record 5405);
    VAR
        ProdOrder: Record 5405;
    BEGIN
        ProdOrder := Rec;
        ProdOrder.SETRANGE(Status, ProdOrder.Status); //002
        ProdOrder.SETRANGE("No.", ProdOrder."No.");
        Code(ProdOrder);
    END;

    PROCEDURE SetUseStdStatusRelease(NewUseStdStatusRelease: Boolean);
    BEGIN
        //003 Start
        UseStdStatusRelease := NewUseStdStatusRelease;
        //003 End
    END;
*/
}