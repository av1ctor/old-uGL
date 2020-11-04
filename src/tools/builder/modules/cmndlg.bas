' ------------------------------------------------------------------------
' Visual Basic for MS-DOS Common Dialog Toolkit
'
' The Common Dialog Toolkit (CMNDLG.BAS and CMNDLGF.FRM)
' provides support for the following dialogs:
'       FileOpen
'       FileSave
'       FilePrint
'       FindText
'       ChangeText
'       ColorPalette
'       About
'
' Support for each dialog is provided via procedures with
' these same names that create the corresponding dialog
' and return user input to your program.  These procedures
' only provide the user interface and return user input.
' They do not actually carry out the corresponding actions
' such as opening the file.  Detailed descriptions of
' these procedures are contained in the comment headers
' above each.
'
' Special routines to preload (CmnDlgRegister) and unload
' (CmnDlgClose) the common dialog form for better
' performance (loaded forms display faster than unloaded
' forms) are also provided.  These routines are optional
' however as the common dialog form will automatically load
' and unload each time you invoke a common dialog.  Preloading
' the common dialog form will make common dialog access
' faster but will require more memory.
'
' All common dialogs are created from the same form (CMNDLGF.FRM).
' The necessary controls for each dialog are children of
' a container picture box for the dialog.  Thus the
' form (CMNDLGF.FRM) contains a picture box with
' appropriate controls for common dialog listed above.
' When a particular common dialog is created and displayed,
' the container picture box for that dialog is made visible
' (thus all controls on that picture box become visible)
' and the form is centered and sized to match the
' container picture box.
'
' To use these common dialogs in your programs, include
' CMNDLG.BAS and CMNDLGF.FRM in your program or use the
' supplied library (CMNDLG.LIB, CMNDLGA.LIB - AltMath version
' for Professional Edition only) and Quick library (CMNDLG.QLB)
' and call the appropriate procedure to invoke the dialog
' you need.
'
' Copyright (C) 1982-1992 Microsoft Corporation
'
' You have a royalty-free right to use, modify, reproduce
' and distribute the sample applications and toolkits provided with
' Visual Basic for MS-DOS (and/or any modified version)
' in any way you find useful, provided that you agree that
' Microsoft has no warranty, obligations or liability for
' any of the sample applications or toolkits.
' ------------------------------------------------------------------------

' Include file containing declarations for called procedures.
'$INCLUDE: 'CMNDLG.BI'

' Common dialog form
'$FORM frmCmnDlg

CONST FALSE = 0
CONST TRUE = NOT FALSE


' About common dialog support routine.
'
' Displays About dialog with custom picture and text.
' Dialog is centered and sized around the picture and
' text.  Text to be displayed is passed as an argument
' to procedure, picture must be created by the
' programmer in the DrawAboutPicture routine.
'
' Parameters:
'   AboutText - text to display in dialog.
'   ForeColor - sets the dialog foreground color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   BackColor - sets the dialog background color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   Flags     - Determines if picture is displayed.
'               Default is no picture.
'
SUB About (AboutText AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Flags AS INTEGER)
    ON LOCAL ERROR GOTO AboutError

    frmCmnDlg.Caption = "About"         ' Set form caption.

    ' Set dialog colors.
    frmCmnDlg.ForeColor = ForeColor
    frmCmnDlg.BackColor = BackColor
    frmCmnDlg.pctAbout.ForeColor = ForeColor
    frmCmnDlg.pctAbout.BackColor = BackColor
    frmCmnDlg.pctAboutPict.ForeColor = ForeColor
    frmCmnDlg.pctAboutPict.BackColor = BackColor
    frmCmnDlg.lblAboutText.ForeColor = ForeColor
    frmCmnDlg.lblAboutText.BackColor = BackColor
    frmCmnDlg.cmdAboutOK.BackColor = BackColor

    ' Determine if picture should be displayed.
    IF Flags = 1 THEN
        CALL DrawAboutPicture           ' Routine that draws picture.
        PictWidth% = frmCmnDlg.pctAboutPict.Width   ' Get Width and Height of picture for
        PictHeight% = frmCmnDlg.pctAboutPict.Height ' determining size of dialog.
    ELSE
        frmCmnDlg.pctAboutPict.visible = FALSE      ' Make picture visible.
        PictWidth% = 0
        PictHeight% = 0
    END IF

    ' Size and position label correctly for text display.
    frmCmnDlg.lblAboutText.Caption = AboutText
    frmCmnDlg.lblAboutText.MOVE frmCmnDlg.pctAboutPict.Left + PictWidth% + 3, frmCmnDlg.lblAboutText.Top, frmCmnDlg.TEXTWIDTH(frmCmnDlg.lblAboutText.Caption), frmCmnDlg.TEXTHEIGHT(frmCmnDlg.lblAboutText.Caption)
    LabelWidth% = frmCmnDlg.lblAboutText.Width      ' Get Width and Height of text for
    LabelHeight% = frmCmnDlg.lblAboutText.Height    ' determining size of dialog.

    ' Size and position About container.
    frmCmnDlg.pctAbout.BorderStyle = 0
    frmCmnDlg.pctAbout.visible = TRUE
    frmCmnDlg.pctAbout.Width = PictWidth% + LabelWidth% + 8
    IF LabelHeight% > PictHeight% THEN
        frmCmnDlg.pctAbout.Height = LabelHeight% + 6
    ELSE
        frmCmnDlg.pctAbout.Height = PictHeight% + 5
    END IF

    ' Center command button at the bottom of the dialog.
    frmCmnDlg.cmdAboutOK.MOVE (frmCmnDlg.pctAbout.ScaleWidth - frmCmnDlg.cmdAboutOK.Width) \ 2, frmCmnDlg.pctAbout.ScaleHeight - 3
    frmCmnDlg.cmdAboutOK.Default = TRUE
    frmCmnDlg.cmdAboutOK.Cancel = TRUE

    ' Size and center dialog.
    frmCmnDlg.MOVE frmCmnDlg.Left, frmCmnDlg.Top, frmCmnDlg.pctAbout.Width + 2, frmCmnDlg.pctAbout.Height + 2
    frmCmnDlg.MOVE (SCREEN.Width - frmCmnDlg.Width) \ 2, ((SCREEN.Height - frmCmnDlg.Height) \ 2) - 2

    ' Display dialog modally.
    frmCmnDlg.SHOW 1

    ' Hide or unload dialog and return control to user's program.
    ' (Hide if user chose to preload form for performance.)
    IF LEFT$(frmCmnDlg.Tag, 1) = "H" THEN
        frmCmnDlg.pctAbout.visible = FALSE
        frmCmnDlg.HIDE
    ELSE
        UNLOAD frmCmnDlg
    END IF

    EXIT SUB

