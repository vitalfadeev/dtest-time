import core.sys.windows.windows;
import std.stdio : writefln;
import element   : Element;
import tools     : max;
import tools     : Writefln;
import element   : DisplayBox;
import element   : DisplayOutside;
import element   : DisplayInside;
import element   : WidthMode;
import element   : HeightMode;
import element   : BoxSizing;


struct Drawer
{
    void DrawTree( HDC hdc, Element* element, RECT* limits, POINT* gCursor, RECT* margin ) nothrow
    {
        // Root
        DrawRoot( hdc, element, limits, gCursor, margin );

        // Childs
        RECT childsLimits = 
            RECT( 
                limits.left   + element.computed.paddingLeft,
                limits.top    + element.computed.paddingTop,
                limits.right  - element.computed.paddingRight,
                limits.bottom - element.computed.paddingBottom
            );
        
        POINT childsGCursor = 
            POINT( 
                limits.left + element.computed.paddingLeft, 
                limits.top + element.computed.paddingTop 
            );
        
        RECT childsMargin = { 0, 0, 0, 0 };

        DrawChilds( hdc, element, &childsLimits, &childsGCursor, &childsMargin );
    }


    pragma( inline )
    void DrawRoot( HDC hdc, Element* element, RECT* limits, POINT* gCursor, RECT* margin ) nothrow
    {
        if ( element.computed.displayBox == DisplayBox.CONTENTS )
        {
            // Display
            final switch ( element.computed.displayOutside )
            {
                case DisplayOutside.INLINE   : DisplayOutside_Inline( element, limits, gCursor, margin ); break;
                case DisplayOutside.BLOCK    : DisplayOutside_Block ( element, limits, gCursor, margin ); break;
                case DisplayOutside.RUN_IN   : break;
            }

            // Element Margin
            auto hpenMargin = CreatePen( PS_DOT, 1, RGB( 0, 0, 0 ) );
            auto bgMargin   = RGB( 0xf7, 0xca, 0x9c );
            auto hbrMargin  = CreateSolidBrush( bgMargin );
            RECT mRect = 
                ( element.computed.boxSizing == BoxSizing.CONTENT_BOX ) ?
                    RECT(
                        element.computed.rect.left   - element.computed.borderLeftWidth  - element.computed.paddingLeft    - element.computed.margin.left,
                        element.computed.rect.top    - element.computed.borderTopWidth   - element.computed.paddingTop     - element.computed.margin.top,
                        element.computed.rect.right  + element.computed.borderRightWidth  + element.computed.paddingRight  + element.computed.margin.right,
                        element.computed.rect.bottom + element.computed.borderBottomWidth + element.computed.paddingBottom + element.computed.margin.bottom
                    ) 
                    : // BORDER_BOX
                    RECT(
                        element.computed.rect.left   - element.computed.margin.left,
                        element.computed.rect.top    - element.computed.margin.top,
                        element.computed.rect.right  + element.computed.margin.right,
                        element.computed.rect.bottom + element.computed.margin.bottom
                    );
            FillRect( hdc, &mRect, hbrMargin ); 
            DeleteObject( hbrMargin ); 
            //Rectangle( hdc, element.computed.left, element.computed.top, element.computed.right, element.computed.bottom );

            // Element Border
            auto hpenBorder = CreatePen( PS_SOLID, 1, RGB( 0, 0, 0 ) );
            auto bgBorder   = RGB( 0xfd, 0xdc, 0x9a );
            auto hbrBorder  = CreateSolidBrush( bgBorder );
            RECT bRect = 
                ( element.computed.boxSizing == BoxSizing.CONTENT_BOX ) ?
                    RECT(
                        element.computed.rect.left   - element.computed.borderLeftWidth   - element.computed.paddingLeft,
                        element.computed.rect.top    - element.computed.borderTopWidth    - element.computed.paddingTop,
                        element.computed.rect.right  + element.computed.borderRightWidth  + element.computed.paddingRight,
                        element.computed.rect.bottom + element.computed.borderBottomWidth + element.computed.paddingBottom
                    ) 
                    : // BORDER_BOX
                    RECT(
                        element.computed.rect.left   ,
                        element.computed.rect.top    ,
                        element.computed.rect.right  ,
                        element.computed.rect.bottom
                    );
            FillRect( hdc, &bRect, hbrBorder ); 
            DeleteObject( hbrBorder ); 
            //Rectangle( hdc, element.computed.left, element.computed.top, element.computed.right, element.computed.bottom );

            // Element Padding
            auto hpenPadding = CreatePen( PS_SOLID, 1, RGB( 0, 0, 0 ) );
            auto bgPadding   = RGB( 0xc2, 0xce, 0x89 );
            auto hbrPadding  = CreateSolidBrush( bgPadding );
            RECT pRect = 
                ( element.computed.boxSizing == BoxSizing.CONTENT_BOX ) ?
                    RECT(
                        element.computed.rect.left   - element.computed.paddingLeft,
                        element.computed.rect.top    - element.computed.paddingTop,
                        element.computed.rect.right  + element.computed.paddingRight,
                        element.computed.rect.bottom + element.computed.paddingBottom
                    ) 
                    : // BORDER_BOX
                    RECT(
                        element.computed.rect.left   + element.computed.borderWidth.left,
                        element.computed.rect.top    + element.computed.borderWidth.top,
                        element.computed.rect.right  - element.computed.borderWidth.right,
                        element.computed.rect.bottom - element.computed.borderWidth.bottom
                    );
            FillRect( hdc, &pRect, hbrPadding ); 
            DeleteObject( hbrPadding ); 
            //Rectangle( hdc, element.computed.left, element.computed.top, element.computed.right, element.computed.bottom );

            // Element Content
            auto hpenContent = CreatePen( PS_SOLID, 1, RGB( 0, 0, 0 ) );
            auto bgContent = RGB( 0x8b, 0xb4, 0xc0 ); 
            auto hbrContent = CreateSolidBrush( bgContent ); 
            RECT cRect = 
                ( element.computed.boxSizing == BoxSizing.CONTENT_BOX ) ?
                    RECT(
                        element.computed.rect.left  ,
                        element.computed.rect.top   ,
                        element.computed.rect.right ,
                        element.computed.rect.bottom
                    ) 
                    : // BORDER_BOX
                    RECT(
                        element.computed.rect.left   + element.computed.borderWidth.left   + element.computed.padding.left,
                        element.computed.rect.top    + element.computed.borderWidth.top    + element.computed.padding.top,
                        element.computed.rect.right  - element.computed.borderWidth.right  - element.computed.padding.right,
                        element.computed.rect.bottom - element.computed.borderWidth.bottom - element.computed.padding.bottom
                    );
            FillRect( hdc, &cRect, hbrContent ); 
            DeleteObject( hbrContent ); 
            //Rectangle( hdc, element.computed.left, element.computed.top, element.computed.right, element.computed.bottom );

            Writefln( "Draw() : %s,%s %sx%s", element.computed.left, element.computed.top, element.computed.right, element.computed.bottom );
        }
    }


