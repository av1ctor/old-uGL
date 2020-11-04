''
'' kbd.bi -- multiple keys press processing module structs & prototypes
''

Type TKBD
        lastkey As Integer
        esc     As Integer
        one     As Integer
        two     As Integer
        three   As Integer
        four    As Integer
        five    As Integer
        six     As Integer
        seven   As Integer
        eight   As Integer
        nine    As Integer
        zero    As Integer
        less    As Integer
        equal   As Integer
        backspc As Integer
        tabk    As Integer
        q       As Integer
        w       As Integer
        e       As Integer
        r       As Integer
        t       As Integer
        y       As Integer
        u       As Integer
        i       As Integer
        o       As Integer
        p       As Integer
        opnBrck As Integer
        clsBrck As Integer
        enter   As Integer
        ctrl    As Integer
        a       As Integer
        s       As Integer
        d       As Integer
        f       As Integer
        g       As Integer
        h       As Integer
        j       As Integer
        k       As Integer
        l       As Integer
        semicol As Integer
        apost   As Integer
        tilde   As Integer
        lshift  As Integer
        bslash  As Integer
        z       As Integer
        x       As Integer
        c       As Integer
        v       As Integer
        b       As Integer
        n       As Integer
        m       As Integer
        comma   As Integer
        dot     As Integer
        slash   As Integer
        rshift  As Integer
        prt     As Integer
        alt     As Integer
        spcbar  As Integer
        caps    As Integer
        f1      As Integer
        f2      As Integer
        f3      As Integer
        f4      As Integer
        f5      As Integer
        f6      As Integer
        f7      As Integer
        f8      As Integer
        f9      As Integer
        f10     As Integer
        numlock As Integer
        scroll  As Integer
        home    As Integer
        up      As Integer
        pgup    As Integer
        min     As Integer
        left    As Integer
        mid     As Integer
        right   As Integer
        plus    As Integer
        endk    As Integer
        down    As Integer
        pgdw    As Integer
        ins     As Integer
        del     As Integer
        sysreq  As Integer
        reserv0 As String * 04
        f11     As Integer
        f12     As Integer
        reserv1 As String * 80
End Type

Declare Sub      kbdInit        (Seg kbd As TKBD)

Declare Sub      kbdEnd         ()

Declare Sub      kbdPause       ()

Declare Sub      kbdResume      ()
