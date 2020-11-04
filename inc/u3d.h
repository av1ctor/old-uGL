#ifndef __U3D_H__
#define __U3D_H__


typedef struct
{
    float       x, y, z;
} u3dVector3f;

typedef struct
{
    float       x, y, z, w;
} u3dVector4f;

typedef struct
{
    float       m11, m12, m13, m14;
    float       m21, m22, m23, m24;
    float       m31, m32, m33, m34;
    float       m41, m42, m43, m44;
} u3dMtrx;
    

#ifdef CPP
extern "C" {
#endif
    
void far pascal u3dVec3Norm         ( void far *vOut, int vOutSize,
                                      void far* vIn, int vInSize, int cnt );
void far pascal u3dMtrxByVec3       ( void far *vOut, int vOutSize, void far* mIn,
                                      void far* vIn, int vInSize, int cnt );
void far pascal u3dMtrxByVec4       ( void far *vOut, int vOutSize, void far* mIn,
                                      void far* vIn, int vInSize, int cnt );
void far pascal u3dMtrxCopy         ( void far* pDst, void far* pSrc );
void far pascal u3dMtrxConc         ( void far* pOut, void far* a, void far* b );
void far pascal u3dMtrxIdent        ( void far* pOut );
void far pascal u3dMtrxLookAt       ( void far* pOut, void far* pEye,
                                      void far* pAt, void far* pUp );
void far pascal u3dMtrxRotX         ( void far* pOut, float ang );
void far pascal u3dMtrxRotY         ( void far* pOut, float ang );
void far pascal u3dMtrxRotZ         ( void far* pOut, float ang );
void far pascal u3dMtrxPersp        ( void far* pOut, float fov,
                                      float asp , float zn, float zf );
void far pascal u3dMtrxScale        ( void far* pOut, float x, float y, float z );
void far pascal u3dMtrxTrans        ( void far* pOut, float x, float y, float z );

#ifdef CPP
}
#endif

#endif //__U3D_H__