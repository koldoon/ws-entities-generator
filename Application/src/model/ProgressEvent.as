package model
{
    import flash.events.Event;

    public class ProgressEvent extends Event
    {
        public static const PROGRESS_MESSAGE:String = "progressMessage";

        public var message:String = "";

        public function ProgressEvent(type:String, message:String, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
            this.message = message;
        }
    }
}
