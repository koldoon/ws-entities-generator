package ru.koldoon.model
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    import mx.controls.Alert;

    import ru.koldoon.tools.notEmpty;

    [Event(name="complete", type="flash.events.Event")]

    public class WSDLLoader extends EventDispatcher
    {
        public static const XSDNS:Namespace = new Namespace("http://www.w3.org/2001/XMLSchema");
        public static const WSDLNS:Namespace = new Namespace("http://schemas.xmlsoap.org/wsdl/");

        public static const TYPES:QName = new QName(WSDLNS, "types");
        public static const SCHEMA:QName = new QName(XSDNS, "schema");
        public static const IMPORT:QName = new QName(XSDNS, "import");
        public static const SCHEMA_LOCATION:QName = new QName(XSDNS, "schemaLocation");


        private var _wsdl:XML;
        private var _url:String;
        private var schemaLocations:Vector.<String>;
        private var urlLoader:URLLoader = new URLLoader();
        private var inProgress:Boolean = false;


        public function WSDLLoader()
        {
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_ioErrorHandler);
        }

        public function get wsdl():XML
        {
            return _wsdl;
        }

        public function load(url:String):void
        {
            if (inProgress) return;

            var urlRequest:URLRequest = new URLRequest(url);
            urlRequest.method = URLRequestMethod.GET;

            urlLoader.addEventListener(Event.COMPLETE, urlLoader_wsdl_completeHandler);
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
            urlLoader.load(urlRequest);

            inProgress = true;
        }

        private function urlLoader_wsdl_completeHandler(event:Event):void
        {
            urlLoader.removeEventListener(Event.COMPLETE, urlLoader_wsdl_completeHandler);
            _wsdl = new XML(urlLoader.data);
            getWsdlSchema();
        }

        private function getWsdlSchema():void
        {
            var schemas:XMLList = wsdl.child(TYPES).child(SCHEMA);
            schemaLocations = new Vector.<String>();

            for (var i:int = 0; i < schemas.length(); i++)
            {
                var schema:XML = schemas[i];
                var schemaUrl:String = schema.child(IMPORT).attribute(SCHEMA_LOCATION);
                if (notEmpty(schemaUrl))
                {
                    schemaLocations.push(schemaUrl);
                    delete schemas[i];
                    i -= 1;
                }
            }

            if (schemaLocations.length > 0)
            {
                loadNextWsdlSchema();
            }
            else
            {
                complete();
            }
        }

        private function loadNextWsdlSchema():void
        {
            var schemaUrl:String = schemaLocations.shift();
            var urlRequest:URLRequest = new URLRequest(schemaUrl);
            urlRequest.method = URLRequestMethod.GET;

            urlLoader.addEventListener(Event.COMPLETE, urlLoader_schema_completeHandler);
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
            urlLoader.load(urlRequest);
        }

        private function urlLoader_schema_completeHandler(event:Event):void
        {
            urlLoader.removeEventListener(Event.COMPLETE, urlLoader_schema_completeHandler);
            var schemaXML:XML = new XML(urlLoader.data);

            wsdl.child(TYPES).appendChild(schemaXML);

            if (schemaLocations.length > 0)
            {
                loadNextWsdlSchema();
            }
            else
            {
                complete();
            }
        }

        private function complete():void
        {
            inProgress = false;
            dispatchEvent(new Event(Event.COMPLETE));
        }

        private function urlLoader_ioErrorHandler(event:IOErrorEvent):void
        {
            Alert.show(event.text, "Could not load WSDL");
            inProgress = false;
        }
    }
}
