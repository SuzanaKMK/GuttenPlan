codeunit 50030 GUI_SalesCheckLine
{
    TableNo = "GUI-to-BC Sales Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        IsBatchMode: Boolean;
        DoesNotExistText: TextConst ENU = '%1 %2 does not exist.';
        MustBeSpecifiedText: TextConst ENU = '%1 must be specified.';
        MustNotBeText: TextConst ENU = '%1 must not %2.';
        MustBeText: TextConst ENU = '%1 %2 %3 must be %4.';
        NotFoundText: TextConst ENU = '%1 %2 is not found on %3 %4.';


    PROCEDURE RunCheckLines(VAR GUItoNAVSalesLine: Record "GUI-to-BC Sales Line");
    VAR
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
    BEGIN
        WITH GUItoNAVSalesLine DO BEGIN

            IF NOT FIND('=><') THEN
                EXIT;


            SetBatchMode(TRUE);
            LineCount := 0;
            StartLineNo := "Entry No.";
            REPEAT
                LineCount := LineCount + 1;
                RunCheck(GUItoNAVSalesLine);
                IF NEXT = 0 THEN
                    FIND('-');
            UNTIL "Entry No." = StartLineNo;
            NoOfRecords := LineCount;
            SetBatchMode(FALSE);
        END;
    END;

    PROCEDURE RunCheck(VAR GUItoNAVSalesLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        UpdateRec: Boolean;
        RunPreProcess: Boolean;
    BEGIN
        WITH GUItoNAVSalesLine DO BEGIN
            IF EmptyLine THEN
                EXIT;


            IF NOT IsCheckLineAllowed THEN
                EXIT;


            RunPreProcess := "Processing Status" = "Processing Status"::"In Progress"; //007

            IF "Validation Error" THEN BEGIN
                SetProcessingStatus("Processing Status"::"In Progress"); //007
                UpdateRec := TRUE;
            END;

            IF RunPreProcess THEN
                OnPreProcess;

            //007 Start
            IF NOT CheckLine(GUItoNAVSalesLine) THEN BEGIN
                SetProcessingStatus("Processing Status"::Error);
                UpdateRec := TRUE;
            END;
            //007 End

            IF NOT "Validation Error" THEN BEGIN
                SetProcessingStatus("Processing Status"::Ready);
                UpdateRec := TRUE;
            END;

            IF UpdateRec THEN
                MODIFY;
        END;

        EXIT(TRUE);
    END;

    PROCEDURE CheckLine(VAR GUItoNAVSalesLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        SalesLine: Record "Sales Line";
        Item: Record Item;
        UOMMgt: Codeunit 5402;
    BEGIN
        //007 Start
        WITH GUItoNAVSalesLine DO BEGIN
            IF "Document Date" = 0D THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Document Date")), GUItoNAVSalesLine));

            IF "Document No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Document No.")), GUItoNAVSalesLine));



            IF "No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("No.")), GUItoNAVSalesLine))
            ELSE
                IF NOT CheckItemNo(GUItoNAVSalesLine) THEN
                    EXIT(FALSE);

            IF Quantity = 0 THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION(Quantity)), GUItoNAVSalesLine));

            IF "Document Line No." = 0 THEN BEGIN
                SalesLine.RESET;
                SalesLine.SETRANGE("Document Type", "Document Type");
                SalesLine.SETRANGE("Document No.", "Document No.");
                SalesLine.SETRANGE(Type, Type);
                SalesLine.SETRANGE("No.", "No.");
                SalesLine.SETFILTER("Outstanding Quantity", '<>0');
                IF NOT SalesLine.FINDFIRST THEN
                    EXIT(
                      AddError(STRSUBSTNO(NotFoundText, FORMAT(Type), "No.", FORMAT("Document Type"), "Document No."), GUItoNAVSalesLine))
                ELSE BEGIN
                    "Document Line No." := SalesLine."Line No.";

                END;
            END;


        END;

        EXIT(TRUE);
        //007 End
    END;

    LOCAL PROCEDURE CheckItemNo(VAR GUItoNAVSalesLine: Record "GUI-to-BC Sales Line"): Boolean;
    VAR
        Item: Record 27;
        ItemTrackingCode: Record 6502;
        UOMMgt: Codeunit 5402;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
        CheckDone: Boolean;
        ItemTrackingSetup: Record "Item Tracking Setup";
    BEGIN
        WITH GUItoNAVSalesLine DO BEGIN
            IF NOT Item.GET("No.") THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, FIELDCAPTION("Lot No."), "Lot No."), GUItoNAVSalesLine));

            IF Item.Blocked THEN
                EXIT(
                  AddError(STRSUBSTNO(MustNotBeText, Item.FIELDCAPTION(Blocked), FORMAT(Item.Blocked)), GUItoNAVSalesLine));

            IF "Unit of Measure Code" = '' THEN BEGIN

                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Unit of Measure Code")), GUItoNAVSalesLine));

            END;

            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
            VALIDATE(Quantity);


            ItemTrackingCode.Code := Item."Item Tracking Code";

            /*  ItemTrackingMgt.GetItemTrackingSettings(
               ItemTrackingCode, 1, "Quantity (Base)" < 0,
               SNRequired, LotRequired, SNInfoRequired, LotInfoRequired); */
            if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
                SNRequired := ItemTrackingCode."SN Specific Tracking";
                LotRequired := ItemTrackingCode."Lot Specific Tracking";
            end;

            IF (SNRequired OR LotRequired) AND ("Quantity (Base)" <> 0) THEN BEGIN
                IF SNRequired AND ("Serial No." = '') THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Serial No.")), GUItoNAVSalesLine));
                IF LotRequired AND ("Lot No." = '') THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Lot No.")), GUItoNAVSalesLine));
            END;
            //007 End

            IF ("Lot No." <> '') OR
               ("Serial No." <> '')
            THEN BEGIN
                IF Item."Item Tracking Code" = '' THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, Item.FIELDCAPTION("Item Tracking Code")), GUItoNAVSalesLine));
            END;
        END;

        EXIT(TRUE);
    END;

    PROCEDURE SetBatchMode(NewBatchMode: Boolean);
    BEGIN
        IsBatchMode := NewBatchMode;
    END;

    LOCAL PROCEDURE AddError(Text: Text[250]; VAR GUItoNAVSalesLine: Record "GUI-to-BC Sales Line"): Boolean;
    BEGIN
        WITH GUItoNAVSalesLine DO BEGIN
            UpdateErrorMsg(Text);
            MODIFY;
        END;
    END;

}