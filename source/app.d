import std.stdio;
import core.time         : Duration;
import core.time         : MonoTime;
import std.datetime      : dur;
import std.conv          : to;
import std.format        : format;
import std.traits        : FieldNameTuple;
import uno_window        : CreateWindowUno;


pragma( inline )
bool odd(T)(T n) { return n & 1; }

pragma( inline )
bool even(T)(T n) { return !( n & 1 ); }


alias uint COLORREF;


struct COLOR
{
    COLORREF valueNative;
}


struct Element
{
    StyleProperties style;
    Computed computed;
}


struct StyleProperties
{
    Value width;
}


struct Computed
{
    int width;
}


struct KeyFrame
{
    uint            timeOffset;
    StyleProperties props;
    Computed        computed;

    string toString()
    {
        return format!"KeyFrame( %s )"( timeOffset );
    }
}


alias uint function( uint t ) TimingFunc;


// animation-direction: normal|reverse|alternate|alternate-reverse|initial|inherit;
enum AnimationDirection
{
    NORMAL,
    REVERSE,
    ALTERNATE,
    ALTERNATE_REVERSE
}


enum AnimationFillMode
{
    FORWARDS,
    BACKWARDS,
    BOTH
}


enum AnimationPlayState
{
    PAUSED,
    RUNNING
}


enum AnimationTimingFunction
{
    LINEAR,
    EASE,
    EASE_IN,
    EASE_OUT,
    EASE_IN_OUT,
    STEP_START,
    STEP_END,
    STEPS,
    CUBIC_BEZIER
}


enum AnimationTimingFunctionArgsStepsDirection
{
    START,
    END
}


alias KeyFrame*[] KeyFrames;


struct Animation
{
    MonoTime                start;
    Duration                delay;
    AnimationDirection      animationDirection       = AnimationDirection.NORMAL;
    Duration                duration;
    AnimationFillMode       animationFillMode        = AnimationFillMode.FORWARDS;
    uint                    animationIterationCount  = 1;
    string                  animationName;
    AnimationPlayState      animationPlayState       = AnimationPlayState.RUNNING;
    AnimationTimingFunction animationTimingFunction  = AnimationTimingFunction.EASE;
    union AnimationTimingFunctionArgs
    {
        struct AnimationTimingFunctionArgsSteps
        {
            uint intervals;
            AnimationTimingFunctionArgsStepsDirection direction = AnimationTimingFunctionArgsStepsDirection.START;
        }
        struct AnimationTimingFunctionArgsCubicBezier
        {
            float a;
            float b;
            float c;
            float d;
        }
        AnimationTimingFunctionArgsSteps steps;
        AnimationTimingFunctionArgsSteps cubicBezier;
    };
    AnimationTimingFunctionArgs animationTimingFunctionArgs;
    TimingFunc              timingFunc;
    KeyFrames               keyFrames;
}


T CR( T )()
{
    T obj;

    return obj;
}


T* CR( T: KeyFrame )( uint timeOffset, void function ( StyleProperties* props ) initFunc )
{
    T* obj = new T;
    obj.timeOffset = timeOffset;
    initFunc( &obj.props );

    return obj;
}


static MonoTime curTime;
Element*        element;
Animation*      animation;


void Do()
{
    curTime = MonoTime.currTime();

    //
    element = new Element();

    element.style.width = 0;
    element.computed.width = 0;

    //
    animation = new Animation();

    animation.start                   = curTime;
    animation.delay                   = dur!"seconds"( 0 );
    animation.duration                = dur!"seconds"( 1 );
    animation.animationDirection      = AnimationDirection.NORMAL;
    animation.animationFillMode       = AnimationFillMode.FORWARDS;
    animation.animationIterationCount = 1;
    animation.animationName           = "example";
    animation.animationPlayState      = AnimationPlayState.RUNNING;
    animation.animationTimingFunction = AnimationTimingFunction.EASE;
    animation.animationTimingFunctionArgs.steps.intervals = 1;
    animation.animationTimingFunctionArgs.steps.direction = AnimationTimingFunctionArgsStepsDirection.START;

    animation.timingFunc = function( uint t ) {
        writefln( "timingFunc( %s ) = %s", t, t );
        return t; // 0 .. 100
    };

    animation.keyFrames ~= 
        CR!KeyFrame(
            0,  
            ( StyleProperties* props ) { 
                props.width = 0;
            }
        );
    //animation.keyFrames ~= 
    //    CR!KeyFrame(
    //        25,  
    //        ( StyleProperties* props ) { 
    //            props.width = 25;
    //        }
    //    );    
    //animation.keyFrames ~= 
    //    CR!KeyFrame(
    //        50,  
    //        ( StyleProperties* props ) { 
    //            props.width = 50;
    //        }
    //    );    
    animation.keyFrames ~= 
        CR!KeyFrame(
            100,  
            ( StyleProperties* props ) { 
                props.width = 100;
            }
        ); 


    //
    import uno_window;

    unoWindow = CreateWindowUno();

    MainLoop();
}


