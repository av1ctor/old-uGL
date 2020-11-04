Version 1.00
BEGIN Form Main
	AutoRedraw   = 0
	BackColor    = QBColor(7)
	BorderStyle  = 1
	Caption      = "UGL Builder"
	ControlBox   = -1
	Enabled      = -1
	ForeColor    = QBColor(0)
	Height       = Char(30)
	Left         = Char(2)
	MaxButton    = 0
	MinButton    = 0
	MousePointer = 0
	Tag          = ""
	Top          = Char(2)
	Visible      = -1
	Width        = Char(63)
	WindowState  = 0
	BEGIN Menu mnuOp
		Caption      = "&Options"
		Checked      = 0
		Enabled      = -1
		Separator    = 0
		Tag          = ""
		Visible      = -1
		BEGIN Menu mnuOpPaths
			Caption      = "&Paths"
			Checked      = 0
			Enabled      = -1
			Separator    = 0
			Shortcut     = ^P
			Tag          = ""
			Visible      = -1
		END
		BEGIN Menu mnuOptionsBldt
			Caption      = "&Build target "
			Checked      = 0
			Enabled      = -1
			Separator    = 0
			Tag          = ""
			Visible      = -1
			BEGIN Menu mnuOpBldTrgBC
				Caption      = "&Borland C/C++"
				Checked      = 0
				Enabled      = -1
				Separator    = 0
				Shortcut     = {F1}
				Tag          = ""
				Visible      = -1
			END
			BEGIN Menu mnuOpBldTrgQb45
				Caption      = "Microsoft QuickBasic &4.50"
				Checked      = -1
				Enabled      = -1
				Separator    = 0
				Shortcut     = {F2}
				Tag          = ""
				Visible      = -1
			END
			BEGIN Menu mnuOpBldTrgQb71
				Caption      = "Microsoft QuickBasic &7.10"
				Checked      = 0
				Enabled      = -1
				Separator    = 0
				Shortcut     = {F3}
				Tag          = ""
				Visible      = -1
			END
			BEGIN Menu mnuOpBldTrgVBDOS
				Caption      = "Microsoft &VisualBasic for DOS 1.0"
				Checked      = 0
				Enabled      = -1
				Separator    = 0
				Shortcut     = {F4}
				Tag          = ""
				Visible      = -1
			END
		END
		BEGIN Menu mnuOpBldTyp
			Caption      = "Build &type"
			Checked      = 0
			Enabled      = -1
			Separator    = 0
			Tag          = ""
			Visible      = -1
			BEGIN Menu mnuOpBldTypSub
				Caption      = "&Release"
				Checked      = -1
				Enabled      = -1
				Index        = 0
				Separator    = 0
				Tag          = ""
				Visible      = -1
			END
			BEGIN Menu mnuOpBldTypSub
				Caption      = "&Debug"
				Checked      = 0
				Enabled      = -1
				Index        = 1
				Separator    = 0
				Tag          = ""
				Visible      = -1
			END
		END
		BEGIN Menu mnuOpSep1
			Caption      = "-"
			Checked      = 0
			Enabled      = -1
			Separator    = -1
			Tag          = ""
			Visible      = -1
		END
		BEGIN Menu mnuOpExit
			Caption      = "E&xit"
			Checked      = 0
			Enabled      = -1
			Separator    = 0
			Shortcut     = ^X
			Tag          = ""
			Visible      = -1
		END
	END
	BEGIN Menu mnuInclude
		Caption      = "&Include"
		Checked      = 0
		Enabled      = -1
		Separator    = 0
		Tag          = ""
		Visible      = -1
		BEGIN Menu mnuIncludeLib
			Caption      = "Main Lib "
			Checked      = 0
			Enabled      = -1
			Separator    = 0
			Tag          = ""
			Visible      = -1
			BEGIN Menu mnuIncludeLibAll
				Caption      = "&All"
				Checked      = -1
				Enabled      = -1
				Separator    = 0
				Tag          = ""
				Visible      = -1
			END
			BEGIN Menu mnuIncludeLibChose
				Caption      = "Chose"
				Checked      = 0
				Enabled      = -1
				Separator    = 0
				Tag          = ""
				Visible      = -1
				BEGIN Menu mnuIncludeLibChoseBpp
					Caption      = "&Bitdepths"
					Checked      = 0
					Enabled      = -1
					Separator    = 0
					Tag          = ""
					Visible      = -1
					BEGIN Menu mnuIncludeLibChoseBppAll
						Caption      = "All"
						Checked      = -1
						Enabled      = -1
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu muSep5
						Caption      = ""
						Checked      = 0
						Enabled      = -1
						Separator    = -1
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseBppSub
						Caption      = "&8 bit"
						Checked      = -1
						Enabled      = -1
						Index        = 0
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseBppSub
						Caption      = "1&5 bit"
						Checked      = -1
						Enabled      = -1
						Index        = 1
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseBppSub
						Caption      = "1&6 bit"
						Checked      = -1
						Enabled      = -1
						Index        = 2
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseBppSub
						Caption      = "&32 bit"
						Checked      = -1
						Enabled      = -1
						Index        = 3
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
				END
				BEGIN Menu mnuIncludeLibChoseBez
					Caption      = "Be&zier Curves"
					Checked      = 0
					Enabled      = -1
					Separator    = 0
					Tag          = ""
					Visible      = -1
					BEGIN Menu mnuIncludeLibChoseBezAll
						Caption      = "All"
						Checked      = -1
						Enabled      = -1
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuSep6
						Caption      = ""
						Checked      = 0
						Enabled      = -1
						Separator    = -1
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseBezSub
						Caption      = "uglCubicBez, uglQuadricBez"
						Checked      = -1
						Enabled      = -1
						Index        = 0
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseBezSub
						Caption      = "ugluCubicBez, ugluQuadricBez"
						Checked      = -1
						Enabled      = -1
						Index        = 1
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseBezSub
						Caption      = "ugluCubicBez3D, ugluQuadricBez3D"
						Checked      = -1
						Enabled      = -1
						Index        = 2
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
				END
				BEGIN Menu mnuIncludeLibChoseFnt
					Caption      = "&Fonts"
					Checked      = 0
					Enabled      = -1
					Separator    = 0
					Tag          = ""
					Visible      = -1
					BEGIN Menu mnuIncludeLibChoseFntSub
						Caption      = "Vector fonts"
						Checked      = -1
						Enabled      = -1
						Index        = 0
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
				END
				BEGIN Menu mnuIncludeLibChoseInp
					Caption      = "&Input"
					Checked      = 0
					Enabled      = -1
					Separator    = 0
					Tag          = ""
					Visible      = -1
					BEGIN Menu mnuIncludeLibChoseInpAll
						Caption      = "All"
						Checked      = -1
						Enabled      = -1
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuSep2
						Caption      = ""
						Checked      = 0
						Enabled      = -1
						Separator    = -1
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseInpSub
						Caption      = "&Keyboard"
						Checked      = -1
						Enabled      = -1
						Index        = 0
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseInpSub
						Caption      = "&Mouse"
						Checked      = -1
						Enabled      = -1
						Index        = 1
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
				END
				BEGIN Menu mnuIncludeLibChosePrm
					Caption      = "&Primitives"
					Checked      = 0
					Enabled      = -1
					Separator    = 0
					Tag          = ""
					Visible      = -1
					BEGIN Menu mnuIncludeLibChosePrmPoly
						Caption      = "Polygons"
						Checked      = 0
						Enabled      = -1
						Separator    = 0
						Tag          = ""
						Visible      = -1
						BEGIN Menu mnuIncludeLibChosePrmPolyAll
							Caption      = "All"
							Checked      = -1
							Enabled      = -1
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuSep3
							Caption      = ""
							Checked      = 0
							Enabled      = -1
							Separator    = -1
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmPolySub
							Caption      = "uglTriF, uglQuadF (Convex)"
							Checked      = -1
							Enabled      = -1
							Index        = 0
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmPolySub
							Caption      = "uglTriG (Convex)"
							Checked      = -1
							Enabled      = -1
							Index        = 1
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmPolySub
							Caption      = "uglTriT, uglQuadT (Convex)"
							Checked      = -1
							Enabled      = -1
							Index        = 2
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmPolySub
							Caption      = "uglPoly (Complex)"
							Checked      = -1
							Enabled      = -1
							Index        = 3
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmPolySub
							Caption      = "uglPolyF (Complex)"
							Checked      = -1
							Enabled      = -1
							Index        = 4
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
					END
					BEGIN Menu mnuIncludeLibChosePrmBlit
						Caption      = "Rotate and Scale"
						Checked      = 0
						Enabled      = -1
						Separator    = 0
						Tag          = ""
						Visible      = -1
						BEGIN Menu mnuIncludeLibChosePrmBlitAll
							Caption      = "All"
							Checked      = -1
							Enabled      = -1
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuSep4
							Caption      = ""
							Checked      = 0
							Enabled      = -1
							Index        = 2
							Separator    = -1
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmBlitSub
							Caption      = "uglPutRot"
							Checked      = -1
							Enabled      = -1
							Index        = 0
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmBlitSub
							Caption      = "uglPutScl"
							Checked      = -1
							Enabled      = -1
							Index        = 1
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmBlitSub
							Caption      = "uglPutRotScl"
							Checked      = -1
							Enabled      = -1
							Index        = 2
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmBlitSub
							Caption      = "uglPutMskRot"
							Checked      = -1
							Enabled      = -1
							Index        = 3
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmBlitSub
							Caption      = "uglPutMskScl"
							Checked      = -1
							Enabled      = -1
							Index        = 4
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
						BEGIN Menu mnuIncludeLibChosePrmBlitSub
							Caption      = "uglPutMskRotScl"
							Checked      = -1
							Enabled      = -1
							Index        = 5
							Separator    = 0
							Tag          = ""
							Visible      = -1
						END
					END
				END
				BEGIN Menu mnuIncludeLibChoseSnd
					Caption      = "&Sound"
					Checked      = 0
					Enabled      = -1
					Separator    = 0
					Tag          = ""
					Visible      = -1
					BEGIN Menu mnuIncludeLibChoseSndSub
						Caption      = "Main"
						Checked      = -1
						Enabled      = -1
						Index        = 0
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
					BEGIN Menu mnuIncludeLibChoseSndSub
						Caption      = "Music (MOD)"
						Checked      = -1
						Enabled      = -1
						Index        = 1
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
				END
				BEGIN Menu mnuIncludeLibChoseMsc
					Caption      = "&Misc"
					Checked      = 0
					Enabled      = -1
					Separator    = 0
					Tag          = ""
					Visible      = -1
					BEGIN Menu mnuIncludeLibChoseMscSub
						Caption      = "Timer module"
						Checked      = -1
						Enabled      = -1
						Index        = 0
						Separator    = 0
						Tag          = ""
						Visible      = -1
					END
				END
			END
		END
		BEGIN Menu mnuIncludeAddons
			Caption      = "&Addons"
			Checked      = 0
			Enabled      = -1
			Separator    = 0
			Tag          = ""
			Visible      = -1
		END
	END
	BEGIN Menu mnuBuild
		Caption      = "&Build"
		Checked      = 0
		Enabled      = -1
		Separator    = 0
		Tag          = ""
		Visible      = -1
	END
	BEGIN Menu mnuSep
		Caption      = "                        "
		Checked      = 0
		Enabled      = -1
		Index        = 0
		Separator    = 0
		Tag          = ""
		Visible      = -1
	END
	BEGIN Menu mnuAbout
		Caption      = "&About"
		Checked      = 0
		Enabled      = -1
		Separator    = 0
		Tag          = ""
		Visible      = -1
	END
