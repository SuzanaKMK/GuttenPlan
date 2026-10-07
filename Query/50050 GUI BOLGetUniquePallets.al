query 50050 "GUI BOL Get Unique Pallets"
{
    QueryType = Normal;

    elements
    {
        dataitem(GUI_Pallets; "GUI Pallets")
        {
            column(Pallet; Pallet)
            {
            }
            column(SalesOrder; "Sales Order")
            {
            }

        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}