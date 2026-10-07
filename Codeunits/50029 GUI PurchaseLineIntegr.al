codeunit 50029 GUIPurchaseLineIntegr
{
    trigger OnRun()
    begin

    end;

    var
        Mgt: Codeunit GUItoBCManagement;
        ItemLotNoFormatText: TextConst ENU = '%1 %2 formatting is wrong.';




    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Purchase Line", 'OnPreProcess', '', false, false)]
    LOCAL PROCEDURE GUIToNAVPurchLineOnPreProcess(VAR Sender: Record "GUI-to-BC Purchase Line");
    BEGIN
        //002 Start
        PreProcess(Sender);
        //002 End
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Purchase Line", 'OnAfterValidateEvent', 'Quantity', false, false)]
    LOCAL PROCEDURE GUIToBCPurchLineOnAfterValidateQuantity(VAR Rec: Record "GUI-to-BC Purchase Line"; VAR xRec: Record "GUI-to-BC Purchase Line"; CurrFieldNo: Integer);
    BEGIN
        //002 Start
        WITH Rec DO BEGIN
            "Quantity (Base)" := CalcBaseQty1(Rec, Quantity);
        END;
        //002 End
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Purchase Line", 'OnMoveGUItoBCPurchaseLine', '', false, false)]
    LOCAL PROCEDURE MoveGUItoBCPurchaseLine(VAR Sender: Record "GUI-to-BC Purchase Line"; ToRecordID: RecordID);

    VAR
        PurchLine: Record "Purchase Line";
        RecRef: RecordRef;
    BEGIN
        IF ToRecordID.TABLENO <> DATABASE::"Purchase Line" THEN
            EXIT;

        RecRef := ToRecordID.GETRECORD;
        IF RecRef.ISTEMPORARY THEN
            EXIT;

        RecRef.SETTABLE(PurchLine);

        PurchLine.GET(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");

        IF Sender."Ready for Processing" AND
          NOT Sender."Validation Error"
        THEN BEGIN
            //004 Sender."Processing Status" := Sender."Processing Status"::Processed;
            Sender.SetProcessingStatus(Sender."Processing Status"::Processed); //004
                                                                               //002 - Not yet available at this step //
                                                                               //002 Sender."Posted Document Type" := ;
                                                                               //002 Sender."Posted Document No." := ;
                                                                               // Re-read Sender to be sure the record still exists
                                                                               //>> if Sender.Get(Sender."Entry No.") then
                                                                               //>>     Sender.Modify(true)
                                                                               //>>  else
                                                                               //>>     Error('GUI-to-BC Purchase Line %1 no longer exists.', Sender."Entry No.");
            Sender.MODIFY;
        END;
    END;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterBCPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    BEGIN

        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Purchase Line") THEN
            PostPurchUpdateFromGUIPurchLine(PurchaseHeader, PurchRcpHdrNo, RetShptHdrNo, PurchInvHdrNo, PurchCrMemoHdrNo)
        ELSE
            PostPurchUpdateFromGUIPurchLineArch(PurchaseHeader, PurchRcpHdrNo, RetShptHdrNo, PurchInvHdrNo, PurchCrMemoHdrNo);

    END;


    LOCAL PROCEDURE PostPurchUpdateFromGUIPurchLine(VAR PurchaseHeader: Record 38; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]);
    VAR
        GUIPurchLine: Record "GUI-to-BC Purchase Line";
    BEGIN
        //003 Start
        WITH GUIPurchLine DO BEGIN
            RESET;
            SETCURRENTKEY("Document Type", "Document No.", "Document Line No."); //004
            SETRANGE("Document Type", PurchaseHeader."Document Type");
            SETRANGE("Document No.", PurchaseHeader."No.");
            SETRANGE(Processed, TRUE); //004
            SETRANGE("Posted Document No.", '');
            IF NOT ISEMPTY THEN BEGIN
                SETRANGE("Posted Document No.");
                FINDSET(TRUE);
                REPEAT
                    IF "Posted Document No." = '' THEN BEGIN
                        UpdatePostedDoc(
                          PurchaseHeader, PurchRcpHdrNo, RetShptHdrNo, PurchInvHdrNo, PurchCrMemoHdrNo,
                          "Posted Document Type", "Posted Document No.");
                        MODIFY;
                    END;
                UNTIL NEXT = 0;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE PostPurchUpdateFromGUIPurchLineArch(VAR PurchaseHeader: Record 38; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]);
    VAR
        GUIPurchLineArch: Record "GUI-to-BC Purchase Line Arch";
    BEGIN
        //003 Start
        WITH GUIPurchLineArch DO BEGIN
            RESET;
            SETCURRENTKEY("Document Type", "Document No.");
            SETRANGE("Document Type", PurchaseHeader."Document Type");
            SETRANGE("Document No.", PurchaseHeader."No.");
            SETRANGE("Posted Document No.", '');
            IF NOT ISEMPTY THEN BEGIN
                SETRANGE("Posted Document No.");
                FINDSET(TRUE);
                REPEAT
                    IF "Posted Document No." = '' THEN BEGIN
                        UpdatePostedDoc(
                          PurchaseHeader, PurchRcpHdrNo, RetShptHdrNo, PurchInvHdrNo, PurchCrMemoHdrNo,
                          "Posted Document Type", "Posted Document No.");
                        MODIFY;
                    END;
                UNTIL NEXT = 0;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE UpdatePostedDoc(PurchaseHeader: Record 38; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; VAR PostedDocType: Option " ","Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo"; VAR PostedDocNo: Code[20]);
    BEGIN
        //003 Start
        WITH PurchaseHeader DO BEGIN
            IF "Document Type" IN ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] THEN BEGIN
                IF RetShptHdrNo <> '' THEN BEGIN
                    PostedDocType := PostedDocType::"Purchase Return Shipment";
                    PostedDocNo := RetShptHdrNo;
                END ELSE BEGIN
                    PostedDocType := PostedDocType::"Purchase Credit Memo";
                    PostedDocNo := PurchCrMemoHdrNo;
                END;
            END ELSE BEGIN
                IF PurchRcpHdrNo <> '' THEN BEGIN
                    PostedDocType := PostedDocType::"Purchase Receipt";
                    PostedDocNo := PurchRcpHdrNo;
                END ELSE BEGIN
                    PostedDocType := PostedDocType::"Purchase Invoice";
                    PostedDocNo := PurchInvHdrNo;
                END;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE SplitItemLotNos(VAR Rec: Record "GUI-to-BC Purchase Line");
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

    LOCAL PROCEDURE PreProcess(VAR Rec: Record "GUI-to-BC Purchase Line");
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

    LOCAL PROCEDURE CalcBaseQty1(VAR Rec: Record "GUI-to-BC Purchase Line"; Qty: Decimal): Decimal;
    BEGIN
        //002 Start
        WITH Rec DO BEGIN
            TESTFIELD("Qty. per Unit of Measure");
            EXIT(ROUND(Qty * "Qty. per Unit of Measure", 0.00001));
        END;
        //002 End
    END;

    LOCAL PROCEDURE ResetPurchHeaderGUIDescription(PurchHeader: Record 38);
    VAR
        PurchLine: Record 39;
    BEGIN
        //005 Start
        WITH PurchHeader DO BEGIN
            PurchLine.RESET;
            PurchLine.SETRANGE("Document Type", "Document Type");
            PurchLine.SETRANGE("Document No.", "No.");
            IF NOT PurchLine.ISEMPTY THEN BEGIN
                if PurchLine.FINDSET(TRUE) then
                    repeat
                        PurchLine.KMK_GUIDescription := '';
                        PurchLine.Modify();
                    until PurchLine.Next() = 0;
            END;
        END;
        //005 End
    END;






}