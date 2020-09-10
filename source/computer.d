import std.traits    : Fields, FieldNameTuple, hasMember;
import std.string    : isNumeric;
import std.format    : format;
import element       : Element;
import element       : Style;
import element       : Computed;
import value         : ValueType;
import tools         : To;
import tools         : Writefln;
import element       : DisplayOutside;
import element       : DisplayInside;
import element       : WidthMode;
import element       : HeightMode;
import std.algorithm : endsWith;


struct Computer
{
    Element*  element;
    Style*    style;
    Computed* computed;
    Element*  parent;


    void ComputeTree( Element* element ) nothrow
    {
        Computer().Compute( element );
        Computer().ComputeChilds( element );
    }


    void ComputeChilds( Element* element ) nothrow
    {
        foreach( c; element.childs )
        {
            ComputeTree( c );
        }
    }


    void Compute( Element* element ) nothrow
    {
        this.element  = element;
        this.style    = &element.style;
        this.computed = &element.computed;
        this.parent   = element.parent;

        static foreach ( pName; FieldNameTuple!Style )
        {
            static if ( hasMember!( Computer, format!"Compute_%s"( pName ) ) )
                mixin( 
                    CallComputeProperty!pName
                );
        }
    }


    void ComputeOneProperty( alias pName )( Element* element, Style* style, Computed* computed ) 
    {
        this.element   = element;
        this.style    = style;
        this.computed = computed;
        this.parent   = element.parent;

        static if ( hasMember!( Computer, format!"Compute_%s"( pName ) ) )
        {
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


    void Compute_left   () nothrow { Compute_Property!( "left"  , Compute_Number, Compute_Inherit ); }
    void Compute_top    () nothrow { Compute_Property!( "top"   , Compute_Number, Compute_Inherit ); }
    void Compute_right  () nothrow { Compute_Property!( "right" , Compute_Number, Compute_Inherit ); }
    void Compute_bottom () nothrow { Compute_Property!( "bottom", Compute_Number, Compute_Inherit ); }
    
    void Compute_marginLeft   () nothrow { Compute_Property!( "marginLeft"  , Compute_Number, Compute_Inherit ); }
    void Compute_marginTop    () nothrow { Compute_Property!( "marginTop"   , Compute_Number, Compute_Inherit ); }
    void Compute_marginRight  () nothrow { Compute_Property!( "marginRight" , Compute_Number, Compute_Inherit ); }
    void Compute_marginBottom () nothrow { Compute_Property!( "marginBottom", Compute_Number, Compute_Inherit ); }
    
    void Compute_paddingLeft   () nothrow { Compute_Property!( "paddingLeft"  , Compute_Number, Compute_Inherit ); }
    void Compute_paddingTop    () nothrow { Compute_Property!( "paddingTop"   , Compute_Number, Compute_Inherit ); }
    void Compute_paddingRight  () nothrow { Compute_Property!( "paddingRight" , Compute_Number, Compute_Inherit ); }
    void Compute_paddingBottom () nothrow { Compute_Property!( "paddingBottom", Compute_Number, Compute_Inherit ); }
    
    void Compute_borderLeftWidth   () nothrow { Compute_Property!( "borderLeftWidth"  , Compute_Number, Compute_Inherit ); }
    void Compute_borderTopWidth    () nothrow { Compute_Property!( "borderTopWidth"   , Compute_Number, Compute_Inherit ); }
    void Compute_borderRightWidth  () nothrow { Compute_Property!( "borderRightWidth" , Compute_Number, Compute_Inherit ); }
    void Compute_borderBottomWidth () nothrow { Compute_Property!( "borderBottomWidth", Compute_Number, Compute_Inherit ); }
    

    void Compute_width() nothrow
    {
        if ( style.width.type == ValueType.STRING )
        {
            if ( style.width.valueString == "auto" )
            {
                computed.widthMode = WidthMode.AUTO;
                return;
            }
            else
            if ( style.width.valueString == "min-content" )
            {
                computed.widthMode = WidthMode.MIN_CONTENT;
                return;
            }
            else
            if ( style.width.valueString == "max-content" )
            {
                computed.widthMode = WidthMode.MAX_CONTENT;
                return;
            }
            else
            if ( style.width.valueString == "fit-content" )
            {
                computed.widthMode = WidthMode.FIT_CONTENT;
                return;
            }
            else
            if ( style.width.valueString.length > 2 && style.width.valueString[ $-1 ] ==  '%' && style.width.valueString[ 0 .. $-2 ].isNumeric )
            {
                computed.widthMode = WidthMode.PERCENTAGE;
                computed.width     = style.width.valueString[ 0 .. $-2 ].To!( typeof( computed.width ) );
                return;
            }
            else
            if ( style.width.valueString.length > 3 && style.width.valueString.endsWith( "px" ) && style.width.valueString[ 0 .. $-3 ].isNumeric )
            {
                computed.widthMode = WidthMode.LENGTH; // px
                computed.width     = style.width.valueString[ 0 .. $-3 ].To!( typeof( computed.width ) );
                return;
            }
            else
            if ( style.width.valueString.length && style.width.valueString.isNumeric )
            {
                computed.widthMode = WidthMode.LENGTH;
                computed.width     = style.width.valueString.To!( typeof( computed.width ) ); // px
                return;
            }
            if ( style.width.valueString == "inherit" )
            {
                if ( parent )
                {
                    computed.widthMode = parent.computed.widthMode;
                    computed.width = parent.computed.width;
                    return;
                }
                return;
            }
        }

        if ( style.width.type == ValueType.INT )
        {
            computed.widthMode = WidthMode.LENGTH;
            computed.width     = style.width.valueInt; // px
            return;
        }

        StyleValueErrorMessage!( "width" );
    }


    void Compute_height() nothrow
    {
        if ( style.height.type == ValueType.STRING )
        {
            if ( style.height.valueString == "auto" )
            {
                computed.heightMode = HeightMode.AUTO;
                return;
            }
            else
            if ( style.height.valueString.length > 2 && style.height.valueString[ $-1 ] ==  '%' && style.height.valueString[ 0 .. $-2 ].isNumeric )
            {
                computed.heightMode = HeightMode.PERCENTAGE;
                computed.height     = style.height.valueString[ 0 .. $-2 ].To!( typeof( computed.height ) );
                return;
            }
            else
            if ( style.height.valueString.length > 3 && style.height.valueString.endsWith( "px" ) && style.height.valueString[ 0 .. $-3 ].isNumeric )
            {
                computed.heightMode = HeightMode.LENGTH; // px
                computed.height     = style.height.valueString[ 0 .. $-3 ].To!( typeof( computed.height ) );
                return;
            }
            else
            if ( style.height.valueString.length && style.height.valueString.isNumeric )
            {
                computed.heightMode = HeightMode.LENGTH;
                computed.height     = style.height.valueString.To!( typeof( computed.height ) ); // px
                return;
            }
            if ( style.height.valueString == "inherit" )
            {
                if ( parent )
                {
                    computed.heightMode = parent.computed.heightMode;
                    computed.height = parent.computed.height;
                    return;
                }
                return;
            }
        }

        if ( style.height.type == ValueType.INT )
        {
            computed.heightMode = HeightMode.LENGTH;
            computed.height     = style.height.valueInt; // px
            return;
        }

        StyleValueErrorMessage!( "height" );
    }


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
                computed.displayOutside = DisplayOutside.INLINE;
                return;
            }
            else
            if ( style.display.valueString == "block" )
            {
                computed.displayOutside = DisplayOutside.BLOCK;
                return;
            }
            else
            if ( style.display.valueString == "inline-block" )
            {
                computed.displayOutside = DisplayOutside.INLINE;
                computed.displayInside  = DisplayInside.FLOW_ROOT;
                return;
            }
            if ( style.display.valueString == "inherit" )
            {
                if ( parent )
                {
                    computed.displayOutside = parent.computed.displayOutside;
                    computed.displayInside = parent.computed.displayInside;
                    return;
                }
                return;
            }
        }

        StyleValueErrorMessage!( "display" );
    }

    void Compute_lineHeight() nothrow { Compute_Property!( "lineHeight", Compute_Number, Compute_Inherit ); }
    void Compute_wrapLine  () nothrow { Compute_Property!( "wrapLine"  , Compute_Number, Compute_Inherit ); }


    void StyleValueErrorMessage( string pName )() nothrow
    {
        Writefln( "error: unsupported value for %s: %s", pName.stringof, __traits( getMember, style, pName ) );
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
                        else // No Parent
                        {
                            computed.%s = Computed.%s.init;
                            return;
                        }
                    }
                }
            }
            ( pName, pName, pName, pName, pName, pName );
}


