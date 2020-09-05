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
import app                     : Animate;
import app                     : Element;
import app                     : Animation;
import app                     : element;
import app                     : animation;
import app                     : AnimateElement;
import app                     : curTime;
import value                   : Value;
import value                   : ValueType;


int xPos; 
int yPos;
Widget rootWidget;

extern (Windows)
LRESULT WinProcUno( HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam ) nothrow
{
    HDC hdc;
    PAINTSTRUCT ps;

    switch ( message )
    {
        case WM_CREATE:
        {
            rootWidget = CreateWidgets();
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
                y = element.computed.width;
            } catch ( Throwable ) {}

            int aLeft   = xPos - aRadius;
            int aTop    = bottom - y - aRadius;
            int aRight  = xPos + aRadius;
            int aBottom = bottom - y + aRadius;

            Ellipse( hdc, aLeft, aTop, aRight, aBottom );   

            //
            RECT wRect;
            GetClientRect( hwnd, &wRect );
            WLoop( hdc, rootWidget, &wRect );

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

        case WM_LBUTTONDOWN: return rootWidget.Event( hwnd, message, wParam, lParam );
            
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


int GET_X_LPARAM( LPARAM lp ) nothrow
{
    return cast( int ) cast( short )LOWORD( lp );
}


int GET_Y_LPARAM( LPARAM lp ) nothrow
{
    return cast( int ) cast( short )HIWORD( lp );
}


enum WidgetState
{
    a,
    b,
    c,
    d
}


enum Display
{
    INLINE,
    BLOCK
}


struct Style
{
    Value left         = 0;
    Value top          = 0;
    Value right        = 0;
    Value bottom       = 0;

    Value margin       = "";
    Value marginLeft   = 0;
    Value marginTop    = 0;
    Value marginRight  = 0;
    Value marginBottom = 0;

    Value display      = "inline";
    Value lineHeight   = "inherit";
    Value wrapLine     = 0;
}


struct Computed
{
    union
    {
        struct
        {        
            int left   = 0;
            int top    = 0;
            int right  = 0;
            int bottom = 0;
        };
        RECT rect;
    }

    union
    {
        struct
        {        
            int marginLeft   = 0;
            int marginTop    = 0;
            int marginRight  = 0;
            int marginBottom = 0;
        };
        RECT margin;
    }

    Display display  = Display.INLINE;
    int lineHeight   = 12;
    int wrapLine     = 0;
}


class Widget
{
    WidgetState widgetState;
    Style       style;
    Computed    computed;
    Widget[]    childs;
    Widget      parent;


    void addChild( Widget c ) nothrow
    {
        if ( c.parent !is null )
        {
            c.parent.removeChild( c );
        }

        c.parent = this;
        childs ~= c;
    }


    void removeChild( Widget c ) nothrow
    {
        try {
            childs = childs.remove!( a => a == c );
        } catch ( Throwable e ) { Writeln( e ); }
    }


    bool HitTest( POINT pt ) nothrow
    {
        return cast( bool ) PtInRect( &computed.rect, pt );
    }


    void MouseClick() nothrow
    {
        try {
            writefln( "MouseClick()" );
        } catch ( Throwable ) {}
    }


    LRESULT Event( HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam ) nothrow
    {
        switch ( message )
        {
            case WM_LBUTTONDOWN: {
                POINT pt;

                pt.x = GET_X_LPARAM( lParam );
                pt.y = GET_Y_LPARAM( lParam );

                if ( HitTest( pt ) )
                {
                    MouseClick();
                }
                return 0;                
            }
            default:
        }

        return 0;
    }
}


Widget CreateWidgets() nothrow
{
    auto rootWidget = new Widget();
    rootWidget.style.left   = 0;
    rootWidget.style.top    = 0;
    rootWidget.style.right  = 10;
    rootWidget.style.bottom = 10;


    auto widgetStateA = new Widget();

    with ( widgetStateA )
    {
        style.marginLeft = 0;
        style.left   = 0;
        style.top    = 10;
        style.right  = 10;
        style.bottom = 10;
    }


    auto widgetStateB = new Widget();

    with ( widgetStateB )
    {
        style.marginLeft = 10;
        style.left   = 0;
        style.top    = 10;
        style.right  = 10;
        style.bottom = 10;
    }


    auto widgetStateC = new Widget();

    with ( widgetStateC )
    {
        style.marginLeft = 10;
        style.left   = 0;
        style.top    = 10;
        style.right  = 10;
        style.bottom = 10;
    }


    auto widgetStateD = new Widget();

    with ( widgetStateD )
    {
        style.marginLeft = 10;
        style.left   = 0;
        style.top    = 10;
        style.right  = 10;
        style.bottom = 10;
    }


    rootWidget.addChild( widgetStateA );
    rootWidget.addChild( widgetStateB );
    rootWidget.addChild( widgetStateC );
    rootWidget.addChild( widgetStateD );

    return rootWidget;
}


void WLoop( HDC hdc, Widget rootWidget, RECT* wRect ) nothrow
{
    // Compute
    Computer().Compute( rootWidget );
 
    // Draw
    POINT pt = { 0, 0 }; // Graphic Cursor
    Drawer().DrawTree( hdc, rootWidget, wRect, &pt );
}


int max( int a, int b ) nothrow
{
    return ( a > b ) ? a : b;
}


struct Drawer
{
    void DrawTree( HDC hdc, Widget widget, RECT* rect, POINT* pt ) nothrow
    {
        DrawWidget( hdc, widget, rect, pt );
    }


    void DrawWidget( HDC hdc, Widget widget, RECT* rect, POINT* pt ) nothrow
    {
        // Root
        RECT* margin = &widget.computed.margin;
        DrawRoot( hdc, widget, rect, pt, margin );

        // Childs
        DrawChilds( hdc, widget, rect, pt );
    }


    pragma( inline )
    void DrawRoot( HDC hdc, Widget widget, RECT* rect, POINT* pt, RECT* margin ) nothrow
    {
        final switch ( widget.computed.display )
        {
            case Display.INLINE : Display_Inline( widget, rect, pt, margin ); break;
            case Display.BLOCK  : Display_Block ( widget, rect, pt, margin ); break;
        }

        // Widget Border
        Rectangle( hdc, widget.computed.left, widget.computed.top, widget.computed.right, widget.computed.bottom );

        try {
            writefln( "Draw(): %s,%s %sx%s", widget.computed.left, widget.computed.top, widget.computed.right, widget.computed.bottom );
        } catch ( Throwable ) {}
    }


    pragma( inline )
    void DrawChilds( HDC hdc, Widget widget, RECT* rect, POINT* pt ) nothrow
    {
        foreach( c; widget.childs ) 
        {
            DrawWidget( hdc, c, rect, pt );
        }
    }


    pragma( inline )
    void PutWidget( Widget widget, int left, int top, POINT* pt, RECT* margin ) nothrow
    {
        auto width = widget.computed.rect.right - widget.computed.rect.left;
        auto height = widget.computed.rect.bottom - widget.computed.rect.top;

        widget.computed.rect.left = left;
        widget.computed.rect.top = top;
        widget.computed.rect.right = left + width;
        widget.computed.rect.bottom = top + height;

        pt.x = widget.computed.rect.right;
        pt.y = widget.computed.rect.top;

        *margin = widget.computed.margin;
    }


    pragma( inline )
    void Display_Inline( Widget widget, RECT* rect, POINT* pt, RECT* margin ) nothrow
    {
        // Wrap
        if ( widget.computed.wrapLine )
        {
            Display_Inline_WrapLine( widget, rect, pt, margin );
        }
        else // No-Wrap
        {
            Display_Inline_NoWrap( widget, rect, pt, margin );
        }
    }


    pragma( inline )
    void Display_Inline_WrapLine( Widget widget, RECT* rect, POINT* pt, RECT* margin ) nothrow
    {
        if ( rect.left + ( widget.computed.rect.right - widget.computed.rect.left ) > rect.right ) // Wrap
        { 
            PutWidget( 
                widget, 
                rect.left + widget.computed.marginLeft, 
                pt.y + widget.computed.lineHeight, 
                pt,
                margin
            );
        }
        else // No-Wrap
        {
            PutWidget( 
                widget, 
                pt.x + ( widget.computed.rect.right - widget.computed.rect.left ) + max( margin.right, widget.computed.marginLeft ), 
                pt.y, 
                pt,
                margin
            );
        }
    }


    pragma( inline )
    void Display_Inline_NoWrap( Widget widget, RECT* rect, POINT* pt, RECT* margin ) nothrow
    {
        PutWidget( 
            widget, 
            pt.x + ( widget.computed.rect.right - widget.computed.rect.left ) + max( margin.right, widget.computed.margin.left ), 
            pt.y, 
            pt,
            margin
        );
    }


    pragma( inline )
    void Display_Block( Widget widget, RECT* rect, POINT* pt, RECT* margin ) nothrow
    {
        auto height = widget.computed.bottom - widget.computed.top;

        PutWidget( 
            widget, 
            rect.left, 
            pt.y + height,
            pt,
            margin
        );
    }
}


struct Computer
{
    Widget    widget;
    Style*    style;
    Computed* computed;
    Widget*   parent;


    void Compute( Widget widget ) nothrow
    {
        this.widget   = widget;
        this.style    = &widget.style;
        this.computed = &widget.computed;
        this.parent   = &widget.parent;

        static foreach ( pName; FieldNameTuple!Style )
        {
            static if ( hasMember!( Computer, format!"Compute_%s"( pName ) ) )
                mixin( 
                    CallComputeProperty!pName
                );
        }
    }


    static
    string CallComputeProperty( string PNAME )()
    {
        return
            format!
            "
                if ( style.%s.type != ValueType.UNDEFINED )   // Style Properties Less Important
                {
                    Compute_%s();
                }
            "
            ( PNAME, PNAME )        
        ;
    }


    void ComputeChilds( Widget widget ) nothrow
    {
        foreach ( c; widget.childs )
        {
            Compute( c );
        }
    }


    void Compute_left           () nothrow { Compute_Property!( "left"  , Compute_Number, Compute_Inherit ); }
    void Compute_top            () nothrow { Compute_Property!( "top"   , Compute_Number, Compute_Inherit ); }
    void Compute_right          () nothrow { Compute_Property!( "right" , Compute_Number, Compute_Inherit ); }
    void Compute_bottom         () nothrow { Compute_Property!( "bottom", Compute_Number, Compute_Inherit ); }
    
    void Compute_marginLeft     () nothrow { Compute_Property!( "marginLeft"  , Compute_Number ); }
    void Compute_marginTop      () nothrow { Compute_Property!( "marginTop"   , Compute_Number ); }
    void Compute_marginRight    () nothrow { Compute_Property!( "marginRight" , Compute_Number ); }
    void Compute_marginBottom   () nothrow { Compute_Property!( "marginBottom", Compute_Number ); }
    
    void Compute_display() nothrow
    {
        //C( 
        //    "inline", Display.INLINE,
        //    "block", Display.BLOCK,
        // );

        if ( style.display.type == ValueType.STRING )
        {
            if ( style.display.valueString == "inline" )
            {
                computed.display = Display.INLINE;
                return;
            }
            else
            if ( style.display.valueString == "block" )
            {
                computed.display = Display.BLOCK;
                return;
            }
        }

        StyleValueErrorMessage!( "display" );
    }

    void Compute_lineHeight     () nothrow { Compute_Property!( "lineHeight", Compute_Number, Compute_Inherit ); }
    void Compute_wrapLine       () nothrow { Compute_Property!( "wrapLine"  , Compute_Number, Compute_Inherit ); }


    void StyleValueErrorMessage( string pName)() nothrow
    {
        Writefln( "error: unsupported value: %s", pName );
        //Writefln( "error: unsupported value: %s: %s", pName.stringof, __traits( getMember, style, pName ) );
    }


    void Compute_Property( string pName, FUNCS... )() nothrow
    {
        static foreach( FUNC; FUNCS )
        {
            mixin( FUNC( pName ) );
        }

        StyleValueErrorMessage!( pName );
    }
}


string Compute_Number( string pName )
{
    return
        format!
            q{
                if ( style.%s.type == ValueType.INT )
                {
                    computed.%s = style.%s.valueInt;
                    return;
                }
                else
                if ( style.%s.type == ValueType.STRING )
                {
                    if ( style.%s.valueString.isNumeric )
                    {                    
                        computed.%s = style.%s.valueString.To!( typeof( Computed.%s ) );
                        return;
                    }
                }
            }
            ( pName, pName, pName, pName, pName, pName, pName, pName );
}


string Compute_Inherit( string pName )
{
    return
        format!
            q{
                if ( style.%s.type == ValueType.STRING )
                {
                    if ( style.%s.valueString == "inherit" )
                    {
                        if ( parent )
                        {
                            computed.%s = parent.computed.%s;
                            return;
                        }
                    }
                }
            }
            ( pName, pName, pName, pName );
}


pragma( inline )
void Writeln( A... )( A a ) nothrow
{
    try {
        writeln( a );
    } catch ( Throwable e ) { assert( 0, e.toString() ); }
}


pragma( inline )
void Writefln( A... )( A a ) nothrow
{
    try {
        writeln( a );
    } catch ( Throwable e ) { assert( 0, e.toString() ); }
}


pragma( inline )
auto To( TYPE, VAR )( VAR var ) nothrow
{
    try {
        return var.to!TYPE;
    } catch ( Throwable e ) { assert( 0, e.toString() ); }
}


template staticCat(T...)
if (T.length)
{
    import std.array;
    enum staticCat = [T].join();
}