' Error handling routine.
AboutError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load dialog.", 0, "About"
          EXIT SUB
    CASE ELSE
          RESUME NEXT
    END SELECT
END SUB

' ChangeText common dialog support routine.
'
' Displays Change dialog which allows users to enter text
' to find and change.  Also allows user to specify options
' for Change operation. This procedure only provides
' the user interface and returns user input.  It does
' not actually carry out the corresponding action.
'
' Parameters:
'   FText - returns text the user wants to change.
'           To supply default find text in dialog, assign
'           default to FText then pass it to this procedure.
'   CText - returns replacement text for FText.
'           To supply default change text in dialog,
'           assign default to CText then pass it to
'           this procedure.
'   ForeColor - sets the dialog foreground color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   BackColor - sets the dialog background color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   Options - Bit field that returns user's option
'           selections as follows:
'              1 - Match Case (default is no match case)
'              2 - Whole Word (default is no whole word match)
'              4 - Replace all occurances of FText with CText (default is Find and Verify)
'           To supply default options, set appropriate
'           bit position in Options then pass it to this
'           procedure.  Note, "4 - Replace all occurances"
'           is a return value only.
'   Flags - Bit field that determines which dialog options
'           are available to the user.  Field is defined as follows:
'              1 - Don't display Match Case check box (default is display check box)
'              2 - Don't display Whole Word check box (default is display check box)
'              4 - Don't display Change All command button (default is display button)
'           To change option availability, set appropriate
'           bit position in Flags then pass it to this
'           procedure.
'   Cancel - returns whether or not user pressed the dialog's Cancel
'           button.  True (-1) means the user canceled the dialog.
'
SUB ChangeText (FText AS STRING, CText AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Options AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)
    ON LOCAL ERROR GOTO ChangeTextError

    frmCmnDlg.Caption = "Change"        ' Set form caption.
    
    ' Determine if Match Case check box will be displayed to the user.
    frmCmnDlg.chkSearchCase.visible = (Flags AND 1) <> 1
    frmCmnDlg.chkSearchCase.Top = 8     ' Position check box correctly.
    frmCmnDlg.chkSearchCase.value = (Options AND 1)

    ' Determine if Whole Word check box will be displayed to the user.
    frmCmnDlg.chkSearchWord.visible = (Flags AND 2) <> 2
    frmCmnDlg.chkSearchWord.Top = 9
    frmCmnDlg.chkSearchWord.value = (Options AND 2) - .5 * (Options AND 2)

    ' Determine if Change All command button will be displayed to the user.
    temp% = (Flags AND 4) <> 4
    frmCmnDlg.cmdSearchChangeAll.visible = temp%
    frmCmnDlg.cmdSearchCancel.Top = 4 - (3 * temp%)

    ' Turn off direction option (only available in FindText dialog).
    frmCmnDlg.fraSearchDir.visible = FALSE

    ' Supply default find text if present.
    frmCmnDlg.txtSearchFind.Text = FText

    ' Supply default change text if present.
    frmCmnDlg.txtSearchChange.Text = CText

    ' Set default and cancel command buttons.
    frmCmnDlg.cmdSearchFind.Default = TRUE
    frmCmnDlg.cmdSearchCancel.Cancel = TRUE

    ' Turn on Change edit field and Change All command button
    frmCmnDlg.txtSearchChange.visible = TRUE
    frmCmnDlg.lblSearchChange.visible = TRUE
    frmCmnDlg.cmdSearchFind.Caption = "Find and &Verify"

    ' Size and position Find/Change container.
    frmCmnDlg.pctFindText.Height = 11
    frmCmnDlg.pctFindText.BorderStyle = 0
    frmCmnDlg.pctFindText.visible = TRUE

    ' Size and center dialog.
    frmCmnDlg.MOVE frmCmnDlg.Left, frmCmnDlg.Top, frmCmnDlg.pctFindText.Width + 2, frmCmnDlg.pctFindText.Height + 2
    frmCmnDlg.MOVE (SCREEN.Width - frmCmnDlg.Width) \ 2, ((SCREEN.Height - frmCmnDlg.Height) \ 2) - 2

    ' Set dialog colors.
    frmCmnDlg.ForeColor = ForeColor
    frmCmnDlg.BackColor = BackColor
    frmCmnDlg.pctFindText.ForeColor = ForeColor
    frmCmnDlg.pctFindText.BackColor = BackColor
    frmCmnDlg.lblSearchFind.ForeColor = ForeColor
    frmCmnDlg.lblSearchFind.BackColor = BackColor
    frmCmnDlg.txtSearchFind.ForeColor = ForeColor
    frmCmnDlg.txtSearchFind.BackColor = BackColor
    frmCmnDlg.lblSearchChange.ForeColor = ForeColor
    frmCmnDlg.lblSearchChange.BackColor = BackColor
    frmCmnDlg.txtSearchChange.ForeColor = ForeColor
    frmCmnDlg.txtSearchChange.BackColor = BackColor
    frmCmnDlg.fraSearchDir.ForeColor = ForeColor
    frmCmnDlg.fraSearchDir.BackColor = BackColor
    FOR i% = 0 TO 1
        frmCmnDlg.optSearchDir(i%).ForeColor = ForeColor
        frmCmnDlg.optSearchDir(i%).BackColor = BackColor
    NEXT i%
    frmCmnDlg.chkSearchCase.ForeColor = ForeColor
    frmCmnDlg.chkSearchCase.BackColor = BackColor
    frmCmnDlg.chkSearchWord.ForeColor = ForeColor
    frmCmnDlg.chkSearchWord.BackColor = BackColor
    frmCmnDlg.cmdSearchFind.BackColor = BackColor
    frmCmnDlg.cmdSearchCancel.BackColor = BackColor
    frmCmnDlg.cmdSearchChangeAll.BackColor = BackColor

    ' Display dialog modally.
    frmCmnDlg.SHOW 1

    ' Determine if user canceled dialog.
    IF frmCmnDlg.cmdSearchCancel.Tag <> "FALSE" THEN
        Cancel = TRUE
    ' If not, return find text, change text, and user options.
    ELSE
        Cancel = FALSE
        FText = frmCmnDlg.txtSearchFind.Text
        CText = frmCmnDlg.txtSearchChange.Text
        Options = frmCmnDlg.chkSearchCase.value OR 2 * frmCmnDlg.chkSearchWord.value OR 4 * VAL(frmCmnDlg.cmdSearchChangeAll.Tag)
        frmCmnDlg.cmdSearchCancel.Tag = ""
    END IF

    ' Hide or unload dialog and return control to user's program.
    ' (Hide if user chose to preload form for performance.)
    IF LEFT$(frmCmnDlg.Tag, 1) = "H" THEN
        frmCmnDlg.pctFindText.visible = FALSE
        frmCmnDlg.HIDE
    ELSE
        UNLOAD frmCmnDlg
    END IF

    EXIT SUB

