module utf;

import core.sys.windows.winnt   : LPWSTR, LPCWSTR, LPCSTR, LPSTR, LPTSTR, WCHAR;
import core.stdc.wchar_         : wcslen;
import std.conv                 : to;
import std.utf                  : toUTFz, toUTF16z, UTFException;


//
// all Windows applications today Unicode
//


LPWSTR toLPWSTR( string s ) nothrow // wchar_t*
{
    try                        { return toUTFz!( LPWSTR )( s ); }
    catch ( UTFException e )   { wstring err = "ERR"w; return cast( LPWSTR )err.ptr; }
    catch ( Exception e )      { wstring err = "ERR"w; return cast( LPWSTR )err.ptr; }
}
alias toLPWSTR toPWSTR;
alias toLPWSTR toLPOLESTR;
alias toLPWSTR toPOLESTR;


LPCWSTR toLPCWSTR( string s ) nothrow // const wchar_t*
{
    try                        { return toUTF16z( s ); }
    catch ( UTFException e )   { return "ERR"w.ptr; }
    catch ( Exception e )      { return "ERR"w.ptr; }
}
alias toLPCWSTR toPCWSTR;


LPCSTR toLPCSTR( string s ) nothrow // const char_t*
{
    try                        { return toUTFz!( LPCSTR )( s ); }
    catch ( UTFException e )   { return "ERR".ptr; }
    catch ( Exception e )      { return "ERR".ptr; }
}
alias toLPCSTR toPCSTR;


LPSTR toLPSTR( string s ) nothrow // char_t*
{
    try                        { return toUTFz!( LPSTR )( s ); }
    catch ( UTFException e )   { string err = "ERR"; return cast( LPSTR )err.ptr; }
    catch ( Exception e )      { string err = "ERR"; return cast( LPSTR )err.ptr; }
}
alias toLPSTR toPSTR;


LPTSTR toLPTSTR( string s ) nothrow // char_t*
{
    try                        { return toUTFz!( LPTSTR )( s ); }
    catch ( UTFException e )   { string err = "ERR"; return cast( LPTSTR )err.ptr; }
    catch ( Exception e )      { string err = "ERR"; return cast( LPTSTR )err.ptr; }
}


// macros TEXT( "x" ) L"x"
LPCWSTR TEXT( const string s )
{
    return toLPCWSTR( s );
}

// alias wchar_t TCHAR;


//
// WCHAR[ WLAN_MAX_NAME_LENGTH ] guidString;
// string s;
// s = _info.strInterfaceDescription[ 0 .. wcslen( _info.strInterfaceDescription.ptr ) ].to!string;
//
string WcharBufToString( WCHAR[] buf )
{
    string s = buf.ptr[ 0 .. wcslen( buf.ptr ) ].to!string;
    
    return s;
}



// FormatMessage( ... lpMsgBuf ... )
// fromUTF16z( cast( wchar* )lpMsgBuf )
wstring fromUTF16z( const wchar* s )
{
    if ( s is null ) return null;

    wchar* ptr;
    for ( ptr = cast( wchar* )s; *ptr; ++ptr ) {}

    return to!wstring( s[ 0 .. ptr - s ] );
}
