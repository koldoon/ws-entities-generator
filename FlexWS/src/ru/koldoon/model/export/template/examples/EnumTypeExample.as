package ru.koldoon.model.export.template.examples
{
    public class EnumTypeExample
    {
        public static const AUS:EnumTypeExample = new EnumTypeExample("AUS");

        private static var _values:Vector.<String>;
        private var _value:String;

        public function EnumTypeExample(value:String)
        {
            _value = value;

            if (!_values)
                _values = new Vector.<String>();

            _values.push(value);
        }

        public function get value():String
        {
            return _value;
        }

        public function getValues():Vector.<String>
        {
            return _values.slice();
        }
    }
}
