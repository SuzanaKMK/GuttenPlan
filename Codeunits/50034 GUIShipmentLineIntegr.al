codeunit 50034 GUIShipmentLineIntegr
{
    trigger OnRun()
    begin

    end;

    var
        Mgt: Codeunit GUItoBCManagement;
        ItemLotNoFormatText: TextConst ENU = '%1 %2 formatting is wrong.';


    LOCAL PROCEDURE PostSalesUpdateFromGUISalesLine(VAR SalesHeader: Record 36; SalesShptHdrNo: Code[20]; RetOrdHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]);
    VAR
        GUISalesLine: Record "GUI-to-BC Sales Line";
    BEGIN
        //003 Start
        WITH GUISalesLine DO BEGIN
            RESET;
            SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //003
            SETRANGE("Document Type", SalesHeader."Document Type");
            SETRANGE("Document No.", SalesHeader."No.");
            SETRANGE(Processed, TRUE); //003
            SETRANGE("Posted Document No.", '');
            IF NOT ISEMPTY THEN BEGIN
                SETRANGE("Posted Document No.");
                FINDSET(TRUE);
                REPEAT
                    IF "Posted Document No." = '' THEN BEGIN
                        UpdatePostedDoc(
                          SalesHeader, SalesShptHdrNo, RetOrdHdrNo, SalesInvHdrNo, SalesCrMemoHdrNo,
                          "Posted Document Type", "Posted Document No.");
                        MODIFY;
                    END;
                UNTIL NEXT = 0;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE PostSalesUpdateFromGUISalesLineArch(VAR SalesHeader: Record 36; SalesShptHdrNo: Code[20]; RetOrdHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]);
    VAR
        GUISalesLineArch: Record "GUI-to-BC Sales Line Arch";
    BEGIN
        //003 Start
        WITH GUISalesLineArch DO BEGIN
            RESET;
            SETCURRENTKEY("Document Type", "Document No.");
            SETRANGE("Document Type", SalesHeader."Document Type");
            SETRANGE("Document No.", SalesHeader."No.");
            SETRANGE("Posted Document No.", '');
            IF NOT ISEMPTY THEN BEGIN
                SETRANGE("Posted Document No.");
                FINDSET(TRUE);
                REPEAT
                    IF "Posted Document No." = '' THEN BEGIN
                        UpdatePostedDoc(
                          SalesHeader, SalesShptHdrNo, RetOrdHdrNo, SalesInvHdrNo, SalesCrMemoHdrNo,
                          "Posted Document Type", "Posted Document No.");
                        MODIFY;
                    END;
                UNTIL NEXT = 0;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE UpdatePostedDoc(VAR SalesHeader: Record 36; SalesShptHdrNo: Code[20]; RetOrdHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; VAR PostedDocType: Option " ","Sales Shipment","Sales Invoice","Sales Return Shipment","Sales Credit Memo"; VAR PostedDocNo: Code[20]);
    BEGIN
        //003 Start
        WITH SalesHeader DO BEGIN
            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                IF RetOrdHdrNo <> '' THEN BEGIN
                    PostedDocType := PostedDocType::"Sales Return Shipment";
                    PostedDocNo := RetOrdHdrNo;
                END ELSE BEGIN
                    PostedDocType := PostedDocType::"Sales Credit Memo";
                    PostedDocNo := SalesCrMemoHdrNo;
                END;
            END ELSE BEGIN
                IF SalesShptHdrNo <> '' THEN BEGIN
                    PostedDocType := PostedDocType::"Sales Shipment";
                    PostedDocNo := SalesShptHdrNo;
                END ELSE BEGIN
                    PostedDocType := PostedDocType::"Sales Invoice";
                    PostedDocNo := SalesInvHdrNo;
                END;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE SplitItemLotNos(VAR Rec: Record "GUI-to-BC Sales Line");
    VAR
        pos: Integer;
    BEGIN
        //002 Start
        WITH Rec DO BEGIN
            IF "No." <> '' THEN
                EXIT;

            TESTFIELD("Item-Lot No.");
            pos := STRPOS("Item-Lot No.", '-');
            IF pos = 0 THEN
                ERROR(ItemLotNoFormatText, FIELDCAPTION("Item-Lot No."), "Item-Lot No.");

            Type := Type::Item;
            "No." := COPYSTR("Item-Lot No.", 1, pos - 1);
            "Lot No." := COPYSTR("Item-Lot No.", pos + 1);
        END;
        //002 End
    END;

    LOCAL PROCEDURE PreProcess(VAR Rec: Record "GUI-to-BC Sales Line");
    BEGIN
        //002 Start
        WITH Rec DO BEGIN
            TESTFIELD("Processing Status", "Processing Status"::"In Progress");
            TESTFIELD("Document No.");
            TESTFIELD(Quantity);

            SplitItemLotNos(Rec);
        END;
        //002 End
    END;

    LOCAL PROCEDURE CalcBaseQty(VAR Rec: Record "GUI-to-BC Sales Line"; Qty: Decimal): Decimal;
    BEGIN
        //002 Start
        WITH Rec DO BEGIN
            TESTFIELD("Qty. per Unit of Measure");
            EXIT(ROUND(Qty * "Qty. per Unit of Measure", 0.00001));
        END;
        //002 End
    END;

    LOCAL PROCEDURE ResetSalesHeaderGUIDescription(SalesHeader: Record "Sales Header");
    VAR
        SalesLine: Record "Sales Line";
    BEGIN
        //004 Start
        WITH SalesHeader DO BEGIN
            SalesLine.RESET;
            SalesLine.SETRANGE("Document Type", "Document Type");
            SalesLine.SETRANGE("Document No.", "No.");
            IF NOT SalesLine.ISEMPTY THEN BEGIN
                if SalesLine.FINDSET then
                    repeat

                        SalesLine.KMK_GUIDescription := '';
                        SalesLine.Modify();
                    until SalesLine.Next() = 0;
            END;
        END;
        //004 End
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Sales Line", 'OnPreProcess', '', false, false)]

    LOCAL PROCEDURE GUIToNAVSalesLineOnPreProcess(VAR Sender: Record "GUI-to-BC Sales Line");
    BEGIN
        //002 Start
        PreProcess(Sender);
        //002 End
    END;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure PostSalesOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean; PreviewMode: Boolean)
    var
    BEGIN

        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Sales Line") THEN
            PostSalesUpdateFromGUISalesLine(SalesHeader, SalesShptHdrNo, RetRcpHdrNo, SalesInvHdrNo, SalesCrMemoHdrNo)
        ELSE
            PostSalesUpdateFromGUISalesLineArch(SalesHeader, SalesShptHdrNo, RetRcpHdrNo, SalesInvHdrNo, SalesCrMemoHdrNo);

    END;

    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Sales Line", 'OnAfterValidateEvent', 'Quantity', false, false)]

    LOCAL PROCEDURE GUIToNAVSalesLineOnAfterValidateQuantity(VAR Rec: Record "GUI-to-BC Sales Line"; VAR xRec: Record "GUI-to-BC Sales Line"; CurrFieldNo: Integer);
    begin

        Rec."Quantity (Base)" := CalcBaseQty(Rec, Rec.Quantity);
    end;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Sales Line", 'OnMoveGUItoNAVSalesLine', '', false, false)]

    LOCAL PROCEDURE OnMoveGUItoBCSalesLine(VAR Sender: Record "GUI-to-BC Sales Line"; ToRecordID: RecordID);
    VAR
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    BEGIN
        IF ToRecordID.TABLENO <> DATABASE::"Sales Line" THEN
            EXIT;

        RecRef := ToRecordID.GETRECORD;
        IF RecRef.ISTEMPORARY THEN
            EXIT;

        RecRef.SETTABLE(SalesLine);

        SalesLine.GET(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        IF Sender."Ready for Processing" AND
          NOT Sender."Validation Error"
        THEN BEGIN

            Sender.SetProcessingStatus(Sender."Processing Status"::Processed); //003

            Sender.MODIFY;
        END;
    END;

}