''
'' snd.bi -- UGL sound module routines
'' note: Include dos.bi and arch.bi first
''

''
'' Sign/unsigned constants
''
const snd.default                 = 0
const snd.signed                  = 1
const snd.unsigned                = 2

''
'' State constants
''
const snd.null                    = 0
const snd.playing                 = 1
const snd.paused                  = 2
const snd.played                  = 3

''
'' Buffer type constants
''
const snd.mem                     = 0
const snd.ems                     = 1

''
'' Sample format constants
''
const snd.s8.mono                 = 0
const snd.s8.stereo               = 1
const snd.s16.mono                = 2
const snd.s16.stereo              = 3

''
'' Interpolation constants
''
const snd.nearest                 = 0
const snd.linear                  = 1
const snd.cubic                   = 2

''
'' Play mode constants
''
const snd.onetime                 = 0
const snd.repeat                  = 1
const snd.pingpong                = 2

''
'' Play direction constants
''
const snd.up                      = 0
const snd.down                    = 1

type sndvoice
    vocID               as long                     '' ID
    state               as integer                  '' ...
    vuLeft		as integer		    '' last sample played, 0..255
    vuRight		as integer		    '' /
    
    sample              as long                     '' attached sample
    mode                as integer                  '' play mode (REPEAT...)
    direction           as integer                  '' direction (UP, DOWN)
    lini                as long                     '' loop start & end points
    lend		as long
    cpos                as long			    '' current position (24.8)
    vol                 as integer		    '' volume (0..256)
    pan                 as integer		    '' pan level (-256..0..256)
    pitch               as long		            '' sampling rate (0..64k)
    
    vprev               as long			    '' prev voice in linked-list
    vnext 		as long			    '' next /     /  /
end type        




''
'' Routine declarations
''
                              
declare function sndInit%        ( byval addr as integer, _
                                   byval irq as integer, _
                                   byval ldma as integer, _
                                   byval hdma as integer )
                                   
declare sub      sndEnd          ()

declare function sndNewWav&       ( byval bufftype as integer, _
                                   filename as string )
                                   
declare function sndNewRaw&       ( byval bufftype as integer, _
                                   byval smpfrmt as integer, _
                                   byval smprate as long, _
                                   byval sign as integer, _
                                   filename as string, _
                                   byval offset as long, _
                                   byval length as long )
                                   
declare function sndNewRawEx&     ( byval bufftype as integer, _
                                   byval smpfrmt as integer, _
                                   byval smprate as long, _
                                   byval sign as integer, _
                                   seg hFile as UAR, _
                                   byval offset as long, _
                                   byval length as long )
                                   
declare sub       sndDel           ( byval hsmp as long )

declare sub       sndSetInterp     ( byval mode as integer )

declare sub       sndMasterSetVol  ( byval vol as integer )

declare sub       sndMasterSetPan  ( byval pan as integer )

declare sub       sndMasterGetVU   ( vuLeft as integer, _ 
                                     vuRight as integer )

declare sub       sndVoiceSetDefault ( seg voice as sndvoice )

declare sub       sndVoiceSetSample( seg voice as sndvoice, _
                                    byval sample as long )
                                    
declare sub       sndVoiceSetDir   ( seg voice as sndvoice, _
                                    byval direction as integer )
                                    
declare sub       sndVoiceSetLoopMode ( seg voice as sndvoice, _
                                       byval mode as integer )
                                       
declare sub       sndVoiceSetLoopPoints ( seg voice as sndvoice, _
                                         byval lstr as long, _ 
                                         byval lend as long )
                                         
declare sub       sndVoiceSetVol   ( seg voice as sndvoice, _
                                    byval vol as integer )
                                    
declare sub       sndVoiceSetPan   ( seg voice as sndvoice, _
                                    byval pan as integer )
                                    
declare sub       sndVoiceSetRate  ( seg voice as sndvoice, _
                                    byval pitch as long )

declare sub       sndVoicePlay     ( seg voice as sndvoice )

declare sub       sndVoiceGetVU    ( vuLeft as integer, _ 
                                     vuRight as integer, _
                                     seg voice as sndvoice )
                                    
declare sub       sndPlay          ( seg voice as sndvoice, _
                                     byval sample as long )

declare sub       sndPlayEx        ( seg voice as sndvoice, _
                                    byval sample as long, _
                                    byval smprate as long, _
                                    byval pan as integer, _
                                    byval vol as integer, _
                                    byval direction as integer, _
                                    byval mode as integer )
                                    
declare sub       sndPause         ( seg voice as sndvoice )

declare sub       sndResume        ( seg voice as sndvoice )

declare sub       sndStop          ( seg voice as sndvoice )

declare function  sndOpenOutput%   ( byval frmt as integer, _
                                     byval freq as long, _
                                     byval bps as integer )
