module uno_window;

import windows;
import core.sys.windows.windows;
static import winapi = core.sys.windows.windows;
import core.time               : Duration;
import core.time               : MonoTime;
import core.time               : dur;
import std.algorithm           : remove;
import std.algorithm.searching : find;
import std.array               : join;
import std.conv                : to;
import std.format              : format;
import std.stdio               : writeln;
import std.stdio               : writefln;
import std.string              : isNumeric;
import std.traits              : Fields, FieldNameTuple, hasMember;
import animator                : Animate;
import animator                : Animation;
import animator                : AnimateElement;
import element                 : Element;
import value                   : Value;
import value                   : ValueType;
import app                     : curTime;
import app                     : animation;
import app                     : element;
import tools                   : GET_X_LPARAM;
import tools                   : GET_Y_LPARAM;
import tools                   : Writeln;
import computer                : Computer;
import drawer                  : Drawer;


int xPos; 
int yPos;
Element* rootElement;


extern (Windows)
LRESULT WinProcUno( HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam ) nothrow
{
    HDC hdc;
    PAINTSTRUCT ps;

    switch ( message )
    {
        case WM_CREATE:
        {
            rootElement = CreateElements();
            return 0;            
        }
            
        case WM_PAINT: {

            hdc = BeginPaint( hwnd, &ps );
            
            // Rect
            int winWidth   = 600;
            int winHeight  = 300;
            int rectWidth  = 100;
            int rectHeight = 100;

            int left   = ( winWidth - rectWidth ) / 2;
            int top    = ( winHeight - rectHeight ) / 2;
            int right  = left + rectWidth;
            int bottom = top + rectHeight;

            Rectangle( hdc, left, top, right, bottom );

            // Cursor
            int eRadius = 5;

            int eLeft   = xPos - eRadius;
            int eTop    = top + rectHeight - eRadius;
            int eRight  = xPos + eRadius;
            int eBottom = top + rectHeight + eRadius;

            Ellipse( hdc, eLeft, eTop, eRight, eBottom );   

            // Animation Result
            int aRadius = 5;

            int y;
            try {
                curTime = animation.start + dur!"msecs"( 10 * ( xPos - left ) );
                AnimateElement( element, animation );
                y = element.computed.left;
            } catch ( Throwable e ) { assert( 0, e.toString() ); }

            int aLeft   = xPos - aRadius;
            int aTop    = bottom - y - aRadius;
            int aRight  = xPos + aRadius;
            int aBottom = bottom - y + aRadius;

            Ellipse( hdc, aLeft, aTop, aRight, aBottom );   

            //
            RECT wRect;
            GetClientRect( hwnd, &wRect );
            WLoop( hdc, rootElement, &wRect );

            //
            EndPaint( hwnd, &ps );

            //RECT irect;
            //GetClientRect( hwnd, &irect );
            //InvalidateRect( hwnd, &irect, 0 );

            return 0;
        }
            
        case WM_MOUSEMOVE: {
            xPos = GET_X_LPARAM( lParam ); 
            yPos = GET_Y_LPARAM( lParam );

            InvalidateRect( hwnd, NULL, 1 );
            
            return 0;
        }

        case WM_LBUTTONDOWN: {
            return rootElement.Event( hwnd, message, wParam, lParam );
        }
            
        case WM_CLOSE: {
            PostQuitMessage( 0 );
            return 0;
        }
            
        default:
            return DefWindowProc( hwnd, message, wParam, lParam );
    }
}


HWND CreateWindowUno()
{
    WNDCLASS wc;

    _CreateClass( &WinProcUno, "Uno Circle", &wc );
    return _CreateWindow( "Test Animation", 600, 310, 600, 300, &wc );
}


Element* CreateElements() nothrow
{
    auto rootElement = new Element();
    rootElement.style.left    = 0;
    rootElement.style.top     = 0;
    rootElement.style.right   = 120;
    rootElement.style.bottom  = 10;
    rootElement.style.display = "inline";


    auto elementStateA = new Element();

    with ( elementStateA )
    {
        style.marginLeft = 0;
        style.left       = 0;
        style.top        = 0;
        style.right      = 10;
        style.bottom     = 10;
        style.display    = "inline-block";
    }


    auto elementStateB = new Element();

    with ( elementStateB )
    {
        style.marginLeft = 10;
        style.left       = 0;
        style.top        = 0;
        style.right      = 10;
        style.bottom     = 10;
        style.display    = "inline-block";
    }


    auto elementStateC = new Element();

    with ( elementStateC )
    {
        style.marginLeft = 10;
        style.left       = 0;
        style.top        = 0;
        style.right      = 10;
        style.bottom     = 10;
        style.display    = "inline-block";
    }


    auto elementStateD = new Element();

    with ( elementStateD )
    {
        style.marginLeft = 10;
        style.left       = 0;
        style.top        = 0;
        style.right      = 10;
        style.bottom     = 10;
        style.display    = "inline-block";
    }


    rootElement.addChild( elementStateA );
    rootElement.addChild( elementStateB );
    rootElement.addChild( elementStateC );
    rootElement.addChild( elementStateD );

    return rootElement;
}


void WLoop( HDC hdc, Element* rootElement, RECT* wRect ) nothrow
{
    // Compute
    Computer().ComputeTree( rootElement );
 
    // Draw
    POINT pt = { 0, 0 }; // Graphic Cursor
    RECT margin = { 0, 0, 0, 0 };
    Drawer().DrawTree( hdc, rootElement, wRect, &pt, &margin );
}

