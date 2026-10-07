tableextension 50018 KMK_ProdOrderExt extends "Production Order"
{
    fields
    {
        // Add changes to table fields here

        field(50020; "GUI Order Shift"; Enum "GUI-to-BC Shift") { }

        field(50060; "GUI Production Line No."; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(50055; Mixes; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(50150; KMK_FinishedQty; Decimal)
        {
            Caption = 'Finished Quantity';
            FieldClass = FlowField;
            DecimalPlaces = 0 : 0;
            CalcFormula = Sum("Prod. Order Line"."Finished Quantity" WHERE(Status = FIELD(Status), "Prod. Order No." = FIELD("No.")));
        }
        field(50160; KMK_FinishedQtyBase; Decimal)
        {
            Caption = 'Finished Qty. (Base)';
            FieldClass = FlowField;
            DecimalPlaces = 0 : 0;
            CalcFormula = Sum("Prod. Order Line"."Finished Qty. (Base)" WHERE(Status = FIELD(Status), "Prod. Order No." = FIELD("No.")));
        }
        field(50200; "Accept Change Status"; Boolean)
        {
            DataClassification = ToBeClassified;
        }


    }

    keys
    {
        // Add changes to keys here
        key(Key9; "Source No.", "Routing No.")
        {

        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}