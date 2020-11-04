/*
 * deftypes.h -- type definitions, internal use only
 */

#ifndef	__DEFTYPES_H__
#define	__DEFTYPES_H__

#ifndef	__BASLIB__
#define STRING char far *
#define ARRAY far
#else
#define STRING void *
#define ARRAY
#endif

#endif /* __DEFTYPES_H__ */