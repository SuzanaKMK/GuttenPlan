codeunit 50009 GUIInvAdjmtIntegr
{
    trigger OnRun()
    begin

    end;

    var
        Mgt: Codeunit GUItoBCManagement;
        ItemLotNoFormatText: TextConst ENU = '%1 %2 formatting is wrong.';
        InvtSetup: Record "Inventory Setup";
        ManufSetup: Record "Manufacturing Setup";
        InvtSetupRead: Boolean;
        ManufSetupRead: Boolean;
        DuplicateDetectedText: TextConst ENU = 'Duplicate detected %1 (%2).';

    /* PROCEDURE CalcBaseQty(VAR Rec: Record 50001; Qty: Decimal): Decimal;
    BEGIN
        //002 Start
        WITH Rec DO BEGIN
            TESTFIELD("Qty. per Unit of Measure");
            EXIT(ROUND(Qty * "Qty. per Unit of Measure", 0.00001));
        END;
        //002 End
    END; */

    LOCAL PROCEDURE PostItemJnl(VAR ItemJournalLine: Record 83);
    VAR
        ItemJnlTemplate: Record 82;
    BEGIN
        //005 Start
        WITH ItemJournalLine DO BEGIN
            IF "Line No." = 0 THEN
                EXIT;

            //006 Start
            IF NOT ItemJnlTemplate.GET("Journal Template Name") THEN
                EXIT;

            IF NOT (ItemJnlTemplate.Type IN [ItemJnlTemplate.Type::Item, ItemJnlTemplate.Type::Transfer]) THEN
                EXIT;
            //006 End

            IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Invt. Adjmt. Line") THEN
                PostItemJnlLineUpdateInvtAdjmt(ItemJournalLine)
            ELSE
                PostItemJnlLineUpdateInvtAdjmtArch(ItemJournalLine);
        END;
        //005 End
    END;

    LOCAL PROCEDURE PostItemJnlLineUpdateInvtAdjmt(VAR ItemJournalLine: Record 83);
    VAR
        InvtAdjmtLine: Record 50001;
    BEGIN
        //005 Start
        WITH ItemJournalLine DO BEGIN
            InvtAdjmtLine.RESET;
            InvtAdjmtLine.SETCURRENTKEY("Journal Template Name", "Journal Batch Name"); //007
            InvtAdjmtLine.SETRANGE("Journal Template Name", "Journal Template Name");
            InvtAdjmtLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            InvtAdjmtLine.SETRANGE("Journal Line No.", "Line No.");
            InvtAdjmtLine.SETRANGE("Journal Document No.", "Document No.");
            //007 Start
            InvtAdjmtLine.SETRANGE(Processed, TRUE);
            IF "External Document No." <> '' THEN
                InvtAdjmtLine.SETRANGE("Document No.", "External Document No.");
            InvtAdjmtLine.SETRANGE("Document Date", "Document Date");
            //007 End
            IF NOT InvtAdjmtLine.ISEMPTY THEN BEGIN
                InvtAdjmtLine.FINDFIRST;
                InvtAdjmtLine."Journal Posted" := TRUE;
                InvtAdjmtLine.MODIFY;
            END;
        END;
        //005 End
    END;

    LOCAL PROCEDURE PostItemJnlLineUpdateInvtAdjmtArch(VAR ItemJournalLine: Record 83);
    VAR
        InvtAdjmtLineArch: Record 50011;
    BEGIN
        //005 Start
        WITH ItemJournalLine DO BEGIN
            InvtAdjmtLineArch.RESET;
            InvtAdjmtLineArch.SETCURRENTKEY("Journal Template Name", "Journal Batch Name");
            InvtAdjmtLineArch.SETRANGE("Journal Template Name", "Journal Template Name");
            InvtAdjmtLineArch.SETRANGE("Journal Batch Name", "Journal Batch Name");
            InvtAdjmtLineArch.SETRANGE("Journal Line No.", "Line No.");
            InvtAdjmtLineArch.SETRANGE("Journal Document No.", "Document No.");
            //007 Start
            IF "External Document No." <> '' THEN
                InvtAdjmtLineArch.SETRANGE("Document No.", "External Document No.");
            InvtAdjmtLineArch.SETRANGE("Document Date", "Document Date");
            //007 End
            IF NOT InvtAdjmtLineArch.ISEMPTY THEN BEGIN
                InvtAdjmtLineArch.FINDFIRST;
                InvtAdjmtLineArch."Journal Posted" := TRUE;
                InvtAdjmtLineArch.MODIFY;
            END;
        END;
        //005 End
    END;

    LOCAL PROCEDURE OpenItemReclassJnl(VAR Rec: Record 50001);
    VAR
        ItemJnlLine: Record 83;
        ItemJnlTemplate: Record 82;
        ItemJnlBatch: Record 233;
        ItemJnlMgt: Codeunit 240;
    BEGIN
        //007 Start
        WITH Rec DO BEGIN
            IF ("Journal Template Name" = '') OR
               ("Journal Batch Name" = '') //009
            THEN
                EXIT;

            ItemJnlTemplate.GET("Journal Template Name");
            IF ItemJnlTemplate."Page ID" = 0 THEN
                EXIT;


            IF ItemJnlBatch.GET("Journal Template Name", "Journal Batch Name") THEN
                ItemJnlMgt.TemplateSelectionFromBatch(ItemJnlBatch);

        END;

    END;

    LOCAL PROCEDURE CheckInvtAdjmtLineAlreadyHandled(VAR InvtAdjmtLine: Record 50001; VAR Handled: Boolean);
    VAR
        OldItemJnlLine: Record 83;
        OldItemLedgEntry: Record 32;
    BEGIN
        //009 Start
        InvtAdjmtLine.TESTFIELD("Entry No.");
        Handled := FALSE;

        OldItemJnlLine.RESET;
        OldItemJnlLine.SETCURRENTKEY("Item No.", "Posting Date");
        OldItemJnlLine.SETRANGE("Item No.", InvtAdjmtLine."Item No.");
        OldItemJnlLine.SETRANGE("Posting Date", InvtAdjmtLine."Document Date");
        OldItemJnlLine.SETRANGE("Variant Code", InvtAdjmtLine."Variant Code");
        IF NOT OldItemJnlLine.ISEMPTY THEN BEGIN
            OldItemJnlLine.SETRANGE("GUI-to-BC Entry No", InvtAdjmtLine."Entry No.");
            Handled := NOT OldItemJnlLine.ISEMPTY;
            IF Handled THEN BEGIN
                OldItemJnlLine.FINDFIRST;
                TransferFromItemJnlLine(InvtAdjmtLine, OldItemJnlLine);
                UpdateInvtAdjmtLineAlreadyHandled(InvtAdjmtLine, DATABASE::"Item Journal Line");
                EXIT;
            END;
        END;

        OldItemLedgEntry.RESET;
        OldItemLedgEntry.SETCURRENTKEY("Item No.", "Posting Date");
        OldItemLedgEntry.SETRANGE("Item No.", InvtAdjmtLine."Item No.");
        OldItemLedgEntry.SETRANGE("Posting Date", InvtAdjmtLine."Document Date");
        OldItemLedgEntry.SETRANGE("Variant Code", InvtAdjmtLine."Variant Code");
        IF NOT OldItemLedgEntry.ISEMPTY THEN BEGIN
            OldItemLedgEntry.SETRANGE("GUI-to-BC Entry No", InvtAdjmtLine."Entry No.");
            Handled := NOT OldItemLedgEntry.ISEMPTY;
            IF Handled THEN BEGIN
                OldItemLedgEntry.FINDFIRST;
                InvtAdjmtLine."Journal Document No." := OldItemLedgEntry."Document No.";
                InvtAdjmtLine."Journal Posted" := TRUE;
                UpdateInvtAdjmtLineAlreadyHandled(InvtAdjmtLine, DATABASE::"Item Ledger Entry");
                EXIT;
            END;
        END;
        //009 End
    END;

    LOCAL PROCEDURE UpdateInvtAdjmtLineAlreadyHandled(VAR InvtAdjmtLine: Record 50001; TableID: Integer);
    BEGIN
        //010 Start
        WITH InvtAdjmtLine DO BEGIN
            SetProcessingStatus("Processing Status"::Processed);
            "Validation Error Message" :=
              COPYSTR(STRSUBSTNO(DuplicateDetectedText, "Entry No.", TableID), 1, MAXSTRLEN("Validation Error Message"));
            MODIFY;
        END;
        //010 End
    END;

    LOCAL PROCEDURE TransferFromItemJnlLine(VAR Rec: Record 50001; ItemJnlLine: Record 83);
    BEGIN
        //010 Start
        WITH Rec DO BEGIN
            "Journal Template Name" := ItemJnlLine."Journal Template Name";
            "Journal Batch Name" := ItemJnlLine."Journal Batch Name";
            "Journal Line No." := ItemJnlLine."Line No.";
            "Journal Document No." := ItemJnlLine."Document No.";
        END;
        //010 End
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Invt. Adjmt. Line", 'OnMoveInvtAdjmtLine', '', false, false)]
    LOCAL PROCEDURE InvtAdjmtLineOnMoveInvtAdjmtLine(VAR Sender: Record 50001; ToRecordID: RecordID);
    VAR
        ItemJnlLine: Record 83;
        RecRef: RecordRef;
    BEGIN
        IF ToRecordID.TABLENO <> DATABASE::"Item Journal Line" THEN
            EXIT;

        RecRef := ToRecordID.GETRECORD;
        IF RecRef.ISTEMPORARY THEN
            EXIT;

        RecRef.SETTABLE(ItemJnlLine);

        ItemJnlLine.GET(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.");
        // Do something //
        // ItemJnlLine.MODIFY;

        IF Sender."Ready for Processing" AND
           NOT Sender."Validation Error"
        THEN BEGIN
            //007 Sender."Processing Status" := Sender."Processing Status"::Processed;
            Sender.SetProcessingStatus(Sender."Processing Status"::Processed); //007
            TransferFromItemJnlLine(Sender, ItemJnlLine); //010 - Moved to function
            Sender.MODIFY(TRUE);
        END;
    END;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GUI Inventory Adjmt.-Chek Line", 'OnCheckInvtAdjmtLineHandled', '', false, false)]
    LOCAL PROCEDURE InvtAdjmtChekLineOnCheckInvtAdjmtLineHandled(VAR InvtAdjmtLine: Record 50001; VAR Handled: Boolean);
    BEGIN
        //009 Start
        CheckInvtAdjmtLineAlreadyHandled(InvtAdjmtLine, Handled);
        //009 End
    END;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GUI Inventory Adjmt.-Post Line", 'OnCheckInvtAdjmtLineHandled', '', false, false)]
    LOCAL PROCEDURE InvtAdjmtPostLineOnCheckInvtAdjmtLineHandled(VAR InvtAdjmtLine: Record 50001; VAR Handled: Boolean);
    BEGIN
        //009 Start
        CheckInvtAdjmtLineAlreadyHandled(InvtAdjmtLine, Handled);
        //009 End
    END;



    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Invt. Adjmt. Line", 'OnAfterValidateEvent', 'Quantity', false, false)]

    LOCAL PROCEDURE InvtAdjmtLineOnAfterValidateQuantity(VAR Rec: Record 50001; VAR xRec: Record 50001; CurrFieldNo: Integer);
    BEGIN
        /*  //002 Start
         WITH Rec DO
             "Quantity (Base)" := CalcBaseQty(Rec, Quantity);
         //002 End */
    END;




    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterPostItemJnlLine', '', false, false)]
    LOCAL PROCEDURE ItemJnlPostLine(VAR ItemJournalLine: Record 83);
    BEGIN
        //005 Start
        PostItemJnl(ItemJournalLine);
        //005 End
    END;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]

    LOCAL PROCEDURE ItemJnlPostLineOnAfterInitItemLedgEntry(VAR NewItemLedgEntry: Record 32; VAR ItemJournalLine: Record 83);
    BEGIN
        //009 Start
        WITH ItemJournalLine DO BEGIN
            NewItemLedgEntry."GUI-to-BC Entry No" := "GUI-to-BC Entry No";
            NewItemLedgEntry."GUI Description" := "GUI Description"; //010
            NewItemLedgEntry."GUI Pallet" := "GUI Pallet";
            NewItemLedgEntry."GUI Time of Action" := "GUI Time of Action";
            NewItemLedgEntry."GUI Type" := "GUI Type";
            NewItemLedgEntry."GUI User ID" := "GUI User ID";
        END;
        //009 End
    END;


}