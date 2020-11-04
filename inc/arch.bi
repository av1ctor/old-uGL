''
'' arch.bi -- UAR (UGL ARchive) routines
''

'' Note: Include DOS.BI first!
    
Type UARHDR
    sig         As Long
    dirOffset   As Long
    dirLength   As Long
End Type

Type UARDIR
    fileName    As String * 56
    filePos     As Long
    fileLength  As Long
End Type

Type UARCTX
    hdr         As UARHDR
    fileOffset  As Long
    fileSize    As Long
End Type


Type UAR
    f           As FILE
    ctx         AS UARCTX
End Type
        
Declare Function uarOpen%       (Seg u As UAR, _
                                 flname As String, _
                                 Byval mode As Integer)

Declare Sub      uarClose       (Seg u As UAR)

Declare Function uarRead&       (Seg u As UAR, _
                                 Byval destine As Long, _
                                 Byval bytes As Long)

Declare Function uarReadEx&     Alias "uarRead" (Seg u As UAR, _
                                 Seg destine As Any, _
                                 Byval bytes As Long)

Declare Function uarReadH&      (Seg u As UAR, _
                                 Byval destine As Long, _
                                 Byval bytes As Long)

Declare Function uarReadHEx&    Alias "uarReadH" (Seg u As UAR, _
                                 Seg destine As Any, _
                                 Byval bytes As Long)

Declare Function uarSeek&       (Seg u As UAR, _
                                 Byval origin As Integer, _
                                 Byval bytes As Long)

Declare Function uarEOF%        (Seg u As UAR)

Declare Function uarPos&        (Seg u As UAR)

Declare Function uarSize&       (Seg u As UAR)


''
'' uar routines using buffers
''
Type UARB
    bf          As BFILE
    ctx         As UARCTX
End Type

Declare Function uarbOpen%      (Seg ub As UARB, _
                                 flname As String, _
                                 Byval mode As Integer, _
                                 Byval bufferSize As Long)

Declare Sub      uarbClose      (Seg ub As UARB)

Declare Function uarbRead&      (Seg ub As UARB, _
                                 Byval destine As Long, _
                                 Byval bytes As Long)

Declare Function uarbReadEx&    Alias "uarbRead" (Seg ub As UARB, _
                                 Seg destine As Any, _
                                 Byval bytes As Long)

Declare Function uarbRead1%     (Seg ub As UARB)

Declare Function uarbRead2%     (Seg ub As UARB)

Declare Function uarbRead4&     (Seg ub As UARB)

Declare Function uarbSeek&      (Seg ub As UARB, _
                                 Byval origin As Integer, _
                                 Byval bytes As Long)

Declare Function uarbEOF%       (Seg ub As UARB)

Declare Function uarbPos&       (Seg ub As UARB)

Declare Function uarbSize&      (Seg ub As UARB)


''
'' direct management of archives (use with care!)
''
Declare Function uarFileFind%   (Seg u As UAR, _
                                 pdir As UARDIR, _
                                 flname As String)
        
Declare Function uarFileSeek%   (Seg u As UAR, _
                                 pdir As UARDIR)

Declare Function uarFileExtract% (Seg u As UAR, _
                                  pdir As UARDIR, _
                                  outFile As String)

Declare Function uarFileAdd%    (Seg u As UAR, _
                                 srcFile As String, _
                                 fileName As String)

Declare Function uarFileDel%    (Seg u As UAR, _
                                 pdir AS UARDIR)

Declare Function uarCreate%     (Seg u As UAR, _
                                 archiveName As String)
