table 50015 "GUI-to-BC Output Line Arch"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = ToBeClassified; }
        field(2; "Prod. Order No."; Code[20]) { DataClassification = ToBeClassified; }
        field(20; "Item No."; Code[20]) { DataClassification = ToBeClassified; }
        field(21; "Document No."; Code[20]) { DataClassification = ToBeClassified; }
        field(25; "Variant Code"; Code[10]) { DataClassification = ToBeClassified; }
        field(30; "Quantity"; Decimal) { DataClassification = ToBeClassified; }
        field(35; "Unit of Measure Code"; Code[10]) { DataClassification = ToBeClassified; }
        field(40; "Quantity (Base)"; Decimal) { DataClassification = ToBeClassified; }
        field(45; "Qty. per Unit of Measure"; Decimal) { DataClassification = ToBeClassified; }
        field(50; "Location Code"; Code[10]) { DataClassification = ToBeClassified; }
        field(60; "Document Date"; Date) { DataClassification = ToBeClassified; }
        field(6500; "Serial No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6501; "Lot No."; Code[20]) { DataClassification = ToBeClassified; }
        field(6502; "Warranty Date"; Date) { DataClassification = ToBeClassified; }
        field(6506; "Expiration Date"; Date) { DataClassification = ToBeClassified; }
        field(9000; "Item-Lot No."; Code[50]) { DataClassification = ToBeClassified; }
        field(9100; "GUI User ID"; Text[50]) { DataClassification = ToBeClassified; }
        field(9105; "GUI Description"; Text[100]) { DataClassification = ToBeClassified; }
        field(9114; "GUI Type"; Text[50]) { DataClassification = ToBeClassified; }
        field(9115; "GUI Time of Action"; DateTime) { DataClassification = ToBeClassified; }
        field(9120; "GUI Pallet"; Text[10]) { DataClassification = ToBeClassified; }
        field(9110; "Appl.-to Item Entry"; Integer) { DataClassification = ToBeClassified; }
        field(10000; "Processing Status"; Enum "GUI-to-BC ProcessStatus") { DataClassification = ToBeClassified; }
        field(10005; "Ready for Processing"; Boolean) { DataClassification = ToBeClassified; }
        field(10010; "Validation Error"; Boolean) { DataClassification = ToBeClassified; }
        field(10015; "Validation Error Message"; Text[100]) { DataClassification = ToBeClassified; }
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