table 50002 "GUI-to-BC Purchase Line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        { AutoIncrement = true; DataClassification = ToBeClassified; }
        field(2; "Transaction No."; Integer) { DataClassification = ToBeClassified; }
        field(3; "Document Type"; Enum "Purchase Document Type") { DataClassification = ToBeClassified; }
        field(4; "Document No."; Code[20])
        {
            TableRelation = "Purchase Header"."No." where("Document Type" = field("Document Type"));
            DataClassification = ToBeClassified;
        }
        field(5; "Document Line No."; Integer)
        {
            TableRelation = "Purchase Line"."Line No." where("Document Type" = field("Document Type"), "Document No." = field("Document No."));
            DataClassification = ToBeClassified;
        }
        field(6; Type; Enum "Purchase Line Type") { DataClassification = ToBeClassified; }
        field(7; "No."; Code[20])
        {

            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account" where("Direct Posting" = const(true), "Account Type" = const(Posting), Blocked = const(false))
            else

            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge"
            else
            if (Type = const(Item), "Document Type" = filter(<> "Credit Memo" & <> "Return Order")) Item where(Blocked = const(false), "Purchasing Blocked" = const(false))
            else
            if (Type = const(Item), "Document Type" = filter("Credit Memo" | "Return Order")) Item where(Blocked = const(false))
            else
            if (Type = const("Allocation Account")) "Allocation Account"
            else
            if (Type = const(Resource)) Resource;
            DataClassification = ToBeClassified;
        }
        field(15; Quantity; Decimal)
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
                if not Item.Get("No.") then Item.Init();
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
        field(18; "Total Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            DataClassification = ToBeClassified;
        }
        field(99; "Document Date"; Date) { DataClassification = ToBeClassified; }
        field(5402; "Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("No."));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal) { DataClassification = ToBeClassified; }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            var
                Item: Record Item;
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                Item.Reset();
                if not Item.Get("No.") then Item.Init();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                if "Qty. per Unit of Measure" <> 0 then
                    "Quantity (Base)" := "Qty. per Unit of Measure" * Quantity;
            end;
        }
        field(5415; "Quantity (Base)"; Decimal) { DataClassification = ToBeClassified; }
        field(5418; "Total Quantity (Base)"; Decimal) { DataClassification = ToBeClassified; }
        field(6500; "Serial No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6501; "Lot No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6502; "Warranty Date"; Date) { DataClassification = ToBeClassified; }
        field(6503; "Expiration Date"; Date) { DataClassification = ToBeClassified; }
        field(9000; "Item-Lot No."; Code[50]) { DataClassification = ToBeClassified; }
        field(9100; "GUI User ID"; Text[50]) { DataClassification = ToBeClassified; }
        field(9105; "GUI Description"; Text[100]) { DataClassification = ToBeClassified; }
        field(9110; "GUI Type"; Text[50]) { DataClassification = ToBeClassified; }
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
        field(20000; "Posted Document Type"; Enum "GUI-to-BC PurchPostedDocType") { DataClassification = ToBeClassified; }
        field(20005; "Posted Document No."; Code[20]) { DataClassification = ToBeClassified; }


    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Document Line No.") { }
        key(Key3; Processed) { }
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
        Rec."Document Type" := Rec."Document Type"::Order;
        Rec.Type := Rec.Type::Item;
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

    local procedure SetLastDateTimeModified();
    begin
        "User ID" := USERID;
        "Last DateTime Modified" := CURRENTDATETIME;
        "Last Date Modified" := DT2DATE("Last DateTime Modified");
    end;

    procedure EmptyLine(): Boolean;
    var
    begin
        EXIT((Quantity = 0));
    end;

    procedure UpdateErrorMsg(Text: Text);
    begin

        SetProcessingStatus("Processing Status"::Error);
        "Validation Error Message" := COPYSTR(Text, 1, MAXSTRLEN("Validation Error Message"));

    end;

    procedure SetProcessingStatus(NewProcessingStatus: Integer);
    begin

        IF NewProcessingStatus > 0 THEN begin
            "Processing Status" := NewProcessingStatus;

            "Ready for Processing" := "Processing Status" = "Processing Status"::Ready;
            "Validation Error" := "Processing Status" = "Processing Status"::Error;
            Processed := "Processing Status" = "Processing Status"::Processed;

            IF NOT "Validation Error" THEN
                "Validation Error Message" := '';
        end;

    end;

    procedure IsCheckLineAllowed(): Boolean;
    begin
        //005 Start
        EXIT(
          NOT Processed AND ("Processing Status" > "Processing Status"::New));
        //005 end
    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin

        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    [IntegrationEvent(true, false)]
    PROCEDURE OnMoveGUItoBCPurchaseLine(ToRecordID: RecordID);
    BEGIN
    END;

    [IntegrationEvent(true, false)]
    PROCEDURE OnPreProcess();
    BEGIN
    END;


}