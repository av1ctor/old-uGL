''
'' font.bi -- stroked/bitmapped fonts module
''

'' vertical align modes:
Const FONT.VALIGN.TOP     = 0%                  '' (default)
Const FONT.VALIGN.BOTTOM  = 1%
Const FONT.VALIGN.BASELINE= 2%  
        
'' horizontal align modes:
Const FONT.HALIGN.LEFT    = 0%                  '' (default)
Const FONT.HALIGN.RIGHT   = 1%
Const FONT.HALIGN.CENTER  = 2%
        
'' background modes:
Const FONT.BG.TRANSPARENT = 0%                  '' (default)
Const FONT.BG.OPAQUE      = 1%

Const FONT.FALSE          = 0%
Const FONT.TRUE           = -1%

'' Print's `format':
Const FONT.FMT.EXPANDTABS = 1%
Const FONT.FMT.TABSTOP    = 2%                  '' (default: 8)
        
Const FONT.FMT.EXTLEADING = 4%
        
Const FONT.FMT.LEFT       = 8%                  '' (default)
Const FONT.FMT.CENTER     = 16%
Const FONT.FMT.RIGHT      = 32%

Const FONT.FMT.SINGLELINE = 64%

Const FONT.FMT.TOP        = 128%                '' (default)
Const FONT.FMT.VCENTER    = 256%                '' (needs FMT.SINGLELINE)
Const FONT.FMT.BOTTOM     = 512%                '' (needs FMT.SINGLELINE)

Const FONT.FMT.WORDBREAK  = 1024%
Const FONT.FMT.WORD.ELLIPSIS= 2048%             '' (needs FMT.SINGLELINE)

Declare Function fontNew&       (fileName As String)
Declare Sub      fontDel        (Seg uFont As Long)
        
Declare Sub      fontSetAlign   (Byval horz As Integer, _
                                 Byval vert As Integer)
Declare Sub      fontGetAlign   (horz As Integer, _
                                 vert As Integer)
Declare Function fontHAlign%    (Byval mode As Integer)
Declare Sub      fontSetHAlign  Alias "fontHAlign" _
                                (Byval mode As Integer)
Declare Function fontVAlign%    (Byval mode As Integer)
Declare Sub      fontSetVAlign  Alias "fontVAlign" _
                                (Byval mode As Integer)

Declare Function fontExtraSpc%  (Byval extra As Integer)
Declare Sub      fontSetExtraSpc Alias "fontExtraSpc" _
                                (Byval extra As Integer)
Declare Function fontGetExtraSpc% ()

Declare Function fontUnderline% (Byval underlined As Integer)
Declare Sub      fontSetUnderline Alias "fontUnderline" _
                                (Byval underlined As Integer)
Declare Function fontGetUnderline% ()

Declare Function fontStrikeOut% (Byval strikedout As Integer)
Declare Sub      fontSetStrikeOut Alias "fontStrikeOut" _
                                (Byval strikedout As Integer)
Declare Function fontGetStrikeOut% ()

Declare Function fontOutline%   (Byval outlined As Integer)
Declare Sub      fontSetOutline Alias "fontOutline" _
                                (Byval outlined As Integer)
Declare Function fontGetOutline% ()

Declare Function fontBGMode%    (Byval mode As Integer)
Declare Sub      fontSetBGMode  Alias "fontBGMode" _
                                (Byval mode As Integer)
Declare Function fontGetBGMode% ()

Declare Function fontBGColor&   (Byval clr As Long)
Declare Sub      fontSetBGColor  Alias "fontBGColor" _
                                (Byval clr As Long)
Declare Function fontGetBGColor& ()

Declare Function fontSize%      (Byval newSize As Integer)
Declare Sub      fontSetSize    Alias "fontSize" _
                                (Byval newSize As Integer)
Declare Function fontGetSize%   ()
        
Declare Function fontAngle%     (Byval newAngle As Integer)
Declare Sub      fontSetAngle   Alias "fontAngle" _
                                (Byval newAngle As Integer)
Declare Function fontGetAngle%  ()


Declare Function fontWidth%     (text As String, _
                                 Byval uFont As Long)

Declare Sub      fontTextOut    (Byval dc As Long, _
                                 Byval x As Long, _
                                 Byval y As Long, _
                                 Byval clr As Long, _
                                 Byval uFont As Long, _
                                 text As String)
                                 
Declare Sub      fontPrint      (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval clr As Long, _
                                 Byval uFont As Long, _
                                 text As String)

Declare Sub      fontDraw       (Byval dc As Long, _
                                 rc As RECT, _
                                 Byval format As Long, _
                                 Byval clr As Long, _
                                 Byval uFont As Long, _
                                 text As String)
