import core.sys.windows.windows;
import std.algorithm           : remove;
import value : Value;
import tools : Writeln;
import tools : Writefln;
import tools : GET_X_LPARAM;
import tools : GET_Y_LPARAM;

alias uint COLORREF;


struct COLOR
{
    COLORREF valueNative;
}


COLOR RGB( ubyte r, ubyte g, ubyte b )
{
    COLORREF valueNative = ( ( b << 16 ) | ( g << 8 ) | r ); // BGR

    return COLOR( valueNative );
}


struct Style
{
    Value left              = 0;
    Value top               = 0;
    Value right             = 0;
    Value bottom            = 0;

    Value margin            = "";
    Value marginLeft        = 0;
    Value marginTop         = 0;
    Value marginRight       = 0;
    Value marginBottom      = 0;

    Value padding           = "";
    Value paddingLeft       = 0;
    Value paddingTop        = 0;
    Value paddingRight      = 0;
    Value paddingBottom     = 0;

    Value borderWidth       = "";
    Value borderLeftWidth   = 0;
    Value borderTopWidth    = 0;
    Value borderRightWidth  = 0;
    Value borderBottomWidth = 0;

    Value width             = "auto";
    Value height            = "auto";

    Value display           = "inline";
    Value lineHeight        = "inherit";
    Value wrapLine          = 0;
    Value overflow          = "visible";
    Value overflowX         = "visible";
    Value overflowY         = "visible";
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

    union
    {
        struct
        {        
            int paddingLeft   = 0;
            int paddingTop    = 0;
            int paddingRight  = 0;
            int paddingBottom = 0;
        };
        RECT padding;
    }

    union
    {
        struct
        {        
            int borderLeftWidth   = 0;
            int borderTopWidth    = 0;
            int borderRightWidth  = 0;
            int borderBottomWidth = 0;
        };
        RECT borderWidth;
    }

    WidthMode       widthMode       = WidthMode.AUTO;
    int             width           = 0;
    HeightMode      heightMode      = HeightMode.AUTO;
    int             height          = 0;

    DisplayOutside  displayOutside  = DisplayOutside.INLINE;
    DisplayInside   displayInside   = DisplayInside.FLOW;
    int             displayListitem = 0;
    DisplayInternal displayInternal = DisplayInternal.TABLE_ROW_GROUP;
    DisplayBox      displayBox      = DisplayBox.CONTENTS;
    DisplayLegacy   displayLegacy   = DisplayLegacy.INLINE_BLOCK;
    bool            displayIsBlockLevel;

    BoxSizing       boxSizing       = BoxSizing.CONTENT_BOX;

    int             lineHeight      = 12;
    int             wrapLine        = 0;
    Overflow        overflowX       = Overflow.VISIBLE;
    Overflow        overflowY       = Overflow.VISIBLE;
}


enum WidthMode
{
    AUTO,
    LENGTH,
    PERCENTAGE,
    MIN_CONTENT, 
    MAX_CONTENT,
    FIT_CONTENT
}


enum HeightMode
{
    AUTO,
    LENGTH,
    PERCENTAGE,
    MIN_CONTENT, 
    MAX_CONTENT,
    FIT_CONTENT
}


enum BoxSizing 
{
    CONTENT_BOX,
    BORDER_BOX,    
}


enum ElementState
{
    a,
    b,
    c,
    d
}


enum DisplayOutside
{
    INLINE,
    BLOCK,
    RUN_IN
}


enum DisplayInside
{
    FLOW, 
    FLOW_ROOT, 
    TABLE, 
    FLEX, 
    GRID, 
    RUBY
}


enum DisplayBox
{
    CONTENTS, 
    NONE
}


enum DisplayInternal
{
    TABLE_ROW_GROUP, 
    TABLE_HEADER_GROUP, 
    TABLE_FOOTER_GROUP, 
    TABLE_ROW, 
    TABLE_CELL, 
    TABLE_COLUMN_GROUP, 
    TABLE_COLUMN, 
    TABLE_CAPTION, 
    RUBY_BASE, 
    RUBY_TEXT, 
    RUBY_BASE_CONTAINER, 
    RUBY_TEXT_CONTAINER
}


enum DisplayLegacy
{
    INLINE_BLOCK, 
    INLINE_LIST_ITEM, 
    INLINE_TABLE, 
    INLINE_FLEX, 
    INLINE_GRID
}


enum Overflow
{
    VISIBLE,
    HIDDEN,
    SCROLL,
    AUTO
}


struct Element
{
    ElementState elementState;
    Style        style;
    Computed     computed;
    Element*[]   childs;
    Element*     parent;


    void addChild( Element*  c ) nothrow
    {
        if ( c.parent !is null )
        {
            c.parent.removeChild( c );
        }

        c.parent = &this;
        childs ~= c;
    }


    void removeChild( Element*  c ) nothrow
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
        Writefln( "MouseClick()" );
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
                break;                
            }
            default:
        }

        // To Childs
        foreach( c; childs )
        {
            c.Event( hwnd, message, wParam, lParam );
        }

        return 0;
    }
}


