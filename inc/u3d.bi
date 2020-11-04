type u3dVector3f
    x           as single
    y           as single
    z           as single    
end type

type u3dVector4f
    x           as single
    y           as single
    z           as single
    w           as single
end type    

type u3dMtrx
    m11         as single
    m12         as single
    m13         as single
    m14         as single
    m21         as single
    m22         as single
    m23         as single
    m24         as single    
    m31         as single
    m32         as single
    m33         as single
    m34         as single    
    m41         as single
    m42         as single
    m43         as single
    m44         as single    
end type
    

declare sub         u3dVec3Norm         ( seg vOut as any, byval vOutSize as integer, _
                                          seg vIn as any,  byval vInSize as integer, _
                                          byval cnt as integer )
                                          
declare sub         u3dMtrxByVec3       ( seg vOut as any, byval vOutSize as integer, _
                                          seg mIn as any, seg vIn as any, byval vInSize as integer, _
                                          byval cnt as integer )    
declare sub         u3dMtrxByVec4       ( seg vOut as any, byval vOutSize as integer, _
                                          seg mIn as any, seg vIn as any, byval vInSize as integer, _
                                          byval cnt as integer )

declare sub         u3dMtrxConc         ( seg pOut as any, seg a as any, _
                                          seg b as any )
declare sub         u3dMtrxCopy         ( seg pDst as any, seg pSrc as any )                                          
declare sub         u3dMtrxIdent        ( seg pOut as any )
declare sub         u3dMtrxLookAt       ( seg pOut as any, seg pEye as any, _
                                          seg pAt as any, seg pUp as any )
declare sub         u3dMtrxRotX         ( seg pOut as any, byval ang as single )
declare sub         u3dMtrxRotY         ( seg pOut as any, byval ang as single )
declare sub         u3dMtrxRotZ         ( seg pOut as any, byval ang as single )
declare sub         u3dMtrxPersp        ( seg pOut as any, byval fov as single, _
                                          byval asp as single, byval zn as single, _
                                          byval zf as single )                                          
declare sub         u3dMtrxScale        ( seg pOut as any, byval x as single, _
                                          byval y as single, byval z as single )
declare sub         u3dMtrxTrans        ( seg pOut as any, byval x as single, _
                                          byval y as single, byval z as single )
