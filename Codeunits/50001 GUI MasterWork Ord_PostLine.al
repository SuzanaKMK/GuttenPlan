codeunit 50001 GUIMasterWorkOrd_PostLine
{
    TableNo = "GUI-to-BC Master WO Line";
    Permissions = TableData 5405 = rimd,
                TableData 5406 = rimd,
                TableData 5407 = rimd,
                TableData 5409 = rimd,
                TableData 5414 = rimd,
                TableData 5415 = rimd,
                TableData 5416 = rimd,
                TableData 50000 = rm,
                TableData 99000771 = r,
                TableData 99000772 = r,
                TableData 99000776 = r,
                TableData 99000779 = r;

    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    var
        TempProdOrder: Record 5405 temporary;
        MfgSetup: Record 99000765;
        GlobalMasterWOLine: Record 50000;
        GlobalMasterWOLineArch: Record 50010;
        TempMasterWOLineBuf: Record 50000 temporary;
        MasterWorkOrdCheckLine: Codeunit 50000;
        CalcProdOrder: Codeunit 99000773;
        Mgt: Codeunit 50010;
        IntegrMgt: Codeunit 50016;
        ErrMsgTxt: Text;
        FirstProdOrderNo: Code[20];
        NextEntryNo: Integer;
        MfgSetupRead: Boolean;
        PrintOrder: Boolean;
        GUIText001: TextConst ENU = 'Prod. Order %1 wasn''t refreshed because of errors encountered.';

    procedure RunWithCheck(VAR MasterWorkOrderBuf2: Record 50000);
    VAR
        MasterWorkOrderBuf: Record 50000;
    begin
        MasterWorkOrderBuf.COPY(MasterWorkOrderBuf2);
        Code(MasterWorkOrderBuf, TRUE);
        MasterWorkOrderBuf2 := MasterWorkOrderBuf;
    end;

    procedure RunWithoutCheck(VAR MasterWorkOrderBuf2: Record 50000);
    VAR
        MasterWorkOrderBuf: Record 50000;
    begin
        MasterWorkOrderBuf.COPY(MasterWorkOrderBuf2);
        Code(MasterWorkOrderBuf, FALSE);
        MasterWorkOrderBuf2 := MasterWorkOrderBuf;
    end;

    local procedure Code(VAR MasterWorkOrderBuf: Record 50000; CheckLine: Boolean);
    begin
        WITH MasterWorkOrderBuf DO begin
            IF EmptyLine THEN
                EXIT;

            //009 Start
            IF ("Processing Status" IN ["Processing Status"::New, "Processing Status"::Processed]) THEN
                EXIT;
            //009 end

            IF CheckLine THEN
                MasterWorkOrdCheckLine.RunCheck(MasterWorkOrderBuf);

            IF NextEntryNo = 0 THEN
                StartPosting(MasterWorkOrderBuf)
            ELSE
                ContinuePosting(MasterWorkOrderBuf);

            IF "Ready for Processing" AND NOT "Validation Error" THEN
                PostMasterWorkOrderLine(MasterWorkOrderBuf);

            FinishPosting;
        end;
    end;

    procedure StartPosting(VAR MasterWorkOrderLine: Record 50000);
    VAR
        ProdOrder: Record 5405;
        ProdOrderLine: Record 5406;
        ProdOrderRtngLine: Record 5409;
        ProdOrderComp: Record 5407;
    begin
        WITH MasterWorkOrderLine DO begin
            GlobalMasterWOLineArch.LOCKTABLE;
            IF GlobalMasterWOLineArch.FINDLAST THEN
                NextEntryNo := GlobalMasterWOLineArch."Entry No." + 1 //006
            ELSE
                NextEntryNo := 1;

            //003 Start
            ProdOrder.LOCKTABLE;
            ProdOrderLine.LOCKTABLE;
            //003 end

            TempMasterWOLineBuf.DELETEALL;
            TempProdOrder.DELETEALL;
        end;
    end;

    procedure ContinuePosting(VAR MasterWorkOrderLine: Record 50000);
    begin
        WITH MasterWorkOrderLine DO begin
            ;
        end;

        TempMasterWOLineBuf.DELETEALL;
    end;

    procedure FinishPosting();
    begin
        //002 Start
        IF NOT Mgt.IsArchivingEnabled(DATABASE::"GUI-to-BC Master WO Line") THEN
            EXIT;
        //002 end

        IF TempMasterWOLineBuf.FINDSET THEN
            REPEAT
                //009 Start - Moved to function //
                IntegrMgt.ArchiveSingleMasterWorkOrder(TempMasterWOLineBuf, NextEntryNo, FALSE);
            //009 end
            UNTIL TempMasterWOLineBuf.NEXT = 0;
    end;

    local procedure PostMasterWorkOrderLine(VAR MasterWorkOrderLine: Record 50000);
    VAR
        ProdOrder: Record 5405;
        ProdOrderLine: Record 5406;
    begin
        WITH MasterWorkOrderLine DO begin
            ProdOrder.LOCKTABLE; //009

            CLEARLASTERROR; //009

            //009 InsertProdOrder(MasterWorkOrderLine,ProdOrder);
            IF InsertProdOrder(MasterWorkOrderLine, ProdOrder) THEN begin //009
                OnMoveMasterWorkOrderLine(ProdOrder.RECORDID);

                TempMasterWOLineBuf := MasterWorkOrderLine;
                TempMasterWOLineBuf.INSERT;
            end ELSE
                ERROR(GETLASTERRORTEXT); //009
        end;
    end;

    local procedure InsertProdOrder(VAR MasterWorkOrderLine: Record 50000; VAR ProdOrder: Record 5405): Boolean;
    VAR
        Item: Record Item;
        HeaderExist: Boolean;
    begin
        Item.GET(MasterWorkOrderLine."Item No.");

        GetMfgSetup;
        IF FindTempProdOrder(MasterWorkOrderLine) THEN
            HeaderExist := ProdOrder.GET(TempProdOrder.Status, TempProdOrder."No.");

        IF NOT HeaderExist THEN begin
            MfgSetup.TESTFIELD("Released Order Nos.");

            ProdOrder.INIT;
            ProdOrder.Status := ProdOrder.Status::Released;
            ProdOrder."No. Series" := ProdOrder.GetNoSeriesCode;
            ProdOrder.INSERT(TRUE);

            ProdOrder."Source Type" := ProdOrder."Source Type"::Item;
            ProdOrder.VALIDATE("Source No.", MasterWorkOrderLine."Item No.");
            ProdOrder."Creation Date" := TODAY;
            ProdOrder."Last Date Modified" := TODAY;
            //   ProdOrder.VALIDATE("Location Code",MfgSetup."GUI Def. Production Location");
            IF MasterWorkOrderLine."Routing No." <> '' THEN //005
                ProdOrder.VALIDATE("Routing No.", MasterWorkOrderLine."Routing No.");
            ProdOrder.VALIDATE(Quantity, MasterWorkOrderLine.Quantity);
            ProdOrder.SetUpdateendDate; //010
            ProdOrder.VALIDATE("Due Date", MasterWorkOrderLine."Order Date"); //004
                                                                              //005 Start
            ProdOrder."GUI Order Shift" := MasterWorkOrderLine."Order Shift";
            ProdOrder."GUI Production Line No." := MasterWorkOrderLine."Production Line No.";
            ProdOrder."Location Code" := MasterWorkOrderLine."Location Code";
            ProdOrder.Mixes := MasterWorkOrderLine.Mixes;
            //005 end
            ProdOrder.MODIFY;

            IF FirstProdOrderNo = '' THEN
                FirstProdOrderNo := ProdOrder."No.";

            InsertTempProdOrder(ProdOrder);
        end;
        InsertProdOrderLine(MasterWorkOrderLine, ProdOrder, Item);

        EXIT(TRUE); //009
    end;

    local procedure InsertProdOrderLine(VAR MasterWorkOrderLine: Record 50000; ProdOrder: Record 5405; Item: Record 27);
    VAR
        ProdOrderLine: Record 5406;
        NextLineNo: Integer;
    begin
        ProdOrderLine.SETRANGE("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.SETRANGE(Status, ProdOrder.Status);
        ProdOrderLine.LOCKTABLE;
        IF ProdOrderLine.FINDLAST THEN
            NextLineNo := ProdOrderLine."Line No." + 10000
        ELSE
            NextLineNo := 10000;

        ProdOrderLine.INIT;
        ProdOrderLine.BlockDynamicTracking(TRUE);
        ProdOrderLine.Status := ProdOrder.Status;
        ProdOrderLine."Prod. Order No." := ProdOrder."No.";
        ProdOrderLine."Line No." := NextLineNo;
        ProdOrderLine.VALIDATE("Item No.", MasterWorkOrderLine."Item No.");
        IF MasterWorkOrderLine."Variant Code" <> '' THEN
            ProdOrderLine.VALIDATE("Variant Code", MasterWorkOrderLine."Variant Code");
        IF (MasterWorkOrderLine."Unit of Measure Code" <> '') AND
           (ProdOrderLine."Unit of Measure Code" <> MasterWorkOrderLine."Unit of Measure Code")
        THEN
            ProdOrderLine.VALIDATE("Unit of Measure Code", MasterWorkOrderLine."Unit of Measure Code");
        ProdOrderLine.VALIDATE(Quantity, MasterWorkOrderLine.Quantity);
        CalcProdOrder.SetProdOrderLineBinCodeFromRoute(ProdOrderLine, ProdOrder."Location Code", ProdOrder."Routing No.");
        ProdOrderLine.INSERT;

        FinalizeOrderHeader(MasterWorkOrderLine, ProdOrder);

        // update Master Work order Line
        //>>SC UpdateRoutingCost(ProdOrderLine);
        MasterWorkOrderLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        // MasterWorkOrderLine."Production Line No." := Format(ProdOrderLine."Line No.");
        MasterWorkOrderLine.Validate(Processed, True);
        MasterWorkOrderLine.SetProcessingStatus(2);
        MasterWorkOrderLine.Modify();
    end;

    local procedure FinalizeOrderHeader(VAR MasterWorkOrderLine: Record 50000; ProdOrder: Record 5405);
    VAR
        ReportSelection: Record 77;
        ProdOrder2: Record 5405;
        RefreshProdOrder: Report 50002;
        Direction: option Forward,Backward;
        CalcLines: Boolean;
        CalcRoutings: Boolean;
        CalcComponents: Boolean;
        CreateInbRqst: Boolean;
    begin
        IF ProdOrder."No." <> '' THEN begin
            ProdOrder2 := ProdOrder;
            ProdOrder2.SETRECFILTER;

            Direction := Direction::Backward;
            CalcLines := TRUE;
            CalcRoutings := TRUE;
            CalcComponents := TRUE;
            CreateInbRqst := TRUE;


            ClearLastError();
            IF NOT ProdOrderRefresh(
              ProdOrder2,
              Direction, CalcLines, CalcRoutings, CalcComponents, CreateInbRqst)
            THEN begin
                IF GETLASTERRORTEXT = '' THEN
                    MasterWorkOrderLine."Validation Error Message" := STRSUBSTNO(GUIText001, ProdOrder2."No.")
                ELSE
                    MasterWorkOrderLine."Validation Error Message" := COPYSTR(GETLASTERRORTEXT, 1, MAXSTRLEN(MasterWorkOrderLine."Validation Error Message"));
                MasterWorkOrderLine.MODIFY;
            end ELSE
                IF PrintOrder THEN begin
                    ProdOrder2 := ProdOrder;
                    ProdOrder2.SETRECFILTER;
                    //SC ReportSelection.PrintWithGUIYesNoWithCheck(ReportSelection.Usage::"Prod. Order",ProdOrder2,FALSE,0);
                end;
            //003 end
        end;
    end;

    local procedure ProdOrderRefresh(VAR ProdOrder2: Record 5405; Direction: Option Forward,Backward; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; CreateInbRqst: Boolean): Boolean;
    VAR
        Family: Record 99000773;
        Item: Record 27;
        ProdOrderLine: Record 5406;
        ProdOrderRtngLine: Record 5409;
        ProdOrderComp: Record 5407;
        CreateProdOrderLines: Codeunit 99000787;
        ProdOrderStatusMgt: Codeunit 5407;
        WhseProdRelease: Codeunit 5774;
        WhseOutputProdRelease: Codeunit 7325;
        RoutingNo: Code[20];
        ErrorOccured: Boolean;
    begin
        //003 Start
        WITH ProdOrder2 DO begin
            ErrorOccured := FALSE;

            IF Status = Status::Finished THEN
                EXIT(TRUE);

            IF Direction = Direction::Backward THEN
                TESTFIELD("Due Date");

            IF CalcLines AND IsComponentPicked(ProdOrder2) THEN
                EXIT(TRUE);

            RoutingNo := "Routing No.";
            CASE "Source Type" OF
                "Source Type"::Item:
                    IF Item.GET("Source No.") THEN
                        RoutingNo := Item."Routing No.";
                "Source Type"::Family:
                    IF Family.GET("Source No.") THEN
                        RoutingNo := Family."Routing No.";
            end;
            IF (RoutingNo <> '') THEN //005
                IF RoutingNo <> "Routing No." THEN begin
                    "Routing No." := RoutingNo;
                    MODIFY;
                end;

            ProdOrderLine.LOCKTABLE;

            CheckReservationExist(ProdOrder2, CalcLines, CalcComponents);

            IF CalcLines THEN begin
                IF NOT CreateProdOrderLines.Copy(ProdOrder2, Direction, '', FALSE) THEN
                    ErrorOccured := TRUE;
            end ELSE begin
                ProdOrderLine.SETRANGE(Status, Status);
                ProdOrderLine.SETRANGE("Prod. Order No.", "No.");
                IF CalcRoutings OR CalcComponents THEN begin
                    IF ProdOrderLine.FIND('-') THEN
                        REPEAT
                            IF CalcRoutings THEN begin
                                ProdOrderRtngLine.SETRANGE(Status, Status);
                                ProdOrderRtngLine.SETRANGE("Prod. Order No.", "No.");
                                ProdOrderRtngLine.SETRANGE("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                                ProdOrderRtngLine.SETRANGE("Routing No.", ProdOrderLine."Routing No.");
                                IF ProdOrderRtngLine.FINDSET(TRUE) THEN
                                    REPEAT
                                        ProdOrderRtngLine.SetSkipUpdateOfCompBinCodes(TRUE);
                                        ProdOrderRtngLine.DELETE(TRUE);
                                    UNTIL ProdOrderRtngLine.NEXT = 0;
                            end;
                            IF CalcComponents THEN begin
                                ProdOrderComp.SETRANGE(Status, Status);
                                ProdOrderComp.SETRANGE("Prod. Order No.", "No.");
                                ProdOrderComp.SETRANGE("Prod. Order Line No.", ProdOrderLine."Line No.");
                                ProdOrderComp.DELETEALL(TRUE);
                            end;
                        UNTIL ProdOrderLine.NEXT = 0;
                    IF ProdOrderLine.FIND('-') THEN
                        REPEAT
                            IF CalcComponents THEN
                                CheckProductionBOMStatus(ProdOrderLine."Production BOM No.", ProdOrderLine."Production BOM Version Code");
                            IF CalcRoutings THEN begin
                                CheckRoutingStatus(ProdOrderLine."Routing No.", ProdOrderLine."Routing Version Code");

                            end;
                            ProdOrderLine."Due Date" := "Due Date";
                            IF NOT CalcProdOrder.Calculate(ProdOrderLine, Direction, CalcRoutings, CalcComponents, FALSE, FALSE) THEN
                                ErrorOccured := TRUE;
                        UNTIL ProdOrderLine.NEXT = 0;
                end;
            end;
            IF (Direction = Direction::Backward) AND
               ("Source Type" = "Source Type"::Family)
            THEN begin
                SetUpdateendDate;
                VALIDATE("Due Date", "Due Date");
            end;

            IF Status = Status::Released THEN begin
                ProdOrderStatusMgt.FlushProdOrder(ProdOrder2, Status, WORKDATE);
                WhseProdRelease.Release(ProdOrder2);
                IF CreateInbRqst THEN
                    WhseOutputProdRelease.Release(ProdOrder2);
            end;
            CLEAR(CalcProdOrder); //008
        end;

        EXIT(NOT ErrorOccured);
        //003 end
    end;

    local procedure IsComponentPicked(ProdOrder: Record 5405): Boolean;
    VAR
        ProdOrderComp: Record 5407;
    begin
        //003 Start
        ProdOrderComp.SETRANGE(Status, ProdOrder.Status);
        ProdOrderComp.SETRANGE("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SETFILTER("Qty. Picked", '<>0');
        EXIT(NOT ProdOrderComp.ISEMPTY);
        //003 end
    end;

    local procedure CheckReservationExist(VAR ProdOrder2: Record 5405; CalcLines: Boolean; CalcComponents: Boolean);
    VAR
        ProdOrderLine2: Record 5406;
        ProdOrderComp2: Record 5407;
    begin
        //003 Start
        WITH ProdOrder2 DO begin
            // Not allowed to refresh if reservations exist
            IF NOT (CalcLines OR CalcComponents) THEN
                EXIT;

            ProdOrderLine2.SETRANGE(Status, Status);
            ProdOrderLine2.SETRANGE("Prod. Order No.", "No.");
            IF ProdOrderLine2.FIND('-') THEN
                REPEAT
                    IF CalcLines THEN begin
                        ProdOrderLine2.CALCFIELDS("Reserved Qty. (Base)");
                        IF ProdOrderLine2."Reserved Qty. (Base)" <> 0 THEN
                            IF ShouldCheckReservedQty(
                                 ProdOrderLine2."Prod. Order No.", 0, DATABASE::"Prod. Order Line",
                                 ProdOrderLine2.Status, ProdOrderLine2."Line No.", DATABASE::"Prod. Order Component")
                            THEN
                                ProdOrderLine2.TESTFIELD("Reserved Qty. (Base)", 0);
                    end;

                    IF CalcComponents THEN begin
                        ProdOrderComp2.SETRANGE(Status, ProdOrderLine2.Status);
                        ProdOrderComp2.SETRANGE("Prod. Order No.", ProdOrderLine2."Prod. Order No.");
                        ProdOrderComp2.SETRANGE("Prod. Order Line No.", ProdOrderLine2."Line No.");
                        ProdOrderComp2.SETAUTOCALCFIELDS("Reserved Qty. (Base)");
                        IF ProdOrderComp2.FIND('-') THEN begin
                            REPEAT
                                IF ProdOrderComp2."Reserved Qty. (Base)" <> 0 THEN
                                    IF ShouldCheckReservedQty(
                                         ProdOrderComp2."Prod. Order No.", ProdOrderComp2."Line No.",
                                         DATABASE::"Prod. Order Component", ProdOrderComp2.Status,
                                         ProdOrderComp2."Prod. Order Line No.", DATABASE::"Prod. Order Line")
                                    THEN
                                        ProdOrderComp2.TESTFIELD("Reserved Qty. (Base)", 0);
                            UNTIL ProdOrderComp2.NEXT = 0;
                        end;
                    end;
                UNTIL ProdOrderLine2.NEXT = 0;
        end;
        //003 end
    end;

    local procedure ShouldCheckReservedQty(ProdOrderNo: Code[20]; LineNo: Integer; SourceType: Integer; Status: Option; ProdOrderLineNo: Integer; SourceType2: Integer): Boolean;
    VAR
        ReservEntry: Record 337;
    begin
        //003 Start
        WITH ReservEntry DO begin
            SETCURRENTKEY("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
            SETRANGE("Source Batch Name", '');
            SETRANGE("Reservation Status", "Reservation Status"::Reservation);
            SETRANGE("Source ID", ProdOrderNo);
            SETRANGE("Source Ref. No.", LineNo);
            SETRANGE("Source Type", SourceType);
            SETRANGE("Source Subtype", Status);
            SETRANGE("Source Prod. Order Line", ProdOrderLineNo);

            IF FINDFIRST THEN begin
                GET("Entry No.", NOT Positive);
                EXIT(
                  NOT (("Source Type" = SourceType2) AND
                       ("Source ID" = ProdOrderNo) AND ("Source Subtype" = Status)));
            end;
        end;

        EXIT(FALSE);
        //003 end
    end;

    local procedure CheckProductionBOMStatus(ProdBOMNo: Code[20]; ProdBOMVersionNo: Code[20]);
    VAR
        ProductionBOMHeader: Record 99000771;
        ProductionBOMVersion: Record 99000779;
    begin
        //003 Start
        IF ProdBOMNo = '' THEN
            EXIT;

        IF ProdBOMVersionNo = '' THEN begin
            ProductionBOMHeader.GET(ProdBOMNo);
            ProductionBOMHeader.TESTFIELD(Status, ProductionBOMHeader.Status::Certified);
        end ELSE begin
            ProductionBOMVersion.GET(ProdBOMNo, ProdBOMVersionNo);
            ProductionBOMVersion.TESTFIELD(Status, ProductionBOMVersion.Status::Certified);
        end;
        //003 end
    end;

    local procedure CheckRoutingStatus(RoutingNo: Code[20]; RoutingVersionNo: Code[20]);
    VAR
        RoutingHeader: Record 99000763;
        RoutingVersion: Record 99000786;
    begin
        //003 Statr
        IF RoutingNo = '' THEN
            EXIT;

        IF RoutingVersionNo = '' THEN begin
            RoutingHeader.GET(RoutingNo);
            RoutingHeader.TESTFIELD(Status, RoutingHeader.Status::Certified);
        end ELSE begin
            RoutingVersion.GET(RoutingNo, RoutingVersionNo);
            RoutingVersion.TESTFIELD(Status, RoutingVersion.Status::Certified);
        end;
        //003 end
    end;

    local procedure UpdateRoutingCost(var ProdOrderLine: Record "Prod. Order Line");
    VAR
        prodRoutLine: Record "Prod. Order Routing Line";
    begin

        prodRoutLine.Reset();
        prodRoutLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        prodRoutLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
        if prodRoutLine.FindSet() then
            repeat
                prodRoutLine."Unit Cost per" := 0;
                prodRoutLine."Run Time" := 0;
                prodRoutLine."Setup Time" := 0;
                prodRoutLine."Direct Unit Cost" := 0;
                prodRoutLine.Modify();
            until prodRoutLine.Next() = 0;
    end;

    local procedure FindTempProdOrder(MasterWorkOrderLine: Record 50000): Boolean;
    begin
        WITH MasterWorkOrderLine DO begin
            IF "Prod. Order No." <> '' THEN begin
                TempProdOrder.SETRANGE("No.", "Prod. Order No.");
                EXIT(TempProdOrder.FINDFIRST);
            end;
        end;
    end;

    local procedure InsertTempProdOrder(NewProdOrder: Record 5405);
    begin
        IF TempProdOrder.GET(NewProdOrder.Status, NewProdOrder."No.") THEN
            EXIT;

        TempProdOrder := NewProdOrder;
        TempProdOrder.INSERT;
    end;

    local procedure GetMfgSetup();
    begin
        IF NOT MfgSetupRead THEN begin
            MfgSetup.GET;
            // MfgSetup.TESTFIELD("GUI Def. Production Location");
            MfgSetupRead := TRUE;
        end;
    end;

    procedure GetNextEntryNo(): Integer;
    begin
        EXIT(NextEntryNo);
    end;

    procedure ChangeProdOrderQuantity(VAR ProdOrderLine: Record 5406);
    VAR
        ProdOrder: Record "Production Order";
    begin
        //008 Start
        WITH ProdOrderLine DO begin
            ProdOrder.GET(Status, "Prod. Order No.");
            MODIFY;

            CalcProdOrder.Recalculate(ProdOrderLine, 1, TRUE);
            CLEAR(CalcProdOrder);

            GET(Status, "Prod. Order No.", "Line No.");
        end;
        //008 end
    end;


}