void AnimateElement( Element* element, Animation* animation )
{
    auto aDelay           = animation.delay;
    auto aStartTime       = animation.start;
    auto aDuration        = animation.duration;
    auto aDirection       = animation.animationDirection;
    TimingFunc timingFunc = animation.timingFunc;

    auto aNowLength = curTime - aStartTime;
    uint t;
    long iterations;

    writefln( "%s, %s", aNowLength, aDuration );

    //
    t = CalculateT( aNowLength, aDuration, aDirection, &iterations );

    //
    KeyFrame* fromKeyFrame;
    KeyFrame* toKeyFrame;

    FindKeyFrames( &animation.keyFrames, t.to!uint, &fromKeyFrame, &toKeyFrame );

    //
    StyleProperties* fromProps;
    StyleProperties* toProps;

    FindProps( element, fromKeyFrame, toKeyFrame, &fromProps, &toProps );

    //
    if ( toKeyFrame is null )
    {
        toKeyFrame = fromKeyFrame;
    }

    //
    if ( fromKeyFrame && toKeyFrame )
    {
        uint frameT = FindFrameT( t, fromKeyFrame, toKeyFrame );

        writefln( "100 * t / to = 100 * %s / %s = %s%%", t, toKeyFrame.timeOffset, frameT );

        //
        AnimateElementProperties( element, fromKeyFrame, toKeyFrame, fromProps, toProps, frameT, timingFunc );
    }
}


pragma( inline )
void FindProps( Element* element, KeyFrame* fromKeyFrame, KeyFrame* toKeyFrame, StyleProperties** fromProps, StyleProperties** toProps )
{
    if ( fromKeyFrame )
    {
        writefln( "from: %s", *fromKeyFrame );
        *fromProps = &fromKeyFrame.props;
    }
    else
    {
        writefln( "from: %s", fromKeyFrame ); // null
        *fromProps = &element.style;
    }

    if ( toKeyFrame )
    {
        writefln( "to: %s", *toKeyFrame );
        *toProps = &toKeyFrame.props;
    }
    else  // toKeyFrame == null
    {
        writefln( "to: %s", toKeyFrame ); // null
        *toProps = *fromProps;

        // Update Element and Stop Animation
        writefln( "Update Element and Stop Animation." );
    }    
}