' Error handling routine.
ChangeTextError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load dialog.", 0, "ChangeText"
          Cancel = TRUE
          EXIT SUB
    CASE ELSE
          RESUME NEXT
    END SELECT
END SUB

' CmnDlgClose common dialog support routine
'
' Unloads common dialog form (if you have preloaded it for
' better performance) so program will terminate,
' otherwise common dialog form will remain loaded but
' invisible.  This routine should be called if
' CmnDlgRegister was used to preload the form.  If
' CmnDlgRegister was not used, the form will be unloaded
' after each use.
'
SUB CmnDlgClose ()
    UNLOAD frmCmnDlg            ' Unload form.
END SUB

' CmnDlgRegister common dialog support routine
'
' Loads and registers common dialog form before using it
' to obtain better performance (loaded forms display faster
' than unloaded forms).  Form will remain loaded (but
' invisible) until this routine is called again to
' unload it.  Thus, all common dialog usage in your
' program will be faster (form is not loaded and unload
' each time a common dialog is invoked).  Keeping the
' form loaded requires more memory, however, than loading
' and unloading it each time a common dialog is used.
'
' Use of this routine is optional since the common dialog
' form does not need to be loaded before it is used (each
' common dialog routine will load the form is it is not
' loaded).
'
' Parameters:
'   Success - returns TRUE (-1) if the load or unload
'           attempt was successful, otherwise returns
'           FALSE (0).
'
SUB CmnDlgRegister (Success AS INTEGER)
    ' Set up error handling.
    ON LOCAL ERROR GOTO RegisterError

    LOAD frmCmnDlg              ' Load form.
    frmCmnDlg.Tag = "H"         ' Set flag for keeping form loaded after
                                ' each common dialog usage.

    Success = TRUE
    EXIT SUB

' Option error handling routine.
' Trap errors that occur when preloading dialog.
RegisterError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load Common Dialogs.", 0, "Common Dialog"
          Success = FALSE
          EXIT SUB
    CASE ELSE
          MSGBOX ERROR$ + ".  Can't load Common Dialogs.", 0, "Common Dialog"
          Success = FALSE
          EXIT SUB
    END SELECT
END SUB

