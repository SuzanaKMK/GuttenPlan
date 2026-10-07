codeunit 50028 "GUI Purchase Line-Post"
{
    TableNo = "GUI-to-BC Purchase Line";

    trigger OnRun()
    var
        GUItoBCPurchaseLine: Record "GUI-to-BC Purchase Line";
    begin
        GUItoBCPurchaseLine.COPY(Rec);
        Code(GUItoBCPurchaseLine);

        Rec := GUItoBCPurchaseLine;
    end;


    var
        ConfMsgProcessText: TextConst ENU = 'Do you want to process the worksheet lines and update Purchase Order?';
        ConfMsgProcessPostText: TextConst ENU = 'Do you want to process the worksheet lines and create and post Purchase Receipt?';
        NothingToProcessText: TextConst ENU = 'There is nothing to post.';
        ProcessedText: TextConst ENU = 'The Purchase order lines were successfully posted.';
        Mgt: Codeunit GUItoBCManagement;
        ConfMsgText: Text;
        NoProcessingResiliencyText: TextConst ENU = 'Stop and Show First Error?';
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';

    LOCAL PROCEDURE Code(VAR BufferLine: Record "GUI-to-BC Purchase Line");
    VAR
        ProcessBatch: Codeunit GUIPurchaseLine_PostBatch;
        FailedCounter: Integer;
        NoProcessingResiliency: Boolean;
    BEGIN
        WITH BufferLine DO BEGIN
            SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003

            //002 Start
            IF Mgt.IsAutomaticPurchDocEnabled THEN
                ConfMsgText := ConfMsgProcessPostText
            ELSE
                ConfMsgText := ConfMsgProcessText;
            //002 End

            IF GUIALLOWED THEN BEGIN
                IF NOT CONFIRM(ConfMsgText, FALSE) THEN
                    EXIT;

                //003 Start
                NoProcessingResiliency := True;
                //>> NoProcessingResiliency := CONFIRM(NoProcessingResiliencyText, FALSE);
                IF NOT NoProcessingResiliency THEN
                    ProcessBatch.SetRunningResiliency;
                //003 End
            END;
            //003 Start
            ProcessBatch.CarryOutBatchAction(BufferLine);
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
                //003 SETFILTER("Processing Status",'<>%1',"Processing Status"::Processed);
                SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003
                FILTERGROUP(0);
            END;
        END;
    END;

}