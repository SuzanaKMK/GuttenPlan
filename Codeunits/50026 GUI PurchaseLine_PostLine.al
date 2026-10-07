codeunit 50026 GUIPurchaseLine_PostLine
{
    TableNo = "GUI-to-BC Purchase Line";
    Permissions = TableData "Purchase Line" = rimd,
                TableData "GUI-to-BC Purchase Line" = r;

    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    var
        TempPurchHdr: Record "Purchase Header" temporary;
        DoesNotExistText: TextConst ENU = '%1 %2 does not exist.';
        MustBeSpecifiedText: TextConst ENU = '%1 must be specified.';
        MustNotBeText: TextConst ENU = '%1 must not %2.';
        MustBeText: TextConst ENU = '%1 %2 %3 must be %4.';
        GlobalPurchLine: Record "GUI-to-BC Purchase Line";
        GlobalPurchLineArch: Record "GUI-to-BC Purchase Line Arch";
        TempGUItoNavPurchLineBuffer: Record "GUI-to-BC Purchase Line" temporary;
        GUIPurchaseLineCheckLine: Codeunit GUIPurchaseLine_CheckLine;
        Mgt: Codeunit 50010;
        ErrorMsgTxt: Text;
        FirstPurchOrderNo: Code[20];
        NextEntryNo: Integer;
        NotFoundOnPurchDoc: TextConst ENU = '%1 %2 not found on %3 %4.';
        MultiLinesFoundOnPurchDoc: TextConst ENU = 'Multiple %1 %2 lines are found on %3 %4.';
        FailedToPost: TextConst ENU = 'Posting of %1 %2 failed.';
        ReservationEntry: Record "Reservation Entry";

    PROCEDURE RunWithCheck(VAR GUItoNavPurchLineBuffer2: Record "GUI-to-BC Purchase Line");
    VAR
        GUItoNavPurchLineBuffer: Record "GUI-to-BC Purchase Line";
    BEGIN
        GUItoNavPurchLineBuffer.COPY(GUItoNavPurchLineBuffer2);
        Code(GUItoNavPurchLineBuffer, TRUE);
        GUItoNavPurchLineBuffer2 := GUItoNavPurchLineBuffer;
    END;

    PROCEDURE RunWithoutCheck(VAR GUItoNavPurchLineBuffer2: Record "GUI-to-BC Purchase Line");
    VAR
        GUItoNavPurchLineBuffer: Record "GUI-to-BC Purchase Line";
    BEGIN
        GUItoNavPurchLineBuffer.COPY(GUItoNavPurchLineBuffer2);
        Code(GUItoNavPurchLineBuffer, FALSE);
        GUItoNavPurchLineBuffer2 := GUItoNavPurchLineBuffer;
    END;

    LOCAL PROCEDURE Code(VAR GUItoNavPurchLineBuffer: Record "GUI-to-BC Purchase Line"; CheckLine: Boolean);
    BEGIN
        WITH GUItoNavPurchLineBuffer DO BEGIN
            IF EmptyLine THEN
                EXIT;

            //011 Start
            IF ("Processing Status" IN ["Processing Status"::New, "Processing Status"::Processed]) THEN
                EXIT;
            //011 End

            IF CheckLine THEN
                GUIPurchaseLineCheckLine.RunCheck(GUItoNavPurchLineBuffer);

            IF NextEntryNo = 0 THEN
                StartPosting(GUItoNavPurchLineBuffer)
            ELSE
                ContinuePosting(GUItoNavPurchLineBuffer);

            IF "Ready for Processing" AND NOT "Validation Error" THEN
                PostPurchLine(GUItoNavPurchLineBuffer);

            FinishPosting;
        END;
    END;

    PROCEDURE StartPosting(VAR GUItoNAVPurchaseLine: Record "GUI-to-BC Purchase Line");
    BEGIN
        WITH GUItoNAVPurchaseLine DO BEGIN
            GlobalPurchLineArch.LOCKTABLE;
            IF GlobalPurchLineArch.FINDLAST THEN
                NextEntryNo := GlobalPurchLineArch."Entry No." + 1 //009
            ELSE
                NextEntryNo := 1;

            TempGUItoNavPurchLineBuffer.DELETEALL;
            TempPurchHdr.DELETEALL;
        END;
    END;

    PROCEDURE ContinuePosting(VAR GUItoNAVPurchaseLine: Record "GUI-to-BC Purchase Line");
    BEGIN
        WITH GUItoNAVPurchaseLine DO BEGIN
            ;
        END;

        TempGUItoNavPurchLineBuffer.DELETEALL;
    END;

    PROCEDURE FinishPosting();
    BEGIN
        //002 Start
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Purchase Line") THEN
            EXIT;
        //002 End

        IF TempGUItoNavPurchLineBuffer.FINDSET THEN
            REPEAT
                GlobalPurchLineArch.INIT;
                GlobalPurchLineArch.TRANSFERFIELDS(TempGUItoNavPurchLineBuffer);
                GlobalPurchLineArch."Entry No." := NextEntryNo;
                GlobalPurchLineArch.INSERT;
                //OnAfterInsertPurchLineArch(GlobalPurchLineArch);
                NextEntryNo += 1;
            UNTIL TempGUItoNavPurchLineBuffer.NEXT = 0;
    END;

    LOCAL PROCEDURE PostPurchLine(VAR GUItoNAVPurchaseLine: Record "GUI-to-BC Purchase Line");
    VAR
        PurchLine: Record 39;
    BEGIN
        WITH GUItoNAVPurchaseLine DO BEGIN
            PurchLine.LOCKTABLE;

            //011 UpdatePurchLine(PurchLine,GUItoNAVPurchaseLine);
            IF UpdatePurchLine(PurchLine, GUItoNAVPurchaseLine) THEN BEGIN
                OnMoveGUItoBCPurchaseLine(PurchLine.RECORDID); // Change proc. status //

                TempGUItoNavPurchLineBuffer := GUItoNAVPurchaseLine;
                TempGUItoNavPurchLineBuffer.INSERT;
            END ELSE
                ERROR(GETLASTERRORTEXT); //011
        END;
    END;

    LOCAL PROCEDURE PostPurchaseHeader(DocType: Integer; DocNo: Code[20]): Boolean;
    VAR
        PurchHeader: Record "Purchase Header";
        PurchasePost: Codeunit "Purch.-Post";
    BEGIN
        ErrorMsgTxt := '';
        CLEARLASTERROR;

        PurchHeader.GET(DocType, DocNo);
        Mgt.SetPurchDocPostingOptions(PurchHeader);
        PurchHeader."Print Posted Documents" := FALSE;

        // SalesPost.SetNoCommit(TRUE);
        PurchasePost.RUN(PurchHeader);
        CLEAR(PurchasePost);

        EXIT(TRUE);
    END;

    LOCAL PROCEDURE UpdatePurchLine(VAR PurchLine: Record 39; GUItoNAVPurchaseLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        PurchaseHeader: Record 38;
        PurchDocRelease: Codeunit 415;
        HeaderExist: Boolean;
        WasReleased: Boolean;
    BEGIN
        WITH GUItoNAVPurchaseLine DO BEGIN
            //002 Start
            IF FindTempPurchOrder(GUItoNAVPurchaseLine) THEN
                HeaderExist := PurchaseHeader.GET(TempPurchHdr."Document Type", TempPurchHdr."No.")
            ELSE BEGIN
                HeaderExist := PurchaseHeader.GET("Document Type", "Document No.");
                IF HeaderExist THEN BEGIN
                    //007 Start - Moved to function //
                    PurchHeaderResetQtyToReceive(PurchaseHeader);
                    //007 End
                    InsertTempPurchOrder(PurchaseHeader);
                END;
            END;

            IF HeaderExist THEN BEGIN
                //005 Start
                IF PurchaseHeader."Posting Date" <> "Document Date" THEN BEGIN
                    IF PurchaseHeader.Status <> PurchaseHeader.Status::Open THEN BEGIN
                        PurchDocRelease.Reopen(PurchaseHeader);
                        WasReleased := TRUE;
                    END;
                    PurchaseHeader.VALIDATE("Posting Date", "Document Date");
                    PurchaseHeader.MODIFY;
                    IF WasReleased THEN
                        PurchDocRelease.RUN(PurchaseHeader);
                END;
                //005 End

                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", PurchaseHeader."Document Type");
                PurchLine.SETRANGE("Document No.", PurchaseHeader."No.");
                IF "Document Line No." <> 0 THEN
                    PurchLine.SETRANGE("Line No.", "Document Line No.")
                ELSE BEGIN
                    PurchLine.SETRANGE(Type, Type);
                    PurchLine.SETRANGE("No.", "No.");
                END;
                PurchLine.SETFILTER("Outstanding Quantity", '<>0');
                CASE PurchLine.COUNT OF
                    1:
                        BEGIN
                            PurchLine.FINDFIRST;
                            PurchLine.VALIDATE("Qty. to Receive", PurchLine."Qty. to Receive" + Quantity);
                            PurchLine.KMK_GUIDescription := "GUI Description"; //012
                            PurchLine."GUI Pallet" := "GUI Pallet";
                            PurchLine."GUI Time of Action" := "GUI Time of Action";
                            PurchLine."GUI User ID" := "GUI User ID";
                            PurchLine."GUI Type" := "GUI Type";
                            PurchLine."GUI-to-BC Entry No" := "Entry No.";
                            PurchLine.MODIFY;


                            /*  UpdatePurchLineItemTracking(
                               PurchLine,
                               "Lot No.", "Serial No.", "Expiration Date", "Warranty Date", "Quantity (Base)"); */
                            CreateReservationEntry(PurchLine,
      "Lot No.", "Serial No.", "Expiration Date", "Warranty Date", "Quantity (Base)");
                        END;
                    0:
                        ERROR(
                          NotFoundOnPurchDoc,
                          FORMAT(Type), "No.", FORMAT(PurchaseHeader."Document Type"), PurchaseHeader."No.");
                    ELSE
                        ERROR(
                          MultiLinesFoundOnPurchDoc,
                          FORMAT(Type), "No.", FORMAT(PurchaseHeader."Document Type"), PurchaseHeader."No.");
                END;
            END;

            EXIT(TRUE); //011
                        //002 End
        END;
    END;

    LOCAL PROCEDURE UpdatePurchLineItemTracking(PurchLine: Record 39; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal);
    VAR
        Item: Record 27;
        ItemTrackingCode: Record 6502;
        TrackingSpecification: Record 336;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingLines: Codeunit GUI_ItemTrackingLines;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OutstandingQtyBase: Decimal;
        QtyToHandleBase: Decimal;
        LastEntryNo: Integer;
        Found: Boolean;
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
    BEGIN
        //005 ItemTrackingLines -> Codeunit 50011 "GUI-to-NAV Item Tracking Lines"
        //002 Start
        WITH PurchLine DO BEGIN


            TESTFIELD(Type, Type::Item);
            TESTFIELD("No.");
            TESTFIELD("Outstanding Quantity");

            Item.GET("No.");
            //010 Start
            //ItemTrackingCode.GET(Item."Item Tracking Code");
            ItemTrackingCode.Code := Item."Item Tracking Code";
            /*  ItemTrackingMgt.GetItemTrackingSettings(
               ItemTrackingCode,0,IsInbound,
               SNRequired,LotRequired,SNInfoRequired,LotInfoRequired); */

            if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
                SNRequired := ItemTrackingCode."SN Specific Tracking";
                LotRequired := ItemTrackingCode."Lot Specific Tracking";
            end;

            IF NOT (SNRequired OR LotRequired) THEN
                EXIT;

            IF (LineQty <> 0) THEN BEGIN
                IF SNRequired AND (SerialNo = '') THEN
                    ERROR(MustBeSpecifiedText, TrackingSpecification.FIELDCAPTION("Serial No."));
                IF LotRequired AND (LotNo = '') THEN
                    ERROR(MustBeSpecifiedText, TrackingSpecification.FIELDCAPTION("Lot No."));
                IF (LotNo = '') AND (SerialNo = '') THEN
                    EXIT;
            END;
            //010 End

            TempTrackingSpecification.RESET;
            TempTrackingSpecification.DELETEALL;

            TrackingSpecification.INIT;
            TrackingSpecification.InitFromPurchLine(PurchLine);

            IF (("Document Type" = "Document Type"::Invoice) AND ("Receipt No." <> '')) OR
               (("Document Type" = "Document Type"::"Credit Memo") AND ("Return Shipment No." <> ''))
            THEN
                ItemTrackingLines.SetFormRunMode(2); // Combined shipment/receipt
            IF "Drop Shipment" THEN BEGIN
                ItemTrackingLines.SetFormRunMode(3); // Drop Shipment
                IF "Sales Order No." <> '' THEN
                    ItemTrackingLines.SetSecondSourceRowID(
                      ItemTrackingMgt.ComposeRowID(DATABASE::"Sales Line", 1, "Sales Order No.", '', 0, "Sales Order Line No."));
            END;
            IF "Expected Receipt Date" = 0D THEN
                ItemTrackingLines.SetSourceSpec(TrackingSpecification, WORKDATE)
            ELSE
                ItemTrackingLines.SetSourceSpec(TrackingSpecification, "Expected Receipt Date");
            ItemTrackingLines.SetInbound(IsInbound);
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
                            //014 Start
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
                            //014 End
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
                //006 Start
                //IF ExpirationDate <> 0D THEN
                IF (ExpirationDate <> 0D) AND
                   (ExpirationDate <> TempTrackingSpecification."Expiration Date") AND
                   (TempTrackingSpecification."Buffer Status2" <> TempTrackingSpecification."Buffer Status2"::"ExpDate blocked")
                THEN
                    //006 End
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
        //002 End
    END;

    PROCEDURE GetNextEntryNo(): Integer;
    BEGIN
        EXIT(NextEntryNo);
    END;

    LOCAL PROCEDURE FindTempPurchOrder(GUIPurchLine: Record "GUI-to-BC Purchase Line"): Boolean;
    BEGIN
        //002 Start
        WITH GUIPurchLine DO BEGIN
            IF "Document No." <> '' THEN BEGIN
                TempPurchHdr.SETRANGE("No.", "Document No.");
                EXIT(TempPurchHdr.FINDFIRST);
            END;
        END;
        //002 End
    END;

    LOCAL PROCEDURE InsertTempPurchOrder(NewPurchOrderHdr: Record 38);
    BEGIN
        //002 Start
        IF TempPurchHdr.GET(NewPurchOrderHdr."Document Type", NewPurchOrderHdr."No.") THEN
            EXIT;

        TempPurchHdr := NewPurchOrderHdr;
        TempPurchHdr.INSERT;
        //002 End
    END;

    PROCEDURE PostPurchDocGUIPurchLine(VAR GUIPurchLine: Record "GUI-to-BC Purchase Line");
    VAR
        PurchHeader: Record 38;
        PurchPost: Codeunit 90;
    BEGIN
        //003 Start
        WITH GUIPurchLine DO BEGIN
            IF NOT PostPurchHeader("Document Type", "Document No.") THEN BEGIN
                ErrorMsgTxt := GETLASTERRORTEXT;
                IF ErrorMsgTxt = '' THEN
                    ErrorMsgTxt := STRSUBSTNO(FailedToPost, FORMAT("Document Type"), "Document No.");

                MODIFYALL("Validation Error Message", COPYSTR(ErrorMsgTxt, 1, MAXSTRLEN("Validation Error Message")));
                MODIFYALL("Validation Error", TRUE);
            END;
        END;
        //003 End
    END;

    PROCEDURE PostPurchDocGUIPurchLineArch(VAR GUIPurchLineArch: Record "GUI-to-BC Purchase Line Arch");
    BEGIN
        //003 Start
        WITH GUIPurchLineArch DO BEGIN
            IF NOT PostPurchHeader("Document Type", "Document No.") THEN BEGIN
                ErrorMsgTxt := GETLASTERRORTEXT;
                IF ErrorMsgTxt = '' THEN
                    ErrorMsgTxt := STRSUBSTNO(FailedToPost, FORMAT("Document Type"), "Document No.");
                IF GUIALLOWED THEN
                    ERROR(ErrorMsgTxt);
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE PostPurchHeader(DocType: Integer; DocNo: Code[20]): Boolean;
    VAR
        PurchHeader: Record 38;
        PurchPost: Codeunit 90;
    BEGIN
        //003 Start
        ErrorMsgTxt := '';
        CLEARLASTERROR;

        PurchHeader.GET(DocType, DocNo);
        Mgt.SetPurchDocPostingOptions(PurchHeader);
        PurchHeader."Print Posted Documents" := FALSE;
        //011 Start
        //CODEUNIT.RUN(CODEUNIT::"Purch.-Post",PurchHeader);
        //>> PurchPost.SetNoCommit(TRUE);
        PurchPost.RUN(PurchHeader);
        CLEAR(PurchPost);
        //011 End
        EXIT(TRUE);
        //003 End
    END;

    PROCEDURE PurchHeaderResetQtyToReceive(PurchHeader: Record 38);
    VAR
        PurchLine: Record 39;
    BEGIN
        //007 Start
        WITH PurchHeader DO BEGIN
            PurchLine.RESET;
            PurchLine.SETRANGE("Document Type", "Document Type");
            PurchLine.SETRANGE("Document No.", "No.");
            PurchLine.SETFILTER("Outstanding Quantity", '<>0');
            IF PurchLine.FINDSET(TRUE) THEN
                REPEAT
                    PurchLineResetQtyToReceive(PurchLine);
                UNTIL PurchLine.NEXT = 0;
        END;
        //007 End
    END;

    PROCEDURE PurchLineResetQtyToReceive(VAR PurchLine: Record 39);
    BEGIN
        //007 Start
        WITH PurchLine DO BEGIN
            //008 Start
            CASE Type OF
                Type::Item:
                    BEGIN
                        //008 End
                        // Reset Qty. to Receive PO line //
                        IF "Qty. to Receive" <> 0 THEN BEGIN
                            // Reset Qty. to Handle on Item Tracking //
                            // UpdatePurchLineItemTracking(PurchLine, '', '', 0D, 0D, 0);
                            CreateReservationEntry(PurchLine, '', '', 0D, 0D, 0);
                            VALIDATE("Qty. to Receive", 0);
                            //012 MODIFY;
                        END;
                        //012 Start
                        //013 "GUI Description" := '';
                        MODIFY;
                        //012 End
                        //008 Start
                    END;
            END;
            //008 End
        END;
        //007 End
    END;

    local procedure CreateReservationEntry(var PurchLine: Record "Purchase Line"; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal)
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

        Item.Get(PurchLine."No.");

        if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
            LotRequired := ItemTrackingCode."Lot Specific Tracking";
            LotInfoRequired := ItemTrackingCode."Lot Info. Inbound Must Exist";
        end;
        IF NOT LotRequired OR LotInfoRequired THEN
            EXIT;

        ReservationEntry.Reset();
        ReservationEntry.SetRange("Source Type", Database::"Purchase Line");
        ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"1");
        ReservationEntry.SetRange("Source ID", PurchLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", PurchLine."Line No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        if LotNo <> '' then
            ReservationEntry.SetRange("Lot No.", LotNo);
        if ReservationEntry.FindFirst() then begin
            if LineQty = 0 then
                ReservationEntry.VALIDATE("Qty. to Handle (Base)", 0);
            ReservationEntry.Modify();
        end

        else begin

            ReservationEntry.Init();
            ReservationEntry."Entry No." := LastEntry + 1;
            ReservationEntry."Item No." := PurchLine."No.";
            ReservationEntry.Description := PurchLine.Description;
            ReservationEntry."Location Code" := PurchLine."Location Code";
            ReservationEntry."Variant Code" := PurchLine."Variant Code";

            ReservationEntry.Validate("Quantity (Base)", LineQty);

            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
            ReservationEntry."Source Type" := Database::"Purchase Line";


            ReservationEntry."Source Subtype" := ReservationEntry."Source Subtype"::"1";
            ReservationEntry."Source ID" := PurchLine."Document No.";
            ReservationEntry."Source Batch Name" := '';
            ReservationEntry."Source Ref. No." := PurchLine."Line No.";
            ReservationEntry."Expected Receipt Date" := WorkDate();

            ReservationEntry."Expiration Date" := ExpirationDate;

            ReservationEntry."Qty. per Unit of Measure" := PurchLine."Qty. per Unit of Measure";
            ReservationEntry.VALIDATE("Lot No.", LotNo);
            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
            ReservationEntry."Created By" := UserId;

            ReservationEntry.Positive := true;

            ReservationEntry."Creation Date" := WorkDate();
            ReservationEntry.Insert();

        end;
    end;
}