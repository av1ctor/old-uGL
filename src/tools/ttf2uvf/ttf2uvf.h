// ttf2uvf.h : main header file for the TTF2UVF application
//

#if !defined(AFX_TTF2UVF_H__5DFBA03E_4CAA_4C87_8D37_838036D0003D__INCLUDED_)
#define AFX_TTF2UVF_H__5DFBA03E_4CAA_4C87_8D37_838036D0003D__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CTtf2uvfApp:
// See ttf2uvf.cpp for the implementation of this class
//

class CTtf2uvfApp : public CWinApp
{
public:
	CTtf2uvfApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CTtf2uvfApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CTtf2uvfApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_TTF2UVF_H__5DFBA03E_4CAA_4C87_8D37_838036D0003D__INCLUDED_)
