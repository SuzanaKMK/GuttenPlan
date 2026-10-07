page 50011 "GUI Output Line Worksheet"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "GUI-to-BC Output Line";

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
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Prod. Order No. field.', Comment = '%';
                }

                field("Item-Lot No."; Rec."Item-Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item-Lot No. field.', Comment = '%';
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
                field("Journal Posted"; Rec."Journal Posted")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Posted field.', Comment = '%';
                }
                field("Journal Document No."; Rec."Journal Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Document No. field.', Comment = '%';
                }
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Template Name field.', Comment = '%';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Journal Batch Name field.', Comment = '%';
                }
                field("Last DateTime Modified"; Rec."Last DateTime Modified")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Last DateTime Modified field.', Comment = '%';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Entry No. field.', Comment = '%';
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


                action("Journals")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Open Output Journals';
                    Image = OpenJournal;

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
                        IntegrMgt.ArchiveOutputLines(Rec); //006
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
                        outputCheckLine: Codeunit GUI_OutputCheckLine;
                    begin
                        outputCheckLine.RunCheckLines(Rec);

                    end;
                }



            }
            action(CreateOutputJnl)
            {
                Caption = 'Create Output Jnl.';

                ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                ApplicationArea = Manufacturing;
                Promoted = true;
                PromotedIsBig = true;
                Image = PostOrder;
                PromotedCategory = Process;
                trigger OnAction()
                var
                begin
                    Codeunit.run(CODEUNIT::"GUI Output Line-Post", Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenOutputJnl)
            {
                Caption = 'Open Output Jnl.';

                ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                ApplicationArea = Manufacturing;
                Promoted = true;
                PromotedIsBig = true;
                Image = OpenJournal;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ItemJnlBatch: Record "Item Journal Batch";
                    GUIBCSetup: Record "GUI-to-BC Setup";
                    ItemJnlMgt: Codeunit ItemJnlManagement;
                begin
                    GUIBCSetup.Reset();
                    GUIBCSetup.Get();

                    if GUIBCSetup."Output Batch Name" <> '' then begin
                        ItemJnlBatch.Reset();
                        ItemJnlBatch.SetFilter("Journal Template Name", '%1', 'OUTPUT');
                        ItemJnlBatch.SetRange(Name, GUIBCSetup."Output Batch Name");
                        If ItemJnlBatch.FindFirst() then
                            ItemJnlMgt.TemplateSelectionFromBatch(ItemJnlBatch);
                    end;


                end;
            }
            action(Post)
            {
                ApplicationArea = Manufacturing;
                Caption = 'P&ost Output Journal';
                Image = Post;
                ShortCutKey = 'F9';
                ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                Promoted = true;
                PromotedIsBig = true;

                PromotedCategory = Process;
                trigger OnAction()
                var

                    PostBatch: Codeunit "GUI Output Line-Post Batch";
                begin
                    //005 Start
                    PostBatch.PostOutputJournal(Rec);
                    CurrPage.UPDATE(FALSE);
                    //005 end
                end;
            }

        }
    }

}