' ColorPalette common dialog support routine
'
' Displays Color dialog which allows users to select a
' a color.  This procedure only provides the user
' interface and returns user input.  It does
' not actually carry out the corresponding action.
'
' Parameters:
'   ColorNum - returns the Basic color number (0-15) that
'           the user selected.  To supply a default
'           color choice in dialog, assign default to
'           ColorNum then pass it to this procedure.
'   ForeColor - sets the dialog foreground color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   BackColor - sets the dialog background color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   Cancel - returns whether or not user pressed the dialog's Cancel
'           button.  True (-1) means the user cancelled the dialog.
'
SUB ColorPalette (ColorNum AS INTEGER, ForeColor AS INTEGER, BackColor AS INTEGER, Cancel AS INTEGER)
    ON LOCAL ERROR GOTO ColorPaletteError

    frmCmnDlg.Caption = "Color Palette"     ' Set form caption.

    ' Determine default color choice and signal it
    ' with a border.
    frmCmnDlg.pctColors(0).Tag = STR$(ColorNum)     ' Mark selected color.
    frmCmnDlg.pctColors(ColorNum).TabStop = TRUE    ' Set tabstop for this color.
    frmCmnDlg.pctColors(ColorNum).PRINT "ÚÄÄÄÄÄ¿"    ' Display border around color.
    frmCmnDlg.pctColors(ColorNum).PRINT "³     ³"
    frmCmnDlg.pctColors(ColorNum).PRINT "ÀÄÄÄÄÄÙ"

    ' Set default and cancel command buttons.
    frmCmnDlg.cmdColorOK.Default = TRUE
    frmCmnDlg.cmdColorCancel.Cancel = TRUE

    ' Size and position ColorPalette container.
    frmCmnDlg.pctColorPalette.BorderStyle = 0
    frmCmnDlg.pctColorPalette.visible = TRUE

    ' Size and center dialog.
    frmCmnDlg.MOVE frmCmnDlg.Left, frmCmnDlg.Top, frmCmnDlg.pctColorPalette.Width + 2, frmCmnDlg.pctColorPalette.Height + 2
    frmCmnDlg.MOVE (SCREEN.Width - frmCmnDlg.Width) \ 2, ((SCREEN.Height - frmCmnDlg.Height) \ 2) - 2

    ' Set dialog colors.
    frmCmnDlg.ForeColor = ForeColor
    frmCmnDlg.BackColor = BackColor
    frmCmnDlg.pctColorPalette.ForeColor = ForeColor
    frmCmnDlg.pctColorPalette.BackColor = BackColor
    frmCmnDlg.fraColors.ForeColor = ForeColor
    frmCmnDlg.fraColors.BackColor = BackColor
    frmCmnDlg.lblColors.ForeColor = ForeColor
    frmCmnDlg.lblColors.BackColor = BackColor
    frmCmnDlg.cmdColorOK.BackColor = BackColor
    frmCmnDlg.cmdColorCancel.BackColor = BackColor

    ' Display dialog modally.
    frmCmnDlg.SHOW 1

    ' Determine if user canceled dialog.
    IF frmCmnDlg.cmdColorCancel.Tag <> "FALSE" THEN
        Cancel = TRUE
    ' If not, return ColorNum.
    ELSE
        Cancel = FALSE
        ColorNum = VAL(frmCmnDlg.pctColors(0).Tag)
        frmCmnDlg.cmdColorCancel.Tag = ""
    END IF

    ' Hide or unload dialog and return control to user's program.
    ' (Hide if user chose to preload form for performance.)
    IF LEFT$(frmCmnDlg.Tag, 1) = "H" THEN
        frmCmnDlg.pctColors(VAL(frmCmnDlg.pctColors(0).Tag)).TabStop = FALSE
        frmCmnDlg.pctColors(VAL(frmCmnDlg.pctColors(0).Tag)).CLS
        frmCmnDlg.pctColorPalette.visible = FALSE
        frmCmnDlg.HIDE
    ELSE
        UNLOAD frmCmnDlg
    END IF

    EXIT SUB

' Error handling routine.
ColorPaletteError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load dialog.", 0, "ColorPalette"
          Cancel = TRUE
          EXIT SUB
    CASE ELSE
          RESUME NEXT
    END SELECT
END SUB

' About Picture drawing routine for About common dialog.
'
' Creates custom text-mode (ASCII) picture to be displayed
' in About dialog.  Add code here to create the picture
' you want to display in your About dialog.  Use PRINT
' method and ForeColor and BackColor properties to
' display characters and set picture Height and Width
' properties appropriately.
'
SUB DrawAboutPicture ()
    frmCmnDlg.pctAboutPict.Height = 8           ' Set picture height.
    frmCmnDlg.pctAboutPict.Width = 15           ' Set picture width.
    frmCmnDlg.pctAboutPict.BorderStyle = 1      ' Set border style.
    frmCmnDlg.pctAboutPict.visible = TRUE       ' Make picture visible.

    ' Display picture.
    frmCmnDlg.pctAboutPict.PRINT "  Microsoft  "
    frmCmnDlg.pctAboutPict.PRINT " Visual Basic"
    frmCmnDlg.pctAboutPict.PRINT "             "
    frmCmnDlg.pctAboutPict.PRINT " Programming "
    frmCmnDlg.pctAboutPict.PRINT "  System for "
    frmCmnDlg.pctAboutPict.PRINT "    MS-DOS   "
END SUB

