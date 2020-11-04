''
'' dos.bi -- DOS (file/conventinal memory) routines
''

''
'' conv memory routines
''
Declare Function memAlloc&      (Byval bytes As Long)

Declare Function memCalloc&     (Byval bytes As Long)

Declare Sub      memFree        (Byval farptr As Long)

Declare Function memAvail&      ()

Declare Sub      memFill        (Byval block As Long, _
                                 Byval bytes As Long, _
                                 Byval char As Integer)

Declare Sub      memFillEx      Alias "memFill" (Seg block As Any, _
                                 Byval bytes As Long, _
                                 Byval char As Integer)

Declare Sub      memCopy        (Byval dst As Long, _
                                 Byval src As Long, _
                                 Byval bytes As Long)

Declare Sub      memCopyEx      Alias "memCopy" (Seg dst As Any, _
                                 Seg src As Any, _
                                 Byval bytes As Long)

''
'' file routines
''
'' fileOpen/bfileOpen's mode(s):
Const F4READ    = 1
Const F4WRITE   = 2
Const F4RW      = F4READ or F4WRITE
Const F4CREATE  = &h4000 or F4RW
Const F4APPEND  = &h8000 or F4WRITE

'' fileSeek/bfileSeek origins:
Const FSSTART   = 0
Const FSCURRENT = 1
Const FSEND     = 2

Type FILE
    prv     As Long
    nxt     As Long
    ptrPos  As Long
    Size    As Long
    handle  As Integer
    mode    As Integer
    state   As Integer
End Type

Declare Function fileExists%    (flname As String)

Declare Function fileOpen%      (Seg f As FILE, _
                                 flname As String, _
                                 Byval mode As Integer)

Declare Sub      fileClose      (Seg f As FILE)

Declare Function fileRead&      (Seg f As FILE, _
                                 Byval destine As Long, _
                                 Byval bytes As Long)

Declare Function fileReadEx&    Alias "fileRead" (Seg f As FILE, _
                                 Seg destine As Any, _
                                 Byval bytes As Long)

Declare Function fileWrite&     (Seg f As FILE, _
                                 Byval source As Long, _
                                 Byval bytes As Long)

Declare Function fileWriteEx&   Alias "fileWrite" (Seg f As FILE, _
                                 Seg source As Any, _
                                 Byval bytes As Long)

Declare Function fileReadH&     (Seg f As FILE, _
                                 Byval destine As Long, _
                                 Byval bytes As Long)

Declare Function fileReadHEx&   Alias "fileReadH" (Seg f As FILE, _
                                 Seg destine As Any, _
                                 Byval bytes As Long)

Declare Function fileWriteH&    (Seg f As FILE, _
                                 Byval source As Long, _
                                 Byval bytes As Long)

Declare Function fileWriteHEx&  Alias "fileWriteH" (Seg f As FILE, _
                                 Seg source As Any, _
                                 Byval bytes As Long)

Declare Function fileSeek&      (Seg f As FILE, _
                                 Byval origin As Integer, _
                                 Byval bytes As Long)

Declare Function fileEOF%       (Seg f As FILE)

Declare Function filePos&       (Seg f As FILE)

Declare Function fileSize&      (Seg f As FILE)

Declare Function fileCopy%      (Seg inFile As FILE, _
                                 Byval inOffs As Long, _
                                 Seg outFile As FILE, _
                                 Byval outOffs As Long, _
                                 Byval bytes As Long)

Declare Function fileExists%    (flname As String)

''
'' file routines using buffers
''
type BFILE
    f       As FILE
    buffer  As Long
    size    As Integer
    index   As Integer
    bytes   As Integer
    written As Integer
    ptrPos  As Long
End Type


Declare Function bfileOpen%     (Seg bf As BFILE, _
                                 flname As String, _
                                 Byval mode As Integer, _
                                 Byval bufferSize As Long)

Declare Sub      bfileClose     (Seg bf As BFILE)

Declare Function bfileRead&     (Seg bf As BFILE, _
                                 Byval destine As Long, _
                                 Byval bytes As Long)

Declare Function bfileReadEx&   Alias "bfileRead" (Seg bf As BFILE, _
                                 Seg destine As Any, _
                                 Byval bytes As Long)

Declare Function bfileRead1%    (Seg bf As BFILE)

Declare Function bfileRead2%    (Seg bf As BFILE)

Declare Function bfileRead4&    (Seg bf As BFILE)

Declare Function bfileWrite&    (Seg bf As BFILE, _
                                 Byval source As Long, _
                                 Byval bytes As Long)

Declare Function bfileWriteEx&  Alias "bfileWrite" (Seg bf As BFILE, _
                                 Seg source As Any, _
                                 Byval bytes As Long)

Declare Sub      bfileWrite1    (Seg bf As BFILE, _
                                 Byval byte As Integer)

Declare Sub      bfileWrite2    (Seg bf As BFILE, _
                                 Byval word As Integer)

Declare Sub      bfileWrite4    (Seg bf As BFILE, _
                                 Byval dword As Long)

Declare Function bfileSeek&     (Seg bf As BFILE, _
                                 Byval origin As Integer, _
                                 Byval bytes As Long)

Declare Function bfileEOF%      (Seg bf As BFILE)

Declare Function bfilePos&      (Seg bf As BFILE)

Declare Function bfileSize&     (Seg bf As BFILE)

