table 50001 "GUI-to-BC Invt. Adjmt. Line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(3; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
        field(5; "Entry Type"; Enum "Item Ledger Entry Type") { DataClassification = ToBeClassified; }
        field(7; "Document No."; Code[20]) { DataClassification = ToBeClassified; }
        field(9; "Location Code"; Code[10]) { DataClassification = ToBeClassified; }
        field(13; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                Item: Record Item;
                UOMMgt: Codeunit "Unit of Measure Management";

            begin

                Item.Reset();
                if not Item.Get("Item No.") then Item.Init();
                if "Unit of Measure Code" = '' then
                    "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Base Unit of Measure")
                else
                    "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
            end;
        }
        field(16; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(50; "New Location Code"; Code[10]) { DataClassification = ToBeClassified; }
        field(60; "Document Date"; Date) { DataClassification = ToBeClassified; }
        field(5402; "Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(5403; "Bin Code"; Code[20]) { DataClassification = ToBeClassified; }
        field(5404; "Qty. per Unit of Measure"; Decimal) { DataClassification = ToBeClassified; }
        field(5406; "New Bin Code"; Code[20]) { DataClassification = ToBeClassified; }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                Item: Record Item;
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                Item.Reset();
                if not Item.Get("Item No.") then Item.Init();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                if "Qty. per Unit of Measure" <> 0 then
                    "Quantity (Base)" := "Qty. per Unit of Measure" * Quantity;
            end;
        }
        field(5413; "Quantity (Base)"; Decimal) { DataClassification = ToBeClassified; }
        field(6500; "Serial No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6501; "Lot No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6502; "Warranty Date"; Date) { DataClassification = ToBeClassified; }
        field(6506; "Expiration Date"; Date) { DataClassification = ToBeClassified; }
        field(9000; "Item-Lot No."; Code[50]) { DataClassification = ToBeClassified; }
        field(9100; "GUI User ID"; Text[50]) { DataClassification = ToBeClassified; }
        field(9105; "GUI Description"; Text[100]) { DataClassification = ToBeClassified; }
        field(9110; "GUI Type"; Text[50]) { DataClassification = ToBeClassified; }
        field(9115; "GUI Time of Action"; DateTime) { DataClassification = ToBeClassified; }
        field(9120; "GUI Pallet"; Text[10]) { DataClassification = ToBeClassified; }
        field(10000; "Processing Status"; Enum "GUI-to-BC ProcessStatus") { DataClassification = ToBeClassified; }
        field(10005; "Ready for Processing"; Boolean) { DataClassification = ToBeClassified; }
        field(10010; "Validation Error"; Boolean) { DataClassification = ToBeClassified; }
        field(10015; "Validation Error Message"; Text[250]) { DataClassification = ToBeClassified; }
        field(10017; Processed; Boolean) { DataClassification = ToBeClassified; }
        field(10020; "User ID"; Code[50]) { DataClassification = ToBeClassified; }
        field(10025; "Created DateTime"; DateTime) { DataClassification = ToBeClassified; }
        field(10040; "Last DateTime Modified"; DateTime) { DataClassification = ToBeClassified; }
        field(10045; "Last Date Modified"; Date) { DataClassification = ToBeClassified; }
        field(20000; "Journal Template Name"; Code[10]) { DataClassification = ToBeClassified; }
        field(20005; "Journal Batch Name"; Code[10]) { DataClassification = ToBeClassified; }
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
        UOMMgt: Codeunit "Unit of Measure Management";

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin

        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
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
          //005 ("Item-Lot No." = '') AND (Quantity = 0));
          (Quantity = 0)); //005
    end;

    procedure UpdateErrorMsg(Text: Text);
    begin
        //006 Start
        SetProcessingStatus("Processing Status"::Error);
        "Validation Error Message" := COPYSTR(Text, 1, MAXSTRLEN("Validation Error Message"));
        //006 end
    end;

    procedure SetProcessingStatus(NewProcessingStatus: Integer);
    begin
        //006 Start
        IF NewProcessingStatus > 0 THEN begin
            "Processing Status" := NewProcessingStatus;

            "Ready for Processing" := "Processing Status" = "Processing Status"::Ready;
            "Validation Error" := "Processing Status" = "Processing Status"::Error;
            Processed := "Processing Status" = "Processing Status"::Processed;

            IF NOT "Validation Error" THEN
                "Validation Error Message" := '';
        end;
        //006 end
    end;

    procedure IsCheckLineAllowed(): Boolean;
    begin
        //006 Start
        EXIT(
          NOT Processed AND ("Processing Status" > "Processing Status"::New));
        //006 end
    end;

    [IntegrationEvent(true, false)]
    procedure OnMoveInvtAdjmtLine(ToRecordID: RecordID);
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