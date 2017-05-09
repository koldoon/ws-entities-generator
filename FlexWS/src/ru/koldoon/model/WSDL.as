package ru.koldoon.model {
    import flash.events.Event;
    import flash.events.EventDispatcher;

    import mx.controls.Alert;

    import ru.koldoon.model.type.AbstractType;
    import ru.koldoon.model.type.CollectionType;
    import ru.koldoon.model.type.ComplexType;
    import ru.koldoon.model.type.EnumType;
    import ru.koldoon.model.type.IType;
    import ru.koldoon.model.type.MapType;
    import ru.koldoon.model.type.Property;
    import ru.koldoon.model.type.SimpleType;
    import ru.koldoon.tools.notEmpty;

    [Event(name="wsdlChange", type="flash.events.Event")]

    public class WSDL extends EventDispatcher {
        public static const XSDNS:Namespace = new Namespace("http://www.w3.org/2001/XMLSchema");
        public static const WSDLNS:Namespace = new Namespace("http://schemas.xmlsoap.org/wsdl/");

        public static const TYPES:QName = new QName(WSDLNS, "types");
        public static const SCHEMA:QName = new QName(XSDNS, "schema");
        public static const IMPORT:QName = new QName(XSDNS, "import");
        public static const SCHEMA_LOCATION:QName = new QName(XSDNS, "schemaLocation");
        public static const SEQUENCE:QName = new QName(XSDNS, "sequence");
        public static const ALL:QName = new QName(XSDNS, "all");
        public static const EXTENSION:QName = new QName(XSDNS, "extension");
        public static const COMPLEX_CONTENT:QName = new QName(XSDNS, "complexContent");
        public static const ELEMENT:QName = new QName(XSDNS, "element");
        public static const COMPLEX_TYPE:QName = new QName(XSDNS, "complexType");
        public static const SIMPLE_TYPE:QName = new QName(XSDNS, "simpleType");
        public static const RESTRICTION:QName = new QName(XSDNS, "restriction");
        public static const ENUMERATION:QName = new QName(XSDNS, "enumeration");
        public static const MESSAGE:QName = new QName(WSDLNS, "message");
        public static const PART:QName = new QName(WSDLNS, "part");

        // -----------------------------------------------------------------------------------
        // Private
        // -----------------------------------------------------------------------------------

        private var _source:XML;
        private var xsnsPrefixes:Object = {"xs": true, "xsd": true};

        /**
         * [name]:[AbstractType]
         */
        private var _unionTypesMap:Object = {};

        /**
         * [elementTypeName]:[CollectionType]
         */
        private var _collectionTypesMap:Object = {};

        /**
         * [name]:[prefix];
         */
        private var messageTypesMap:Object = {};
        private var _types:Vector.<IType> = new Vector.<IType>();
        private var _messages:Vector.<String> = new Vector.<String>();


        /**
         * Constructor
         *
         * @param wsdl
         */
        public function WSDL(wsdl:XML = null) {
            if (wsdl) {
                source = wsdl;
            }
        }


        public function set source(value:XML):void {
            _source = value;
            _types = new Vector.<IType>();
            _unionTypesMap = {};
            _messages = new Vector.<String>();
            messageTypesMap = {};

            // xsnsPrefixes = getSchemaNamespacePrefix(_source);
            parseMessages(_source.child(MESSAGE));

            var schemas:XMLList = _source.child(TYPES).child(SCHEMA);
            var schema:XML;
            for each (schema in schemas) {
                parseSimpleTypes(schema);
            }
            for each (schema in schemas) {
                parseComplexTypes(schema);
            }
            updateCollectionTypes();

            dispatchEvent(new Event("wsdlChange"));
        }


        [Bindable(event="wsdlChange")]
        public function get source():XML {
            return _source;
        }


        /**
         * [name]:[AbstractType]
         */
        [Bindable(event="wsdlChange")]
        public function get unionTypesMap():Object {
            return _unionTypesMap;
        }


        private static function getSchemaNamespacePrefix(xml:XML):String {
            for each (var ns:Namespace in xml.namespaceDeclarations()) {
                if (ns.uri == XSDNS.uri) {
                    return ns.prefix;
                }
            }

            return "";
        }


        private function parseMessages(messagesList:XMLList):void {
            for each (var message:XML in messagesList) {
                _messages.push(String(message.@name));

                for each (var messagePart:XML in message.child(PART)) {
                    if (String(messagePart.@name) == "parameters") {
                        var elementType:Array = String(messagePart.@element).split(":");
                        var prefix:String = elementType[0];
                        var typeName:String = elementType[1];

                        messageTypesMap[typeName] = prefix;
                    }
                }
            }
        }


        /**
         * @see ComplexType
         */
        [Bindable(event="wsdlChange")]
        public function get types():Vector.<IType> {
            return _types;
        }


        public function get messages():Vector.<String> {
            return _messages;
        }


        private function parseSimpleTypes(schema:XML):void {
            var simpleTypes:XMLList = schema.child(SIMPLE_TYPE); // enums
            for each (var simpleType:XML in simpleTypes) {
                var enumType:EnumType = parseEnumType(simpleType);

                if (enumType) {
                    _types.push(enumType);
                }
            }
        }


        private function parseComplexTypes(schema:XML):void {
            var complexTypes:XMLList = schema.child(COMPLEX_TYPE);
            for each (var complexTypeXML:XML in complexTypes) {
                var complexType:ComplexType = parseComplexType(complexTypeXML);

                if (complexType && !messageTypesMap[complexType.name]) {
                    _types.push(complexType);
                }
            }
        }


        private function updateCollectionTypes():void {
            // After all, Update collection types with real element type instances
            for (var collectionTypeName:String in _collectionTypesMap) {
                CollectionType(_collectionTypesMap[collectionTypeName]).elementType = getUnionTypeInstance(collectionTypeName);
            }
        }


        /**
         * Example:
         * <xsd:simpleType name="totalsType">
         *     <xsd:restriction base="xs:string">
         *         <xsd:enumeration value="SECURED"/>
         *         <xsd:enumeration value="SEGREGATED"/>
         *     </xsd:restriction>
         * </xsd:simpleType>
         *
         * @param xmlData
         */
        private function parseEnumType(xmlData:XML):EnumType {
            var enumeration:XMLList = xmlData.child(RESTRICTION).child(ENUMERATION);
            if (enumeration.length() == 0) {
                return null;
            }

            var className:String = xmlData.@name;
            var type:EnumType = new EnumType(className);

            for each (var item:XML in enumeration) {
                type.values.push(item.@value);
            }

            _unionTypesMap[className] = type;
            return type;
        }


        /**
         * Example:
         * <xsd:complexType name="FXTransactionVO">
         *     <xsd:sequence>
         *          <xsd:element name="accountName" type="xs:string" minOccurs="0"/>
         *          <xsd:element name="userId" type="xs:string" minOccurs="0"/>
         *     </xsd:sequence>
         * </xsd:complexType>
         *
         * @param xmlData
         * @return
         */
        private function parseComplexType(xmlData:XML):ComplexType {
            if (xmlData.children().length() == 0) {
                return null;
            }

            var className:String = xmlData.@name;
            var sequence:XMLList = xmlData.child(SEQUENCE).child(ELEMENT);
            var all:XMLList = xmlData.child(ALL).child(ELEMENT);
            var extension:XMLList = xmlData.child(COMPLEX_CONTENT).child(EXTENSION);

            var complexType:ComplexType = getUnionTypeInstance(className) as ComplexType;
            complexType.properties = getPropertiesFromXmlElements(sequence);
            complexType.properties = complexType.properties.concat(getPropertiesFromXmlElements(all));

            if (extension.length() > 0) {
                var extensionDef:Array = String(extension.@base).split(":");
                var extensionName:String = extensionDef[1];
                complexType.parent = getUnionTypeInstance(extensionName);

                var extSequence:XMLList = extension.child(SEQUENCE).child(ELEMENT);
                var extAll:XMLList = extension.child(ALL).child(ELEMENT);

                complexType.properties = complexType.properties.concat(getPropertiesFromXmlElements(extSequence));
                complexType.properties = complexType.properties.concat(getPropertiesFromXmlElements(extAll));
            }

            return complexType;
        }


        /**
         * Example:
         * <xs:complexType>
         *     <xs:sequence>
         *         <xs:element name="entry" minOccurs="0" maxOccurs="unbounded">
         *             <xs:complexType>
         *                 <xs:sequence>
         *                     <xs:element name="key" minOccurs="0" type="xs:string"/>
         *                     <xs:element name="value" minOccurs="0" type="tns:CurrencyCutOffVO"/>
         *                 </xs:sequence>
         *             </xs:complexType>
         *         </xs:element>
         *     </xs:sequence>
         * </xs:complexType>
         *
         * @param xmlData
         * @return
         */
        private function parseMapType(xmlData:XML):MapType {
            var mapType:MapType = new MapType();
            var elements:XMLList = xmlData.child(SEQUENCE).child(ELEMENT).child(COMPLEX_TYPE).child(SEQUENCE).child(ELEMENT);
            var keyTypeDef:Array;
            var valueTypeDef:Array;

            for each (var element:XML in elements) {
                if (String(element.@name) == "key") {
                    keyTypeDef = String(element.@type).split(":");
                }

                if (String(element.@name) == "value") {
                    valueTypeDef = String(element.@type).split(":");
                }
            }

            if (!keyTypeDef || !valueTypeDef) {
                throw new Error("PARSING_ERROR");
            }

            if (keyTypeDef[0] in xsnsPrefixes) {
                mapType.keyType = new SimpleType(keyTypeDef[1]);
            }
            else {
                mapType.keyType = getUnionTypeInstance(keyTypeDef[1]);
            }

            if (valueTypeDef[0] in xsnsPrefixes) {
                mapType.valueType = new SimpleType(valueTypeDef[1]);
            }
            else {
                mapType.valueType = getUnionTypeInstance(valueTypeDef[1]);
            }

            return mapType;
        }


        private function getPropertiesFromXmlElements(elementsList:XMLList):Vector.<Property> {
            var properties:Vector.<Property> = new Vector.<Property>();
            for each (var element:XML in elementsList) {
                if (notEmpty(element.@ref)) // In case of message argument types
                {
                    continue;
                }

                var propInfo:Property = new Property(element.@name);
                var propTypeDef:Array = String(element.@type).split(":");
                var complexContent:XMLList = element.child(COMPLEX_TYPE);

                if (complexContent.length() > 0) {
                    try {
                        propInfo.type = parseMapType(complexContent[0]);
                    }
                    catch (error:Error) {
                        Alert.show("Could not parse probably map type:\n" + element.toXMLString());
                    }
                }
                else if (propTypeDef[0] in xsnsPrefixes) {
                    propInfo.type = new SimpleType(propTypeDef[1]);
                }
                else {
                    if (element.@maxOccurs == "unbounded") {
                        // real collection type will be injected after parsing all complex types
                        propInfo.type = getCollectionTypeInstance(propTypeDef[1]);
                    }
                    else {
                        propInfo.type = getUnionTypeInstance(propTypeDef[1]);
                    }
                }

                properties.push(propInfo);
            }

            return properties;
        }


        private function getUnionTypeInstance(className:String):AbstractType {
            if (!_unionTypesMap[className]) {
                // create a ComplexType instance by default
                // SimpleType instances should be parsed the first
                _unionTypesMap[className] = new ComplexType(className);
            }

            return AbstractType(_unionTypesMap[className]);
        }


        private function getCollectionTypeInstance(elementClassName:String):CollectionType {
            if (!_collectionTypesMap[elementClassName]) {
                _collectionTypesMap[elementClassName] = new CollectionType(elementClassName);
            }

            return CollectionType(_collectionTypesMap[elementClassName]);
        }
    }
}
