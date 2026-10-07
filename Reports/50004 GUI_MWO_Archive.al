report 50004 "GUI Archive Master Work Orders"
{
    Permissions = TableData 50000 = rmd,
                TableData 50010 = rim;
    Caption = 'Archive Master Work Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("GUI-to-BC Master WO Line"; "GUI-to-BC Master WO Line")
        {
            DataItemTableView = SORTING("Entry No.")
                                 WHERE("Processing Status" = CONST(Processed));
            RequestFilterFields = "Order Date", "Last Date Modified", "Entry No.";


            trigger OnPreDataItem()
            var
            begin
                SETFILTER("GUI-to-BC Master WO Line"."Order Date", DateFilter);

                IF (FromEntryNo <> 0) AND (ToEntryNo <> 0) THEN
                    SETRANGE("Entry No.", FromEntryNo, ToEntryNo);

                IF GUIALLOWED AND NOT HideDialog THEN
                    Window.OPEN(Text000);

            end;

            trigger OnAfterGetRecord()
            var
            begin
                IF GUIALLOWED AND NOT HideDialog THEN
                    Window.UPDATE(1, "Entry No.");

                IF "Processing Status" <> "Processing Status"::Processed THEN
                    CurrReport.SKIP;

                IF NextEntryNo = 0 THEN begin
                    MasterWorkOrderArchive.RESET;
                    IF MasterWorkOrderArchive.FINDLAST THEN
                        NextEntryNo := MasterWorkOrderArchive."Entry No." + 1
                    ELSE
                        NextEntryNo := 1;
                end;

                MasterWorkOrderArchive.INIT;
                MasterWorkOrderArchive.TRANSFERFIELDS("GUI-to-BC Master WO Line");
                MasterWorkOrderArchive."Entry No." := NextEntryNo;
                MasterWorkOrderArchive.INSERT;

                DELETE;

                NextEntryNo += 1;
                EntriesArchived += 1;
            end;

            trigger OnPostDataItem()
            var
            begin
                IF GUIALLOWED AND NOT HideDialog THEN begin
                    Window.CLOSE;
                    MESSAGE(Text003, EntriesArchived);
                end;

            end;
        }



    }
    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DateFilter; DateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Job Queue Date Filter';

                    }

                }
            }
        }

    }
    trigger OnPreReport()
    var
    begin
        IF GUIALLOWED AND NOT HideDialog THEN begin
            IF "GUI-to-BC Master WO Line".GETFILTER("Last Date Modified") <> '' THEN begin
                MasterWorkOrderLine.COPYFILTERS("GUI-to-BC Master WO Line");
                IF MasterWorkOrderLine.FINDLAST THEN
                    IF MasterWorkOrderLine."Last Date Modified" > CALCDATE('<-1M>', TODAY) THEN
                        IF NOT CONFIRM(Text002, FALSE) THEN
                            CurrReport.QUIT;
            end ELSE
                IF NOT CONFIRM(Text001, FALSE) THEN
                    CurrReport.QUIT;
        end;


    end;





    var
        MasterWorkOrderLine: Record 50000;
        MasterWorkOrderArchive: Record 50010;
        Window: Dialog;
        FromEntryNo: Integer;
        ToEntryNo: Integer;
        Text000: TextConst ENU = 'Processing #1##########;';
        Text001: TextConst ENU = 'You have not defined a date filter. Do you want to continue?';
        Text002: TextConst ENU = 'Your date filter allows archiving of entries that are less than one month old. Do you want to continue?';
        Text003: TextConst ENU = '%1 entries were archived.';
        EntriesArchived: Integer;
        NextEntryNo: Integer;
        HideDialog: Boolean;
        DateFilter: Text;

    procedure InitializeRequest(NewFromEntryNo: Integer; NewToEntryNo: Integer);
    begin
        FromEntryNo := NewFromEntryNo;
        ToEntryNo := NewToEntryNo;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean);
    begin
        HideDialog := NewHideDialog;
    end;
}