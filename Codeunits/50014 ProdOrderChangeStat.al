codeunit 50014 KMK_ProdOrderChangeStat
{
    TableNo = "Production Order";
    Permissions = TableData 242 = r,
                TableData "Production Order" = rimd,
                TableData 5410 = rid,
                TableData 5896 = rim;

    trigger OnRun()
    begin
        IF RunningResiliency THEN
            rec.LOCKTABLE;

        CarryOutStatusChangeAction(Rec);

    end;

    var
        TempFailedProdOrder: Record "Production Order" temporary;
        ProdOrderStatusChange: Codeunit KMK_ProdOrderChangeStat;
        RunningResiliency: Boolean;
        Window: Dialog;
        CounterFailed: Integer;
        LineCounter: Integer;
        NewStatus: Option Quote,Planned,"Firm Planned",Released,Finished;
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
        HideDialog: Boolean;
        WindowOpened: Boolean;
        Text001: TextConst ENU = 'Checking Prod. Orders #1########\';
        Text002: TextConst ENU = 'Updating Prod. Orders #2########';
        PrintOrder: Boolean;
        Text003: TextConst ENU = 'You cannot finish line %1 on %2 %3. Component %4 needed quantity (%5) is larger than the quantity available (%6).';
        UseStdStatusRelease: Boolean;
        Text004: TextConst ENU = 'Some %1s have not been finished - output is still missing. Do you still want to finish selected orders?';
        Text005: TextConst ENU = 'The update has been interrupted to respect the warning.';
        Text006: TextConst ENU = 'Some %1s have not been finished - consumption is still missing. Do you still want to finish selected orders?';
        Text008: TextConst ENU = '%1 %2 cannot be finished as the associated subcontract order %3 has not been fully delivered.';
        ShowWarningOrder: Boolean;
        ShowWarningComp: Boolean;

    PROCEDURE CarryOutBatchAction(VAR ProdOrder2: Record "Production Order");
    VAR
        ProdOrder: Record "Production Order";
    BEGIN
        ProdOrder.COPY(ProdOrder2);
        IF ProdOrder.GETFILTER("No.") = '' THEN
            //>> ProdOrder.SETRANGE("Accept Change Status", TRUE);
            Code(ProdOrder);
        ProdOrder2 := ProdOrder;
    END;

    PROCEDURE Set(Status: Option Quote,Planned,"Firm Planned",Released,Finished; PostingDate: Date; UpdateUnitCost: Boolean; NewPrintOrders: Boolean);
    BEGIN
        NewStatus := Status;
        NewPostingDate := PostingDate;
        NewUpdateUnitCost := UpdateUnitCost;
        PrintOrder := NewPrintOrders;
    END;

    LOCAL PROCEDURE Code(VAR ProdOrder: Record "Production Order");
    VAR
        StartOrderNo: Code[20];
        Confirmed: Boolean;
    BEGIN
        WITH ProdOrder DO BEGIN
            SETRANGE(Status, ProdOrder.Status::Released);

            IF NOT RunningResiliency THEN
                LOCKTABLE;

            IF NOT FIND('=><') THEN BEGIN
                COMMIT;
                EXIT;
            END;

            OpenWidnow;

            // Check orders
            LineCounter := 0;
            StartOrderNo := "No.";
            //004 Start
            ShowWarningOrder := FALSE;
            ShowWarningComp := FALSE;
            //004 End
            REPEAT
                LineCounter := LineCounter + 1;
                IF WindowOpened THEN
                    Window.UPDATE(1, LineCounter);
                CheckProdOrder(ProdOrder);
                IF NEXT = 0 THEN
                    FIND('-');
            UNTIL "No." = StartOrderNo;

            //004 Start
            Confirmed := TRUE;
            IF GUIALLOWED AND NOT HideDialog AND
               ShowWarningOrder
            THEN
                Confirmed :=
                  Confirmed AND
                  CONFIRM(STRSUBSTNO(Text004, ProdOrder.TABLECAPTION));
            IF GUIALLOWED AND NOT HideDialog AND
               ShowWarningComp
            THEN
                Confirmed :=
                  Confirmed AND
                  CONFIRM(STRSUBSTNO(Text006, ProdOrder.TABLECAPTION));
            IF NOT Confirmed THEN
                ERROR(Text005);
            //004 End

            LineCounter := 0;
            IF FIND('-') THEN
                REPEAT
                    LineCounter := LineCounter + 1;
                    IF RunningResiliency THEN BEGIN
                        IF NOT TryCarryOutStatusChangeAction(ProdOrder) THEN BEGIN
                            SetFailedProdOrder(ProdOrder);
                            CounterFailed := CounterFailed + 1;
                        END;
                    END ELSE
                        CarryOutStatusChangeAction(ProdOrder);
                UNTIL NEXT = 0;

            ResetProdOrders(ProdOrder);
            COMMIT;

            CloseWindow;
        END;
    END;

    LOCAL PROCEDURE CheckProdOrder(ProdOrder: Record "Production Order");
    VAR
        ProdOrderLine: Record 5406;
        ProdOrderComp: Record 5407;
        TempEntrySummary: Record 338 temporary;
        Item: Record 27;
        QtyToPost: Decimal;
        QtyToPostBase: Decimal;
        AvailQtyBase: Decimal;
    BEGIN
        WITH ProdOrder DO BEGIN
            //004 Start
            CheckBeforeFinishProdOrder(ProdOrder);
            //004 End

            ProdOrderLine.RESET;
            ProdOrderLine.SETRANGE(Status, Status);
            ProdOrderLine.SETRANGE("Prod. Order No.", "No.");
            IF ProdOrderLine.FINDSET THEN
                REPEAT
                    ProdOrderLine.TESTFIELD("Finished Quantity");

                    ProdOrderComp.RESET;
                    ProdOrderComp.SETCURRENTKEY(Status, "Prod. Order No.", "Routing Link Code", "Flushing Method");
                    ProdOrderComp.SETRANGE(Status, Status);
                    ProdOrderComp.SETRANGE("Prod. Order No.", "No.");
                    ProdOrderComp.SETRANGE("Routing Link Code", '');
                    ProdOrderComp.SETFILTER(
                      "Flushing Method",
                      '%1|%2',
                      ProdOrderComp."Flushing Method"::Backward,
                      ProdOrderComp."Flushing Method"::"Pick + Backward");
                    ProdOrderComp.SETRANGE("Prod. Order Line No.", ProdOrderLine."Line No.");
                    ProdOrderComp.SETFILTER("Item No.", '<>%1', '');
                    IF ProdOrderComp.FINDSET THEN
                        REPEAT
                            Item.GET(ProdOrderComp."Item No.");
                            Item.TESTFIELD("Rounding Precision");

                            // Calc. qty. based on actual output //
                            QtyToPost := ROUND(ProdOrderComp.GetNeededQty(0, FALSE), Item."Rounding Precision", '>');
                            QtyToPostBase := ROUND(QtyToPost * ProdOrderComp."Qty. per Unit of Measure", 0.00001);

                            IF Item."Item Tracking Code" <> '' THEN
                                // Get FIFO summary //
                                AvailQtyBase := RetrieveItemTrackingData(ProdOrderComp, TempEntrySummary)
                            ELSE BEGIN
                                Item.SETRANGE("Location Filter", ProdOrderComp."Location Code");
                                Item.SETRANGE("Variant Filter", ProdOrderComp."Variant Code");
                                Item.CALCFIELDS(Inventory);
                                AvailQtyBase := Item.Inventory;
                            END;

                            IF AvailQtyBase < QtyToPostBase THEN
                                ERROR(
                                  Text003,
                                  ProdOrderLine."Line No.", ProdOrder.TABLECAPTION, ProdOrderLine."Prod. Order No.",
                                  ProdOrderComp."Item No.", QtyToPostBase, AvailQtyBase);
                        UNTIL ProdOrderComp.NEXT = 0;
                UNTIL ProdOrderLine.NEXT = 0;
        END;
    END;

    LOCAL PROCEDURE CarryOutStatusChangeAction(VAR ProdOrder: Record "Production Order");
    BEGIN
        WITH ProdOrder DO BEGIN
            LineCounter := LineCounter + 1;
            IF NOT RunningResiliency THEN
                IF WindowOpened THEN
                    Window.UPDATE(2, LineCounter);

            IF UpdateProdOrder(ProdOrder) THEN BEGIN
                ProdOrder.GET(Status, "No."); //003
                ChangeStatusOnProdOrder(ProdOrder);
                PrintProdOrder(ProdOrder);
            END;
        END;
    END;


    LOCAL PROCEDURE TryCarryOutStatusChangeAction(VAR ProdOrder: Record 5405): Boolean;
    BEGIN
        WITH ProdOrder DO BEGIN
            ProdOrderStatusChange.Set(NewStatus, NewPostingDate, NewUpdateUnitCost, PrintOrder);
            ProdOrderStatusChange.SetUseStdStatusRelease(UseStdStatusRelease); //004
            ProdOrderStatusChange.SetTryParameters(TempFailedProdOrder, LineCounter);
            IF ProdOrderStatusChange.RUN(ProdOrder) THEN BEGIN
                ProdOrderStatusChange.GetTryParameters(LineCounter);
                IF WindowOpened THEN
                    Window.UPDATE(2, LineCounter);
                EXIT(TRUE);
            END;
            EXIT(FALSE);
        END;
    END;

    PROCEDURE SetTryParameters(VAR TryFailedProdOrder: Record 5405 temporary; TryLineCounter: Integer);
    BEGIN
        SetRunningResiliency;
        LineCounter := TryLineCounter;

        IF TryFailedProdOrder.FIND('-') THEN
            REPEAT
                TempFailedProdOrder := TryFailedProdOrder;
                IF TempFailedProdOrder.INSERT THEN;
            UNTIL TryFailedProdOrder.NEXT = 0;
    END;

    PROCEDURE GetTryParameters(VAR TryLineCounter: Integer);
    BEGIN
        TryLineCounter := LineCounter;
    END;

    LOCAL PROCEDURE UpdateProdOrder(ProdOrder: Record 5405): Boolean;
    VAR
        ProdOrderLine: Record 5406;
        ProdOrderComp: Record 5407;
        TempEntrySummary: Record 338 temporary;
        TempEntrySummary2: Record 338 temporary;
        Item: Record 27;
        Setup: Record 50005;
        QtyToPost: Decimal;
        QtyToPostBase: Decimal;
        AvailQtyBase: Decimal;
        OK: Boolean;
        Handled: Boolean;
    BEGIN
        WITH ProdOrder DO BEGIN
            Setup.GET;

            ProdOrderLine.RESET;
            ProdOrderLine.SETRANGE(Status, Status);
            ProdOrderLine.SETRANGE("Prod. Order No.", "No.");
            IF ProdOrderLine.FINDSET THEN
                REPEAT
                    IF (ProdOrderLine.Quantity <> ProdOrderLine."Finished Quantity") AND
                            (Setup."Prod. Change Status Set Qty" = Setup."Prod. Change Status Set Qty"::"Finished Qty.")
                         THEN begin
                        ProdOrderLine.VALIDATE(Quantity, ProdOrderLine."Finished Quantity");
                        ProdOrderLine.MODIFY;
                        OnAfterChangeProdOrderLineQuantity(ProdOrderLine, Handled); //002
                    end;                                                       //  END;

                    //004 Start
                    OK := TRUE;
                    IF NOT UseStdStatusRelease THEN BEGIN
                        //004 End
                        ProdOrderComp.RESET;
                        ProdOrderComp.SETCURRENTKEY(Status, "Prod. Order No.", "Routing Link Code", "Flushing Method");
                        ProdOrderComp.SETRANGE(Status, Status);
                        ProdOrderComp.SETRANGE("Prod. Order No.", "No.");
                        ProdOrderComp.SETRANGE("Routing Link Code", '');
                        ProdOrderComp.SETFILTER(
                          "Flushing Method",
                          '%1|%2',
                          ProdOrderComp."Flushing Method"::Backward,
                          ProdOrderComp."Flushing Method"::"Pick + Backward");
                        ProdOrderComp.SETRANGE("Prod. Order Line No.", ProdOrderLine."Line No.");
                        ProdOrderComp.SETFILTER("Item No.", '<>%1', '');
                        IF ProdOrderComp.FINDSET THEN BEGIN
                            //004 OK := TRUE;
                            REPEAT
                                Item.GET(ProdOrderComp."Item No.");
                                Item.TESTFIELD("Rounding Precision");

                                IF Item."Item Tracking Code" <> '' THEN BEGIN
                                    // Calc. qty. based on actual output //
                                    QtyToPost := ROUND(ProdOrderComp.GetNeededQty(0, FALSE), Item."Rounding Precision", '>');
                                    QtyToPostBase := ROUND(QtyToPost * ProdOrderComp."Qty. per Unit of Measure", 0.00001);

                                    // Get FIFO summary //
                                    AvailQtyBase := RetrieveItemTrackingData(ProdOrderComp, TempEntrySummary);

                                    IF AvailQtyBase >= QtyToPostBase THEN
                                        CopyFromEntrySummaryToEntrySummary(TempEntrySummary, TempEntrySummary2, QtyToPostBase)
                                    ELSE
                                        OK := FALSE;
                                END;
                            UNTIL (ProdOrderComp.NEXT = 0) OR NOT OK;

                            IF OK THEN BEGIN
                                ProdOrderComp.FINDSET;
                                REPEAT
                                    TempEntrySummary2.RESET;
                                    TempEntrySummary2.SETFILTER("Summary Type", FORMAT(ProdOrderComp."Item No."));
                                    IF TempEntrySummary2.FINDSET THEN BEGIN
                                        // Reset item tracking //
                                        UpdateProdOrderCompItemTracking(ProdOrderComp, '', '', 0D, 0D, 0);

                                        QtyToPostBase := TempEntrySummary2."Total Requested Quantity";
                                        REPEAT
                                            IF TempEntrySummary2."Total Quantity" > QtyToPostBase THEN BEGIN
                                                UpdateProdOrderCompItemTracking(
                                                  ProdOrderComp, TempEntrySummary2."Lot No.", '', TempEntrySummary2."Expiration Date", 0D, QtyToPostBase);
                                                QtyToPostBase := 0;
                                            END ELSE BEGIN
                                                UpdateProdOrderCompItemTracking(
                                                  ProdOrderComp, TempEntrySummary2."Lot No.", '', TempEntrySummary2."Expiration Date", 0D, TempEntrySummary2."Total Quantity");
                                                QtyToPostBase := QtyToPostBase - TempEntrySummary2."Total Quantity";
                                            END;
                                        UNTIL (TempEntrySummary2.NEXT = 0) OR
                                              (QtyToPostBase = 0);
                                        IF QtyToPostBase <> 0 THEN
                                            OK := FALSE;
                                    END;
                                UNTIL ProdOrderComp.NEXT = 0;
                            END;
                            TempEntrySummary2.RESET;
                            TempEntrySummary2.DELETEALL;
                        END;
                        //004 Start
                    END;
                    //004 End

                    IF NOT OK THEN
                        EXIT(FALSE);
                UNTIL ProdOrderLine.NEXT = 0;
        END;
        EXIT(TRUE);
    END;

    LOCAL PROCEDURE UpdateProdOrderCompItemTracking(ProdOrderComp: Record 5407; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal);
    VAR
        Item: Record 27;
        ItemTrackingCode: Record 6502;
        TrackingSpecification: Record 336;
        TempTrackingSpecification: Record 336 temporary;
        ItemTrackingLines: Codeunit 50011;
        ItemTrackingMgt: Codeunit 6500;
        LastEntryNo: Integer;
        Found: Boolean;
    BEGIN
        // ItemTrackingLines -> Codeunit 50011 "GUI-to-NAV Item Tracking Lines"
        WITH ProdOrderComp DO BEGIN
            IF (LotNo = '') AND
               (SerialNo = '') AND
               (LineQty <> 0)
            THEN
                EXIT;

            TESTFIELD("Item No.");
            TESTFIELD(Quantity);

            Item.GET("Item No.");
            ItemTrackingCode.GET(Item."Item Tracking Code");

            TempTrackingSpecification.RESET;
            TempTrackingSpecification.DELETEALL;

            TrackingSpecification.INIT;
            TrackingSpecification.InitFromProdOrderComp(ProdOrderComp);

            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ProdOrderComp."Due Date");
            ItemTrackingLines.SetInbound(ProdOrderComp.IsInbound);
            ItemTrackingLines.SetBlockCommit(TRUE);
            ItemTrackingLines.GUIOpenForm;
            ItemTrackingLines.GUIGetRecords(TempTrackingSpecification);
            IF TempTrackingSpecification.FIND('+') THEN
                LastEntryNo := TempTrackingSpecification."Entry No."
            ELSE
                LastEntryNo := 0;

            Found := FALSE;
            IF LastEntryNo <> 0 THEN BEGIN
                IF LineQty <> 0 THEN BEGIN
                    TempTrackingSpecification.SETRANGE("Lot No.", LotNo);
                    TempTrackingSpecification.SETRANGE("Serial No.", SerialNo);
                END;
                IF TempTrackingSpecification.FINDSET THEN BEGIN
                    REPEAT
                        Found := TRUE;
                        IF LineQty = 0 THEN
                            TempTrackingSpecification.VALIDATE("Qty. to Handle (Base)", 0)
                        ELSE BEGIN
                            IF (TempTrackingSpecification."Qty. to Handle (Base)" + LineQty) > TempTrackingSpecification."Quantity (Base)" THEN
                                TempTrackingSpecification.VALIDATE(
                                  "Quantity (Base)",
                                  TempTrackingSpecification."Qty. to Handle (Base)" + LineQty)
                            ELSE
                                TempTrackingSpecification.VALIDATE(
                                  "Qty. to Handle (Base)",
                                  TempTrackingSpecification."Qty. to Handle (Base)" + LineQty);
                        END;
                        ItemTrackingLines.GUIModifyRecord(TempTrackingSpecification);
                    UNTIL TempTrackingSpecification.NEXT = 0;
                END;
            END;

            IF NOT Found AND
               (LineQty <> 0)
            THEN BEGIN
                LastEntryNo := LastEntryNo + 1;

                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := LastEntryNo;
                TempTrackingSpecification."Quantity (Base)" := 0;
                TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                TempTrackingSpecification."Qty. to Invoice (Base)" := 0;
                TempTrackingSpecification."Quantity Handled (Base)" := 0;
                TempTrackingSpecification."Quantity Invoiced (Base)" := 0;
                TempTrackingSpecification."Qty. to Handle" := 0;
                TempTrackingSpecification."Qty. to Invoice" := 0;

                TempTrackingSpecification.VALIDATE("Quantity (Base)", LineQty);
                IF LotNo <> '' THEN
                    TempTrackingSpecification.VALIDATE("Lot No.", LotNo);
                IF SerialNo <> '' THEN
                    TempTrackingSpecification.VALIDATE("Serial No.", SerialNo);
                //IF ExpirationDate <> 0D THEN
                IF (ExpirationDate <> 0D) AND
                   (ExpirationDate <> TempTrackingSpecification."Expiration Date") AND
                   (TempTrackingSpecification."Buffer Status2" <> TempTrackingSpecification."Buffer Status2"::"ExpDate blocked")
                THEN
                    TempTrackingSpecification.VALIDATE("Expiration Date", ExpirationDate);
                IF WarrantyDate <> 0D THEN
                    TempTrackingSpecification.VALIDATE("Warranty Date", WarrantyDate);

                ItemTrackingLines.GUIInsertRecord(TempTrackingSpecification);
                Found := TRUE;
            END;
            IF Found THEN
                ItemTrackingLines.GUICloseForm;

            CLEAR(ItemTrackingLines);
        END;
    END;



    //OnBeforeCheckBeforeFinishProdOrder(ProdOrder, IsHandled);

    LOCAL PROCEDURE ChangeStatusOnProdOrder(VAR ProdOrder: Record 5405);
    VAR
        ProdOrderStatusMgt: Codeunit 5407;

    BEGIN
        //  ProdOrderStatusMgt.OnBeforeCheckBeforeFinishProdOrder(ProdOrder, IsHandled);(TRUE); //004

        //ProdOrderStatusMgt.ChangeStatusOnProdOrder(ProdOrder,NewStatus,NewPostingDate,NewUpdateUnitCost); 
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProdOrder, NewStatus, NewPostingDate, NewUpdateUnitCost);
        CLEAR(ProdOrderStatusMgt);
    END;

    LOCAL PROCEDURE SetFailedProdOrder(ProdOrder: Record 5405);
    BEGIN
        TempFailedProdOrder := ProdOrder;
        TempFailedProdOrder.INSERT;
    END;

    LOCAL PROCEDURE ResetProdOrders(VAR ProdOrder: Record 5405);
    VAR
        ProdOrder2: Record 5405;
    BEGIN
        WITH ProdOrder DO BEGIN
            ProdOrder2.COPY(ProdOrder);
            IF ProdOrder2.FINDFIRST THEN;
            IF FIND('-') THEN
                REPEAT
                    TempFailedProdOrder := ProdOrder;
                    IF NOT TempFailedProdOrder.FIND THEN BEGIN
                        ProdOrder."Accept Change Status" := FALSE;
                        ProdOrder.MODIFY;
                    END;
                UNTIL NEXT = 0;
        END;
    END;

    LOCAL PROCEDURE OpenWidnow();
    BEGIN
        IF NOT HideDialog AND GUIALLOWED THEN BEGIN
            Window.OPEN(Text001 + Text002);
            WindowOpened := TRUE;
        END ELSE
            WindowOpened := FALSE;
    END;

    LOCAL PROCEDURE CloseWindow();
    BEGIN
        IF WindowOpened THEN BEGIN
            Window.CLOSE;
            WindowOpened := FALSE;
        END;
    END;

    PROCEDURE SetRunningResiliency();
    BEGIN
        RunningResiliency := TRUE;
    END;

    PROCEDURE GetFailedCounter(): Integer;
    BEGIN
        EXIT(CounterFailed);
    END;

    LOCAL PROCEDURE PrintProdOrder(ProdOrder: Record 5405);
    VAR
        ProdOrder2: Record 5405;
        ReportSelection: Record 77;
    BEGIN
        IF PrintOrder THEN BEGIN
            ProdOrder2 := ProdOrder;
            ProdOrder2.SETRECFILTER;
            //>>SC ReportSelection.PrintWithGUIYesNoWithCheck(ReportSelection.Usage::"Prod. Order",ProdOrder2,FALSE,0);
        END;
    END;

    LOCAL PROCEDURE RetrieveItemTrackingData(ProdOrderComp: Record 5407; VAR TempEntrySummary: Record 338 temporary) TotalQty: Decimal;
    VAR
        TrackingSpecification: Record 336 temporary;
        ItemLedgEntry: Record 32;
    BEGIN
        TrackingSpecification.INIT;
        TrackingSpecification.InitFromProdOrderComp(ProdOrderComp);

        ItemLedgEntry.RESET;
        ItemLedgEntry.SETCURRENTKEY("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        ItemLedgEntry.SETRANGE("Item No.", TrackingSpecification."Item No.");
        ItemLedgEntry.SETRANGE(Open, TRUE);
        ItemLedgEntry.SETRANGE("Variant Code", TrackingSpecification."Variant Code");
        ItemLedgEntry.SETRANGE(Positive, TRUE);
        ItemLedgEntry.SETRANGE("Location Code", TrackingSpecification."Location Code");

        TransferItemLedgToTempRec(ItemLedgEntry, TrackingSpecification, TempEntrySummary);

        TempEntrySummary.RESET;
        TempEntrySummary.CALCSUMS("Total Quantity");
        TotalQty := TempEntrySummary."Total Quantity";
    END;

    LOCAL PROCEDURE TransferItemLedgToTempRec(VAR ItemLedgEntry: Record 32; VAR TrackingSpecification: Record 336 temporary; VAR TempEntrySummary: Record 338 temporary);
    VAR
        TempGlobalReservEntry: Record 337 temporary;
        LastSummaryEntryNo: Integer;
        LookupMode: Option "Serial No.","Lot No.";
    BEGIN
        LastSummaryEntryNo := 0;
        TempEntrySummary.RESET;
        TempEntrySummary.DELETEALL;

        IF ItemLedgEntry.FINDSET THEN
            REPEAT
                IF ItemLedgEntry.TrackingExists THEN
                    CreateEntrySummary(
                      TrackingSpecification, ItemLedgEntry, LookupMode::"Lot No.",
                      TempEntrySummary, LastSummaryEntryNo);
            UNTIL ItemLedgEntry.NEXT = 0;
    END;

    LOCAL PROCEDURE CreateEntrySummary(TrackingSpecification: Record 336 temporary; ItemLedgEntry: Record 32; LookupMode: Option "Serial No.","Lot No."; VAR TempEntrySummary: Record 338 temporary; VAR LastSummaryEntryNo: Integer);
    VAR
        DoInsert: Boolean;
    BEGIN
        TempEntrySummary.RESET;
        TempEntrySummary.SETCURRENTKEY("Lot No.", "Serial No.");

        // Set filters
        CASE LookupMode OF
            LookupMode::"Serial No.":
                BEGIN
                    IF ItemLedgEntry."Serial No." = '' THEN
                        EXIT;
                    TempEntrySummary.SETRANGE("Serial No.", ItemLedgEntry."Serial No.");
                    TempEntrySummary.SETRANGE("Lot No.", ItemLedgEntry."Lot No.");
                END;
            LookupMode::"Lot No.":
                BEGIN
                    TempEntrySummary.SETRANGE("Serial No.", '');
                    TempEntrySummary.SETRANGE("Lot No.", ItemLedgEntry."Lot No.");
                    IF ItemLedgEntry."Serial No." <> '' THEN
                        TempEntrySummary.SETRANGE("Table ID", 0)
                    ELSE
                        TempEntrySummary.SETFILTER("Table ID", '<>%1', 0);
                END;
        END;

        // If no summary exists, create new record
        IF NOT TempEntrySummary.FINDFIRST THEN BEGIN
            TempEntrySummary.INIT;
            TempEntrySummary."Entry No." := LastSummaryEntryNo + 1;
            TempEntrySummary."Summary Type" := FORMAT(ItemLedgEntry."Item No.");
            LastSummaryEntryNo := TempEntrySummary."Entry No.";

            IF (LookupMode = LookupMode::"Lot No.") AND
               (ItemLedgEntry."Serial No." <> '')
            THEN
                TempEntrySummary."Table ID" := 0 // Mark as summation
            ELSE
                TempEntrySummary."Table ID" := DATABASE::"Item Ledger Entry";

            IF LookupMode = LookupMode::"Serial No." THEN
                TempEntrySummary."Serial No." := ItemLedgEntry."Serial No."
            ELSE
                TempEntrySummary."Serial No." := '';

            TempEntrySummary."Lot No." := ItemLedgEntry."Lot No.";

            TempEntrySummary."Warranty Date" := ItemLedgEntry."Warranty Date";
            TempEntrySummary."Expiration Date" := ItemLedgEntry."Expiration Date";

            DoInsert := TRUE;
        END;

        // Sum up values
        TempEntrySummary."Total Quantity" += ItemLedgEntry."Remaining Quantity";

        // Update available quantity on the record
        TempEntrySummary.UpdateAvailable;
        IF DoInsert THEN
            TempEntrySummary.INSERT
        ELSE
            TempEntrySummary.MODIFY;
    END;

    LOCAL PROCEDURE CopyFromEntrySummaryToEntrySummary(VAR TempEntrySummary: Record 338 temporary; VAR TempEntrySummary2: Record 338 temporary; QtyToPostBase: Decimal);
    VAR
        LastEntryNo: Integer;
    BEGIN
        TempEntrySummary2.RESET;
        IF TempEntrySummary2.FINDLAST THEN
            LastEntryNo := TempEntrySummary2."Entry No."
        ELSE
            LastEntryNo := 0;

        WITH TempEntrySummary DO BEGIN
            RESET;
            IF FINDSET THEN
                REPEAT
                    TempEntrySummary2 := TempEntrySummary;
                    TempEntrySummary2."Entry No." := LastEntryNo + 1;
                    TempEntrySummary2."Total Requested Quantity" := QtyToPostBase;
                    TempEntrySummary2.INSERT;
                    LastEntryNo := TempEntrySummary2."Entry No.";
                UNTIL NEXT = 0;
        END;
    END;

    [IntegrationEvent(true, false)]
    LOCAL PROCEDURE OnAfterChangeProdOrderLineQuantity(VAR ProdOrderLine: Record 5406; VAR Handled: Boolean);
    BEGIN
    END;

    PROCEDURE SetUseStdStatusRelease(NewUseStdStatusRelease: Boolean);
    BEGIN
        //004 Start
        UseStdStatusRelease := NewUseStdStatusRelease;
        //004 End
    END;

    LOCAL PROCEDURE CheckBeforeFinishProdOrder(ProdOrder: Record 5405);
    VAR
        ProdOrderLine: Record 5406;
        ProdOrderComp: Record 5407;
        ProdOrderRtngLine: Record 5409;
        PurchLine: Record 39;
        ShowWarning: Boolean;
    BEGIN
        //004 Start
        WITH PurchLine DO BEGIN
            SETCURRENTKEY("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
            SETRANGE("Document Type", "Document Type"::Order);
            SETRANGE(Type, Type::Item);
            SETRANGE("Prod. Order No.", ProdOrder."No.");
            SETFILTER("Outstanding Quantity", '<>%1', 0);
            IF FINDFIRST THEN
                ERROR(Text008, ProdOrder.TABLECAPTION, ProdOrder."No.", "Document No.");
        END;

        WITH ProdOrderLine DO BEGIN
            SETRANGE(Status, ProdOrder.Status);
            SETRANGE("Prod. Order No.", ProdOrder."No.");
            SETFILTER("Remaining Quantity", '<>0');
            IF NOT ISEMPTY THEN BEGIN
                ProdOrderRtngLine.SETRANGE(Status, ProdOrder.Status);
                ProdOrderRtngLine.SETRANGE("Prod. Order No.", ProdOrder."No.");
                ProdOrderRtngLine.SETRANGE("Next Operation No.", '');
                IF NOT ProdOrderRtngLine.ISEMPTY THEN BEGIN
                    ProdOrderRtngLine.SETFILTER("Flushing Method", '<>%1', ProdOrderRtngLine."Flushing Method"::Backward);
                    IF NOT ProdOrderRtngLine.ISEMPTY THEN
                        ShowWarningOrder := TRUE;
                END ELSE
                    ShowWarningOrder := TRUE;
            END;
        END;

        WITH ProdOrderComp DO BEGIN
            SETAUTOCALCFIELDS("Pick Qty. (Base)");
            SETRANGE(Status, ProdOrder.Status);
            SETRANGE("Prod. Order No.", ProdOrder."No.");
            SETFILTER("Remaining Quantity", '<>0');
            IF FINDSET THEN
                REPEAT
                    TESTFIELD("Pick Qty. (Base)", 0);
                    IF (("Flushing Method" <> "Flushing Method"::Backward) AND
                        ("Flushing Method" <> "Flushing Method"::"Pick + Backward") AND
                        ("Routing Link Code" = '')) OR
                       (("Routing Link Code" <> '') AND NOT RtngWillFlushComp(ProdOrderComp))
                    THEN
                        ShowWarningComp := TRUE;
                UNTIL NEXT = 0;
        END;
        //004 End
    END;

    LOCAL PROCEDURE RtngWillFlushComp(ProdOrderComp: Record 5407): Boolean;
    VAR
        ProdOrderRtngLine: Record 5409;
        ProdOrderLine: Record 5406;
    BEGIN
        //004 Start
        IF ProdOrderComp."Routing Link Code" = '' THEN
            EXIT;

        WITH ProdOrderComp DO
            ProdOrderLine.GET(Status, "Prod. Order No.", "Prod. Order Line No.");

        WITH ProdOrderRtngLine DO BEGIN
            SETCURRENTKEY("Prod. Order No.", Status, "Flushing Method");
            SETRANGE("Flushing Method", "Flushing Method"::Backward);
            SETRANGE(Status, Status::Released);
            SETRANGE("Prod. Order No.", ProdOrderComp."Prod. Order No.");
            SETRANGE("Routing Link Code", ProdOrderComp."Routing Link Code");
            SETRANGE("Routing No.", ProdOrderLine."Routing No.");
            SETRANGE("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            EXIT(FINDFIRST);
        END;
        //004 End
    END;


}