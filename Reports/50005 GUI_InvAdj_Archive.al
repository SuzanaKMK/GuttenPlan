report 50005 "GUI Archive Invt. Adjustments"
{
    Permissions = TableData "GUI-to-BC Invt. Adjmt. Line" = rmd,
                TableData "GUI-to-BC Invt. Adjmt. Arch." = rim;
    Caption = 'Archive Inventory Adjmt.';
    ProcessingOnly = true;

    dataset
    {
        dataitem("GUI-to-BC Invt. Adjmt. Line"; "GUI-to-BC Invt. Adjmt. Line")
        {
            DataItemTableView = SORTING("Entry No.")
                                 WHERE("Processing Status" = CONST(Processed));
            RequestFilterFields = "Document Date", "Last Date Modified", "Entry No.";


            trigger OnPreDataItem()
            var
            begin
                SETFILTER("GUI-to-BC Invt. Adjmt. Line"."Document Date", DateFilter);

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
                    InvtAdjmtArchive.RESET;
                    IF InvtAdjmtArchive.FINDLAST THEN
                        NextEntryNo := InvtAdjmtArchive."Entry No." + 1
                    ELSE
                        NextEntryNo := 1;
                end;

                InvtAdjmtArchive.INIT;
                InvtAdjmtArchive.TRANSFERFIELDS("GUI-to-BC Invt. Adjmt. Line");
                InvtAdjmtArchive."Entry No." := NextEntryNo;
                InvtAdjmtArchive.INSERT;

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
            IF GUIALLOWED AND NOT HideDialog THEN begin
                IF "GUI-to-BC Invt. Adjmt. Line".GETFILTER("Last Date Modified") <> '' THEN begin
                    InvtAdjmtLine.COPYFILTERS("GUI-to-BC Invt. Adjmt. Line");
                    IF InvtAdjmtLine.FINDLAST THEN
                        IF InvtAdjmtLine."Last Date Modified" > CALCDATE('<-1M>', TODAY) THEN
                            IF NOT CONFIRM(Text002, FALSE) THEN
                                CurrReport.QUIT;
                end ELSE
                    IF NOT CONFIRM(Text001, FALSE) THEN
                        CurrReport.QUIT;
            end;
        end;


    end;





    var
        InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line";
        InvtAdjmtArchive: Record "GUI-to-BC Invt. Adjmt. Arch.";

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