codeunit 50008 "GUI Inventory Adjmt.-Post"
{
    TableNo = "GUI-to-BC Invt. Adjmt. Line";

    trigger OnRun()
    var
        InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line";
    begin
        InvtAdjmtLine.COPY(Rec);
        Code(InvtAdjmtLine);

        Rec := InvtAdjmtLine;


    end;

    var
        ConfMsgProcessText: TextConst ENU = 'Do you want to process the worksheet lines and create item journal lines?';
        ConfMsgProcessPostText: TextConst ENU = 'Do you want to process the worksheet lines and create and post item journal lines?';
        NothingToProcessText: TextConst ENU = 'There is nothing to post.';
        ProcessedText: TextConst ENU = 'The inventory adjustment lines were successfully posted.';
        Mgt: Codeunit 50010;
        ConfMsgText: Text;
        NoProcessingResiliencyText: TextConst ENU = 'Stop and Show First Error?';
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';

    local procedure Code(VAR InvtAdjmtLine: Record "GUI-to-BC Invt. Adjmt. Line");
    VAR
        ProcessBatch: Codeunit 50007;
        FailedCounter: Integer;
        NoProcessingResiliency: Boolean;
    begin
        WITH InvtAdjmtLine DO begin
            SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003

            //002 Start
            IF Mgt.IsAutomaticInvtAdjmtEnabled THEN
                ConfMsgText := ConfMsgProcessPostText
            ELSE
                ConfMsgText := ConfMsgProcessText;
            //002 end

            IF GUIALLOWED THEN begin
                IF NOT CONFIRM(ConfMsgText, FALSE) THEN
                    EXIT;

                //003 Start
                NoProcessingResiliency := TRUE;
                //>>CONFIRM(NoProcessingResiliencyText, FALSE);
                IF NOT NoProcessingResiliency THEN
                    ProcessBatch.SetRunningResiliency;
                //003 end
            end;
            //003 Start
            ProcessBatch.CarryOutBatchAction(InvtAdjmtLine);
            FailedCounter := ProcessBatch.GetFailedCounter;
            //003 end

            IF GUIALLOWED THEN
                //003 Start
                IF FailedCounter <> 0 THEN
                    MESSAGE(SkippedLineMsg)
                ELSE IF "Entry No." = 0 THEN
                    //003 end
                    MESSAGE(NothingToProcessText)
                ELSE
                    MESSAGE(ProcessedText);

            IF NOT FIND('=><') THEN begin
                RESET;
                FILTERGROUP(2);
                //003 SETFILTER("Processing Status",'<>%1',"Processing Status"::Processed);
                SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003
                FILTERGROUP(0);
            end;
        end;
    end;


}