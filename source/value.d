import std.format : format;


enum ValueType
{
    UNDEFINED,
    INT,
    UINT,
    FLOAT,
    STRING,
}


struct Value
{
    ValueType type = ValueType.UNDEFINED;
    union
    {
        int    valueInt;
        uint   valueUint;
        float  valueFloat;
        string valueString;
    }
    bool modified;


    this( T )( T v )
    {
        static if ( is( T == string ) )
        {
            type        = ValueType.STRING;
            valueString = v;
            modified    = false;
        }
        else
        static if ( is( T == int ) )
        {
            type     = ValueType.INT;
            valueInt = v;
            modified = false;
        }
        else
        static if ( is( T == float ) )
        {
            type       = ValueType.FLOAT;
            valueFloat = v;
            modified   = false;
        }
        else
        static if ( is( T == double ) )
        {
            type       = ValueType.FLOAT;
            valueFloat = v;
            modified   = false;
        }
        else
        static if ( is( T == Value ) )
        {
            type        = v.type;
            valueString = v.valueString;
            modified    = false;
        }
        else
            assert( 0, "unsupported type: " ~ T.stringof  );
    }

    //void opAssign( string v )
    //{
    //    type = ValueType.STRING;
    //    valueString = v;
    //    modified = true;
    //}


    //void opAssign( int v )
    //{
    //    type = ValueType.INT;
    //    valueInt = v;
    //    modified = true;
    //}


    //void opAssign( float v )
    //{
    //    type = ValueType.FLOAT;
    //    valueFloat = v;
    //    modified = true;
    //}


    void opAssign( T )( T v )
    {
        static if ( is( T == string ) )
        {
            type        = ValueType.STRING;
            valueString = v;
            modified    = true;
        }
        else
        static if ( is( T == int ) )
        {
            type     = ValueType.INT;
            valueInt = v;
            modified = true;
        }
        else
        static if ( is( T == uint ) )
        {
            type     = ValueType.UINT;
            valueUint = v;
            modified = true;
        }
        else
        static if ( is( T == float ) )
        {
            type       = ValueType.FLOAT;
            valueFloat = v;
            modified   = true;
        }
        else
        static if ( is( T == double ) )
        {
            type       = ValueType.FLOAT;
            valueFloat = v;
            modified   = true;
        }
        else
        static if ( is( T == Value ) )
        {
            type        = v.type;
            valueString = v.valueString;
            modified    = true;
        }
        else
            assert( 0, "unsupported type: " ~ T.stringof  );
    }


    string toString()
    {
        final switch ( type )
        {
            case ValueType.UNDEFINED : return "UNDEFINED";
            case ValueType.INT       : return format!"INT( %x )"( valueInt );
            case ValueType.UINT      : return format!"UINT( %x )"( valueUint );
            case ValueType.FLOAT     : return format!"FLOAT( %f )"( valueFloat );
            case ValueType.STRING    : return format!"STRING( %s )"( valueString );
        }
    }
}

