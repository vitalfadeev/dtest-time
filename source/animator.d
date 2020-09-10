import core.sys.windows.windows;
import core.time  : Duration;
import core.time  : MonoTime;
import core.time  : dur;
import std.format : format;
import std.traits : Fields, FieldNameTuple, hasMember;
import element    : Style;
import element    : Computed;
import element    : Element;
import element    : COLOR;
import app        : curTime;
import std.stdio  : writefln;
import std.conv   : to;
import tools      : odd;
import computer   : Computer;


struct KeyFrame
{
    uint     timeOffset;
    Style    style;
    Computed computed;

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
    Style* fromStyle;
    Style* toStyle;

    FindProps( element, fromKeyFrame, toKeyFrame, &fromStyle, &toStyle );

    //
    if ( toKeyFrame is null )
    {
        toKeyFrame = fromKeyFrame;
    }

    //
    if ( fromKeyFrame && toKeyFrame )
    {
        uint frameT = FindFrameT( t, fromKeyFrame, toKeyFrame );

        writefln( "%%          : 100 * t / to = 100 * %s / %s = %s%%", t, toKeyFrame.timeOffset, frameT );

        //
        AnimateElementProperties( element, fromKeyFrame, toKeyFrame, fromStyle, toStyle, frameT, timingFunc );
    }
}


pragma( inline )
void FindProps( Element* element, KeyFrame* fromKeyFrame, KeyFrame* toKeyFrame, Style** fromStyle, Style** toStyle )
{
    if ( fromKeyFrame )
    {
        writefln( "from       : %s", *fromKeyFrame );
        *fromStyle = &fromKeyFrame.style;
    }
    else
    {
        writefln( "from       : %s", fromKeyFrame ); // null
        *fromStyle = &element.style;
    }

    if ( toKeyFrame )
    {
        writefln( "to         : %s", *toKeyFrame );
        *toStyle = &toKeyFrame.style;
    }
    else  // toKeyFrame == null
    {
        writefln( "to         : %s", toKeyFrame ); // null
        *toStyle = *fromStyle;

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
            writefln( "iterations : %s", iterations );
            t = ( 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            writefln( "t          : %s", t );
        }
        else
        if ( aDirection == AnimationDirection.REVERSE )
        {
            iterations = 0;
            writefln( "iterations : %s", iterations );
            t = ( 100 - 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 100 .. 0
            writefln( "t          : %s", t );
        }
        if ( aDirection == AnimationDirection.ALTERNATE )
        {
            iterations = 0;
            writefln( "iterations : %s", iterations );
            t = ( 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            writefln( "t          : %s", t );
        }
        else
        if ( aDirection == AnimationDirection.ALTERNATE_REVERSE )
        {
            iterations = 0;
            writefln( "iterations : %s", iterations );
            t = ( 100 - 100 * aNowLength.total!"msecs" / aDuration.total!"msecs" ).to!uint; // 0 .. 100
            writefln( "t          : %s", t );
        }

    }
    else 
    if ( aNowLength > aDuration ) // 101: 0 .. 100 | 100 .. ~
    {
        iterations = aNowLength.total!"msecs" / aDuration.total!"msecs"; // integer
        writefln( "iterations : %s", iterations );

        if ( aDirection == AnimationDirection.NORMAL )
        {
            // forward
            auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
            t = ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 0 .. 100

            writefln( "t          : %s", t );
        }
        else
        if ( aDirection == AnimationDirection.REVERSE )
        {
            auto cleanNowLength = aNowLength.total!"msecs" - iterations * aDuration.total!"msecs";
            t = 100 - ( 100 * cleanNowLength / aDuration.total!"msecs" ).to!uint; // 100 .. 0

            writefln( "t          : %s", t );
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

            writefln( "t          : %s", t );
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

            writefln( "t          : %s", t );
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
    Element*   element,
    KeyFrame*  fromKeyFrame, 
    KeyFrame*  toKeyFrame,
    Style*     fromStyle,    
    Style*     toStyle,
    uint       frameT,
    TimingFunc timingFunc
    )
{
    static foreach( pName; FieldNameTuple!Style )
    {
        static if ( isAnimatable!( Computed, pName ) )
        {
            if ( ( __traits( getMember, toStyle, pName ).modified ) )
            {
                Computer().ComputeOneProperty!pName( element, fromStyle, &fromKeyFrame.computed );
                Computer().ComputeOneProperty!pName( element, toStyle  , &toKeyFrame.computed );

                auto a = __traits( getMember, &fromKeyFrame.computed, pName );
                auto b = __traits( getMember, &toKeyFrame.computed, pName );

                //
                auto x = Animate( frameT, a, b, timingFunc );
                writefln( "Anim %s  : frameT ( a, b ) = %s%% ( %s, %s ) = %s", pName, frameT, a, b, x );

                //
                mixin(
                    format!
                        q{
                            element.style.%s = x;
                        }
                        ( pName )
                );
                Computer().ComputeOneProperty!pName( element, &element.style, &element.computed );
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
        writefln( "Result     : %s x = ( a + ( b - a ) * t / 100 ) = ( %s + ( %s - %s ) * %s / 100 )", T.stringof, a, b, a, t );
        return ( a + ( b - a ) * t / 100 ).to!T;
    }
    else
    if ( a > b )
    {
        writefln( "Result     : %s x = ( a - ( a - b ) * t / 100 ) = ( %s - ( %s - %s ) * %s / 100 )", T.stringof, a, a, b, t );
        return ( a - ( a - b ) * t / 100 ).to!T;
    }
    else // a == b
    {
        writefln( "Result     : %s x = ( b ) = ( %s )", T.stringof, b );
        return b;
    }
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