    pragma( inline )
    void GetWidth( Element* element, RECT* limits, int* width ) nothrow
    {
        final switch ( element.computed.displayOutside )
        {
            case DisplayOutside.INLINE   : GetWidthInline( element, limits, width ); break;
            case DisplayOutside.BLOCK    : GetWidthBlock( element, limits, width ); break;
            case DisplayOutside.RUN_IN   : break;
        }
    }


    pragma( inline )
    void GetHeight( Element* element, RECT* limits, int* height ) nothrow
    {
        final switch ( element.computed.displayOutside )
        {
            case DisplayOutside.INLINE   : GetHeightInline( element, limits, height ); break;
            case DisplayOutside.BLOCK    : GetHeightBlock( element, limits, height ); break;
            case DisplayOutside.RUN_IN   : break;
        }
    }


    pragma( inline )
    void GetWidthInline( Element* element, RECT* limits, int* width ) nothrow
    {
        final switch ( element.computed.displayInside )
        {
            case DisplayInside.FLOW      : GetWidthInlineFlow( element, limits, width ); break;
            case DisplayInside.FLOW_ROOT : GetWidthInlineFlowRoot( element, limits, width ); break;
            case DisplayInside.TABLE     : GetWidthInlineTable( element, limits, width ); break;
            case DisplayInside.FLEX      : GetWidthInlineFlex( element, limits, width ); break;
            case DisplayInside.GRID      : GetWidthInlineGrid( element, limits, width ); break;
            case DisplayInside.RUBY      : GetWidthInlineRuby( element, limits, width ); break;
        }
    }


    pragma( inline )
    void GetHeightInline( Element* element, RECT* limits, int* height ) nothrow
    {
        final switch ( element.computed.boxSizing )
        {
            case BoxSizing.CONTENT_BOX:
                *height = 
                    element.computed.paddingTop + 
                    element.computed.borderTopWidth + 
                    10 + 
                    element.computed.borderBottomWidth + 
                    element.computed.borderTopWidth;
                break;

            case BoxSizing.BORDER_BOX:
                *height = 10;
                break;
        }
    }


