Codeunit 50010 GUItoBCManagement
{

    trigger OnRun()
    var

    begin

    end;




    VAR
        Setup: Record "GUI-to-BC Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SetupRead: Boolean;
        MustNotBeText: TextConst ENU = 'must not be "%1".';
        SalesSetupRead: Boolean;

    local procedure GetSetup();
    begin
        IF NOT SetupRead THEN begin
            Setup.GET;
            SetupRead := TRUE;
        end;
    end;

    procedure IsArchivingEnabled(TableID: Integer): Boolean;
    begin
        GetSetup;
        IF Setup."Enable Auto Archive" THEN
            CASE TableID OF
                DATABASE::"GUI-to-BC Master WO Line":
                    EXIT(Setup."Auto Archive Master Work Order");
                DATABASE::"GUI-to-BC Invt. Adjmt. Line":
                    EXIT(Setup."Auto Archive Invt. Adjustment");
                DATABASE::"GUI-to-BC Purchase Line":
                    EXIT(Setup."Auto Archive Purchase");
                DATABASE::"GUI-to-BC Sales Line":
                    EXIT(Setup."Auto Archive Sales");
                DATABASE::"GUI-to-BC Output Line":
                    EXIT(Setup."Auto Archive Output");
            end;
    end;

    procedure IsAutomaticPurchDocEnabled(): Boolean;
    begin
        //003 Start
        GetSetup;
        EXIT(Setup."Enable Auto Purch. Post");
        //003 end
    end;

    procedure IsAutomaticSalesDocEnabled(): Boolean;
    begin
        //004 Start
        GetSetup;
        EXIT(Setup."Enable Auto Sales Post");
        //004 end
    end;

    procedure IsAutomaticInvtAdjmtEnabled(): Boolean;
    begin
        //005 Start
        GetSetup;
        EXIT(Setup."Enable Auto Invt. Adjmt. Post");
        //005 end
    end;

    procedure IsAutomaticProdOutputEnabled(): Boolean;
    begin
        //006 Start
        GetSetup;
        EXIT(Setup."Enable Auto Prod. Output Post");
        //006 end
    end;

    procedure SetPurchDocPostingOptions(VAR PurchHeader: Record "Purchase Header");
    begin
        //003 Start
        GetSetup;
        IF Setup."Purchase Post Action" = Setup."Purchase Post Action"::" " THEN
            Setup.FIELDERROR("Purchase Post Action", STRSUBSTNO(MustNotBeText, FORMAT(Setup."Purchase Post Action")));

        WITH PurchHeader DO begin
            Receive :=
              Setup."Purchase Post Action" IN [Setup."Purchase Post Action"::Receive,
                                               Setup."Purchase Post Action"::"Receive and Invoice"];
            Invoice :=
              Setup."Purchase Post Action" = Setup."Purchase Post Action"::"Receive and Invoice";
        end;
        //003 end
    end;

    procedure SetSalesDocPostingOptions(VAR SalesHeader: Record "Sales Header");
    begin
        //004 Start
        GetSetup;
        IF Setup."Sales Post Action" = Setup."Sales Post Action"::" " THEN
            Setup.FIELDERROR("Sales Post Action", STRSUBSTNO(MustNotBeText, FORMAT(Setup."Sales Post Action")));

        WITH SalesHeader DO begin
            Ship :=
              Setup."Sales Post Action" IN [Setup."Sales Post Action"::Ship,
                                            Setup."Sales Post Action"::"Ship and Invoice"];
            Invoice :=
              Setup."Sales Post Action" = Setup."Sales Post Action"::"Ship and Invoice";
        end;
        //004 end
    end;

    procedure SetUpNewItemJnlLine(VAR Rec: Record "Item Journal Line"; LastItemJnlLine: Record "Item Journal Line");
    VAR
        MfgSetup: Record "Manufacturing Setup";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        UserMgt: Codeunit "User Setup Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeries: Codeunit "No. Series";
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        //006 Start
        WITH Rec DO begin
            TESTFIELD("Journal Template Name");
            TESTFIELD("Journal Batch Name");

            ItemJnlTemplate.GET("Journal Template Name");
            ItemJnlBatch.GET("Journal Template Name", "Journal Batch Name");
            MfgSetup.GET;

            ItemJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
            ItemJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
            IF ItemJnlLine.FINDFIRST THEN begin
                "Posting Date" := LastItemJnlLine."Posting Date";
                "Document Date" := LastItemJnlLine."Posting Date";
                IF (ItemJnlTemplate.Type IN
                    [ItemJnlTemplate.Type::Consumption, ItemJnlTemplate.Type::Output])
                THEN begin
                    IF NOT MfgSetup."Doc. No. Is Prod. Order No." THEN
                        "Document No." := LastItemJnlLine."Document No."
                end ELSE
                    "Document No." := LastItemJnlLine."Document No.";
            end ELSE begin
                "Posting Date" := WORKDATE;
                "Document Date" := WORKDATE;
                IF ItemJnlBatch."No. Series" <> '' THEN begin
                    CLEAR(NoSeriesMgt);
                    "Document No." := NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", "Posting Date", FALSE);
                end;
                IF (ItemJnlTemplate.Type IN
                    [ItemJnlTemplate.Type::Consumption, ItemJnlTemplate.Type::Output]) AND
                   NOT MfgSetup."Doc. No. Is Prod. Order No."
                THEN
                    IF ItemJnlBatch."No. Series" <> '' THEN begin
                        CLEAR(NoSeriesMgt);
                        "Document No." := NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", "Posting Date", FALSE);
                    end;
            end;

            "Recurring Method" := LastItemJnlLine."Recurring Method";
            "Entry Type" := LastItemJnlLine."Entry Type";
            "Source Code" := ItemJnlTemplate."Source Code";
            "Reason Code" := ItemJnlBatch."Reason Code";
            "Posting No. Series" := ItemJnlBatch."Posting No. Series";
            IF ItemJnlTemplate.Type = ItemJnlTemplate.Type::Revaluation THEN begin
                "Value Entry Type" := "Value Entry Type"::Revaluation;
                "Entry Type" := "Entry Type"::"Positive Adjmt.";
            end;

            CASE "Entry Type" OF
                "Entry Type"::Purchase:
                    "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter);
                "Entry Type"::Sale:
                    "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter);
                "Entry Type"::Output:
                    ;
            end;

            IF Location.GET("Location Code") THEN
                IF Location."Directed Put-away and Pick" THEN
                    "Location Code" := '';
        end;
        //006 end
    end;

    procedure IsBOLPrintingonShipmentPostEnabled(): Boolean;
    begin

        GetSetup;
        EXIT(Setup."Print BOL on Shipment Post");

    end;

    local procedure GetSalesSetup();
    begin
        //007 Start
        //008 Start
        //IF NOT SetupRead THEN begin
        IF NOT SalesSetupRead THEN begin
            //008 end
            SalesSetup.GET;
            SalesSetupRead := TRUE;
        end;
        //007 end
    end;

    procedure GetBOLReportID(): Integer;
    begin

        GetSalesSetup;
        EXIT(SalesSetup.KMK_BOLReportNo);

    end;

}
