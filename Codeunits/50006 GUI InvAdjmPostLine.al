codeunit 50006 "GUI Inventory Adjmt.-Post Line"
{

    TableNo = "GUI-to-BC Invt. Adjmt. Line";

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


    var
        InvtSetup: Record 313;
        GlobalInvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line";
        GlobalInvtAdjmtLineArch: Record 50011;
        TempInvtAdjmtLineBuf: Record "GUI-to-BC Invt. Adjmt. Line" temporary;
        ItemJnlTemplate: Record 82;
        ItemJnlBatch: Record 233;
        InvtAdjmtCheckLine: Codeunit 50005;
        //>>  ItemJnlPostLine: Codeunit 22;
        NoSeriesMgt: Codeunit 396;
        Mgt: Codeunit 50010;
        IntegrMgt: Codeunit GUIToBCIntegrationMgt;
        ErrMsgTxt: Text;
        NextEntryNo: Integer;
        InvtSetupRead: Boolean;
        ItemJnlPostFailedText: TextConst ENU = 'Item Journal Line posting failed.';
        // InvtAdjmtJnlBatchNameText: TextConst ENU = 'GUI-ADJ';
        InvtAdjmtJnlBatchNameText: Text;
        InvtAdjmtJnlBatchDescText: TextConst ENU = 'GUI-to-BC Adjustments Journal';
        MustBeSpecifiedText: TextConst ENU = '%1 must be specified.';
        ReservationEntry: Record "Reservation Entry";

    procedure RunWithCheck(VAR InvtAdjmtBuf2: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        InvtAdjmtBuf: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        InvtAdjmtBuf.COPY(InvtAdjmtBuf2);
        Code(InvtAdjmtBuf, TRUE);
        InvtAdjmtBuf2 := InvtAdjmtBuf;
    end;

    procedure RunWithoutCheck(VAR InvtAdjmtBuf2: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        InvtAdjmtBuf: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        InvtAdjmtBuf.COPY(InvtAdjmtBuf2);
        Code(InvtAdjmtBuf, FALSE);
        InvtAdjmtBuf2 := InvtAdjmtBuf;
    end;

    local procedure Code(VAR InvtAdjmtBuf: Record "GUI-to-BC Invt. Adjmt. Line"; CheckLine: Boolean);
    begin
        WITH InvtAdjmtBuf DO begin
            IF EmptyLine THEN
                EXIT;

            //011 Start
            IF ("Processing Status" IN ["Processing Status"::New, "Processing Status"::Processed]) THEN
                EXIT;
            //011 end

            IF CheckLine THEN
                InvtAdjmtCheckLine.RunCheck(InvtAdjmtBuf);

            IF NextEntryNo = 0 THEN
                StartPosting(InvtAdjmtBuf)
            ELSE
                ContinuePosting(InvtAdjmtBuf);

            IF "Ready for Processing" AND NOT "Validation Error" THEN
                PostInvtAdjmtLine(InvtAdjmtBuf);

            FinishPosting;
        end;
    end;

    procedure StartPosting(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    begin
        WITH InvtAdjmtLine DO begin
            GlobalInvtAdjmtLineArch.LOCKTABLE;
            IF GlobalInvtAdjmtLineArch.FINDLAST THEN
                NextEntryNo := GlobalInvtAdjmtLineArch."Entry No." + 1 //009
            ELSE
                NextEntryNo := 1;

            TempInvtAdjmtLineBuf.DELETEALL;
        end;

        //005 Start
        //GetItemJnlTemplate(PAGE::"Item Reclass. Journal",1,FALSE);
        //GetItemJnlBatch;
        //005 end
    end;

    procedure ContinuePosting(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    begin
        WITH InvtAdjmtLine DO begin
            ;
        end;

        TempInvtAdjmtLineBuf.DELETEALL;
    end;

    procedure FinishPosting();
    begin
        //002 Start
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Invt. Adjmt. Line") THEN
            EXIT;
        //002 end

        IF TempInvtAdjmtLineBuf.FINDSET THEN
            REPEAT
                //011 Start - Moved to function //
                IntegrMgt.ArchiveSingleInvtAdjmt(TempInvtAdjmtLineBuf, NextEntryNo, FALSE);
            //011 end
            UNTIL TempInvtAdjmtLineBuf.NEXT = 0;
    end;

    local procedure PostInvtAdjmtLine(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        ItemJnlLine: Record 83;
        Handled: Boolean;
    begin
        WITH InvtAdjmtLine DO begin
            ItemJnlLine.LOCKTABLE; //011

            CLEARLASTERROR;

            //012 Start
            OnCheckInvtAdjmtLineHandled(InvtAdjmtLine, Handled);
            IF NOT Handled THEN begin
                //012 end
                IF CreateItemJnlLine(ItemJnlLine, InvtAdjmtLine) THEN
                    OnMoveInvtAdjmtLine(ItemJnlLine.RECORDID)
                ELSE
                    ERROR(GETLASTERRORTEXT); //011
            end; //012

            TempInvtAdjmtLineBuf := InvtAdjmtLine;
            TempInvtAdjmtLineBuf.INSERT;
        end;
    end;

    local procedure CreateItemJnlLine(VAR ItemJnlLine: Record "Item Journal Line"; InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    VAR
        xItemJnlLine: Record "Item Journal Line";
        NextLineNo: Integer;
        InvtAdjmtLineUpdate: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        WITH ItemJnlLine DO begin
            //005 Start
            GetInvtAdjmtJnlTemplate(InvtAdjmtLine);
            GetItemJnlBatch;
            CLEAR(xItemJnlLine);
            //005 end

            RESET;
            SETRANGE("Journal Template Name", ItemJnlTemplate.Name);
            SETRANGE("Journal Batch Name", ItemJnlBatch.Name);
            IF FINDLAST THEN begin
                NextLineNo := "Line No." + 10000;
                xItemJnlLine := ItemJnlLine;
            end ELSE
                NextLineNo := 10000;

            INIT;
            "Journal Template Name" := ItemJnlTemplate.Name;
            "Journal Batch Name" := ItemJnlBatch.Name;
            "Line No." := NextLineNo;

            //005 Start
            "Entry Type" := GetItemJnlLineEntryType(InvtAdjmtLine);
            //005 end
            SetUpNewItemJnlLine(ItemJnlLine, xItemJnlLine);
            INSERT(TRUE);

            //005 Start
            "Entry Type" := GetItemJnlLineEntryType(InvtAdjmtLine);
            //005 end
            "Posting Date" := InvtAdjmtLine."Document Date";
            "Document Date" := InvtAdjmtLine."Document Date";
            "External Document No." := InvtAdjmtLine."Document No.";
            "GUI Description" := InvtAdjmtLine."GUI Description";
            "GUI Pallet" := InvtAdjmtLine."GUI Pallet";
            "GUI Time of Action" := InvtAdjmtLine."GUI Time of Action";
            "GUI Type" := InvtAdjmtLine."GUI Type";
            "GUI-to-BC Entry No" := InvtAdjmtLine."Entry No.";
            "GUI User ID" := InvtAdjmtLine."GUI User ID";
            Validate("Item No.", InvtAdjmtLine."Item No.");
            Validate("Unit of Measure Code", InvtAdjmtLine."Unit of Measure Code");
            Validate(Quantity, InvtAdjmtLine.Quantity);
            Validate("Location Code", InvtAdjmtLine."Location Code");




            // InvtAdjmtLine.CopyToItemJnlLine(ItemJnlLine,TRUE);
            InvtAdjmtLine.OnCopyToItemJnlLine(ItemJnlLine, TRUE); //003

            InvtAdjmtLineUpdate.Reset();
            If InvtAdjmtLineUpdate.get(InvtAdjmtLine."Entry No.") then begin
                InvtAdjmtLineUpdate."Journal Template Name" := ItemJnlLine."Journal Template Name";
                InvtAdjmtLineUpdate."Journal Batch Name" := ItemJnlLine."Journal Batch Name";
                InvtAdjmtLineUpdate."Journal Document No." := ItemJnlLine."Document No.";
                InvtAdjmtLineUpdate."Journal Line No." := ItemJnlLine."Line No.";
                InvtAdjmtLineUpdate.Validate(Processed, True);
                InvtAdjmtLineUpdate.SetProcessingStatus(2);
                InvtAdjmtLineUpdate.Modify();


            end;
            MODIFY;



            CreateReservationEntry(ItemJnlLine,
            InvtAdjmtLine."Lot No.", InvtAdjmtLine."Serial No.", InvtAdjmtLine."Expiration Date", InvtAdjmtLine."Warranty Date", "Quantity (Base)");
            CreateLotNoInfo(InvtAdjmtLine);
            EXIT(TRUE);
            //007 end
        end;
    end;

    local procedure SetUpNewItemJnlLine(VAR Rec: Record 83; LastItemJnlLine: Record 83);
    begin
        //005 Start
        Mgt.SetUpNewItemJnlLine(Rec, LastItemJnlLine); //008 - moved to function
                                                       //005 end
    end;

    local procedure UpdateItemJnlLineItemTracking(ItemJnlLine: Record 83; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal; IsReclassJnl: Boolean);
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
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
        ItemTrackinSetup: Record "Item Tracking Setup";
    begin
        WITH ItemJnlLine DO begin
            TESTFIELD("Item No.");
            TESTFIELD(Quantity);

            Item.GET("Item No.");
            //010 Start
            //ItemTrackingCode.GET(Item."Item Tracking Code");
            ItemTrackingCode.Code := Item."Item Tracking Code";
            /*             ItemTrackingMgt.GetItemTrackingSetup(
                          ItemTrackingCode, ItemJnlLine."Entry Type", IsInbound,
                          ItemTrackinSetup); */
            if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
                SNRequired := ItemTrackingCode."SN Specific Tracking";
                LotRequired := ItemTrackingCode."Lot Specific Tracking";
            end;
            IF NOT SNRequired OR LotInfoRequired THEN
                EXIT;

            IF (LineQty <> 0) THEN begin
                IF SNRequired AND (SerialNo = '') THEN
                    ERROR(MustBeSpecifiedText, TrackingSpecification.FIELDCAPTION("Serial No."));
                IF LotRequired AND (LotNo = '') THEN
                    ERROR(MustBeSpecifiedText, TrackingSpecification.FIELDCAPTION("Lot No."));
                IF (LotNo = '') AND (SerialNo = '') THEN
                    EXIT;
            end;
            //010 end

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
                            //013 Start
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
                            //013 end
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

                ItemTrackingLines.GUIInsertRecord(TempTrackingSpecification);
                Found := TRUE;
            end;
            IF Found THEN
                ItemTrackingLines.GUICloseForm;

            CLEAR(ItemTrackingLines);
        end;

    end;
    //003 end


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

    local procedure GetInvtAdjmtJnlTemplate(InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    begin
        //005 Start
        WITH InvtAdjmtLine DO begin
            CASE "Entry Type" OF
                "Entry Type"::"Negative Adjmt.",
              "Entry Type"::"Positive Adjmt.":
                    EXIT(GetItemJnlTemplate(PAGE::"Item Journal", 0, FALSE));
                "Entry Type"::Transfer:
                    EXIT(GetItemJnlTemplate(PAGE::"Item Reclass. Journal", 1, FALSE));
            end;
        end;
        //005 end
    end;

    local procedure GetItemJnlTemplate(PageID: Integer; PageTemplate: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order"; RecurringJnl: Boolean): Boolean;
    begin
        // PAGE::"Item Reclass. Journal",1,FALSE
        ItemJnlTemplate.RESET;
        ItemJnlTemplate.SETRANGE("Page ID", PageID);
        ItemJnlTemplate.SETRANGE(Recurring, RecurringJnl);
        ItemJnlTemplate.SETRANGE(Type, PageTemplate);
        EXIT(ItemJnlTemplate.FINDFIRST);
    end;

    local procedure GetItemJnlBatch(): Boolean;
    var
        GuiToBCSetup: Record "GUI-to-BC Setup";
    begin
        GuiToBCSetup.Reset();
        GuiToBCSetup.Get();
        IF GuiToBCSetup."Item Jnl Batch Name" = '' then
            InvtAdjmtJnlBatchNameText := 'GUI-ADJ'
        else
            InvtAdjmtJnlBatchNameText := GuiToBCSetup."Item Jnl Batch Name";

        IF NOT ItemJnlBatch.GET(ItemJnlTemplate.Name, InvtAdjmtJnlBatchNameText) THEN begin
            ItemJnlBatch.INIT;
            ItemJnlBatch."Journal Template Name" := ItemJnlTemplate.Name;
            ItemJnlBatch.SetupNewBatch;
            ItemJnlBatch.Name := InvtAdjmtJnlBatchNameText;
            ItemJnlBatch.Description := InvtAdjmtJnlBatchDescText;
            ItemJnlBatch."No. Series" := ItemJnlTemplate."No. Series"; //007
            ItemJnlBatch.INSERT(TRUE);
        end;

        ItemJnlBatch.SETRANGE("Journal Template Name", ItemJnlTemplate.Name);
        ItemJnlBatch.SETRANGE(Name, InvtAdjmtJnlBatchNameText);
        EXIT(ItemJnlBatch.FINDFIRST);
    end;

    local procedure GetItemJnlLineEntryType(InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Integer;
    VAR
        ItemJnlLine: Record 83;
    begin
        //005 Start
        //004 Start
        WITH InvtAdjmtLine DO begin
            CASE "Entry Type" OF
                "Entry Type"::"Negative Adjmt.":
                    EXIT(ItemJnlLine."Entry Type"::"Negative Adjmt.");
                "Entry Type"::"Positive Adjmt.":
                    EXIT(ItemJnlLine."Entry Type"::"Positive Adjmt.");
                "Entry Type"::Transfer:
                    //004 end
                    EXIT(ItemJnlLine."Entry Type"::Transfer);
            end; //004
        end;
        //005 end
    end;

    procedure PostInvtReclassJournal(VAR Rec: Record "GUI-to-BC Invt. Adjmt. Line"; Last: Boolean);
    VAR
        ItemJnlLine: Record 83;
        InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        //006 Start
        WITH Rec DO begin
            InvtAdjmtLine.COPY(Rec);
            InvtAdjmtLine.MODIFYALL("Journal Posted", TRUE);

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
        //006 end
    end;

    procedure PostSingleInvtReclassJournal(VAR Rec: Record "GUI-to-BC Invt. Adjmt. Line"; Last: Boolean);
    VAR
        ItemJnlLine: Record 83;
        InvtAdjLine: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        //011 Start
        WITH Rec DO begin
            InvtAdjLine.COPY(Rec);
            InvtAdjLine."Journal Posted" := TRUE;
            InvtAdjLine.MODIFY;

            IF ("Journal Template Name" = '') OR
               ("Journal Batch Name" = '')
            THEN
                EXIT;

            ItemJnlLine.RESET;
            ItemJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
            ItemJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            ItemJnlLine.SETRANGE("Line No.", "Journal Line No.");
            IF ItemJnlLine.FINDFIRST THEN
                PostItemJnl(ItemJnlLine, Last);
        end;
        //011 end
    end;

    procedure PostInvtReclassJournalArch(VAR Rec: Record 50011; Last: Boolean);
    VAR
        ItemJnlLine: Record 83;
        InvtAdjmtLineArch: Record 50011;
    begin
        //006 Start
        WITH Rec DO begin
            InvtAdjmtLineArch.COPY(Rec);
            InvtAdjmtLineArch.MODIFYALL("Journal Posted", TRUE);

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
        //006 end
    end;

    local procedure PostItemJnl(VAR Rec: Record 83; Last: Boolean): Boolean;
    VAR
        ItemJnlLine: Record 83;
        ErrorMsgTxt: Text;
    begin
        //006 Start
        WITH Rec DO begin
            ItemJnlLine.COPY(Rec);
            PostItemJnl2(ItemJnlLine, Last);
            COPY(ItemJnlLine);
            EXIT(TRUE);
        end;
        //006 end
    end;

    local procedure PostItemJnl2(VAR ItemJnlLine: Record 83; Last: Boolean);
    VAR
        ItemJnlPostBatch: Codeunit 50012;
        ErrorMsgTxt: Text;
    begin
        //006 Start
        WITH ItemJnlLine DO begin
            ErrorMsgTxt := '';
            CLEARLASTERROR;

            ItemJnlTemplate.GET("Journal Template Name");
            ItemJnlTemplate.TESTFIELD("Force Posting Report", FALSE);

            //CODEUNIT.RUN(CODEUNIT::"GUI Item Jnl.-Post Batch",ItemJnlLine);
            ItemJnlPostBatch.SetHideDialog(TRUE);
            ItemJnlPostBatch.SetNoCommit(TRUE);
            ItemJnlPostBatch.RUN(ItemJnlLine);
            IF Last THEN
                ItemJnlPostBatch.FinalizeBatchPost; // Has COMMIT's
            CLEAR(ItemJnlPostBatch);
        end;
        //006 end
    end;

    local procedure CreateReservationEntry(var ItemJnlLine: Record "Item Journal Line"; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SNRequired: Boolean;
        LotRequired: Boolean;
        LotInfoRequired: Boolean;
        LastEntry: Integer;
        NextReserEntry: Record "Reservation Entry";
    begin
        NextReserEntry.Reset();
        IF NextReserEntry.FindLast() THEN
            LastEntry := NextReserEntry."Entry No."
        ELSE
            LastEntry := 0;

        Item.Get(ItemJnlLine."Item No.");

        if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
            LotRequired := ItemTrackingCode."Lot Specific Tracking";
            LotInfoRequired := ItemTrackingCode."Lot Info. Inbound Must Exist";
        end;
        IF NOT LotRequired OR LotInfoRequired THEN
            EXIT;

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Positive Adjmt." then begin
            ReservationEntry.Init();
            ReservationEntry."Entry No." := LastEntry + 1;
            ReservationEntry."Item No." := ItemJnlLine."Item No.";
            ReservationEntry.Description := ItemJnlLine.Description;
            ReservationEntry."Location Code" := ItemJnlLine."Location Code";
            ReservationEntry."Variant Code" := ItemJnlLine."Variant Code";

            ReservationEntry.Validate("Quantity (Base)", ItemJnlLine."Quantity (Base)");

            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
            ReservationEntry."Source Type" := Database::"Item Journal Line";


            ReservationEntry."Source Subtype" := ReservationEntry."Source Subtype"::"2";
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
        end;

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt." then
            ReservationEntry.Init();
        ReservationEntry."Entry No." := LastEntry + 1;
        ReservationEntry."Item No." := ItemJnlLine."Item No.";
        ReservationEntry.Description := ItemJnlLine.Description;
        ReservationEntry."Location Code" := ItemJnlLine."Location Code";
        ReservationEntry."Variant Code" := ItemJnlLine."Variant Code";


        ReservationEntry.Validate("Quantity (Base)", -ItemJnlLine."Quantity (Base)");
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
        ReservationEntry."Source Type" := Database::"Item Journal Line";

        ReservationEntry."Source Subtype" := ReservationEntry."Source Subtype"::"3";

        ReservationEntry."Source ID" := ItemJnlLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := ItemJnlLine."Journal Batch Name";
        ReservationEntry."Source Ref. No." := ItemJnlLine."Line No.";
        ReservationEntry."Shipment Date" := ItemJnlLine."Posting Date";
        ReservationEntry."Qty. per Unit of Measure" := ItemJnlLine."Qty. per Unit of Measure";
        ReservationEntry.VALIDATE("Lot No.", LotNo);
        ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
        ReservationEntry."Created By" := UserId;
        ReservationEntry."Creation Date" := WorkDate();
        ReservationEntry.Positive := false;
        ReservationEntry.Insert();
    end;


    [IntegrationEvent(true, false)]
    local procedure OnCheckInvtAdjmtLineHandled(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"; VAR Handled: Boolean);
    begin
    end;

    local procedure CreateLotNoInfo(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
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
                if (InvtAdjmtLine."Entry Type" = InvtAdjmtLine."Entry Type"::"Positive Adjmt.") and (LotNoInfo.KMK_ManufactureDate = 0D) then
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
                if (InvtAdjmtLine."Entry Type" = InvtAdjmtLine."Entry Type"::"Positive Adjmt.") and (LotNoInfo.KMK_ManufactureDate = 0D) then
                    LotNoInfo.KMK_ManufactureDate := InvtAdjmtLine."Document Date";
                LotNoInfo.KMK_DaysRemaining := ExpDate - TODAY;
            end;
            LotNoInfo.Modify()
        end;
        //007 end
    end;
}