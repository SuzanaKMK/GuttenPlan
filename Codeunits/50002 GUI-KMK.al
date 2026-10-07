codeunit 50002 GUI_KMK
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure OnAfterInitItemLedgEntryKMK(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    var
    begin
        NewItemLedgEntry."GUI Description" := ItemJournalLine."GUI Description";
        NewItemLedgEntry."GUI Pallet" := ItemJournalLine."GUI Pallet";
        NewItemLedgEntry."GUI Time of Action" := ItemJournalLine."GUI Time of Action";
        NewItemLedgEntry."GUI Type" := ItemJournalLine."GUI Type";
        NewItemLedgEntry."GUI-to-BC Entry No" := ItemJournalLine."GUI-to-BC Entry No";
        NewItemLedgEntry."GUI User ID" := ItemJournalLine."GUI User ID";

    end;


    [EventSubscriber(ObjectType::Table, Database::"Lot No. Information", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEvent(VAR Rec: Record "Lot No. Information"; RunTrigger: Boolean)
    var
    begin
        // CreateLotNoInfo(Rec);
        Rec.Description := 'Auto Create';

    end;


    [EventSubscriber(ObjectType::Page, Page::"Lot No. Information Card", 'OnAfterGetCurrRecordEvent', '', false, false)]

    local procedure LotNoInfoOnAfterGetRecord(VAR Rec: Record "Lot No. Information");
    begin
        UpdateDaysRemaining(Rec);  //024
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyItemJnlLineFromSalesLine', '', false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesLine(var ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line")
    begin
        ItemJnlLine."GUI Description" := SalesLine.KMK_GUIDescription;
        ItemJnlLine."GUI Pallet" := SalesLine."GUI Pallet";
        ItemJnlLine."GUI Time of Action" := SalesLine."GUI Time of Action";
        ItemJnlLine."GUI Type" := SalesLine."GUI Type";
        ItemJnlLine."GUI User ID" := SalesLine."GUI User ID";
        ItemJnlLine."GUI-to-BC Entry No" := SalesLine."GUI-to-BC Entry No";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyItemJnlLineFromPurchLine', '', false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchLine(var ItemJnlLine: Record "Item Journal Line"; PurchLine: Record "Purchase Line")
    begin
        ItemJnlLine."GUI Description" := PurchLine.KMK_GUIDescription;
        ItemJnlLine."GUI Pallet" := PurchLine."GUI Pallet";
        ItemJnlLine."GUI Time of Action" := PurchLine."GUI Time of Action";
        ItemJnlLine."GUI Type" := PurchLine."GUI Type";
        ItemJnlLine."GUI User ID" := PurchLine."GUI User ID";
        ItemJnlLine."GUI-to-BC Entry No" := PurchLine."GUI-to-BC Entry No";

    end;




    local procedure CreateLotNoInfo(VAR ResEntry: Record "Reservation Entry");
    VAR
        LotNoInfo: Record "Lot No. Information";
        ResEntryItem: Record Item;
        ExpDate: Date;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        EntriesExist: Boolean;
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        //007 Start
        //034 COMMIT;
        IF NOT LotNoInfo.GET(ResEntry."Item No.", ResEntry."Variant Code", ResEntry."Lot No.") THEN begin
            ResEntryItem.GET(ResEntry."Item No.");
            LotNoInfo.INIT;
            LotNoInfo."Item No." := ResEntry."Item No.";
            LotNoInfo."Lot No." := ResEntry."Lot No.";
            LotNoInfo.Description := 'Auto Create';
            ExpDate := ResEntry."Expiration Date";  //024

            IF ExpDate = 0D THEN
                ExpDate := ItemTrackingMgt.ExistingExpirationDate(ResEntry."Item No.", ResEntry."Variant Code", ItemTrackingSetup, false, EntriesExist);

            IF ExpDate <> 0D then begin
                //>>  LotNoInfo.KMK_ManufactureDate := ExpDate - ResEntryItem.KMK_ShelfLifeDays;

                LotNoInfo.KMK_ManufactureDate := ResEntry."Expected Receipt Date";
                LotNoInfo.KMK_DaysRemaining := ExpDate - TODAY;
            end;

            LotNoInfo.Insert()
        end else begin


            LotNoInfo.Description := 'Auto Create';
            ExpDate := ResEntry."Expiration Date";

            IF ExpDate = 0D THEN
                ExpDate := ItemTrackingMgt.ExistingExpirationDate(ResEntry."Item No.", ResEntry."Variant Code", ItemTrackingSetup, false, EntriesExist);

            IF ExpDate <> 0D THEN begin
                // LotNoInfo.KMK_ManufactureDate := ExpDate - ResEntryItem.KMK_ShelfLifeDays;
                If LotNoInfo.KMK_ManufactureDate = 0D then LotNoInfo.KMK_ManufactureDate := ResEntry."Expected Receipt Date";
                LotNoInfo.KMK_DaysRemaining := ExpDate - TODAY;
            end;
        end;
        //007 end
    end;

    local procedure UpdateDaysRemaining(VAR LotNoInfo: Record 6505);
    var
        ILE: Record "Item Ledger Entry";
    begin
        //024 Start
        ILE.Reset();
        ILE.setrange("Item No.", LotNoInfo."Item No.");
        ILE.SetRange("Variant Code", LotNoInfo."Variant Code");
        ILE.SetRange("Lot No.", LotNoInfo."Lot No.");
        if not ILE.FindFirst() then ILE.Init();
        IF LotNoInfo.KMK_ManufactureDate <> 0D THEN
            LotNoInfo.KMK_DaysRemaining := ILE."Expiration Date" - Today();

    end;












    var
        myInt: Integer;
}