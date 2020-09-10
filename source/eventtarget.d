enum EventType
{
    //
}


struct EventListener 
{
    void handleEvent( Event* event )
    {
        //
    }
}


struct EventTarget
{
    void addEventListener( EventType type, EventListener* listener, bool capture, bool passive, bool useCapture )
    {
        //
    }


    void removeEventListener( EventType type, EventListener* listener, bool capture, bool passive, bool useCapture )
    {
        //
    }


    void dispatchEvent( Event* event )
    {
        //
    }
}

