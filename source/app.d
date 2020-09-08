import std.stdio;
import core.time    : Duration;
import core.time    : MonoTime;
import std.datetime : dur;
import std.conv     : to;
import std.format   : format;
import std.traits   : FieldNameTuple;
import uno_window   : CreateWindowUno;
import element      : Element;
import element      : Style;
import animator     : KeyFrame;
import animator     : Animation;
import animator     : AnimationDirection;
import animator     : AnimationFillMode;
import animator     : AnimationPlayState;
import animator     : AnimationTimingFunction;
import animator     : AnimationTimingFunctionArgsStepsDirection;


T CR( T )()
{
    T obj;

    return obj;
}


T* CR( T: KeyFrame )( uint timeOffset, void function ( Style* style ) initFunc )
{
    T* obj = new T;
    obj.timeOffset = timeOffset;
    initFunc( &obj.style );

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
        writefln( "timingFunc : timingFunc( %s ) = %s", t, t );
        return t; // 0 .. 100
    };

    animation.keyFrames ~= 
        CR!KeyFrame(
            0,  
            ( Style* style ) { 
                style.left = 0;
            }
        );
    //animation.keyFrames ~= 
    //    CR!KeyFrame(
    //        25,  
    //        ( Style* style ) { 
    //            style.left = 25;
    //        }
    //    );    
    //animation.keyFrames ~= 
    //    CR!KeyFrame(
    //        50,  
    //        ( Style* style ) { 
    //            style.left = 50;
    //        }
    //    );    
    animation.keyFrames ~= 
        CR!KeyFrame(
            100,  
            ( Style* style ) { 
                style.left = 100;
            }
        ); 


    //
    import uno_window;

    unoWindow = CreateWindowUno();

    MainLoop();
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

