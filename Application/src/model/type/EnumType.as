package model.type
{
    import mx.utils.StringUtil;

    public class EnumType extends AbstractType
    {
        public var values:Vector.<String> = new Vector.<String>();

        public function EnumType(name:String)
        {
            super(name);
        }

        override public function getDescription():String
        {
            var valuesString:String = "<br>";
            for each (var value:String in values)
            {
                valuesString += StringUtil.substitute(" -> {0}<br>", value);
            }

            return super.getDescription() + valuesString;
        }
    }
}
