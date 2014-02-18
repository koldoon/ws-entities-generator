package ru.koldoon.model.type
{
    import mx.utils.StringUtil;

    public class MapType extends AbstractType
    {
        public var keyType:AbstractType;

        public var valueType:AbstractType;


        public function MapType()
        {
        }


        override public function get name():String
        {
            return "Object";
        }

        [Bindable(event="__NoChangeEvent__")]
        override public function get displayName():String
        {
            return StringUtil.substitute(
                    "Map of &lt;{0}, {1}&gt;",
                    keyType ? keyType.displayName : "String",
                    valueType ? valueType.displayName : "Object");
        }
    }
}