    pragma( inline )
    void GetWidthInlineFlow( Element* element, RECT* limits, int* width ) nothrow
    {
        Writefln( "GetWidthInlineFlow(): widthMode : %s", element.computed.widthMode );
        CalculateWidthAuto( element, limits, width );
    }


    pragma( inline )
    void GetWidthInlineFlowRoot( Element* element, RECT* limits, int* width ) nothrow
    {
        Writefln( "GetWidthInlineFlowRoot(): widthMode : %s", element.computed.widthMode );
        final switch ( element.computed.widthMode )
        {
            case WidthMode.AUTO        : CalculateWidthAuto( element, limits, width ); break;
            case WidthMode.LENGTH      : *width = element.computed.width; break;
            case WidthMode.PERCENTAGE  : break;
            case WidthMode.MIN_CONTENT : break;
            case WidthMode.MAX_CONTENT : break;
            case WidthMode.FIT_CONTENT : break;
        }        
    }


    pragma( inline )
    void GetWidthInlineTable( Element* element, RECT* limits, int* width ) nothrow
    {
        assert( 0, "unsupported" );
    }


    pragma( inline )
    void GetWidthInlineFlex( Element* element, RECT* limits, int* width ) nothrow
    {
        assert( 0, "unsupported" );
    }


    pragma( inline )
    void GetWidthInlineGrid( Element* element, RECT* limits, int* width ) nothrow
    {
        assert( 0, "unsupported" );
    }


    pragma( inline )
    void GetWidthInlineRuby( Element* element, RECT* limits, int* width ) nothrow
    {
        assert( 0, "unsupported" );
    }


    pragma( inline )
    void GetWidthBlock( Element* element, RECT* limits, int* width ) nothrow
    {
        Writefln( "GetWidthBlock(): widthMode : %s", element.computed.widthMode );
        final switch ( element.computed.widthMode )
        {
            case WidthMode.AUTO        : CalculateWidthAuto( element, limits, width ); break;
            case WidthMode.LENGTH      : *width = element.computed.width; break;
            case WidthMode.PERCENTAGE  : break;
            case WidthMode.MIN_CONTENT : break;
            case WidthMode.MAX_CONTENT : break;
            case WidthMode.FIT_CONTENT : break;
        }        
    }


    pragma( inline )
    void GetHeightBlock( Element* element, RECT* limits, int* height ) nothrow
    {
        Writefln( "GetHeightBlock(): heightMode : %s", element.computed.heightMode );
        final switch ( element.computed.heightMode )
        {
            case HeightMode.AUTO        : CalculateHeightAuto( element, limits, height ); break;
            case HeightMode.LENGTH      : *height = element.computed.height; break;
            case HeightMode.PERCENTAGE  : break;
            case HeightMode.MIN_CONTENT : break;
            case HeightMode.MAX_CONTENT : break;
            case HeightMode.FIT_CONTENT : break;
        }        
    }


    pragma( inline )
    void CalculateWidthAuto( Element* element, RECT* limits, int* width ) nothrow
    {
        int totalWidth;
        int childWidth;
        int widthMax;
        RECT margin;

        //
        foreach( c; element.childs )
        {
            final switch ( c.computed.displayOutside )
            {
                case DisplayOutside.INLINE: 
                    
                    GetWidth( c, limits, &childWidth ); 

                    if ( c.computed.boxSizing == BoxSizing.CONTENT_BOX )
                    {
                        AddPaddingToWidth( c, &childWidth );
                        AddBorderToWidth( c, &childWidth );
                    }

                    AddMarginToWidth( c, &margin, &childWidth );
                    
                    totalWidth += childWidth; 
                    
                    if ( totalWidth > widthMax )
                    {
                        widthMax = totalWidth;
                    }

                    margin = c.computed.margin;
                    
                    break;

                case DisplayOutside.BLOCK: 

                    totalWidth = 0;
                    
                    GetWidth( c, limits, &childWidth ); 
                    
                    if ( c.computed.boxSizing == BoxSizing.CONTENT_BOX )
                    {
                        AddPaddingToWidth( c, &childWidth );
                        AddBorderToWidth( c, &childWidth );
                    }
                    
                    margin = RECT( 0, 0, 0, 0 );

                    AddMarginToWidth( c, &margin, &childWidth );

                    totalWidth += childWidth; 

                    if ( totalWidth > widthMax )
                    {
                        widthMax = totalWidth;
                    }
                    
                    break;

                case DisplayOutside.RUN_IN: 
                    break;
            }
        }

        //


        //
        auto boxWidth = limits.right - limits.left;

        if ( widthMax > boxWidth )
        {
            widthMax = boxWidth;
        }

        //
        *width = widthMax;
    }


