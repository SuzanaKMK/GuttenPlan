codeunit 50038 "GUI Output Line-Post"
{

    TableNo = "GUI-to-BC Output Line";

    trigger OnRun()
    var
        OutputLine: Record "GUI-to-BC Output Line";
    begin
        OutputLine.COPY(Rec);
        Code(OutputLine);

        Rec := OutputLine;
    end;

    var
        ConfMsgProcessText: TextConst ENU = 'Do you want to process the worksheet lines and create Output journal lines?';
        ConfMsgProcessPostText: TextConst ENU = 'Do you want to process the worksheet lines and create and post output journal lines?';
        NothingToProcessText: TextConst ENU = 'There is nothing to post.';
        ProcessedText: TextConst ENU = 'The Output lines were successfully posted.';
        Mgt: Codeunit GUItoBCManagement;
        ConfMsgText: Text;
        NoProcessingResiliencyText: TextConst ENU = 'Stop and Show First Error?';
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';



    procedure Code(var OutputLine: Record "GUI-to-BC Output Line")
    var
        ProcessBatch: Codeunit "GUI Output Line-Post Batch";
        FailedCounter: Integer;
        NoProcessingResiliency: Boolean;
    BEGIN
        WITH OutputLine DO BEGIN
            SETCURRENTKEY("Entry No."); //003
            SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003

            //002 Start
            IF Mgt.IsAutomaticProdOutputEnabled THEN
                ConfMsgText := ConfMsgProcessPostText
            ELSE
                ConfMsgText := ConfMsgProcessText;
            //002 End

            IF GUIALLOWED THEN BEGIN
                IF NOT CONFIRM(ConfMsgText, FALSE) THEN
                    EXIT;

                //003 Start
                NoProcessingResiliency := CONFIRM(NoProcessingResiliencyText, FALSE);
                IF NOT NoProcessingResiliency THEN
                    ProcessBatch.SetRunningResiliency;
                //003 End
            END;
            //003 Start
            ProcessBatch.CarryOutBatchAction(OutputLine);
            FailedCounter := ProcessBatch.GetFailedCounter;
            //003 End

            IF GUIALLOWED THEN
                //003 Start
                IF FailedCounter <> 0 THEN
                    MESSAGE(SkippedLineMsg)
                ELSE IF "Entry No." = 0 THEN
                    //003 End
                    MESSAGE(NothingToProcessText)
                ELSE
                    MESSAGE(ProcessedText);

            IF NOT FIND('=><') THEN BEGIN
                RESET;
                FILTERGROUP(2);

                SETFILTER("Processing Status", '>%1', "Processing Status"::New);
                FILTERGROUP(0);
            END;
        END;
    END;



}