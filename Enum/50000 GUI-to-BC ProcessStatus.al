enum 50000 "GUI-to-BC ProcessStatus"
{
    Extensible = true;

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; "In Progress")
    {
        Caption = 'In Progress';
    }
    value(2; "Processed") { Caption = 'Processed'; }
    value(3; "Ready") { Caption = 'Ready'; }
    value(4; "Error") { Caption = 'Error'; }


}