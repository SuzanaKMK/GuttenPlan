codeunit 50000 GUI_MasterWorkOrdCheckLine
{
    TableNo = "GUI-to-BC Master WO Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        IsBatchMode: Boolean;
        DoesnotExistText: TextConst ENU = '%1 %2 does not exist.';
        MustBeSpecifiedText: TextConst ENU = '%1 must be specified.';
        MustnotBeText: TextConst ENU = '%1 must not %2.';
        MustBeText: TextConst ENU = '%1 %2 %3 must be %4.';
        ItemDoesnotHaveBOMText: TextConst ENU = 'Item No. %1 does not have Production BOM specified.';


    procedure RunCheckLines(VAR MasterWorkOrderLine: Record "GUI-to-BC Master WO Line");
    VAR
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
    begin
        WITH MasterWorkOrderLine DO begin
            //003 Start
            if not FIND('=><') then
                exit;
            //003 end

            SetBatchMode(TRUE);
            LineCount := 0;
            StartLineNo := "Entry No.";
            REPEAT
                LineCount := LineCount + 1;
                RunCheck(MasterWorkOrderLine);
                if NEXT = 0 then
                    FIND('-');
            UNTIL "Entry No." = StartLineNo;
            NoOfRecords := LineCount;
            SetBatchMode(FALSE);
        end;
    end;

    procedure RunCheck(VAR MasterWorkOrderLine: Record "GUI-to-BC Master WO Line"): Boolean;
    VAR
        UpdateRec: Boolean;
        OK: Boolean;
    begin
        //>>  WITH MasterWorkOrderLine DO begin
        if MasterWorkOrderLine.FIndset() then begin
            if MasterWorkOrderLine.EmptyLine then
                exit;

            //004 Start
            if not MasterWorkOrderLine.IsCheckLineAllowed then
                exit;
            //004 end

            if MasterWorkOrderLine."Validation Error" then begin
                MasterWorkOrderLine.SetProcessingStatus(MasterWorkOrderLine."Processing Status"::"In Progress"); //004
                UpdateRec := TRUE;
            end;

            //004 Start
            if not CheckLine(MasterWorkOrderLine) then begin
                MasterWorkOrderLine.SetProcessingStatus(MasterWorkOrderLine."Processing Status"::Error);
                UpdateRec := TRUE;
            end;
            //004 end

            if not MasterWorkOrderLine."Validation Error" then begin
                MasterWorkOrderLine.SetProcessingStatus(MasterWorkOrderLine."Processing Status"::Ready); //004
                UpdateRec := TRUE;
            end;

            if UpdateRec then
                MasterWorkOrderLine.Modify();
        end;

        exit(TRUE);
    end;

    procedure CheckLine(VAR MasterWorkOrderLine: Record "GUI-to-BC Master WO Line"): Boolean;
    begin
        //004 Start
        //>>  WITH MasterWorkOrderLine DO begin
        if MasterWorkOrderLine.FindFirst() then begin
            if MasterWorkOrderLine."Order Date" = 0D then
                exit(
                  AddError(strsubstno(MustBeSpecifiedText, MasterWorkOrderLine.FieldCaption("Order Date")), MasterWorkOrderLine));

            if MasterWorkOrderLine."Item No." = '' then
                exit(
                  AddError(strsubstno(MustBeSpecifiedText, MasterWorkOrderLine.FieldCaption("Item No.")), MasterWorkOrderLine))
            ELSE
                if not CheckItemNo(MasterWorkOrderLine) then
                    exit(FALSE);

            if MasterWorkOrderLine."Routing No." = '' then
                exit(
                  AddError(strsubstno(MustBeSpecifiedText, MasterWorkOrderLine.FieldCaption("Routing No.")), MasterWorkOrderLine))
            ELSE
                if not CheckRoutingNo(MasterWorkOrderLine) then
                    exit(FALSE);


        end;

        exit(TRUE);
        //004 end
    end;

    local procedure CheckItemNo(VAR MasterWorkOrderLine: Record "GUI-to-BC Master WO Line"): Boolean;
    VAR
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        RtngHeader: Record "Routing Header";
        CheckDone: Boolean;
    begin
        //>>  WITH MasterWorkOrderLine DO begin
        if MasterWorkOrderLine.FindFirst() then begin
            if not Item.get(MasterWorkOrderLine."Item No.") then
                exit(
                  AddError(strsubstno(DoesnotExistText, MasterWorkOrderLine.FieldCaption("Item No."), MasterWorkOrderLine."Item No."), MasterWorkOrderLine));

            if Item.Blocked then
                exit(
                  AddError(strsubstno(MustnotBeText, Item.FieldCaption(Blocked), FORMAT(Item.Blocked)), MasterWorkOrderLine));

            if not Item.IsMfgItem then
                exit(
                  AddError(strsubstno(MustBeText, Item.tablecaption, Item."No.", Item.FieldCaption("Replenishment System"), FORMAT(Item."Replenishment System"::"Prod. Order")), MasterWorkOrderLine));

            if not Item.HasBOM then
                exit(
                  AddError(strsubstno(ItemDoesnotHaveBOMText, Item."No."), MasterWorkOrderLine));

            if Item."Base Unit of Measure" = '' then
                exit(
                  AddError(strsubstno(MustBeSpecifiedText, Item.FieldCaption("Base Unit of Measure")), MasterWorkOrderLine));

            //002 ProdBOMHeader.get(Item."Production BOM No.");
            if not ProdBOMHeader.get(Item."Production BOM No.") then
                exit(
                  AddError(strsubstno(DoesnotExistText, Item.FieldCaption("Production BOM No."), Item."Production BOM No."), MasterWorkOrderLine));
            //002 end

            if ProdBOMHeader.Status <> ProdBOMHeader.Status::Certified then
                exit(
                  AddError(strsubstno(MustBeText, ProdBOMHeader.tablecaption, ProdBOMHeader."No.", ProdBOMHeader.FieldCaption(Status), FORMAT(ProdBOMHeader.Status::Certified)), MasterWorkOrderLine));

            if ProdBOMHeader."Unit of Measure Code" = '' then
                exit(
                  AddError(strsubstno(MustBeSpecifiedText, ProdBOMHeader.FieldCaption("Unit of Measure Code")), MasterWorkOrderLine));


        end;

        exit(TRUE);
    end;

    local procedure CheckRoutingNo(VAR MasterWorkOrderLine: Record "GUI-to-BC Master WO Line"): Boolean;
    VAR
        RtngHeader: Record "Routing Header";
        CheckDone: Boolean;
    begin
        //>> WITH MasterWorkOrderLine DO begin
        if MasterWorkOrderLine.FindSet() then begin
            if not RtngHeader.get(MasterWorkOrderLine."Routing No.") then
                exit(
                  AddError(strsubstno(DoesnotExistText, MasterWorkOrderLine.FieldCaption("Routing No."), MasterWorkOrderLine."Routing No."), MasterWorkOrderLine));

            if RtngHeader.Status <> RtngHeader.Status::Certified then
                exit(
                  AddError(strsubstno(MustBeText, RtngHeader.tablecaption, RtngHeader."No.", RtngHeader.FieldCaption(Status), FORMAT(RtngHeader.Status::Certified)), MasterWorkOrderLine));
        end;
        exit(TRUE);
    end;

    procedure SetBatchMode(NewBatchMode: Boolean);
    begin
        IsBatchMode := NewBatchMode;
    end;

    local procedure AddError(Text: Text[250]; VAR MasterWorkOrderLine: Record "GUI-to-BC Master WO Line"): Boolean;
    begin
        //>>WITH MasterWorkOrderLine DO begin
        if MasterWorkOrderLine.FindSet() then begin
            MasterWorkOrderLine.UpdateErrorMsg(Text); //004 Moved to function //
            MasterWorkOrderLine.Modify();
        end;
    end;



}