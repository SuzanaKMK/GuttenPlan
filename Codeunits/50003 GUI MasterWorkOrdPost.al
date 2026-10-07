codeunit 50003 "GUI Master Work Ord.-Post"
{
    TableNo = "GUI-to-BC Master WO Line";

    trigger OnRun()
    var
        MasterWorkOrdLine: Record "GUI-to-BC Master WO Line";
    BEGIN
        MasterWorkOrdLine.COPY(Rec);
        Code(MasterWorkOrdLine);

        Rec := MasterWorkOrdLine;
    END;


    var
        ConfMsgProcessText: TextConst ENU = 'Do you want to process the worksheet lines and create Production Orders?';
        ConfMsgProcessPostText: TextConst ENU = 'Do you want to process the worksheet lines and create Production Order?';
        NothingToProcessText: TextConst ENU = 'There is nothing to post.';
        ProcessedText: TextConst ENU = 'The Master Work order lines were successfully posted.';
        Mgt: Codeunit GUItoBCManagement;
        ConfMsgText: Text;
        NoProcessingResiliencyText: TextConst ENU = 'Stop and Show First Error?';
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';



    LOCAL PROCEDURE Code(VAR MasterWorkOrdLine: Record 50000);
    VAR
        ProcessBatch: Codeunit "GUI Master Work Ord.-Post B.";
        FailedCounter: Integer;
        NoProcessingResiliency: Boolean;
    BEGIN
        WITH MasterWorkOrdLine DO BEGIN
            SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003

            ConfMsgText := ConfMsgProcessText;

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
            ProcessBatch.CarryOutBatchAction(MasterWorkOrdLine);
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