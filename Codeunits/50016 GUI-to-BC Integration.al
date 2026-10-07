codeunit 50016 GUIToBCIntegrationMgt
{
    trigger OnRun()
    begin

    end;


    VAR
        NothingToHandleText: TextConst ENU = 'Nothing to handle.';
        UnknownErrorText: TextConst ENU = 'Unknown Error.';
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';

    local procedure HandleMasterWorkOrder(OrderDate: Date; OrderShift: Integer; ItemNo: Code[20]; ProdLineNo: Code[10]) ErrMsg: Text;
    VAR
        BufferLine: Record 50000;
    begin
        ErrMsg := '';
        CLEARLASTERROR;


        SetMasterWorkOrderFilterFor(BufferLine, OrderDate, OrderShift, ItemNo, ProdLineNo);
        CheckMasterWorkOrder(BufferLine, FALSE);
        IF NOT ProcessMasterWorkOrder(BufferLine, ErrMsg) THEN
            IF ErrMsg = '' THEN //003
                ErrMsg := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(ErrMsg));
    end;

    local procedure CheckMasterWorkOrder(VAR BufferLine: Record 50000; NoCommit: Boolean);
    VAR
        BufferCheckLine: Codeunit 50000;
    begin
        /*     //007 added parameters //
            WITH BufferLine DO begin

                SETRANGE(Processed, FALSE);
                IF NOT ISEMPTY THEN begin
                    FINDSET(TRUE, FALSE);
                    REPEAT
                        BufferCheckLine.RunCheck(BufferLine);
                    UNTIL NEXT = 0;
                    IF NOT NoCommit THEN
                        COMMIT;
                end;
                SETRANGE(Processed);

            end; */

        // Filter for unprocessed records only
        BufferLine.SetRange(Processed, false);

        // Quick existence check (lightweight, no locking)
        if BufferLine.IsEmpty then begin
            BufferLine.SetRange(Processed);
            exit;
        end;


        if BufferLine.FindSet(false, false) then
            repeat
                BufferCheckLine.RunCheck(BufferLine);
            until BufferLine.Next = 0;

        // Optional commit only if requested
        if not NoCommit then
            Commit;

        // Clean up filter for caller
        BufferLine.SetRange(Processed);
    end;

    local procedure ProcessMasterWorkOrder(VAR BufferLine: Record 50000; VAR ErrMsg: Text): Boolean;
    VAR
        BufferPostBatch: Codeunit 50013;
        FailedCounter: Integer;
    begin
        //007 added parameters //
        /*   WITH BufferLine DO begin

              SETRANGE("Ready for Processing", TRUE);
              IF NOT ISEMPTY THEN begin
                  BufferPostBatch.SetHideDialog(NOT GUIALLOWED);
                  BufferPostBatch.SetRunningResiliency;
                  BufferPostBatch.CarryOutBatchAction(BufferLine);
                  FailedCounter := BufferPostBatch.GetFailedCounter;
                  IF FailedCounter <> 0 THEN
                      AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleMasterWorkOrder()->"%1"', SkippedLineMsg));

              end ELSE
                  AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleMasterWorkOrder()->"%1"', NothingToHandleText)); //003

              SETRANGE("Ready for Processing"); //007
              IF NOT FIND('=><') THEN
                  RESET;
          end;
          EXIT(ErrMsg = ''); //003 */

        // Work only on lines that are ready for processing
        BufferLine.SetRange("Ready for Processing", true);

        if BufferLine.IsEmpty then begin
            AddToErrorMsg(
              ErrMsg,
              StrSubstNo('HandleMasterWorkOrder()->"%1"', NothingToHandleText)); //003
        end else begin
            BufferPostBatch.SetHideDialog(not GuiAllowed);
            BufferPostBatch.SetRunningResiliency;
            BufferPostBatch.CarryOutBatchAction(BufferLine);

            FailedCounter := BufferPostBatch.GetFailedCounter;
            if FailedCounter <> 0 then
                AddToErrorMsg(
                  ErrMsg,
                  StrSubstNo('HandleMasterWorkOrder()->"%1"', SkippedLineMsg));
        end;

        // Remove the helper filter
        BufferLine.SetRange("Ready for Processing");

        // If there are no records at all under current filters, reset completely
        if not BufferLine.Find('=><') then
            BufferLine.Reset;

        exit(ErrMsg = ''); //003
    end;

    local procedure SetMasterWorkOrderFilterFor(VAR BufferLine: Record 50000; OrderDate: Date; OrderShift: Integer; ItemNo: Code[20]; ProdLineNo: Code[10]);
    begin

        /*         WITH BufferLine DO begin
                    RESET;
                    SETFILTER("Processing Status", '>%1', "Processing Status"::"New");
                    IF OrderDate <> 0D THEN
                        SETRANGE("Order Date", OrderDate);
                    IF OrderShift <> 0 THEN
                        SETRANGE("Order Shift", OrderShift);
                    IF ItemNo <> '' THEN
                        SETRANGE("Item No.", ItemNo);
                    IF ProdLineNo <> '' THEN
                        SETRANGE("Production Line No.", ProdLineNo);
                end;
         */
        BufferLine.Reset;


        BufferLine.SetFilter(
            "Processing Status",
            '>%1',
            BufferLine."Processing Status"::"New");

        if OrderDate <> 0D then
            BufferLine.SetRange("Order Date", OrderDate);

        if OrderShift <> 0 then
            BufferLine.SetRange("Order Shift", OrderShift);

        if ItemNo <> '' then
            BufferLine.SetRange("Item No.", ItemNo);

        if ProdLineNo <> '' then
            BufferLine.SetRange("Production Line No.", ProdLineNo);
    end;

    local procedure HandleInventoryAdjustment(DocNo: Code[20]; ItemNo: Code[20]) ErrMsg: Text;
    VAR
        BufferLine: Record 50001;
    begin
        ErrMsg := '';
        ClearLastError();


        SetInventoryAdjustmentFilterFor(BufferLine, DocNo, ItemNo);
        CheckInventoryAdjustment(BufferLine, FALSE);
        if not ProcessInventoryAdjustment(BufferLine, ErrMsg) then
            if ErrMsg = '' then //003
                ErrMsg := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(ErrMsg));
    end;

    local procedure CheckInventoryAdjustment(VAR BufferLine: Record 50001; NoCommit: Boolean);
    VAR
        BufferCheckLine: Codeunit 50005;
    begin
        /*   WITH BufferLine DO begin

              SETRANGE(Processed, FALSE);
              IF NOT ISEMPTY THEN begin
                  FINDSET(TRUE, FALSE);
                  REPEAT
                      BufferCheckLine.RunCheck(BufferLine);
                  UNTIL NEXT = 0;
                  IF NOT NoCommit THEN
                      COMMIT;
              end;
              SETRANGE(Processed);

          end; */


        BufferLine.SetRange(Processed, false);
        if BufferLine.IsEmpty then begin
            BufferLine.SetRange(Processed);
            exit;
        end;


        if BufferLine.FindSet(false, false) then
            repeat
                BufferCheckLine.RunCheck(BufferLine);
            until BufferLine.Next = 0;


        if not NoCommit then
            Commit;

        BufferLine.SetRange(Processed);
    end;

    local procedure ProcessInventoryAdjustment(VAR BufferLine: Record 50001; VAR ErrMsg: Text): Boolean;
    VAR
        BufferPostBatch: Codeunit 50007;
        FailedCounter: Integer;
    begin
        /*  WITH BufferLine DO begin

             SETRANGE("Ready for Processing", TRUE);
             IF NOT ISEMPTY THEN begin
                 BufferPostBatch.SetHideDialog(NOT GUIALLOWED);
                 BufferPostBatch.SetRunningResiliency;
                 BufferPostBatch.CarryOutBatchAction(BufferLine);
                 FailedCounter := BufferPostBatch.GetFailedCounter;
                 IF FailedCounter <> 0 THEN
                     AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleInventoryAdjustment()->"%1"', SkippedLineMsg));

             end ELSE
                 AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleInventoryAdjustment()->"%1"', NothingToHandleText)); //003

             SETRANGE("Ready for Processing"); //007
             IF NOT FIND('=><') THEN
                 RESET;
         end;
         EXIT(ErrMsg = ''); //003 */

        // 1. Use a separate variable so you don't keep filters/locks on the caller's record longer than needed
        BufferLine.Reset();
        BufferLine.SetRange("Ready for Processing", true);

        // IsEmpty() is preferred over Count() to avoid heavy locking
        if BufferLine.IsEmpty() then begin
            AddToErrorMsg(
              ErrMsg,
              StrSubstNo('HandleInventoryAdjustment()->"%1"', NothingToHandleText));
            exit(ErrMsg = '');
        end;

        // 2. Do all “expensive” or UI-related work before any write operations inside BufferPostBatch
        BufferPostBatch.SetHideDialog(not GuiAllowed);
        BufferPostBatch.SetRunningResiliency;

        // 3. Let the batch codeunit do fast, set-based updates, and ensure it does not hold locks longer than needed
        //    (inside CarryOutBatchAction, prefer FindSet(false, false) and ModifyAll/Insert/DeleteAll patterns)
        BufferPostBatch.CarryOutBatchAction(BufferLine);

        FailedCounter := BufferPostBatch.GetFailedCounter;
        if FailedCounter <> 0 then
            AddToErrorMsg(
              ErrMsg,
              StrSubstNo('HandleInventoryAdjustment()->"%1"', SkippedLineMsg));

        // 4. Release filter on "Ready for Processing" and avoid unnecessary FIND
        BufferLine.SetRange("Ready for Processing");
        BufferLine.Reset();

        exit(ErrMsg = '');
    end;

    local procedure SetInventoryAdjustmentFilterFor(var BufferLine: Record "GUI-to-BC Invt. Adjmt. Line"; DocNo: Code[20]; ItemNo: Code[20]);
    begin

        /*   WITH BufferLine DO begin
              RESET;
              SETFILTER("Processing Status", '>%1', "Processing Status"::New);
              IF DocNo <> '' THEN
                  SETRANGE("Document No.", DocNo);
              IF ItemNo <> '' THEN
                  SETRANGE("Item No.", ItemNo);
          end; */

        BufferLine.Reset;
        BufferLine.SetFilter("Processing Status", '>%1', BufferLine."Processing Status"::New);

        if DocNo <> '' then
            BufferLine.SetRange("Document No.", DocNo);

        if ItemNo <> '' then
            BufferLine.SetRange("Item No.", ItemNo);

    end;

    local procedure HandlePurchaseReceipt(DocNo: Code[20]) ErrMsg: Text;
    VAR
        BufferLine: Record 50002;
    begin
        //007 added DocNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;


        SetPurchaseReceiptFilterFor(BufferLine, DocNo);
        CheckPurchaseReceipt(BufferLine, FALSE);
        IF NOT ProcessPurchaseReceipt(BufferLine, ErrMsg) THEN
            IF ErrMsg = '' THEN //003
                ErrMsg := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(ErrMsg));
    end;

    local procedure CheckPurchaseReceipt(VAR BufferLine: Record 50002; NoCommit: Boolean);
    VAR
        BufferCheckLine: Codeunit 50025;
    begin
        //007 added DocNo parameter //
        WITH BufferLine DO begin

            SETRANGE(Processed, FALSE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    BufferCheckLine.RunCheck(BufferLine);
                UNTIL NEXT = 0;
                IF NOT NoCommit THEN
                    COMMIT;
            end;
            SETRANGE(Processed);

        end;
    end;

    local procedure ProcessPurchaseReceipt(VAR BufferLine: Record 50002; VAR ErrMsg: Text): Boolean;
    VAR
        BufferPostBatch: Codeunit 50027;
        FailedCounter: Integer;
    begin
        //007 added DocNo parameter //
        WITH BufferLine DO begin

            SETRANGE("Ready for Processing", TRUE);
            IF NOT ISEMPTY THEN begin
                BufferPostBatch.SetHideDialog(NOT GUIALLOWED);
                BufferPostBatch.SetRunningResiliency;
                BufferPostBatch.CarryOutBatchAction(BufferLine);
                FailedCounter := BufferPostBatch.GetFailedCounter;
                IF FailedCounter <> 0 THEN
                    AddToErrorMsg(ErrMsg, STRSUBSTNO('HandlePurchaseReceipt()->"%1"', SkippedLineMsg));

            end ELSE
                AddToErrorMsg(ErrMsg, STRSUBSTNO('HandlePurchaseReceipt()->"%1"', NothingToHandleText)); //003

            SETRANGE("Ready for Processing"); //007
            IF NOT FIND('=><') THEN
                RESET;
        end;
        EXIT(ErrMsg = ''); //003
    end;

    local procedure SetPurchaseReceiptFilterFor(VAR BufferLine: Record 50002; DocNo: Code[20]);
    begin

        WITH BufferLine DO begin
            RESET;
            SETFILTER("Processing Status", '>%1', "Processing Status"::New);
            IF DocNo <> '' THEN
                SETRANGE("Document No.", DocNo);
        end;

    end;

    local procedure HandleSalesShipment(DocNo: Code[20]) ErrMsg: Text;
    VAR
        BufferLine: Record 50003;
    begin
        //007 added DocNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;


        SetSalesShipmentFilterFor(BufferLine, DocNo);
        CheckSalesShipment(BufferLine, FALSE);
        IF NOT ProcessSalesShipment(BufferLine, ErrMsg) THEN //003

            IF ErrMsg = '' THEN //003
                ErrMsg := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(ErrMsg));
    end;

    local procedure CheckSalesShipment(VAR BufferLine: Record 50003; NoCommit: Boolean);
    VAR
        BufferCheckLine: Codeunit 50030;
    begin
        //007 added DocNo parameter //
        WITH BufferLine DO begin

            SETRANGE(Processed, FALSE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    BufferCheckLine.RunCheck(BufferLine);
                UNTIL NEXT = 0;
                IF NOT NoCommit THEN
                    COMMIT;
            end;
            SETRANGE(Processed);

        end;
    end;

    local procedure ProcessSalesShipment(VAR BufferLine: Record 50003; VAR ErrMsg: Text): Boolean;
    VAR
        BufferPostBatch: Codeunit 50032;
        FailedCounter: Integer;
    begin
        //007 added DocNo parameter //
        WITH BufferLine DO begin

            SETRANGE("Ready for Processing", TRUE);
            IF NOT ISEMPTY THEN begin
                BufferPostBatch.SetHideDialog(NOT GUIALLOWED);
                BufferPostBatch.SetRunningResiliency;
                BufferPostBatch.CarryOutBatchAction(BufferLine);
                FailedCounter := BufferPostBatch.GetFailedCounter;
                IF FailedCounter <> 0 THEN
                    AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleSalesShipment()->"%1"', SkippedLineMsg));

            end ELSE
                AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleSalesShipment()->"%1"', NothingToHandleText)); //003

            SETRANGE("Ready for Processing"); //007
            IF NOT FIND('=><') THEN
                RESET;
        end;
        EXIT(ErrMsg = ''); //003
    end;

    local procedure SetSalesShipmentFilterFor(VAR BufferLine: Record 50003; DocNo: Code[20]);
    begin

        WITH BufferLine DO begin
            RESET;
            SETFILTER("Processing Status", '>%1', "Processing Status"::New);
            IF DocNo <> '' THEN
                SETRANGE("Document No.", DocNo);
        end;

    end;

    local procedure HandleProductionOutput(OrderNo: Code[20]) ErrMsg: Text;
    VAR
        BufferLine: Record 50004;
    begin
        //007 added OrderNo parameter //
        ErrMsg := '';
        CLEARLASTERROR;


        SetProductionOutputFilterFor(BufferLine, OrderNo);
        CheckProductionOutput(BufferLine, FALSE);
        IF NOT ProcessProductionOutput(BufferLine, ErrMsg) THEN
            IF ErrMsg = '' THEN //003
                ErrMsg := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(ErrMsg));
    end;

    local procedure CheckProductionOutput(VAR BufferLine: Record 50004; NoCommit: Boolean);
    VAR
        BufferCheckLine: Codeunit 50035;
    begin
        //007 added OrderNo parameter //
        WITH BufferLine DO begin

            SETRANGE(Processed, FALSE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    BufferCheckLine.RunCheck(BufferLine);
                UNTIL NEXT = 0;
                IF NOT NoCommit THEN
                    COMMIT;
            end;
            SETRANGE(Processed);

        end;
    end;

    local procedure ProcessProductionOutput(VAR BufferLine: Record 50004; VAR ErrMsg: Text): Boolean;
    VAR
        BufferPostBatch: Codeunit 50037;
        FailedCounter: Integer;
    begin
        //007 added OrderNo parameter //
        WITH BufferLine DO begin

            SETRANGE("Ready for Processing", TRUE);
            IF NOT ISEMPTY THEN begin
                BufferPostBatch.SetHideDialog(NOT GUIALLOWED);
                BufferPostBatch.SetRunningResiliency;
                BufferPostBatch.CarryOutBatchAction(BufferLine);
                FailedCounter := BufferPostBatch.GetFailedCounter;
                IF FailedCounter <> 0 THEN
                    AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleProductionOutput()->"%1"', SkippedLineMsg));

            end ELSE
                AddToErrorMsg(ErrMsg, STRSUBSTNO('HandleProductionOutput()->"%1"', NothingToHandleText)); //003

            SETRANGE("Ready for Processing"); //007
            IF NOT FIND('=><') THEN
                RESET;
        end;
        EXIT(ErrMsg = ''); //003
    end;

    local procedure SetProductionOutputFilterFor(VAR BufferLine: Record 50004; OrderNo: Code[20]);
    begin

        WITH BufferLine DO begin
            RESET;
            SETFILTER("Processing Status", '>%1', "Processing Status"::New);
            IF OrderNo <> '' THEN
                SETRANGE("Prod. Order No.", OrderNo);
        end;

    end;

    local procedure AddToErrorMsg(VAR ErrMsg: Text; Text: Text);
    begin
        //003 Start
        IF ErrMsg = '' THEN
            ErrMsg := COPYSTR(Text, 1, MAXSTRLEN(ErrMsg))
        ELSE
            IF STRLEN(ErrMsg) + STRLEN(Text) + 2 <= MAXSTRLEN(ErrMsg) THEN
                ErrMsg := ErrMsg + '->' + Text;
        //003 end
    end;

    local procedure ClearUnitCost(ItemJournalLine: Record 83);
    begin
        //004.djc Start
        WITH ItemJournalLine DO begin
            "Unit Cost" := 0;
            MODIFY;
        end;
        //004.djc end
    end;

    local procedure ClearCostAndTime(ProdOrderRoutingLine: Record 5409);
    begin
        //004.djc Start
        WITH ProdOrderRoutingLine DO begin
            "Unit Cost per" := 0;
            "Setup Time" := 0;
            "Run Time" := 0;
            MODIFY;
        end;
        //004.djc end
    end;

    procedure ArchiveMasterWorkOrders(VAR Rec: Record 50000);
    VAR
        MasterWOLine: Record 50000;
        NextEntryNo: Integer;
    begin

        WITH MasterWOLine DO begin
            RESET;
            COPY(Rec);
            SETRANGE(Processed, TRUE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    ArchiveSingleMasterWorkOrder(MasterWOLine, NextEntryNo, FALSE);
                UNTIL NEXT = 0;
                DELETEALL(TRUE);
            end;
        end;

    end;

    procedure ArchiveSingleMasterWorkOrder(VAR MasterWOLine: Record 50000; VAR NextEntryNo: Integer; RunDelete: Boolean);
    VAR
        MasterWOLineArch: Record 50010;
    begin

        WITH MasterWOLine DO begin
            IF NextEntryNo = 0 THEN begin
                MasterWOLineArch.RESET;
                IF MasterWOLineArch.FINDLAST THEN
                    NextEntryNo := MasterWOLineArch."Entry No.";
                NextEntryNo += 1;
            end;

            MasterWOLineArch.INIT;
            MasterWOLineArch.TRANSFERFIELDS(MasterWOLine);
            MasterWOLineArch."Entry No." := NextEntryNo;
            MasterWOLineArch.INSERT;
            NextEntryNo += 1;

            IF RunDelete THEN
                DELETE(TRUE);
        end;

    end;

    procedure ArchiveInvtAdjmts(VAR Rec: Record 50001);
    VAR
        InvtAdjmtLine: Record 50001;
        NextEntryNo: Integer;
    begin

        WITH InvtAdjmtLine DO begin
            RESET;
            COPY(InvtAdjmtLine);
            SETRANGE(Processed, TRUE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    ArchiveSingleInvtAdjmt(InvtAdjmtLine, NextEntryNo, FALSE);
                UNTIL NEXT = 0;
                DELETEALL(TRUE);
            end;
        end;

    end;

    procedure ArchiveSingleInvtAdjmt(VAR InvtAdjmtLine: Record 50001; VAR NextEntryNo: Integer; RunDelete: Boolean);
    VAR
        InvtAdjmtLineArch: Record 50011;
    begin

        WITH InvtAdjmtLine DO begin
            IF NextEntryNo = 0 THEN begin
                InvtAdjmtLineArch.RESET;
                IF InvtAdjmtLineArch.FINDLAST THEN
                    NextEntryNo := InvtAdjmtLineArch."Entry No.";
                NextEntryNo += 1;
            end;

            InvtAdjmtLineArch.INIT;
            InvtAdjmtLineArch.TRANSFERFIELDS(InvtAdjmtLine);
            InvtAdjmtLineArch."Entry No." := NextEntryNo;
            InvtAdjmtLineArch.INSERT;
            NextEntryNo += 1;

            IF RunDelete THEN
                DELETE(TRUE);
        end;

    end;

    procedure ArchivePurchLines(VAR Rec: Record 50002);
    VAR
        PurchLine: Record 50002;
        NextEntryNo: Integer;
    begin

        WITH PurchLine DO begin
            RESET;
            COPY(Rec);
            SETRANGE(Processed, TRUE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    ArchiveSinglePurchLine(PurchLine, NextEntryNo, FALSE);
                UNTIL NEXT = 0;
                DELETEALL(TRUE);
            end;
        end;

    end;

    procedure ArchiveSinglePurchLine(VAR PurchLine: Record 50002; VAR NextEntryNo: Integer; RunDelete: Boolean);
    VAR
        PurchLineArch: Record "GUI-to-BC Purchase Line Arch";
    begin

        WITH PurchLine DO begin
            IF NextEntryNo = 0 THEN begin
                PurchLineArch.RESET;
                IF PurchLineArch.FINDLAST THEN
                    NextEntryNo := PurchLineArch."Entry No.";
                NextEntryNo += 1;
            end;

            PurchLineArch.INIT;
            PurchLineArch.TRANSFERFIELDS(PurchLine);
            PurchLineArch."Entry No." := NextEntryNo;
            PurchLineArch.INSERT;
            NextEntryNo += 1;

            IF RunDelete THEN
                DELETE(TRUE);
        end;

    end;

    procedure ArchiveSalesLines(VAR Rec: Record "GUI-to-BC Sales Line");
    VAR
        SalesLine: Record "GUI-to-BC Sales Line";
        NextEntryNo: Integer;
    begin

        WITH SalesLine DO begin
            RESET;
            COPY(Rec);
            SETRANGE(Processed, TRUE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    ArchiveSingleSalesLine(SalesLine, NextEntryNo, FALSE);
                UNTIL NEXT = 0;
                DELETEALL(TRUE);
            end;
        end;

    end;

    procedure ArchiveSingleSalesLine(VAR SalesLine: Record "GUI-to-BC Sales Line"; VAR NextEntryNo: Integer; RunDelete: Boolean);
    VAR
        SalesLineArch: Record "GUI-to-BC Sales Line Arch";
    begin

        WITH SalesLine DO begin
            IF NextEntryNo = 0 THEN begin
                SalesLineArch.RESET;
                IF SalesLineArch.FINDLAST THEN
                    NextEntryNo := SalesLineArch."Entry No.";
                NextEntryNo += 1;
            end;

            SalesLineArch.INIT;
            SalesLineArch.TRANSFERFIELDS(SalesLine);
            SalesLineArch."Entry No." := NextEntryNo;
            SalesLineArch.INSERT;
            NextEntryNo += 1;

            IF RunDelete THEN
                DELETE(TRUE);
        end;

    end;

    procedure ArchiveOutputLines(VAR Rec: Record "GUI-to-BC Output Line");
    VAR
        OutputLine: Record "GUI-to-BC Output Line";
        NextEntryNo: Integer;
    begin

        WITH OutputLine DO begin
            RESET;
            COPY(Rec);
            SETRANGE(Processed, TRUE);
            IF NOT ISEMPTY THEN begin
                FINDSET(TRUE, FALSE);
                REPEAT
                    ArchiveSingleOutputLine(OutputLine, NextEntryNo, FALSE);
                UNTIL NEXT = 0;
                DELETEALL(TRUE);
            end;
        end;

    end;

    procedure ArchiveSingleOutputLine(VAR OutputLine: Record "GUI-to-BC Output Line"; VAR NextEntryNo: Integer; RunDelete: Boolean);
    VAR
        OutputLineArch: Record "GUI-to-BC Output Line Arch";
    begin

        WITH OutputLine DO begin
            IF NextEntryNo = 0 THEN begin
                OutputLineArch.RESET;
                IF OutputLineArch.FINDLAST THEN
                    NextEntryNo := OutputLineArch."Entry No.";
                NextEntryNo += 1;
            end;

            OutputLineArch.INIT;
            OutputLineArch.TRANSFERFIELDS(OutputLine);
            OutputLineArch."Entry No." := NextEntryNo;
            OutputLineArch.INSERT;
            NextEntryNo += 1;

            IF RunDelete THEN
                DELETE(TRUE);
        end;

    end;




    [EventSubscriber(ObjectType::Codeunit, Codeunit::GUItoBC_Integration_WS, 'OnProcessMasterWorkOrder', '', false, false)]
    LOCAL PROCEDURE GUIIntegrWSOnProcessMasterWorkOrder(OrderDate: Date; OrderShift: Integer; ItemNo: Code[20]; ProdLineNo: Code[10]; VAR ErrMsg: Text; VAR Handled: Boolean);
    BEGIN

        IF NOT Handled THEN BEGIN
            ErrMsg := HandleMasterWorkOrder(OrderDate, OrderShift, ItemNo, ProdLineNo);
            Handled := TRUE;
        END;

    END;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GUItoBC_Integration_WS, 'OnProcessInventoryAdjustment', '', false, false)]
    LOCAL PROCEDURE GUIIntegrWSOnProcessInventoryAdjustment(DocNo: Code[20]; ItemNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    BEGIN

        IF NOT Handled THEN BEGIN
            ErrMsg := HandleInventoryAdjustment(DocNo, ItemNo);
            Handled := TRUE;
        END;

    END;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GUItoBC_Integration_WS, 'OnProcessPurchaseReceipt', '', false, false)]
    LOCAL PROCEDURE GUIIntegrWSOnProcessPurchaseReceipt(DocNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    BEGIN

        IF NOT Handled THEN BEGIN
            ErrMsg := HandlePurchaseReceipt(DocNo);
            Handled := TRUE;
        END;

    END;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GUItoBC_Integration_WS, 'OnProcessSalesShipment', '', false, false)]
    LOCAL PROCEDURE GUIIntegrWSOnProcessSalesShipment(DocNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    BEGIN

        IF NOT Handled THEN BEGIN
            ErrMsg := HandleSalesShipment(DocNo);
            Handled := TRUE;
        END;

    END;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::GUItoBC_Integration_WS, 'OnProcessProductionOutput', '', false, false)]
    LOCAL PROCEDURE GUIIntegrWSOnProcessProductionOutput(OrderNo: Code[20]; VAR ErrMsg: Text; VAR Handled: Boolean);
    BEGIN

        IF NOT Handled THEN BEGIN
            ErrMsg := HandleProductionOutput(OrderNo);
            Handled := TRUE;
        END;

    END;




    [EventSubscriber(ObjectType::Page, Page::"GUI Master Work Ord. Worksheet", 'OnAfterActionEvent', 'TestWorksheet', false, false)]

    LOCAL PROCEDURE MasterWorkOrdWorksheetOnAfterTestWorksheetAction(VAR Rec: Record 50000);
    VAR
        BufferLine: Record 50000;
    BEGIN

        BufferLine.COPY(Rec);
        CheckMasterWorkOrder(BufferLine, TRUE);

    END;


    [EventSubscriber(ObjectType::Page, Page::"GUI Inventory Adjmt. Worksheet", 'OnAfterActionEvent', 'TestWorksheet', false, false)]
    LOCAL PROCEDURE InventoryAdjmtWorksheetOnAfterTestWorksheetAction(VAR Rec: Record 50001);
    VAR
        BufferLine: Record 50001;
    BEGIN

        BufferLine.COPY(Rec);
        CheckInventoryAdjustment(BufferLine, TRUE);

    END;


    [EventSubscriber(ObjectType::Page, Page::"GUI Purchase Receipt Worksheet", 'OnAfterActionEvent', 'TestWorksheet', false, false)]
    LOCAL PROCEDURE PurchaseReceiptWorksheetOnAfterTestWorksheetAction(VAR Rec: Record 50002);
    VAR
        BufferLine: Record 50002;
    BEGIN

        BufferLine.COPY(Rec);
        CheckPurchaseReceipt(BufferLine, TRUE);

    END;


    [EventSubscriber(ObjectType::Page, Page::"GUI Sales Shipment Worksheet", 'OnAfterActionEvent', 'TestWorksheet', false, false)]
    LOCAL PROCEDURE SalesShipmentWorksheetOnAfterTestWorksheetAction(VAR Rec: Record 50003);
    VAR
        BufferLine: Record 50003;
    BEGIN

        BufferLine.COPY(Rec);
        CheckSalesShipment(BufferLine, TRUE);

    END;


    [EventSubscriber(ObjectType::Page, Page::"GUI Output Line Worksheet", 'OnAfterActionEvent', 'TestWorksheet', false, false)]
    LOCAL PROCEDURE OutputLineWorksheetOnAfterTestWorksheetAction(VAR Rec: Record 50004);
    VAR
        BufferLine: Record 50004;
    BEGIN

        BufferLine.COPY(Rec);
        CheckProductionOutput(BufferLine, TRUE);

    END;


    [EventSubscriber(ObjectType::table, database::"Prod. Order Routing Line", 'OnAfterInsertEvent', '', false, false)]
    LOCAL PROCEDURE ProdOrderRtngLineOnAfterInsert(VAR Rec: Record 5409; RunTrigger: Boolean);
    BEGIN
        //007 Start
        WITH Rec DO BEGIN
            IF ISTEMPORARY THEN
                EXIT;

            ClearCostAndTime(Rec);
        END;
        //007 End
    END;


}