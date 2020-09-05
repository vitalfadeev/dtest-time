module windows;

import core.sys.windows.windows;
import std.path : dirName, baseName;
import std.file : thisExePath;
import utf      : toLPWSTR;

pragma( lib, "user32.lib" ); // MessageBox
pragma( lib, "gdi32.lib" );  // GetStockObject
pragma( lib, "ole32.lib" );  // CoInitialize, CoUninitialize

alias extern ( Windows ) LRESULT function( HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam ) nothrow WINPROC;


void _CreateClass( WINPROC winProc, string windowName, WNDCLASS* wc )
{
    auto classname = ( baseName( thisExePath ) ~ "-" ~ windowName ).toLPWSTR;

    if ( GetClassInfo( GetModuleHandle( NULL ), classname, wc ) )
    {
        // class exists
        throw new Exception( "Error when window class creation: class exists" );
    }
    else
    {
        wc.style         = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc   = winProc;
        wc.cbClsExtra    = 0;
        wc.cbWndExtra    = 0;
        wc.hInstance     = GetModuleHandle( NULL );
        wc.hIcon         = LoadIcon( NULL, IDI_APPLICATION );
        wc.hCursor       = LoadCursor( NULL, IDC_ARROW );
        wc.hbrBackground = NULL;
        wc.lpszMenuName  = NULL;
        wc.lpszClassName = classname;

        if ( !RegisterClass( wc ) )
            throw new Exception( "Error when window class creation" );
    }
}


HWND _CreateWindow( string windowName, int x, int y, int w, int h, WNDCLASS* wc )
{
    DWORD style =
        WS_TILEDWINDOW | WS_OVERLAPPEDWINDOW | WS_CAPTION |
        WS_SIZEBOX | WS_SYSMENU | WS_VISIBLE | WS_CLIPCHILDREN | 
        WS_CLIPSIBLINGS;
    DWORD styleEx = 0;

    HWND hwnd = CreateWindowEx( styleEx, 
                           wc.lpszClassName,        // window class name
                           windowName.toLPWSTR,     // window caption
                           style,                   //  0x00000008
                           x,                       // initial x position
                           y,                       // initial y position
                           w,                       // initial x size
                           h,                       // initial y size
                           NULL,                    // parent window handle
                           NULL,                    // window menu handle
                           GetModuleHandle( NULL ), // program instance handle
                           NULL
                          );                        // creation parameters

    ShowWindow( hwnd, SW_NORMAL );
    UpdateWindow( hwnd );

    return hwnd;
}
