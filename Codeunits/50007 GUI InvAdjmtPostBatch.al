codeunit 50007 "GUI Inventory Adjmt.-Post B."
{
    TableNo = "GUI-to-BC Invt. Adjmt. Line";

    trigger OnRun()
    begin
        //005 Start
        IF RunningResiliency THEN
            rec.LockTable();

        CarryOutInvtAdjmtLineAction(Rec);

    end;

    var
        TempInvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line" Temporary;
        TempFailedInvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line" Temporary;
        InvtAdjmtChekLine: Codeunit 50005;
        InvtAdjmtPostLine: Codeunit 50006;
        Mgt: Codeunit 50010;
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';
        CounterFailed: Integer;
        HideDialog: Boolean;
        RunningResiliency: Boolean;

    procedure CarryOutBatchAction(VAR Rec: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        //005 Start
        InvtAdjmtLine.COPY(Rec);
        Code(InvtAdjmtLine);
        Rec := InvtAdjmtLine;
        //005 end
    end;

    local procedure Code(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    begin
        WITH InvtAdjmtLine DO begin
            //002 SETFILTER("Processing Status",'<>%1',"Processing Status"::Processed);
            //005 SETRANGE("Processing Status","Processing Status"::"In Progress"); //002
            SETFILTER("Processing Status", '>%1', "Processing Status"::New);
            SETRANGE(Processed, FALSE);
            //005 end

            IF NOT RunningResiliency THEN //003
                LOCKTABLE;

            ProcessLines(InvtAdjmtLine);
        end;
    end;

    local procedure ProcessLines(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        TempInvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line" temporary;
        SkippedLine: Boolean;
    begin
        WITH InvtAdjmtLine DO begin
            SETRANGE("Ready for Processing", TRUE);
            IF NOT FIND('=><') THEN begin
                "Entry No." := 0;
                COMMIT;
                EXIT;
            end;

            // Check lines
            LineCount := 0;
            StartLineNo := "Entry No.";
            NoOfRecords := COUNT;
            InvtAdjmtChekLine.SetBatchMode(TRUE);
            REPEAT
                LineCount := LineCount + 1;
                CheckLine(InvtAdjmtLine);
                //005 TempInvtAdjmtLine := InvtAdjmtLine2;
                //005 TempInvtAdjmtLine.INSERT;
                IF NEXT = 0 THEN
                    FINDFIRST;
            UNTIL "Entry No." = StartLineNo;

            // Post lines
            LineCount := 0;
            LastDocNo := '';
            LastPostedDocNo := '';
            //005 Start
            SkippedLine := FALSE;
            CounterFailed := 0;
            //005 end

            FINDSET(TRUE, FALSE);
            REPEAT
                //005 Start
                IF RunningResiliency THEN begin
                    COMMIT;
                    CLEARLASTERROR;
                    IF NOT TryCarryOutInvtAdjmtLineAction(InvtAdjmtLine) THEN begin
                        UpdateErrorMsg(GETLASTERRORTEXT);
                        MODIFY;
                        SetFailedInvtAdjmtLine(InvtAdjmtLine);
                        CounterFailed += 1;
                    end;
                    COMMIT;
                end ELSE
                    CarryOutInvtAdjmtLineAction(InvtAdjmtLine);
            //005 end
            UNTIL NEXT = 0;

            //005 //003 Start
            //IF Mgt.IsAutomaticInvtAdjmtEnabled THEN begin
            //  COMMIT; //004
            //  PostInvtJournal(InvtAdjmtLine);
            //end;
            //005 //003 end

            UpdateAndDeleteLines(InvtAdjmtLine);

            COMMIT;
            CLEAR(InvtAdjmtChekLine);
            CLEAR(InvtAdjmtPostLine);
            //005 CLEARMARKS;
        end;

        IF SkippedLine THEN
            IF GUIALLOWED AND NOT HideDialog THEN
                MESSAGE(SkippedLineMsg);
    end;

    local procedure CheckLine(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        InvtAdjmtLineToUpdate: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        InvtAdjmtLineToUpdate.COPY(InvtAdjmtLine);
        InvtAdjmtChekLine.RunCheck(InvtAdjmtLineToUpdate);
        //005 Start
        InvtAdjmtLine.COPY(InvtAdjmtLineToUpdate);
        InvtAdjmtLine.MODIFY;
        //005 end
    end;

    local procedure CheckDocumentNo(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    begin
    end;

    local procedure CarryOutInvtAdjmtLineAction(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    VAR
        InvtAdjmtLine2: Record "GUI-to-BC Invt. Adjmt. Line";
        Handled: Boolean;
    begin
        WITH InvtAdjmtLine DO begin
            IF "Validation Error" THEN
                EXIT(FALSE);

            //005 Start
            IF NOT "Ready for Processing" THEN
                EXIT(FALSE);
            //005 end

            LineCount := LineCount + 1;

            CheckDocumentNo(InvtAdjmtLine);

            //006 Start
            OnCheckInvtAdjmtLineHandled(InvtAdjmtLine, Handled);
            IF NOT Handled THEN begin
                //end
                InvtAdjmtLine2.COPY(InvtAdjmtLine);
                InvtAdjmtPostLine.RunWithoutCheck(InvtAdjmtLine2);

                //005 Start
                IF Mgt.IsAutomaticInvtAdjmtEnabled THEN begin
                    PostSingleInvtJournal(InvtAdjmtLine2, LineCount = NoOfRecords);
                end;
                //005 end
            end; //006
        end;
        EXIT(TRUE);
    end;

    local procedure UpdateAndDeleteLines(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        InvtAdjmtLine2: Record "GUI-to-BC Invt. Adjmt. Line";
        InvtAdjmtLine3: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        InvtAdjmtLine2.COPY(InvtAdjmtLine);
        InvtAdjmtLine2.SETFILTER("Item No.", '<>%1', '');
        IF InvtAdjmtLine2.FINDLAST THEN; // Remember the last line

        //002 Start
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Invt. Adjmt. Line") THEN
            EXIT;
        //002 end

        InvtAdjmtLine3.COPY(InvtAdjmtLine);
        //InvtAdjmtLine3.SETCURRENTKEY("Processing Status","Order Date","Order Shift","Item No.");
        //005 Start
        //InvtAdjmtLine3.SETRANGE("Processing Status",InvtAdjmtLine3."Processing Status"::Processed);
        InvtAdjmtLine3.SETRANGE("Ready for Processing");
        InvtAdjmtLine3.SETRANGE(Processed, TRUE);
        //005 end
        IF NOT InvtAdjmtLine3.ISEMPTY THEN
            InvtAdjmtLine3.DELETEALL;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean);
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetRunningResiliency();
    begin
        //>>RunningResiliency := TRUE; //005
        RunningResiliency := False; //005
    end;

    procedure SetTryParam(TryLineCount: Integer; VAR TryFailedInvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    begin
        //005 Start
        SetRunningResiliency;

        LineCount := TryLineCount;
        IF TryFailedInvtAdjmtLine.FINDSET THEN
            REPEAT
                TempFailedInvtAdjmtLine := TryFailedInvtAdjmtLine;
                TempFailedInvtAdjmtLine.INSERT;
            UNTIL TryFailedInvtAdjmtLine.NEXT = 0;
        //005 end
    end;

    procedure GetTryParam(VAR TryLineCount: Integer);
    begin
        //005 Start
        TryLineCount := LineCount;
        //005 end
    end;

    procedure TryCarryOutInvtAdjmtLineAction(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"): Boolean;
    VAR
        CarryOutAction: Codeunit 50007;
    begin
        //005 Start
        CarryOutAction.SetTryParam(LineCount, TempFailedInvtAdjmtLine);
        IF CarryOutAction.RUN(InvtAdjmtLine) THEN begin
            CarryOutAction.GetTryParam(LineCount);
            EXIT(TRUE);
        end;
        EXIT(FALSE);
        //005 end
    end;

    local procedure SetFailedInvtAdjmtLine(NewFailedInvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    begin
        //005 Start
        TempFailedInvtAdjmtLine := NewFailedInvtAdjmtLine;
        TempFailedInvtAdjmtLine.INSERT;
        //005 end
    end;

    procedure GetFailedCounter(): Integer;
    begin
        //005 Start
        EXIT(CounterFailed);
        //005 end
    end;

    procedure PostInvtJournal(VAR Rec: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        //005 Start
        InvtAdjmtLine.COPY(Rec);
        PostInvtJournal2(InvtAdjmtLine);
        Rec := InvtAdjmtLine;
        //005 end
    end;

    local procedure PostSingleInvtJournal(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"; Last: Boolean);
    VAR
        LastEntryNo: Integer;
    begin
        //005 Start
        WITH InvtAdjmtLine DO begin
            IF ("Processing Status" <> "Processing Status"::Processed) OR
               "Journal Posted"
            THEN
                EXIT;

            IF ("Journal Template Name" <> '') AND
               ("Journal Batch Name" <> '')
            THEN
                InvtAdjmtPostLine.PostSingleInvtReclassJournal(InvtAdjmtLine, Last OR RunningResiliency);
        end;
        //005 end
    end;

    local procedure PostInvtJournal2(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        xInvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line";
        LastEntryNo: Integer;
    begin
        //005 Start
        WITH InvtAdjmtLine DO begin
            SETCURRENTKEY("Journal Template Name", "Journal Batch Name"); //005
                                                                          //005 SETRANGE("Processing Status","Processing Status"::Processed);
            SETRANGE(Processed, TRUE); //005
            SETRANGE("Journal Posted", FALSE);
            IF ISEMPTY THEN
                EXIT;

            FINDLAST;
            LastEntryNo := "Entry No.";

            IF FINDSET THEN begin
                xInvtAdjmtLine.COPYFILTERS(InvtAdjmtLine); //005
                REPEAT
                    SETRANGE("Journal Template Name", "Journal Template Name");
                    SETRANGE("Journal Batch Name", "Journal Batch Name");
                    FIND('+');
                    IF ("Journal Template Name" <> '') AND
                       ("Journal Batch Name" <> '')
                    THEN
                        InvtAdjmtPostLine.PostInvtReclassJournal(InvtAdjmtLine, LastEntryNo = "Entry No.");
                    SETRANGE("Journal Template Name");
                    SETRANGE("Journal Batch Name");
                    COPYFILTERS(xInvtAdjmtLine); //005
                UNTIL NEXT = 0;
            end;
        end;
        //005 end
    end;

    procedure PostInvtJournalArch(VAR Rec: Record "GUI-to-BC Invt. Adjmt. Arch.");
    VAR
        InvtAdjmtLineArch: Record "GUI-to-BC Invt. Adjmt. Arch.";
    begin
        //005 Start
        InvtAdjmtLineArch.COPY(Rec);
        PostInvtJournalArch2(InvtAdjmtLineArch);
        Rec := InvtAdjmtLineArch;
        //005 end
    end;

    local procedure PostInvtJournalArch2(VAR InvtAdjmtLineArch: Record "GUI-to-BC Invt. Adjmt. Arch.");
    VAR
        xInvtAdjmtLineArch: Record "GUI-to-BC Invt. Adjmt. Arch.";
        LastEntryNo: Integer;
    begin
        //005 Start
        WITH InvtAdjmtLineArch DO begin
            SETCURRENTKEY("Journal Template Name", "Journal Batch Name");
            SETRANGE("Journal Posted", FALSE);
            IF ISEMPTY THEN
                EXIT;

            FINDLAST;
            LastEntryNo := "Entry No.";

            IF FINDSET THEN begin
                xInvtAdjmtLineArch.COPYFILTERS(InvtAdjmtLineArch); //005
                REPEAT
                    SETRANGE("Journal Template Name", "Journal Template Name");
                    SETRANGE("Journal Batch Name", "Journal Batch Name");
                    FIND('+');
                    IF ("Journal Template Name" <> '') AND
                       ("Journal Batch Name" <> '')
                    THEN
                        InvtAdjmtPostLine.PostInvtReclassJournalArch(InvtAdjmtLineArch, LastEntryNo = "Entry No.");
                    SETRANGE("Journal Template Name");
                    SETRANGE("Journal Batch Name");
                    COPYFILTERS(xInvtAdjmtLineArch); //005
                UNTIL NEXT = 0;
            end;
        end;
        //005 end
    end;



    [IntegrationEvent(true, false)]
    local procedure OnCheckInvtAdjmtLineHandled(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line"; VAR Handled: Boolean);
    begin
    end;
}
