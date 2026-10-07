codeunit 50039 GUI_Output_Line_Integr
{
    trigger OnRun()
    begin

    end;

    var

    VAR
        InvtSetup: Record 313;
        ManufSetup: Record 99000765;
        Mgt: Codeunit 50010;
        InvtSetupRead: Boolean;
        ManufSetupRead: Boolean;
        ItemLotNoFormatText: TextConst ENU = '%1 %2 formatting is wrong.';

    LOCAL PROCEDURE GetInventorySetup();
    BEGIN
        /* IF NOT InvtSetupRead THEN BEGIN
          InvtSetup.GET;
          InvtSetup.TESTFIELD("GUI Default Dry Whse. Location");
          InvtSetupRead := TRUE;
        END;
   */
    END;

    LOCAL PROCEDURE GetManufSetup();
    BEGIN
        /*  IF NOT ManufSetupRead THEN BEGIN
           ManufSetup.GET;
           ManufSetup.TESTFIELD("GUI Def. Production Location");
           ManufSetupRead := TRUE;
         END; */
    END;

    PROCEDURE SplitItemLotNos(VAR Rec: Record 50004);
    VAR
        pos: Integer;
    BEGIN
        WITH Rec DO BEGIN
            IF "Item No." <> '' THEN
                EXIT;

            TESTFIELD("Item-Lot No.");
            pos := STRPOS("Item-Lot No.", '-');
            IF pos = 0 THEN
                ERROR(ItemLotNoFormatText, FIELDCAPTION("Item-Lot No."), "Item-Lot No.");

            "Item No." := COPYSTR("Item-Lot No.", 1, pos - 1);
            "Lot No." := COPYSTR("Item-Lot No.", pos + 1);
        END;
    END;

    PROCEDURE PreProcess(VAR Rec: Record 50004);
    VAR
        FromLocCode: Code[10];
        ToLocCode: Code[10];
    BEGIN
        WITH Rec DO BEGIN
            TESTFIELD("Processing Status", "Processing Status"::"In Progress");
            TESTFIELD(Quantity);

            //  GetInventorySetup;
            //  GetManufSetup;

            SplitItemLotNos(Rec);
        END;
    END;

    PROCEDURE CopyToItemJnlLine(VAR Rec: Record 50004; VAR ItemJnlLine: Record 83; ValidateField: Boolean);
    BEGIN
        WITH Rec DO BEGIN
            IF ValidateField THEN BEGIN
            END ELSE BEGIN
            END;
            ItemJnlLine."GUI Description" := "GUI Description"; //005
        END;
    END;

    PROCEDURE CalcBaseQty(VAR Rec: Record 50004; Qty: Decimal): Decimal;
    BEGIN
        WITH Rec DO BEGIN
            TESTFIELD("Qty. per Unit of Measure");
            EXIT(ROUND(Qty * "Qty. per Unit of Measure", 0.00001));
        END;
    END;

    LOCAL PROCEDURE PostItemJnlLine(VAR ItemJournalLine: Record 83);
    VAR
        ItemJnlTemplate: Record 82;
    BEGIN
        //003 Start
        WITH ItemJournalLine DO BEGIN
            IF "Line No." = 0 THEN
                EXIT;

            IF NOT ItemJnlTemplate.GET("Journal Template Name") THEN
                EXIT;

            IF NOT (ItemJnlTemplate.Type IN [ItemJnlTemplate.Type::Output]) THEN
                EXIT;

            IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Output Line Arch") THEN
                PostItemJnlLineUpdateOutputLine(ItemJournalLine)
            ELSE
                PostItemJnlLineUpdateOutputLineArch(ItemJournalLine);
        END;

    END;

    LOCAL PROCEDURE PostItemJnlLineUpdateOutputLine(VAR ItemJournalLine: Record 83);
    VAR
        OutputLine: Record 50004;
    BEGIN
        //003 Start
        WITH ItemJournalLine DO BEGIN
            OutputLine.RESET;
            OutputLine.SETCURRENTKEY("Journal Template Name", "Journal Batch Name");
            OutputLine.SETRANGE("Journal Template Name", "Journal Template Name");
            OutputLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            OutputLine.SETRANGE("Journal Line No.", "Line No.");
            OutputLine.SETRANGE("Journal Document No.", "Document No.");
            //006 Start
            OutputLine.SETRANGE("Prod. Order No.", "Order No.");
            IF "External Document No." <> '' THEN
                OutputLine.SETRANGE("Document No.", "External Document No.");
            OutputLine.SETRANGE("Document Date", "Document Date");
            //006 End
            OutputLine.SETRANGE(Processed, TRUE);
            IF NOT OutputLine.ISEMPTY THEN BEGIN
                OutputLine.FINDFIRST;
                OutputLine."Journal Posted" := TRUE;
                OutputLine.MODIFY;
            END;
        END;
        //003 End
    END;

    LOCAL PROCEDURE PostItemJnlLineUpdateOutputLineArch(VAR ItemJournalLine: Record 83);
    VAR
        OutputLineArch: Record "GUI-to-BC Output Line Arch";
    BEGIN

        WITH ItemJournalLine DO BEGIN
            OutputLineArch.RESET;
            OutputLineArch.SETCURRENTKEY("Journal Template Name", "Journal Batch Name");
            OutputLineArch.SETRANGE("Journal Template Name", "Journal Template Name");
            OutputLineArch.SETRANGE("Journal Batch Name", "Journal Batch Name");
            OutputLineArch.SETRANGE("Journal Line No.", "Line No.");
            OutputLineArch.SETRANGE("Journal Document No.", "Document No.");

            OutputLineArch.SETRANGE("Prod. Order No.", "Order No.");
            IF "External Document No." <> '' THEN
                OutputLineArch.SETRANGE("Document No.", "External Document No.");
            OutputLineArch.SETRANGE("Document Date", "Document Date");

            IF NOT OutputLineArch.ISEMPTY THEN BEGIN
                OutputLineArch.FINDFIRST;
                OutputLineArch."Journal Posted" := TRUE;
                OutputLineArch.MODIFY;
            END;
        END;

    END;

    LOCAL PROCEDURE OpenOutputJnl(VAR Rec: Record 50004);
    VAR
        ItemJnlLine: Record 83;
        ItemJnlTemplate: Record 82;
    BEGIN
        //004 Start
        WITH Rec DO BEGIN
            IF "Journal Template Name" = '' THEN
                EXIT;

            ItemJnlTemplate.GET("Journal Template Name");
            IF ItemJnlTemplate."Page ID" = 0 THEN
                EXIT;

            ItemJnlLine.RESET;
            ItemJnlLine.FILTERGROUP(2);
            ItemJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
            ItemJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            ItemJnlLine.FILTERGROUP(0);
            PAGE.RUN(ItemJnlTemplate."Page ID", ItemJnlLine);
        END;
        //004 End
    END;




    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Output Line", 'OnMoveOutputLine', '', false, false)]
    LOCAL PROCEDURE OutputLineOnMoveOutputLine(VAR Sender: Record "GUI-to-BC Output Line"; ToRecordID: RecordID);
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

        IF Sender."Ready for Processing" AND
           NOT Sender."Validation Error"
        THEN BEGIN
            //004 Sender."Processing Status" := Sender."Processing Status"::Processed;
            Sender.SetProcessingStatus(Sender."Processing Status"::Processed); //004
            Sender."Journal Template Name" := ItemJnlLine."Journal Template Name";
            Sender."Journal Batch Name" := ItemJnlLine."Journal Batch Name";
            Sender."Journal Line No." := ItemJnlLine."Line No.";
            Sender."Journal Document No." := ItemJnlLine."Document No.";
            Sender.MODIFY(TRUE);
        END;
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Output Line", 'OnSplitItemLotNos', '', false, false)]
    LOCAL PROCEDURE OutputLineOnSplitItemLotNos(VAR Sender: Record 50004);
    BEGIN
        SplitItemLotNos(Sender);
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Output Line", 'OnPreProcess', '', false, false)]

    LOCAL PROCEDURE OutputLineOnPreProcess(VAR Sender: Record 50004);
    BEGIN
        PreProcess(Sender);
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Output Line", 'OnCopyToItemJnlLine', '', false, false)]

    LOCAL PROCEDURE OutputLineOnCopyToItemJnlLine(VAR Sender: Record 50004; VAR ItemJnlLine: Record 83; ValidateField: Boolean);
    BEGIN
        CopyToItemJnlLine(Sender, ItemJnlLine, ValidateField);
    END;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Output Line", 'OnAfterValidateEvent', 'Quantity', false, false)]
    LOCAL PROCEDURE OutputLineOnAfterValidateQuantity(VAR Rec: Record 50004; VAR xRec: Record 50004; CurrFieldNo: Integer);
    BEGIN
        WITH Rec DO BEGIN
            "Quantity (Base)" := CalcBaseQty(Rec, Quantity);
        END;
    END;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterPostItemJnlLine', '', false, false)]
    LOCAL PROCEDURE ItemJnlPostLineOnAfterPostItemJnlLine(VAR ItemJournalLine: Record 83);
    BEGIN

        PostItemJnlLine(ItemJournalLine);

    END;



    /*  [EventSubscriber(ObjectType::Page, Page::"GUI Output Line Worksheet", 'OpenOutputJnl', '', false, false)]

    LOCAL PROCEDURE OutputLineWorksheetOnOpenOutputJnlAction(VAR Rec : Record 50004);
    BEGIN
      //004 Start
      OpenOutputJnl(Rec);
      //004 End
    END; */



}