package model
{
    import flash.events.Event;

    public class JavaTypesParserEvent extends Event
    {
        public static const TYPE_FOUND:String = "typeFound";

        public var typeName:String;
        public var typePackage:String;

        public function JavaTypesParserEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
        }
    }
}
