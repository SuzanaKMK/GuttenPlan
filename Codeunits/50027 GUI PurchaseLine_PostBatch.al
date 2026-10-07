codeunit 50027 GUIPurchaseLine_PostBatch
{
    TableNo = "GUI-to-BC Purchase Line";
    trigger OnRun()
    begin
        IF RunningResiliency THEN BEGIN
            rec.LockTable();
        END;

        CarryOutBufferLineAction(Rec);

    end;

    var
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';
        TempBufferLine: Record "GUI-to-BC Purchase Line" temporary;
        TempFailedBufferLine: Record "GUI-to-BC Purchase Line" temporary;
        TempPurchHeader: Record "Purchase Header" temporary;
        PurchHeader: Record 38;
        BufferCheckLine: Codeunit GUIPurchaseLine_CheckLine;
        BufferPostLine: Codeunit 50026;
        Mgt: Codeunit 50010;
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        LineCount: Integer;
        StartLineNo: Integer;
        EndLIneNo: Integer;
        NoOfRecords: Integer;
        CounterFailed: Integer;
        HideDialog: Boolean;
        RunningResiliency: Boolean;

    PROCEDURE CarryOutBatchAction(VAR Rec: Record "GUI-to-BC Purchase Line");
    VAR
        BufferLine: Record "GUI-to-BC Purchase Line";
    BEGIN
        /* //008 Start
        BufferLine.COPY(Rec);
        Code(BufferLine);
        Rec := BufferLine;
        //008 End */
        //006 Start
        BufferLine.COPY(Rec);
        Code(BufferLine);
        Rec := BufferLine;
        //006 End
    END;

    LOCAL PROCEDURE Code(VAR BufferLine: Record "GUI-to-BC Purchase Line");
    BEGIN
        InitDetails; //008
        BufferLine.Reset();
        BufferLine.SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //008  
        BufferLine.SETFILTER("Processing Status", '>%1', BufferLine."Processing Status"::New); //008
        BufferLine.SETRANGE(Processed, FALSE); //008
        IF NOT RunningResiliency THEN BEGIN //008
            BufferLine.LOCKTABLE;
        END;

        ProcessLines(BufferLine);
    END;


    LOCAL PROCEDURE ProcessLines(VAR BufferLine: Record "GUI-to-BC Purchase Line");
    VAR
        SkippedLine: Boolean;
    BEGIN

        WITH BufferLine DO BEGIN
            IF NOT FIND('=><') THEN BEGIN
                //  if not FindFirst() then begin
                "Entry No." := 0;
                COMMIT;
                EXIT;
            END;



            // Check Lines
            LineCount := 0;
            StartLineNo := "Entry No.";

            NoOfRecords := COUNT;
            BufferCheckLine.SetBatchMode(TRUE);
            REPEAT
                LineCount := LineCount + 1;
                CheckLine(BufferLine);
                //008 TempGUItoNAVPurchaseLine := GUIPurchLine2;
                //008 TempGUItoNAVPurchaseLine.INSERT;
                IF NEXT = 0 THEN
                    FINDFIRST;
            Until "Entry No." = StartLineNo;
            ///UNTIL Next = 0;
            // Post Lines
            LineCount := 0;
            //008 Start
            SkippedLine := FALSE;
            CounterFailed := 0;
            CLEAR(PurchHeader);

            CheckAndSyncAndSetReadyDocuments(BufferLine);
            COMMIT;
            //008 End

            SETRANGE("Ready for Processing", TRUE);
            //008 Start
            IF NOT ISEMPTY THEN BEGIN
                TempPurchHeader.RESET;
                IF TempPurchHeader.FINDSET THEN BEGIN
                    REPEAT
                        SETRANGE("Document Type", TempPurchHeader."Document Type");
                        SETRANGE("Document No.", TempPurchHeader."No.");
                        IF FINDSET(TRUE, FALSE) THEN BEGIN
                            REPEAT
                                NoOfRecords := COUNT;
                                IF RunningResiliency THEN BEGIN
                                    COMMIT;
                                    CLEARLASTERROR;
                                    IF NOT TryCarryOutBufferLineAction(BufferLine) THEN BEGIN
                                        GET("Entry No.");
                                        UpdateErrorMsg(GETLASTERRORTEXT);
                                        MODIFY;
                                        SetFailedBufferLine(BufferLine);
                                        CounterFailed += 1;
                                    END;
                                    COMMIT;
                                END ELSE
                                    CarryOutBufferLineAction(BufferLine);
                            Until NEXT = 0;
                        END;
                        SETRANGE("Document No.");
                        SETRANGE("Document Type");
                    UNTIL TempPurchHeader.NEXT = 0;
                    TempPurchHeader.DELETEALL;
                END;
                //008 End

                UpdateAndDeleteLines(BufferLine);

                COMMIT;
            END; //008

            CLEAR(BufferCheckLine);
            CLEAR(BufferPostLine);
            //008 CLEARMARKS;
        END;

        IF SkippedLine THEN
            IF GUIALLOWED AND NOT HideDialog THEN
                MESSAGE(SkippedLineMsg);
    END;

    LOCAL PROCEDURE CheckLine(VAR BufferLine: Record "GUI-to-BC Purchase Line");
    VAR
        BufferLineToUpdate: Record "GUI-to-BC Purchase Line";
    BEGIN

        BufferLineToUpdate.COPY(BufferLine);
        BufferCheckLine.RunCheck(BufferLineToUpdate);
        //006 Start
        BufferLine.COPY(BufferLineToUpdate);
        BufferLine.MODIFY;
        //006 End
    END;

    LOCAL PROCEDURE CheckDocumentNo(VAR BufferLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        BufferLine2: Record "GUI-to-BC Purchase Line";
    BEGIN

        WITH BufferLine DO BEGIN
            // All lines for Doc are ready, no errors //
            BufferLine2.RESET;
            BufferLine2.SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //006
            BufferLine2.SETRANGE("Document Type", "Document Type");
            BufferLine2.SETRANGE("Document No.", "Document No.");
            BufferLine2.SETRANGE("Validation Error", TRUE); //006
            BufferLine2.SETRANGE(Processed, FALSE); //006
            EXIT(BufferLine2.ISEMPTY);
        END;
        //002 End
    END;

    LOCAL PROCEDURE CarryOutBufferLineAction(VAR BufferLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        BufferLine2: Record "GUI-to-BC Purchase Line";
    BEGIN
        WITH BufferLine DO BEGIN
            //008 Start
            IF BufferLine.FINDSET(TRUE) THEN BEGIN
                REPEAT
                    LineCount := LineCount + 1;

                    IF "Ready for Processing" AND NOT "Validation Error" THEN BEGIN
                        IF NOT ParametersMatch(PurchHeader, BufferLine) THEN BEGIN
                            PurchHeader.GET("Document Type", "Document No.");
                            LastDocNo := PurchHeader."No.";
                        END;
                        //008 End
                        BufferLine2.COPY(BufferLine);
                        BufferPostLine.RunWithoutCheck(BufferLine2);
                        //008 Start
                    END;
                UNTIL NEXT = 0;
                BufferLine := BufferLine2;

                IF (PurchHeader."No." <> '') THEN
                    FinalizePurchHeader(PurchHeader, BufferLine);
            END;
            //008 End
        END;
        EXIT(TRUE);


    END;

    LOCAL PROCEDURE UpdateAndDeleteLines(VAR BufferLine: Record "GUI-to-BC Purchase Line");
    VAR
        BufferLine2: Record "GUI-to-BC Purchase Line";
        BufferLine3: Record "GUI-to-BC Purchase Line";
    BEGIN
        BufferLine2.COPY(BufferLine);
        BufferLine2.SETFILTER("No.", '<>%1', '');
        IF BufferLine2.FINDLAST THEN; // Remember the last line

        //002 Start
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Purchase Line") THEN
            EXIT;
        //002 End

        BufferLine3.COPY(BufferLine);
        //008 Start
        //BufferLine3.SETCURRENTKEY("Processing Status","Document Date","No.");
        //BufferLine3.SETRANGE("Processing Status",GUIShipLine3."Processing Status"::Processed);
        BufferLine3.SETRANGE("Ready for Processing");
        BufferLine3.SETRANGE(Processed, TRUE);
        //008 End
        IF NOT BufferLine3.ISEMPTY THEN
            BufferLine3.DELETEALL;
    END;

    PROCEDURE SetHideDialog(NewHideDialog: Boolean);
    BEGIN
        HideDialog := NewHideDialog;
    END;

    PROCEDURE SetRunningResiliency();
    BEGIN
        //>> RunningResiliency := TRUE; //008
        RunningResiliency := False; //005
    END;

    PROCEDURE SetTryParam(TryLineCount: Integer; TryLastDocNo: Code[20]; TryPurchHeader: Record 38; VAR TryFailedBufferLine: Record "GUI-to-BC Purchase Line");
    BEGIN
        //008 Start
        SetRunningResiliency;

        LineCount := TryLineCount;
        LastDocNo := TryLastDocNo;
        PurchHeader := TryPurchHeader;
        IF TryFailedBufferLine.FINDSET THEN
            REPEAT
                TempFailedBufferLine := TryFailedBufferLine;
                TempFailedBufferLine.INSERT;
            UNTIL TryFailedBufferLine.NEXT = 0;
        //008 End
    END;

    PROCEDURE GetTryParam(VAR TryLineCount: Integer; VAR TryLastDocNo: Code[20]; VAR TryPurchHeader: Record 38);
    BEGIN
        //008 Start
        TryLineCount := LineCount;
        TryLastDocNo := LastDocNo;
        TryPurchHeader := PurchHeader;
        //008 End
    END;

    PROCEDURE TryCarryOutBufferLineAction(VAR BufferLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        CarryOutAction: Codeunit GUIPurchaseLine_PostBatch;
    BEGIN
        //008 Start
        CarryOutAction.SetTryParam(LineCount, LastDocNo, PurchHeader, TempFailedBufferLine);
        IF CarryOutAction.RUN(BufferLine) THEN BEGIN
            CarryOutAction.GetTryParam(LineCount, LastDocNo, PurchHeader);
            EXIT(TRUE);
        END;
        EXIT(FALSE);
        //008 End
    END;

    LOCAL PROCEDURE SetFailedBufferLine(NewFailedBufferLine: Record "GUI-to-BC Purchase Line");
    BEGIN
        //008 Start
        TempFailedBufferLine := NewFailedBufferLine;
        TempFailedBufferLine.INSERT;
        //008 End
    END;

    PROCEDURE GetFailedCounter(): Integer;
    BEGIN
        //008 Start
        EXIT(CounterFailed);
        //008 End
    END;

    LOCAL PROCEDURE FinalizePurchHeader(VAR PurchHdr: Record 38; VAR BufferLine: Record "GUI-to-BC Purchase Line");
    VAR
        BufferLine2: Record "GUI-to-BC Purchase Line";
    BEGIN
        //008 Start
        IF NOT RunningResiliency THEN
          ;

        IF Mgt.IsAutomaticPurchDocEnabled() THEN BEGIN
            BufferLine2.COPY(BufferLine);
            BufferLine2.SETCURRENTKEY("Document Type", "Document No.", "Document Line No.");
            BufferLine2.SETRANGE("Document Type", PurchHdr."Document Type");
            BufferLine2.SETRANGE("Document No.", PurchHdr."No.");
            BufferLine2.SETRANGE("Posted Document No.", '');
            BufferLine2.SETRANGE("Processing Status");
            BufferLine2.SETRANGE("Ready for Processing");
            BufferLine2.SETRANGE("Validation Error");
            BufferLine2.SETRANGE(Processed);
            IF NOT BufferLine2.ISEMPTY THEN BEGIN
                BufferLine2.SETRANGE(Processed, FALSE);
                IF BufferLine2.ISEMPTY THEN BEGIN
                    BufferLine2.SETRANGE(Processed, TRUE);
                    BufferLine2.FINDSET;
                    BufferPostLine.PostPurchDocGUIPurchLine(BufferLine2);
                END;
            END;
        END;
        //008 End
    END;

    PROCEDURE PostPurchDoc(VAR Rec: Record "GUI-to-BC Purchase Line");
    VAR
        GUItoNAVPurchLine: Record "GUI-to-BC Purchase Line";
    BEGIN
        //003 Start
        GUItoNAVPurchLine.COPY(Rec);
        PostGUIPurchDoc(GUItoNAVPurchLine);
        Rec := GUItoNAVPurchLine;
        //003 End
    END;

    LOCAL PROCEDURE PostGUIPurchDoc(VAR GUItoNAVPurchaseLine: Record "GUI-to-BC Purchase Line");
    VAR
        GUItoNAVPurchLine: Record "GUI-to-BC Purchase Line";
        xGUItoNAVPurchLine: Record "GUI-to-BC Purchase Line";
    BEGIN
        //003 Start
        WITH GUItoNAVPurchLine DO BEGIN
            COPY(GUItoNAVPurchaseLine);
            SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //008
            SETRANGE(Processed, TRUE); //008
            SETRANGE("Posted Document No.", '');
            IF FINDSET THEN BEGIN
                xGUItoNAVPurchLine.COPYFILTERS(GUItoNAVPurchLine); //008
                REPEAT
                    SETRANGE("Document Type", "Document Type");
                    SETRANGE("Document No.", "Document No.");
                    FIND('+');
                    BufferPostLine.PostPurchDocGUIPurchLine(GUItoNAVPurchLine);
                    SETRANGE("Document Type");
                    SETRANGE("Document No.");
                    COPYFILTERS(xGUItoNAVPurchLine); //008
                UNTIL NEXT = 0;
            END;
        END;
        //003 End
    END;

    PROCEDURE PostPurchDocArch(VAR Rec: Record "GUI-to-BC Purchase Line Arch");
    VAR
        GUItoNAVPurchLineArch: Record "GUI-to-BC Purchase Line Arch";
    BEGIN
        //003 Start
        GUItoNAVPurchLineArch.COPY(Rec);
        PostGUIPurchDocArch(GUItoNAVPurchLineArch);
        Rec := GUItoNAVPurchLineArch;
        //003 End
    END;

    LOCAL PROCEDURE PostGUIPurchDocArch(VAR GUItoNAVPurchaseLineArch: Record "GUI-to-BC Purchase Line Arch");
    VAR
        GUItoNAVPurchLineArch: Record "GUI-to-BC Purchase Line Arch";
        xGUItoNAVPurchLineArch: Record "GUI-to-BC Purchase Line Arch";
    BEGIN
        //003 Start
        WITH GUItoNAVPurchLineArch DO BEGIN
            COPY(GUItoNAVPurchaseLineArch);
            SETCURRENTKEY("Document Type", "Document No.");
            SETRANGE("Posted Document No.", '');
            IF FINDSET THEN BEGIN
                xGUItoNAVPurchLineArch.COPYFILTERS(GUItoNAVPurchLineArch); //008
                REPEAT
                    SETRANGE("Document Type", "Document Type");
                    SETRANGE("Document No.", "Document No.");
                    FIND('+');
                    BufferPostLine.PostPurchDocGUIPurchLineArch(GUItoNAVPurchLineArch);
                    SETRANGE("Document Type");
                    SETRANGE("Document No.");
                    COPYFILTERS(xGUItoNAVPurchLineArch); //008
                UNTIL NEXT = 0;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE SynchronizeDocument(VAR GUIPurchaseLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        DoesNotExistText: TextConst ENU = '%1 %2 does not exist.';
    BEGIN
        //005 Start
        WITH GUIPurchaseLine DO BEGIN
            IF NOT FindTempPurchOrder(GUIPurchaseLine) THEN BEGIN
                IF PurchHeader.GET("Document Type", "Document No.") THEN BEGIN
                    InsertTempPurchOrder(PurchHeader);
                    EXIT(SynchronizeDocumentLine(PurchHeader));
                END ELSE BEGIN
                    //008 Start
                    UpdateErrorMsg(STRSUBSTNO(DoesNotExistText, "Document Type", "Document No."));
                    MODIFY;
                    EXIT(FALSE);
                END;
                //008 End
            END;
            EXIT(TRUE);
        END;
        //005 End
    END;

    LOCAL PROCEDURE SynchronizeDocumentLine(VAR PurchHdr: Record "Purchase Header"): Boolean;
    VAR
        PurchaseLine: Record "Purchase Line";
        GUIPurchLine: Record "GUI-to-BC Purchase Line";
        LineDoesNotExistText: TextConst ENU = 'Line with %1 %2 does not exist in %3 %4.';
        ReleasePurchaseDocument: Codeunit 415;
        UnitOfMeasureCode: Code[10];
        DiffersUnitOfMeasure: TextConst ENU = 'Check Unit of Measure in Entry No %1, it differs from other Entries for Line %2 in %3 %4.';
        WasReleased: Boolean;
    BEGIN
        //005 Start
        //006 Start
        BufferPostLine.PurchHeaderResetQtyToReceive(PurchHdr);
        //006 End

        WITH GUIPurchLine DO BEGIN
            //006 Start
            SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //008
                                                                                 //008 SETRANGE("Processing Status","Processing Status"::"In Progress");
                                                                                 //006 End
            SETRANGE("Document Type", PurchHdr."Document Type");
            SETRANGE("Document No.", PurchHdr."No.");
            SETRANGE("Ready for Processing", TRUE); //008
            IF FINDSET THEN
                REPEAT
                    PurchaseLine.SETRANGE("Document Type", "Document Type");
                    PurchaseLine.SETRANGE("Document No.", "Document No.");
                    PurchaseLine.SETRANGE(Type, Type);
                    PurchaseLine.SETRANGE("No.", "No.");
                    //010 Start
                    IF "Document Line No." <> 0 THEN
                        PurchaseLine.SETRANGE("Line No.", "Document Line No.");
                    //010 End
                    IF PurchaseLine.ISEMPTY THEN BEGIN
                        //008 Start
                        UpdateErrorMsg(STRSUBSTNO(LineDoesNotExistText, Type, "No.", "Document Type", "Document No."));
                        MODIFY;
                        EXIT(FALSE);
                        //008 End
                    END;
                UNTIL NEXT = 0;

            PurchaseLine.RESET;
            PurchaseLine.SETRANGE("Document Type", PurchHdr."Document Type");
            PurchaseLine.SETRANGE("Document No.", PurchHdr."No.");
            //007 Start
            PurchaseLine.SETRANGE(Type, PurchaseLine.Type::Item);
            PurchaseLine.SETFILTER("No.", '<>%1', '');
            //007 End
            IF PurchaseLine.FINDSET THEN BEGIN
                //006 Start
                IF PurchHdr.Status <> PurchHdr.Status::Open THEN BEGIN
                    //006 End
                    ReleasePurchaseDocument.Reopen(PurchHdr);
                    //006 Start
                    WasReleased := TRUE;
                END;
                //006 End
                REPEAT
                    PurchaseLine.SetPurchHeader(PurchHdr); //009
                    RESET;
                    //006 Start
                    SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //008
                                                                                         //008 SETRANGE("Processing Status","Processing Status"::"In Progress");
                                                                                         //006 End
                    SETRANGE("Document Type", PurchaseLine."Document Type");
                    SETRANGE("Document No.", PurchaseLine."Document No.");
                    SETRANGE("Ready for Processing", TRUE); //008
                    SETRANGE(Type, PurchaseLine.Type);
                    SETRANGE("No.", PurchaseLine."No.");
                    //010 Start
                    SETRANGE("Document Line No.", 0);
                    IF ISEMPTY THEN
                        SETRANGE("Document Line No.", PurchaseLine."Line No.");
                    //010 End
                    IF NOT ISEMPTY THEN BEGIN
                        //006 SETRANGE("Processing Status","Processing Status"::"In Progress");
                        CALCSUMS(Quantity);
                        IF PurchaseLine."Outstanding Quantity" <> Quantity THEN
                            PurchaseLine.VALIDATE(Quantity, Quantity + PurchaseLine."Quantity Received");

                        CLEAR(UnitOfMeasureCode);
                        IF FINDSET THEN
                            REPEAT
                                IF (UnitOfMeasureCode = '') THEN
                                    UnitOfMeasureCode := "Unit of Measure Code";
                                IF (UnitOfMeasureCode <> "Unit of Measure Code") THEN BEGIN
                                    //008 Start
                                    UpdateErrorMsg(STRSUBSTNO(DiffersUnitOfMeasure, "Entry No.", PurchaseLine."Line No.", "Document Type", "Document No."));
                                    MODIFY;
                                    EXIT(FALSE);
                                    //008 End
                                END;
                            UNTIL NEXT = 0;

                        IF (UnitOfMeasureCode <> '') AND
                           (UnitOfMeasureCode <> PurchaseLine."Unit of Measure Code")
                        THEN
                            PurchaseLine.VALIDATE("Unit of Measure Code", UnitOfMeasureCode);
                        PurchaseLine.MODIFY;
                    END ELSE
                        PurchaseLine.DELETE(TRUE);
                UNTIL PurchaseLine.NEXT = 0;

                //006 Start
                IF WasReleased THEN
                    ReleasePurchaseDocument.RUN(PurchHdr);
                //006 End
            END;

            EXIT(TRUE);
        END;
        //005 End
    END;

    LOCAL PROCEDURE FindTempPurchOrder(GUIPurchaseLine: Record "GUI-to-BC Purchase Line"): Boolean;
    BEGIN
        //005 Start
        WITH GUIPurchaseLine DO BEGIN
            IF "Document No." <> '' THEN BEGIN
                TempPurchHeader.SETRANGE("No.", "Document No.");
                EXIT(TempPurchHeader.FINDFIRST);
            END;
        END;
        //005 End
    END;

    LOCAL PROCEDURE InsertTempPurchOrder(NewPurchOrderHdr: Record 38);
    BEGIN
        //005 Start
        IF TempPurchHeader.GET(NewPurchOrderHdr."Document Type", NewPurchOrderHdr."No.") THEN
            EXIT;

        TempPurchHeader := NewPurchOrderHdr;
        TempPurchHeader.INSERT;
        //005 End
    END;

    LOCAL PROCEDURE CheckAndSyncDocument(VAR BufferLine: Record "GUI-to-BC Purchase Line"): Boolean;
    BEGIN
        //006 Start
        IF CheckDocumentNo(BufferLine) THEN
            EXIT(SynchronizeDocument(BufferLine));

        EXIT(FALSE);
        //006 End
    END;

    LOCAL PROCEDURE CheckAndSyncAndSetReadyDocuments(VAR BufferLine: Record "GUI-to-BC Purchase Line");
    VAR
        BufferLine2: Record "GUI-to-BC Purchase Line";
        PrevDocNo: Code[20];
        OK: Boolean;
        PurchLine: Record 39;
    BEGIN
        //008 Start
        WITH BufferLine2 DO BEGIN
            COPY(BufferLine);
            SETRANGE("Ready for Processing", TRUE);
            IF NOT ISEMPTY THEN BEGIN

                PurchHeader.LOCKTABLE; //009
                PurchLine.LOCKTABLE; //009

                OK := TRUE;
                SETRANGE("Ready for Processing");
                FIND('-');
                REPEAT
                    SETRANGE("Document Type", "Document Type");
                    SETRANGE("Document No.", "Document No.");
                    FIND('+');
                    // Check buffer lines and synchronize with sales lines //
                    OK := OK AND CheckAndSyncDocument(BufferLine2);
                    SETRANGE("Document Type");
                    SETRANGE("Document No.");
                UNTIL NEXT = 0;

                // Not ALL lines are ready for processing //
                IF NOT OK THEN BEGIN
                    PrevDocNo := '';
                    OK := TRUE;
                    FIND('-');
                    REPEAT
                        IF (PrevDocNo = '') OR
                           (PrevDocNo <> "Document No.")
                        THEN BEGIN
                            OK := CheckDocumentNo(BufferLine2);
                            PrevDocNo := "Document No.";
                        END;

                        IF NOT OK THEN BEGIN
                            // Set back to In Progress //
                            IF "Ready for Processing" THEN BEGIN
                                SetProcessingStatus("Processing Status"::"In Progress");
                                MODIFY;
                            END;
                            // Remove from temp source //
                            IF TempPurchHeader.GET("Document Type", "Document No.") THEN
                                TempPurchHeader.DELETE;
                            CounterFailed += 1;
                        END;
                    UNTIL NEXT = 0;
                END;

                CLEAR(PurchHeader);
            END;
        END;
        //008 End
    END;

    LOCAL PROCEDURE InitDetails();
    BEGIN
        //008 Start
        LastDocNo := '';
        //008 End
    END;

    LOCAL PROCEDURE ParametersMatch(PurchHeader: Record 38; BufferLine: Record "GUI-to-BC Purchase Line"): Boolean;
    BEGIN
        //008 Start
        EXIT(
          (BufferLine."Document No." = LastDocNo));
        //008 End
    END;

    LOCAL PROCEDURE CheckFinalizeSalesHeader(BufferLine: Record "GUI-to-BC Purchase Line"; VAR PurchHeader: Record 38) Result: Boolean;
    BEGIN
        //008 Start
        WITH BufferLine DO
            Result :=
              (LastDocNo <> "Document No.");
        //008 End
    END;

}