' FileOpen common dialog support routine
'
' Displays Open dialog which allows users to select a
' file from disk.  This procedure only provides
' the user interface and returns user input.  It does
' not actually carry out the corresponding action.
'
' Parameters:
'   FileName - returns the name (without path) of the
'           file the user wants to open.  To supply
'           default filename in dialog, assign default
'           to FileName then pass it to this procedure.
'   PathName - returns the path (without filename) of
'           the file the user wants to open.  To supply
'           default path in dialog, assign default to
'           PathName then pass it to this procedure.
'           Note, only pass a valid drive and path. Do
'           not include a filename or file pattern.
'   DefaultExt - sets the default search pattern for the
'           File Listbox.  Default pattern when DefaultExt
'           is null is "*.*".  To specify a different
'           search pattern (i.e. "*.BAS"), assign new
'           value to DefaultExt then pass it to this
'           procedure.
'   DialogTitle - sets the dialog title.  Default title
'           when DialogTitle is null is "Open".  To
'           specify a different title (i.e. "Open My File"),
'           assign new value to DialogTitle then pass it to
'           this procedure.
'   ForeColor - sets the dialog foreground color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   BackColor - sets the dialog background color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   Flags - unused.  Use this to customize dialog action if needed.
'   Cancel - returns whether or not user pressed the dialog's Cancel
'           button.  True (-1) means the user cancelled the dialog.
'
SUB FileOpen (FileName AS STRING, PathName AS STRING, DefaultExt AS STRING, DialogTitle AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)
    ' Set up error handling for option validation.
    ON LOCAL ERROR GOTO FileOpenError

    ' Set form caption.
    IF DialogTitle = "" THEN
        frmCmnDlg.Caption = "Open"
    ELSE
        frmCmnDlg.Caption = DialogTitle
    END IF

    ' Determine search pattern for file listbox.
    IF DefaultExt <> "" THEN
        frmCmnDlg.filOpenList.Pattern = DefaultExt
    ELSE
        frmCmnDlg.filOpenList.Pattern = "*.*"
    END IF

    ' Determine default path.
    IF PathName <> "" THEN
        ' Set drive and path for file-system controls.
        ' Set Directory listbox path.  If PathName is different
        ' than current path, PathChange event will be triggered
        ' which updates Drive listbox drive and File listbox path.
        frmCmnDlg.dirOpenList.Path = PathName
    END IF
    ' Display current path to the user.
    frmCmnDlg.lblOpenPath.Caption = frmCmnDlg.filOpenList.Path

    ' Determine default filename to display in edit field.
    IF FileName <> "" THEN
        frmCmnDlg.txtOpenFile.Text = UCASE$(FileName)
    ELSE
        frmCmnDlg.txtOpenFile.Text = frmCmnDlg.filOpenList.Pattern
    END IF

    ' Set default and cancel command buttons.
    frmCmnDlg.cmdOpenOK.Default = TRUE
    frmCmnDlg.cmdOpenCancel.Cancel = TRUE

    ' Size and position Open/Save container.
    frmCmnDlg.pctFileOpen.BorderStyle = 0
    frmCmnDlg.pctFileOpen.visible = TRUE

    ' Size and center dialog.
    frmCmnDlg.MOVE frmCmnDlg.Left, frmCmnDlg.Top, frmCmnDlg.pctFileOpen.Width + 2, frmCmnDlg.pctFileOpen.Height + 2
    frmCmnDlg.MOVE (SCREEN.Width - frmCmnDlg.Width) \ 2, ((SCREEN.Height - frmCmnDlg.Height) \ 2) - 2

    ' Set dialog colors.
    frmCmnDlg.ForeColor = ForeColor
    frmCmnDlg.BackColor = BackColor
    frmCmnDlg.pctFileOpen.ForeColor = ForeColor
    frmCmnDlg.pctFileOpen.BackColor = BackColor
    frmCmnDlg.lblOpenFile.ForeColor = ForeColor
    frmCmnDlg.lblOpenFile.BackColor = BackColor
    frmCmnDlg.txtOpenFile.ForeColor = ForeColor
    frmCmnDlg.txtOpenFile.BackColor = BackColor
    frmCmnDlg.lblOpenPath.ForeColor = ForeColor
    frmCmnDlg.lblOpenPath.BackColor = BackColor
    frmCmnDlg.filOpenList.ForeColor = ForeColor
    frmCmnDlg.filOpenList.BackColor = BackColor
    frmCmnDlg.drvOpenList.ForeColor = ForeColor
    frmCmnDlg.drvOpenList.BackColor = BackColor
    frmCmnDlg.dirOpenList.ForeColor = ForeColor
    frmCmnDlg.dirOpenList.BackColor = BackColor
    frmCmnDlg.cmdOpenOK.BackColor = BackColor
    frmCmnDlg.cmdOpenCancel.BackColor = BackColor

    ' Display dialog modally.
    frmCmnDlg.SHOW 1

    ' Determine if user canceled dialog.
    IF frmCmnDlg.cmdOpenCancel.Tag <> "FALSE" THEN
        Cancel = TRUE
    ' If not, return FileName and PathName.
    ELSE
        Cancel = FALSE
        FileName = frmCmnDlg.txtOpenFile.Text
        PathName = frmCmnDlg.filOpenList.Path
        frmCmnDlg.cmdOpenCancel.Tag = ""
    END IF

    ' Hide or unload dialog and return control to user's program.
    ' (Hide if user chose to preload form for performance.)
    IF LEFT$(frmCmnDlg.Tag, 1) = "H" THEN
        frmCmnDlg.pctFileOpen.visible = FALSE
        frmCmnDlg.HIDE
    ELSE
        UNLOAD frmCmnDlg
    END IF

    EXIT SUB

' Option error handling routine.
' Ignore errors here and let dialog's controls
' handle the errors.
FileOpenError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load dialog.", 0, "FileOpen"
          Cancel = TRUE
          EXIT SUB
    CASE ELSE
          RESUME NEXT
    END SELECT
END SUB

