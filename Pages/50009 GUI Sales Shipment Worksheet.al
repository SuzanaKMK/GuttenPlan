page 50009 "GUI Sales Shipment Worksheet"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "GUI-to-BC Sales Line";
    SourceTableView = sorting("Entry No.") where("Processing Status" = FILTER('>New'));


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
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Transaction No. field.', Comment = '%';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document No. field.', Comment = '%';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Date field.', Comment = '%';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.', Comment = '%';
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Line No. field.', Comment = '%';
                }
                field("Item-Lot No."; Rec."Item-Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item-Lot No. field.', Comment = '%';
                }

                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Type field.', Comment = '%';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.', Comment = '%';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Variant Code field.', Comment = '%';
                }
                field("GUI Description"; Rec."GUI Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Description field.', Comment = '%';
                }
                field("GUI Type"; Rec."GUI Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Type field.', Comment = '%';
                }
                field("GUI Time of Action"; Rec."GUI Time of Action")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Time of Action field.', Comment = '%';
                }
                field("GUI User ID"; Rec."GUI User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI User ID field.', Comment = '%';
                }
                field("GUI Pallet"; Rec."GUI Pallet")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the GUI Pallet field.', Comment = '%';
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
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Lot No. field.', Comment = '%';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Expiration Date field.', Comment = '%';
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
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Posted Document No. field.', Comment = '%';
                }
                field("Posted Document Type"; Rec."Posted Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Posted Document Type field.', Comment = '%';
                }
            }
        }
        area(Factboxes)
        {

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

                action(SalesDocument)
                {
                    Caption = 'Sales Order';
                    ApplicationArea = Basic;
                    RunObject = Page "Sales Order";
                    RunPageLink = "No." = field("Document No.");
                    Image = DocumentEdit;
                }
                action(SalesShipDocument)
                {
                    Caption = 'Sales Shipment';
                    ApplicationArea = Basic;
                    RunObject = Page "Posted Sales Shipment Lines";
                    RunPageLink = "Order No." = field("Document No.");
                    Image = Documents;
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

                    Caption = 'Archi&ve Sales Lines';
                    Image = Archive;

                    trigger OnAction()
                    var
                        IntegrMgt: Codeunit GUIToBCIntegrationMgt;
                    begin
                        IntegrMgt.ArchiveSalesLines(Rec);
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
                        SalesCheck: Codeunit GUI_SalesCheckLine;
                    begin
                        SalesCheck.RunCheckLines(Rec);

                    end;
                }

                action("UpdateSalesOrder")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Update Sales Order';
                    Ellipsis = true;
                    Image = DocumentEdit;
                    Promoted = true;
                    PromotedIsBig = true;
                    PromotedCategory = Process;
                    ToolTip = 'Update document.';
                    trigger OnAction()
                    var

                    begin
                        CODEUNIT.RUN(CODEUNIT::"GUI Shipment Line-Post", Rec);
                        CurrPage.UPDATE(FALSE);


                    end;
                }

            }

            action(Post)
            {
                ApplicationArea = Manufacturing;
                Caption = 'P&ost Sales Order';
                Image = Post;
                ShortCutKey = 'F9';
                ToolTip = 'Finalize the document by posting the amounts and quantities to the related accounts in your company books.';

                Promoted = true;
                PromotedIsBig = true;

                PromotedCategory = Process;
                trigger OnAction()
                var

                    PostBatch: Codeunit 50032;
                begin
                    //006 Start
                    PostBatch.PostSalesDoc(Rec);
                    CurrPage.UPDATE(FALSE);
                end;
            }

        }
    }
}