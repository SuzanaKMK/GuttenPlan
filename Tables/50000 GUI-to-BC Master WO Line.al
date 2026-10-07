table 50000 "GUI-to-BC Master WO Line"
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
            TableRelation = Item;
        }
        field(20; "Order Shift"; Enum "GUI-to-BC Shift") { }

        field(25; "Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(30; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(35; "Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
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
            TableRelation = "Routing Header"."No.";
        }
        field(55; Mixes; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(60; "Production Line No."; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(9100; "GUI User ID"; Text[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = User."User Name";

        }
        field(10000; "Processing Status"; Enum "GUI-to-BC ProcessStatus")
        {
            DataClassification = ToBeClassified;
        }
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
        field(20000; "Prod. Order Status"; Enum "Production Order Status")
        {
            DataClassification = ToBeClassified;
        }
        field(20005; "Prod. Order No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(65; "Location Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = Location where("Use As In-Transit" = filter(false));
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
        rec."Prod. Order Status" := Rec."Prod. Order Status"::Released;
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
    begin
        EXIT(
          ("Item No." = '') AND (Quantity = 0));
    end;

    procedure UpdateErrorMsg(Text: Text);
    begin
        //004 Start
        SetProcessingStatus("Processing Status"::Error);
        "Validation Error Message" := COPYSTR(Text, 1, MAXSTRLEN("Validation Error Message"));
        //004 end
    end;

    procedure SetProcessingStatus(NewProcessingStatus: Integer);
    begin
        //004 Start
        IF NewProcessingStatus > 0 THEN begin
            "Processing Status" := NewProcessingStatus;

            "Ready for Processing" := "Processing Status" = "Processing Status"::Ready;
            "Validation Error" := "Processing Status" = "Processing Status"::Error;
            Processed := "Processing Status" = "Processing Status"::Processed;

            IF NOT "Validation Error" THEN
                "Validation Error Message" := '';
        end;
        //004 end
    end;

    procedure IsCheckLineAllowed(): Boolean;
    begin
        //004 Start
        EXIT(
          NOT Processed AND ("Processing Status" > "Processing Status"::New));
        //004 end
    end;



    [IntegrationEvent(true, false)]
    procedure OnMoveMasterWorkOrderLine(ToRecordID: RecordID);
    begin
    end;


}