' FilePrint common dialog support routine
'
' Displays Print dialog which allows users to select
' Print destination (PRINTER.PrintTarget) and the
' number of copies to print.  This procedure only provides
' the user interface and returns user input.  It does
' not actually carry out the corresponding action.
'
' Parameters:
'   Copies - returns the number of copies (1 to 99) the user wants
'           to print.  To supply default number of copies
'           in dialog, assign default to Copies then
'           pass it to this procedure (default when Copies
'           is 0 is 1).
'   ForeColor - sets the dialog foreground color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   BackColor - sets the dialog background color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   Cancel - returns whether or not user pressed the dialog's Cancel
'           button.  True (-1) means the user cancelled the dialog.
'
SUB FilePrint (Copies AS INTEGER, ForeColor AS INTEGER, BackColor AS INTEGER, Cancel AS INTEGER)
    ON LOCAL ERROR GOTO FilePrintError

    frmCmnDlg.Caption = "Print"         ' Set form caption.

    ' Determine default number of copies.
    IF Copies = 0 THEN
        frmCmnDlg.txtPrintCopies.Text = "1"
    ELSE
        frmCmnDlg.txtPrintCopies.Text = STR$(Copies)
    END IF

    ' Set default and cancel command buttons.
    frmCmnDlg.cmdPrintOK.Default = TRUE
    frmCmnDlg.cmdPrintCancel.Cancel = TRUE

    ' Size and position Print container.
    frmCmnDlg.pctFilePrint.BorderStyle = 0
    frmCmnDlg.pctFilePrint.visible = TRUE

    ' Size and center dialog.
    frmCmnDlg.MOVE frmCmnDlg.Left, frmCmnDlg.Top, frmCmnDlg.pctFilePrint.Width + 2, frmCmnDlg.pctFilePrint.Height + 2
    frmCmnDlg.MOVE (SCREEN.Width - frmCmnDlg.Width) \ 2, ((SCREEN.Height - frmCmnDlg.Height) \ 2) - 2

    ' Set dialog colors.
    frmCmnDlg.ForeColor = ForeColor
    frmCmnDlg.BackColor = BackColor
    frmCmnDlg.pctFilePrint.ForeColor = ForeColor
    frmCmnDlg.pctFilePrint.BackColor = BackColor
    frmCmnDlg.lblPrintCopies.ForeColor = ForeColor
    frmCmnDlg.lblPrintCopies.BackColor = BackColor
    frmCmnDlg.txtPrintCopies.ForeColor = ForeColor
    frmCmnDlg.txtPrintCopies.BackColor = BackColor
    frmCmnDlg.txtPrintFile.ForeColor = ForeColor
    frmCmnDlg.txtPrintFile.BackColor = BackColor
    frmCmnDlg.fraPrintTarget.ForeColor = ForeColor
    frmCmnDlg.fraPrintTarget.BackColor = BackColor
    FOR i% = 0 TO 3
        frmCmnDlg.optPrintTarget(i%).ForeColor = ForeColor
        frmCmnDlg.optPrintTarget(i%).BackColor = BackColor
    NEXT i%
    FOR i% = 0 TO 1
        frmCmnDlg.optPrintAppend(i%).ForeColor = ForeColor
        frmCmnDlg.optPrintAppend(i%).BackColor = BackColor
    NEXT i%
    frmCmnDlg.lblPrintAppend.ForeColor = ForeColor
    frmCmnDlg.lblPrintAppend.BackColor = BackColor
    frmCmnDlg.cmdPrintOK.BackColor = BackColor
    frmCmnDlg.cmdPrintCancel.BackColor = BackColor
    
    ' Display dialog modally.
    frmCmnDlg.SHOW 1

    ' Determine if user canceled dialog.
    IF frmCmnDlg.cmdPrintCancel.Tag <> "FALSE" THEN
        Cancel = TRUE
    ' If not, return number of copies to print.
    ELSE
        Cancel = FALSE
        IF VAL(frmCmnDlg.txtPrintCopies.Text) > 99 THEN
            Copies = 99
        ELSEIF VAL(frmCmnDlg.txtPrintCopies.Text) < 1 THEN
            Copies = 1
        ELSE
            Copies = VAL(frmCmnDlg.txtPrintCopies.Text)
        END IF
        frmCmnDlg.cmdPrintCancel.Tag = ""
    END IF

    ' Hide or unload dialog and return control to user's program.
    ' (Hide if user chose to preload form for performance.)
    IF LEFT$(frmCmnDlg.Tag, 1) = "H" THEN
        frmCmnDlg.pctFilePrint.visible = FALSE
        frmCmnDlg.HIDE
    ELSE
        UNLOAD frmCmnDlg
    END IF

    EXIT SUB

' Error handling routine.
FilePrintError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load dialog.", 0, "FindPrint"
          Cancel = TRUE
          EXIT SUB
    CASE ELSE
          RESUME NEXT
    END SELECT
END SUB

