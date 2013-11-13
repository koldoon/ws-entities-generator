package ru.koldoon.model.type
{
    import mx.utils.StringUtil;

    public class CollectionType extends AbstractType
    {
        public function CollectionType(name:String)
        {
            super(name);
        }

        override public function get displayName():String
        {
            return StringUtil.substitute("Collection of &lt;{0}&gt;", name);
        }
    }
}
