codeunit 50032 GUIShipmentLine_PostBatch

{
    TableNo = "GUI-to-BC Sales Line";

    trigger OnRun()
    begin
        IF RunningResiliency THEN
            rec.LockTable();
        CarryOutBufferLineAction(Rec);

    end;

    var
        TempBufferLine: Record "GUI-to-BC Sales Line" temporary;
        TempFailedBufferLine: Record "GUI-to-BC Sales Line" temporary;
        TempSalesHeader: Record "Sales Header" temporary;
        SalesHeader: Record 36;
        BufferCheckLine: Codeunit 50030;
        BufferPostLine: Codeunit 50031;
        Mgt: Codeunit 50010;
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        CounterFailed: Integer;
        HideDialog: Boolean;
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';
        RunningResiliency: Boolean;

    PROCEDURE CarryOutBatchAction(VAR Rec: Record "GUI-to-BC Sales Line");
    VAR
        BufferLine: Record "GUI-to-BC Sales Line";
    BEGIN
        //006 Start
        BufferLine.COPY(Rec);
        Code(BufferLine);
        Rec := BufferLine;
        //006 End
    END;

    LOCAL PROCEDURE Code(VAR BufferLine: Record "GUI-to-BC Sales Line");
    BEGIN
        InitDetails; //006
        WITH BufferLine DO BEGIN
            SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //006                                                                     //006 SETRANGE("Processing Status","Processing Status"::"In Progress");
            SETFILTER("Processing Status", '>%1', "Processing Status"::New);
            SETRANGE(Processed, FALSE);
            //006 End

            IF NOT RunningResiliency THEN //006
                LOCKTABLE;

            ProcessLines(BufferLine);
        END;
    END;

    LOCAL PROCEDURE ProcessLines(VAR BufferLine: Record "GUI-to-BC Sales Line");
    VAR
        SkippedLine: Boolean;
    BEGIN
        WITH BufferLine DO BEGIN
            IF NOT FIND('=><') THEN BEGIN
                "Entry No." := 0;
                COMMIT;
                EXIT;
            END;

            // Check lines
            LineCount := 0;
            StartLineNo := "Entry No.";
            NoOfRecords := COUNT;
            BufferCheckLine.SetBatchMode(TRUE);
            REPEAT
                LineCount := LineCount + 1;
                CheckLine(BufferLine);
                //006 TempGUISalesLine := GUIShipLine2;
                //006 TempGUISalesLine.INSERT;
                IF NEXT = 0 THEN
                    FINDFIRST;
            UNTIL "Entry No." = StartLineNo;

            // Post lines
            LineCount := 0;
            //006 Start
            SkippedLine := FALSE;
            CounterFailed := 0;
            CLEAR(SalesHeader);

            CheckAndSyncAndSetReadyDocuments(BufferLine);
            COMMIT;
            //006 End

            SETRANGE("Ready for Processing", TRUE);
            //006 Start
            IF NOT ISEMPTY THEN BEGIN
                TempSalesHeader.RESET;
                IF TempSalesHeader.FINDSET THEN BEGIN
                    REPEAT
                        SETRANGE("Document Type", TempSalesHeader."Document Type");
                        SETRANGE("Document No.", TempSalesHeader."No.");
                        IF FINDSET(TRUE, FALSE) THEN BEGIN
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
                        END;
                        SETRANGE("Document No.");
                        SETRANGE("Document Type");
                    UNTIL TempSalesHeader.NEXT = 0;
                    TempSalesHeader.DELETEALL;
                END;
                //006 End

                UpdateAndDeleteLines(BufferLine);

                COMMIT;
            END; //006

            CLEAR(BufferCheckLine);
            CLEAR(BufferPostLine);
            //006 CLEARMARKS;
        END;

        IF SkippedLine THEN
            IF GUIALLOWED AND NOT HideDialog THEN
                MESSAGE(SkippedLineMsg);
    END;

    LOCAL PROCEDURE CheckLine(VAR BufferLine: Record "GUI-to-BC Sales Line");
    VAR
        BufferLineToUpdate: Record "GUI-to-BC Sales Line";
    BEGIN
        BufferLineToUpdate.COPY(BufferLine);
        BufferCheckLine.RunCheck(BufferLineToUpdate);
        //006 Start
        BufferLine.COPY(BufferLineToUpdate);
        BufferLine.MODIFY;
        //006 End
    END;

    LOCAL PROCEDURE CheckDocumentNo(VAR BufferLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        BufferLine2: Record "GUI-to-BC Sales Line";
    BEGIN
        //002 Start
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

    LOCAL PROCEDURE CarryOutBufferLineAction(VAR BufferLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        BufferLine2: Record "GUI-to-BC Sales Line";
    BEGIN
        WITH BufferLine DO BEGIN
            //006 Start
            IF FINDSET(TRUE) THEN BEGIN
                REPEAT
                    LineCount := LineCount + 1;

                    IF "Ready for Processing" AND NOT "Validation Error" THEN BEGIN
                        IF NOT ParametersMatch(SalesHeader, BufferLine) THEN BEGIN
                            SalesHeader.GET("Document Type", "Document No.");
                            LastDocNo := SalesHeader."No.";
                        END;
                        //006 End
                        BufferLine2.COPY(BufferLine);
                        BufferPostLine.RunWithoutCheck(BufferLine2);
                        //006 Start
                    END;
                UNTIL NEXT = 0;
                BufferLine := BufferLine2;

                IF (SalesHeader."No." <> '') THEN
                    FinalizeSalesHeader(SalesHeader, BufferLine);
            END;
            //006 End
        END;
        EXIT(TRUE);
    END;

    LOCAL PROCEDURE UpdateAndDeleteLines(VAR BufferLine: Record "GUI-to-BC Sales Line");
    VAR
        BufferLine2: Record "GUI-to-BC Sales Line";
        BufferLine3: Record "GUI-to-BC Sales Line";
    BEGIN
        BufferLine2.COPY(BufferLine);
        BufferLine2.SETFILTER("No.", '<>%1', '');
        IF BufferLine2.FINDLAST THEN; // Remember the last line

        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Sales Line") THEN
            EXIT;

        BufferLine3.COPY(BufferLine);
        //006 Start
        //BufferLine3.SETCURRENTKEY("Processing Status","Document Date","No.");
        //BufferLine3.SETRANGE("Processing Status",GUIShipLine3."Processing Status"::Processed);
        BufferLine3.SETRANGE("Ready for Processing");
        BufferLine3.SETRANGE(Processed, TRUE);
        //006 End
        IF NOT BufferLine3.ISEMPTY THEN
            BufferLine3.DELETEALL;
    END;

    PROCEDURE SetHideDialog(NewHideDialog: Boolean);
    BEGIN
        HideDialog := NewHideDialog;
    END;

    PROCEDURE SetRunningResiliency();
    BEGIN
        RunningResiliency := TRUE; //006
    END;

    PROCEDURE SetTryParam(TryLineCount: Integer; TryLastDocNo: Code[20]; TrySalesHeader: Record 36; VAR TryFailedBufferLine: Record "GUI-to-BC Sales Line");
    BEGIN
        //006 Start
        SetRunningResiliency;

        LineCount := TryLineCount;
        LastDocNo := TryLastDocNo;
        SalesHeader := TrySalesHeader;
        IF TryFailedBufferLine.FINDSET THEN
            REPEAT
                TempFailedBufferLine := TryFailedBufferLine;
                TempFailedBufferLine.INSERT;
            UNTIL TryFailedBufferLine.NEXT = 0;
        //006 End
    END;

    PROCEDURE GetTryParam(VAR TryLineCount: Integer; VAR TryLastDocNo: Code[20]; VAR TrySalesHeader: Record 36);
    BEGIN
        //006 Start
        TryLineCount := LineCount;
        TryLastDocNo := LastDocNo;
        TrySalesHeader := SalesHeader;
        //006 End
    END;

    PROCEDURE TryCarryOutBufferLineAction(VAR BufferLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        CarryOutAction: Codeunit 50032;
    BEGIN
        //006 Start
        CarryOutAction.SetTryParam(LineCount, LastDocNo, SalesHeader, TempFailedBufferLine);
        IF CarryOutAction.RUN(BufferLine) THEN BEGIN
            CarryOutAction.GetTryParam(LineCount, LastDocNo, SalesHeader);
            EXIT(TRUE);
        END;
        EXIT(FALSE);
        //006 End
    END;

    LOCAL PROCEDURE SetFailedBufferLine(NewFailedBufferLine: Record "GUI-to-BC Sales Line");
    BEGIN
        //006 Start
        TempFailedBufferLine := NewFailedBufferLine;
        TempFailedBufferLine.INSERT;
        //006 End
    END;

    PROCEDURE GetFailedCounter(): Integer;
    BEGIN
        //006 Start
        EXIT(CounterFailed);
        //006 End
    END;

    LOCAL PROCEDURE FinalizeSalesHeader(VAR SalesHdr: Record 36; VAR BufferLine: Record "GUI-to-BC Sales Line");
    VAR
        BufferLine2: Record "GUI-to-BC Sales Line";
    BEGIN
        //006 Start
        IF NOT RunningResiliency THEN
          ;

        IF Mgt.IsAutomaticSalesDocEnabled THEN BEGIN
            BufferLine2.COPY(BufferLine);
            BufferLine2.SETCURRENTKEY("Document Type", "Document No.", "Document Line No.");
            BufferLine2.SETRANGE("Document Type", SalesHdr."Document Type");
            BufferLine2.SETRANGE("Document No.", SalesHdr."No.");
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
                    BufferPostLine.PostSalesDocGUISalesLine(BufferLine2);
                END;
            END;
        END;
        //006 End
    END;

    PROCEDURE PostSalesDoc(VAR Rec: Record "GUI-to-BC Sales Line");
    VAR
        GUItoNAVSalesLine: Record "GUI-to-BC Sales Line";
    BEGIN
        GUItoNAVSalesLine.COPY(Rec);
        PostGUISalesDoc(GUItoNAVSalesLine);
        Rec := GUItoNAVSalesLine;
    END;

    LOCAL PROCEDURE PostGUISalesDoc(VAR GUItoNAVSalesOrderLine: Record "GUI-to-BC Sales Line");
    VAR
        GUItoNAVSalesLine: Record "GUI-to-BC Sales Line";
        xGUItoNAVSalesLine: Record "GUI-to-BC Sales Line";
    BEGIN
        WITH GUItoNAVSalesLine DO BEGIN
            COPY(GUItoNAVSalesOrderLine);
            SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //006
            SETRANGE(Processed, TRUE); //006
            SETRANGE("Posted Document No.", '');
            IF FINDSET THEN BEGIN
                xGUItoNAVSalesLine.COPYFILTERS(GUItoNAVSalesLine); //006
                REPEAT
                    SETRANGE("Document Type", "Document Type");
                    SETRANGE("Document No.", "Document No.");
                    FIND('+');
                    BufferPostLine.PostSalesDocGUISalesLine(GUItoNAVSalesLine);
                    SETRANGE("Document Type");
                    SETRANGE("Document No.");
                    COPYFILTERS(xGUItoNAVSalesLine); //006
                UNTIL NEXT = 0;
            END;
        END;
    END;

    PROCEDURE PostSalesDocArch(VAR Rec: Record "GUI-to-BC Sales Line Arch");
    VAR
        GUItoNAVSalesLineArch: Record "GUI-to-BC Sales Line Arch";
    BEGIN
        GUItoNAVSalesLineArch.COPY(Rec);
        PostGUISalesDocArch(GUItoNAVSalesLineArch);
        Rec := GUItoNAVSalesLineArch;
    END;

    LOCAL PROCEDURE PostGUISalesDocArch(VAR GUItoNAVSalesLineArch: Record "GUI-to-BC Sales Line Arch");
    VAR
        GUItoNAVSalesArch: Record "GUI-to-BC Sales Line Arch";
        xGUItoNAVSalesArch: Record "GUI-to-BC Sales Line Arch";
    BEGIN
        WITH GUItoNAVSalesArch DO BEGIN
            COPY(GUItoNAVSalesLineArch);
            SETCURRENTKEY("Document Type", "Document No.");
            SETRANGE("Posted Document No.", '');
            IF FINDSET THEN BEGIN
                xGUItoNAVSalesArch.COPYFILTERS(GUItoNAVSalesArch); //006
                REPEAT
                    SETRANGE("Document Type", "Document Type");
                    SETRANGE("Document No.", "Document No.");
                    FIND('+');
                    BufferPostLine.PostSalesDocGUISalesLineArch(GUItoNAVSalesArch);
                    SETRANGE("Document Type");
                    SETRANGE("Document No.");
                    COPYFILTERS(xGUItoNAVSalesArch); //006
                UNTIL NEXT = 0;
            END;
        END;
    END;

    LOCAL PROCEDURE SynchronizeDocument(VAR GUItoNAVSalesLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        DoesNotExistText: TextConst ENU = '%1 %2 does not exist.';
    BEGIN
        //003 Start
        WITH GUItoNAVSalesLine DO BEGIN
            IF NOT FindTempSalesOrder(GUItoNAVSalesLine) THEN BEGIN
                IF SalesHeader.GET("Document Type", "Document No.") THEN BEGIN
                    InsertTempSalesOrder(SalesHeader);
                    EXIT(SynchronizeDocumentLine(SalesHeader));
                END ELSE BEGIN
                    //006 Start
                    UpdateErrorMsg(STRSUBSTNO(DoesNotExistText, "Document Type", "Document No."));
                    MODIFY;
                    EXIT(FALSE);
                END;
                //006 End
            END;
            EXIT(TRUE);
        END;
        //003 End
    END;

    LOCAL PROCEDURE SynchronizeDocumentLine(VAR SalesHdr: Record 36): Boolean;
    VAR
        SalesLine: Record 37;
        GUISalesLine: Record "GUI-to-BC Sales Line";
        LineDoesNotExistText: TextConst ENU = 'Line with %1 %2 does not exist in %3 %4.';
        ReleaseSalesDoc: Codeunit 414;
        UnitOfMeasureCode: Code[10];
        DiffersUnitOfMeasure: TextConst ENU = 'Check Unit of Measure in Entry No %1, it differs from other Entries for Line %2 in %3 %4.';
        WasReleased: Boolean;
    BEGIN
        //003 Start
        //004 Start
        BufferPostLine.SalesHeaderResetQtyToShip(SalesHdr);
        //004 End

        WITH GUISalesLine DO BEGIN
            //004 Start
            RESET;
            SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //006
                                                                                 //006 SETRANGE("Processing Status","Processing Status"::"In Progress");
                                                                                 //004 End
            SETRANGE("Document Type", SalesHdr."Document Type");
            SETRANGE("Document No.", SalesHdr."No.");
            SETRANGE("Ready for Processing", TRUE); //006
            IF FINDSET THEN
                REPEAT
                    SalesLine.SETRANGE("Document Type", "Document Type");
                    SalesLine.SETRANGE("Document No.", "Document No.");
                    SalesLine.SETRANGE(Type, Type);
                    SalesLine.SETRANGE("No.", "No.");
                    //008 Start
                    IF "Document Line No." <> 0 THEN
                        SalesLine.SETRANGE("Line No.", "Document Line No.");
                    //008 End
                    IF SalesLine.ISEMPTY THEN BEGIN
                        //006 Start
                        UpdateErrorMsg(STRSUBSTNO(LineDoesNotExistText, Type, "No.", "Document Type", "Document No."));
                        MODIFY;
                        EXIT(FALSE);
                        //006 End
                    END;
                UNTIL NEXT = 0;

            SalesLine.RESET;
            SalesLine.SETRANGE("Document Type", SalesHdr."Document Type");
            SalesLine.SETRANGE("Document No.", SalesHdr."No.");
            //005 Start
            SalesLine.SETRANGE(Type, SalesLine.Type::Item);
            SalesLine.SETFILTER("No.", '<>%1', '');
            //005 End
            IF SalesLine.FINDSET THEN BEGIN
                //004 Start
                IF SalesHdr.Status <> SalesHdr.Status::Open THEN BEGIN
                    //004 End
                    ReleaseSalesDoc.Reopen(SalesHdr);
                    //004 Start
                    WasReleased := TRUE;
                END;
                //004 End
                REPEAT
                    SalesLine.SetSalesHeader(SalesHdr); //007
                    RESET;
                    //004 Start
                    SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //006
                                                                                         //006 SETRANGE("Processing Status","Processing Status"::"In Progress");
                                                                                         //004 End
                    SETRANGE("Document Type", SalesLine."Document Type");
                    SETRANGE("Document No.", SalesLine."Document No.");
                    SETRANGE("Ready for Processing", TRUE); //006
                    SETRANGE(Type, SalesLine.Type);
                    SETRANGE("No.", SalesLine."No.");
                    //008 Start
                    SETRANGE("Document Line No.", 0);
                    IF ISEMPTY THEN
                        SETRANGE("Document Line No.", SalesLine."Line No.");
                    //008 End
                    IF NOT ISEMPTY THEN BEGIN
                        //004 SETRANGE("Processing Status","Processing Status"::"In Progress");
                        CALCSUMS(Quantity);
                        IF SalesLine."Outstanding Quantity" <> Quantity THEN
                            SalesLine.VALIDATE(Quantity, Quantity + SalesLine."Quantity Shipped");

                        CLEAR(UnitOfMeasureCode);
                        IF FINDSET THEN
                            REPEAT
                                IF (UnitOfMeasureCode = '') THEN
                                    UnitOfMeasureCode := "Unit of Measure Code";
                                IF (UnitOfMeasureCode <> "Unit of Measure Code") THEN BEGIN
                                    //006 Start
                                    UpdateErrorMsg(STRSUBSTNO(DiffersUnitOfMeasure, "Entry No.", SalesLine."Line No.", "Document Type", "Document No."));
                                    MODIFY;
                                    EXIT(FALSE);
                                    //006 End
                                END;
                            UNTIL NEXT = 0;

                        IF (UnitOfMeasureCode <> '') AND
                           (UnitOfMeasureCode <> SalesLine."Unit of Measure Code")
                        THEN
                            SalesLine.VALIDATE("Unit of Measure Code", UnitOfMeasureCode);
                        SalesLine.MODIFY;
                    END ELSE
                        SalesLine.DELETE(TRUE);
                UNTIL SalesLine.NEXT = 0;

                //004 Start
                IF WasReleased THEN
                    ReleaseSalesDoc.RUN(SalesHdr);
                //004 End
            END;

            EXIT(TRUE);
        END;
        //003 End
    END;

    LOCAL PROCEDURE FindTempSalesOrder(GUISalesLine: Record "GUI-to-BC Sales Line"): Boolean;
    BEGIN
        //003 Start
        WITH GUISalesLine DO BEGIN
            IF "Document No." <> '' THEN BEGIN
                TempSalesHeader.SETRANGE("No.", "Document No.");
                EXIT(TempSalesHeader.FINDFIRST);
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE InsertTempSalesOrder(NewSalesOrderHdr: Record 36);
    BEGIN
        //003 Start
        IF TempSalesHeader.GET(NewSalesOrderHdr."Document Type", NewSalesOrderHdr."No.") THEN
            EXIT;

        TempSalesHeader := NewSalesOrderHdr;
        TempSalesHeader.INSERT;
        //003 End
    END;

    LOCAL PROCEDURE CheckAndSyncDocument(VAR BufferLine: Record "GUI-to-BC Sales Line"): Boolean;
    BEGIN
        //004 Start
        IF CheckDocumentNo(BufferLine) THEN
            EXIT(SynchronizeDocument(BufferLine));

        EXIT(FALSE);
        //004 End
    END;

    LOCAL PROCEDURE CheckAndSyncAndSetReadyDocuments(VAR BufferLine: Record "GUI-to-BC Sales Line");
    VAR
        BufferLine2: Record "GUI-to-BC Sales Line";
        PrevDocNo: Code[20];
        OK: Boolean;
        SalesLine: Record 37;
    BEGIN
        //006 Start
        WITH BufferLine2 DO BEGIN
            COPY(BufferLine);
            SETRANGE("Ready for Processing", TRUE);
            IF NOT ISEMPTY THEN BEGIN

                SalesHeader.LOCKTABLE; //007
                SalesLine.LOCKTABLE; //007

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
                            IF TempSalesHeader.GET("Document Type", "Document No.") THEN
                                TempSalesHeader.DELETE;
                            CounterFailed += 1;
                        END;
                    UNTIL NEXT = 0;
                END;

                CLEAR(SalesHeader);
            END;
        END;
        //006 End
    END;

    LOCAL PROCEDURE InitDetails();
    BEGIN

        LastDocNo := '';

    END;

    LOCAL PROCEDURE ParametersMatch(SalesHeader: Record 36; BufferLine: Record "GUI-to-BC Sales Line"): Boolean;
    BEGIN
        //006 Start
        EXIT(
          (BufferLine."Document No." = LastDocNo));
        //006 End
    END;

    LOCAL PROCEDURE CheckFinalizeSalesHeader(BufferLine: Record "GUI-to-BC Sales Line"; VAR SalesHeader: Record 36) Result: Boolean;
    BEGIN
        //006 Start
        WITH BufferLine DO
            Result :=
              (LastDocNo <> "Document No.");
        //006 End
    END;

}