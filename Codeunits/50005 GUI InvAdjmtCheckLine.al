codeunit 50005 "GUI Inventory Adjmt.-Chek Line"
{

    TableNo = "GUI-to-BC Invt. Adjmt. Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var


        IsBatchMode: Boolean;
        DoesNotExistText: TextConst ENU = '%1 %2 does not exist.';
        MustBeSpecifiedText: TextConst ENU = '%1 must be specified.';
        MustNotBeText: TextConst ENU = '%1 must not %2.';
        MustBeText: TextConst ENU = 'ENU=%1 %2 %3 must be %4.';
        ExceedsQtyAvailText: TextConst ENU = 'The total item tracking quantity %1 exceeds the quantity available.';
        CannotBeSameText: TextConst ENU = '=%1 and %2 cannot be the same.';
        ItemAvailabilityNotificationTxt: TextConst ENU = 'Item availability is low.;ESM=La disponibilidad del producto es baja.;FRC=La disponibilit‚ de l''article est faible.;ENC=Item availability is low.';

    procedure RunCheckLines(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
    begin
        WITH InvtAdjmtLine DO begin
            //006 Start
            IF NOT FIND('=><') THEN
                EXIT;
            //006 end

            SetBatchMode(TRUE);
            LineCount := 0;
            StartLineNo := "Entry No.";
            REPEAT
                LineCount := LineCount + 1;
                RunCheck(InvtAdjmtLine);
                IF NEXT = 0 THEN
                    FIND('-');
            UNTIL "Entry No." = StartLineNo;
            NoOfRecords := LineCount;
            SetBatchMode(FALSE);
        end;
    end;

    procedure RunCheck(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    VAR
        UpdateRec: Boolean;
        RunPreProcess: Boolean;
        Handled: Boolean;
    begin
        WITH InvtAdjmtLine DO begin
            IF EmptyLine THEN
                EXIT;

            //009 Start
            IF NOT IsCheckLineAllowed THEN
                EXIT;
            //009 end

            //010 Start - Comment Out if needed at this stage of processing //
            //OnCheckInvtAdjmtLineHandled(InvtAdjmtLine,Handled);
            //IF Handled THEN
            //  EXIT;
            //010 end

            RunPreProcess := "Processing Status" = "Processing Status"::"In Progress"; //009

            IF "Validation Error" THEN begin
                SetProcessingStatus("Processing Status"::"In Progress"); //009
                UpdateRec := TRUE;
            end;

            //003 PreProcess;
            IF RunPreProcess THEN //009
                OnPreProcess; //003

            //009 Start
            IF NOT CheckLine(InvtAdjmtLine) THEN begin
                SetProcessingStatus("Processing Status"::Error);
                UpdateRec := TRUE;
            end;
            //009 end

            IF NOT "Validation Error" THEN begin
                SetProcessingStatus("Processing Status"::Ready); //009
                UpdateRec := TRUE;
            end;

            IF UpdateRec THEN
                MODIFY;
        end;

        EXIT(TRUE);
    end;

    procedure CheckLine(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    begin
        //009 Start
        WITH InvtAdjmtLine DO begin
            IF "Document Date" = 0D THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Document Date")), InvtAdjmtLine));

            IF "Document No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Document No.")), InvtAdjmtLine));


            IF "Location Code" = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Location Code")), InvtAdjmtLine))
            ELSE
                IF NOT CheckLocationCode(InvtAdjmtLine, FIELDCAPTION("Location Code")) THEN
                    EXIT(FALSE);

            IF "Entry Type" = "Entry Type"::Transfer THEN begin //004
                IF "New Location Code" = '' THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("New Location Code")), InvtAdjmtLine))
                ELSE
                    IF NOT CheckLocationCode(InvtAdjmtLine, FIELDCAPTION("New Location Code")) THEN
                        EXIT(FALSE);

                IF "Location Code" = "New Location Code" THEN
                    EXIT(
                      AddError(STRSUBSTNO(CannotBeSameText, FIELDCAPTION("Location Code"), FIELDCAPTION("New Location Code")), InvtAdjmtLine));
            end; //004

            IF "Item No." = '' THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Item No.")), InvtAdjmtLine))
            ELSE
                IF NOT CheckItemNo(InvtAdjmtLine) THEN
                    EXIT(FALSE);

            //008 Start
            IF NOT InvtAdjLineCheckItemAvailability(InvtAdjmtLine) THEN
                EXIT(FALSE);
            //008 end

            IF NOT CheckLotSnAvailable(InvtAdjmtLine) THEN
                EXIT(FALSE);
        end;

        EXIT(TRUE);
        //009 end
    end;

    local procedure CheckItemNo(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    VAR
        Item: Record 27;
        UOMMgt: Codeunit 5402;
    begin
        WITH InvtAdjmtLine DO begin
            IF NOT Item.GET("Item No.") THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, FIELDCAPTION("Item No."), "Item No."), InvtAdjmtLine));

            IF Item.Blocked THEN
                EXIT(
                  AddError(STRSUBSTNO(MustNotBeText, Item.FIELDCAPTION(Blocked), FORMAT(Item.Blocked)), InvtAdjmtLine));

            IF "Unit of Measure Code" = '' THEN begin
                IF Item."Base Unit of Measure" = '' THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, Item.FIELDCAPTION("Base Unit of Measure")), InvtAdjmtLine));
                "Unit of Measure Code" := Item."Base Unit of Measure";
            end;

            IF ("Lot No." <> '') OR
               ("Serial No." <> '')
            THEN begin
                IF Item."Item Tracking Code" = '' THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, Item.FIELDCAPTION("Item Tracking Code")), InvtAdjmtLine));
            end;

            //005 Start
            IF Item."Item Tracking Code" <> '' THEN begin
                IF ("Lot No." = '') AND
                   ("Serial No." = '')
                THEN
                    EXIT(
                      AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Lot No.")), InvtAdjmtLine));
            end;
            //005 end

            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
            // "Quantity (Base)" := CalcBaseQty(Quantity);
            VALIDATE(Quantity); //003
        end;
        EXIT(TRUE);
    end;

    local procedure CheckLocationCode(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"; CalledByFieldName: Text): Boolean;
    VAR
        Location: Record 14;
        Bin: Record 7354;
        LocCode: Code[10];
    begin
        WITH InvtAdjmtLine DO begin
            CASE CalledByFieldName OF
                FIELDCAPTION("Location Code"):
                    LocCode := "Location Code";
                FIELDCAPTION("New Location Code"):
                    LocCode := "New Location Code";
            end;

            IF NOT Location.GET(LocCode) THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, CalledByFieldName, LocCode), InvtAdjmtLine));

            IF Location."Use As In-Transit" THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeText, CalledByFieldName, LocCode, Location.FIELDCAPTION("Use As In-Transit"), FORMAT(NOT Location."Use As In-Transit")), InvtAdjmtLine));

            IF Location."Bin Mandatory" THEN
                CASE CalledByFieldName OF
                    FIELDCAPTION("Location Code"):
                        IF "Bin Code" = '' THEN
                            EXIT(
                              AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("Bin Code")), InvtAdjmtLine))
                        ELSE
                            IF NOT Bin.GET("Location Code", "Bin Code") THEN
                                EXIT(
                                  AddError(STRSUBSTNO(DoesNotExistText, FIELDCAPTION("Bin Code"), "Bin Code"), InvtAdjmtLine));
                    FIELDCAPTION("New Location Code"):
                        IF "New Bin Code" = '' THEN
                            EXIT(
                              AddError(STRSUBSTNO(MustBeSpecifiedText, FIELDCAPTION("New Bin Code")), InvtAdjmtLine))
                        ELSE
                            IF NOT Bin.GET("New Location Code", "New Bin Code") THEN
                                EXIT(
                                  AddError(STRSUBSTNO(DoesNotExistText, FIELDCAPTION("New Bin Code"), "New Bin Code"), InvtAdjmtLine));
                end;
        end;
        EXIT(TRUE);
    end;

    local procedure CheckLotSnAvailable(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    VAR
        Item: Record 27;
        ItemTrackingCode: Record 6502;
        TrackingSpecification: Record 336 temporary;
        ItemJnlLine: Record 83 temporary;
        ItemTrackingLines: Page 6510;
        ItemTrackingDataCollection: Codeunit 6501;
        ReserveItemJnlLine: Codeunit 99000835;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LookupMode: Option "Serial No.","Lot No.";
        ExpDate: Date;
        EntriesExist: Boolean;
        ItemTrackinSetup: Record "Item Tracking Setup";
    begin


        WITH InvtAdjmtLine DO begin
            IF ("Lot No." = '') AND
               ("Serial No." = '')
            THEN
                EXIT(TRUE);

            Item.GET("Item No.");
            IF NOT ItemTrackingCode.GET(Item."Item Tracking Code") THEN
                EXIT(
                  AddError(STRSUBSTNO(DoesNotExistText, Item.FIELDCAPTION("Item Tracking Code"), Item."Item Tracking Code"), InvtAdjmtLine));

            ExpDate :=
              ItemTrackingMgt.ExistingExpirationDate(
                "Item No.", "Variant Code", ItemTrackinSetup,
             FALSE, EntriesExist);

            IF ExpDate <> 0D THEN
                "Expiration Date" := ExpDate;

            //004 Start
            IF (ExpDate <> 0D) AND
               (ExpDate <> "Expiration Date")
            THEN
                EXIT(
                  AddError(STRSUBSTNO(MustBeText, FIELDCAPTION("Expiration Date"), FORMAT("Expiration Date"), '', ExpDate), InvtAdjmtLine));

            IF ("Entry Type" IN ["Entry Type"::"Negative Adjmt.", ItemJnlLine."Entry Type"::Transfer]) THEN begin
                //004 end
                ItemJnlLine.INIT;
                //004 Start
                IF "Entry Type" = "Entry Type"::"Negative Adjmt." THEN
                    ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt."
                ELSE
                    //004 end
                    ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;

                //003 InvtAdjmtLine.CopyToItemJnlLine(ItemJnlLine,FALSE);
                OnCopyToItemJnlLine(ItemJnlLine, FALSE); //003
                                                         //  TrackingSpecification.InitFromItemJnlLine(ItemJnlLine);
                ReserveItemJnlLine.InitFromItemJnlLine(TrackingSpecification, ItemJnlLine);
                LookupMode := LookupMode::"Lot No.";
                ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode("Bin Code", ItemTrackingCode);
                /*  SC
                IF NOT ItemTrackingDataCollection.LotSNAvailable(TrackingSpecification, LookupMode) THEN
                     EXIT(
                       AddError(STRSUBSTNO(ExceedsQtyAvailText, InvtAdjmtLine."Quantity (Base)"), InvtAdjmtLine)); */
            end; //004
        end;
        EXIT(TRUE);
    end;

    local procedure InvtAdjLineCheckItemAvailability(VAR InvtAdjLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    VAR
        ItemNetChange: Decimal;
    begin
        //008 Start
        WITH InvtAdjLine DO begin
            CASE "Entry Type" OF
                "Entry Type"::Purchase, "Entry Type"::"Positive Adjmt.":
                    ItemNetChange := Quantity;
                "Entry Type"::Sale, "Entry Type"::"Negative Adjmt.", "Entry Type"::Transfer:
                    ItemNetChange := -Quantity;
            end;
            IF CheckItemAvailable(
                "Item No.",
                "Variant Code",
                "Location Code",
                "Unit of Measure Code",
                "Qty. per Unit of Measure",
                ItemNetChange,
                0,
                0D)
            THEN
                EXIT(
                  AddError(ItemAvailabilityNotificationTxt, InvtAdjLine));
        end;
        EXIT(TRUE);
        //008 end
    end;

    local procedure CheckItemAvailable(ItemNo: Code[20]; ItemVariantCode: Code[10]; ItemLocationCode: Code[10]; ItemUnitOfMeasureCode: Code[10]; ItemQtyPerUnitOfMeasure: Decimal; NewItemNetChange: Decimal; OldItemNetChange: Decimal; ItemAdjustmentDate: Date): Boolean;
    VAR
        Item: Record 27;
        InitialQtyAvailable: Decimal;
    begin
        //008 Start
        IF NewItemNetChange >= 0 THEN
            EXIT(FALSE);

        SetItemFilterFor(Item, ItemNo, ItemVariantCode, ItemLocationCode, ItemAdjustmentDate);
        InitialQtyAvailable := ConvertQty(CalculateItemAvailability(Item), ItemQtyPerUnitOfMeasure);
        EXIT(InitialQtyAvailable + NewItemNetChange < 0);
        //008 end
    end;

    local procedure CalculateItemAvailability(VAR Item: Record 27) InitialQtyAvailable: Decimal;
    VAR
        AvailableToPromise: Codeunit 5790;
        InventoryQty: Decimal;
        SchedRcpt: Decimal;
        GrossReq: Decimal;
    begin
        //008 Start
        InventoryQty := AvailableToPromise.CalcAvailableInventory(Item);
        SchedRcpt := AvailableToPromise.CalcScheduledReceipt(Item);
        GrossReq := AvailableToPromise.CalcGrossRequirement(Item);

        InitialQtyAvailable :=
          InventoryQty +
          SchedRcpt - GrossReq;
        //008 end
    end;

    local procedure ConvertQty(Qty: Decimal; QtyPerUnitOfMeasure: Decimal): Decimal;
    begin
        //008 Start
        IF QtyPerUnitOfMeasure = 0 THEN
            QtyPerUnitOfMeasure := 1;
        EXIT(ROUND(Qty / QtyPerUnitOfMeasure, 0.00001));
        //008 end
    end;

    local procedure ConvertQtyToBaseQty(Qty: Decimal; QtyPerUnitOfMeasure: Decimal): Decimal;
    begin
        //008 Start
        IF QtyPerUnitOfMeasure = 0 THEN
            QtyPerUnitOfMeasure := 1;
        EXIT(ROUND(Qty * QtyPerUnitOfMeasure, 0.00001));
        //008 end
    end;

    local procedure SetItemFilterFor(VAR Item: Record 27; ItemNo: Code[20]; ItemVariantCode: Code[10]; ItemLocationCode: Code[10]; AdjustmentDate: Date);
    begin
        //008 Start
        Item.GET(ItemNo);
        Item.SETRANGE("No.", ItemNo);
        Item.SETRANGE("Variant Filter", ItemVariantCode);
        Item.SETRANGE("Location Filter", ItemLocationCode);
        Item.SETRANGE("Drop Shipment Filter", FALSE);
        Item.SETRANGE("Date Filter", 0D, AdjustmentDate)
        //008 end
    end;

    procedure SetBatchMode(NewBatchMode: Boolean);
    begin
        IsBatchMode := NewBatchMode;
    end;

    local procedure AddError(Text: Text[250]; VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    begin
        WITH InvtAdjmtLine DO begin
            UpdateErrorMsg(Text); //009 Moved to function //
            MODIFY;
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckInvtAdjmtLineHandled(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"; VAR Handled: Boolean);
    begin
    end;

}