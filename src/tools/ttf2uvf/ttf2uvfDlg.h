// ttf2uvfDlg.h : header file
//

#if !defined(AFX_TTF2UVFDLG_H__7D650636_24C5_4318_98F2_E1A617B5864E__INCLUDED_)
#define AFX_TTF2UVFDLG_H__7D650636_24C5_4318_98F2_E1A617B5864E__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "previewbutton.h"

/////////////////////////////////////////////////////////////////////////////
// CTtf2uvfDlg dialog

class CTtf2uvfDlg : public CDialog
{
// Construction
public:
	CFont *GetFont(BOOL big = FALSE);
	CTtf2uvfDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CTtf2uvfDlg)
	enum { IDD = IDD_TTF2UVF_DIALOG };
	CListBox	m_stylelist;
	CPreviewButton m_preview;
	CListBox	m_listbox;
	CTreeCtrl	m_tree;
	CString		m_editb;
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CTtf2uvfDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	//{{AFX_MSG(CTtf2uvfDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	afx_msg void OnButton1();
	afx_msg void OnButton2();
	afx_msg void OnSelchangeList1();
	afx_msg void OnSelchangeList2();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
private:
	BOOL m_italic;
	BOOL m_bold;
	CString m_Font;	
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_TTF2UVFDLG_H__7D650636_24C5_4318_98F2_E1A617B5864E__INCLUDED_)