    pragma( inline )
    void CalculateHeightAuto( Element* element, RECT* limits, int* height ) nothrow
    {
        int totalHeight;
        int childHeight;
        int heightMax;
        RECT margin;

        //
        foreach( c; element.childs )
        {
            final switch ( c.computed.displayOutside )
            {
                case DisplayOutside.INLINE: 
                    break;

                case DisplayOutside.BLOCK:
                    totalHeight += c.computed.height;
                    break;

                case DisplayOutside.RUN_IN: 
                    break;
            }
        }

        //
        auto boxHeight = limits.right - limits.left;

        if ( heightMax > boxHeight )
        {
            heightMax = boxHeight;
        }

        //
        *height = heightMax;
    }


    pragma( inline )
    void AddPaddingToWidth( Element* element, int* childWidth ) nothrow
    {
        *childWidth = *childWidth + element.computed.paddingLeft + element.computed.paddingRight;
    }


    pragma( inline )
    void AddBorderToWidth( Element* element, int* childWidth ) nothrow
    {
        *childWidth = *childWidth + element.computed.borderLeftWidth + element.computed.borderRightWidth;
    }


    pragma( inline )
    void AddMarginToWidth( Element* element, RECT* margin, int* childWidth ) nothrow
    {
        *childWidth = *childWidth + max( margin.right, element.computed.marginLeft );
    }


    pragma( inline )
    void DrawChilds( HDC hdc, Element* element, RECT* limits, POINT* gCursor, RECT* margin ) nothrow
    {
        final switch ( element.computed.displayInside )
        {
            case DisplayInside.FLOW      : DisplayChilds_Flow( hdc, element, limits, gCursor, margin ); break;
            case DisplayInside.FLOW_ROOT : break;
            case DisplayInside.TABLE     : break;
            case DisplayInside.FLEX      : DisplayChilds_Flex( hdc, element, limits, gCursor, margin ); break;
            case DisplayInside.GRID      : break;
            case DisplayInside.RUBY      : break;
        }
    }


    pragma( inline )
    void DisplayChilds_Flow( HDC hdc, Element* element, RECT* limits, POINT* gCursor, RECT* margin ) nothrow
    {
        foreach( c; element.childs ) 
        {
            DrawTree( hdc, c, limits, gCursor, margin );
        }
    }


    pragma( inline )
    void DisplayChilds_Flex( HDC hdc, Element* element, RECT* limits, POINT* gCursor, RECT* margin ) nothrow
    {
        foreach( c; element.childs ) 
        {
            DrawTree( hdc, c, limits, gCursor, margin );
        }
    }


    pragma( inline )
    void PutElement( Element* element, int left, int top, POINT* gCursor, RECT* margin ) nothrow
    {
        auto width  = element.computed.rect.right - element.computed.rect.left;
        auto height = element.computed.rect.bottom - element.computed.rect.top;

        element.computed.rect.left   = left;
        element.computed.rect.top    = top;
        element.computed.rect.right  = left + width;
        element.computed.rect.bottom = top + height;

        gCursor.x = element.computed.rect.right;
        gCursor.y = element.computed.rect.top;

        *margin = element.computed.margin;
    }


    pragma( inline )
    void DisplayOutside_Inline( Element* element, RECT* limits, POINT* gCursor, RECT* margin ) nothrow
    {
        int elementWidth;
        int elementHeight;

        // Box Width
        GetWidth( element, limits, &elementWidth );
        element.computed.right = element.computed.left + elementWidth;

        // Box Height
        GetHeight( element, limits, &elementHeight );
        element.computed.bottom = element.computed.top + elementHeight;

        // Wrap
        if ( limits.left + gCursor.x + elementWidth > limits.right )
        { 
            PutElement( 
                element, 
                limits.left + element.computed.marginLeft, 
                gCursor.y + element.computed.lineHeight, 
                gCursor,
                margin
            );
        }
        else // No-Wrap
        {
            PutElement( 
                element, 
                gCursor.x + max( margin.right, element.computed.marginLeft ), 
                gCursor.y, 
                gCursor,
                margin
            );
        }
    }


    pragma( inline )
    void DisplayOutside_Block( Element* element, RECT* limits, POINT* gCursor, RECT* margin ) nothrow
    {
        auto height = element.computed.bottom - element.computed.top;

        PutElement( 
            element, 
            limits.left, 
            gCursor.y + height,
            gCursor,
            margin
        );
    }
}

