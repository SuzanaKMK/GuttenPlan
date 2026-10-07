codeunit 50036 GUIOutputLinePostLine
{

    TableNo = 50004;
    Permissions = TableData 5405 = rimd,
                TableData 5406 = rimd,
                TableData 5407 = rimd,
                TableData 5409 = rimd,
                TableData 5414 = rimd,
                TableData 5415 = rimd,
                TableData 5416 = rimd,
                TableData 50000 = rm,
                TableData 99000771 = r,
                TableData 99000772 = r,
                TableData 99000776 = r,
                TableData 99000779 = r;

    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;



    VAR
        InvtSetup: Record "Inventory Setup";
        GlobalOutputLine: Record "GUI-to-BC Output Line";
        GlobalOutputLineArch: Record "GUI-to-BC Output Line Arch";
        TempGlobalOutputLineBuf: Record "GUI-to-BC Output Line" temporary;
        ItemJnlPostFailedText: TextConst ENU = 'Output Line posting failed.';
        InvtAdjmtJnlBatchNameText: Text;
        InvtAdjmtJnlBatchDescText: TextConst ENU = 'GUI-to-BC Output Journal';
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        OutputCheckLine: Codeunit GUI_OutputCheckLine;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        NoSeriesMgt: Codeunit "No. Series";
        Mgt: Codeunit GUItoBCManagement;
        IntegrMgt: Codeunit 50016;
        ErrMsgTxt: Text;
        NextEntryNo: Integer;
        InvtSetupRead: Boolean;
        ReservationEntry: Record "Reservation Entry";

    procedure RunWithCheck(VAR OutputLineBuf2: Record "GUI-to-BC Output Line");
    VAR
        OutputLineBuf: Record "GUI-to-BC Output Line";
    begin
        OutputLineBuf.COPY(OutputLineBuf2);
        Code(OutputLineBuf, TRUE);
        OutputLineBuf2 := OutputLineBuf;
    end;

    procedure RunWithoutCheck(VAR OutputLineBuf2: Record "GUI-to-BC Output Line");
    VAR
        OutputLineBuf: Record "GUI-to-BC Output Line";
    begin
        OutputLineBuf.COPY(OutputLineBuf2);
        Code(OutputLineBuf, FALSE);
        OutputLineBuf2 := OutputLineBuf;
    end;

    local procedure Code(VAR OutputLineBuf: Record "GUI-to-BC Output Line"; CheckLine: Boolean);
    begin
        WITH OutputLineBuf DO begin
            IF EmptyLine THEN
                EXIT;

            //006 Start
            IF ("Processing Status" IN ["Processing Status"::New, "Processing Status"::Processed]) THEN
                EXIT;
            //006 end

            IF CheckLine THEN
                OutputCheckLine.RunCheck(OutputLineBuf);

            IF NextEntryNo = 0 THEN
                StartPosting(OutputLineBuf)
            ELSE
                ContinuePosting(OutputLineBuf);

            IF "Ready for Processing" AND NOT "Validation Error" THEN
                PostOutputLine(OutputLineBuf);

            FinishPosting;
        end;
    end;

    procedure StartPosting(VAR OutputLine: Record "GUI-to-BC Output Line");
    begin
        WITH OutputLine DO begin
            GlobalOutputLineArch.LOCKTABLE;
            IF GlobalOutputLineArch.FINDLAST THEN
                NextEntryNo := GlobalOutputLineArch."Entry No." + 1 //004
            ELSE
                NextEntryNo := 1;

            TempGlobalOutputLineBuf.DELETEALL;
        end;

    end;

    procedure ContinuePosting(VAR OutputLine: Record "GUI-to-BC Output Line");
    begin
        WITH OutputLine DO begin
            ;
        end;

        TempGlobalOutputLineBuf.DELETEALL;
    end;

    procedure FinishPosting();
    begin
        //003 Start
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Output Line") THEN
            EXIT;
        //003 end

        IF TempGlobalOutputLineBuf.FINDSET THEN
            REPEAT
                //006 Start - Moved to function //
                IntegrMgt.ArchiveSingleOutputLine(TempGlobalOutputLineBuf, NextEntryNo, FALSE);
            //006 end
            UNTIL TempGlobalOutputLineBuf.NEXT = 0;
    end;

    local procedure PostOutputLine(VAR OutputLine: Record 50004);
    VAR
        ItemJnlLine: Record 83;
    begin
        WITH OutputLine DO begin
            ItemJnlLine.LOCKTABLE; //006

            CLEARLASTERROR;

            //003 Start
            //CreateOutputJnlLine(ItemJnlLine,OutputLine);
            //IF ItemJnlPostLine.RunWithCheck(ItemJnlLine) THEN begin
            IF CreateOutputJnlLine(ItemJnlLine, OutputLine) THEN begin
                //003 end
                OnMoveOutputLine(ItemJnlLine.RECORDID);
                TempGlobalOutputLineBuf := OutputLine;
                TempGlobalOutputLineBuf.INSERT;
                //003 Start
                //end ELSE begin
                //  ErrMsgTxt := COPYSTR(GETLASTERRORTEXT,1,MAXSTRLEN(ErrMsgTxt));
                //  IF ErrMsgTxt = '' THEN
                //    ErrMsgTxt := ItemJnlPostFailedText;
                //
                //  "Validation Error Message" := COPYSTR(ErrMsgTxt,1,MAXSTRLEN("Validation Error Message"));
                //  MODIFY;
                //end;
                //CLEAR(ItemJnlPostLine);
            end ELSE
                ERROR(GETLASTERRORTEXT); //006
                                         //003 end
        end;
    end;

    local procedure CreateOutputJnlLine(VAR ItemJnlLine: Record 83; OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    VAR
        xItemJnlLine: Record 83;
        ProdOrderLine: Record 5406;
        ProdOrderRtngLine: Record 5409;
        ItemLedgEntry: Record 32;
        OutputJnlExplRoute: Codeunit 5406;
        ItemJnlCheckLine: Codeunit 21;
        CostCalcMgt: Codeunit 5836;
        QtyFinished: Decimal;
        CurrQtyFinished: Decimal;
        OutputQty: Decimal;
        QtyToRevert: Decimal;
        NextLineNo: Integer;
        LastLineNo: Integer;
        Found: Boolean;
        Handled: Boolean;
        Revert: Boolean;
        OutputLineUpdate: Record "GUI-to-BC Output Line";

    begin
        WITH ItemJnlLine DO begin
            //003 Start
            GetOutputJnlTemplate(OutputLine);
            GetItemJnlBatch;
            CLEAR(xItemJnlLine);
            //003 end

            RESET;
            SETRANGE("Journal Template Name", ItemJnlTemplate.Name);
            SETRANGE("Journal Batch Name", ItemJnlBatch.Name);
            IF FINDLAST THEN begin
                NextLineNo := "Line No." + 10000;
                xItemJnlLine := ItemJnlLine; //003
            end ELSE
                NextLineNo := 10000;

            //003 Start
            Found := FALSE;
            Revert := FALSE; //011

            SETRANGE("Order No.", OutputLine."Prod. Order No.");
            SETRANGE("External Document No.", OutputLine."Document No."); //006
            IF NOT FINDLAST THEN begin
                //005 Start
                ProdOrderLine.RESET;
                ProdOrderLine.SETRANGE(Status, ProdOrderLine.Status::Released);
                ProdOrderLine.SETRANGE("Prod. Order No.", OutputLine."Prod. Order No.");
                IF ProdOrderLine.COUNT = 1 THEN begin
                    ProdOrderLine.FINDFIRST;
                    //011 Start
                    //IF ProdOrderLine."Remaining Quantity" < OutputLine.Quantity THEN begin
                    //  ProdOrderLine.VALIDATE(Quantity,ProdOrderLine.Quantity + OutputLine.Quantity - ProdOrderLine."Remaining Quantity");
                    //012 Start
                    //IF (ProdOrderLine."Remaining Quantity" < OutputLine.Quantity) OR
                    //   ((ProdOrderLine."Remaining Quantity" = 0) AND (OutputLine.Quantity < 0))
                    IF (ProdOrderLine."Remaining Quantity" < ABS(OutputLine.Quantity))
                    //012 end
                    THEN begin
                        Revert := OutputLine.Quantity < 0;
                        QtyToRevert := ABS(OutputLine.Quantity);
                        //012 Start
                        IF ProdOrderLine."Finished Quantity" > ProdOrderLine.Quantity THEN
                            ProdOrderLine.Quantity := ProdOrderLine."Finished Quantity";
                        //012 end
                        ProdOrderLine.VALIDATE(Quantity, ProdOrderLine.Quantity + QtyToRevert - ProdOrderLine."Remaining Quantity");
                        //011 end
                        ProdOrderLine.MODIFY;
                        OnAfterChangeProdOrderLineQuantity(ProdOrderLine, Handled);
                    end;
                end;
                //005 end

                INIT;
                "Journal Template Name" := ItemJnlTemplate.Name;
                "Journal Batch Name" := ItemJnlBatch.Name;
                "Line No." := NextLineNo;

                "Entry Type" := GetItemJnlLineEntryType(OutputLine);
                SetUpNewOutputJnlLine(ItemJnlLine, xItemJnlLine);
                VALIDATE("Entry Type", "Entry Type"::Output);
                INSERT(TRUE);

                "Posting Date" := OutputLine."Document Date"; //003 WORKDATE;
                "Document Date" := OutputLine."Document Date";
                VALIDATE("Order No.", OutputLine."Prod. Order No.");
                "External Document No." := OutputLine."Document No.";
                "GUI Description" := OutputLine."GUI Description"; //007
                "GUI Pallet" := OutputLine."GUI Pallet";
                "GUI Time of Action" := OutputLine."GUI Time of Action";
                "GUI Type" := OutputLine."GUI Type";
                "GUI-to-BC Entry No" := OutputLine."Entry No.";
                "GUI User ID" := OutputLine."GUI User ID";
                MODIFY;

                OutputJnlExplRoute.RUN(ItemJnlLine);

                SETFILTER("Line No.", '%1..', NextLineNo);
                IF FINDLAST THEN begin
                    LastLineNo := "Line No."; //009

                    ProdOrderLine.GET(ProdOrderLine.Status::Released, "Order No.", "Order Line No.");
                    //011 Start
                    IF Revert THEN begin
                        ProdOrderLine.VALIDATE(Quantity, ProdOrderLine.Quantity - QtyToRevert);
                        ProdOrderLine.MODIFY;
                        Handled := FALSE;
                        OnAfterChangeProdOrderLineQuantity(ProdOrderLine, Handled);
                    end;
                    //011 end

                    ProdOrderRtngLine.GET(ProdOrderRtngLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
                    QtyFinished := CostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRtngLine);

                    SETRANGE("Operation No.", '..%1', "Operation No.");
                    FINDSET(TRUE);
                    REPEAT
                        Handled := FALSE; //009
                                          //008 Start
                        OutputQty := OutputLine."Quantity";
                        IF OutputQty > 0 THEN begin
                            //008 end
                            ProdOrderRtngLine.GET(ProdOrderRtngLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
                            CurrQtyFinished := CostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRtngLine);
                            IF CurrQtyFinished < QtyFinished + OutputLine."Quantity" THEN begin
                                //008 Start
                                //VALIDATE("Output Quantity",QtyFinished + OutputLine."Quantity (Base)" - CurrQtyFinished);
                                //MODIFY;
                                OutputQty := QtyFinished + OutputLine."Quantity" - CurrQtyFinished;
                                //008 end
                            end;
                            //008 Start
                        end;

                        //009 Start
                        IF ("Line No." = LastLineNo) AND
                           (OutputLine."Appl.-to Item Entry" <> 0)
                        THEN begin
                            ItemLedgEntry.GET(OutputLine."Appl.-to Item Entry");
                            IF NOT ItemLedgEntry.TrackingExists THEN begin
                                VALIDATE("Applies-to Entry", OutputLine."Appl.-to Item Entry");
                                Handled := TRUE;
                            end;
                        end;
                        //009 end

                        IF OutputQty <> "Output Quantity" THEN begin
                            VALIDATE("Output Quantity", OutputQty);
                            //009 MODIFY;
                            Handled := TRUE; //009
                        end;
                        //008 end

                        //009 Start
                        IF Handled THEN
                            MODIFY;
                    //009 end
                    UNTIL NEXT = 0;
                    SETRANGE("Operation No.");
                    FINDLAST;
                end;
            end ELSE begin
                Found := TRUE;

                SETFILTER("Line No.", '%1..', "Line No."); //006
                SETRANGE("Operation No.", '..%1', "Operation No.");
                FINDSET(TRUE);
                REPEAT
                    VALIDATE("Output Quantity", "Output Quantity" + OutputLine."Quantity (Base)");
                    MODIFY;
                UNTIL NEXT = 0;
                SETRANGE("Operation No.");
                FINDLAST;
            end;
            CreateReservationEntry(ItemJnlLine,
                          OutputLine."Lot No.", OutputLine."Serial No.", OutputLine."Expiration Date", OutputLine."Warranty Date", OutputLine."Quantity (Base)");
            CreateLotNoInfo(OutputLine);
            /*  UpdateItemJnlLineItemTracking(
               ItemJnlLine,
               OutputLine."Lot No.", OutputLine."Serial No.", OutputLine."Expiration Date", OutputLine."Warranty Date", OutputLine."Quantity (Base)",
               IsReclass(ItemJnlLine),
               OutputLine."Appl.-to Item Entry");  *///009
                                                     //003 end
            If OutputLineUpdate.get(OutputLine."Entry No.") then begin
                OutputLineUpdate."Journal Template Name" := ItemJnlLine."Journal Template Name";
                OutputLineUpdate."Journal Batch Name" := ItemJnlLine."Journal Batch Name";
                OutputLineUpdate."Journal Document No." := ItemJnlLine."Document No.";
                OutputLineUpdate."Journal Line No." := ItemJnlLine."Line No.";
                OutputLineUpdate.Validate(Processed, True);
                OutputLineUpdate.SetProcessingStatus(2);
                OutputLineUpdate.Modify();
            end;
            EXIT(TRUE);
        end;
    end;


    local procedure SetUpNewOutputJnlLine(VAR Rec: Record 83; LastItemJnlLine: Record 83);
    begin
        //003 Start
        Mgt.SetUpNewItemJnlLine(Rec, LastItemJnlLine);
        //003 end
    end;

    local procedure UpdateItemJnlLineItemTracking(ItemJnlLine: Record 83; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal; IsReclassJnl: Boolean; AppliesToItemEntry: Integer);
    VAR
        Item: Record 27;
        ItemTrackingCode: Record 6502;
        TrackingSpecification: Record 336;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingLines: Codeunit 50011;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OutstandingQtyBase: Decimal;
        QtyToHandleBase: Decimal;
        LastEntryNo: Integer;
        Found: Boolean;
    begin
        //003 Start - ItemTrackingForm -> Codeunit 50011 "GUI-to-NAV Item Tracking Lines"
        WITH ItemJnlLine DO begin
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
            TrackingSpecification.InitFromItemJnlLine(ItemJnlLine);

            IF IsReclassJnl THEN
                ItemTrackingLines.SetFormRunMode(1);
            ItemTrackingLines.SetSourceSpec(TrackingSpecification, ItemJnlLine."Posting Date");
            ItemTrackingLines.SetInbound(ItemJnlLine.IsInbound);
            ItemTrackingLines.SetBlockCommit(TRUE);
            ItemTrackingLines.GUIOpenForm;
            ItemTrackingLines.GUIGetRecords(TempTrackingSpecification);
            IF TempTrackingSpecification.FIND('+') THEN
                LastEntryNo := TempTrackingSpecification."Entry No."
            ELSE
                LastEntryNo := 0;

            Found := FALSE;
            IF LastEntryNo <> 0 THEN begin
                IF LineQty <> 0 THEN begin
                    TempTrackingSpecification.SETRANGE("Lot No.", LotNo);
                    TempTrackingSpecification.SETRANGE("Serial No.", SerialNo);
                end;
                IF TempTrackingSpecification.FINDSET THEN begin
                    REPEAT
                        Found := TRUE;
                        IF LineQty = 0 THEN
                            TempTrackingSpecification.VALIDATE("Qty. to Handle (Base)", 0)
                        ELSE begin
                            //010 Start
                            //IF (TempTrackingSpecification."Qty. to Handle (Base)" + LineQty) > TempTrackingSpecification."Quantity (Base)" THEN
                            //  TempTrackingSpecification.VALIDATE(
                            //    "Quantity (Base)",
                            //    TempTrackingSpecification."Qty. to Handle (Base)" + LineQty)
                            //ELSE
                            //  TempTrackingSpecification.VALIDATE(
                            //    "Qty. to Handle (Base)",
                            //    TempTrackingSpecification."Qty. to Handle (Base)" + LineQty);
                            OutstandingQtyBase :=
                              TempTrackingSpecification."Quantity (Base)" -
                              TempTrackingSpecification."Quantity Handled (Base)" -
                              TempTrackingSpecification."Qty. to Handle (Base)";

                            IF OutstandingQtyBase >= LineQty THEN
                                OutstandingQtyBase := 0
                            ELSE
                                OutstandingQtyBase := LineQty - OutstandingQtyBase;

                            QtyToHandleBase := TempTrackingSpecification."Qty. to Handle (Base)" + LineQty;

                            IF OutstandingQtyBase > 0 THEN
                                TempTrackingSpecification.VALIDATE(
                                  "Quantity (Base)",
                                  TempTrackingSpecification."Quantity (Base)" + OutstandingQtyBase);

                            IF QtyToHandleBase <> TempTrackingSpecification."Qty. to Handle (Base)" THEN
                                TempTrackingSpecification.VALIDATE(
                                  "Qty. to Handle (Base)",
                                  QtyToHandleBase);
                            //010 end
                        end;
                        ItemTrackingLines.GUIModifyRecord(TempTrackingSpecification);
                    UNTIL TempTrackingSpecification.NEXT = 0;
                end;
            end;

            IF NOT Found AND
               (LineQty <> 0)
            THEN begin
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

                //009 Start
                IF AppliesToItemEntry <> 0 THEN
                    TempTrackingSpecification.VALIDATE("Appl.-to Item Entry", AppliesToItemEntry);
                //009 end

                ItemTrackingLines.GUIInsertRecord(TempTrackingSpecification);
                Found := TRUE;
            end;
            IF Found THEN
                ItemTrackingLines.GUICloseForm;

            CLEAR(ItemTrackingLines);
        end;
        //003 end
    end;

    local procedure GetInvtSetup();
    begin
        IF NOT InvtSetupRead THEN begin
            InvtSetup.GET;
            InvtSetupRead := TRUE;
        end;
    end;

    procedure GetNextEntryNo(): Integer;
    begin
        EXIT(NextEntryNo);
    end;

    local procedure GetOutputJnlTemplate(OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    begin
        //003 Start
        WITH OutputLine DO begin
            EXIT(GetItemJnlTemplate(PAGE::"Output Journal", 5, FALSE));
        end;
        //003 end
    end;

    local procedure GetItemJnlTemplate(PageID: Integer; PageTemplate: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order"; RecurringJnl: Boolean): Boolean;
    begin

        ItemJnlTemplate.RESET;
        ItemJnlTemplate.SETRANGE("Page ID", PageID);
        ItemJnlTemplate.SETRANGE(Recurring, RecurringJnl);
        ItemJnlTemplate.SETRANGE(Type, PageTemplate);
        EXIT(ItemJnlTemplate.FINDFIRST);
    end;

    local procedure GetItemJnlBatch(): Boolean;
    var
        GuiBCSetup: Record "GUI-to-BC Setup";
    begin
        GuiBCSetup.Reset();
        GuiBCSetup.Get();
        if GuiBCSetup."Output Batch Name" <> '' then
            InvtAdjmtJnlBatchNameText := GuiBCSetup."Output Batch Name" else
            InvtAdjmtJnlBatchNameText := 'GUI-OUTPUT';

        IF NOT ItemJnlBatch.GET(ItemJnlTemplate.Name, InvtAdjmtJnlBatchNameText) THEN begin
            ItemJnlBatch.INIT;
            ItemJnlBatch."Journal Template Name" := ItemJnlTemplate.Name;
            ItemJnlBatch.SetupNewBatch;
            ItemJnlBatch.Name := InvtAdjmtJnlBatchNameText;
            ItemJnlBatch.Description := InvtAdjmtJnlBatchDescText;
            ItemJnlBatch."No. Series" := ItemJnlTemplate."No. Series";
            ItemJnlBatch.INSERT(TRUE);
        end;

        ItemJnlBatch.SETRANGE("Journal Template Name", ItemJnlTemplate.Name);
        ItemJnlBatch.SETRANGE(Name, InvtAdjmtJnlBatchNameText);
        EXIT(ItemJnlBatch.FINDFIRST);
    end;

    local procedure GetItemJnlLineEntryType(OutputLine: Record "GUI-to-BC Output Line"): Integer;
    VAR
        ItemJnlLine: Record "Item Journal Line";
    begin
        //003 Start
        WITH OutputLine DO begin
            EXIT(ItemJnlLine."Entry Type"::Output);
        end;
        //003 end
    end;

    procedure PostOutputJournal(VAR Rec: Record "GUI-to-BC Output Line"; Last: Boolean);
    VAR
        ItemJnlLine: Record "Item Journal Line";
        OutputLine: Record "GUI-to-BC Output Line";
    begin
        //003 Start
        WITH Rec DO begin
            OutputLine.COPY(Rec);
            OutputLine.MODIFYALL("Journal Posted", TRUE);

            IF ("Journal Template Name" = '') OR
               ("Journal Batch Name" = '')
            THEN
                EXIT;

            ItemJnlLine.RESET;
            ItemJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
            ItemJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            IF ItemJnlLine.FINDSET(TRUE, TRUE) THEN
                PostItemJnl(ItemJnlLine, Last);
        end;
        //003 end
    end;

    procedure PostSingleOutputJournal(VAR Rec: Record "GUI-to-BC Output Line"; Last: Boolean);
    VAR
        ItemJnlLine: Record 83;
        OutputLine: Record "GUI-to-BC Output Line";
        Done: Boolean;
    begin
        //006 Start
        WITH Rec DO begin
            OutputLine.COPY(Rec);
            OutputLine."Journal Posted" := TRUE;
            OutputLine.MODIFY;

            IF ("Journal Template Name" = '') OR
               ("Journal Batch Name" = '')
            THEN
                EXIT;

            ItemJnlLine.RESET;
            ItemJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
            ItemJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            IF "Journal Line No." <> 0 THEN
                ItemJnlLine.SETRANGE("Line No.", "Journal Line No.");
            ItemJnlLine.SETRANGE("Order No.", "Prod. Order No.");
            ItemJnlLine.SETRANGE("External Document No.", "Document No.");
            IF NOT ItemJnlLine.ISEMPTY THEN begin
                IF "Journal Line No." <> 0 THEN
                    ItemJnlLine.SETRANGE("Line No.");
                ItemJnlLine.FINDSET;
                PostItemJnl(ItemJnlLine, Last);
            end;
        end;
        //006 end
    end;

    procedure PostOutputJournalArch(VAR Rec: Record "GUI-to-BC Output Line Arch"; Last: Boolean);
    VAR
        ItemJnlLine: Record "Item Journal Line";
        OutputLineArch: Record "GUI-to-BC Output Line Arch";
    begin
        //003 Start
        WITH Rec DO begin
            OutputLineArch.COPY(Rec);
            OutputLineArch.MODIFYALL("Journal Posted", TRUE);

            IF ("Journal Template Name" = '') OR
               ("Journal Batch Name" = '')
            THEN
                EXIT;

            ItemJnlLine.RESET;
            ItemJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
            ItemJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            //006 Start
            IF "Journal Line No." <> 0 THEN
                ItemJnlLine.SETRANGE("Line No.", "Journal Line No.");
            ItemJnlLine.SETRANGE("Order No.", "Prod. Order No.");
            ItemJnlLine.SETRANGE("External Document No.", "Document No.");
            IF NOT ItemJnlLine.ISEMPTY THEN begin
                IF "Journal Line No." <> 0 THEN
                    ItemJnlLine.SETRANGE("Line No.");
                ItemJnlLine.FINDSET;
                //006 end
                PostItemJnl(ItemJnlLine, Last);
            end; //006
        end;
        //003 end
    end;

    local procedure PostItemJnl(VAR Rec: Record "Item Journal Line"; Last: Boolean): Boolean;
    VAR
        ItemJnlLine: Record "Item Journal Line";
        ErrorMsgTxt: Text;
    begin
        //003 Start
        WITH Rec DO begin
            ItemJnlLine.COPY(Rec);
            PostItemJnl2(ItemJnlLine, Last);
            COPY(ItemJnlLine);
            EXIT(TRUE);
        end;
        //003 end
    end;

    local procedure PostItemJnl2(VAR ItemJnlLine: Record 83; Last: Boolean);
    VAR
        ItemJnlPostBatch: Codeunit 50012;
        ErrorMsgTxt: Text;
    begin

        WITH ItemJnlLine DO begin
            ErrorMsgTxt := '';
            CLEARLASTERROR;

            ItemJnlTemplate.GET("Journal Template Name");
            ItemJnlTemplate.TESTFIELD("Force Posting Report", FALSE);


            ItemJnlPostBatch.SetHideDialog(TRUE);
            ItemJnlPostBatch.SetNoCommit(TRUE);
            ItemJnlPostBatch.RUN(ItemJnlLine);
            IF Last THEN
                ItemJnlPostBatch.FinalizeBatchPost; // Has COMMIT's
            CLEAR(ItemJnlPostBatch);
        end;

    end;

    local procedure CreateReservationEntry(var ItemJnlLine: Record "Item Journal Line"; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SNRequired: Boolean;
        LotInfoRequired: Boolean;
        LastEntry: Integer;
        NextReserEntry: Record "Reservation Entry";

        LotNoInfo: Record "Lot No. Information";
    begin
        NextReserEntry.Reset();
        IF NextReserEntry.FindLast() THEN
            LastEntry := NextReserEntry."Entry No."
        ELSE
            LastEntry := 0;

        Item.Get(ItemJnlLine."Item No.");

        if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
            SNRequired := ItemTrackingCode."SN Specific Tracking";
            LotInfoRequired := ItemTrackingCode."Lot Specific Tracking";
        end;
        IF (SNRequired) OR (LotInfoRequired) THEN begin

            ReservationEntry.Init();
            ReservationEntry."Entry No." := LastEntry + 1;
            ReservationEntry."Item No." := ItemJnlLine."Item No.";
            ReservationEntry.Description := ItemJnlLine.Description;
            ReservationEntry."Location Code" := ItemJnlLine."Location Code";
            ReservationEntry."Variant Code" := ItemJnlLine."Variant Code";

            if ItemJnlLine."Quantity (Base)" < 0 then begin
                ReservationEntry.Validate("Quantity (Base)", ItemJnlLine."Quantity");
                ReservationEntry."Appl.-to Item Entry" := FindItemLedgerEntry(ItemJnlLine, LotNo);
            end else
                ReservationEntry.Validate("Quantity (Base)", ItemJnlLine."Quantity");

            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
            ReservationEntry."Source Type" := Database::"Item Journal Line";


            ReservationEntry."Source Subtype" := ReservationEntry."Source Subtype"::"6";
            ReservationEntry."Source ID" := ItemJnlLine."Journal Template Name";
            ReservationEntry."Source Batch Name" := ItemJnlLine."Journal Batch Name";
            ReservationEntry."Source Ref. No." := ItemJnlLine."Line No.";
            ReservationEntry."Expected Receipt Date" := ItemJnlLine."Document Date";

            ReservationEntry."Expiration Date" := ExpirationDate;

            ReservationEntry."Qty. per Unit of Measure" := ItemJnlLine."Qty. per Unit of Measure";
            ReservationEntry.VALIDATE("Lot No.", LotNo);
            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
            ReservationEntry."Created By" := UserId;

            ReservationEntry.Positive := true;

            ReservationEntry."Creation Date" := WorkDate();
            ReservationEntry.Insert();

            //update Lot No card and change Mfg. date
            /*   LotNoInfo.Reset();
              LotNoInfo.SetRange("Item No.", ItemJnlLine."Item No.");
              LotNoInfo.SetRange("Lot No.", LotNo);
              if LotNoInfo.FindFirst() then begin
                  if  LotNoInfo.KMK_ManufactureDate =0D then
                  LotNoInfo.KMK_ManufactureDate := ItemJnlLine."Document Date";
               LotNoInfo.Modify();
              end; */
        end;

    end;

    local procedure OnAfterChangeProdOrderLineQuantity(VAR ProdOrderLine: Record 5406; VAR Handled: Boolean);
    begin
    end;

    local procedure CreateLotNoInfo(VAR InvtAdjmtLine: Record "GUI-to-BC Output Line");
    VAR
        LotNoInfo: Record "Lot No. Information";
        ResEntryItem: Record Item;
        ExpDate: Date;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        EntriesExist: Boolean;
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        //007 Start
        //034 COMMIT;
        IF NOT LotNoInfo.GET(InvtAdjmtLine."Item No.", InvtAdjmtLine."Variant Code", InvtAdjmtLine."Lot No.") THEN begin
            ResEntryItem.GET(InvtAdjmtLine."Item No.");
            LotNoInfo.INIT;
            LotNoInfo."Item No." := InvtAdjmtLine."Item No.";
            LotNoInfo."Lot No." := InvtAdjmtLine."Lot No.";
            LotNoInfo.Description := 'Auto Create';
            ExpDate := InvtAdjmtLine."Expiration Date";  //024

            IF ExpDate = 0D THEN
                ExpDate := ItemTrackingMgt.ExistingExpirationDate(InvtAdjmtLine."Item No.", InvtAdjmtLine."Variant Code", ItemTrackingSetup, false, EntriesExist);

            IF ExpDate <> 0D then begin
                //>> LotNoInfo.KMK_ManufactureDate := ExpDate - ResEntryItem.KMK_ShelfLifeDays;
                if (LotNoInfo.KMK_ManufactureDate = 0D) then
                    LotNoInfo.KMK_ManufactureDate := InvtAdjmtLine."Document Date";
                LotNoInfo.KMK_DaysRemaining := ExpDate - TODAY;
            end;

            LotNoInfo.Insert()
        end else begin


            LotNoInfo.Description := 'Auto Create';
            ExpDate := InvtAdjmtLine."Expiration Date";

            IF ExpDate = 0D THEN
                ExpDate := ItemTrackingMgt.ExistingExpirationDate(InvtAdjmtLine."Item No.", InvtAdjmtLine."Variant Code", ItemTrackingSetup, false, EntriesExist);

            IF ExpDate <> 0D THEN begin
                //>>  LotNoInfo.KMK_ManufactureDate := ExpDate - ResEntryItem.KMK_ShelfLifeDays;
                if (LotNoInfo.KMK_ManufactureDate = 0D) then
                    LotNoInfo.KMK_ManufactureDate := InvtAdjmtLine."Document Date";
                LotNoInfo.KMK_DaysRemaining := ExpDate - TODAY;
            end;
            LotNoInfo.Modify()
        end;
        //007 end
    end;

    procedure FindItemLedgerEntry(VAR ItemJournalLine: Record "Item Journal Line"; LotNo: Code[20]): Integer
    var
        ILE: Record "Item Ledger Entry";
    begin
        ILE.Setrange("Order Type", ILE."Order Type"::Production);
        ILE.Setrange("Order No.", ItemJournalLine."Order No.");
        ILE.Setrange("Order Line No.", ItemJournalLine."Order Line No.");
        ILE.Setrange("Entry Type", ILE."Entry Type"::Output);
        ILE.SetFilter("Remaining Quantity", '>=%1', ItemJournalLine.Quantity);
        if ILE.FindFirst() then
            exit(ILE."Entry No.");
    end;


}