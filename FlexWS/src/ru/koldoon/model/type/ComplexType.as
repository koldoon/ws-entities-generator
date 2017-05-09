package ru.koldoon.model.type {
    import mx.utils.StringUtil;

    [Bindable]
    public class ComplexType extends AbstractType {
        /**
         * Super class
         */
        public var parent:IType;

        public var properties:Vector.<Property>;


        override public function getDescription():String {
            var headerString:String = StringUtil.substitute("<b>[ {0} ]</b>", name);
            var propsString:String = "";

            for each (var prop:Property in properties) {
                propsString += StringUtil.substitute(" + {0} : {1}<br>", prop.name, prop.type.displayName);
            }

            var parentString:String = parent ? "<br>parent:<br>" + parent.getDescription() : "";

            return headerString + "<br>" + propsString + parentString;
        }


        public function ComplexType(name:String) {
            super(name);
        }
    }
}
