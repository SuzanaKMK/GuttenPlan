table 50005 "GUI-to-BC Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10]) { DataClassification = ToBeClassified; }
        field(2; "Enable Auto Archive"; Boolean) { DataClassification = ToBeClassified; }
        field(10; "Auto Archive Master Work Order"; Boolean) { DataClassification = ToBeClassified; }
        field(15; "Auto Archive Invt. Adjustment"; Boolean) { DataClassification = ToBeClassified; }
        field(20; "Auto Archive Purchase"; Boolean) { DataClassification = ToBeClassified; }
        field(25; "Auto Archive Sales"; Boolean) { DataClassification = ToBeClassified; }
        field(30; "Auto Archive Output"; Boolean) { DataClassification = ToBeClassified; }
        field(100; "Purchase Post Action"; Enum "GUI-to-BC Purch Post Act.") { DataClassification = ToBeClassified; }
        field(105; "Enable Auto Purch. Post"; Boolean) { DataClassification = ToBeClassified; }
        field(110; "Sales Post Action"; Enum "GUI-to-BC Sales Post Act.") { DataClassification = ToBeClassified; }
        field(115; "Enable Auto Sales Post"; Boolean) { DataClassification = ToBeClassified; }
        field(120; "Enable Auto Invt. Adjmt. Post"; Boolean) { DataClassification = ToBeClassified; }
        field(130; "Enable Auto Prod. Output Post"; Boolean) { DataClassification = ToBeClassified; }
        field(140; "Prod. Change Status Set Qty"; Enum "GUI-to-BC ProdChangeStatSetQty") { DataClassification = ToBeClassified; }
        field(200; "Print BOL on Shipment Post"; Boolean) { DataClassification = ToBeClassified; }
        field(210; "Output Batch Name"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = const('OUTPUT'));
        }
        field(220; "Item Reclass Batch Name"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = const('RECLASS'));
        }
        field(230; "Item Jnl Batch Name"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = const('ITEM'));
        }





    }

    keys
    {
        key(Key1; "Primary Key")
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