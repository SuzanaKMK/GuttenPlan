table 50004 "GUI-to-BC Output Line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Prod. Order No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Production Order"."No.";
        }
        field(20; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
        field(21; "Document No."; Code[20]) { DataClassification = ToBeClassified; }
        field(25; "Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(30; "Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                Item: Record Item;
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                Item.Reset();
                if not Item.Get("Item No.") then Item.Init();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Base Unit of Measure");
            end;
        }
        field(35; "Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(40; "Quantity (Base)"; Decimal) { DataClassification = ToBeClassified; }
        field(45; "Qty. per Unit of Measure"; Decimal) { DataClassification = ToBeClassified; }
        field(50; "Location Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = Location where("Use As In-Transit" = filter(false));
        }
        field(60; "Document Date"; Date) { DataClassification = ToBeClassified; }
        field(6500; "Serial No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6501; "Lot No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6502; "Warranty Date"; Date) { DataClassification = ToBeClassified; }
        field(6506; "Expiration Date"; Date) { DataClassification = ToBeClassified; }
        field(9000; "Item-Lot No."; Code[50]) { DataClassification = ToBeClassified; }
        field(9100; "GUI User ID"; Text[50]) { DataClassification = ToBeClassified; }
        field(9105; "GUI Description"; Text[100]) { DataClassification = ToBeClassified; }
        field(9110; "Appl.-to Item Entry"; Integer)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                ItemLedgEntry: Record 32;
                ItemTrackingLines: Codeunit 50011;
            begin

                IF "Appl.-to Item Entry" = 0 THEN
                    EXIT;

                IF CurrFieldNo = 0 THEN
                    EXIT;

                ItemLedgEntry.GET("Appl.-to Item Entry");

                TESTFIELD(Quantity);
                IF Signed(Quantity) * ItemLedgEntry.Quantity > 0 THEN begin
                    IF Quantity > 0 THEN
                        FIELDERROR(Quantity, MustBeNegativeErrText);
                    IF Quantity < 0 THEN
                        FIELDERROR(Quantity, MustBePositiveErrText);
                end;

                ItemLedgEntry.TESTFIELD("Item No.", "Item No.");
                ItemLedgEntry.TESTFIELD(Positive, TRUE);
                ItemLedgEntry.TESTFIELD("Variant Code", "Variant Code");
                ItemLedgEntry.TESTFIELD("Serial No.", "Serial No.");
                ItemLedgEntry.TESTFIELD("Lot No.", "Lot No.");

                TESTFIELD("Location Code", ItemLedgEntry."Location Code");
                TESTFIELD("Variant Code", ItemLedgEntry."Variant Code");

                IF ABS("Quantity (Base)") > ABS(ItemLedgEntry."Remaining Quantity") THEN
                    ERROR(RemainingQtyErr, ItemLedgEntry.FIELDCAPTION("Remaining Quantity"), ItemLedgEntry."Entry No.", FIELDCAPTION("Quantity (Base)"));
                //009 end
            end;
        }
        field(9114; "GUI Type"; Text[50]) { DataClassification = ToBeClassified; }
        field(9115; "GUI Time of Action"; DateTime) { DataClassification = ToBeClassified; }
        field(9120; "GUI Pallet"; Text[10]) { DataClassification = ToBeClassified; }
        field(10000; "Processing Status"; Enum "GUI-to-BC ProcessStatus") { DataClassification = ToBeClassified; }
        field(10005; "Ready for Processing"; Boolean) { DataClassification = ToBeClassified; }
        field(10010; "Validation Error"; Boolean) { DataClassification = ToBeClassified; }
        field(10015; "Validation Error Message"; Text[100]) { DataClassification = ToBeClassified; }
        field(10017; Processed; Boolean) { DataClassification = ToBeClassified; }
        field(10020; "User ID"; Code[50]) { DataClassification = ToBeClassified; }
        field(10025; "Created DateTime"; DateTime) { DataClassification = ToBeClassified; }
        field(10040; "Last DateTime Modified"; DateTime) { DataClassification = ToBeClassified; }
        field(10045; "Last Date Modified"; Date) { DataClassification = ToBeClassified; }
        field(20000; "Journal Template Name"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Template";
        }
        field(20005; "Journal Batch Name"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(20010; "Journal Line No."; Integer) { DataClassification = ToBeClassified; }
        field(20015; "Journal Document No."; Code[20]) { DataClassification = ToBeClassified; }
        field(20020; "Journal Posted"; Boolean) { DataClassification = ToBeClassified; }

    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
        MustBePositiveErrText: TextConst ENU = 'must be positive';
        MustBeNegativeErrText: TextConst ENU = 'must be negative';
        MustBeOpenErrText: TextConst ENU = 'When posting, the entry %1 will be opened first.';
        RemainingQtyErr: TextConst ENU = 'The %1 in item ledger entry %2 is too low to cover %3.';





    trigger OnInsert()
    begin
        "Created DateTime" := CURRENTDATETIME;
    end;

    trigger OnModify()
    begin
        SetLastDateTimeModified;
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    local procedure SetLastDateTimeModified();
    begin
        "User ID" := USERID;
        "Last DateTime Modified" := CURRENTDATETIME;
        "Last Date Modified" := DT2DATE("Last DateTime Modified");
    end;

    procedure EmptyLine(): Boolean;
    begin
        EXIT(
          ("Item No." = '') AND (Quantity = 0));
    end;

    procedure UpdateErrorMsg(Text: Text);
    begin
        //007 Start
        SetProcessingStatus("Processing Status"::Error);
        "Validation Error Message" := COPYSTR(Text, 1, MAXSTRLEN("Validation Error Message"));
        //007 end
    end;

    procedure SetProcessingStatus(NewProcessingStatus: Integer);
    begin
        //007 Start
        IF NewProcessingStatus > 0 THEN begin
            "Processing Status" := NewProcessingStatus;

            "Ready for Processing" := "Processing Status" = "Processing Status"::Ready;
            "Validation Error" := "Processing Status" = "Processing Status"::Error;
            Processed := "Processing Status" = "Processing Status"::Processed;

            IF NOT "Validation Error" THEN
                "Validation Error Message" := '';
        end;
        //007 end
    end;

    procedure IsCheckLineAllowed(): Boolean;
    begin
        //007 Start
        EXIT(
          NOT Processed AND ("Processing Status" > "Processing Status"::New));
        //007 end
    end;

    local procedure Signed(Value: Decimal): Decimal;
    begin

        EXIT(Value);

    end;

    local procedure SelectItemEntry(CalledByFieldNo: Integer);
    VAR
        ItemLedgEntry: Record "Item Ledger Entry";
        OutputLine: Record "GUI-to-BC Output Line";
    begin
        //009 Start
        IF Quantity >= 0 THEN
            EXIT;

        ItemLedgEntry.RESET;
        ItemLedgEntry.SETCURRENTKEY(
          "Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgEntry.SETRANGE("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SETRANGE("Order No.", "Prod. Order No.");
        ItemLedgEntry.SETRANGE("Entry Type", ItemLedgEntry."Entry Type"::Output);
        ItemLedgEntry.SETRANGE("Prod. Order Comp. Line No.", 0);
        ItemLedgEntry.SETRANGE("Item No.", "Item No.");
        ItemLedgEntry.SETRANGE("Variant Code", "Variant Code");
        IF "Location Code" <> '' THEN
            ItemLedgEntry.SETRANGE("Location Code", "Location Code");
        IF CalledByFieldNo = FIELDNO("Appl.-to Item Entry") THEN begin
            IF "Serial No." <> '' THEN
                ItemLedgEntry.SETRANGE("Serial No.", "Serial No.");
            IF "Lot No." <> '' THEN
                ItemLedgEntry.SETRANGE("Lot No.", "Lot No.");
        end;
        ItemLedgEntry.SETRANGE(Positive, (Signed(Quantity) < 0));
        ItemLedgEntry.SETRANGE(Open, TRUE);

        IF PAGE.RUNMODAL(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK THEN begin
            IF CalledByFieldNo = FIELDNO("Lot No.") THEN begin
                "Lot No." := ItemLedgEntry."Lot No.";
                "Expiration Date" := ItemLedgEntry."Expiration Date";
            end;
            VALIDATE("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
        end;
        //009 end
    end;

    local procedure CheckItemAvailable(CalledByFieldNo: Integer);
    begin

        IF (CurrFieldNo = 0) OR (CurrFieldNo <> CalledByFieldNo) THEN // Prevent two checks on quantity
            EXIT;

        IF (CurrFieldNo <> 0) AND ("Item No." <> '') AND (Quantity <> 0) THEN
          ;

    end;

    [IntegrationEvent(true, false)]
    procedure OnMoveOutputLine(ToRecordID: RecordID);
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnCopyToItemJnlLine(VAR ItemJnlLine: Record 83; ValidateField: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnSplitItemLotNos();
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnPreProcess();
    begin
    end;



}