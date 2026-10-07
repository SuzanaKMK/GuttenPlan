codeunit 50035 GUI_OutputCheckLine
{
    TableNo = 50004;
    trigger OnRun()
    begin

    end;


    VAR
        IsBatchMode: Boolean;
        DoesNotExistText: TextConst ENU = '%1 %2 does not exist.';
        MustBeSpecifiedText: TextConst ENU = '%1 must be specified.';
        MustNotBeText: TextConst ENU = '%1 must not %2.';
        MustBeText: TextConst ENU = '%1 %2 %3 must be %4.';
        ItemDoesNotHaveBOMText: TextConst ENU = 'Item No. %1 does not have Production BOM specified.';
        MustBePositiveErrText: TextConst ENU = 'must be positive';
        MustBeNegativeErrText: TextConst ENU = 'must be negative';
        MustBeOpenErrText: TextConst ENU = 'When posting, the entry %1 will be opened first.';
        RemainingQtyErr: TextConst ENU = 'The %1 in item ledger entry %2 is too low to cover %3.';

    procedure RunCheckLines(VAR OutputLine: Record "GUI-to-BC Output Line");
    VAR
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
    begin
        WITH OutputLine DO begin
            //003 Start
            IF NOT FIND('=><') THEN
                EXIT;
            //003 end

            SetBatchMode(TRUE);
            LineCount := 0;
            StartLineNo := "Entry No.";
            REPEAT
                LineCount := LineCount + 1;
                RunCheck(OutputLine);
                IF NEXT = 0 THEN
                    FIND('-');
            UNTIL "Entry No." = StartLineNo;
            NoOfRecords := LineCount;
            SetBatchMode(FALSE);
        end;
    end;

    procedure RunCheck(VAR OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    VAR
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        UpdateRec: Boolean;
        OK: Boolean;
    begin
        WITH OutputLine DO begin
            IF EmptyLine THEN
                EXIT;

            //004 Start
            IF NOT IsCheckLineAllowed THEN
                EXIT;
            //004 end

            IF "Validation Error" THEN begin
                SetProcessingStatus("Processing Status"::"In Progress"); //004
                UpdateRec := TRUE;
            end;

            //004 Start
            IF NOT CheckLine(OutputLine) THEN begin
                SetProcessingStatus("Processing Status"::Error);
                UpdateRec := TRUE;
            end;
            //004 end

            IF NOT "Validation Error" THEN begin
                SetProcessingStatus("Processing Status"::Ready); //004
                UpdateRec := TRUE;
            end;

            IF UpdateRec THEN
                MODIFY;
        end;

        EXIT(TRUE);
    end;

    procedure CheckLine(VAR OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    VAR
        ProdOrder: Record 5405;
        ProdOrderLine: Record 5406;
    begin
        //004 Start
        WITH OutputLine DO begin
            IF "Document Date" = 0D THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Document Date")), OutputLine));

            //003 Start
            IF "Prod. Order No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Prod. Order No.")), OutputLine))
            ELSE begin
                ProdOrder.Reset();
                if not ProdOrder.GET(ProdOrder.Status::Released, "Prod. Order No.") then
                    exit(
                      AddError(STRSUBSTNO(DoesNotExistText, FIELDCAPTION("Prod. Order No."), "Prod. Order No."), OutputLine));
            end;

            IF "Item No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Item No.")), OutputLine))
            ELSE
                IF NOT CheckItemNo(OutputLine) THEN
                    EXIT(FALSE);

            //002 Start
            IF "Location Code" = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Location Code")), OutputLine))
            ELSE
                IF NOT CheckLocationCode(OutputLine, FIELDCAPTION("Location Code")) THEN
                    EXIT(FALSE);
            //002 end

            //005 Start
            IF "Appl.-to Item Entry" <> 0 THEN
                IF NOT CheckAppliesToItemEntry(OutputLine, FIELDCAPTION("Appl.-to Item Entry")) THEN
                    EXIT(FALSE);
            //005 end
        end;

        EXIT(TRUE);
        //004 end
    end;

    local procedure CheckItemNo(VAR OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    VAR
        Item: Record Item;
        CheckDone: Boolean;
    begin
        WITH OutputLine DO begin
            IF NOT Item.GET("Item No.") THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, FIELDCAPTION("Item No."), "Item No."), OutputLine));

            IF Item.Blocked THEN
                EXIT(
                  AddError(STRSUBSTNO(MustNotBeText, Item.FIELDCAPTION(Blocked), FORMAT(Item.Blocked)), OutputLine));
        end;

        EXIT(TRUE);
    end;

    local procedure CheckLocationCode(VAR OutputLine: Record "GUI-to-BC Output Line"; CalledByFieldName: Text): Boolean;
    VAR
        Location: Record Location;
        Bin: Record Bin;
        LocCode: Code[10];
    begin
        //002 Start
        WITH OutputLine DO begin
            CASE CalledByFieldName OF
                FIELDCAPTION("Location Code"):
                    LocCode := "Location Code";
            end;

            IF NOT Location.GET(LocCode) THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, CalledByFieldName, LocCode), OutputLine));

            IF Location."Use As In-Transit" THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeText, CalledByFieldName, LocCode, Location.FIELDCAPTION("Use As In-Transit"), FORMAT(NOT Location."Use As In-Transit")), OutputLine));

            IF Location."Bin Mandatory" THEN
              ;
        end;
        EXIT(TRUE);
        //002 end
    end;

    local procedure CheckAppliesToItemEntry(VAR OutputLine: Record "GUI-to-BC Output Line"; CalledByFieldName: Text): Boolean;
    VAR
        ItemLedgEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SNRequired: Boolean;
        LotRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
    begin
        //005 Start
        WITH OutputLine DO begin
            IF "Appl.-to Item Entry" = 0 THEN
                EXIT(TRUE);

            IF NOT ItemLedgEntry.GET("Appl.-to Item Entry") THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, CalledByFieldName, "Appl.-to Item Entry"), OutputLine));

            Item.GET("Item No.");
            ItemTrackingCode.Code := Item."Item Tracking Code";

            /*  ItemTrackingMgt.GetItemTrackingSettings(
               ItemTrackingCode, 6, "Quantity (Base)" < 0,
               SNRequired, LotRequired, SNInfoRequired, LotInfoRequired); */

            IF (SNRequired OR LotRequired) AND ("Quantity (Base)" <> 0) THEN begin
                IF SNRequired AND ("Serial No." = '') THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Serial No.")), OutputLine));
                IF LotRequired AND ("Lot No." = '') THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Lot No.")), OutputLine));
            end;

            IF ("Lot No." <> '') OR
               ("Serial No." <> '')
            THEN begin
                IF Item."Item Tracking Code" = '' THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, Item.FIELDCAPTION("Item Tracking Code")), OutputLine));
            end;

            IF Quantity = 0 THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION(Quantity)), OutputLine));

            IF Signed(Quantity) * ItemLedgEntry.Quantity > 0 THEN begin
                IF Quantity > 0 THEN
                    EXIT(
                      AddError(STRSUBSTNO('%1 %2', FIELDCAPTION(Quantity), MustBeNegativeErrText), OutputLine));
                IF Quantity < 0 THEN
                    EXIT(
                      AddError(STRSUBSTNO('%1 %2', FIELDCAPTION(Quantity), MustBePositiveErrText), OutputLine));
            end;

            IF ItemLedgEntry."Item No." <> "Item No." THEN
                EXIT(
                  AddError(
                    STRSUBSTNO(MustBeText, ItemLedgEntry.TABLECAPTION, ItemLedgEntry.FIELDCAPTION("Item No."), ItemLedgEntry."Item No.", "Item No."), OutputLine));

            IF ItemLedgEntry."Variant Code" <> "Variant Code" THEN
                EXIT(
                  AddError(
                    STRSUBSTNO(MustBeText, ItemLedgEntry.TABLECAPTION, ItemLedgEntry.FIELDCAPTION("Variant Code"), ItemLedgEntry."Variant Code", "Variant Code"), OutputLine));

            IF ItemLedgEntry."Serial No." <> "Serial No." THEN
                EXIT(
                  AddError(
                    STRSUBSTNO(MustBeText, ItemLedgEntry.TABLECAPTION, ItemLedgEntry.FIELDCAPTION("Serial No."), ItemLedgEntry."Serial No.", "Serial No."), OutputLine));

            IF ItemLedgEntry."Lot No." <> "Lot No." THEN
                EXIT(
                  AddError(
                    STRSUBSTNO(MustBeText, ItemLedgEntry.TABLECAPTION, ItemLedgEntry.FIELDCAPTION("Lot No."), ItemLedgEntry."Lot No.", "Lot No."), OutputLine));

            IF ABS("Quantity (Base)") > ABS(ItemLedgEntry."Remaining Quantity") THEN
                EXIT(
                  AddError(
                    STRSUBSTNO(RemainingQtyErr, ItemLedgEntry.FIELDCAPTION("Remaining Quantity"), ItemLedgEntry."Entry No.", FIELDCAPTION("Quantity (Base)")),
                    OutputLine));
        end;

        EXIT(TRUE);
        //005 end
    end;

    local procedure Signed(Value: Decimal): Decimal;
    begin
        //005 Start
        EXIT(Value);
        //005 end
    end;

    procedure SetBatchMode(NewBatchMode: Boolean);
    begin
        IsBatchMode := NewBatchMode;
    end;

    local procedure AddError(Text: Text[250]; VAR OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    begin
        WITH OutputLine DO begin
            UpdateErrorMsg(Text); //004 Moved to function //
            MODIFY;
        end;
    end;



    var
        myInt: Integer;
}