pragma( inline )
uint CalculateT( Duration aNowLength, Duration aDuration, AnimationDirection aDirection, long* iterationsCount )
{
    long iterations;
    uint t;

    if ( aNowLength < aDuration ) // 0 .. 100
    {
        if ( aNowLength < dur!"msecs"( 0 ) )
        {
            aNowLength = dur!"msecs"( 0 );
        }

        if ( aDirection == AnimationDirection.NORMAL )
        {
            iterations = 0;
            writefln( "iterations: %s", iterations );
            t = ( 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            writefln( "t: %s", t );
        }
        else
        if ( aDirection == AnimationDirection.REVERSE )
        {
            iterations = 0;
            writefln( "iterations: %s", iterations );
            t = ( 100 - 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 100 .. 0
            writefln( "t: %s", t );
        }
        if ( aDirection == AnimationDirection.ALTERNATE )
        {
            iterations = 0;
            writefln( "iterations: %s", iterations );
            t = ( 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            writefln( "t: %s", t );
        }
        else
        if ( aDirection == AnimationDirection.ALTERNATE_REVERSE )
        {
            iterations = 0;
            writefln( "iterations: %s", iterations );
            t = ( 100 - 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            writefln( "t: %s", t );
        }

    }
    else 
    if ( aNowLength > aDuration ) // 101: 0 .. 100 | 100 .. ~
    {
        iterations = aNowLength.total!"msecs" / aDuration.total!"msecs"; // integer
        writefln( "iterations: %s", iterations );

        if ( aDirection == AnimationDirection.NORMAL )
        {
            // forward
            auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
            t = ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 0 .. 100

            writefln( "t: %s", t );
        }
        else
        if ( aDirection == AnimationDirection.REVERSE )
        {
            auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
            t = 100 - ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 100 .. 0

            writefln( "t: %s", t );
        }
        else
        if ( aDirection == AnimationDirection.ALTERNATE )
        {
            if ( odd( iterations ) )
            {
                // backward
                auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
                t = 100 - ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 100 .. 0
            }
            else
            {
                // forward
                auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
                t = ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            }

            writefln( "t: %s", t );
        }
        else
        if ( aDirection == AnimationDirection.ALTERNATE_REVERSE )
        {
            if ( odd( iterations ) )
            {
                // forward
                auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
                t = ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            }
            else
            {
                // backward
                auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
                t = 100 - ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 100 .. 0
            }

            writefln( "t: %s", t );
        }
        else
        {
            assert( 0, "unsupported" );
        }
    }
    else  // aNowLength == aDuration // 100
    {
        t = 100;
    }

    *iterationsCount = iterations;

    return t;    
}


pragma( inline )
void AnimateElementProperties( 
    Element* element, 
    KeyFrame* fromKeyFrame, KeyFrame* toKeyFrame, 
    StyleProperties* fromProps, StyleProperties* toProps ,
    uint frameT,
    TimingFunc timingFunc
    )
{
    static foreach( pName; FieldNameTuple!StyleProperties )
    {
        static if ( isAnimatable!( Computed, pName ) )
        {
            if ( ( __traits( getMember, toProps, pName ).modified ) )
            {
                Compute( element, &fromKeyFrame.computed, fromProps, pName );
                Compute( element, &toKeyFrame.computed, toProps, pName );

                auto a = __traits( getMember, &fromKeyFrame.computed, pName );
                auto b = __traits( getMember, &toKeyFrame.computed, pName );

                //
                auto x = Animate( frameT, a, b, timingFunc );
                writefln( "Animated %s: frameT ( a, b ) = %s%% ( %s, %s ) = %s", pName, frameT, a, b, x );

                //
                mixin(
                    format!
                        q{
                            element.style.%s = x;
                        }
                        ( pName )
                );
                Compute( element, &element.computed, &element.style, pName );
            }
        }
    }
}


pragma( inline )
void FindKeyFrames( KeyFrame*[]* subFrames, uint t, KeyFrame** fromKeyFrame, KeyFrame** toKeyFrame )
{
    KeyFrame* prev = null;

    foreach( sf; *subFrames )
    {
        if ( sf.timeOffset > t )
        {
            *fromKeyFrame = prev;
            *toKeyFrame = sf;
            return;
        }

        prev = sf;
    }

    *fromKeyFrame = prev;
    *toKeyFrame = null;
}


pragma( inline )
TIMETYPE FindFrameT( TIMETYPE )( TIMETYPE t, KeyFrame* fromKeyFrame, KeyFrame* toKeyFrame )
{
    TIMETYPE frameT; // 0 .. 100

    //
    if ( t == 100 )
    {
        frameT = 100;
    }
    else
    if ( fromKeyFrame && toKeyFrame )
    {
        auto posKeyFrame = t - fromKeyFrame.timeOffset;
        auto lengthKeyFrame = ( toKeyFrame.timeOffset - fromKeyFrame.timeOffset );
        frameT = 100 * posKeyFrame / lengthKeyFrame;
    }
    else
    if ( fromKeyFrame is null )
    {
        auto posKeyFrame = t;
        auto lengthKeyFrame = toKeyFrame.timeOffset;
        frameT = 100 * posKeyFrame / lengthKeyFrame;
    }
    else
    if ( toKeyFrame is null )
    {
        frameT = 100;
    }

    return frameT;
}


T Animate( TIMETYPE, T, FUNC )( TIMETYPE t, T a, T b, FUNC timingFunc )
{
    static if ( is( T == COLOR ) )
    {
        auto tEased = timingFunc( t );

        return 
            RGB(
                AnimateAB( tEased, a.r, b.r ),
                AnimateAB( tEased, a.g, b.g ),
                AnimateAB( tEased, a.b, b.b ),
                0
            );
    }
    else
    static if ( is( T == int ) )
    {
        auto tEased = timingFunc( t );
        return AnimateAB( tEased, a, b );
    }
    else
    static if ( is( T == uint ) )
    {
        auto tEased = timingFunc( t );
        return AnimateAB( tEased, a, b );
    }
    else
    {
        assert( 0, "unsupported value type: " ~ T.stringof );
    }
}


pragma( inline )
T AnimateAB( T )( uint t, T a, T b )
{
    if ( a < b )
    {
        writefln( "%s x = ( a + ( b - a ) * t / 100 ) = ( %s + ( %s - %s ) * %s / 100 )", T.stringof, a, b, a, t );
        return ( a + ( b - a ) * t / 100 ).to!T;
    }
    else
    if ( a > b )
    {
        writefln( "%s x = ( a - ( a - b ) * t / 100 ) = ( %s - ( %s - %s ) * %s / 100 )", T.stringof, a, a, b, t );
        return ( a - ( a - b ) * t / 100 ).to!T;
    }
    else // a == b
    {
        writefln( "%s x = ( b ) = ( %s )", T.stringof, b );
        return b;
    }
}


COLOR RGB( ubyte r, ubyte g, ubyte b )
{
    COLORREF valueNative = ( ( b << 16 ) | ( g << 8 ) | r ); // BGR

    return COLOR( valueNative );
}


bool isAnimatable( alias PROPS, alias PNAME )()
{
    mixin(
        format!
            q{
                return
                    is( typeof( PROPS.%s ) == uint ) ||
                    is( typeof( PROPS.%s ) == int ) ||
                    is( typeof( PROPS.%s ) == COLOR );
            }
            ( PNAME, PNAME, PNAME )
    );
}


enum ValueType
{
    UNDEFINED,
    INT,
    UINT,
    FLOAT,
    STRING,
    COLOR,
    ALIGN,
}


struct Value
{
    ValueType type = ValueType.UNDEFINED;
    union
    {
        int    valueInt;
        uint   valueUint;
        float  valueFloat;
        COLOR  valueColor;
        string valueString;
        ALIGN  valueAlign;
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
        static if ( is( T == COLOR ) )
        {
            type        = v.type;
            valueString = v.valueColor;
            modified    = false;
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
        static if ( is( T == COLOR ) )
        {
            type       = ValueType.COLOR;
            valueColor = v;
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
            case ValueType.COLOR     : return format!"COLOR( %s )"( valueColor );
            case ValueType.STRING    : return format!"STRING( %s )"( valueString );
            case ValueType.ALIGN     : return format!"ALIGN( %s )"( valueAlign );
        }
    }
}


enum ALIGN
{
    TOP,
    LEFT, 
    RIGHT, 
    CENTER, 
    JUSTIFY, 
    INITIAL, 
    INHERIT,  // --> cumputed.align
}


void Compute( Element* element, Computed* computed, StyleProperties* props, string pName )
{
    if ( pName == "width" )
    {
        Compute_width( computed, props );
    }
    else
    {
        assert( 0, "unsupported property: " ~ pName );
    }
}


void Compute_width( Computed* computed, StyleProperties* props )
{
    if ( props.width.type == ValueType.INT )
    {
        computed.width = props.width.valueInt;
        return;
    }

    assert( 0, "unsupported type: " ~ format!"%s"( props.width.type ) );
}


import core.sys.windows.windows;
import std.stdio;
import std.stdio : writeln;

// angle -> x , y
HWND unoWindow;


void MainLoop()
{
    MSG msg;
    RECT vrect;

    while ( GetMessage( &msg, NULL, 0, 0 ) )
    {
        TranslateMessage( &msg );
        DispatchMessage( &msg );
    }
}


void main()
{
    Do();
}
