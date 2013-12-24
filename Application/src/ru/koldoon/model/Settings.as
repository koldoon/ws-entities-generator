package ru.koldoon.model
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.SharedObject;

    import mx.collections.ArrayCollection;
    import mx.events.CollectionEvent;

    import ru.koldoon.tools.isEmpty;

    public class Settings extends EventDispatcher
    {
        private var sharedObj:SharedObject;
        private var settingsData:Object = { };
        private var _targetPackage:String = "";

        // -----------------------------------------------------------------------------------
        // Singleton
        // -----------------------------------------------------------------------------------

        private static var _instance:Settings;

        [Bindable("__NoChangeEvent__")]
        public static function getInstance():Settings
        {
            if (!_instance)
                _instance = new Settings();

            return _instance;
        }


        // -----------------------------------------------------------------------------------
        // Roots settings
        // -----------------------------------------------------------------------------------

        [Bindable(event="dataChange")]
        public function get projectRoot():String
        {
            return settingsData.projectRoot;
        }

        public function set projectRoot(value:String):void
        {
            settingsData.projectRoot = value;
            _targetPackage = getTargetPackage();
            dispatchEvent(new Event("dataChange"));
            writeSettings();
        }

        [Bindable(event="dataChange")]
        public function get javaRoot():String
        {
            return settingsData.javaRoot;
        }

        public function set javaRoot(value:String):void
        {
            settingsData.javaRoot = value;
            dispatchEvent(new Event("dataChange"));
            writeSettings();
        }

        [Bindable(event="dataChange")]
        public function get target():String
        {
            return settingsData.target;
        }

        public function set target(value:String):void
        {
            settingsData.target = value;
            _targetPackage = getTargetPackage();
            dispatchEvent(new Event("dataChange"));
            writeSettings();
        }

        [Bindable(event="dataChange")]
        public function get targetPackage():String
        {
            return _targetPackage;
        }

        private function getTargetPackage():String
        {
            var pckg:String;
            if (isEmpty(target) || isEmpty(projectRoot) || target.indexOf(projectRoot) == -1)
            {
                pckg = "";
            }
            else
            {
                pckg = target.slice(projectRoot.length + 1).split("\\").join(".").split("/").join(".");
            }

            return pckg;
        }

        // -----------------------------------------------------------------------------------
        // Types Map
        // -----------------------------------------------------------------------------------

        private var _typesMapCollection:ArrayCollection = new ArrayCollection();

        /**
         * Map of [RemoteTypeName]:[LocalTypeName]
         */
        [Bindable(event="dataChange")]
        public function get typesMap():Object
        {
            return settingsData.typesMap;
        }

        public function resetTypesMap():void
        {
            var typesMapDefault:Object = {
                double:   "Number",
                string:   "String",
                dateTime: "Date",
                long:     "Number",
                boolean:  "Boolean",
                deciaml:  "Number"

            };

            typesMapCollection.source = getListOfTypesMap(typesMapDefault);
            dispatchEvent(new Event("dataChange"));
        }

        [Bindable(event="__NoChangeEvent__")]
        public function get typesMapCollection():ArrayCollection
        {
            return _typesMapCollection;
        }

        public function Settings()
        {
            if (_instance)
                throw new Error("Always use Settings.getInstance() instead of creation");

            sharedObj = SharedObject.getLocal("ru.koldoon.wsasgen");
            settingsData = sharedObj.data.settings || { };
            _targetPackage = getTargetPackage();
            typesMapCollection.source = getListOfTypesMap(settingsData.typesMap);
            typesMapCollection.addEventListener(CollectionEvent.COLLECTION_CHANGE, typesMapCollection_changeHandler);
            dispatchEvent(new Event("dataChange"));
        }

        private function getListOfTypesMap(map:Object):Array
        {
            var types:Array = [];
            for (var remoteType:String in map)
            {
                var mapItem:Object = { };
                mapItem.remoteType = remoteType;
                mapItem.localType = map[remoteType];
                types.push(mapItem);
            }

            return types;
        }

        private function writeSettings():void
        {
            if (sharedObj)
            {
                try
                {
                    sharedObj.data.settings = settingsData;
                    sharedObj.flush();
                }
                catch (e:Error)
                {

                }
            }
        }

        private function typesMapCollection_changeHandler(event:CollectionEvent):void
        {
            var typesMap:Object = { };
            for each (var obj:Object in _typesMapCollection)
            {
                typesMap[obj.remoteType] = obj.localType;
            }

            settingsData.typesMap = typesMap;
            writeSettings();
        }
    }
}
