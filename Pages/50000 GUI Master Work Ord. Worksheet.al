page 50000 "GUI Master Work Ord. Worksheet"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "GUI-to-BC Master WO Line";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {


                field("Processing Status"; Rec."Processing Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Processing Status field.', Comment = '%';
                }
                field("Ready for Processing"; Rec."Ready for Processing")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Ready for Processing field.', Comment = '%';
                }
                field(Processed; Rec.Processed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Processed field.', Comment = '%';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Order Date field.', Comment = '%';
                }
                field("Order Shift"; Rec."Order Shift")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Order Shift field.', Comment = '%';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item No. field.', Comment = '%';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Variant Code field.', Comment = '%';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Location Code field.', Comment = '%';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity field.', Comment = '%';
                }

                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Unit of Measure Code field.', Comment = '%';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity (Base) field.', Comment = '%';
                    Visible = false;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Routing No. field.', Comment = '%';
                }
                field(Mixes; Rec.Mixes)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Mixes field.', Comment = '%';
                }
                field("Production Line No."; Rec."Production Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Production Line No. field.', Comment = '%';
                }
                field("Validation Error"; Rec."Validation Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Validation Error field.', Comment = '%';
                }
                field("Validation Error Message"; Rec."Validation Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Validation Error Message field.', Comment = '%';
                }
                field("Prod. Order Status"; Rec."Prod. Order Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Prod. Order Status field.', Comment = '%';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Prod. Order No. field.', Comment = '%';
                }
                field("GUI User ID"; Rec."GUI User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI User ID field.', Comment = '%';
                }
            }
        }

    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;


                action("ProdOrder")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Production order';
                    Image = OpenJournal;
                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        //004 Start
                        IF NOT ProdOrder.GET(rec."Prod. Order Status", rec."Prod. Order No.") THEN
                            EXIT;

                        CASE rec."Prod. Order Status" OF
                            rec."Prod. Order Status"::Simulated:
                                PAGE.RUN(PAGE::"Simulated Production Order", ProdOrder);
                            rec."Prod. Order Status"::Planned:
                                PAGE.RUN(PAGE::"Planned Production Order", ProdOrder);
                            rec."Prod. Order Status"::"Firm Planned":
                                PAGE.RUN(PAGE::"Firm Planned Prod. Order", ProdOrder);
                            rec."Prod. Order Status"::Released:
                                PAGE.RUN(PAGE::"Released Production Order", ProdOrder);
                            rec."Prod. Order Status"::Finished:
                                PAGE.RUN(PAGE::"Finished Production Order", ProdOrder);
                        end;
                        //004 end
                    end;

                }
                action("Item")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item';
                    Image = Item;

                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ToolTip = 'View or change detailed information about the record that is being processed on the journal line.';
                }

                action(ItemLedgerEntry)
                {
                    Caption = 'Item Ledger E&ntries';

                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    ApplicationArea = Basic;
                    RunObject = Page "Item Ledger Entries";
                    RunPageView = sorting("Item No.");
                    RunPageLink = "Item No." = field("Item No.");
                    Image = ItemLedger;
                }


            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Archive")
                {
                    ApplicationArea = Manufacturing;

                    Caption = 'Archi&ve Worksheet Lines';
                    Image = Archive;

                    trigger OnAction()
                    var
                        IntegrMgt: Codeunit 50016;
                    begin

                        IntegrMgt.ArchiveMasterWorkOrders(Rec); //006
                        CurrPage.UPDATE(FALSE);

                    end;
                }

            }

            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("TestWorksheet")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Test';
                    Ellipsis = true;
                    Image = TestReport;
                    Promoted = true;
                    PromotedIsBig = true;
                    PromotedCategory = Process;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        WOCheckLine: Codeunit GUI_MasterWorkOrdCheckLine;
                    begin
                        WOCheckLine.RunCheckLines(Rec);

                    end;
                }



            }
            action(CreateProdOrder)
            {
                Caption = 'Create Production Order';

                ToolTip = '';

                ApplicationArea = Manufacturing;
                Promoted = true;
                PromotedIsBig = true;
                Image = PostOrder;
                PromotedCategory = Process;
                trigger OnAction()
                var
                begin
                    CODEUNIT.RUN(CODEUNIT::"GUI Master Work Ord.-Post", Rec);
                    CurrPage.UPDATE(FALSE);
                end;
            }

        }
    }
    var


    local procedure SetLastDateTimeModified();
    begin
        rec."User ID" := USERID;
        rec."Last DateTime Modified" := CURRENTDATETIME;
        rec."Last Date Modified" := DT2DATE(rec."Last DateTime Modified");
    end;

    procedure EmptyLine(): Boolean;
    begin
        EXIT(
          (rec."Item No." = '') AND (rec.Quantity = 0));
    end;

    procedure UpdateErrorMsg(Text: Text);
    begin
        //004 Start
        SetProcessingStatus(rec."Processing Status"::Error);
        rec."Validation Error Message" := COPYSTR(Text, 1, MAXSTRLEN(rec."Validation Error Message"));
        //004 end
    end;

    procedure SetProcessingStatus(NewProcessingStatus: Integer);
    begin
        //004 Start
        IF NewProcessingStatus > 0 THEN begin
            rec."Processing Status" := NewProcessingStatus;

            rec."Ready for Processing" := rec."Processing Status" = rec."Processing Status"::Ready;
            rec."Validation Error" := rec."Processing Status" = rec."Processing Status"::Error;
            rec.Processed := rec."Processing Status" = rec."Processing Status"::Processed;

            IF NOT rec."Validation Error" THEN
                rec."Validation Error Message" := '';
        end;
        //004 end
    end;

    procedure IsCheckLineAllowed(): Boolean;
    begin
        //004 Start
        EXIT(
          NOT rec.Processed AND (rec."Processing Status" > rec."Processing Status"::New));
        //004 end
    end;

    [IntegrationEvent(true, false)]
    procedure OnMoveMasterWorkOrderLine(ToRecordID: RecordID);
    begin
    end;

}