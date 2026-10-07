codeunit 50033 "GUI Shipment Line-Post"
{
    TableNo = "GUI-to-BC Sales Line";

    trigger OnRun()
    var
        GUISalesLine: Record "GUI-to-BC Sales Line";
    BEGIN
        GUISalesLine.COPY(Rec);
        Code(GUISalesLine);

        Rec := GUISalesLine;
    END;


    var
        ConfMsgProcessText: TextConst ENU = 'Do you want to process the worksheet lines and update sales order lines?';
        ConfMsgProcessPostText: TextConst ENU = 'Do you want to process the worksheet lines and update and post sales lines?';
        NothingToProcessText: TextConst ENU = 'There is nothing to post.';
        ProcessedText: TextConst ENU = 'The Sales lines were successfully posted.';
        Mgt: Codeunit GUItoBCManagement;
        ConfMsgText: Text;
        NoProcessingResiliencyText: TextConst ENU = 'Stop and Show First Error?';
        SkippedLineMsg: TextConst ENU = 'One or more lines has not been processed.';

    LOCAL PROCEDURE Code(VAR GUISalesLine: Record "GUI-to-BC Sales Line");
    VAR
        ProcessBatch: Codeunit GUIShipmentLine_PostBatch;
        FailedCounter: Integer;
        NoProcessingResiliency: Boolean;
    BEGIN
        WITH GUISalesLine DO BEGIN
            SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003

            IF Mgt.IsAutomaticSalesDocEnabled THEN
                ConfMsgText := ConfMsgProcessPostText
            ELSE
                ConfMsgText := ConfMsgProcessText;
            //002 End

            IF GUIALLOWED THEN BEGIN
                IF NOT CONFIRM(ConfMsgText, FALSE) THEN
                    EXIT;

                NoProcessingResiliency := CONFIRM(NoProcessingResiliencyText, FALSE);
                IF NOT NoProcessingResiliency THEN
                    ProcessBatch.SetRunningResiliency;

            END;

            ProcessBatch.CarryOutBatchAction(GUISalesLine);
            FailedCounter := ProcessBatch.GetFailedCounter;


            IF GUIALLOWED THEN
                IF FailedCounter <> 0 THEN
                    MESSAGE(SkippedLineMsg)
                ELSE IF "Entry No." = 0 THEN
                    MESSAGE(NothingToProcessText)
                ELSE
                    MESSAGE(ProcessedText);

            IF NOT FIND('=><') THEN BEGIN
                RESET;
                FILTERGROUP(2);
                SETFILTER("Processing Status", '>%1', "Processing Status"::New); //003
                FILTERGROUP(0);
            END;
        END;
    END;


}