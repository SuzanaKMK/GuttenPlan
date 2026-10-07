table 50010 "GUI-to-BC Master WO Arch"
{
    DataClassification = ToBeClassified;


    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = True;
            Caption = 'Entry No.';
            Editable = false;
            DataClassification = ToBeClassified;
        }
        field(10; "Order Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(15; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Order Shift"; Enum "GUI-to-BC Shift") { DataClassification = ToBeClassified; }

        field(25; "Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(30; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(35; "Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(40; "Quantity (Base)"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(45; "Qty. per Unit of Measure"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(50; "Routing No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(55; Mixes; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(60; "Production Line No."; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(9100; "GUI User ID"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        /*   field(10000; "Processing Status"; Enum "Production Order Status" ) 
          {
              DataClassification = ToBeClassified;
          } */
        field(10005; "Ready for Processing"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(10010; "Validation Error"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(10015; "Validation Error Message"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(10017; Processed; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(10020; "User ID"; Code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(10025; "Created DateTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(10040; "Last DateTime Modified"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(10045; "Last Date Modified"; Date)
        {
            DataClassification = ToBeClassified;
        }
        /* field(20000; "Prod. Order Status"; Enum "Production Order Status") 
        {
            DataClassification = ToBeClassified;
        } */
        field(20005; "Prod. Order No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }


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