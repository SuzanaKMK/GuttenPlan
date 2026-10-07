codeunit 50011 GUI_ItemTrackingLines
{
    trigger OnRun()
    begin

    end;


    var
        Rec: Record "Tracking Specification" temporary;
        xRec: Record "Tracking Specification" temporary;
        xTempItemTrackingLine: Record "Tracking Specification" temporary;
        TotalItemTrackingLine: Record "Tracking Specification";
        TempItemTrackLineInsert: Record "Tracking Specification" temporary;
        TempItemTrackLineModify: Record "Tracking Specification" temporary;
        TempItemTrackLineDelete: Record "Tracking Specification" temporary;
        TempItemTrackLineReserv: Record "Tracking Specification" temporary;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        TempReservEntry: Record "Reservation Entry" temporary;
        NoSeriesMgt: Codeunit "No. Series";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ReservEngineMgt: Codeunit 99000831;
        ItemTrackingDataCollection: Codeunit 6501;
        UndefinedQtyArray: ARRAY[3] OF Decimal;
        SourceQuantityArray: ARRAY[5] OF Decimal;
        QtyPerUOM: Decimal;
        QtyToAddAsBlank: Decimal;
        CurrentSignFactor: Integer;
        LastEntryNo: Integer;
        CurrentSourceType: Integer;
        SecondSourceID: Integer;
        IsAssembleToOrder: Boolean;
        ExpectedReceiptDate: Date;
        ShipmentDate: Date;
        CurrentEntryStatus: Option Reservation,Tracking,Surplus,Prospect;
        FormRunMode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment",Transfer;
        InsertIsBlocked: Boolean;
        DeleteIsBlocke: Boolean;
        BlockCommit: Boolean;
        IsCorrection: Boolean;
        CurrentFormIsOpen: Boolean;
        CalledFromSynchWhseItemTrkg: Boolean;
        Inbound: Boolean;
        CurrentSourceCaption: Text[255];
        CurrentSourceRowID: Text[250];
        SecondSourceRowID: Text[250];
        ForBinCode: Code[20];
        ApplFromItemEntryVisible: Boolean;
        ApplToItemEntryVisible: Boolean;
        ItemNoEditable: Boolean;
        variantCodeEditable: Boolean;
        LocationCodeEditable: Boolean;
        Handle1Visible: Boolean;
        Handle2Visible: Boolean;
        Handle3Visible: Boolean;
        QtyToHandleBaseVisible: Boolean;
        Invoice1Visible: Boolean;
        Invoice2Visible: Boolean;
        Invoice3Visible: Boolean;
        QtyToInvoiceBaseVisible: Boolean;
        NewSerialNoVisible: Boolean;
        NewLotNoVisible: Boolean;
        NewExpirationDateVisible: Boolean;
        ButtonLineReclassVisible: Boolean;
        ButtonLineVisible: Boolean;
        FunctionsSupplyVisible: Boolean;
        FunctionsDemandVisible: Boolean;
        InboundIsSet: Boolean;
        QtyToHandleBaseEditable: Boolean;
        QtyToInvoiceBaseEditable: Boolean;
        QuantityBaseEditable: Boolean;
        SerialNoEditable: Boolean;
        LotNoEditable: Boolean;
        DescriptionEditable: Boolean;
        NewSerialNoEditable: Boolean;
        NewLotNoEditable: Boolean;
        NewExpirationDateEditable: Boolean;
        ExpirationDateEditable: Boolean;
        WarrantyDateEditable: Boolean;
        ExcludePostedEntries: Boolean;
        ProdOrderLineHandling: Boolean;
        Text002: TextConst ENU = 'Quantity must be %1.';
        Text003: TextConst ENU = 'negative';
        Text004: TextConst ENU = 'positive';
        Text005: TextConst ENU = '=Error when writing to database.';
        Text006: TextConst ENU = 'The corrections cannot be saved as excess quantity has been defined.\Close the form anyway?;ESM=No se pueden guardar las correcciones porque existe un exceso de cdad.\¨Desea cerrar el formulario?;FRC=Les corrections ne peuvent ˆtre enregistr‚es car vous avez indiqu‚ une quantit‚ excessive.\Souhaitez-vous tout de mˆme fermer le formulaire ?;ENC=The corrections cannot be saved as excess quantity has been defined.\Close the form anyway?';
        Text007: TextConst ENU = 'Another user has modified the item tracking data since it was retrieved from the database.\Start again.;ESM=Otro usuario ha modificado datos seguim. prod. desde que se recuper¢ de la base de datos.\Empiece otra vez.;FRC=Un autre utilisateur a modifi‚ les donn‚es de tra‡abilit‚ depuis qu''elles ont ‚t‚ extraites de la base de donn‚es.\Veuillez recommencer.;ENC=Another user has modified the item tracking data since it was retrieved from the database.\Start again.';
        Text008: TextConst ENU = 'The quantity to create must be an integer.;ESM=La cantidad a crear debe ser un n§ entero.;FRC=La quantit‚ … cr‚er doit un entier.;ENC=The quantity to create must be an integer.';
        Text009: TextConst ENU = 'The quantity to create must be positive.;ESM=La cdad. a crear debe ser positiva.;FRC=La quantit‚ … cr‚er doit ˆtre positive.;ENC=The quantity to create must be positive.';
        Text011: TextConst ENU = 'Tracking specification with Serial No. %1 and Lot No. %2 already exists.;ESM=La especificaci¢n de seguimiento con N§ serie %1 y N§ lote %2 ya existe.;FRC=La sp‚cification tra‡abilit‚ avec le nø de s‚rie %1 et le nø de lot %2 existe d‚j….;ENC=Tracking specification with Serial No. %1 and Lot No. %2 already exists.';
        Text012: TextConst ENU = 'Tracking specification with Serial No. %1 already exists.;ESM=La especificaci¢n de seguimiento con N§ serie %1 ya existe.;FRC=La sp‚cification tra‡abilit‚ avec le nø de s‚rie %1 existe d‚j….;ENC=Tracking specification with Serial No. %1 already exists.';
        Text014: TextConst ENU = 'The total item tracking quantity %1 exceeds the %2 quantity %3.\The changes cannot be saved to the database.;ESM=La cdad. seguim. prod. total %1 excede el %2 cantidad %3.\No se pueden guardar los cambios en la base de datos.;FRC=La quantit‚ tra‡abilit‚ totale %1 d‚passe la quantit‚ %2 %3.\Les modifications ne peuvent ˆtre enregistr‚es dans la base de donn‚es.;ENC=The total item tracking quantity %1 exceeds the %2 quantity %3.\The changes cannot be saved to the database.';
        Text015: TextConst ENU = 'Do you want to synchronize item tracking on the line with item tracking on the related drop shipment %1?;ESM=¨Quiere sincronizar el seguim. de prod. en la l¡nea con el seguim. de prod. del env¡o directo relacionado %1?;FRC=Voulez-vous synchroniser le suivi d''article sur la ligne avec suivi d''article de la livraison annul‚e %1 correspondante?;ENC=Do you want to synchronize item tracking on the line with item tracking on the related drop shipment %1?';
        Text016: TextConst ENU = 'purchase order line;ESM=l¡nea pedido compra;FRC=ligne de bon de commande;ENC=purchase order line';
        Text017: TextConst ENU = 'sales order line';
        Text018: TextConst ENU = 'Saving item tracking line changes;';
        Text019: TextConst ENU = 'There are availability warnings on one or more lines.\Close the form anyway?';
        Text020: TextConst ENU = 'Placeholder;ESM=Marcador de posici¢n;FRC=ParamŠtre substituable;ENC=Placeholder';
        DifferentExpDateMsg: TextConst ENU = '@@@="%1 = Lot no., %2 = Item expiration date (Example: A tracking specification exists for lot number ''L001'' and expiration date 25.01.2019.)';

    procedure SetFormRunMode(Mode: Option ,Reclass,"Combined Ship/Rcpt","Drop Shipment");
    begin
        FormRunMode := Mode;
    end;

    procedure SetSourceSpec(TrackingSpecification: Record "Tracking Specification"; AvailabilityDate: Date);
    var
        ReservEntry: Record 337;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        Controls: Option Handle,Invoice,Quantity,Reclass,LotSN;
        DeleteIsBlocked: Boolean;
    begin
        GetItem(TrackingSpecification."Item No.");
        ForBinCode := TrackingSpecification."Bin Code";
        setfilters(TrackingSpecification);
        TempTrackingSpecification.DELETEALL;
        TempItemTrackLineInsert.DELETEALL;
        TempItemTrackLineModify.DELETEALL;
        TempItemTrackLineDelete.DELETEALL;

        TempReservEntry.DELETEALL;
        LastEntryNo := 0;
        if ItemTrackingMgt.IsOrderNetworkEntity(TrackingSpecification."Source Type",
             TrackingSpecification."Source Subtype") AND NOT (FormRunMode = FormRunMode::"Drop Shipment")
        then
            CurrentEntryStatus := CurrentEntryStatus::Surplus
        else
            CurrentEntryStatus := CurrentEntryStatus::Prospect;

        // Set controls for Qty to handle:
        SetControls(Controls::Handle, GetHandleSource(TrackingSpecification));
        // Set controls for Qty to Invoice:
        SetControls(Controls::Invoice, GetInvoiceSource(TrackingSpecification));

        SetControls(Controls::Reclass, FormRunMode = FormRunMode::Reclass);

        if FormRunMode = FormRunMode::"Combined Ship/Rcpt" then
            SetControls(Controls::LotSN, FALSE);
        if ItemTrackingMgt.ItemTrkgIsManagedByWhse(
             TrackingSpecification."Source Type",
             TrackingSpecification."Source Subtype",
             TrackingSpecification."Source ID",
             TrackingSpecification."Source Prod. Order Line",
             TrackingSpecification."Source Ref. No.",
             TrackingSpecification."Location Code",
             TrackingSpecification."Item No.")
        then begin
            SetControls(Controls::Quantity, FALSE);
            QtyToHandleBaseEditable := TRUE;
            DeleteIsBlocked := TRUE;
        end;

        ReservEntry."Source Type" := TrackingSpecification."Source Type";
        ReservEntry."Source Subtype" := TrackingSpecification."Source Subtype";
        CurrentSignFactor := CreateReservEntry.SignFactor(ReservEntry);
        CurrentSourceCaption := ReservEntry.TextCaption;
        CurrentSourceType := ReservEntry."Source Type";

        if CurrentSignFactor < 0 then begin
            ExpectedReceiptDate := 0D;
            ShipmentDate := AvailabilityDate;
        end else begin
            ExpectedReceiptDate := AvailabilityDate;
            ShipmentDate := 0D;
        end;

        SourceQuantityArray[1] := TrackingSpecification."Quantity (Base)";
        SourceQuantityArray[2] := TrackingSpecification."Qty. to Handle (Base)";
        SourceQuantityArray[3] := TrackingSpecification."Qty. to Invoice (Base)";
        SourceQuantityArray[4] := TrackingSpecification."Quantity Handled (Base)";
        SourceQuantityArray[5] := TrackingSpecification."Quantity Invoiced (Base)";
        QtyPerUOM := TrackingSpecification."Qty. per Unit of Measure";

        ReservEntry.SETCURRENTKEY(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");

        ReservEntry.Setrange("Source ID", TrackingSpecification."Source ID");
        ReservEntry.Setrange("Source Ref. No.", TrackingSpecification."Source Ref. No.");
        ReservEntry.Setrange("Source Type", TrackingSpecification."Source Type");
        ReservEntry.Setrange("Source Subtype", TrackingSpecification."Source Subtype");
        ReservEntry.Setrange("Source Batch Name", TrackingSpecification."Source Batch Name");
        ReservEntry.Setrange("Source Prod. Order Line", TrackingSpecification."Source Prod. Order Line");

        // Transfer Receipt gets special treatment:
        if (TrackingSpecification."Source Type" = DATABASE::"Transfer Line") AND
           (FormRunMode <> FormRunMode::Transfer) AND
           (TrackingSpecification."Source Subtype" = 1)
        then begin
            ReservEntry.Setrange("Source Subtype", 0);
            AddReservEntriesToTempRecSet(ReservEntry, TempTrackingSpecification2, TRUE, 8421504);
            ReservEntry.Setrange("Source Subtype", 1);
            ReservEntry.Setrange("Source Prod. Order Line", TrackingSpecification."Source Ref. No.");
            ReservEntry.Setrange("Source Ref. No.");
            DeleteIsBlocked := TRUE;
            SetControls(Controls::Quantity, FALSE);
        end;

        AddReservEntriesToTempRecSet(ReservEntry, TempTrackingSpecification, FALSE, 0);

        TempReservEntry.COPYFILTERS(ReservEntry);

        TrackingSpecification.SETCURRENTKEY(
          "Source ID", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");

        TrackingSpecification.Setrange("Source ID", TrackingSpecification."Source ID");
        TrackingSpecification.Setrange("Source Type", TrackingSpecification."Source Type");
        TrackingSpecification.Setrange("Source Subtype", TrackingSpecification."Source Subtype");
        TrackingSpecification.Setrange("Source Batch Name", TrackingSpecification."Source Batch Name");
        TrackingSpecification.Setrange("Source Prod. Order Line", TrackingSpecification."Source Prod. Order Line");
        TrackingSpecification.Setrange("Source Ref. No.", TrackingSpecification."Source Ref. No.");

        if TrackingSpecification.FINDSET then
            REPEAT
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification.INSERT;
            UNTIL TrackingSpecification.NEXT = 0;

        // Data regarding posted quantities on transfers is collected from Item Ledger Entries:
        if TrackingSpecification."Source Type" = DATABASE::"Transfer Line" then
            CollectPostedTransferEntries(TrackingSpecification, TempTrackingSpecification);

        // Data regarding posted quantities on assembly orders is collected from Item Ledger Entries:
        if NOT ExcludePostedEntries then
            if (TrackingSpecification."Source Type" = DATABASE::"Assembly Line") OR
               (TrackingSpecification."Source Type" = DATABASE::"Assembly Header")
            then
                CollectPostedAssemblyEntries(TrackingSpecification, TempTrackingSpecification);

        // Data regarding posted output quantities on prod.orders is collected from Item Ledger Entries:
        if TrackingSpecification."Source Type" = DATABASE::"Prod. Order Line" then
            if TrackingSpecification."Source Subtype" = 3 then
                CollectPostedOutputEntries(TrackingSpecification, TempTrackingSpecification);

        // if run for Drop Shipment a RowID is prepared for synchronisation:
        if FormRunMode = FormRunMode::"Drop Shipment" then
            CurrentSourceRowID := ItemTrackingMgt.ComposeRowID(TrackingSpecification."Source Type",
                TrackingSpecification."Source Subtype", TrackingSpecification."Source ID",
                TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line",
                TrackingSpecification."Source Ref. No.");

        // Synchronization of outbound transfer order:
        if (TrackingSpecification."Source Type" = DATABASE::"Transfer Line") AND
           (TrackingSpecification."Source Subtype" = 0)
        then begin
            BlockCommit := TRUE;
            CurrentSourceRowID := ItemTrackingMgt.ComposeRowID(TrackingSpecification."Source Type",
                TrackingSpecification."Source Subtype", TrackingSpecification."Source ID",
                TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line",
                TrackingSpecification."Source Ref. No.");
            SecondSourceRowID := ItemTrackingMgt.ComposeRowID(TrackingSpecification."Source Type",
                1, TrackingSpecification."Source ID",
                TrackingSpecification."Source Batch Name", TrackingSpecification."Source Prod. Order Line",
                TrackingSpecification."Source Ref. No.");
            FormRunMode := FormRunMode::Transfer;
        end;

        AddToGlobalRecordSet(TempTrackingSpecification);
        AddToGlobalRecordSet(TempTrackingSpecification2);
        CalculateSums;

        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode(ForBinCode, ItemTrackingCode);
        ItemTrackingDataCollection.RetrieveLookupData(Rec, FALSE);

        FunctionsDemandVisible := CurrentSignFactor * SourceQuantityArray[1] < 0;
        FunctionsSupplyVisible := NOT FunctionsDemandVisible;
    end;

    procedure SetSecondSourceQuantity(SecondSourceQuantityArray: ARRAY[3] OF Decimal);
    var
        Controls: Option Handle,Invoice;
    begin
        CASE SecondSourceQuantityArray[1] OF
            DATABASE::"Warehouse Receipt Line", DATABASE::"Warehouse Shipment Line":
                begin
                    SourceQuantityArray[2] := SecondSourceQuantityArray[2]; // "Qty. to Handle (Base)"
                    SourceQuantityArray[3] := SecondSourceQuantityArray[3]; // "Qty. to Invoice (Base)"
                    SetControls(Controls::Invoice, FALSE);
                end;
            else
                exit;
        end;
        CalculateSums();
    end;

    procedure SetSecondSourceRowID(RowID: Text[250]);
    begin
        SecondSourceRowID := RowID;
    end;

    local procedure AddReservEntriesToTempRecSet(var ReservEntry: Record 337; var TempTrackingSpecification: Record "Tracking Specification" temporary; SwapSign: Boolean; Color: Integer);
    var
        FromReservEntry: Record 337;
        AddTracking: Boolean;
    begin
        if ReservEntry.FINDSET then
            REPEAT
                if Color = 0 then begin
                    TempReservEntry := ReservEntry;
                    TempReservEntry.INSERT;
                end;
                if ReservEntry.TrackingExists then begin
                    AddTracking := TRUE;
                    if SecondSourceID = DATABASE::"Warehouse Shipment Line" then
                        if FromReservEntry.GET(ReservEntry."Entry No.", NOT ReservEntry.Positive) then
                            AddTracking := (FromReservEntry."Source Type" = DATABASE::"Assembly Header") = IsAssembleToOrder
                        else
                            AddTracking := NOT IsAssembleToOrder;

                    if AddTracking then begin
                        TempTrackingSpecification.TransferFields(ReservEntry);
                        // Ensure uniqueness of Entry No. by making it negative:
                        TempTrackingSpecification."Entry No." *= -1;
                        if SwapSign then
                            TempTrackingSpecification."Quantity (Base)" *= -1;
                        if Color <> 0 then begin
                            TempTrackingSpecification."Quantity Handled (Base)" :=
                              TempTrackingSpecification."Quantity (Base)";
                            TempTrackingSpecification."Quantity Invoiced (Base)" :=
                              TempTrackingSpecification."Quantity (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                            TempTrackingSpecification."Qty. to Invoice (Base)" := 0;
                        end;
                        TempTrackingSpecification."Buffer Status" := Color;
                        TempTrackingSpecification.INSERT;
                    end;
                end;
            UNTIL ReservEntry.NEXT = 0;
    end;

    local procedure AddToGlobalRecordSet(var TempTrackingSpecification: Record "Tracking Specification" temporary);
    var
        ExpDate: Date;
        EntriesExist: Boolean;
        ItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin


        WITH Rec DO begin //002
            TempTrackingSpecification.SETCURRENTKEY("Lot No.", "Serial No.");
            if TempTrackingSpecification.FindFirst() then
                REPEAT
                    TempTrackingSpecification.Setrange("Lot No.", TempTrackingSpecification."Lot No.");
                    TempTrackingSpecification.Setrange("Serial No.", TempTrackingSpecification."Serial No.");
                    TempTrackingSpecification.calcsums("Quantity (Base)", "Qty. to Handle (Base)",
                      "Qty. to Invoice (Base)", "Quantity Handled (Base)", "Quantity Invoiced (Base)");
                    if TempTrackingSpecification."Quantity (Base)" <> 0 then begin
                        Rec := TempTrackingSpecification;
                        "Quantity (Base)" *= CurrentSignFactor;
                        "Qty. to Handle (Base)" *= CurrentSignFactor;
                        "Qty. to Invoice (Base)" *= CurrentSignFactor;
                        "Quantity Handled (Base)" *= CurrentSignFactor;
                        "Quantity Invoiced (Base)" *= CurrentSignFactor;
                        "Qty. to Handle" :=
                          CalcQty("Qty. to Handle (Base)");
                        "Qty. to Invoice" :=
                          CalcQty("Qty. to Invoice (Base)");
                        "Entry No." := NextEntryNo;

                        ExpDate := ItemTrackingMgt.ExistingExpirationDate(
                            "Item No.", "variant Code", ItemTrackingSetup, FALSE, EntriesExist);

                        if ExpDate <> 0D then begin
                            "Expiration Date" := ExpDate;
                            "Buffer Status2" := "Buffer Status2"::"ExpDate blocked";
                        end;

                        INSERT;

                        if "Buffer Status" = 0 then begin
                            xTempItemTrackingLine := Rec;
                            xTempItemTrackingLine.INSERT;
                        end;
                    end;

                    TempTrackingSpecification.FindFirst();
                    TempTrackingSpecification.Setrange("Lot No.");
                    TempTrackingSpecification.Setrange("Serial No.");
                UNTIL TempTrackingSpecification.Next() = 0;
        end; //002
    end;

    local procedure SetControls(Controls: Option Handle,Invoice,Quantity,Reclass,LotSN; SetAccess: Boolean);
    begin
        CASE Controls OF
            Controls::Handle:
                begin
                    Handle1Visible := SetAccess;
                    Handle2Visible := SetAccess;
                    Handle3Visible := SetAccess;
                    QtyToHandleBaseVisible := SetAccess;
                    QtyToHandleBaseEditable := SetAccess;
                end;
            Controls::Invoice:
                begin
                    Invoice1Visible := SetAccess;
                    Invoice2Visible := SetAccess;
                    Invoice3Visible := SetAccess;
                    QtyToInvoiceBaseVisible := SetAccess;
                    QtyToInvoiceBaseEditable := SetAccess;
                end;
            Controls::Quantity:
                begin
                    QuantityBaseEditable := SetAccess;
                    SerialNoEditable := SetAccess;
                    LotNoEditable := SetAccess;
                    DescriptionEditable := SetAccess;
                    InsertIsBlocked := TRUE;
                end;
            Controls::Reclass:
                begin
                    NewSerialNoVisible := SetAccess;
                    NewSerialNoEditable := SetAccess;
                    NewLotNoVisible := SetAccess;
                    NewLotNoEditable := SetAccess;
                    NewExpirationDateVisible := SetAccess;
                    NewExpirationDateEditable := SetAccess;
                    ButtonLineReclassVisible := SetAccess;
                    ButtonLineVisible := NOT SetAccess;
                end;
            Controls::LotSN:
                begin
                    SerialNoEditable := SetAccess;
                    LotNoEditable := SetAccess;
                    ExpirationDateEditable := SetAccess;
                    WarrantyDateEditable := SetAccess;
                    InsertIsBlocked := SetAccess;
                end;
        end;
    end;

    local procedure GetItem(ItemNo: Code[20]);
    begin
        if Item."No." <> ItemNo then begin
            Item.GET(ItemNo);
            Item.TESTFIELD("Item Tracking Code");
            if ItemTrackingCode.Code <> Item."Item Tracking Code" then
                ItemTrackingCode.GET(Item."Item Tracking Code");
        end;
    end;

    local procedure setfilters(TrackingSpecification: Record "Tracking Specification");
    begin
        WITH Rec DO begin //002
            FILTERGROUP := 2;
            SETCURRENTKEY("Source ID", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
            Setrange("Source ID", TrackingSpecification."Source ID");
            Setrange("Source Type", TrackingSpecification."Source Type");
            Setrange("Source Subtype", TrackingSpecification."Source Subtype");
            Setrange("Source Batch Name", TrackingSpecification."Source Batch Name");
            if (TrackingSpecification."Source Type" = DATABASE::"Transfer Line") AND
               (TrackingSpecification."Source Subtype" = 1)
            then begin
                setfilter("Source Prod. Order Line", '0 | ' + FORMAT(TrackingSpecification."Source Ref. No."));
                Setrange("Source Ref. No.");
            end else begin
                Setrange("Source Prod. Order Line", TrackingSpecification."Source Prod. Order Line");
                Setrange("Source Ref. No.", TrackingSpecification."Source Ref. No.");
            end;
            Setrange("Item No.", TrackingSpecification."Item No.");
            Setrange("Location Code", TrackingSpecification."Location Code");
            Setrange("variant Code", TrackingSpecification."variant Code");
            FILTERGROUP := 0;
        end; //002
    end;

    local procedure CheckLine(TrackingLine: Record "Tracking Specification");
    begin
        if TrackingLine."Quantity (Base)" * SourceQuantityArray[1] < 0 then
            if SourceQuantityArray[1] < 0 then
                ERROR(Text002, Text003)
            else
                ERROR(Text002, Text004);
    end;

    local procedure CalculateSums();
    var
        xTrackingSpec: Record "Tracking Specification";
    begin
        WITH Rec DO begin //002
            xTrackingSpec.COPY(Rec);
            RESET;
            calcsums("Quantity (Base)",
              "Qty. to Handle (Base)",
              "Qty. to Invoice (Base)");
            TotalItemTrackingLine := Rec;
            COPY(xTrackingSpec);

            UpdateUndefinedQtyArray;
        end; //002
    end;

    local procedure UpdateUndefinedQty(): Boolean;
    begin
        UpdateUndefinedQtyArray;
        if ProdOrderLineHandling then // Avoid check for prod.journal lines
            exit(TRUE);
        exit(ABS(SourceQuantityArray[1]) >= ABS(TotalItemTrackingLine."Quantity (Base)"));
    end;

    local procedure UpdateUndefinedQtyArray();
    begin
        UndefinedQtyArray[1] := SourceQuantityArray[1] - TotalItemTrackingLine."Quantity (Base)";
        UndefinedQtyArray[2] := SourceQuantityArray[2] - TotalItemTrackingLine."Qty. to Handle (Base)";
        UndefinedQtyArray[3] := SourceQuantityArray[3] - TotalItemTrackingLine."Qty. to Invoice (Base)";
    end;

    local procedure TempRecIsValid() OK: Boolean;
    var
        ReservEntry: Record 337;
        RecordCount: Integer;
        IdenticalArray: ARRAY[2] OF Boolean;
    begin
        OK := FALSE;
        TempReservEntry.SETCURRENTKEY("Entry No.", Positive);
        ReservEntry.SETCURRENTKEY("Source ID", "Source Ref. No.", "Source Type",
          "Source Subtype", "Source Batch Name", "Source Prod. Order Line");

        ReservEntry.COPYFILTERS(TempReservEntry);

        if ReservEntry.FINDSET then
            REPEAT
                if NOT TempReservEntry.GET(ReservEntry."Entry No.", ReservEntry.Positive) then
                    exit(FALSE);
                if NOT EntriesAreIdentical(ReservEntry, TempReservEntry, IdenticalArray) then
                    exit(FALSE);
                RecordCount += 1;
            UNTIL ReservEntry.NEXT = 0;

        OK := RecordCount = TempReservEntry.COUNT;
    end;

    local procedure EntriesAreIdentical(var ReservEntry1: Record 337; var ReservEntry2: Record 337; var IdenticalArray: ARRAY[2] OF Boolean): Boolean;
    begin
        IdenticalArray[1] := (
                              (ReservEntry1."Entry No." = ReservEntry2."Entry No.") AND
                              (ReservEntry1."Item No." = ReservEntry2."Item No.") AND
                              (ReservEntry1."Location Code" = ReservEntry2."Location Code") AND
                              (ReservEntry1."Quantity (Base)" = ReservEntry2."Quantity (Base)") AND
                              (ReservEntry1."Reservation Status" = ReservEntry2."Reservation Status") AND
                              (ReservEntry1."Creation Date" = ReservEntry2."Creation Date") AND
                              (ReservEntry1."Transferred from Entry No." = ReservEntry2."Transferred from Entry No.") AND
                              (ReservEntry1."Source Type" = ReservEntry2."Source Type") AND
                              (ReservEntry1."Source Subtype" = ReservEntry2."Source Subtype") AND
                              (ReservEntry1."Source ID" = ReservEntry2."Source ID") AND
                              (ReservEntry1."Source Batch Name" = ReservEntry2."Source Batch Name") AND
                              (ReservEntry1."Source Prod. Order Line" = ReservEntry2."Source Prod. Order Line") AND
                              (ReservEntry1."Source Ref. No." = ReservEntry2."Source Ref. No.") AND
                              (ReservEntry1."Expected Receipt Date" = ReservEntry2."Expected Receipt Date") AND
                              (ReservEntry1."Shipment Date" = ReservEntry2."Shipment Date") AND
                              (ReservEntry1."Serial No." = ReservEntry2."Serial No.") AND
                              (ReservEntry1."Created By" = ReservEntry2."Created By") AND
                              (ReservEntry1."Changed By" = ReservEntry2."Changed By") AND
                              (ReservEntry1.Positive = ReservEntry2.Positive) AND
                              (ReservEntry1."Qty. per Unit of Measure" = ReservEntry2."Qty. per Unit of Measure") AND
                              (ReservEntry1.Quantity = ReservEntry2.Quantity) AND
                              (ReservEntry1."Action Message Adjustment" = ReservEntry2."Action Message Adjustment") AND
                              (ReservEntry1.Binding = ReservEntry2.Binding) AND
                              (ReservEntry1."Suppressed Action Msg." = ReservEntry2."Suppressed Action Msg.") AND
                              (ReservEntry1."Planning Flexibility" = ReservEntry2."Planning Flexibility") AND
                              (ReservEntry1."Lot No." = ReservEntry2."Lot No.") AND
                              (ReservEntry1."variant Code" = ReservEntry2."variant Code") AND
                              (ReservEntry1."Quantity Invoiced (Base)" = ReservEntry2."Quantity Invoiced (Base)"));

        IdenticalArray[2] := (
                              (ReservEntry1.Description = ReservEntry2.Description) AND
                              (ReservEntry1."New Serial No." = ReservEntry2."New Serial No.") AND
                              (ReservEntry1."New Lot No." = ReservEntry2."New Lot No.") AND
                              (ReservEntry1."Expiration Date" = ReservEntry2."Expiration Date") AND
                              (ReservEntry1."Warranty Date" = ReservEntry2."Warranty Date") AND
                              (ReservEntry1."New Expiration Date" = ReservEntry2."New Expiration Date"));

        exit(IdenticalArray[1] AND IdenticalArray[2]);
    end;

    local procedure QtyToHandleAndInvoiceChanged(var ReservEntry1: Record 337; var ReservEntry2: Record 337): Boolean;
    begin
        exit(
          (ReservEntry1."Qty. to Handle (Base)" <> ReservEntry2."Qty. to Handle (Base)") OR
          (ReservEntry1."Qty. to Invoice (Base)" <> ReservEntry2."Qty. to Invoice (Base)"));
    end;

    local procedure NextEntryNo(): Integer;
    begin
        LastEntryNo += 1;
        exit(LastEntryNo);
    end;

    local procedure WriteToDatabase();
    var
        Window: Dialog;
        ChangeType: Option Insert,Modify,Delete;
        EntryNo: Integer;
        NoOfLines: Integer;
        i: Integer;
        ModifyLoop: Integer;
        Decrease: Boolean;
    begin
        WITH Rec DO begin //002
            if CurrentFormIsOpen then begin
                TempReservEntry.LOCKTABLE;
                TempRecValid;

                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                    QtyToAddAsBlank := 0
                else
                    QtyToAddAsBlank := UndefinedQtyArray[1] * CurrentSignFactor;

                RESET;
                DELETEALL;

                Window.OPEN('#1############# @2@@@@@@@@@@@@@@@@@@@@@');
                Window.UPDATE(1, Text018);
                NoOfLines := TempItemTrackLineInsert.COUNT + TempItemTrackLineModify.COUNT + TempItemTrackLineDelete.COUNT;
                if TempItemTrackLineDelete.FindFirst() then begin
                    REPEAT
                        i := i + 1;
                        if i MOD 100 = 0 then
                            Window.UPDATE(2, ROUND(i / NoOfLines * 10000, 1));
                        RegisterChange(TempItemTrackLineDelete, TempItemTrackLineDelete, ChangeType::Delete, FALSE);
                        if TempItemTrackLineModify.GET(TempItemTrackLineDelete."Entry No.") then
                            TempItemTrackLineModify.DELETE;
                    UNTIL TempItemTrackLineDelete.NEXT = 0;
                    TempItemTrackLineDelete.DELETEALL;
                end;

                FOR ModifyLoop := 1 TO 2 DO begin
                    if TempItemTrackLineModify.FindFirst() then
                        REPEAT
                            if xTempItemTrackingLine.GET(TempItemTrackLineModify."Entry No.") then begin
                                // Process decreases before increases
                                Decrease := (xTempItemTrackingLine."Quantity (Base)" > TempItemTrackLineModify."Quantity (Base)");
                                if ((ModifyLoop = 1) AND Decrease) OR ((ModifyLoop = 2) AND NOT Decrease) then begin
                                    i := i + 1;
                                    if (xTempItemTrackingLine."Serial No." <> TempItemTrackLineModify."Serial No.") OR
                                       (xTempItemTrackingLine."Lot No." <> TempItemTrackLineModify."Lot No.") OR
                                       (xTempItemTrackingLine."Appl.-from Item Entry" <> TempItemTrackLineModify."Appl.-from Item Entry") OR
                                       (xTempItemTrackingLine."Appl.-to Item Entry" <> TempItemTrackLineModify."Appl.-to Item Entry")
                                    then begin
                                        RegisterChange(xTempItemTrackingLine, xTempItemTrackingLine, ChangeType::Delete, FALSE);
                                        RegisterChange(TempItemTrackLineModify, TempItemTrackLineModify, ChangeType::Insert, FALSE);
                                        if (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Handle (Base)") OR
                                           (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Invoice (Base)")
                                        then
                                            SetQtyToHandleAndInvoice(TempItemTrackLineInsert);
                                    end else begin
                                        RegisterChange(xTempItemTrackingLine, TempItemTrackLineModify, ChangeType::Modify, FALSE);
                                        SetQtyToHandleAndInvoice(TempItemTrackLineModify);
                                    end;
                                    TempItemTrackLineModify.DELETE;
                                end;
                            end else begin
                                i := i + 1;
                                TempItemTrackLineModify.DELETE;
                            end;
                            if i MOD 100 = 0 then
                                Window.UPDATE(2, ROUND(i / NoOfLines * 10000, 1));
                        UNTIL TempItemTrackLineModify.NEXT = 0;
                end;

                if TempItemTrackLineInsert.FindFirst() then begin
                    REPEAT
                        i := i + 1;
                        if i MOD 100 = 0 then
                            Window.UPDATE(2, ROUND(i / NoOfLines * 10000, 1));
                        if TempItemTrackLineModify.GET(TempItemTrackLineInsert."Entry No.") then
                            TempItemTrackLineInsert.TRANSFERFIELDS(TempItemTrackLineModify);
                        if NOT RegisterChange(TempItemTrackLineInsert, TempItemTrackLineInsert, ChangeType::Insert, FALSE) then
                            ERROR(Text005);
                        if (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Handle (Base)") OR
                           (TempItemTrackLineInsert."Quantity (Base)" <> TempItemTrackLineInsert."Qty. to Invoice (Base)")
                        then
                            SetQtyToHandleAndInvoice(TempItemTrackLineInsert);
                    UNTIL TempItemTrackLineInsert.NEXT = 0;
                    TempItemTrackLineInsert.DELETEALL;
                end;
                Window.CLOSE;
            end else begin
                TempReservEntry.LOCKTABLE;
                TempRecValid;

                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                    QtyToAddAsBlank := 0
                else
                    QtyToAddAsBlank := UndefinedQtyArray[1] * CurrentSignFactor;

                RESET;
                setfilter("Buffer Status", '<>%1', 0);
                DELETEALL;
                RESET;

                xTempItemTrackingLine.RESET;
                SETCURRENTKEY("Entry No.");
                xTempItemTrackingLine.SETCURRENTKEY("Entry No.");
                if xTempItemTrackingLine.FindFirst() then
                    REPEAT
                        Setrange("Lot No.", xTempItemTrackingLine."Lot No.");
                        Setrange("Serial No.", xTempItemTrackingLine."Serial No.");
                        if FindFirst() then begin
                            if RegisterChange(xTempItemTrackingLine, Rec, ChangeType::Modify, FALSE) then begin
                                EntryNo := xTempItemTrackingLine."Entry No.";
                                xTempItemTrackingLine := Rec;
                                xTempItemTrackingLine."Entry No." := EntryNo;
                                xTempItemTrackingLine.MODifY;
                            end;
                            SetQtyToHandleAndInvoice(Rec);
                            DELETE;
                        end else begin
                            RegisterChange(xTempItemTrackingLine, xTempItemTrackingLine, ChangeType::Delete, FALSE);
                            xTempItemTrackingLine.DELETE;
                        end;
                    UNTIL xTempItemTrackingLine.NEXT = 0;

                RESET;

                if FindFirst() then
                    REPEAT
                        if RegisterChange(Rec, Rec, ChangeType::Insert, FALSE) then begin
                            xTempItemTrackingLine := Rec;
                            xTempItemTrackingLine.INSERT;
                        end else
                            ERROR(Text005);
                        SetQtyToHandleAndInvoice(Rec);
                        DELETE;
                    UNTIL NEXT = 0;
            end;

            UpdateOrderTracking;
            ReestablishReservations; // Late Binding

            if NOT BlockCommit then
                COMMIT;
        end; //002
    end;

    local procedure RegisterChange(var OldTrackingSpecification: Record "Tracking Specification"; var NewTrackingSpecification: Record "Tracking Specification"; ChangeType: Option Insert,Modify,FullDelete,PartDelete,ModifyAll; ModifySharedFields: Boolean) OK: Boolean;
    var
        ReservEntry1: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        CreateReservEntry: Codeunit 99000830;
        ReservationMgt: Codeunit 99000845;
        QtyToAdd: Decimal;
        LostReservQty: Decimal;
        IdenticalArray: ARRAY[2] OF Boolean;
        NoSeries: Codeunit "No. Series";
    begin
        OK := FALSE;

        if ((CurrentSignFactor * NewTrackingSpecification."Qty. to Handle") < 0) AND
           (FormRunMode <> FormRunMode::"Drop Shipment")
        then begin
            NewTrackingSpecification."Expiration Date" := 0D;
            OldTrackingSpecification."Expiration Date" := 0D;
        end;

        CASE ChangeType OF
            ChangeType::Insert:
                begin
                    if (OldTrackingSpecification."Quantity (Base)" = 0) OR NOT OldTrackingSpecification.TrackingExists then
                        exit(TRUE);
                    TempReservEntry.Setrange("Serial No.", '');
                    TempReservEntry.Setrange("Lot No.", '');
                    OldTrackingSpecification."Quantity (Base)" :=
                      CurrentSignFactor *
                      ReservEngineMgt.AddItemTrackingToTempRecSet(
                        TempReservEntry, NewTrackingSpecification,
                        CurrentSignFactor * OldTrackingSpecification."Quantity (Base)", QtyToAddAsBlank,
                        ItemTrackingCode);
                    TempReservEntry.Setrange("Serial No.");
                    TempReservEntry.Setrange("Lot No.");

                    // Late Binding
                    if ReservEngineMgt.RetrieveLostReservQty(LostReservQty) then begin
                        TempItemTrackLineReserv := NewTrackingSpecification;
                        TempItemTrackLineReserv."Quantity (Base)" := LostReservQty * CurrentSignFactor;
                        TempItemTrackLineReserv.Insert();
                    end;

                    if OldTrackingSpecification."Quantity (Base)" = 0 then
                        exit(TRUE);

                    if FormRunMode = FormRunMode::Reclass then begin
                        CreateReservEntry.SetNewTrackingFromNewTrackingSpecification(OldTrackingSpecification);
                        CreateReservEntry.SetNewExpirationDate(OldTrackingSpecification."New Expiration Date");
                    end;
                    CreateReservEntry.SetDates(
                      NewTrackingSpecification."Warranty Date", NewTrackingSpecification."Expiration Date");
                    CreateReservEntry.SetApplyFromEntryNo(NewTrackingSpecification."Appl.-from Item Entry");
                    CreateReservEntry.SetApplyToEntryNo(NewTrackingSpecification."Appl.-to Item Entry");
                    CreateReservEntry.CreateReservEntryFor(
                      OldTrackingSpecification."Source Type",
                      OldTrackingSpecification."Source Subtype",
                      OldTrackingSpecification."Source ID",
                      OldTrackingSpecification."Source Batch Name",
                      OldTrackingSpecification."Source Prod. Order Line",
                      OldTrackingSpecification."Source Ref. No.",
                      OldTrackingSpecification."Qty. per Unit of Measure",
                      0,
                      OldTrackingSpecification."Quantity (Base)",
                      TempReservEntry);
                    CreateReservEntry.CreateEntry(OldTrackingSpecification."Item No.",
                      OldTrackingSpecification."variant Code",
                      OldTrackingSpecification."Location Code",
                      OldTrackingSpecification.Description,
                      ExpectedReceiptDate,
                      ShipmentDate, 0, CurrentEntryStatus);
                    CreateReservEntry.GetLastEntry(ReservEntry1);
                    if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then
                        ReservEngineMgt.UpdateActionMessages(ReservEntry1);

                    if ModifySharedFields then begin
                        ReservEntry1.SetPointerFilter();
                        //  ReservationMgt.SetPointerFilter(ReservEntry1);
                        ReservEntry1.Setrange("Lot No.", ReservEntry1."Lot No.");
                        ReservEntry1.Setrange("Serial No.", ReservEntry1."Serial No.");
                        ReservEntry1.setfilter("Entry No.", '<>%1', ReservEntry1."Entry No.");
                        ModifyFieldsWithinFilter(ReservEntry1, NewTrackingSpecification);
                    end;

                    OK := TRUE;
                end;
            ChangeType::Modify:
                begin
                    ReservEntry1.TRANSFERFIELDS(OldTrackingSpecification);
                    ReservEntry2.TRANSFERFIELDS(NewTrackingSpecification);

                    ReservEntry1."Entry No." := ReservEntry2."Entry No."; // if only entry no. has changed it should not trigger
                    if EntriesAreIdentical(ReservEntry1, ReservEntry2, IdenticalArray) then
                        exit(QtyToHandleAndInvoiceChanged(ReservEntry1, ReservEntry2));

                    if ABS(OldTrackingSpecification."Quantity (Base)") < ABS(NewTrackingSpecification."Quantity (Base)") then begin
                        // Item Tracking is added to any blank reservation entries:
                        TempReservEntry.Setrange("Serial No.", '');
                        TempReservEntry.Setrange("Lot No.", '');
                        QtyToAdd :=
                          CurrentSignFactor *
                          ReservEngineMgt.AddItemTrackingToTempRecSet(
                            TempReservEntry, NewTrackingSpecification,
                            CurrentSignFactor * (NewTrackingSpecification."Quantity (Base)" -
                                                 OldTrackingSpecification."Quantity (Base)"), QtyToAddAsBlank,
                            ItemTrackingCode);
                        TempReservEntry.Setrange("Serial No.");
                        TempReservEntry.Setrange("Lot No.");

                        // Late Binding
                        if ReservEngineMgt.RetrieveLostReservQty(LostReservQty) then begin
                            TempItemTrackLineReserv := NewTrackingSpecification;
                            TempItemTrackLineReserv."Quantity (Base)" := LostReservQty * CurrentSignFactor;
                            TempItemTrackLineReserv.INSERT;
                        end;

                        OldTrackingSpecification."Quantity (Base)" := QtyToAdd;
                        OldTrackingSpecification."Warranty Date" := NewTrackingSpecification."Warranty Date";
                        OldTrackingSpecification."Expiration Date" := NewTrackingSpecification."Expiration Date";
                        OldTrackingSpecification.Description := NewTrackingSpecification.Description;
                        RegisterChange(OldTrackingSpecification, OldTrackingSpecification,
                          ChangeType::Insert, NOT IdenticalArray[2]);
                    end else begin
                        TempReservEntry.Setrange("Serial No.", OldTrackingSpecification."Serial No.");
                        TempReservEntry.Setrange("Lot No.", OldTrackingSpecification."Lot No.");
                        OldTrackingSpecification."Serial No." := '';
                        OldTrackingSpecification."Lot No." := '';
                        OldTrackingSpecification."Warranty Date" := 0D;
                        OldTrackingSpecification."Expiration Date" := 0D;
                        QtyToAdd :=
                          CurrentSignFactor *
                          ReservEngineMgt.AddItemTrackingToTempRecSet(
                            TempReservEntry, OldTrackingSpecification,
                            CurrentSignFactor * (OldTrackingSpecification."Quantity (Base)" -
                                                 NewTrackingSpecification."Quantity (Base)"), QtyToAddAsBlank,
                            ItemTrackingCode);
                        TempReservEntry.Setrange("Serial No.");
                        TempReservEntry.Setrange("Lot No.");
                        RegisterChange(NewTrackingSpecification, NewTrackingSpecification,
                          ChangeType::PartDelete, NOT IdenticalArray[2]);
                    end;
                    OK := TRUE;
                end;
            ChangeType::FullDelete, ChangeType::PartDelete:
                begin
                    ReservationMgt.SetItemTrackingHandling(1); // Allow deletion of Item Tracking
                    ReservEntry1.TRANSFERFIELDS(OldTrackingSpecification);
                    ReservEntry1.SetPointerFilter();
                    // ReservationMgt.SetPointerFilter(ReservEntry1);
                    ReservEntry1.Setrange("Lot No.", ReservEntry1."Lot No.");
                    ReservEntry1.Setrange("Serial No.", ReservEntry1."Serial No.");
                    if ChangeType = ChangeType::FullDelete then begin
                        TempReservEntry.Setrange("Serial No.", OldTrackingSpecification."Serial No.");
                        TempReservEntry.Setrange("Lot No.", OldTrackingSpecification."Lot No.");
                        OldTrackingSpecification."Serial No." := '';
                        OldTrackingSpecification."Lot No." := '';
                        OldTrackingSpecification."Warranty Date" := 0D;
                        OldTrackingSpecification."Expiration Date" := 0D;
                        QtyToAdd :=
                          CurrentSignFactor *
                          ReservEngineMgt.AddItemTrackingToTempRecSet(
                            TempReservEntry, OldTrackingSpecification,
                            CurrentSignFactor * OldTrackingSpecification."Quantity (Base)", QtyToAddAsBlank,
                            ItemTrackingCode);
                        TempReservEntry.Setrange("Serial No.");
                        TempReservEntry.Setrange("Lot No.");
                        ReservationMgt.DeleteReservEntries(TRUE, 0, ReservEntry1)
                    end else begin
                        ReservationMgt.DeleteReservEntries(FALSE, ReservEntry1."Quantity (Base)" -
                          OldTrackingSpecification."Quantity Handled (Base)", ReservEntry1);
                        if ModifySharedFields then begin
                            ReservEntry1.Setrange("Reservation Status");
                            ModifyFieldsWithinFilter(ReservEntry1, OldTrackingSpecification);
                        end;
                    end;
                    OK := TRUE;
                end;
        end;
        SetQtyToHandleAndInvoice(NewTrackingSpecification);
    end;

    local procedure UpdateOrderTracking();
    var
        TempReservEntry: Record "Reservation Entry" temporary;
    begin
        if NOT ReservEngineMgt.CollectAffectedSurplusEntries(TempReservEntry) then
            exit;
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
            exit;
        ReservEngineMgt.UpdateOrderTracking(TempReservEntry);
    end;

    local procedure ModifyFieldsWithinFilter(var ReservEntry1: Record 337; var TrackingSpecification: Record "Tracking Specification");
    begin
        // Used to ensure that field values that are common to a SN/Lot are copied to all entries.
        if ReservEntry1.FindFirst() then
            REPEAT
                ReservEntry1.Description := TrackingSpecification.Description;
                ReservEntry1."Warranty Date" := TrackingSpecification."Warranty Date";
                ReservEntry1."Expiration Date" := TrackingSpecification."Expiration Date";
                ReservEntry1."New Serial No." := TrackingSpecification."New Serial No.";
                ReservEntry1."New Lot No." := TrackingSpecification."New Lot No.";
                ReservEntry1."New Expiration Date" := TrackingSpecification."New Expiration Date";
                ReservEntry1.MODifY;
            UNTIL ReservEntry1.NEXT = 0;
    end;

    local procedure SetQtyToHandleAndInvoice(TrackingSpecification: Record "Tracking Specification");
    var
        ReservEntry1: Record 337;
        ReservationMgt: Codeunit 99000845;
        TotalQtyToHandle: Decimal;
        TotalQtyToInvoice: Decimal;
        QtyToHandleThisLine: Decimal;
        QtyToInvoiceThisLine: Decimal;
    begin
        if IsCorrection then
            exit;

        TotalQtyToHandle := TrackingSpecification."Qty. to Handle (Base)" * CurrentSignFactor;
        TotalQtyToInvoice := TrackingSpecification."Qty. to Invoice (Base)" * CurrentSignFactor;

        ReservEntry1.TRANSFERFIELDS(TrackingSpecification);
        ReservEntry1.SetPointerFilter();
        //ReservationMgt.SetPointerFilter(ReservEntry1);
        ReservEntry1.Setrange("Lot No.", ReservEntry1."Lot No.");
        ReservEntry1.Setrange("Serial No.", ReservEntry1."Serial No.");
        if TrackingSpecification.TrackingExists then begin
            ItemTrackingMgt.SetPointerFilter(TrackingSpecification);
            TrackingSpecification.Setrange("Lot No.", TrackingSpecification."Lot No.");
            TrackingSpecification.Setrange("Serial No.", TrackingSpecification."Serial No.");

            if TrackingSpecification.FindFirst() then
                REPEAT
                    if NOT TrackingSpecification.Correction then begin
                        QtyToInvoiceThisLine :=
                          TrackingSpecification."Quantity Handled (Base)" - TrackingSpecification."Quantity Invoiced (Base)";
                        if ABS(QtyToInvoiceThisLine) > ABS(TotalQtyToInvoice) then
                            QtyToInvoiceThisLine := TotalQtyToInvoice;

                        if TrackingSpecification."Qty. to Invoice (Base)" <> QtyToInvoiceThisLine then begin
                            TrackingSpecification."Qty. to Invoice (Base)" := QtyToInvoiceThisLine;
                            TrackingSpecification.MODifY;
                        end;

                        TotalQtyToInvoice -= QtyToInvoiceThisLine;
                    end;
                UNTIL (TrackingSpecification.NEXT = 0);
        end;

        if TrackingSpecification."Lot No." <> '' then
            FOR ReservEntry1."Reservation Status" := ReservEntry1."Reservation Status"::Reservation TO
                ReservEntry1."Reservation Status"::Prospect
            DO begin
                ReservEntry1.Setrange("Reservation Status", ReservEntry1."Reservation Status");
                if ReservEntry1.FindFirst() then
                    REPEAT
                        QtyToHandleThisLine := ReservEntry1."Quantity (Base)";
                        QtyToInvoiceThisLine := QtyToHandleThisLine;

                        if ABS(QtyToHandleThisLine) > ABS(TotalQtyToHandle) then
                            QtyToHandleThisLine := TotalQtyToHandle;
                        if ABS(QtyToInvoiceThisLine) > ABS(TotalQtyToInvoice) then
                            QtyToInvoiceThisLine := TotalQtyToInvoice;

                        if (ReservEntry1."Qty. to Handle (Base)" <> QtyToHandleThisLine) OR
                           (ReservEntry1."Qty. to Invoice (Base)" <> QtyToInvoiceThisLine) AND NOT ReservEntry1.Correction
                        then begin
                            ReservEntry1."Qty. to Handle (Base)" := QtyToHandleThisLine;
                            ReservEntry1."Qty. to Invoice (Base)" := QtyToInvoiceThisLine;
                            ReservEntry1.MODifY;
                        end;

                        TotalQtyToHandle -= QtyToHandleThisLine;
                        TotalQtyToInvoice -= QtyToInvoiceThisLine;

                    UNTIL (ReservEntry1.NEXT = 0);
            end
        else
            if ReservEntry1.FindFirst() then
                if (ReservEntry1."Qty. to Handle (Base)" <> TotalQtyToHandle) OR
                   (ReservEntry1."Qty. to Invoice (Base)" <> TotalQtyToInvoice) AND NOT ReservEntry1.Correction
                then begin
                    ReservEntry1."Qty. to Handle (Base)" := TotalQtyToHandle;
                    ReservEntry1."Qty. to Invoice (Base)" := TotalQtyToInvoice;
                    ReservEntry1.MODifY;
                end;
    end;

    local procedure CollectPostedTransferEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary);
    var
        ItemEntryRelation: Record 6507;
        ItemLedgerEntry: Record 32;
    begin
        // Used for collecting information about posted Transfer Shipments from the created Item Ledger Entries.
        if TrackingSpecification."Source Type" <> DATABASE::"Transfer Line" then
            exit;

        ItemEntryRelation.SETCURRENTKEY("Order No.", "Order Line No.");
        ItemEntryRelation.Setrange("Order No.", TrackingSpecification."Source ID");
        ItemEntryRelation.Setrange("Order Line No.", TrackingSpecification."Source Ref. No.");

        CASE TrackingSpecification."Source Subtype" OF
            0: // Outbound
                ItemEntryRelation.Setrange("Source Type", DATABASE::"Transfer Shipment Line");
            1: // Inbound
                ItemEntryRelation.Setrange("Source Type", DATABASE::"Transfer Receipt Line");
        end;

        if ItemEntryRelation.FindFirst() then
            REPEAT
                ItemLedgerEntry.GET(ItemEntryRelation."Item Entry No.");
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification."Serial No." := ItemLedgerEntry."Serial No.";
                TempTrackingSpecification."Lot No." := ItemLedgerEntry."Lot No.";
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip;
                TempTrackingSpecification.INSERT;
            UNTIL ItemEntryRelation.NEXT = 0;
    end;

    local procedure CollectPostedAssemblyEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary);
    var
        ItemEntryRelation: Record 6507;
        ItemLedgerEntry: Record 32;
    begin
        // Used for collecting information about posted Assembly Lines from the created Item Ledger Entries.
        if (TrackingSpecification."Source Type" <> DATABASE::"Assembly Line") AND
           (TrackingSpecification."Source Type" <> DATABASE::"Assembly Header")
        then
            exit;

        ItemEntryRelation.SETCURRENTKEY("Order No.", "Order Line No.");
        ItemEntryRelation.Setrange("Order No.", TrackingSpecification."Source ID");
        ItemEntryRelation.Setrange("Order Line No.", TrackingSpecification."Source Ref. No.");
        if TrackingSpecification."Source Type" = DATABASE::"Assembly Line" then
            ItemEntryRelation.Setrange("Source Type", DATABASE::"Posted Assembly Line")
        else
            ItemEntryRelation.Setrange("Source Type", DATABASE::"Posted Assembly Header");

        if ItemEntryRelation.FindFirst() then
            REPEAT
                ItemLedgerEntry.GET(ItemEntryRelation."Item Entry No.");
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification."Serial No." := ItemLedgerEntry."Serial No.";
                TempTrackingSpecification."Lot No." := ItemLedgerEntry."Lot No.";
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip;
                TempTrackingSpecification.INSERT;
            UNTIL ItemEntryRelation.NEXT = 0;
    end;

    local procedure CollectPostedOutputEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary);
    var
        ItemLedgerEntry: Record 32;
        ProdOrderRoutingLine: Record 5409;
        BackwardFlushing: Boolean;
    begin
        // Used for collecting information about posted prod. order output from the created Item Ledger Entries.
        if TrackingSpecification."Source Type" <> DATABASE::"Prod. Order Line" then
            exit;

        if (TrackingSpecification."Source Type" = DATABASE::"Prod. Order Line") AND
           (TrackingSpecification."Source Subtype" = 3)
        then begin
            ProdOrderRoutingLine.Setrange(Status, TrackingSpecification."Source Subtype");
            ProdOrderRoutingLine.Setrange("Prod. Order No.", TrackingSpecification."Source ID");
            ProdOrderRoutingLine.Setrange("Routing Reference No.", TrackingSpecification."Source Prod. Order Line");
            if ProdOrderRoutingLine.FINDLAST then
                BackwardFlushing :=
                  ProdOrderRoutingLine."Flushing Method" = ProdOrderRoutingLine."Flushing Method"::Backward;
        end;

        ItemLedgerEntry.SETCURRENTKEY("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.Setrange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.Setrange("Order No.", TrackingSpecification."Source ID");
        ItemLedgerEntry.Setrange("Order Line No.", TrackingSpecification."Source Prod. Order Line");
        ItemLedgerEntry.Setrange("Entry Type", ItemLedgerEntry."Entry Type"::Output);

        if ItemLedgerEntry.FindFirst() then
            REPEAT
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification."Serial No." := ItemLedgerEntry."Serial No.";
                TempTrackingSpecification."Lot No." := ItemLedgerEntry."Lot No.";
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip;
                TempTrackingSpecification.INSERT;

                if BackwardFlushing then begin
                    SourceQuantityArray[1] += ItemLedgerEntry.Quantity;
                    SourceQuantityArray[2] += ItemLedgerEntry.Quantity;
                    SourceQuantityArray[3] += ItemLedgerEntry.Quantity;
                end;

            UNTIL ItemLedgerEntry.NEXT = 0;
    end;

    local procedure ZeroLineExists() OK: Boolean;
    var
        xTrackingSpec: Record "Tracking Specification";
    begin
        WITH Rec DO begin //002
            if ("Quantity (Base)" <> 0) OR TrackingExists then
                exit(FALSE);
            xTrackingSpec.COPY(Rec);
            RESET;
            Setrange("Quantity (Base)", 0);
            Setrange("Serial No.", '');
            Setrange("Lot No.", '');
            OK := NOT ISEMPTY;
            COPY(xTrackingSpec);
        end; //002
    end;

    local procedure AssignSerialNo();
    var
        EnterQuantityToCreate: Page 6513;
        QtyToCreate: Decimal;
        QtyToCreateInt: Integer;
        CreateLotNo: Boolean;
        CreateSNNo: Boolean;
    begin
        WITH Rec DO begin //002
            if ZeroLineExists then
                DELETE;
            CreateSNNo := false;

            QtyToCreate := UndefinedQtyArray[1] * QtySignFactor;
            if QtyToCreate < 0 then
                QtyToCreate := 0;

            if QtyToCreate MOD 1 <> 0 then
                ERROR(Text008);

            QtyToCreateInt := QtyToCreate;

            CLEAR(EnterQuantityToCreate);
            EnterQuantityToCreate.SetFields("Item No.", "variant Code", QtyToCreate, false, false);
            if EnterQuantityToCreate.RUNMODAL = ACTION::OK then begin
                EnterQuantityToCreate.GetFields(QtyToCreateInt, CreateLotNo, CreateSNNo);
                AssignSerialNoBatch(QtyToCreateInt, CreateLotNo);
            end;
        end; //002
    end;

    local procedure AssignSerialNoBatch(QtyToCreate: Integer; CreateLotNo: Boolean);
    var
        i: Integer;
    begin
        WITH Rec DO begin //002
            if QtyToCreate <= 0 then
                ERROR(Text009);
            if QtyToCreate MOD 1 <> 0 then
                ERROR(Text008);

            GetItem("Item No.");

            if CreateLotNo then begin
                TESTFIELD("Lot No.", '');
                Item.TESTFIELD("Lot Nos.");
                VALIDATE("Lot No.", NoSeriesMgt.GetNextNo(Item."Lot Nos.", WORKDATE, TRUE));
            end;

            Item.TESTFIELD("Serial Nos.");
            ItemTrackingDataCollection.SetSkipLot(TRUE);
            FOR i := 1 TO QtyToCreate DO begin
                VALIDATE("Quantity Handled (Base)", 0);
                VALIDATE("Quantity Invoiced (Base)", 0);
                VALIDATE("Serial No.", NoSeriesMgt.GetNextNo(Item."Serial Nos.", WORKDATE, TRUE));
                VALIDATE("Quantity (Base)", QtySignFactor);
                "Entry No." := NextEntryNo;
                if TestTempSpecificationExists then
                    ERROR('');
                INSERT;
                TempItemTrackLineInsert.TRANSFERFIELDS(Rec);
                TempItemTrackLineInsert.INSERT;
                if i = QtyToCreate then
                    ItemTrackingDataCollection.SetSkipLot(FALSE);
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
            end;
            CalculateSums;
        end; //002
    end;

    local procedure AssignLotNo();
    var
        QtyToCreate: Decimal;
    begin
        WITH Rec DO begin //002
            if ZeroLineExists then
                DELETE;

            if (SourceQuantityArray[1] * UndefinedQtyArray[1] <= 0) OR
               (ABS(SourceQuantityArray[1]) < ABS(UndefinedQtyArray[1]))
            then
                QtyToCreate := 0
            else
                QtyToCreate := UndefinedQtyArray[1];

            GetItem("Item No.");

            Item.TESTFIELD("Lot Nos.");
            VALIDATE("Quantity Handled (Base)", 0);
            VALIDATE("Quantity Invoiced (Base)", 0);
            VALIDATE("Lot No.", NoSeriesMgt.GetNextNo(Item."Lot Nos.", WORKDATE, TRUE));
            "Qty. per Unit of Measure" := QtyPerUOM;
            VALIDATE("Quantity (Base)", QtyToCreate);
            "Entry No." := NextEntryNo;
            TestTempSpecificationExists;
            INSERT;
            TempItemTrackLineInsert.TRANSFERFIELDS(Rec);
            TempItemTrackLineInsert.INSERT;
            ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
              TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
            CalculateSums;
        end; //002
    end;

    local procedure CreateCustomizedSN();
    var
        EnterCustomizedSN: Page 6515;
        QtyToCreate: Decimal;
        QtyToCreateInt: Integer;
        Increment: Integer;
        CreateLotNo: Boolean;
        CustomizedSN: Code[20];
        GetCreateSNInfo: Boolean;
    begin
        WITH Rec DO begin //002
            if ZeroLineExists then
                DELETE;

            QtyToCreate := UndefinedQtyArray[1] * QtySignFactor;
            if QtyToCreate < 0 then
                QtyToCreate := 0;

            if QtyToCreate MOD 1 <> 0 then
                ERROR(Text008);

            GetCreateSNInfo := true;
            QtyToCreateInt := QtyToCreate;

            CLEAR(EnterCustomizedSN);
            EnterCustomizedSN.SetFields("Item No.", "variant Code", QtyToCreate, FALSE, false);
            if EnterCustomizedSN.RUNMODAL = ACTION::OK then begin
                EnterCustomizedSN.GetFields(QtyToCreateInt, CreateLotNo, CustomizedSN, Increment, GetCreateSNInfo);
                CreateCustomizedSNBatch(QtyToCreateInt, CreateLotNo, CustomizedSN, Increment);
            end;
            CalculateSums;
        end; //002
    end;

    local procedure CreateCustomizedSNBatch(QtyToCreate: Decimal; CreateLotNo: Boolean; CustomizedSN: Code[20]; Increment: Integer);
    var
        TextManagement: Codeunit 49;
        i: Integer;
        Counter: Integer;
    begin
        WITH Rec DO begin //002
                          //>>  TextManagement.EvaluateIncStr(CustomizedSN, CustomizedSN);
            NoSeriesMgt.TestManual(Item."Serial Nos.");

            if QtyToCreate <= 0 then
                ERROR(Text009);
            if QtyToCreate MOD 1 <> 0 then
                ERROR(Text008);

            if CreateLotNo then begin
                TESTFIELD("Lot No.", '');
                Item.TESTFIELD("Lot Nos.");
                VALIDATE("Lot No.", NoSeriesMgt.GetNextNo(Item."Lot Nos.", WORKDATE, TRUE));
            end;

            FOR i := 1 TO QtyToCreate DO begin
                VALIDATE("Quantity Handled (Base)", 0);
                VALIDATE("Quantity Invoiced (Base)", 0);
                VALIDATE("Serial No.", CustomizedSN);
                VALIDATE("Quantity (Base)", QtySignFactor);
                "Entry No." := NextEntryNo;
                if TestTempSpecificationExists then
                    ERROR('');
                INSERT;
                TempItemTrackLineInsert.TRANSFERFIELDS(Rec);
                TempItemTrackLineInsert.INSERT;
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
                if i < QtyToCreate then begin
                    Counter := Increment;
                    REPEAT
                        CustomizedSN := INCSTR(CustomizedSN);
                        Counter := Counter - 1;
                    UNTIL Counter <= 0;
                end;
            end;
            CalculateSums;
        end; //002
    end;

    local procedure TestTempSpecificationExists() Exists: Boolean;
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        WITH Rec DO begin //002
            TrackingSpecification.COPY(Rec);
            SETCURRENTKEY("Lot No.", "Serial No.");
            Setrange("Serial No.", "Serial No.");
            if "Serial No." = '' then
                Setrange("Lot No.", "Lot No.");
            setfilter("Entry No.", '<>%1', "Entry No.");
            Setrange("Buffer Status", 0);
            Exists := NOT ISEMPTY;
            COPY(TrackingSpecification);
            if Exists AND CurrentFormIsOpen then
                if "Serial No." = '' then
                    MESSAGE(
                      Text011,
                      "Serial No.",
                      "Lot No.")
                else
                    MESSAGE(
                      Text012,
                      "Serial No.");
        end; //002
    end;

    local procedure TestExpirationDateMismatchOnTempSpec() Mismatch: Boolean;
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        WITH Rec DO begin //002
            if ("Expiration Date" = 0D) OR ("Lot No." = '') then
                exit(FALSE);

            TrackingSpecification.COPY(Rec);
            setfilter("Entry No.", '<>%1', "Entry No.");
            if ISEMPTY then
                Mismatch := FALSE
            else begin
                Setrange("Lot No.", "Lot No.");
                setfilter("Expiration Date", '<>%1', "Expiration Date");
                Setrange("Buffer Status", 0);
                Mismatch := NOT ISEMPTY;
            end;
            COPY(TrackingSpecification);
            if Mismatch AND CurrentFormIsOpen then
                MESSAGE(DifferentExpDateMsg, "Lot No.", "Expiration Date");
        end; //002
    end;

    local procedure VerifyNewTrackingSpecification(): Boolean;
    begin
        WITH Rec DO begin //002
            if TestTempSpecificationExists then
                exit(FALSE);

            exit(NOT TestExpirationDateMismatchOnTempSpec);
        end; //002
    end;

    local procedure QtySignFactor(): Integer;
    begin
        if SourceQuantityArray[1] < 0 then
            exit(-1);

        exit(1)
    end;

    procedure RegisterItemTrackingLines(SourceSpecification: Record "Tracking Specification"; AvailabilityDate: Date; var TempSpecification: Record "Tracking Specification" temporary);
    begin
        WITH Rec DO begin //002
            SourceSpecification.TESTFIELD("Source Type"); // Check if source has been set.
            if NOT CalledFromSynchWhseItemTrkg then
                TempSpecification.RESET;
            if NOT TempSpecification.FindFirst() then
                exit;

            IsCorrection := SourceSpecification.Correction;
            ExcludePostedEntries := TRUE;
            SetSourceSpec(SourceSpecification, AvailabilityDate);
            RESET;
            SETCURRENTKEY("Lot No.", "Serial No.");

            REPEAT
                Setrange("Lot No.", TempSpecification."Lot No.");
                Setrange("Serial No.", TempSpecification."Serial No.");
                if FindFirst() then begin
                    if IsCorrection then begin
                        "Quantity (Base)" :=
                          "Quantity (Base)" + TempSpecification."Quantity (Base)";
                        "Qty. to Handle (Base)" :=
                          "Qty. to Handle (Base)" + TempSpecification."Qty. to Handle (Base)";
                        "Qty. to Invoice (Base)" :=
                          "Qty. to Invoice (Base)" + TempSpecification."Qty. to Invoice (Base)";
                    end else
                        VALIDATE("Quantity (Base)",
                          "Quantity (Base)" + TempSpecification."Quantity (Base)");
                    MODifY;
                end else begin
                    TRANSFERFIELDS(SourceSpecification);
                    "Serial No." := TempSpecification."Serial No.";
                    "Lot No." := TempSpecification."Lot No.";
                    "Warranty Date" := TempSpecification."Warranty Date";
                    "Expiration Date" := TempSpecification."Expiration Date";
                    if FormRunMode = FormRunMode::Reclass then begin
                        "New Serial No." := TempSpecification."New Serial No.";
                        "New Lot No." := TempSpecification."New Lot No.";
                        "New Expiration Date" := TempSpecification."New Expiration Date"
                    end;
                    VALIDATE("Quantity (Base)", TempSpecification."Quantity (Base)");
                    "Entry No." := NextEntryNo;
                    INSERT;
                end;
            UNTIL TempSpecification.NEXT = 0;
            RESET;
            if FindFirst() then
                REPEAT
                    CheckLine(Rec);
                UNTIL NEXT = 0;

            Setrange("Lot No.", SourceSpecification."Lot No.");
            Setrange("Serial No.", SourceSpecification."Serial No.");

            CalculateSums;
            if UpdateUndefinedQty then
                WriteToDatabase
            else
                ERROR(Text014, TotalItemTrackingLine."Quantity (Base)",
                  LOWERCASE(TempReservEntry.TextCaption), SourceQuantityArray[1]);

            // Copy to inbound part of transfer
            if FormRunMode = FormRunMode::Transfer then
                SynchronizeLinkedSources('');
        end; //002
    end;

    local procedure SynchronizeLinkedSources(DialogText: Text[250]): Boolean;
    begin
        if CurrentSourceRowID = '' then
            exit(FALSE);
        if SecondSourceRowID = '' then
            exit(FALSE);

        ItemTrackingMgt.SynchronizeItemTracking(CurrentSourceRowID, SecondSourceRowID, DialogText);
        exit(TRUE);
    end;

    procedure SetBlockCommit(NewBlockCommit: Boolean);
    begin
        BlockCommit := NewBlockCommit;
    end;

    procedure SetCalledFromSynchWhseItemTrkg(CalledFromSynchWhseItemTrkg2: Boolean);
    begin
        CalledFromSynchWhseItemTrkg := CalledFromSynchWhseItemTrkg2;
    end;

    local procedure UpdateExpDateColor();
    begin
        WITH Rec DO begin //002
            if ("Buffer Status2" = "Buffer Status2"::"ExpDate blocked") OR (CurrentSignFactor < 0) then;
        end; //002
    end;

    local procedure UpdateExpDateEditable();
    begin
        WITH Rec DO begin //002
            ExpirationDateEditable :=
              NOT (("Buffer Status2" = "Buffer Status2"::"ExpDate blocked") OR (CurrentSignFactor < 0));
        end; //002
    end;

    local procedure LookupAvailable(LookupMode: Option "Serial No.","Lot No.");
    begin
        WITH Rec DO begin //002
            "Bin Code" := ForBinCode;
            ItemTrackingDataCollection.LookupTrackingAvailability(Rec, LookupMode);
            "Bin Code" := '';
            //CurrPage.UPDATE;
        end; //002
    end;

    local procedure LotSnAvailable(var TrackingSpecification: Record "Tracking Specification"; LookupMode: Option "Serial No.","Lot No."): Boolean;
    begin
        //>>  exit(ItemTrackingDataCollection.LotSNAvailable(TrackingSpecification, LookupMode));
    end;

    local procedure SelectEntries();
    var
        xTrackingSpec: Record "Tracking Specification";
        MaxQuantity: Decimal;
    begin
        WITH Rec DO begin //002
            xTrackingSpec.COPYFILTERS(Rec);
            MaxQuantity := UndefinedQtyArray[1];
            if MaxQuantity * CurrentSignFactor > 0 then
                MaxQuantity := 0;
            "Bin Code" := ForBinCode;
            ItemTrackingDataCollection.SelectMultipleTrackingNo(Rec, MaxQuantity, CurrentSignFactor);
            "Bin Code" := '';
            if FINDSET then
                REPEAT
                    CASE "Buffer Status" OF
                        "Buffer Status"::MODifY:
                            begin
                                if TempItemTrackLineModify.GET("Entry No.") then
                                    TempItemTrackLineModify.DELETE;
                                if TempItemTrackLineInsert.GET("Entry No.") then begin
                                    TempItemTrackLineInsert.TRANSFERFIELDS(Rec);
                                    TempItemTrackLineInsert.MODifY;
                                end else begin
                                    TempItemTrackLineModify.TRANSFERFIELDS(Rec);
                                    TempItemTrackLineModify.INSERT;
                                end;
                            end;
                        "Buffer Status"::INSERT:
                            begin
                                TempItemTrackLineInsert.TRANSFERFIELDS(Rec);
                                TempItemTrackLineInsert.INSERT;
                            end;
                    end;
                    "Buffer Status" := 0;
                    MODifY;
                UNTIL NEXT = 0;
            LastEntryNo := "Entry No.";
            CalculateSums;
            UpdateUndefinedQtyArray;
            COPYFILTERS(xTrackingSpec);
            //CurrPage.UPDATE(FALSE);
        end; //002
    end;

    local procedure ReestablishReservations();
    var
        LateBindingMgt: Codeunit 6502;
    begin
        if TempItemTrackLineReserv.FINDSET then
            REPEAT
                LateBindingMgt.ReserveItemTrackingLine(TempItemTrackLineReserv, 0, TempItemTrackLineReserv."Quantity (Base)");
                SetQtyToHandleAndInvoice(TempItemTrackLineReserv);
            UNTIL TempItemTrackLineReserv.NEXT = 0;
        TempItemTrackLineReserv.DELETEALL;
    end;

    procedure SetInbound(NewInbound: Boolean);
    begin
        InboundIsSet := TRUE;
        Inbound := NewInbound;
    end;

    local procedure TempRecValid();
    begin
        if NOT TempRecIsValid then
            ERROR(Text007);
    end;

    local procedure GetHandleSource(TrackingSpecification: Record "Tracking Specification"): Boolean;
    var
        QtyToHandleColumnIsHidden: Boolean;
    begin
        WITH TrackingSpecification DO begin
            if ("Source Type" = DATABASE::"Item Journal Line") AND ("Source Subtype" = 6) then begin // 6 => Prod.order line
                ProdOrderLineHandling := TRUE;
                exit(TRUE);  // Display Handle column for prod. orders
            end;
            QtyToHandleColumnIsHidden :=
              ("Source Type" IN
               [DATABASE::"Item Ledger Entry",
                DATABASE::"Item Journal Line",
                DATABASE::"Job Journal Line",
                DATABASE::"Requisition Line"]) OR
              (("Source Type" IN [DATABASE::"Sales Line", DATABASE::"Purchase Line", DATABASE::"Service Line"]) AND
               ("Source Subtype" IN [0, 2, 3])) OR
              (("Source Type" = DATABASE::"Assembly Line") AND ("Source Subtype" = 0));
        end;
        exit(NOT QtyToHandleColumnIsHidden);
    end;

    local procedure GetInvoiceSource(TrackingSpecification: Record "Tracking Specification"): Boolean;
    var
        QtyToInvoiceColumnIsHidden: Boolean;
    begin
        WITH TrackingSpecification DO begin
            QtyToInvoiceColumnIsHidden :=
              ("Source Type" IN
               [DATABASE::"Item Ledger Entry",
                DATABASE::"Item Journal Line",
                DATABASE::"Job Journal Line",
                DATABASE::"Requisition Line",
                DATABASE::"Transfer Line",
                DATABASE::"Assembly Line",
                DATABASE::"Assembly Header",
                DATABASE::"Prod. Order Line",
                DATABASE::"Prod. Order Component"]) OR
              (("Source Type" IN [DATABASE::"Sales Line", DATABASE::"Purchase Line", DATABASE::"Service Line"]) AND
               ("Source Subtype" IN [0, 2, 3, 4]))
        end;
        exit(NOT QtyToInvoiceColumnIsHidden);
    end;

    procedure SetSecondSourceID(SourceID: Integer; IsATO: Boolean);
    begin
        SecondSourceID := SourceID;
        IsAssembleToOrder := IsATO;
    end;

    local procedure SynchronizeWarehouseItemTracking();
    var
        WarehouseShipmentLine: Record 7321;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        WITH Rec DO begin //002
            if ItemTrackingMgt.ItemTrkgIsManagedByWhse(
                 "Source Type", "Source Subtype", "Source ID",
                 "Source Prod. Order Line", "Source Ref. No.", "Location Code", "Item No.")
            then
                exit;

            WarehouseShipmentLine.Setrange("Source Type", "Source Type");
            WarehouseShipmentLine.Setrange("Source Subtype", "Source Subtype");
            WarehouseShipmentLine.Setrange("Source No.", "Source ID");
            WarehouseShipmentLine.Setrange("Source Line No.", "Source Ref. No.");
            if WarehouseShipmentLine.FINDSET then
                REPEAT
                    DeleteWhseItemTracking(WarehouseShipmentLine);
                    WarehouseShipmentLine.CreateWhseItemTrackingLines;
                UNTIL WarehouseShipmentLine.NEXT = 0;
        end; //002
    end;

    local procedure DeleteWhseItemTracking(WarehouseShipmentLine: Record 7321);
    var
        WhseItemTrackingLine: Record 6550;
    begin
        WhseItemTrackingLine.Setrange("Source Type", DATABASE::"Warehouse Shipment Line");
        WhseItemTrackingLine.Setrange("Source ID", WarehouseShipmentLine."No.");
        WhseItemTrackingLine.Setrange("Source Ref. No.", WarehouseShipmentLine."Line No.");
        WhseItemTrackingLine.DELETEALL(TRUE);
    end;

    procedure GUIOpenForm();
    begin
        //001 Start
        UpdateUndefinedQty;
        //001 end
    end;

    procedure GUICloseForm();
    begin
        //001 Start
        if UpdateUndefinedQty then
            WriteToDatabase;
        if FormRunMode = FormRunMode::Transfer then
            SynchronizeLinkedSources('');
        //001 end
    end;

    procedure GUIGetRecords(var GUITrackingSpecification: Record "Tracking Specification" temporary);
    begin
        WITH Rec DO begin //002
                          //001 Start
            if FindFirst() then
                REPEAT
                    GUITrackingSpecification := Rec;
                    GUITrackingSpecification.INSERT;
                UNTIL NEXT = 0;
            //001 end
        end; //002
    end;

    procedure GUIInsertRecord(var GUITrackingSpecification: Record "Tracking Specification" temporary): Boolean;
    begin
        WITH Rec DO begin //002
                          //001 Start
            Rec := GUITrackingSpecification;
            "Entry No." := NextEntryNo;
            "Qty. per Unit of Measure" := QtyPerUOM;
            if (NOT InsertIsBlocked) AND (NOT ZeroLineExists) then
                if NOT TestTempSpecificationExists then begin
                    TempItemTrackLineInsert.TRANSFERFIELDS(Rec);
                    TempItemTrackLineInsert.INSERT;
                    INSERT;
                    ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                      TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 0);
                end;
            CalculateSums;

            exit(FALSE);
            //001 end
        end; //002
    end;

    procedure GUIModifyRecord(var GUITrackingSpecification: Record "Tracking Specification" temporary): Boolean;
    var
        xTempTrackingSpec: Record "Tracking Specification" temporary;
    begin
        WITH Rec DO begin //002
                          //001 Start
            Rec := GUITrackingSpecification;

            if NOT TestTempSpecificationExists then
                MODifY;

            if (xRec."Lot No." <> "Lot No.") OR (xRec."Serial No." <> "Serial No.") then begin
                xTempTrackingSpec := xRec;
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  xTempTrackingSpec, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 2);
            end;

            if TempItemTrackLineModify.GET("Entry No.") then
                TempItemTrackLineModify.DELETE;
            if TempItemTrackLineInsert.GET("Entry No.") then begin
                TempItemTrackLineInsert.TRANSFERFIELDS(Rec);
                TempItemTrackLineInsert.MODifY;
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  TempItemTrackLineInsert, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 1);
            end else begin
                TempItemTrackLineModify.TRANSFERFIELDS(Rec);
                TempItemTrackLineModify.INSERT;
                ItemTrackingDataCollection.UpdateTrackingDataSetWithChange(
                  TempItemTrackLineModify, CurrentSignFactor * SourceQuantityArray[1] < 0, CurrentSignFactor, 1);
            end;
            CalculateSums;

            exit(FALSE);
            //001 end
        end; //002
    end;


}