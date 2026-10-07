report 50030 "GUI Output Line - Post (JQ)"
{
    ProcessingOnly = true;
    Caption = 'GUI Output Line - Post (JQ)';
    UseRequestPage = false;

    trigger OnPreReport()
    var
        ErrMsg: Text;
    begin
        ErrMsg := GUI2NAVIntegrationWS.ProductionOutput('');

    end;

    var

    VAR
        OutputBuf: Record "GUI-to-BC Output Line";
        OutputCheckLine: Codeunit GUI_OutputCheckLine;
        GUI2NAVIntegrationWS: Codeunit GUItoBC_Integration_WS;

    local procedure Code(VAR OutputLine: Record 50004);
    VAR
        OutputPostBatch: Codeunit GUIOutputLinePostLine;
    begin
        WITH OutputLine DO begin
            OutputPostBatch.RUN(OutputLine);

            IF NOT FIND('=><') THEN begin
                RESET;
            end;
        end;
    end;
}