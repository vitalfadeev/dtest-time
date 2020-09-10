import core.sys.windows.windows;
import std.conv : to;
import std.stdio : writeln;
import std.stdio : writefln;


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
        writefln( a );
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


pragma( inline )
bool odd(T)(T n) { return n & 1; }


pragma( inline )
bool even(T)(T n) { return !( n & 1 ); }


int max( int a, int b ) nothrow
{
    return ( a > b ) ? a : b;
}


int GET_X_LPARAM( LPARAM lp ) nothrow
{
    return cast( int ) cast( short )LOWORD( lp );
}


int GET_Y_LPARAM( LPARAM lp ) nothrow
{
    return cast( int ) cast( short )HIWORD( lp );
}


