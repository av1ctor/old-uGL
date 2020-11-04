// ttf2uvfDlg.cpp : implementation file
//

#include "stdafx.h"
#include "ttf2uvf.h"
#include "ttf2uvfDlg.h"
#include "uvf.h"


#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif



/////////////////////////////////////////////////////////////////////////////
// CAboutDlg dialog used for App About

class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

// Dialog Data
	//{{AFX_DATA(CAboutDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CAboutDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	//{{AFX_MSG(CAboutDlg)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
	//{{AFX_DATA_INIT(CAboutDlg)
	//}}AFX_DATA_INIT
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CAboutDlg)
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
	//{{AFX_MSG_MAP(CAboutDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CTtf2uvfDlg dialog

CTtf2uvfDlg::CTtf2uvfDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CTtf2uvfDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CTtf2uvfDlg)
	m_editb = _T("");
	//}}AFX_DATA_INIT
	// Note that LoadIcon does not require a subsequent DestroyIcon in Win32
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CTtf2uvfDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CTtf2uvfDlg)	
	DDX_Control(pDX, IDC_PREVIEW, m_preview);
	DDX_Control(pDX, IDC_LIST2, m_stylelist);
	DDX_Control(pDX, IDC_LIST1, m_listbox);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CTtf2uvfDlg, CDialog)
	//{{AFX_MSG_MAP(CTtf2uvfDlg)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDC_BUTTON1, OnButton1)
	ON_BN_CLICKED(IDC_BUTTON2, OnButton2)
	ON_LBN_SELCHANGE(IDC_LIST1, OnSelchangeList1)
	ON_LBN_SELCHANGE(IDC_LIST2, OnSelchangeList2)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CTtf2uvfDlg message handlers

int CALLBACK enumfontproc(const LOGFONT *lpelfe, const TEXTMETRICA *lpntme, unsigned long FontType,  long lParam)
{
	
	CListBox *combo = (CListBox *)lParam;

	//if (combo->FindStringExact(-1, lpelfe->lfFaceName) == CB_ERR)
		//fonts.push_back(CString(lpelfe->lfFaceName));
		//font_count++;
	if (combo->FindStringExact(-1, lpelfe->lfFaceName) == CB_ERR)
		combo->AddString(lpelfe->lfFaceName);

	return 1;
}

BOOL CTtf2uvfDlg::OnInitDialog()
{	
	CDialog::OnInitDialog();

	// Add "About..." menu item to system menu.

	// IDM_ABOUTBOX must be in the system command range.
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		CString strAboutMenu;
		strAboutMenu.LoadString(IDS_ABOUTBOX);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon
	
	// TODO: Add extra initialization here
	LOGFONT lf;

	lf.lfCharSet		= DEFAULT_CHARSET;
	lf.lfFaceName[0]	= 0;
	lf.lfPitchAndFamily = 0;

	CClientDC cdc(this);

	EnumFontFamiliesEx(cdc.m_hAttribDC, &lf, enumfontproc, (DWORD) &m_listbox, 0);

	m_stylelist.AddString("Regular");
	m_stylelist.AddString("Italic");
	m_stylelist.AddString("Bold");
	m_stylelist.AddString("Bold Italic");

	m_listbox.SelectString(-1, "Times New Roman");
	m_stylelist.SelectString(-1, "Regular");
	OnSelchangeList1();
	OnSelchangeList2();


	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CTtf2uvfDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialog::OnSysCommand(nID, lParam);
	}
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CTtf2uvfDlg::OnPaint() 
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, (WPARAM) dc.GetSafeHdc(), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

// The system calls this to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CTtf2uvfDlg::OnQueryDragIcon()
{
	return (HCURSOR) m_hIcon;
}




void CTtf2uvfDlg::OnButton1() 
{
	DWORD size;
	PUVF uvf = NULL;
	PSD_UVFHDR	pHdr = {0};
	CClientDC cdc(this);

	CFileDialog dlg(FALSE, "uvf", NULL, OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT,
					    "UGL Vector Font (*.uvf)|*.uvf|All Files (*.*)|*.*||");

		dlg.m_ofn.lpstrTitle = "Export Font";

		if (dlg.DoModal() == IDOK) {

			LOGFONT lf = {
				72*10,
				0,
				0,
				0,
				m_bold ? 700 : 400,
				m_italic,
				FALSE,
				FALSE,
				DEFAULT_CHARSET,
				OUT_DEFAULT_PRECIS,
				CLIP_DEFAULT_PRECIS,
				DEFAULT_QUALITY,
				DEFAULT_PITCH | FF_DONTCARE,
			};

			strcpy(lf.lfFaceName, m_Font.GetBuffer(0));

	

			if ((uvf = uvfConvert( cdc.m_hDC, &lf, &pHdr )) != NULL) {
				
				if (uvfSave( uvf, &pHdr, dlg.GetPathName().GetBuffer(0)) == NULL)
					MessageBox("Failed to create / write UVF file", "ttf2uvf Error", MB_ICONSTOP);

				free( uvf );

			} else
				MessageBox("Failed to convert font", "ttf2uvf Error", MB_ICONSTOP);

		}
	
}

void CTtf2uvfDlg::OnButton2() 
{
	OnCancel();	
}

void CTtf2uvfDlg::OnSelchangeList1() 
{
	CString buffer;

	m_listbox.GetText(m_listbox.GetCurSel(), buffer);
	m_Font = buffer;

	m_preview.Invalidate();
}

void CTtf2uvfDlg::OnSelchangeList2() 
{
	CString buffer;

	m_stylelist.GetText(m_stylelist.GetCurSel(), buffer);

	if (buffer == "Bold") {
			m_bold   = TRUE;
			m_italic = FALSE;
	
	} else if (buffer == "Italic") {
			m_bold   = FALSE;
			m_italic = TRUE;
	
	} else if (buffer == "Bold Italic") {
			m_bold   = TRUE;
			m_italic = TRUE;
	
	} else if (buffer == "Regular") {
			m_bold   = FALSE;
			m_italic = FALSE;
	}
	m_preview.Invalidate();
}

CFont *CTtf2uvfDlg::GetFont(BOOL big)
{
	LOGFONT lf = {
		48*5,
		0,
		0,
		0,
		m_bold ? 700 : 400,
		m_italic,
		FALSE,
		FALSE,
		DEFAULT_CHARSET,
		OUT_DEFAULT_PRECIS,
		CLIP_DEFAULT_PRECIS,
		DEFAULT_QUALITY,
		DEFAULT_PITCH | FF_DONTCARE,
	};

	strcpy(lf.lfFaceName, m_Font.GetBuffer(0));

	CFont *font = new CFont;
	font->CreatePointFontIndirect(&lf, NULL);

	return font;
}