END
'$FORM frmAbout
DECLARE SUB CmnDlgClose ()
DECLARE SUB CmnDlgRegister (Success AS INTEGER)
'$FORM frmAddons
'$FORM frmOutput
DECLARE SUB mnuOpBldTrgBC_Click ()
DECLARE SUB mnuOpBldTrgQb45_Click ()
DECLARE SUB mnuOpBldTrgQb71_Click ()
DECLARE SUB mnuOpBldTrgVBDos_Click ()
DECLARE SUB BuildLinkCommands (lnkcmnd AS STRING)
DECLARE SUB Form_Unload (Cancel AS INTEGER)
'$FORM Path
'$INCLUDE: 'global.bi'

CONST true = -1
CONST false = 0

SUB BuildLinkCommands (lnkcmnd AS STRING)
    DIM crlf AS STRING


    lnkcmnd = ""
    crlf = " &" + CHR$(13) + CHR$(10)
    


    ''
    '' Bit depth
    ''
    ''
    IF (mnuIncludeLibChoseBppSub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-8main" + crlf + "-8pixel" + crlf
        lnkcmnd = lnkcmnd + "-8vline" + crlf + "-8putm" + crlf
        lnkcmnd = lnkcmnd + "-8putb" + crlf + "-8hflip" + crlf
        lnkcmnd = lnkcmnd + "-8plxf" + crlf + "-8plxg" + crlf
        lnkcmnd = lnkcmnd + "-8plxt" + crlf + "-8line" + crlf + "+stubs\8stub" + crlf
    END IF

    IF (mnuIncludeLibChoseBppSub(1).checked = false) THEN
        lnkcmnd = lnkcmnd + "-15main" + crlf + "-15putm" + crlf + "-15hflip" + crlf
        lnkcmnd = lnkcmnd + "-15plxg" + crlf + "-15plxt" + crlf + "+stubs\15stub" + crlf
    END IF

    IF (mnuIncludeLibChoseBppSub(2).checked = false) THEN
        
        ''
        '' The 15 bit routines depends on some of the 16 bit ll routines
        ''
        IF (mnuIncludeLibChoseBppSub(1).checked = true) THEN
            lnkcmnd = lnkcmnd + "-16main" + crlf + "-16putm" + crlf
            lnkcmnd = lnkcmnd + "-16plxg" + crlf + "+stubs\16stub" + crlf
        ELSE
        
            lnkcmnd = lnkcmnd + "-16main" + crlf + "-16pixel" + crlf + "-16line" + crlf
            lnkcmnd = lnkcmnd + "-16vline" + crlf + "-16putm" + crlf + "-16hflip" + crlf + "-16plxf" + crlf
            lnkcmnd = lnkcmnd + "-16plxg" + crlf + "-16plxt" + crlf + "+stubs\16stub" + crlf
        END IF
    END IF

    IF (mnuIncludeLibChoseBppSub(3).checked = false) THEN
        lnkcmnd = lnkcmnd + "-32main" + crlf + "-32pixel" + crlf + "-32line" + crlf
        lnkcmnd = lnkcmnd + "-32vline" + crlf + "-32putm" + crlf + "-32hflip" + crlf + "-32plxf" + crlf
        lnkcmnd = lnkcmnd + "-32plxg" + crlf + "-32plxt" + crlf + "+stubs\32stub" + crlf
    END IF


    ''
    '' Beziers
    ''
    ''
    IF (mnuIncludeLibChoseBezSub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-uglbez" + crlf
    END IF

    IF (mnuIncludeLibChoseBezSub(1).checked = false) THEN
        lnkcmnd = lnkcmnd + "-glubez" + crlf
    END IF

    IF (mnuIncludeLibChoseBezSub(2).checked = false) THEN
        lnkcmnd = lnkcmnd + "-glubez3d" + crlf
    END IF


    ''
    '' Fonts
    ''
    ''
    IF (mnuIncludeLibChoseFntSub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-mdfont" + crlf
    END IF


    ''
    '' Input
    ''
    ''
    IF (mnuIncludeLibChoseInpSub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-mdkbd" + crlf
    END IF

    IF (mnuIncludeLibChoseInpSub(1).checked = false) THEN
        lnkcmnd = lnkcmnd + "-mdmouse" + crlf
    END IF


    ''
    '' Primitives - polygons
    ''
    ''
    IF (mnuIncludeLibChosePrmPolySub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-mscshfa" + crlf
        lnkcmnd = lnkcmnd + "-uglplxf" + crlf
    END IF

    IF (mnuIncludeLibChosePrmPolySub(1).checked = false) THEN
        lnkcmnd = lnkcmnd + "-mscshga" + crlf
        lnkcmnd = lnkcmnd + "-uglplxg" + crlf
    END IF

    IF (mnuIncludeLibChosePrmPolySub(2).checked = false) THEN
        lnkcmnd = lnkcmnd + "-mscshta" + crlf
        lnkcmnd = lnkcmnd + "-uglplxt" + crlf
    END IF

    IF (mnuIncludeLibChosePrmPolySub(3).checked = false) THEN
        lnkcmnd = lnkcmnd + "-uglpoly" + crlf
    END IF

    IF (mnuIncludeLibChosePrmPolySub(4).checked = false) THEN
        lnkcmnd = lnkcmnd + "-uglpolyf" + crlf
    END IF



    ''
    '' Primitives - scale and rotate
    ''
    ''
    IF (mnuIncludeLibChosePrmBlitSub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-uglrtscl" + crlf
    END IF


    ''
    '' Sound module
    ''
    ''
    IF (mnuIncludeLibChoseSndSub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-sbdrv" + crlf + "-sndint" + crlf
        lnkcmnd = lnkcmnd + "-sndctrl" + crlf + "-sndamain" + crlf
        lnkcmnd = lnkcmnd + "-sndmain" + crlf + "-sndnew" + crlf
        lnkcmnd = lnkcmnd + "-sndmixer" + crlf + "-sndconv" + crlf + "-sndplay" + crlf
    END IF

    IF (mnuIncludeLibChoseSndSub(1).checked = false) THEN
        lnkcmnd = lnkcmnd + "-modamain" + crlf + "-modcmn" + crlf
        lnkcmnd = lnkcmnd + "-modctrl" + crlf + "-modload" + crlf
        lnkcmnd = lnkcmnd + "-modmain" + crlf + "-modmem" + crlf
        lnkcmnd = lnkcmnd + "-modplay" + crlf + "-modtbl" + crlf
    END IF



    ''
    '' Misc
    ''
    ''
    IF (mnuIncludeLibChoseMscSub(0).checked = false) THEN
        lnkcmnd = lnkcmnd + "-mdtimer"
    END IF


    ''
    '' Addons (have to be last)
    ''
    FOR i = 0 TO 13
        addons(i) = LTRIM$(RTRIM$(addons(i)))

        IF (addons(i) <> "") THEN
            IF (lnkcmnd <> "") THEN
                lnkcmnd = lnkcmnd + crlf + "+" + addons(i)
            ELSE
                lnkcmnd = "+" + addons(i)
            END IF
        END IF
    NEXT i


END SUB

DEFSNG A-Z
SUB Form_Load ()
    DIM i AS INTEGER
    DIM checked AS INTEGER

    REDIM addons(29)  AS STRING


    SCREEN 0
    WIDTH 80, 50

    ''
    '' This is so we know which compiler
    '' was chosen
    ''
    Compiler = QB45
    Path.caption = "QuickBasic 4.50 Paths"

    ''
    '' Load paths
    ''
    IF (DIR$("uglbuild.ini") <> "") THEN

        OPEN "uglbuild.ini" FOR INPUT AS #1

        INPUT #1, PathReturn.PathBinBC
        INPUT #1, PathReturn.PathLibBC

        INPUT #1, PathReturn.PathBinQB45
        INPUT #1, PathReturn.PathLibQB45

        INPUT #1, PathReturn.PathBinQB71
        INPUT #1, PathReturn.PathLibQB71

        INPUT #1, PathReturn.PathBinVBDOS
        INPUT #1, PathReturn.PathLibVBDOS

        INPUT #1, checked
        mnuIncludeLibAll.checked = checked

        INPUT #1, checked
        mnuIncludeLibChoseBezAll.checked = checked
        FOR i = 0 TO 2
            INPUT #1, checked
            mnuIncludeLibChoseBezSub(i).checked = checked
        NEXT i

        INPUT #1, checked
        mnuIncludeLibChoseBppAll.checked = checked
        FOR i = 0 TO 3
            INPUT #1, checked
            mnuIncludeLibChoseBppSub(i).checked = checked
        NEXT i

        FOR i = 0 TO 0
            INPUT #1, checked
            mnuIncludeLibChoseFntSub(i).checked = checked
        NEXT i

        INPUT #1, checked
        mnuIncludeLibChoseInpAll.checked = checked
        FOR i = 0 TO 1
            INPUT #1, checked
            mnuIncludeLibChoseInpSub(i).checked = checked
        NEXT i

        FOR i = 0 TO 0
            INPUT #1, checked
            mnuIncludeLibChoseMscSub(i).checked = checked
        NEXT i

        INPUT #1, checked
        mnuIncludeLibChosePrmBlitAll.checked = checked
        FOR i = 0 TO 5
            INPUT #1, checked
            mnuIncludeLibChosePrmBlitSub(i).checked = checked
        NEXT i

        INPUT #1, checked
        mnuIncludeLibChosePrmPolyAll.checked = checked
        FOR i = 0 TO 4
            INPUT #1, checked
            mnuIncludeLibChosePrmPolySub(i).checked = checked
        NEXT i

        FOR i = 0 TO 1
            INPUT #1, checked
            mnuIncludeLibChoseSndSub(i).checked = checked
        NEXT i

        INPUT #1, checked
        mnuOpBldTypSub(0).checked = checked
        INPUT #1, checked
        mnuOpBldTypSub(1).checked = checked
        INPUT #1, checked
        mnuOpBldTrgBC.checked = checked
        INPUT #1, checked
        mnuOpBldTrgQb45.checked = checked
        INPUT #1, checked
        mnuOpBldTrgQb71.checked = checked
        INPUT #1, checked
        mnuOpBldTrgVBDos.checked = checked

        FOR i = 0 TO 13
            IF (NOT EOF(1)) THEN INPUT #1, addons(i)
        NEXT i

        IF mnuOpBldTrgBC.checked THEN mnuOpBldTrgBC_Click
        IF mnuOpBldTrgQb45.checked THEN mnuOpBldTrgQb45_Click
        IF mnuOpBldTrgQb71.checked THEN mnuOpBldTrgQb71_Click
        IF mnuOpBldTrgVBDos.checked THEN mnuOpBldTrgVBDos_Click



        CLOSE #1

        PathReturn.Status = ChoseOK
    END IF

    CmnDlgRegister Success%


    ''
    '' Load the text in the about box
    ''
    frmAbout.Label1.caption = "Custom library builder for UGL 0.22" + CHR$(13) + CHR$(10) + "Coded by Blitz" + CHR$(13) + CHR$(10) + CHR$(13) + CHR$(10) + "UGL by v1ctor & Blitz" + CHR$(13) + CHR$(10) + "Visit us at http://dotnet.zext.net"


END SUB

SUB Form_Unload (Cancel AS INTEGER)
    DIM i AS INTEGER

    ''
    '' Save paths
    ''
    OPEN "uglbuild.ini" FOR OUTPUT AS #1

    PRINT #1, PathReturn.PathBinBC
    PRINT #1, PathReturn.PathLibBC

    PRINT #1, PathReturn.PathBinQB45
    PRINT #1, PathReturn.PathLibQB45

    PRINT #1, PathReturn.PathBinQB71
    PRINT #1, PathReturn.PathLibQB71

    PRINT #1, PathReturn.PathBinVBDOS
    PRINT #1, PathReturn.PathLibVBDOS

    ''
    '' Settings
    ''
    ''
    PRINT #1, mnuIncludeLibAll.checked

    PRINT #1, mnuIncludeLibChoseBezAll.checked
    FOR i = 0 TO 2
        PRINT #1, mnuIncludeLibChoseBezSub(i).checked
    NEXT i

    PRINT #1, mnuIncludeLibChoseBppAll.checked
    FOR i = 0 TO 3
        PRINT #1, mnuIncludeLibChoseBppSub(i).checked
    NEXT i

    FOR i = 0 TO 0
        PRINT #1, mnuIncludeLibChoseFntSub(i).checked
    NEXT i

    PRINT #1, mnuIncludeLibChoseInpAll.checked
    FOR i = 0 TO 1
        PRINT #1, mnuIncludeLibChoseInpSub(i).checked
    NEXT i

    FOR i = 0 TO 0
        PRINT #1, mnuIncludeLibChoseMscSub(i).checked
    NEXT i

    PRINT #1, mnuIncludeLibChosePrmBlitAll.checked
    FOR i = 0 TO 5
        PRINT #1, mnuIncludeLibChosePrmBlitSub(i).checked
    NEXT i

    PRINT #1, mnuIncludeLibChosePrmPolyAll.checked
    FOR i = 0 TO 4
        PRINT #1, mnuIncludeLibChosePrmPolySub(i).checked
    NEXT i

    FOR i = 0 TO 1
        PRINT #1, mnuIncludeLibChoseSndSub(i).checked
    NEXT i

    PRINT #1, mnuOpBldTypSub(0).checked
    PRINT #1, mnuOpBldTypSub(1).checked
    PRINT #1, mnuOpBldTrgBC.checked
    PRINT #1, mnuOpBldTrgQb45.checked
    PRINT #1, mnuOpBldTrgQb71.checked
    PRINT #1, mnuOpBldTrgVBDos.checked

    FOR i = 0 TO 13
        PRINT #1, addons(i)
    NEXT i


    CLOSE #1

    CmnDlgClose
    END
END SUB

DEFINT A-Z
SUB mnuAbout_Click ()
    frmAbout.SHOW
END SUB

SUB mnuBuild_Click ()
    DIM i AS INTEGER
    DIM bpp AS INTEGER
    DIM buildOut AS STRING
    DIM lnkcmnd AS STRING
    DIM binpath AS STRING
    DIM libpath AS STRING
    DIM qlbname AS STRING
    DIM uglpath AS STRING
    DIM ugllib  AS STRING

    ''
    '' Atleast on bpp needs to be selected
    ''
    bpp = mnuIncludeLibChoseBppSub(0).checked
    FOR i = 0 TO 3
        bpp = bpp OR mnuIncludeLibChoseBppSub(0).checked
    NEXT i
    
    IF (bpp = false) THEN
        MSGBOX "Atleast one bitdepth needs to be selected...", 1, "Build Error"
        EXIT SUB
    END IF



    IF (mnuOpBldTypSub(0).checked = true) THEN
        uglpath = "release"
    ELSE
        uglpath = "debug"
    END IF

    SELECT CASE Compiler
        CASE BC
            ugllib = "uglc"
            uglpath = uglpath + "\bc\"
            binpath = PathReturn.PathBinBC
            libpath = PathReturn.PathLibBC

        CASE QB45
            ugllib = "ugl"
            qlbname = "bqlb45.lib"
            uglpath = uglpath + "\qb\"
            binpath = PathReturn.PathBinQB45
            libpath = PathReturn.PathLibQB45

        CASE QB71
            ugllib = "uglp"
            qlbname = "qbxqlb.lib"
            uglpath = uglpath + "\pds\"
            binpath = PathReturn.PathBinQB71
            libpath = PathReturn.PathLibQB71

        CASE VBDOS
            ugllib = "uglv"
            qlbname = "vbdosqlb.lib"
            uglpath = uglpath + "\vbd\"
            binpath = PathReturn.PathBinVBDOS
            libpath = PathReturn.PathLibVBDOS
    END SELECT

    FOR i = 0 TO 500
        lnkcmnd = LTRIM$(RTRIM$(lnkcmnd))
        binpath = LTRIM$(RTRIM$(binpath))
        libpath = LTRIM$(RTRIM$(libpath))
    NEXT i
    

    IF (RIGHT$(binpath, 1) <> "\") THEN binpath = binpath + "\"
    IF (RIGHT$(libpath, 1) <> "\") THEN libpath = libpath + "\"


    IF (mnuOpBldTypSub(0).checked = true) THEN
        ugllib = ugllib
    ELSE
        ugllib = ugllib + "d"
    END IF



    ''
    '' Check if all the required files are there
    ''
    ''
    IF (DIR$("..\tools\liblink\lib16.exe") = "") THEN
        MSGBOX "Could not find ..\tools\liblink\lib16.exe", 0, "Error"
        EXIT SUB
    END IF

    IF (DIR$("..\tools\liblink\link16.exe") = "") THEN
        MSGBOX "Could not find ..\tools\liblink\link16.exe", 0, "Error"
        EXIT SUB
    END IF


    IF (DIR$(uglpath + ugllib + ".lib") = "") THEN
        MSGBOX "Could not find " + uglpath + ugllib + ".lib" + ", aborting build", 0, "Error, original lib not found"
        EXIT SUB
    END IF

    IF (Compiler <> BC) THEN
        IF (DIR$(libpath + qlbname) = "") THEN
            MSGBOX "Could not find " + libpath + qlbname + ", aborting build", 0, "Error, library path set?"
            EXIT SUB
        END IF
    END IF


    ''
    '' Build command list
    ''
    ''
    BuildLinkCommands lnkcmnd
    OPEN "ugltmp" FOR OUTPUT AS #1
    IF (lnkcmnd = "") THEN
        PRINT #1, ugllib + ".lib"
        PRINT #1, "y"
        PRINT #1, "+" + uglpath + ugllib + ".lib"
        PRINT #1, ""
        PRINT #1, ugllib + ".lib"
    ELSE
        PRINT #1, uglpath + ugllib + ".lib"
        PRINT #1, lnkcmnd
        PRINT #1, ""
        PRINT #1, ugllib + ".lib"
    END IF
    CLOSE #1


    ''
    '' Build the lib
    ''
    ''
    IF (DIR$(ugllib + ".lib") <> "") THEN
        KILL ugllib + ".lib"
    END IF

    IF (DIR$(ugllib + ".qlb") <> "") THEN
        KILL ugllib + ".qlb"
    END IF


    SHELL "..\tools\liblink\lib16 @ugltmp > ugltmpb"
    IF (Compiler <> BC) THEN
        SHELL "..\tools\liblink\link16 /seg:800 /q " + ugllib + ".lib," + ugllib + ".qlb,nul," + libpath + qlbname + "; >> ugltmpb"
    END IF
    SHELL "del *.bak > nul"
    SHELL "del *.map > nul"
    CLOSE #1
    

    ''
    '' View output
    ''
    ''
    frmOutput.txtOutput.text = ""
    OPEN "ugltmpb" FOR INPUT AS #1
    WHILE (NOT EOF(1))
        LINE INPUT #1, buildOut
        frmOutput.txtOutput.text = frmOutput.txtOutput.text + buildOut + CHR$(13) + CHR$(10)
    WEND
    CLOSE #1


    IF (DIR$("ugltmp") <> "") THEN KILL "ugltmp"
    IF (DIR$("ugltmpb") <> "") THEN KILL "ugltmpb"
    frmOutput.SHOW

END SUB

SUB mnuIncludeAddons_Click ()
    frmAddons.SHOW
END SUB

SUB mnuIncludeLibAll_Click ()
    DIM i AS INTEGER

    IF (mnuIncludeLibAll.checked = true) THEN
        mnuIncludeLibAll.checked = false
    ELSE
        mnuIncludeLibAll.checked = true
    END IF

    ''
    '' Bpp
    ''
    mnuIncludeLibChoseBppAll.checked = mnuIncludeLibAll.checked
    FOR i = 0 TO 3
        mnuIncludeLibChoseBppSub(i).checked = mnuIncludeLibAll.checked
    NEXT i


    ''
    '' Beziers
    ''
    mnuIncludeLibChoseBezAll.checked = mnuIncludeLibAll.checked
    FOR i = 0 TO 2
        mnuIncludeLibChoseBezSub(i).checked = mnuIncludeLibAll.checked
    NEXT i


    ''
    '' Font
    ''
    FOR i = 0 TO 0
        mnuIncludeLibChoseFntSub(i).checked = mnuIncludeLibAll.checked
    NEXT i


    ''
    '' Input
    ''
    mnuIncludeLibChoseInpAll.checked = mnuIncludeLibAll.checked
    FOR i = 0 TO 1
        mnuIncludeLibChoseInpSub(i).checked = mnuIncludeLibAll.checked
    NEXT i


    ''
    '' Primitives
    ''
    mnuIncludeLibChosePrmPolyAll.checked = mnuIncludeLibAll.checked
    FOR i = 0 TO 4
        mnuIncludeLibChosePrmPolySub(i).checked = mnuIncludeLibAll.checked
    NEXT i

    mnuIncludeLibChosePrmBlitAll.checked = mnuIncludeLibAll.checked
    FOR i = 0 TO 5
        mnuIncludeLibChosePrmBlitSub(i).checked = mnuIncludeLibAll.checked
    NEXT i


    ''
    '' Sound & music
    ''
    FOR i = 0 TO 1
        mnuIncludeLibChoseSndSub(i).checked = mnuIncludeLibAll.checked
    NEXT i


    ''
    '' Misc
    ''
    FOR i = 0 TO 0
        mnuIncludeLibChoseMscSub(i).checked = mnuIncludeLibAll.checked
    NEXT i


END SUB

SUB mnuIncludeLibChoseBezAll_Click ()
    DIM i AS INTEGER

    IF (mnuIncludeLibChoseBezAll.checked = false) THEN
        mnuIncludeLibChoseBezAll.checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseBezAll.checked = false
    END IF


    FOR i = 0 TO 2
        mnuIncludeLibChoseBezSub(i).checked = mnuIncludeLibChoseBezAll.checked
    NEXT i

END SUB

SUB mnuIncludeLibChoseBezSub_Click (Index AS INTEGER)

    IF (mnuIncludeLibChoseBezSub(Index).checked = false) THEN
        mnuIncludeLibChoseBezSub(Index).checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseBezAll.checked = false
        mnuIncludeLibChoseBezSub(Index).checked = false
    END IF

END SUB

SUB mnuIncludeLibChoseBppAll_Click ()
    DIM i AS INTEGER

    IF (mnuIncludeLibChoseBppAll.checked = false) THEN
        mnuIncludeLibChoseBppAll.checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseBppAll.checked = false
    END IF


    FOR i = 0 TO 3
        mnuIncludeLibChoseBppSub(i).checked = mnuIncludeLibChoseBppAll.checked
    NEXT i

END SUB

SUB mnuIncludeLibChoseBppSub_Click (Index AS INTEGER)

    IF (mnuIncludeLibChoseBppSub(Index).checked = false) THEN
        mnuIncludeLibChoseBppSub(Index).checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseBppAll.checked = false
        mnuIncludeLibChoseBppSub(Index).checked = false
    END IF

END SUB

SUB mnuIncludeLibChoseFntSub_Click (Index AS INTEGER)
    DIM i AS INTEGER

    ''
    '' If vector fonts are chose we need to include
    '' uglPoly and uglPolyF
    ''
    IF (mnuIncludeLibChoseFntSub(0).checked = false) THEN
        FOR i = 3 TO 4
            mnuIncludeLibChosePrmPolySub(i).checked = true
        NEXT i

        mnuIncludeLibChoseFntSub(0).checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseFntSub(0).checked = false
    END IF

END SUB

SUB mnuIncludeLibChoseInpAll_Click ()
    DIM i AS INTEGER


    IF (mnuIncludeLibChoseInpAll.checked = false) THEN
        mnuIncludeLibChoseInpAll.checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseInpAll.checked = false
    END IF


    FOR i = 0 TO 1
        mnuIncludeLibChoseInpSub(i).checked = mnuIncludeLibChoseInpAll.checked
    NEXT i

END SUB

SUB mnuIncludeLibChoseInpSub_Click (Index AS INTEGER)

    IF (mnuIncludeLibChoseInpSub(Index).checked = false) THEN
        mnuIncludeLibChoseInpSub(Index).checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseInpAll.checked = false
        mnuIncludeLibChoseInpSub(Index).checked = false
    END IF

END SUB

SUB mnuIncludeLibChoseMscSub_Click (Index AS INTEGER)

    ''
    '' Music module depends on timer
    ''
    IF (mnuIncludeLibChoseMscSub(Index).checked = false) THEN
        mnuIncludeLibChoseMscSub(Index).checked = true
    ELSE
        IF (Index = 0) THEN
            mnuIncludeLibChoseSndSub(1).checked = false
        END IF

        mnuIncludeLibAll.checked = false
        mnuIncludeLibChoseMscSub(Index).checked = false
    END IF

END SUB

SUB mnuIncludeLibChosePrmBlitAll_Click ()
    DIM i AS INTEGER

    IF (mnuIncludeLibChosePrmBlitAll.checked = false) THEN
        mnuIncludeLibChosePrmBlitAll.checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChosePrmBlitAll.checked = false
    END IF


    FOR i = 0 TO 5
        mnuIncludeLibChosePrmBlitSub(i).checked = mnuIncludeLibChosePrmBlitAll.checked
    NEXT i


    ''
    '' Dependencies
    ''
    ''
    IF (mnuIncludeLibChosePrmBlitAll.checked = true) THEN
        mnuIncludeLibChosePrmPolySub(2).checked = true
    END IF


END SUB

SUB mnuIncludeLibChosePrmBlitSub_Click (Index AS INTEGER)
    DIM i AS INTEGER

    IF (mnuIncludeLibChosePrmBlitSub(Index).checked = false) THEN
        FOR i = 0 TO 5
            mnuIncludeLibChosePrmBlitSub(i).checked = true
        NEXT i

        ''
        '' The rotate and scale routines require uglQuadT
        ''
        ''
        mnuIncludeLibChosePrmPolySub(2).checked = true

    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChosePrmBlitAll.checked = false

        FOR i = 0 TO 5
            mnuIncludeLibChosePrmBlitSub(i).checked = false
        NEXT i
    END IF
END SUB

SUB mnuIncludeLibChosePrmPolyAll_Click ()
    DIM i AS INTEGER

    IF (mnuIncludeLibChosePrmPolyAll.checked = false) THEN
        mnuIncludeLibChosePrmPolyAll.checked = true
    ELSE
        mnuIncludeLibAll.checked = false
        mnuIncludeLibChosePrmPolyAll.checked = false
    END IF


    FOR i = 0 TO 4
        mnuIncludeLibChosePrmPolySub(i).checked = mnuIncludeLibChosePrmPolyAll.checked
    NEXT i


    ''
    '' Dependencies
    ''
    IF (mnuIncludeLibChosePrmPolyAll.checked = false) THEN
        mnuIncludeLibChoseFntSub(0).checked = false

        FOR i = 0 TO 5
            mnuIncludeLibChosePrmBlitSub(i).checked = false
        NEXT i
    END IF


END SUB

SUB mnuIncludeLibChosePrmPolySub_Click (Index AS INTEGER)
    DIM i AS INTEGER

    ''
    '' If vector fonts depend on uglPoly, so if
    '' they're not chosen we have to uncheck
    '' the vector fonts as well
    ''
    IF ((Index >= 3) AND (Index <= 4)) THEN

        i = Index
        IF (mnuIncludeLibChosePrmPolySub(i).checked = true) THEN
            mnuIncludeLibChoseFntSub(0).checked = false
            mnuIncludeLibChosePrmPolySub(i).checked = false
            mnuIncludeLibAll.checked = false
            mnuIncludeLibChosePrmPolyAll.checked = false

        ELSE
            mnuIncludeLibChosePrmPolySub(i).checked = true
        END IF
        

    ELSE


        IF (mnuIncludeLibChosePrmPolySub(Index).checked = false) THEN
            mnuIncludeLibChosePrmPolySub(Index).checked = true
        ELSE
            mnuIncludeLibAll.checked = false
            mnuIncludeLibChosePrmPolyAll.checked = false

            mnuIncludeLibChosePrmPolySub(Index).checked = false

            ''
            '' Rotate and scale routines depend upon
            '' uglQuadT
            ''
            ''
            IF (mnuIncludeLibChosePrmPolySub(2).checked = false) THEN
                FOR i = 0 TO 5
                    mnuIncludeLibChosePrmBlitSub(i).checked = false
                NEXT i
            END IF


        END IF

    END IF

END SUB

SUB mnuIncludeLibChoseSndSub_Click (Index AS INTEGER)

    ''
    '' Music module requires sound module and
    '' timer module
    ''
    IF (Index = 0) THEN
        IF (mnuIncludeLibChoseSndSub(0).checked = false) THEN
            mnuIncludeLibChoseSndSub(0).checked = true
        ELSE
            mnuIncludeLibChoseSndSub(0).checked = false
            mnuIncludeLibChoseSndSub(1).checked = false
        END IF
    ELSEIF (Index = 1) THEN
        mnuIncludeLibAll.checked = false

        IF (mnuIncludeLibChoseSndSub(1).checked = false) THEN
            mnuIncludeLibChoseSndSub(0).checked = true
            mnuIncludeLibChoseSndSub(1).checked = true
            mnuIncludeLibChoseMscSub(0).checked = true
        ELSE
            mnuIncludeLibChoseSndSub(1).checked = false
        END IF
    END IF


END SUB

DEFSNG A-Z
SUB mnuOpBldTrgBC_Click ()

    mnuOpBldTrgBC.checked = true
    mnuOpBldTrgQb45.checked = false
    mnuOpBldTrgQb71.checked = false
    mnuOpBldTrgVBDos.checked = false

    Compiler = BC
    Path.caption = "Borland C/C++ Paths"
    'mnuOp.Checked

END SUB

SUB mnuOpBldTrgQb45_Click ()

    mnuOpBldTrgBC.checked = false
    mnuOpBldTrgQb45.checked = true
    mnuOpBldTrgQb71.checked = false
    mnuOpBldTrgVBDos.checked = false

    Compiler = QB45
    Path.caption = "QuickBasic 4.50 Paths"

END SUB

SUB mnuOpBldTrgQb71_Click ()

    mnuOpBldTrgBC.checked = false
    mnuOpBldTrgQb45.checked = false
    mnuOpBldTrgQb71.checked = true
    mnuOpBldTrgVBDos.checked = false

    Compiler = QB71
    Path.caption = "QuickBasic 7.10 Paths"

END SUB

SUB mnuOpBldTrgVBDos_Click ()

    mnuOpBldTrgBC.checked = false
    mnuOpBldTrgQb45.checked = false
    mnuOpBldTrgQb71.checked = false
    mnuOpBldTrgVBDos.checked = true

    Compiler = VBDOS
    Path.caption = "Visual Basic 1.00 Paths"

END SUB

DEFINT A-Z
SUB mnuOpBldTypSub_Click (Index AS INTEGER)

    IF (Index = 0) THEN
        mnuOpBldTypSub(0).checked = true
        mnuOpBldTypSub(1).checked = false
    ELSE
        mnuOpBldTypSub(0).checked = false
        mnuOpBldTypSub(1).checked = true
    END IF
        
END SUB

DEFSNG A-Z
SUB mnuOpExit_Click ()
    Form_Unload false
END SUB

SUB mnuOpPaths_Click ()
    Path.SHOW
END SUB

