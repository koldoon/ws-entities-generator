package model.type
{
    import model.export.IExportableType;

    import mx.utils.StringUtil;

    public class AbstractType implements IExportableType
    {
        private var _name:String = "";
        private var _remoteType:String = "";

        public function AbstractType(name:String = null)
        {
            this._name = name;
        }


        public function get name():String
        {
            return _name;
        }

        public function set name(value:String):void
        {
            _name = value;
        }

        [Bindable]
        public function get remoteType():String
        {
            return _remoteType;
        }

        public function set remoteType(value:String):void
        {
            _remoteType = value;
        }

        public function getDescription():String
        {
            return StringUtil.substitute("<b>[ {0} ]</b>", _name);
        }


        private var _selected:Boolean;

        [Bindable]
        public function get selected():Boolean
        {
            return _selected;
        }

        public function set selected(value:Boolean):void
        {
            _selected = value;
        }

        [Bindable(event="__NoChangeEvent__")]
        public function get displayName():String
        {
            return name;
        }


        private var _status:String = "";

        [Bindable]
        public function get status():String
        {
            return _status;
        }

        public function set status(value:String):void
        {
            _status = value;
        }
    }
}
