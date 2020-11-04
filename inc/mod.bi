''
'' mod.bi -- Mod player routines
''

const mod.mem             = 0
const mod.ems             = 1

const mod.null            = 0
const mod.playing         = 1
const mod.paused          = 2
const mod.stopped         = 3

const mod.onetime         = 0
const mod.repeat          = 1

const mod.mono            = 0
const mod.stereomin       = 0
const mod.stereomax       = 256


''
'' Structure definitions
''
type UGMPATTERNCTX
    memtype         as string * 1
    patterns        as string * 1
    addr            as long
end type

type UGMINST
    slength         as long
    c2spd           as integer
    volume          as string * 1
    loopstr         as long
    loopend         as long
    hsample         as long
end type

type UGMMOD
    mID             as string * 4
    playmode        as string * 1
    state           as integer
    channels        as string * 1
    songLength      as string * 1
    songOrder       as string * 128
    instruments(30) as UGMINST
    patCtx          as UGMPATTERNCTX
    
    bps             as string * 1
    speed           as string * 1
    currPat         as string * 1
    currRow         as string * 1
    currTick        as string * 1
    jmpFlags        as string * 1
    mnext           as long
    mprev           as long
end type



''
'' Routines
''
declare function    modInit%        ( )

declare sub         modEnd          ( )

declare function    modNew%         ( seg module as UGMMOD, _
                                      byval memtype as integer, _
                                      filename as string )
                                      
declare sub         modDel          ( seg module as UGMMOD )

declare sub         modPlay         ( seg module as UGMMOD )

declare sub         modPause        ( )

declare sub         modResume       ( )

declare sub         modStop         ( )

declare function    modGetPlayState%( )

declare sub         modGetChanVU    ( l as integer, _
                                      r as integer, _
                                      byval chn as integer )
                                      
declare function    modGetVolume%   ( )

declare sub         modSetVolume    ( byval vol as integer )

declare function    modGetPlayMode% ( seg module as UGMMOD )

declare sub         modSetPlayMode  ( seg module as UGMMOD, _
                                      byval playmode as integer )

declare sub         modSetStereo    ( byval strength as integer )

declare sub         modSetCacheSize ( byval csize as integer )

declare sub         modFadeOut      ( byval steps as integer )

declare sub         modFadeIn       ( byval steps as integer )

declare sub         modFadeToVol    ( byval vol as integer, _
                                      byval steps as integer )