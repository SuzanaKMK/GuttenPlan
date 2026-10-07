codeunit 50015 GUItoBC_Integration_WS
{

    trigger OnRun()
    begin
        IF GUIALLOWED THEN
            SimulateWSMethods
        ELSE
            Code;
    end;

    var
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';
        NothingToHandleText: TextConst ENU = 'Nothing to handle.';
        UnknownErrorText: TextConst ENU = 'Unknown Error.';



    local procedure SimulateWSMethods();
    VAR
        MenuString: TextConst ENU = 'Master Workorder,Inventory Adjmt.,Prod. Output,Purchase Rcpt.,Sales Shpmt.';
        ErrMsg: Text;
        Selection: Integer;
        SuccessText: TextConst ENU = 'Completed Successfully.';

    begin

        Selection := STRMENU(MenuString);
        CASE Selection OF
            1:
                ErrMsg := MasterWorkOrder('', 0, '', '');
            2:
                ErrMsg := InventoryAdjustment('', '');
            3:
                ErrMsg := ProductionOutput('');
            4:
                ErrMsg := PurchaseReceipt('');
            5:
                ErrMsg := SalesShipment('');
            ELSE
                EXIT;
        end;

        IF ErrMsg <> '' THEN
            MESSAGE(ErrMsg)
        ELSE
            MESSAGE(SuccessText);

    end;

    local procedure Code();
    VAR
        ErrMsg: Text;
    begin
        //002 Start
        ErrMsg := MasterWorkOrder('', 0, '', '');
        ErrMsg := InventoryAdjustment('', '');
        ErrMsg := ProductionOutput('');
        ErrMsg := PurchaseReceipt('');
        ErrMsg := SalesShipment('');
        //002 end
    end;

    [ServiceEnabled]
    procedure MasterWorkOrder(OrderDate: Text; OrderShift: Integer; ItemNo: Code[20]; ProdLineNo: Code[10]) ErrMsg: Text;
    VAR
        DateVar: Date;
        Handled: Boolean;
    begin
        //002 added OrderNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;

        //003 Start
        OrderDate := DELCHR(OrderDate, '<>', '"');
        EVALUATE(DateVar, OrderDate);
        //003 end

        OnProcessMasterWorkOrder(DateVar, OrderShift, ItemNo, ProdLineNo, ErrMsg, Handled); //002
    end;

    [ServiceEnabled]
    procedure InventoryAdjustment(DocNo: Code[20]; ItemNo: Code[20]) ErrMsg: Text;
    VAR
        Handled: Boolean;
    begin
        ErrMsg := '';
        CLEARLASTERROR;

        OnProcessInventoryAdjustment(DocNo, ItemNo, ErrMsg, Handled); //002
    end;

    [ServiceEnabled]
    procedure PurchaseReceipt(DocNo: Code[20]) ErrMsg: Text;
    VAR
        Handled: Boolean;
    begin
        //002 added OrderNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;

        OnProcessPurchaseReceipt(DocNo, ErrMsg, Handled); //002
    end;

    [ServiceEnabled]
    procedure SalesShipment(DocNo: Code[20]) ErrMsg: Text;
    VAR
        Handled: Boolean;
    begin
        //002 added OrderNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;

        OnProcessSalesShipment(DocNo, ErrMsg, Handled); //002
    end;

    [ServiceEnabled]
    procedure ProductionOutput(OrderNo: Code[20]) ErrMsg: Text;
    VAR
        Handled: Boolean;
    begin
        //002 added OrderNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;

        OnProcessProductionOutput(OrderNo, ErrMsg, Handled); //002
    end;

    LOCAL PROCEDURE HandleSalesShipment(DocNo: Code[20]) ErrMsg: Text;
    VAR
        BufferLine: Record 50003;
    BEGIN
        //007 added DocNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;

        //007 Start
        SetSalesShipmentFilterFor(BufferLine, DocNo);
        CheckSalesShipment(BufferLine, FALSE);
        IF NOT ProcessSalesShipment(BufferLine, ErrMsg) THEN //003
                                                             //007 End
            IF ErrMsg = '' THEN //003
                ErrMsg := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(ErrMsg));
    END;

    LOCAL PROCEDURE ProcessSalesShipment(VAR BufferLine: Record 50003; VAR ErrMsg: Text): Boolean;
    VAR
        BufferPostBatch: Codeunit 50032;
        FailedCounter: Integer;
    BEGIN
        //007 added DocNo parameter //
        WITH BufferLine DO BEGIN
            //007 Start
            SETRANGE("Ready for Processing", TRUE);
            IF NOT ISEMPTY THEN BEGIN
                BufferPostBatch.SetHideDialog(NOT GUIALLOWED);
                BufferPostBatch.SetRunningResiliency;
                BufferPostBatch.CarryOutBatchAction(BufferLine);
                FailedCounter := BufferPostBatch.GetFailedCounter;
                IF FailedCounter <> 0 THEN
                    AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleSalesShipment()->"%1"', SkippedLineMsg));
                //007 End
            END ELSE
                AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleSalesShipment()->"%1"', NothingToHandleText)); //003

            SETRANGE("Ready for Processing"); //007
            IF NOT FIND('=><') THEN
                RESET;
        END;
        EXIT(ErrMsg = ''); //003
    END;


    LOCAL PROCEDURE AddToErrorMsg(VAR ErrMsg: Text; Text: Text);
    BEGIN
        //003 Start
        IF ErrMsg = '' THEN
            ErrMsg := COPYSTR(Text, 1, MAXSTRLEN(ErrMsg))
        ELSE
            IF STRLEN(ErrMsg) + STRLEN(Text) + 2 <= MAXSTRLEN(ErrMsg) THEN
                ErrMsg := ErrMsg + '->' + Text;
        //003 End
    END;

    LOCAL PROCEDURE ClearUnitCost(ItemJournalLine: Record 83);
    BEGIN
        //004.djc Start
        WITH ItemJournalLine DO BEGIN
            "Unit Cost" := 0;
            MODIFY;
        END;
        //004.djc End
    END;

    LOCAL PROCEDURE ClearCostAndTime(ProdOrderRoutingLine: Record 5409);
    BEGIN
        //004.djc Start
        WITH ProdOrderRoutingLine DO BEGIN
            "Unit Cost per" := 0;
            "Setup Time" := 0;
            "Run Time" := 0;
            MODIFY;
        END;
        //004.djc End
    END;


    LOCAL PROCEDURE SetSalesShipmentFilterFor(VAR BufferLine: Record 50003; DocNo: Code[20]);
    BEGIN
        //007 Start
        WITH BufferLine DO BEGIN
            RESET;
            SETFILTER("Processing Status", '>%1', "Processing Status"::New);
            IF DocNo <> '' THEN
                SETRANGE("Document No.", DocNo);
        END;
        //007 End
    END;

    LOCAL PROCEDURE CheckSalesShipment(VAR BufferLine: Record 50003; NoCommit: Boolean);
    VAR
        BufferCheckLine: Codeunit 50030;
    BEGIN
        //007 added DocNo parameter //
        WITH BufferLine DO BEGIN
            //007 Start
            SETRANGE(Processed, FALSE);
            IF NOT ISEMPTY THEN BEGIN
                FINDSET(TRUE, FALSE);
                REPEAT
                    BufferCheckLine.RunCheck(BufferLine);
                UNTIL NEXT = 0;
                IF NOT NoCommit THEN
                    COMMIT;
            END;
            SETRANGE(Processed);
            //007 End
        END;
    END;

    /* LOCAL PROCEDURE ProcessSalesShipment(VAR BufferLine : Record 50003;VAR ErrMsg : Text) : Boolean;
    VAR
      BufferPostBatch : Codeunit 50032;
      FailedCounter : Integer;
    BEGIN
      //007 added DocNo parameter //
      WITH BufferLine DO BEGIN
        //007 Start
        SETRANGE("Ready for Processing",TRUE);
        IF NOT ISEMPTY THEN BEGIN
          BufferPostBatch.SetHideDialog(NOT GUIALLOWED);
          BufferPostBatch.SetRunningResiliency;
          BufferPostBatch.CarryOutBatchAction(BufferLine);
          FailedCounter := BufferPostBatch.GetFailedCounter;
          IF FailedCounter <> 0 THEN
            AddToErrorMsg(ErrMsg,STRSUBSTNO('HandleSalesShipment()->"%1"',SkippedLineMsg));
        //007 End
        END ELSE
          AddToErrorMsg(ErrMsg,STRSUBSTNO('HandleSalesShipment()->"%1"',NothingToHandleText)); //003

        SETRANGE("Ready for Processing"); //007
        IF NOT FIND('=><') THEN
          RESET;
      END;
      EXIT(ErrMsg = ''); //003
    END; */



    [IntegrationEvent(true, false)]
    local procedure OnProcessMasterWorkOrder(OrderDate: Date; OrderShift: Integer; ItemNo: Code[20]; ProdLineNo: Code[10]; VAR ErrMsg: Text; VAR Handled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnProcessInventoryAdjustment(DocNo: Code[20]; ItemNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnProcessPurchaseReceipt(DocNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnProcessSalesShipment(DocNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnProcessProductionOutput(OrderNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    begin
    end;

}