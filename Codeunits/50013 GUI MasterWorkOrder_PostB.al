codeunit 50013 "GUI Master Work Ord.-Post B."
{

    TableNo = "GUI-to-BC Master WO Line";
    trigger OnRun()
    begin
        IF RunningResiliency THEN
            Rec.LOCKTABLE;

        CarryOutMasterWOLineAction(Rec);

    end;

    var

    VAR
        TempMasterWorkOrdLine: Record "GUI-to-BC Master WO Line" temporary;
        TempFailedMasterWOLine: Record "GUI-to-BC Master WO Line" temporary;
        BufferChekLine: Codeunit GUI_MasterWorkOrdCheckLine;
        BufferPostLine: Codeunit GUIMasterWorkOrd_PostLine;
        Mgt: Codeunit GUItoBCManagement;
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';
        CounterFailed: Integer;
        HideDialog: Boolean;
        RunningResiliency: Boolean;

    procedure CarryOutBatchAction(VAR Rec: Record "GUI-to-BC Master WO Line");
    VAR
        MasterWOLine: Record "GUI-to-BC Master WO Line";
    begin
        //003 Start
        MasterWOLine.COPY(Rec);
        Code(MasterWOLine);
        Rec := MasterWOLine;
        //003 end
    end;

    local procedure Code(VAR MasterWorkOrdLine: Record "GUI-to-BC Master WO Line");
    begin
        WITH MasterWorkOrdLine DO begin
            //002 SETFILTER("Processing Status",'<>%1',"Processing Status"::Processed);
            //003 SETRANGE("Processing Status","Processing Status"::"In Progress"); //002
            SETFILTER("Processing Status", '>%1', "Processing Status"::New);
            SETRANGE(Processed, FALSE);
            //003 end

            IF NOT RunningResiliency THEN //003
                LOCKTABLE;

            ProcessLines(MasterWorkOrdLine);
        end;
    end;

    local procedure ProcessLines(VAR MasterWorkOrdLine: Record "GUI-to-BC Master WO Line");
    VAR
        TempMasterWorkOrdLine: Record "GUI-to-BC Master WO Line" temporary;
        SkippedLine: Boolean;
    begin
        WITH MasterWorkOrdLine DO begin
            IF NOT FIND('=><') THEN begin
                "Entry No." := 0;
                COMMIT;
                EXIT;
            end;

            // Check lines
            LineCount := 0;
            StartLineNo := "Entry No.";
            NoOfRecords := COUNT;
            BufferChekLine.SetBatchMode(TRUE);
            REPEAT
                LineCount := LineCount + 1;
                //UpdateDialog(RefPostingState::"Checking lines",LineCount,NoOfRecords);
                CheckLine(MasterWorkOrdLine);
                //003 TempMasterWorkOrdLine := MasterWorkOrdLine2;
                //003 TempMasterWorkOrdLine.INSERT;
                IF NEXT = 0 THEN
                    FINDFIRST;
            UNTIL "Entry No." = StartLineNo;

            // Post lines
            LineCount := 0;
            LastDocNo := '';
            LastPostedDocNo := '';
            //003 Start
            SkippedLine := FALSE;
            CounterFailed := 0;
            //003 end

            SETRANGE("Ready for Processing", TRUE);
            FINDSET(TRUE, FALSE);
            REPEAT
                //003 Start
                IF RunningResiliency THEN begin
                    COMMIT;
                    CLEARLASTERROR;
                    IF NOT TryCarryOutMasterWOLineAction(MasterWorkOrdLine) THEN begin
                        UpdateErrorMsg(GETLASTERRORTEXT);
                        MODIFY;
                        SetFailedMasterWOLine(MasterWorkOrdLine);
                        CounterFailed += 1;
                    end;
                    COMMIT;
                end ELSE
                    CarryOutMasterWOLineAction(MasterWorkOrdLine);
            //003 end
            UNTIL NEXT = 0;

            UpdateAndDeleteLines(MasterWorkOrdLine);

            COMMIT;
            CLEAR(BufferChekLine);
            CLEAR(BufferPostLine);
            //003 CLEARMARKS;
        end;

        IF SkippedLine THEN
            IF GUIALLOWED AND NOT HideDialog THEN
                MESSAGE(SkippedLineMsg);
    end;

    local procedure CheckLine(VAR MasterWorkOrdLine: Record "GUI-to-BC Master WO Line");
    VAR
        MasterWOLineToUpdate: Record "GUI-to-BC Master WO Line";
    begin
        MasterWOLineToUpdate.COPY(MasterWorkOrdLine);
        BufferChekLine.RunCheck(MasterWOLineToUpdate);
        //003 Start
        MasterWorkOrdLine.COPY(MasterWOLineToUpdate);
        MasterWorkOrdLine.MODIFY;
        //003 end
    end;

    local procedure CheckDocumentNo(VAR MasterWorkOrdLine: Record "GUI-to-BC Master WO Line");
    begin
    end;

    local procedure CarryOutMasterWOLineAction(VAR MasterWOLine: Record "GUI-to-BC Master WO Line"): Boolean;
    VAR
        MasterWOLine2: Record "GUI-to-BC Master WO Line";
    begin
        WITH MasterWOLine DO begin
            IF "Validation Error" THEN
                EXIT(FALSE);

            //003 Start
            IF NOT "Ready for Processing" THEN
                EXIT(FALSE);
            //003 end

            LineCount := LineCount + 1;

            CheckDocumentNo(MasterWOLine);

            MasterWOLine2.COPY(MasterWOLine);
            BufferPostLine.RunWithoutCheck(MasterWOLine2);
        end;
        EXIT(TRUE);
    end;

    local procedure UpdateAndDeleteLines(VAR MasterWorkOrdLine: Record "GUI-to-BC Master WO Line");
    VAR
        MasterWorkOrdLine2: Record "GUI-to-BC Master WO Line";
        MasterWorkOrdLine3: Record "GUI-to-BC Master WO Line";
    begin
        MasterWorkOrdLine2.COPY(MasterWorkOrdLine);
        MasterWorkOrdLine2.SETFILTER("Item No.", '<>%1', '');
        IF MasterWorkOrdLine2.FINDLAST THEN; // Remember the last line

        //002 Start
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Master WO Line") THEN
            EXIT;
        //002 end

        MasterWorkOrdLine3.COPY(MasterWorkOrdLine);
        MasterWorkOrdLine3.SETCURRENTKEY("Order Date", "Order Shift", "Item No.", "Production Line No."); //003
                                                                                                          //003 Start
                                                                                                          //MasterWorkOrdLine3.SETRANGE("Processing Status",MasterWorkOrdLine3."Processing Status"::Processed);
        MasterWorkOrdLine3.SETRANGE("Ready for Processing");
        MasterWorkOrdLine3.SETRANGE(Processed, TRUE);
        //003 end
        IF NOT MasterWorkOrdLine3.ISEMPTY THEN
            MasterWorkOrdLine3.DELETEALL;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean);
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetRunningResiliency();
    begin
        RunningResiliency := TRUE; //003
    end;

    procedure SetTryParam(TryLineCount: Integer; VAR TryFailedMasterWOLine: Record "GUI-to-BC Master WO Line");
    begin
        //003 Start
        SetRunningResiliency;

        LineCount := TryLineCount;
        IF TryFailedMasterWOLine.FINDSET THEN
            REPEAT
                TempFailedMasterWOLine := TryFailedMasterWOLine;
                TempFailedMasterWOLine.INSERT;
            UNTIL TryFailedMasterWOLine.NEXT = 0;
        //003 end
    end;

    procedure GetTryParam(VAR TryLineCount: Integer);
    begin
        //003 Start
        TryLineCount := LineCount;
        //003 end
    end;

    procedure TryCarryOutMasterWOLineAction(VAR MasterWOLine: Record "GUI-to-BC Master WO Line"): Boolean;
    VAR
        CarryOutAction: Codeunit "GUI Master Work Ord.-Post B.";
    begin
        //003 Start
        CarryOutAction.SetTryParam(LineCount, TempFailedMasterWOLine);
        IF CarryOutAction.RUN(MasterWOLine) THEN begin
            CarryOutAction.GetTryParam(LineCount);
            EXIT(TRUE);
        end;
        EXIT(FALSE);
        //003 end
    end;

    local procedure SetFailedMasterWOLine(NewFailedMasterWOLine: Record "GUI-to-BC Master WO Line");
    begin
        //003 Start
        TempFailedMasterWOLine := NewFailedMasterWOLine;
        TempFailedMasterWOLine.INSERT;
        //003 end
    end;

    procedure GetFailedCounter(): Integer;
    begin
        //003 Start
        EXIT(CounterFailed);
        //003 end
    end;

}