// PreviewButton.cpp : implementation file
//

#include "stdafx.h"
#include "ttf2uvf.h"
#include "ttf2uvfdlg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CPreviewButton

CPreviewButton::CPreviewButton()
{
}

CPreviewButton::~CPreviewButton()
{
}


BEGIN_MESSAGE_MAP(CPreviewButton, CButton)
	//{{AFX_MSG_MAP(CPreviewButton)
		// NOTE - the ClassWizard will add and remove mapping macros here.
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CPreviewButton message handlers

void CPreviewButton::DrawItem(LPDRAWITEMSTRUCT lpDrawItemStruct) 
{
	CDC *cdc = CDC::FromHandle(lpDrawItemStruct->hDC);
	CTtf2uvfDlg *dlg = (CTtf2uvfDlg *)GetParent();
	CFont *font = dlg->GetFont();
	CFont *oldfont = cdc->SelectObject(font);

	cdc->TextOut(0, 0, "UGL Vector Font");

	cdc->SelectObject(oldfont);
	delete font;
}
