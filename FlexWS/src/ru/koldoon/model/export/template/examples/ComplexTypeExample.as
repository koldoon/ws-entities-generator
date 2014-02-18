package ru.koldoon.model.export.template.examples
{
    import mx.collections.ArrayCollection;

    [RemoteClass(alias="")]
    public class ComplexTypeExample extends SomeAbstractClassExample
    {
        private var _variableName:String;
        public function get variableName():String
        {
            return _variableName;
        }

        public function set variableName(value:String):void
        {
            _variableName = value;
        }


        private var _collectionName:ArrayCollection;
        /**
         * Collection of <code>CollectionElementType</code>
         * @see CollectionElementType
         */
        public function get collectionName():ArrayCollection
        {
            return _collectionName;
        }

        public function set collectionName(value:ArrayCollection):void
        {
            _collectionName = value;
        }


        public function ComplexTypeExample()
        {
        }
    }
}
