codeunit 50004 "GUI Master Work Ord. Integr."
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;


    [EventSubscriber(ObjectType::Table, Database::"GUI-to-BC Master WO Line", 'OnMoveMasterWorkOrderLine', '', false, false)]
    LOCAL PROCEDURE MasterWOLineOnMoveMasterWorkOrderLine(VAR Sender: Record 50000; ToRecordID: RecordID);
    VAR
        ProdOrder: Record 5405;
        RecRef: RecordRef;
    BEGIN
        IF ToRecordID.TABLENO <> DATABASE::"Production Order" THEN
            EXIT;

        RecRef := ToRecordID.GETRECORD;
        IF RecRef.ISTEMPORARY THEN
            EXIT;

        RecRef.SETTABLE(ProdOrder);

        ProdOrder.GET(ProdOrder.Status, ProdOrder."No.");


        IF Sender."Ready for Processing" AND
           NOT Sender."Validation Error"
        THEN BEGIN

            Sender.SetProcessingStatus(Sender."Processing Status"::Processed);
            Sender."Prod. Order Status" := ProdOrder.Status;
            Sender."Prod. Order No." := ProdOrder."No.";
            Sender.MODIFY(TRUE);
        END;
    END;

}