codeunit 50025 GUIPurchaseLine_CheckLine

{
    TableNo = "GUI-to-BC Purchase Line";

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

    PROCEDURE RunCheckLines(VAR GUItoNAVPurchLine: Record "GUI-to-BC Purchase Line");
    VAR
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
    BEGIN
        WITH GUItoNAVPurchLine DO BEGIN
            //004 Start
            IF NOT FIND('=><') THEN
                EXIT;
            //004 End

            SetBatchMode(TRUE);
            LineCount := 0;
            StartLineNo := "Entry No.";
            REPEAT
                LineCount := LineCount + 1;
                RunCheck(GUItoNAVPurchLine);
                IF NEXT = 0 THEN
                    FIND('-');
            UNTIL "Entry No." = StartLineNo;
            NoOfRecords := LineCount;
            SetBatchMode(FALSE);
        END;
    END;

    PROCEDURE RunCheck(VAR GUItoNAVPurchLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        UpdateRec: Boolean;
        RunPreProcess: Boolean;
    BEGIN
        WITH GUItoNAVPurchLine DO BEGIN
            IF EmptyLine THEN
                EXIT;

            //008 Start
            IF NOT IsCheckLineAllowed THEN
                EXIT;
            //008 End

            RunPreProcess := "Processing Status" = "Processing Status"::"In Progress"; //008

            IF "Validation Error" THEN BEGIN
                SetProcessingStatus("Processing Status"::"In Progress"); //008
                UpdateRec := TRUE;
            END;

            IF RunPreProcess THEN //008
                OnPreProcess; //002 

            //008 Start
            IF NOT CheckLine(GUItoNAVPurchLine) THEN BEGIN
                SetProcessingStatus("Processing Status"::Error);
                UpdateRec := TRUE;
            END;
            //008 End

            IF NOT "Validation Error" THEN BEGIN
                SetProcessingStatus("Processing Status"::Ready);
                UpdateRec := TRUE;
            END;

            IF UpdateRec THEN
                MODIFY;
        END;

        EXIT(TRUE);
    END;

    LOCAL PROCEDURE CheckLine(VAR GUItoNAVPurchLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        PurchLine: Record 39;
        Item: Record 27;
        UOMMgt: Codeunit 5402;
    BEGIN
        //008 Start
        WITH GUItoNAVPurchLine DO BEGIN
            IF "Document Date" = 0D THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Document Date")), GUItoNAVPurchLine));

            IF "Document No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Document No.")), GUItoNAVPurchLine));

            //002 Start
            IF ("No." = '') AND ("Lot No." = '') THEN //004
                IF "Item-Lot No." = '' THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Item-Lot No.")), GUItoNAVPurchLine));
            //002 End

            //003 Start
            IF Type <> Type::Item THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeText, TABLECAPTION, FIELDCAPTION(Type), '', Type::Item), GUItoNAVPurchLine));
            //003 End

            IF "No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("No.")), GUItoNAVPurchLine))
            ELSE
                //002 Start
                IF NOT CheckItemNo(GUItoNAVPurchLine) THEN
                    EXIT(FALSE);

            IF Quantity = 0 THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION(Quantity)), GUItoNAVPurchLine));

            IF "Document Line No." = 0 THEN BEGIN
                PurchLine.RESET;
                PurchLine.SETRANGE("Document Type", "Document Type");
                PurchLine.SETRANGE("Document No.", "Document No.");
                PurchLine.SETRANGE(Type, Type);
                PurchLine.SETRANGE("No.", "No.");
                PurchLine.SETFILTER("Outstanding Quantity", '<>0');
                IF NOT PurchLine.FINDFIRST THEN
                    EXIT(
                      AddError(STRSUBSTNO(NotFoundText, FORMAT(Type), "No.", FORMAT("Document Type"), "Document No."), GUItoNAVPurchLine))
                ELSE BEGIN
                    "Document Line No." := PurchLine."Line No.";

                    //006 Start
                    //IF "Unit of Measure Code" <> PurchLine."Unit of Measure Code" THEN BEGIN
                    //  Item.GET("No.");
                    //  "Unit of Measure Code" := PurchLine."Unit of Measure Code";
                    //  "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item,"Unit of Measure Code");
                    //  VALIDATE(Quantity);
                    //END;
                    //006 End
                END;
            END;
            //002 End

            //007 Start
            //IF "Lot No." = '' THEN
            //  EXIT(
            //    AddError(STRSUBSTNO(MustBeSpecifiedText,FIELDCAPTION("Lot No.")),GUItoNAVPurchLine));
            //007 End

        END;

        EXIT(TRUE);
        //008 End
    END;

    LOCAL PROCEDURE CheckItemNo(VAR GUItoNAVPurchLine: Record "GUI-to-BC Purchase Line"): Boolean;
    VAR
        Item: Record 27;
        ItemTrackingCode: Record 6502;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit 5402;
        CheckDone: Boolean;
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
    BEGIN
        WITH GUItoNAVPurchLine DO BEGIN
            IF NOT Item.GET("No.") THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, FIELDCAPTION("Lot No."), "Lot No."), GUItoNAVPurchLine));

            IF Item.Blocked THEN
                EXIT(
                  AddError(STRSUBSTNO(MustNotBeText, Item.FIELDCAPTION(Blocked), FORMAT(Item.Blocked)), GUItoNAVPurchLine));

            //002 Start
            //006 Start
            //IF "Unit of Measure Code" = '' THEN BEGIN
            //  IF Item."Purch. Unit of Measure" = '' THEN
            //    EXIT(
            //      AddError(STRSUBSTNO(MustBeSpecifiedText,Item.FIELDCAPTION("Purch. Unit of Measure")),GUItoNAVPurchLine));
            //  "Unit of Measure Code" := Item."Purch. Unit of Measure";
            //END;
            IF "Unit of Measure Code" = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Unit of Measure Code")), GUItoNAVPurchLine));
            //006 End

            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");

            //>> VALIDATE(Quantity);

            "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
            Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
            "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));

            //007 Start
            ItemTrackingCode.Code := Item."Item Tracking Code";
            /*  ItemTrackingMgt.GetItemTrackingSettings(
               ItemTrackingCode,0,"Quantity (Base)" > 0,
               SNRequired,LotRequired,SNInfoRequired,LotInfoRequired);

      */
            if ItemTrackingCode.GET(Item."Item Tracking Code") then begin
                SNRequired := ItemTrackingCode."SN Specific Tracking";
                LotRequired := ItemTrackingCode."Lot Specific Tracking";
            end;
            IF (SNRequired OR LotRequired) AND ("Quantity (Base)" <> 0) THEN BEGIN
                IF SNRequired AND ("Serial No." = '') THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Serial No.")), GUItoNAVPurchLine));
                IF LotRequired AND ("Lot No." = '') THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Lot No.")), GUItoNAVPurchLine));
            END;
            //007 End

            IF ("Lot No." <> '') OR
               ("Serial No." <> '')
            THEN BEGIN
                IF Item."Item Tracking Code" = '' THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, Item.FIELDCAPTION("Item Tracking Code")), GUItoNAVPurchLine));
            END;
            //002 End
        END;

        EXIT(TRUE);
    END;

    PROCEDURE SetBatchMode(NewBatchMode: Boolean);
    BEGIN
        IsBatchMode := NewBatchMode;
    END;

    LOCAL PROCEDURE AddError(Text: Text[250]; VAR GUItoNAVPurchLine: Record "GUI-to-BC Purchase Line"): Boolean;
    BEGIN
        WITH GUItoNAVPurchLine DO BEGIN
            UpdateErrorMsg(Text); //008 Moved to function //
            MODIFY;
        END;
    END;

}