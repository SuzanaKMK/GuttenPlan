report 50002 "GUI Master Work Ord.-Post (JQ)"
{
    Caption = 'GUI Master Work Ord.-Post (JQ)';

    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnPreReport()
    var
        ErrMsg: Text;
    begin


        WITH MasterWorkOrderBuf DO begin
            RESET;

            SETRANGE("Processing Status", "Processing Status"::"In Progress"); //002
            IF FIND('-') THEN begin
                MasterWorkOrderCheckLine.RunCheckLines(MasterWorkOrderBuf);

                SETRANGE("Ready for Processing", TRUE);
                IF FIND('-') THEN
                    Code(MasterWorkOrderBuf);
            end;
        end;

        ErrMsg := GUI2NAVIntegrationWS.MasterWorkOrder('', 0, '', '');

    end;


    var

        MasterWorkOrderBuf: Record "GUI-to-BC Master WO Line";
        MasterWorkOrderCheckLine: Codeunit 50000;
        GUI2NAVIntegrationWS: Codeunit GUItoBC_Integration_WS;


    local procedure Code(VAR MasterWorkOrderLine: Record 50000);
    VAR
        MasterWorkOrdPostBatch: Codeunit 50001;
    begin
        WITH MasterWorkOrderLine DO begin
            MasterWorkOrdPostBatch.RUN(MasterWorkOrderLine);

            IF NOT FIND('=><') THEN begin
                RESET;
            end;
        end;
    end;

}