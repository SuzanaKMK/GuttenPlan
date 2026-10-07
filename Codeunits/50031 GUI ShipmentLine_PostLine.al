codeunit 50031 GUI_ShipmentLine_PostLine
{

    TableNo = "GUI-to-BC Sales Line";

    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    var
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        GlobalSalesLine: Record "GUI-to-BC Sales Line";
        GlobalSalesLineArch: Record "GUI-to-BC Sales Line Arch";
        TempGUItoNavSalesLineBuffer: Record "GUI-to-BC Sales Line" temporary;
        BufferLineCheckLine: Codeunit GUI_SalesCheckLine;
        Mgt: Codeunit GUItoBCManagement;
        IntegrMgt: Codeunit GUIToBCIntegrationMgt;
        ErrorMsgTxt: Text;
        FirstSalesOrderNo: Code[20];
        NextEntryNo: Integer;
        DoesNotExistText: TextConst ENU = '%1 %2 does not exist.';
        MustBeSpecifiedText: TextConst ENU = '%1 must be specified';
        MustNotBeText: TextConst ENU = '%1 must not %2.';
        MustBeText: TextConst ENU = '%1 %2 %3 must be %4.';
        NotFoundOnSalesDoc: TextConst ENU = '%1 %2 not found on %3 %4.';
        MultiLinesFoundOnSalesDoc: TextConst ENU = 'Multiple %1 %2 lines are found on %3 %4.';
        FailedToPost: TextConst ENU = 'Posting of %1 %2 failed.';
        ReservationEntry: Record "Reservation Entry";

    PROCEDURE RunWithCheck(VAR GUItoNAVSalesLineBuff2: Record "GUI-to-BC Sales Line");
    VAR
        GUItoNAVSalesLineBuff: Record "GUI-to-BC Sales Line";
    BEGIN
        GUItoNAVSalesLineBuff.COPY(GUItoNAVSalesLineBuff2);
        Code(GUItoNAVSalesLineBuff, TRUE);
        GUItoNAVSalesLineBuff2 := GUItoNAVSalesLineBuff;
    END;

    PROCEDURE RunWithoutCheck(VAR GUItoNAVSalesLineBuff2: Record 50003);
    VAR
        GUItoNAVSalesLineBuf: Record 50003;
    BEGIN
        GUItoNAVSalesLineBuf.COPY(GUItoNAVSalesLineBuff2);
        Code(GUItoNAVSalesLineBuf, FALSE);
        GUItoNAVSalesLineBuff2 := GUItoNAVSalesLineBuf;
    END;

    LOCAL PROCEDURE Code(VAR BufferLine: Record 50003; CheckLine: Boolean);
    VAR
        SalesLine: Record 37;
    BEGIN
        WITH BufferLine DO BEGIN
            IF EmptyLine THEN
                EXIT;

            //015 Start
            IF ("Processing Status" IN ["Processing Status"::New, "Processing Status"::Processed]) THEN
                EXIT;
            //015 End

            IF CheckLine THEN
                BufferLineCheckLine.RunCheck(BufferLine);

            IF NextEntryNo = 0 THEN
                StartPosting(BufferLine)
            ELSE
                ContinuePosting(BufferLine);

            IF "Ready for Processing" AND NOT "Validation Error" THEN
                PostBufferLine(BufferLine);

            FinishPosting;
        END;
    END;

    PROCEDURE StartPosting(VAR BUfferLine: Record 50003);
    BEGIN
        WITH BUfferLine DO BEGIN
            GlobalSalesLineArch.LOCKTABLE;
            IF GlobalSalesLineArch.FINDLAST THEN
                NextEntryNo := GlobalSalesLineArch."Entry No." + 1 //011
            ELSE
                NextEntryNo := 1;

            TempGUItoNavSalesLineBuffer.DELETEALL;
            TempSalesLine.DELETEALL;
        END;
    END;

    PROCEDURE ContinuePosting(VAR BufferLine: Record 50003);
    BEGIN
        WITH BufferLine DO BEGIN
            ;
        END;

        TempGUItoNavSalesLineBuffer.DELETEALL;
    END;

    PROCEDURE FinishPosting();
    BEGIN
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Sales Line") THEN
            EXIT;

        IF TempGUItoNavSalesLineBuffer.FINDSET THEN
            REPEAT
                //015 Start - Moved to function //
                IntegrMgt.ArchiveSingleSalesLine(TempGUItoNavSalesLineBuffer, NextEntryNo, FALSE);
            //015 End
            UNTIL TempGUItoNavSalesLineBuffer.NEXT = 0;
    END;

    LOCAL PROCEDURE PostBufferLine(VAR BufferLine: Record "GUI-to-BC Sales Line");
    VAR
        SalesLine: Record "Sales Line";
    BEGIN
        WITH BufferLine DO BEGIN
            SalesLine.LOCKTABLE;

            //015 UpdateSalesLine(SalesLine,BufferLine);
            IF UpdateSalesLine(SalesLine, BufferLine) THEN BEGIN
                OnMoveGUItoNAVSalesLine(SalesLine.RECORDID); // Change proc. status //

                TempGUItoNavSalesLineBuffer := BufferLine;
                TempGUItoNavSalesLineBuffer.INSERT;
            END ELSE
                ERROR(GETLASTERRORTEXT); //015
        END;
    END;

    LOCAL PROCEDURE UpdateSalesLine(VAR SalesLine: Record "Sales Line"; BufferLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        SalesHeader: Record "Sales Header";
        SalesDocRelease: Codeunit "Release Sales Document";
        HeaderExist: Boolean;
        WasReleased: Boolean;
    BEGIN
        WITH BufferLine DO BEGIN
            IF FindTempSalesOrder(BufferLine) THEN
                HeaderExist := SalesHeader.GET(TempSalesHeader."Document Type", TempSalesHeader."No.")
            ELSE BEGIN
                HeaderExist := SalesHeader.GET("Document Type", "Document No.");
                IF HeaderExist THEN BEGIN

                    SalesHeaderResetQtyToShip(SalesHeader);

                    InsertTempSalesOrder(SalesHeader);
                END;
            END;

            IF HeaderExist THEN BEGIN
                //004 Start
                //014 Start
                //IF SalesHeader."Posting Date" <> "Document Date" THEN BEGIN
                IF ((SalesHeader."Posting Date" <> "Document Date") OR
                    (SalesHeader."Shipment Date" <> "Document Date")) AND
                   ("Document Date" <> 0D)
                THEN BEGIN
                    //014 Start
                    IF SalesHeader.Status <> SalesHeader.Status::Open THEN BEGIN
                        SalesDocRelease.Reopen(SalesHeader);
                        WasReleased := TRUE;
                    END;
                    SalesHeader.SetHideValidationDialog(TRUE); //015
                    IF (SalesHeader."Posting Date" <> "Document Date") THEN //014
                        SalesHeader.VALIDATE("Posting Date", "Document Date");
                    //014 Start
                    IF (SalesHeader."Shipment Date" <> "Document Date") THEN
                        SalesHeader.VALIDATE("Shipment Date", "Document Date");
                    //014 End
                    SalesHeader.MODIFY;
                    IF WasReleased THEN
                        SalesDocRelease.RUN(SalesHeader);
                END;
                //004 End

                SalesLine.RESET;
                SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
                SalesLine.SETRANGE("Document No.", SalesHeader."No.");
                IF "Document Line No." <> 0 THEN
                    SalesLine.SETRANGE("Line No.", "Document Line No.")
                ELSE BEGIN
                    SalesLine.SETRANGE(Type, Type);
                    SalesLine.SETRANGE("No.", "No.");
                END;
                SalesLine.SETFILTER("Outstanding Quantity", '<>0');
                CASE SalesLine.COUNT OF
                    1:
                        BEGIN
                            SalesLine.FINDFIRST;
                            SalesLine.VALIDATE("Qty. to Ship", SalesLine."Qty. to Ship" + Quantity);
                            SalesLine.KMK_GUIDescription := "GUI Description"; //016
                            SalesLine."GUI Pallet" := "GUI Pallet";
                            SalesLine."GUI Time of Action" := "GUI Time of Action";
                            SalesLine."GUI Type" := "GUI Type";
                            SalesLine."GUI User ID" := "GUI User ID";
                            SalesLine."GUI-to-BC Entry No" := "Entry No.";



                            SalesLine.MODIFY;

                            /*  UpdateSalesLinetItemTracking(
                               SalesLine,
                               "Lot No.", "Serial No.", "Expiration Date", "Warranty Date", "Quantity (Base)"); */
                            CreateReservationEntry(SalesLine,
         "Lot No.", "Serial No.", "Expiration Date", "Warranty Date", BufferLine."Quantity (Base)");

                        END;
                    0:
                        ERROR(
                          NotFoundOnSalesDoc,
                          FORMAT(Type), "No.", FORMAT(SalesHeader."Document Type"), SalesHeader."No.");
                    ELSE
                        ERROR(
                          MultiLinesFoundOnSalesDoc,
                          FORMAT(Type), "No.", FORMAT(SalesHeader."Document Type"), SalesHeader."No.");
                END;
            END;

            EXIT(TRUE); //015
        END;
    END;

    LOCAL PROCEDURE UpdateSalesLinetItemTracking(VAR SalesLine: Record 37; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal);
    VAR
        Item: Record 27;
        ItemTrackingCode: Record 6502;
        TrackingSpecification: Record "Tracking Specification";
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

    BEGIN
        //004 ItemTrackingLines -> Codeunit 50011 "GUI-to-NAV Item Tracking Lines"
        WITH SalesLine DO BEGIN
            IF (LotNo = '') AND
               (SerialNo = '') AND
               (LineQty <> 0)
            THEN
                EXIT;

            TESTFIELD(Type, Type::Item);
            TESTFIELD("No.");
            TESTFIELD("Outstanding Quantity");

            Item.GET("No.");

            ItemTrackingCode.Code := Item."Item Tracking Code";
            /*   ItemTrackingMgt.GetItemTrackingSettings(
                ItemTrackingCode, 0, IsInbound,
                SNRequired, LotRequired, SNInfoRequired, LotInfoRequired); */

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
            //015 End

            TempTrackingSpecification.RESET;
            TempTrackingSpecification.DELETEALL;

            TrackingSpecification.INIT;
            TrackingSpecification.InitFromSalesLine(SalesLine);

            IF (("Document Type" = "Document Type"::Invoice) AND ("Shipment No." <> '')) OR
               (("Document Type" = "Document Type"::"Credit Memo") AND ("Return Receipt No." <> ''))
            THEN
                ItemTrackingLines.SetFormRunMode(2); // Combined shipment/receipt
            IF "Drop Shipment" THEN BEGIN
                ItemTrackingLines.SetFormRunMode(3); // Drop Shipment
                                                     //002 Start
                IF SalesLine."Purchase Order No." <> '' THEN
                    ItemTrackingLines.SetSecondSourceRowID(
                      ItemTrackingMgt.ComposeRowID(DATABASE::"Purchase Line", 1, "Purchase Order No.", '', 0, "Purch. Order Line No."));
                //002 End
            END;
            IF "Shipment Date" = 0D THEN
                ItemTrackingLines.SetSourceSpec(TrackingSpecification, WORKDATE)
            ELSE
                ItemTrackingLines.SetSourceSpec(TrackingSpecification, "Shipment Date");
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
                        //002 Start
                        ELSE BEGIN
                            //018 Start
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
                            //018 End
                        END;
                        //002 End
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
                //005 Start
                //IF ExpirationDate <> 0D THEN
                IF (ExpirationDate <> 0D) AND
                   (ExpirationDate <> TempTrackingSpecification."Expiration Date") AND
                   (TempTrackingSpecification."Buffer Status2" <> TempTrackingSpecification."Buffer Status2"::"ExpDate blocked")
                THEN
                    //005 End
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

    PROCEDURE GetNextEntryNo(): Integer;
    BEGIN
        EXIT(NextEntryNo);
    END;

    LOCAL PROCEDURE FindTempSalesOrder(GUISalesLine: Record 50003): Boolean;
    BEGIN
        WITH GUISalesLine DO BEGIN
            IF "Document No." <> '' THEN BEGIN
                TempSalesHeader.SETRANGE("No.", "Document No.");
                EXIT(TempSalesHeader.FINDFIRST);
            END;
        END;
    END;

    LOCAL PROCEDURE InsertTempSalesOrder(NewSalesOrderHdr: Record 36);
    BEGIN
        IF TempSalesHeader.GET(NewSalesOrderHdr."Document Type", NewSalesOrderHdr."No.") THEN
            EXIT;

        TempSalesHeader := NewSalesOrderHdr;
        TempSalesHeader.INSERT;
    END;

    PROCEDURE PostSalesDocGUISalesLine(VAR GUISalesLine: Record 50003);
    VAR
        SalesHeader: Record 36;
        SalesPost: Codeunit 80;
    BEGIN
        WITH GUISalesLine DO BEGIN
            IF NOT PostSalesHeader("Document Type", "Document No.") THEN BEGIN
                ErrorMsgTxt := GETLASTERRORTEXT;
                IF ErrorMsgTxt = '' THEN
                    ErrorMsgTxt := STRSUBSTNO(FailedToPost, FORMAT("Document Type"), "Document No.");

                MODIFYALL("Validation Error Message", COPYSTR(ErrorMsgTxt, 1, MAXSTRLEN("Validation Error Message")));
                MODIFYALL("Validation Error", TRUE);
            END;
        END;
    END;


    PROCEDURE PostSalesDocGUISalesLineArch(VAR GUISalesLineArch: Record "GUI-to-BC Sales Line Arch");
    BEGIN
        WITH GUISalesLineArch DO BEGIN
            IF NOT PostSalesHeader("Document Type", "Document No.") THEN BEGIN
                ErrorMsgTxt := GETLASTERRORTEXT;
                IF ErrorMsgTxt = '' THEN
                    ErrorMsgTxt := STRSUBSTNO(FailedToPost, FORMAT("Document Type"), "Document No.");
                IF GUIALLOWED THEN
                    ERROR(ErrorMsgTxt);
            END;
        END;
    END;


    LOCAL PROCEDURE PostSalesHeader(DocType: Integer; DocNo: Code[20]): Boolean;
    VAR
        SalesHeader: Record 36;
        SalesPost: Codeunit 80;
    BEGIN
        ErrorMsgTxt := '';
        CLEARLASTERROR;

        SalesHeader.GET(DocType, DocNo);
        Mgt.SetSalesDocPostingOptions(SalesHeader);
        SalesHeader."Print Posted Documents" := FALSE;

        // SalesPost.SetNoCommit(TRUE);
        SalesPost.RUN(SalesHeader);
        CLEAR(SalesPost);
        PrintBillOfLading(SalesHeader);  //008
        EXIT(TRUE);
    END;


    PROCEDURE SalesHeaderResetQtyToShip(SalesHeader: Record 36);
    VAR
        SalesLine: Record 37;
    BEGIN
        //006 Start
        WITH SalesHeader DO BEGIN
            SalesLine.RESET;
            SalesLine.SETRANGE("Document Type", "Document Type");
            SalesLine.SETRANGE("Document No.", "No.");
            SalesLine.SETFILTER("Outstanding Quantity", '<>0');
            IF SalesLine.FINDSET(TRUE) THEN
                REPEAT
                    SalesLineResetQtyToShip(SalesLine);
                UNTIL SalesLine.NEXT = 0;
        END;
        //006 End
    END;

    PROCEDURE SalesLineResetQtyToShip(VAR SalesLine: Record "Sales Line");
    BEGIN
        //006 Start
        WITH SalesLine DO BEGIN
            //007 Start
            CASE Type OF
                Type::Item:
                    BEGIN
                        //007 End
                        // Reset Qty. to Sales Shipment SO line //
                        IF "Qty. to Ship" <> 0 THEN BEGIN
                            // Reset Qty. to Handle on Item Tracking //
                            //>>  UpdateSalesLinetItemTracking(SalesLine, '', '', 0D, 0D, 0);
                            //12/21/25
                            CreateReservationEntry(SalesLine, '', '', 0D, 0D, 0);
                            VALIDATE("Qty. to Ship", 0);
                            //016 MODIFY;
                        END;
                        //016 Start
                        //017 "GUI Description" := '';
                        MODIFY;
                        //016 End
                        //007 Start
                    END;
            END;
            //007 End
        END;
        //006 End
    END;


    LOCAL PROCEDURE PrintBillOfLading(SalesHeader: Record 36);
    VAR
        DocumentSendingProfile: Record 60;
        BOLReportNo: Integer;
        BOLSalesHeader: Record 36;
        SRSetup: Record "Sales & Receivables Setup";
        ServerPath: Text;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        PrintNodeMgt: Codeunit "PrintNode Management";

    BEGIN

        IF SalesHeader.KMK_BOLPrinted THEN
            EXIT;

        IF NOT Mgt.IsBOLPrintingonShipmentPostEnabled THEN
            EXIT;

        BOLReportNo := Mgt.GetBOLReportID;
        IF BOLReportNo = 0 THEN
            EXIT;

        /* // Save BOL report

        SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesHeader.SETRANGE("No.", SalesHeader."No.");
        SRSetup.Reset();
        SRSetup.Get();
        if SRSetup.KMK_BOLReportFolder <> '' then begin
            //>> SaveReportAsPdfToFolder(SalesHeader);
            SaveBOLasPDF(SalesHeader);
        end; */


        //print BOL
        /* 
                SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type");
                SalesHeader.SETRANGE("No.", SalesHeader."No.");
                REPORT.RUNMODAL(BOLReportNo, FALSE, FALSE, SalesHeader);

                IF BOLSalesHeader.GET(SalesHeader."Document Type", SalesHeader."No.") THEN BEGIN   //013
                    BOLSalesHeader.KMK_BOLPrinted := TRUE;
                    BOLSalesHeader.MODIFY;
                END; */

        //send to PrintNode
        SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesHeader.SETRANGE("No.", SalesHeader."No.");
        if SalesHeader.FindFirst() then
            PrintNodeMgt.SendReportToPrintNode(50050, SalesHeader, 'BOL' + '-' + SalesHeader."No.");

    END;



    local procedure CreateReservationEntry(var SalesLine: Record "Sales Line"; LotNo: Code[20]; SerialNo: Code[20]; ExpirationDate: Date; WarrantyDate: Date; LineQty: Decimal)
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

        Item.Get(SalesLine."No.");

        if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
            LotRequired := ItemTrackingCode."Lot Specific Tracking";
            LotInfoRequired := ItemTrackingCode."Lot Info. Inbound Must Exist";
        end;
        IF NOT LotRequired OR LotInfoRequired THEN
            EXIT;

        // does reservation exist?


        ReservationEntry.Reset();
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"1");
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
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
            //zero out
            ReservationEntry."Quantity (Base)" := 0;
            ReservationEntry."Qty. to Handle (Base)" := 0;
            ReservationEntry."Qty. to Invoice (Base)" := 0;
            ReservationEntry."Qty. to Handle (Base)" := 0;
            ReservationEntry."Quantity Invoiced (Base)" := 0;


            ReservationEntry."Item No." := SalesLine."No.";

            // ReservationEntry.Description := SalesLine.Description;
            ReservationEntry."Location Code" := SalesLine."Location Code";
            ReservationEntry."Variant Code" := SalesLine."Variant Code";

            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
            ReservationEntry."Source Type" := Database::"Sales Line";

            ReservationEntry."Source Subtype" := ReservationEntry."Source Subtype"::"1";
            ReservationEntry."Source ID" := SalesLine."Document No.";
            ReservationEntry."Source Batch Name" := '';
            ReservationEntry."Source Ref. No." := SalesLine."Line No.";
            ReservationEntry."Shipment Date" := SalesLine."Shipment Date";

            ReservationEntry."Expiration Date" := ExpirationDate;

            ReservationEntry."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
            ReservationEntry.Validate("Quantity (Base)", (-1) * LineQty);

            ReservationEntry.VALIDATE("Lot No.", LotNo);
            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
            ReservationEntry."Created By" := UserId;

            ReservationEntry.Positive := false;

            ReservationEntry."Creation Date" := WorkDate();
            ReservationEntry.Insert();
        end;
    end;


    procedure SaveReportAsPdfToFolder(var SalesHeader: Record "Sales Header")
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        FullPath: Text;
        ServerFolder: Text;
        RecRef: RecordRef;
        SRSetup: Record "Sales & Receivables Setup";
    begin
        // 1. Define server folder on C: (BC service machine)
        // ServerFolder := 'C:\BCExports\BOL\';  // ensure this exists and is writable
        SRSetup.Reset();
        SRSetup.Get();
        if SRSetup.KMK_BOLReportFolder = '' then exit;

        ServerFolder := SRSetup.KMK_BOLReportFolder;
        // 2. Build filename
        FileName := StrSubstNo('BOL_%1_%2.pdf',
          SalesHeader."No.", Format(CurrentDateTime, 0, 9));

        FullPath := ServerFolder + FileName;



        // 3. Generate the PDF into a TempBlob
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);

        // RecRef for Sales Header
        RecRef.GetTable(SalesHeader);

        Report.SaveAs(
            SRSetup.KMK_BOLReportNo,     // correct report ID?
            '',                        // request page params if needed
            ReportFormat::Pdf,
            OutStr,
            RecRef);                   // passing RecRef is fine for on‑prem [web:32]



        // 4. Get the PDF stream back
        TempBlob.CreateInStream(InStr);

        // 5. Save stream to server file system path
        // in on-prem you can also use Upload/Download variants that allow direct paths
        FileMgt.DownloadFromStreamHandler(
         InStr,
         '',
         '',
         '',
         FullPath);
    end;


    procedure SaveBOLasPDF(var SalesHeader: Record "Sales Header")

    var
        ReportParameters: text;
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OStream: OutStream;
        SelectedExportType: Integer;

        RecRef: RecordRef;
    begin
        Clear(ReportParameters);
        Clear(OStream);
        Clear(SelectedExportType);


        ReportParameters := Report.RunRequestPage(50050);
        TempBlob.CreateOutStream(OStream);
        RecRef.gettable(SalesHeader);

        Report.SaveAs(50050, '', ReportFormat::Pdf, OStream, RecRef);
        FileManagement.BLOBExport(TempBlob, SalesHeader."No." + '-' + Format(CURRENTDATETIME, 0, '<Day,2><Month,2><Year4><Hours24><Minutes,2><Seconds,2>') + '.pdf', true);

    end;
}