codeunit 50012 GUIItemJnlPostLine
{
    TableNo = 83;
    Permissions = TableData 233 = imd,
                TableData 7313 = r;
    trigger OnRun()
    begin
        ItemJnlLine.COPY(Rec);
        Code;
        Rec := ItemJnlLine;
    end;




    VAR
        Text000: TextConst ENU = 'cannot exceed %1 characters';
        Text001: TextConst ENU = 'Journal Batch Name    #1##########\\';
        Text002: TextConst ENU = 'Checking lines        #2######\';
        Text003: TextConst ENU = 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: TextConst ENU = 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: TextConst ENU = 'Posting lines         #3###### @4@@@@@@@@@@@@@';
        Text006: TextConst ENU = 'A maximum of %1 posting number series can be used in each journal.';
        Text007: TextConst ENU = '<Month Text>';
        Text008: TextConst ENU = 'There are new postings made in the period you want to revalue item no. %1.\';
        Text009: TextConst ENU = 'You must calculate the inventory value again.';
        Text010: TextConst ENU = '@@@="One or more reservation entries exist for the item with Item No. = 1000, Location Code = BLUE, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
        ItemJnlTemplate: Record 82;
        ItemJnlBatch: Record 233;
        ItemJnlLine: Record 83;
        ItemLedgEntry: Record 32;
        WhseEntry: Record 7312;
        ItemReg: Record 46;
        WhseReg: Record 7313;
        GLSetup: Record 98;
        InvtSetup: Record 313;
        AccountingPeriod: Record 50;
        NoSeries: Record "No. Series" temporary;
        Location: Record 14;
        ItemJnlCheckLine: Codeunit 21;
        ItemJnlPostLine: Codeunit 22;
        ItemJnlPostBatch: Codeunit 23;
        NoSeriesMgt: Codeunit "No. Series - Batch";
        NoSeriesMgt2: ARRAY[10] OF Codeunit "No. Series - Batch";
        WMSMgmt: Codeunit 7302;
        WhseJnlPostLine: Codeunit 7301;
        InvtAdjmt: Codeunit 5895;
        Window: Dialog;
        ItemRegNo: Integer;
        WhseRegNo: Integer;
        StartLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        MonthText: Text[30];
        NoOfRecords: Integer;
        LineCount: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        NoOfPostingNoSeries: Integer;
        PostingNoSeriesNo: Integer;
        WhseTransaction: Boolean;
        PhysInvtCount: Boolean;
        HideDialog: Boolean;
        NoCommit: Boolean;

    local procedure Code();
    VAR
        UpdateAnalysisView: Codeunit 410;
        UpdateItemAnalysisView: Codeunit 7150;
        PhysInvtCountMgt: Codeunit 7380;
        GUIBCSetup: Record "GUI-to-BC Setup";
        OldEntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output,"","Assembly Consumption","Assembly Output";
    begin
        WITH ItemJnlLine DO begin
            LOCKTABLE;
            SETRANGE("Journal Template Name", "Journal Template Name");
            SETRANGE("Journal Batch Name", "Journal Batch Name");

            ItemJnlTemplate.GET("Journal Template Name");
            ItemJnlBatch.GET("Journal Template Name", "Journal Batch Name");
            IF STRLEN(INCSTR(ItemJnlBatch.Name)) > MAXSTRLEN(ItemJnlBatch.Name) THEN
                ItemJnlBatch.FIELDERROR(
                  Name,
                  STRSUBSTNO(
                    Text000,
                    MAXSTRLEN(ItemJnlBatch.Name)));

            IF ItemJnlTemplate.Recurring THEN begin
                SETRANGE("Posting Date", 0D, WORKDATE);
                SETFILTER("Expiration Date", '%1 | %2..', 0D, WORKDATE);
            end;

            IF NOT FIND('=><') THEN begin
                "Line No." := 0;
                //001 Start
                IF NOT NoCommit THEN
                    //001 end
                    COMMIT;
                EXIT;
            end;

            CheckItemAvailability(ItemJnlLine);

            //001 Start
            IF ShowDialog THEN begin
                //001 end
                IF ItemJnlTemplate.Recurring THEN
                    Window.OPEN(
                      Text001 +
                      Text002 +
                      Text003 +
                      Text004)
                ELSE
                    Window.OPEN(
                      Text001 +
                      Text002 +
                      Text005);

                Window.UPDATE(1, "Journal Batch Name");
                //001 Start
            end;
            //001 end
            CheckLines(ItemJnlLine);

            // Find next register no.
            ItemLedgEntry.LOCKTABLE;
            IF ItemLedgEntry.FINDLAST THEN;
            IF WhseTransaction THEN begin
                WhseEntry.LOCKTABLE;
                IF WhseEntry.FINDLAST THEN;
            end;

            ItemReg.LOCKTABLE;
            IF ItemReg.FINDLAST THEN
                ItemRegNo := ItemReg."No." + 1
            ELSE
                ItemRegNo := 1;

            WhseReg.LOCKTABLE;
            IF WhseReg.FINDLAST THEN
                WhseRegNo := WhseReg."No." + 1
            ELSE
                WhseRegNo := 1;

            GLSetup.GET;
            PhysInvtCount := FALSE;

            // Post lines
            LineCount := 0;
            OldEntryType := "Entry Type";
            PostLines(ItemJnlLine, PhysInvtCountMgt);

            // Copy register no. and current journal batch name to item journal
            IF NOT ItemReg.FINDLAST OR (ItemReg."No." <> ItemRegNo) THEN
                ItemRegNo := 0;
            IF NOT WhseReg.FINDLAST OR (WhseReg."No." <> WhseRegNo) THEN
                WhseRegNo := 0;

            INIT;

            "Line No." := ItemRegNo;
            IF "Line No." = 0 THEN
                "Line No." := WhseRegNo;

            InvtSetup.GET;
            IF InvtSetup."Automatic Cost Adjustment" <>
               InvtSetup."Automatic Cost Adjustment"::Never
            THEN begin
                InvtAdjmt.SetProperties(TRUE, InvtSetup."Automatic Cost Posting");
                InvtAdjmt.MakeMultiLevelAdjmt;
            end;

            // Update/delete lines
            IF "Line No." <> 0 THEN begin
                IF ItemJnlTemplate.Recurring THEN begin
                    HandleRecurringLine(ItemJnlLine);
                end ELSE
                    HandleNonRecurringLine(ItemJnlLine, OldEntryType);
                IF ItemJnlBatch."No. Series" <> '' THEN
                    NoSeriesMgt.SaveState;
                IF NoSeries.FINDSET THEN
                    REPEAT
                        EVALUATE(PostingNoSeriesNo, NoSeries.Description);
                        NoSeriesMgt2[PostingNoSeriesNo].SaveState;
                    UNTIL NoSeries.NEXT = 0;
            end;

            IF PhysInvtCount THEN
                PhysInvtCountMgt.UpdateItemSKUListPhysInvtCount;

            //001 Start
            IF ShowDialog THEN
                //001 end
                Window.CLOSE;
            //001 Start
            IF NOT NoCommit THEN
                //001 end
                COMMIT;
            CLEAR(ItemJnlCheckLine);
            CLEAR(ItemJnlPostLine);
            clear(ItemJnlPostBatch);

            CLEAR(WhseJnlPostLine);
            CLEAR(InvtAdjmt)
        end;
        //001 Start
        IF NOT NoCommit THEN begin
            //001 end
            UpdateAnalysisView.UpdateAll(0, TRUE);
            UpdateItemAnalysisView.UpdateAll(0, TRUE);
            COMMIT;
            //001 Start
        end;
        //001 end
    end;

    local procedure CheckLines(VAR ItemJnlLine: Record 83);
    begin
        WITH ItemJnlLine DO begin
            LineCount := 0;
            StartLineNo := "Line No.";
            REPEAT
                LineCount := LineCount + 1;
                //001 Start
                IF ShowDialog THEN
                    //001 end
                    Window.UPDATE(2, LineCount);
                CheckRecurringLine(ItemJnlLine);

                IF (("Value Entry Type" = "Value Entry Type"::"Direct Cost") AND ("Item Charge No." = '')) OR
                   (("Invoiced Quantity" <> 0) AND (Amount <> 0))
                THEN begin
                    ItemJnlCheckLine.RunCheck(ItemJnlLine);

                    IF (Quantity <> 0) AND
                       ("Value Entry Type" = "Value Entry Type"::"Direct Cost") AND
                       ("Item Charge No." = '')
                    THEN
                        CheckWMSBin(ItemJnlLine);

                    IF ("Value Entry Type" = "Value Entry Type"::Revaluation) AND
                       ("Inventory Value Per" = "Inventory Value Per"::" ") AND
                       "Partial Revaluation"
                    THEN
                        CheckRemainingQty;
                end;

                IF NEXT = 0 THEN
                    FINDFIRST;
            UNTIL "Line No." = StartLineNo;
            NoOfRecords := LineCount;
        end;
    end;

    local procedure PostLines(VAR ItemJnlLine: Record 83; VAR PhysInvtCountMgt: Codeunit 7380);
    VAR
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
    begin
        LastDocNo := '';
        LastDocNo2 := '';
        LastPostedDocNo := '';
        WITH ItemJnlLine DO begin
            SETCURRENTKEY("Journal Template Name", "Journal Batch Name", "Line No.");
            FINDSET;
            REPEAT
                IF NOT EmptyLine AND
                   (ItemJnlBatch."No. Series" <> '') AND
                   ("Document No." <> LastDocNo2)
                THEN
                    TESTFIELD("Document No.", NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", "Posting Date", FALSE));
                IF NOT EmptyLine THEN
                    LastDocNo2 := "Document No.";
                MakeRecurringTexts(ItemJnlLine);
                ConstructPostingNumber(ItemJnlLine);

                IF "Inventory Value Per" <> "Inventory Value Per"::" " THEN
                    ItemJnlPostSumLine(ItemJnlLine)
                ELSE
                    IF (("Value Entry Type" = "Value Entry Type"::"Direct Cost") AND ("Item Charge No." = '')) OR
                       (("Invoiced Quantity" <> 0) AND (Amount <> 0))
                    THEN begin
                        LineCount := LineCount + 1;
                        //001 Start
                        IF ShowDialog THEN begin
                            //001 end
                            Window.UPDATE(3, LineCount);
                            Window.UPDATE(4, ROUND(LineCount / NoOfRecords * 10000, 1));
                            //001 Start
                        end;
                        //001 end
                        OriginalQuantity := Quantity;
                        OriginalQuantityBase := "Quantity (Base)";
                        IF NOT ItemJnlPostLine.RunWithCheck(ItemJnlLine) THEN
                            ItemJnlPostLine.CheckItemTracking;
                        IF "Value Entry Type" <> "Value Entry Type"::Revaluation THEN begin
                            ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification);
                            PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempTrackingSpecification);
                        end;
                    end;

                IF IsPhysInvtCount(ItemJnlTemplate, "Phys Invt Counting Period Code", "Phys Invt Counting Period Type") THEN begin
                    IF NOT PhysInvtCount THEN begin
                        PhysInvtCountMgt.InitTempItemSKUList;
                        PhysInvtCount := TRUE;
                    end;
                    PhysInvtCountMgt.AddToTempItemSKUList("Item No.", "Location Code", "Variant Code", "Phys Invt Counting Period Type");
                end;
            UNTIL NEXT = 0;
        end;
    end;

    local procedure HandleRecurringLine(VAR ItemJnlLine: Record 83);
    VAR
        ItemJnlLine2: Record 83;
    begin
        LineCount := 0;
        ItemJnlLine2.COPYFILTERS(ItemJnlLine);
        ItemJnlLine2.FINDSET;
        REPEAT
            LineCount := LineCount + 1;
            //001 Start
            IF ShowDialog THEN begin
                //001 end
                Window.UPDATE(5, LineCount);
                Window.UPDATE(6, ROUND(LineCount / NoOfRecords * 10000, 1));
                //001 Start
            end;
            //001 end
            IF ItemJnlLine2."Posting Date" <> 0D THEN
                ItemJnlLine2.VALIDATE("Posting Date", CALCDATE(ItemJnlLine2."Recurring Frequency", ItemJnlLine2."Posting Date"));
            IF (ItemJnlLine2."Recurring Method" = ItemJnlLine2."Recurring Method"::Variable) AND
               (ItemJnlLine2."Item No." <> '')
            THEN begin
                ItemJnlLine2.Quantity := 0;
                ItemJnlLine2."Invoiced Quantity" := 0;
                ItemJnlLine2.Amount := 0;
            end;
            ItemJnlLine2.MODIFY;
        UNTIL ItemJnlLine2.NEXT = 0;
    end;

    local procedure HandleNonRecurringLine(VAR ItemJnlLine: Record 83; OldEntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output,,"Assembly Consumption","Assembly Output");
    VAR
        ItemJnlLine2: Record 83;
        ItemJnlLine3: Record 83;
    begin
        WITH ItemJnlLine DO begin
            ItemJnlLine2.COPYFILTERS(ItemJnlLine);
            ItemJnlLine2.SETFILTER("Item No.", '<>%1', '');
            IF ItemJnlLine2.FINDLAST THEN; // Remember the last line
            ItemJnlLine2."Entry Type" := OldEntryType;

            ItemJnlLine3.COPY(ItemJnlLine);
            ItemJnlLine3.DELETEALL;
            ItemJnlLine3.RESET;
            ItemJnlLine3.SETRANGE("Journal Template Name", "Journal Template Name");
            ItemJnlLine3.SETRANGE("Journal Batch Name", "Journal Batch Name");
            IF NOT ItemJnlLine3.FINDLAST THEN
                IF INCSTR("Journal Batch Name") <> '' THEN begin
                    ItemJnlBatch.DELETE;
                    ItemJnlBatch.Name := INCSTR("Journal Batch Name");
                    IF ItemJnlBatch.INSERT THEN;
                    "Journal Batch Name" := ItemJnlBatch.Name;
                end;

            ItemJnlLine3.SETRANGE("Journal Batch Name", "Journal Batch Name");
            IF (ItemJnlBatch."No. Series" = '') AND NOT ItemJnlLine3.FINDLAST AND
               NOT (ItemJnlLine2."Entry Type" IN [ItemJnlLine2."Entry Type"::Consumption, ItemJnlLine2."Entry Type"::Output])
            THEN begin
                ItemJnlLine3.INIT;
                ItemJnlLine3."Journal Template Name" := "Journal Template Name";
                ItemJnlLine3."Journal Batch Name" := "Journal Batch Name";
                ItemJnlLine3."Line No." := 10000;
                ItemJnlLine3.INSERT;
                ItemJnlLine3.SetUpNewLine(ItemJnlLine2);
                ItemJnlLine3.MODIFY;
            end;
        end;
    end;

    local procedure ConstructPostingNumber(VAR ItemJnlLine: Record 83);
    begin
        WITH ItemJnlLine DO begin
            IF "Posting No. Series" = '' THEN
                "Posting No. Series" := ItemJnlBatch."No. Series"
            ELSE
                IF NOT EmptyLine THEN
                    IF "Document No." = LastDocNo THEN
                        "Document No." := LastPostedDocNo
                    ELSE begin
                        IF NOT NoSeries.GET("Posting No. Series") THEN begin
                            NoOfPostingNoSeries := NoOfPostingNoSeries + 1;
                            IF NoOfPostingNoSeries > ARRAYLEN(NoSeriesMgt2) THEN
                                ERROR(
                                  Text006,
                                  ARRAYLEN(NoSeriesMgt2));
                            NoSeries.Code := "Posting No. Series";
                            NoSeries.Description := FORMAT(NoOfPostingNoSeries);
                            NoSeries.INSERT;
                        end;
                        LastDocNo := "Document No.";
                        EVALUATE(PostingNoSeriesNo, NoSeries.Description);
                        "Document No." := NoSeriesMgt2[PostingNoSeriesNo].GetNextNo("Posting No. Series", "Posting Date", FALSE);
                        LastPostedDocNo := "Document No.";
                    end;
        end;
    end;

    local procedure CheckRecurringLine(VAR ItemJnlLine2: Record 83);
    VAR
        NULDF: DateFormula;
    begin
        WITH ItemJnlLine2 DO begin
            IF "Item No." <> '' THEN
                IF ItemJnlTemplate.Recurring THEN begin
                    TESTFIELD("Recurring Method");
                    TESTFIELD("Recurring Frequency");
                    IF "Recurring Method" = "Recurring Method"::Variable THEN
                        TESTFIELD(Quantity);
                end ELSE begin
                    CLEAR(NULDF);
                    TESTFIELD("Recurring Method", 0);
                    TESTFIELD("Recurring Frequency", NULDF);
                end;
        end;
    end;

    local procedure MakeRecurringTexts(VAR ItemJnlLine2: Record 83);
    begin
        WITH ItemJnlLine2 DO begin
            IF ("Item No." <> '') AND ("Recurring Method" <> 0) THEN begin // Not recurring
                Day := DATE2DMY("Posting Date", 1);
                Week := DATE2DWY("Posting Date", 2);
                Month := DATE2DMY("Posting Date", 2);
                MonthText := FORMAT("Posting Date", 0, Text007);
                AccountingPeriod.SETRANGE("Starting Date", 0D, "Posting Date");
                IF NOT AccountingPeriod.FINDLAST THEN
                    AccountingPeriod.Name := '';
                "Document No." :=
                  DELCHR(
                    PADSTR(
                      STRSUBSTNO("Document No.", Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MAXSTRLEN("Document No.")),
                    '>');
                Description :=
                  DELCHR(
                    PADSTR(
                      STRSUBSTNO(Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MAXSTRLEN(Description)),
                    '>');
            end;
        end;
    end;

    local procedure ItemJnlPostSumLine(ItemJnlLine4: Record 83);
    VAR
        Item: Record 27;
        ItemLedgEntry4: Record 32;
        ItemLedgEntry5: Record 32;
        Remainder: Decimal;
        RemAmountToDistribute: Decimal;
        RemQuantity: Decimal;
        DistributeCosts: Boolean;
        IncludeExpectedCost: Boolean;
        PostingDate: Date;
        IsLastEntry: Boolean;
    begin
        DistributeCosts := TRUE;
        RemAmountToDistribute := ItemJnlLine.Amount;
        RemQuantity := ItemJnlLine.Quantity;
        IF ItemJnlLine.Amount <> 0 THEN begin
            LineCount := LineCount + 1;
            //001 Start
            IF ShowDialog THEN begin
                //001 end
                Window.UPDATE(3, LineCount);
                Window.UPDATE(4, ROUND(LineCount / NoOfRecords * 10000, 1));
                //001 Start
            end;
            //001 end
            WITH ItemLedgEntry4 DO begin
                Item.GET(ItemJnlLine4."Item No.");
                IncludeExpectedCost := (Item."Costing Method" = Item."Costing Method"::Standard) AND
                  (ItemJnlLine4."Inventory Value Per" <> ItemJnlLine4."Inventory Value Per"::" ");
                RESET;
                SETCURRENTKEY("Item No.", Positive, "Location Code", "Variant Code");
                SETRANGE("Item No.", ItemJnlLine."Item No.");
                SETRANGE(Positive, TRUE);
                PostingDate := ItemJnlLine."Posting Date";

                IF (ItemJnlLine4."Location Code" <> '') OR
                   (ItemJnlLine4."Inventory Value Per" IN
                    [ItemJnlLine."Inventory Value Per"::Location,
                     ItemJnlLine4."Inventory Value Per"::"Location and Variant"])
                THEN
                    SETRANGE("Location Code", ItemJnlLine."Location Code");
                IF (ItemJnlLine."Variant Code" <> '') OR
                   (ItemJnlLine4."Inventory Value Per" IN
                    [ItemJnlLine."Inventory Value Per"::Variant,
                     ItemJnlLine4."Inventory Value Per"::"Location and Variant"])
                THEN
                    SETRANGE("Variant Code", ItemJnlLine."Variant Code");
                IF FINDSET THEN
                    REPEAT
                        IF IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) THEN begin
                            ItemLedgEntry5 := ItemLedgEntry4;

                            ItemJnlLine4."Entry Type" := "Entry Type";
                            ItemJnlLine4.Quantity :=
                              CalculateRemQuantity("Entry No.", ItemJnlLine."Posting Date");

                            ItemJnlLine4."Quantity (Base)" := ItemJnlLine4.Quantity;
                            ItemJnlLine4."Invoiced Quantity" := ItemJnlLine4.Quantity;
                            ItemJnlLine4."Invoiced Qty. (Base)" := ItemJnlLine4.Quantity;
                            ItemJnlLine4."Location Code" := "Location Code";
                            ItemJnlLine4."Variant Code" := "Variant Code";
                            ItemJnlLine4."Applies-to Entry" := "Entry No.";
                            ItemJnlLine4."Source No." := "Source No.";
                            ItemJnlLine4."Order Type" := "Order Type";
                            ItemJnlLine4."Order No." := "Order No.";
                            ItemJnlLine4."Order Line No." := "Order Line No.";

                            IF ItemJnlLine4.Quantity <> 0 THEN begin
                                ItemJnlLine4.Amount :=
                                  ItemJnlLine."Inventory Value (Revalued)" * ItemJnlLine4.Quantity /
                                  ItemJnlLine.Quantity -
                                  ROUND(
                                    CalculateRemInventoryValue(
                                      "Entry No.", Quantity, ItemJnlLine4.Quantity,
                                      IncludeExpectedCost AND NOT "Completely Invoiced", PostingDate),
                                    GLSetup."Amount Rounding Precision") + Remainder;

                                RemQuantity := RemQuantity - ItemJnlLine4.Quantity;

                                IF RemQuantity = 0 THEN begin
                                    IF NEXT > 0 THEN
                                        REPEAT
                                            IF IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) THEN begin
                                                RemQuantity := CalculateRemQuantity("Entry No.", ItemJnlLine."Posting Date");
                                                IF RemQuantity > 0 THEN
                                                    ERROR(Text008 + Text009, ItemJnlLine4."Item No.");
                                            end;
                                        UNTIL NEXT = 0;

                                    ItemJnlLine4.Amount := RemAmountToDistribute;
                                    DistributeCosts := FALSE;
                                end ELSE begin
                                    REPEAT
                                        IsLastEntry := NEXT = 0;
                                    UNTIL IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) OR IsLastEntry;
                                    IF IsLastEntry OR (RemQuantity < 0) THEN
                                        ERROR(Text008 + Text009, ItemJnlLine4."Item No.");
                                    Remainder := ItemJnlLine4.Amount - ROUND(ItemJnlLine4.Amount, GLSetup."Amount Rounding Precision");
                                    ItemJnlLine4.Amount := ROUND(ItemJnlLine4.Amount, GLSetup."Amount Rounding Precision");
                                    RemAmountToDistribute := RemAmountToDistribute - ItemJnlLine4.Amount;
                                end;
                                ItemJnlLine4."Unit Cost" := ItemJnlLine4.Amount / ItemJnlLine4.Quantity;

                                IF ItemJnlLine4.Amount <> 0 THEN begin
                                    IF IncludeExpectedCost AND NOT ItemLedgEntry5."Completely Invoiced" THEN begin
                                        ItemJnlLine4."Applied Amount" := ROUND(
                                            ItemJnlLine4.Amount * (ItemLedgEntry5.Quantity - ItemLedgEntry5."Invoiced Quantity") /
                                            ItemLedgEntry5.Quantity,
                                            GLSetup."Amount Rounding Precision");
                                    end ELSE
                                        ItemJnlLine4."Applied Amount" := 0;
                                    ItemJnlPostLine.RunWithCheck(ItemJnlLine4);
                                end;
                            end ELSE begin
                                REPEAT
                                    IsLastEntry := NEXT = 0;
                                UNTIL IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) OR IsLastEntry;
                                IF IsLastEntry THEN
                                    ERROR(Text008 + Text009, ItemJnlLine4."Item No.");
                            end;
                        end ELSE
                            DistributeCosts := NEXT <> 0;
                    UNTIL NOT DistributeCosts;
            end;

            IF ItemJnlLine."Update Standard Cost" THEN
                UpdateStdCost;
        end;
    end;

    local procedure IncludeEntryInCalc(ItemLedgEntry: Record 32; PostingDate: Date; IncludeExpectedCost: Boolean): Boolean;
    begin
        WITH ItemLedgEntry DO begin
            IF IncludeExpectedCost THEN
                EXIT("Posting Date" IN [0D .. PostingDate]);
            EXIT("Completely Invoiced" AND ("Last Invoice Date" IN [0D .. PostingDate]));
        end;
    end;

    local procedure UpdateStdCost();
    VAR
        Item: Record 27;
        SKU: Record 5700;
    begin
        WITH ItemJnlLine DO begin
            IF SKU.GET("Location Code", "Item No.", "Variant Code") THEN begin
                SKU.VALIDATE("Standard Cost", "Unit Cost (Revalued)");
                SKU.MODIFY;
            end ELSE begin
                Item.GET("Item No.");
                Item.VALIDATE("Standard Cost", "Unit Cost (Revalued)");
                Item."Single-Level Material Cost" := "Single-Level Material Cost";
                Item."Single-Level Capacity Cost" := "Single-Level Capacity Cost";
                Item."Single-Level Subcontrd. Cost" := "Single-Level Subcontrd. Cost";
                Item."Single-Level Cap. Ovhd Cost" := "Single-Level Cap. Ovhd Cost";
                Item."Single-Level Mfg. Ovhd Cost" := "Single-Level Mfg. Ovhd Cost";
                Item."Rolled-up Material Cost" := "Rolled-up Material Cost";
                Item."Rolled-up Capacity Cost" := "Rolled-up Capacity Cost";
                Item."Rolled-up Subcontracted Cost" := "Rolled-up Subcontracted Cost";
                Item."Rolled-up Mfg. Ovhd Cost" := "Rolled-up Mfg. Ovhd Cost";
                Item."Rolled-up Cap. Overhead Cost" := "Rolled-up Cap. Overhead Cost";
                Item."Last Unit Cost Calc. Date" := "Posting Date";
                Item.MODIFY;
            end;
        end;
    end;

    local procedure CheckRemainingQty();
    VAR
        ItemLedgerEntry: Record 32;
        RemainingQty: Decimal;
    begin
        RemainingQty := ItemLedgerEntry.CalculateRemQuantity(
            ItemJnlLine."Applies-to Entry", ItemJnlLine."Posting Date");

        IF RemainingQty <> ItemJnlLine.Quantity THEN
            ERROR(Text008 + Text009, ItemJnlLine."Item No.");
    end;

    local procedure PostWhseJnlLine(ItemJnlLine: Record 83; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; VAR TempTrackingSpecification: Record "Tracking Specification" temporary);
    VAR
        WhseJnlLine: Record 7311;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        WITH ItemJnlLine DO begin
            Quantity := OriginalQuantity;
            "Quantity (Base)" := OriginalQuantityBase;
            GetLocation("Location Code");
            IF NOT ("Entry Type" IN ["Entry Type"::Consumption, "Entry Type"::Output]) THEN
                IF Location."Bin Mandatory" THEN
                    IF WMSMgmt.CreateWhseJnlLine(ItemJnlLine, ItemJnlTemplate.Type, WhseJnlLine, FALSE) THEN begin
                        ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, FALSE);
                        IF TempWhseJnlLine2.FINDSET THEN
                            REPEAT
                                WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, FALSE);
                                WhseJnlPostLine.RUN(TempWhseJnlLine2);
                            UNTIL TempWhseJnlLine2.NEXT = 0;
                    end;

            IF "Entry Type" = "Entry Type"::Transfer THEN begin
                GetLocation("New Location Code");
                IF Location."Bin Mandatory" THEN
                    IF WMSMgmt.CreateWhseJnlLine(ItemJnlLine, ItemJnlTemplate.Type, WhseJnlLine, TRUE) THEN begin
                        ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, TRUE);
                        IF TempWhseJnlLine2.FINDSET THEN
                            REPEAT
                                WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, TRUE);
                                WhseJnlPostLine.RUN(TempWhseJnlLine2);
                            UNTIL TempWhseJnlLine2.NEXT = 0;
                    end;
            end;
        end;
    end;

    local procedure CheckWMSBin(ItemJnlLine: Record 83);
    begin
        WITH ItemJnlLine DO begin
            GetLocation("Location Code");
            IF Location."Bin Mandatory" THEN
                WhseTransaction := TRUE;
            CASE "Entry Type" OF
                "Entry Type"::Purchase, "Entry Type"::Sale,
                "Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt.":
                    begin
                        IF Location."Directed Put-away and Pick" THEN
                            WMSMgmt.CheckAdjmtBin(
                              Location, Quantity,
                              ("Entry Type" IN
                               ["Entry Type"::Purchase,
                                "Entry Type"::"Positive Adjmt."]));
                    end;
                "Entry Type"::Transfer:
                    begin
                        IF Location."Directed Put-away and Pick" THEN
                            WMSMgmt.CheckAdjmtBin(Location, -Quantity, FALSE);
                        GetLocation("New Location Code");
                        IF Location."Directed Put-away and Pick" THEN
                            WMSMgmt.CheckAdjmtBin(Location, Quantity, TRUE);
                        IF Location."Bin Mandatory" THEN
                            WhseTransaction := TRUE;
                    end;
            end;
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10]);
    begin
        IF LocationCode = '' THEN
            CLEAR(Location)
        ELSE
            IF Location.Code <> LocationCode THEN
                Location.GET(LocationCode);
    end;

    procedure GetWhseRegNo(): Integer;
    begin
        EXIT(WhseRegNo);
    end;

    procedure GetItemRegNo(): Integer;
    begin
        EXIT(ItemRegNo);
    end;

    local procedure IsPhysInvtCount(ItemJnlTemplate2: Record 82; PhysInvtCountingPeriodCode: Code[10]; PhysInvtCountingPeriodType: Option " ",Item,SKU): Boolean;
    begin
        EXIT(
          (ItemJnlTemplate2.Type = ItemJnlTemplate2.Type::"Phys. Inventory") AND
          (PhysInvtCountingPeriodType <> PhysInvtCountingPeriodType::" ") AND
          (PhysInvtCountingPeriodCode <> ''));
    end;

    local procedure CheckItemAvailability(VAR ItemJnlLine: Record 83);
    VAR
        Item: Record 27;
        TempSKU: Record 5700 temporary;
        ItemJnlLine2: Record 83;
        QtyinItemJnlLine: Decimal;
        AvailableQty: Decimal;
    begin
        ItemJnlLine2.COPYFILTERS(ItemJnlLine);
        IF ItemJnlLine2.FINDSET THEN
            REPEAT
                IF NOT TempSKU.GET(ItemJnlLine2."Location Code", ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code") THEN
                    InsertTempSKU(TempSKU, ItemJnlLine2);
            UNTIL ItemJnlLine2.NEXT = 0;

        IF TempSKU.FINDSET THEN
            REPEAT
                QtyinItemJnlLine := CalcRequiredQty(TempSKU, ItemJnlLine2);
                IF QtyinItemJnlLine < 0 THEN begin
                    Item.GET(TempSKU."Item No.");
                    Item.SETFILTER("Location Filter", TempSKU."Location Code");
                    Item.SETFILTER("Variant Filter", TempSKU."Variant Code");
                    Item.CALCFIELDS("Reserved Qty. on Inventory", "Net Change");
                    AvailableQty := Item."Net Change" - Item."Reserved Qty. on Inventory" + SelfReservedQty(TempSKU, ItemJnlLine2);

                    IF (Item."Reserved Qty. on Inventory" > 0) AND (AvailableQty < ABS(QtyinItemJnlLine)) THEN
                        IF NOT CONFIRM(
                             Text010, FALSE, TempSKU.FIELDCAPTION("Item No."), TempSKU."Item No.", TempSKU.FIELDCAPTION("Location Code"),
                             TempSKU."Location Code", TempSKU.FIELDCAPTION("Variant Code"), TempSKU."Variant Code")
                        THEN
                            ERROR('');
                end;
            UNTIL TempSKU.NEXT = 0;
    end;

    local procedure InsertTempSKU(VAR TempSKU: Record 5700 temporary; ItemJnlLine: Record 83);
    begin
        WITH TempSKU DO begin
            INIT;
            "Location Code" := ItemJnlLine."Location Code";
            "Item No." := ItemJnlLine."Item No.";
            "Variant Code" := ItemJnlLine."Variant Code";
            INSERT;
        end;
    end;

    local procedure CalcRequiredQty(TempSKU: Record 5700 temporary; VAR ItemJnlLine: Record 83): Decimal;
    VAR
        SignFactor: Integer;
        QtyinItemJnlLine: Decimal;
    begin
        QtyinItemJnlLine := 0;
        ItemJnlLine.SETRANGE("Item No.", TempSKU."Item No.");
        ItemJnlLine.SETRANGE("Location Code", TempSKU."Location Code");
        ItemJnlLine.SETRANGE("Variant Code", TempSKU."Variant Code");
        ItemJnlLine.FINDSET;
        REPEAT
            IF (ItemJnlLine."Entry Type" IN
                [ItemJnlLine."Entry Type"::Sale,
                 ItemJnlLine."Entry Type"::"Negative Adjmt.",
                 ItemJnlLine."Entry Type"::Consumption]) OR
               (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer)
            THEN
                SignFactor := -1
            ELSE
                SignFactor := 1;
            QtyinItemJnlLine += ItemJnlLine."Quantity (Base)" * SignFactor;
        UNTIL ItemJnlLine.NEXT = 0;
        EXIT(QtyinItemJnlLine);
    end;

    local procedure SelfReservedQty(SKU: Record 5700; ItemJnlLine: Record 83): Decimal;
    VAR
        ReservationEntry: Record 337;
    begin
        IF ItemJnlLine."Order Type" <> ItemJnlLine."Order Type"::Production THEN
            EXIT;

        WITH ReservationEntry DO begin
            SETRANGE("Item No.", SKU."Item No.");
            SETRANGE("Location Code", SKU."Location Code");
            SETRANGE("Variant Code", SKU."Variant Code");
            SETRANGE("Source Type", DATABASE::"Prod. Order Component");
            SETRANGE("Source ID", ItemJnlLine."Order No.");
            IF ISEMPTY THEN
                EXIT;
            CALCSUMS("Quantity (Base)");
            EXIT(-"Quantity (Base)");
        end;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean);
    begin
        //001 Start
        HideDialog := NewHideDialog;
        //001 end
    end;

    local procedure ShowDialog(): Boolean;
    begin
        //001 Start
        EXIT(NOT HideDialog AND GUIALLOWED);
        //001 end
    end;

    procedure FinalizeBatchPost();
    VAR
        UpdateAnalysisView: Codeunit 410;
        UpdateItemAnalysisView: Codeunit 7150;
    begin
        //001 Start
        IF NoCommit THEN begin
            COMMIT;
            UpdateAnalysisView.UpdateAll(0, TRUE);
            UpdateItemAnalysisView.UpdateAll(0, TRUE);
            COMMIT;
        end;
        //001 end
    end;

    procedure SetNoCommit(NewNoCommit: Boolean);
    begin
        //001 Start
        NoCommit := NewNoCommit;
        //001 end
    end;



}