' FileSave common dialog support routine
'
' Displays Save dialog which allows users to specify
' filename for subsequent file save operation.
' This procedure only provides the user interface and
' returns user input.  It does not actually carry out
' the corresponding action.
'
' Parameters:
'   FileName - returns the name (without path) of the
'           file for the save operation.  To supply
'           default filename in dialog, assign default
'           to FileName then pass it to this procedure.
'   PathName - returns the path (without filename) of
'           the file for the save operation.  To supply
'           default path in dialog, assign default to
'           PathName then pass it to this procedure.
'           Note, only pass a valid drive and path. Do
'           not include a filename or file pattern.
'   DefaultExt - sets the default search pattern for the
'           File Listbox.  Default pattern when DefaultExt
'           is null is "*.*".  To specify a different
'           search pattern (i.e. "*.BAS"), assign new
'           value to DefaultExt then pass it to this
'           procedure.
'   DialogTitle - sets the dialog title.  Default title
'           when DialogTitle is null is "Save As".  To
'           specify a different title (i.e. "Save My File"),
'           assign new value to DialogTitle then pass it to
'           this procedure.
'   ForeColor - sets the dialog foreground color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   BackColor - sets the dialog background color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   Flags - unused.  Use this to customize dialog action if needed.
'   Cancel - returns whether or not user pressed the dialog's Cancel
'           button.  True (-1) means the user cancelled the dialog.
'
SUB FileSave (FileName AS STRING, PathName AS STRING, DefaultExt AS STRING, DialogTitle AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)
    ' Set up error handling for option validation.
    ON LOCAL ERROR GOTO FileSaveError

    ' Set form caption.
    IF DialogTitle = "" THEN
        frmCmnDlg.Caption = "Save As"
    ELSE
        frmCmnDlg.Caption = DialogTitle
    END IF
    frmCmnDlg.Tag = frmCmnDlg.Tag + "SAVE"              ' Set form tag for common unload procedure.

    ' Determine search pattern for file listbox.
    IF DefaultExt <> "" THEN
        frmCmnDlg.filOpenList.Pattern = DefaultExt
    ELSE
        frmCmnDlg.filOpenList.Pattern = "*.*"
    END IF

    ' Determine default path.
    IF PathName <> "" THEN
        ' If the path ends with a backslash, remove it.
        IF RIGHT$(PathName, 1) = "\" THEN
            PathName = LEFT$(PathName, LEN(PathName) - 1)
        END IF
        ' Set drive and path for file-system controls.

        ' Set File listbox path.  If PathName is different
        ' than current path, PathChange event will be triggered
        ' which updates Drive listbox drive and Directory listbox path.
        frmCmnDlg.filOpenList.Path = PathName
    END IF
    ' Display current path to the user.
    frmCmnDlg.lblOpenPath.Caption = frmCmnDlg.filOpenList.Path

    ' Determine default filename to display in edit field.
    IF FileName <> "" THEN
        frmCmnDlg.txtOpenFile.Text = UCASE$(FileName)
    ELSE
        frmCmnDlg.txtOpenFile.Text = frmCmnDlg.filOpenList.Pattern
    END IF

    ' Set default and cancel command buttons.
    frmCmnDlg.cmdOpenOK.Default = TRUE
    frmCmnDlg.cmdOpenCancel.Cancel = TRUE

    ' Size and position Open/Save container.
    frmCmnDlg.pctFileOpen.BorderStyle = 0
    frmCmnDlg.pctFileOpen.visible = TRUE

    ' Size and center dialog.
    frmCmnDlg.MOVE frmCmnDlg.Left, frmCmnDlg.Top, frmCmnDlg.pctFileOpen.Width + 2, frmCmnDlg.pctFileOpen.Height + 2
    frmCmnDlg.MOVE (SCREEN.Width - frmCmnDlg.Width) \ 2, ((SCREEN.Height - frmCmnDlg.Height) \ 2) - 2

    ' Set dialog colors.
    frmCmnDlg.ForeColor = ForeColor
    frmCmnDlg.BackColor = BackColor
    frmCmnDlg.pctFileOpen.ForeColor = ForeColor
    frmCmnDlg.pctFileOpen.BackColor = BackColor
    frmCmnDlg.lblOpenFile.ForeColor = ForeColor
    frmCmnDlg.lblOpenFile.BackColor = BackColor
    frmCmnDlg.txtOpenFile.ForeColor = ForeColor
    frmCmnDlg.txtOpenFile.BackColor = BackColor
    frmCmnDlg.lblOpenPath.ForeColor = ForeColor
    frmCmnDlg.lblOpenPath.BackColor = BackColor
    frmCmnDlg.filOpenList.ForeColor = ForeColor
    frmCmnDlg.filOpenList.BackColor = BackColor
    frmCmnDlg.drvOpenList.ForeColor = ForeColor
    frmCmnDlg.drvOpenList.BackColor = BackColor
    frmCmnDlg.dirOpenList.ForeColor = ForeColor
    frmCmnDlg.dirOpenList.BackColor = BackColor
    frmCmnDlg.cmdOpenOK.BackColor = BackColor
    frmCmnDlg.cmdOpenCancel.BackColor = BackColor

    ' Display dialog modally.
    frmCmnDlg.SHOW 1

    ' Determine if user canceled dialog.
    IF frmCmnDlg.cmdOpenCancel.Tag <> "FALSE" THEN
        Cancel = TRUE
    ' If not, return FileName and PathName.
    ELSE
        Cancel = FALSE
        FileName = frmCmnDlg.txtOpenFile.Text
        PathName = frmCmnDlg.filOpenList.Path
        frmCmnDlg.cmdOpenCancel.Tag = ""
    END IF

    ' Hide or unload dialog and return control to user's program.
    ' (Hide if user chose to preload form for performance.)
    IF LEFT$(frmCmnDlg.Tag, 1) = "H" THEN
        frmCmnDlg.pctFileOpen.visible = FALSE
        frmCmnDlg.HIDE
        frmCmnDlg.Tag = "H"              ' Reset tag.
    ELSE
        UNLOAD frmCmnDlg
    END IF

    EXIT SUB

' Option error handling routine.
' Ignore errors here and let dialog's controls
' handle the errors.
FileSaveError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load dialog.", 0, "FileSave"
          Cancel = TRUE
          EXIT SUB
    CASE ELSE
          RESUME NEXT
    END SELECT
END SUB

