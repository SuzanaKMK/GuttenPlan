tableextension 50016 GUI_ItemLedgerEntry extends "Item Ledger Entry"
{
    fields
    {
        field(50100; "GUI User ID"; Text[50]) { DataClassification = ToBeClassified; }
        field(50105; "GUI Description"; Text[100]) { DataClassification = ToBeClassified; }
        field(50114; "GUI Type"; Text[50]) { DataClassification = ToBeClassified; }
        field(50115; "GUI Time of Action"; DateTime) { DataClassification = ToBeClassified; }
        field(50120; "GUI Pallet"; Text[10]) { DataClassification = ToBeClassified; }
        field(50125; "GUI-to-BC Entry No"; Integer) { DataClassification = ToBeClassified; }

        // Add changes to table fields here
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}