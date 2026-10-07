table 50014 "GUI-to-BC Sales Line Arch"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = ToBeClassified; }
        field(2; "Transaction No."; Integer) { DataClassification = ToBeClassified; }
        field(3; "Document Type"; Enum "Sales Document Type") { DataClassification = ToBeClassified; }
        field(4; "Document No."; Code[20]) { DataClassification = ToBeClassified; }
        field(5; "Document Line No."; Integer) { DataClassification = ToBeClassified; }
        field(6; Type; Enum "Sales Line Type") { DataClassification = ToBeClassified; }
        field(7; "No."; Code[20]) { DataClassification = ToBeClassified; }
        field(15; Quantity; Decimal) { DataClassification = ToBeClassified; }
        field(18; "Total Quantity"; Decimal) { DataClassification = ToBeClassified; }
        field(99; "Document Date"; Date) { DataClassification = ToBeClassified; }
        field(5402; "Variant Code"; Code[10]) { DataClassification = ToBeClassified; }
        field(5404; "Qty. per Unit of Measure"; Decimal) { DataClassification = ToBeClassified; }
        field(5407; "Unit of Measure Code"; Code[10]) { DataClassification = ToBeClassified; }
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
        field(20000; "Posted Document Type"; Enum "GUI-to-BC Sales P. Doc Type") { DataClassification = ToBeClassified; }
        field(20005; "Posted Document No."; Code[20]) { DataClassification = ToBeClassified; }
        field(50053; "Shipper Signature"; Text[50]) { DataClassification = ToBeClassified; }

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

}