' FindText common dialog support routine.
'
' Displays Find dialog which allows users to enter text
' to find.  Also allows user to specify options
' for Find operation. This procedure only provides
' the user interface and returns user input.  It does
' not actually carry out the corresponding action.
'
' Parameters:
'   FText - returns text the user wants to find.
'           To supply default find text in dialog, assign
'           default to FText then pass it to this procedure.
'   ForeColor - sets the dialog foreground color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   BackColor - sets the dialog background color.  Does not affect
'           SCREEN.ControlPanel color settings.
'   Options - Bit field that returns user's option
'           selections as follows:
'              1 - Match Case (default is no match case)
'              2 - Whole Word (default is no whole word match)
'              4 - Search direction is up (default is down)
'           To supply default options, set appropriate
'           bit position in Options then pass it to this
'           procedure.
'   Flags - Bit field that determines which dialog options
'           are available to the user.  Field is defined as follows:
'              1 - Don't display Match Case check box (default is display check box)
'              2 - Don't display Whole Word check box (default is display check box)
'              4 - Don't display Direction option buttons (default is display buttons)
'           To change option availability, set appropriate
'           bit position in Flags then pass it to this
'           procedure.
'   Cancel - returns whether or not user pressed the dialog's Cancel
'           button.  True (-1) means the user canceled the dialog.
'
SUB FindText (FText AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Options AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)
    ON LOCAL ERROR GOTO FindTextError

    frmCmnDlg.Caption = "Find"        ' Set form caption.

    ' Determine if Match Case check box will be displayed to the user.
    frmCmnDlg.chkSearchCase.visible = (Flags% AND 1) <> 1
    frmCmnDlg.chkSearchCase.Top = 5     ' Position check box correctly since Change edit field is not displayed.
    frmCmnDlg.chkSearchCase.value = (Options AND 1)

    ' Determine if Whole Word check box will be displayed to the user.
    frmCmnDlg.chkSearchWord.visible = (Flags% AND 2) <> 2
    frmCmnDlg.chkSearchWord.Top = 6
    frmCmnDlg.chkSearchWord.value = (Options AND 2) - .5 * (Options AND 2)

    ' Determine if Direction option buttons will be displayed to the user.
    frmCmnDlg.fraSearchDir.visible = (Flags% AND 4) <> 4
    frmCmnDlg.fraSearchDir.Top = 4
    frmCmnDlg.optSearchDir(0).value = ((Options AND 4) = 4)
    frmCmnDlg.optSearchDir(1).value = ((Options AND 4) <> 4)

    ' Turn off Change edit field and Change All command button
    ' (only available in ChangeText dialog).
    frmCmnDlg.txtSearchChange.visible = FALSE
    frmCmnDlg.lblSearchChange.visible = FALSE
    frmCmnDlg.cmdSearchChangeAll.visible = FALSE
    frmCmnDlg.cmdSearchCancel.Top = 4
    frmCmnDlg.cmdSearchFind.Caption = "Find &Next"

    ' Supply default find text if present.
    frmCmnDlg.txtSearchFind.Text = FText

    ' Set default and cancel command buttons.
    frmCmnDlg.cmdSearchFind.Default = TRUE
    frmCmnDlg.cmdSearchCancel.Cancel = TRUE

    ' Size and position Find/Change container.
    frmCmnDlg.pctFindText.Height = 8
    frmCmnDlg.pctFindText.BorderStyle = 0
    frmCmnDlg.pctFindText.visible = TRUE

    ' Size and center dialog.
    frmCmnDlg.MOVE frmCmnDlg.Left, frmCmnDlg.Top, frmCmnDlg.pctFindText.Width + 2, frmCmnDlg.pctFindText.Height + 2
    frmCmnDlg.MOVE (SCREEN.Width - frmCmnDlg.Width) \ 2, ((SCREEN.Height - frmCmnDlg.Height) \ 2) - 2

    ' Set dialog colors.
    frmCmnDlg.ForeColor = ForeColor
    frmCmnDlg.BackColor = BackColor
    frmCmnDlg.pctFindText.ForeColor = ForeColor
    frmCmnDlg.pctFindText.BackColor = BackColor
    frmCmnDlg.lblSearchFind.ForeColor = ForeColor
    frmCmnDlg.lblSearchFind.BackColor = BackColor
    frmCmnDlg.txtSearchFind.ForeColor = ForeColor
    frmCmnDlg.txtSearchFind.BackColor = BackColor
    frmCmnDlg.lblSearchChange.ForeColor = ForeColor
    frmCmnDlg.lblSearchChange.BackColor = BackColor
    frmCmnDlg.txtSearchChange.ForeColor = ForeColor
    frmCmnDlg.txtSearchChange.BackColor = BackColor
    frmCmnDlg.fraSearchDir.ForeColor = ForeColor
    frmCmnDlg.fraSearchDir.BackColor = BackColor
    FOR i% = 0 TO 1
        frmCmnDlg.optSearchDir(i%).ForeColor = ForeColor
        frmCmnDlg.optSearchDir(i%).BackColor = BackColor
    NEXT i%
    frmCmnDlg.chkSearchCase.ForeColor = ForeColor
    frmCmnDlg.chkSearchCase.BackColor = BackColor
    frmCmnDlg.chkSearchWord.ForeColor = ForeColor
    frmCmnDlg.chkSearchWord.BackColor = BackColor
    frmCmnDlg.cmdSearchFind.BackColor = BackColor
    frmCmnDlg.cmdSearchCancel.BackColor = BackColor
    frmCmnDlg.cmdSearchChangeAll.BackColor = BackColor

    ' Display dialog modally.
    frmCmnDlg.SHOW 1

    ' Determine if user canceled dialog.
    IF frmCmnDlg.cmdSearchCancel.Tag <> "FALSE" THEN
        Cancel = TRUE
    ' If not, return find text and user options.
    ELSE
        Cancel = FALSE
        FText = frmCmnDlg.txtSearchFind.Text
        Options = frmCmnDlg.chkSearchCase.value OR 2 * frmCmnDlg.chkSearchWord.value OR -4 * frmCmnDlg.optSearchDir(0).value
        frmCmnDlg.cmdSearchCancel.Tag = ""
    END IF

    ' Hide or unload dialog and return control to user's program.
    ' (Hide if user chose to preload form for performance.)
    IF LEFT$(frmCmnDlg.Tag, 1) = "H" THEN
        frmCmnDlg.pctFindText.visible = FALSE
        frmCmnDlg.HIDE
    ELSE
        UNLOAD frmCmnDlg
    END IF

    EXIT SUB

' Error handling routine.
FindTextError:
    SELECT CASE ERR
    CASE 7:                                       ' Out of memory.
          MSGBOX "Out of memory.  Can't load dialog.", 0, "FindText"
          Cancel = TRUE
          EXIT SUB
    CASE ELSE
          RESUME NEXT
    END SELECT
END SUB

