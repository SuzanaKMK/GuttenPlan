codeunit 50037 "GUI Output Line-Post Batch"
{
    TableNo = "GUI-to-BC Output Line";

    trigger OnRun()
    var
        OutputLine: Record "GUI-to-BC Output Line";
    begin
        IF NOT RunningResiliency THEN
            Rec.LOCKTABLE;


        CarryOutOutputLineAction(Rec);
    end;

    VAR
        TempOutputLine: Record "GUI-to-BC Output Line" temporary;
        TempFailedOutputLine: Record "GUI-to-BC Output Line" temporary;
        OutputChekLine: Codeunit GUI_OutputCheckLine;
        OutputPostLine: Codeunit 50036;
        Mgt: Codeunit GUItoBCManagement;
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;


        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';
        CounterFailed: Integer;
        HideDialog: Boolean;
        RunningResiliency: Boolean;

    procedure CarryOutBatchAction(VAR Rec: Record "GUI-to-BC Output Line");
    VAR
        OutputLine: Record "GUI-to-BC Output Line";
    begin

        OutputLine.COPY(Rec);
        Code(OutputLine);
        Rec := OutputLine;
        //003 end
    end;

    local procedure Code(VAR OutputLine: Record "GUI-to-BC Output Line");
    begin
        WITH OutputLine DO begin
            //003 setrange("Processing Status","Processing Status"::"In Progress");
            setfilter("Processing Status", '>%1', "Processing Status"::New);
            setrange(Processed, FALSE);
            //003 end

            IF NOT RunningResiliency THEN //003
                LOCKTABLE;

            ProcessLines(OutputLine);
        end;
    end;

    local procedure ProcessLines(VAR OutputLine: Record "GUI-to-BC Output Line");
    VAR
        SkippedLine: Boolean;
    begin
        WITH OutputLine DO begin
            IF NOT FIND('=><') THEN begin
                "Entry No." := 0;
                COMMIT;
                EXIT;
            end;

            // Check lines
            LineCount := 0;
            StartLineNo := "Entry No.";
            NoOfRecords := COUNT;
            OutputChekLine.SetBatchMode(TRUE);
            REPEAT
                LineCount := LineCount + 1;
                CheckLine(OutputLine);
                //003 TempOutputLine := OutputLine2;
                //003 TempOutputLine.INSERT;
                IF NEXT = 0 THEN
                    FINDFIRST;
            UNTIL "Entry No." = StartLineNo;

            // Post lines
            LineCount := 0;
            //003 Start
            SkippedLine := FALSE;
            CounterFailed := 0;
            //003 end

            setrange("Ready for Processing", TRUE);
            FINDSET(TRUE, FALSE);
            REPEAT
                //003 Start
                IF RunningResiliency THEN begin
                    COMMIT;
                    CLEARLASTERROR;
                    IF NOT TryCarryOutOutputLineAction(OutputLine) THEN begin
                        UpdateErrorMsg(GETLASTERRORTEXT);
                        MODIFY;
                        SetFailedOutputLine(OutputLine);
                        CounterFailed += 1;
                    end;
                    COMMIT;
                end ELSE
                    CarryOutOutputLineAction(OutputLine);
            //003 end
            UNTIL NEXT = 0;

            //003 //002 Start
            IF Mgt.IsAutomaticProdOutputEnabled THEN begin
                COMMIT;
                PostOutputJournal(OutputLine);
            end;
            //003 //002 end

            UpdateAndDeleteLines(OutputLine);

            COMMIT;
            CLEAR(OutputChekLine);
            CLEAR(OutputPostLine);
            //003 CLEARMARKS;
        end;

        IF SkippedLine THEN
            IF GUIALLOWED AND NOT HideDialog THEN
                MESSAGE(SkippedLineMsg);
    end;

    local procedure CheckLine(VAR OutputLine: Record "GUI-to-BC Output Line");
    VAR
        OutputLineToUpdate: Record "GUI-to-BC Output Line";
    begin
        OutputLineToUpdate.COPY(OutputLine);
        OutputChekLine.RunCheck(OutputLineToUpdate);
        //003 Start
        OutputLine.COPY(OutputLineToUpdate);
        OutputLine.MODIFY;
        //003 end
    end;

    local procedure CheckDocumentNo(VAR OutputLine: Record "GUI-to-BC Output Line");
    begin
    end;

    local procedure CarryOutOutputLineAction(VAR OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    VAR
        OutputLine2: Record "GUI-to-BC Output Line";
    begin
        WITH OutputLine DO begin
            IF "Validation Error" THEN
                EXIT(FALSE);

            //003 Start
            IF NOT "Ready for Processing" THEN
                EXIT(FALSE);
            //003 end

            LineCount := LineCount + 1;

            CheckDocumentNo(OutputLine);

            OutputLine2.COPY(OutputLine);
            OutputPostLine.RunWithoutCheck(OutputLine2);

            //003 Start
            IF Mgt.IsAutomaticProdOutputEnabled THEN begin
                PostSingleOutputJournal(OutputLine2, LineCount = NoOfRecords);
            end;
            //003 end
        end;
        EXIT(TRUE);
    end;

    local procedure UpdateAndDeleteLines(VAR OutputLine: Record "GUI-to-BC Output Line");
    VAR
        OutputLine2: Record "GUI-to-BC Output Line";
        OutputLine3: Record "GUI-to-BC Output Line";
    begin
        OutputLine2.COPY(OutputLine);
        OutputLine2.setfilter("Item No.", '<>%1', '');
        IF OutputLine2.FindLast() THEN; // Remember the last line

        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Output Line") THEN
            EXIT;

        OutputLine3.COPY(OutputLine);
        //003 Start
        //OutputLine3.setrange("Processing Status",OutputLine3."Processing Status"::Processed);
        OutputLine3.setrange("Ready for Processing");
        OutputLine3.setrange(Processed, TRUE);
        //003 end
        IF NOT OutputLine3.ISEMPTY THEN
            OutputLine3.DELETEALL(TRUE);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean);
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetRunningResiliency();
    begin
        RunningResiliency := TRUE; //003
    end;

    procedure SetTryParam(TryLineCount: Integer; VAR TryFailedOutputLine: Record "GUI-to-BC Output Line");
    begin
        //003 Start
        SetRunningResiliency;

        LineCount := TryLineCount;
        IF TryFailedOutputLine.FINDSET THEN
            REPEAT
                TempFailedOutputLine := TryFailedOutputLine;
                TempFailedOutputLine.INSERT;
            UNTIL TryFailedOutputLine.NEXT = 0;
        //003 end
    end;

    procedure GetTryParam(VAR TryLineCount: Integer);
    begin
        //003 Start
        TryLineCount := LineCount;
        //003 end
    end;

    procedure TryCarryOutOutputLineAction(VAR OutputLine: Record "GUI-to-BC Output Line"): Boolean;
    VAR
        CarryOutAction: Codeunit 50037;
    begin
        //003 Start
        CarryOutAction.SetTryParam(LineCount, TempFailedOutputLine);
        IF CarryOutAction.RUN(OutputLine) THEN begin
            CarryOutAction.GetTryParam(LineCount);
            EXIT(TRUE);
        end;
        EXIT(FALSE);
        //003 end
    end;

    local procedure SetFailedOutputLine(NewFailedOutputLine: Record "GUI-to-BC Output Line");
    begin
        //003 Start
        TempFailedOutputLine := NewFailedOutputLine;
        TempFailedOutputLine.INSERT;
        //003 end
    end;

    procedure GetFailedCounter(): Integer;
    begin
        //003 Start
        EXIT(CounterFailed);
        //003 end
    end;

    procedure PostOutputJournal(VAR Rec: Record "GUI-to-BC Output Line");
    VAR
        OutputLine: Record "GUI-to-BC Output Line";
    begin
        //002 Start
        OutputLine.COPY(Rec);
        PostOutputJournal2(OutputLine);
        Rec := OutputLine;
        //002 end
    end;

    local procedure PostSingleOutputJournal(VAR OutputLine: Record "GUI-to-BC Output Line"; Last: Boolean);
    VAR
        LastEntryNo: Integer;
    begin
        //003 Start
        WITH OutputLine DO begin
            IF ("Processing Status" <> "Processing Status"::Processed) OR
               "Journal Posted"
            THEN
                EXIT;

            IF ("Journal Template Name" <> '') AND
               ("Journal Batch Name" <> '')
            THEN
                OutputPostLine.PostSingleOutputJournal(OutputLine, Last OR RunningResiliency);
        end;
        //003 end
    end;

    local procedure PostOutputJournal2(VAR OutputLine: Record "GUI-to-BC Output Line");
    VAR
        xOutputLine: Record "GUI-to-BC Output Line";
        LastEntryNo: Integer;
    begin
        //002 Start
        WITH OutputLine DO begin
            SETCURRENTKEY("Journal Template Name", "Journal Batch Name");
            setrange(Processed, TRUE);
            setrange("Journal Posted", FALSE);
            IF ISEMPTY THEN
                EXIT;

            FINDLAST;
            LastEntryNo := "Entry No.";

            IF FINDSET THEN begin
                xOutputLine.COPYFILTERS(OutputLine); //003
                REPEAT
                    setrange("Journal Template Name", "Journal Template Name");
                    setrange("Journal Batch Name", "Journal Batch Name");
                    FIND('+');
                    IF ("Journal Template Name" <> '') AND
                       ("Journal Batch Name" <> '')
                    THEN
                        OutputPostLine.PostOutputJournal(OutputLine, LastEntryNo = "Entry No.");
                    setrange("Journal Template Name");
                    setrange("Journal Batch Name");
                    COPYFILTERS(xOutputLine); //003
                UNTIL NEXT = 0;
            end;
        end;
        //002 end
    end;

    procedure PostOutputJournalArch(VAR Rec: Record "GUI-to-BC Output Line Arch");
    VAR
        OutputLineArch: Record "GUI-to-BC Output Line Arch";
    begin
        //002 Start
        OutputLineArch.COPY(Rec);
        PostOutputJournalArch2(OutputLineArch);
        Rec := OutputLineArch;
        //002 end
    end;

    local procedure PostOutputJournalArch2(VAR OutputLineArch: Record "GUI-to-BC Output Line Arch");
    VAR
        xOutputLineArch: Record "GUI-to-BC Output Line Arch";
        LastEntryNo: Integer;
    begin
        //005 Start
        WITH OutputLineArch DO begin
            SETCURRENTKEY("Journal Template Name", "Journal Batch Name");
            setrange("Journal Posted", FALSE);
            IF ISEMPTY THEN
                EXIT;

            FINDLAST;
            LastEntryNo := "Entry No.";

            IF FINDSET THEN begin
                xOutputLineArch.COPYFILTERS(OutputLineArch); //003
                REPEAT
                    setrange("Journal Template Name", "Journal Template Name");
                    setrange("Journal Batch Name", "Journal Batch Name");
                    FIND('+');
                    IF ("Journal Template Name" <> '') AND
                       ("Journal Batch Name" <> '')
                    THEN
                        OutputPostLine.PostOutputJournalArch(OutputLineArch, LastEntryNo = "Entry No.");
                    setrange("Journal Template Name");
                    setrange("Journal Batch Name");
                    COPYFILTERS(xOutputLineArch); //003
                UNTIL NEXT = 0;
            end;
        end;
        //002 end
    end;
}