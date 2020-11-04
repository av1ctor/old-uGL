' Procedure declarations for Common Dialog Toolkit.
'

' Public routines.
DECLARE SUB About (AboutText AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Flags AS INTEGER)
DECLARE SUB ChangeText (FText AS STRING, CText AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Options AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)
DECLARE SUB CmnDlgClose ()
DECLARE SUB CmnDlgRegister (Success AS INTEGER)
DECLARE SUB ColorPalette (ColorNum AS INTEGER, ForeColor AS INTEGER, BackColor AS INTEGER, Cancel AS INTEGER)
DECLARE SUB FileOpen (FileName AS STRING, PathName AS STRING, DefaultExt AS STRING, DialogTitle AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)
DECLARE SUB FilePrint (Copies AS INTEGER, ForeColor AS INTEGER, BackColor AS INTEGER, Cancel AS INTEGER)
DECLARE SUB FileSave (FileName AS STRING, PathName AS STRING, DefaultExt AS STRING, DialogTitle AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)
DECLARE SUB FindText (FText AS STRING, ForeColor AS INTEGER, BackColor AS INTEGER, Options AS INTEGER, Flags AS INTEGER, Cancel AS INTEGER)

' Private routines.
DECLARE SUB DrawAboutPicture ()
DECLARE SUB filOpenList_DblClick ()

