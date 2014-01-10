package ru.koldoon.model
{
    import flash.events.Event;
    import flash.events.EventDispatcher;

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

    public class WSDL extends EventDispatcher
    {
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
        private var xsnsPrefix:String = "";

        /**
         * [name]:[AbstractType]
         */
        private var _typesMap:Object = { };

        /**
         * [name]:[prefix];
         */
        private var messageTypesMap:Object = { };
        private var _types:Vector.<IType> = new Vector.<IType>();
        private var _messages:Vector.<String> = new Vector.<String>();


        /**
         * Constructor
         *
         * @param wsdl
         */
        public function WSDL(wsdl:XML = null)
        {
            if (wsdl)
            {
                source = wsdl;
            }
        }


        public function set source(value:XML):void
        {
            _source = value;
            _types = new Vector.<IType>();
            _typesMap = { };
            _messages = new Vector.<String>();
            messageTypesMap = { };

            xsnsPrefix = getSchemaNamespacePrefix(_source);
            parseMessages(_source.child(MESSAGE));

            var schemas:XMLList = _source.child(TYPES).child(SCHEMA);
            for each (var schema:XML in schemas)
            {
                parseTypes(schema);
            }

            dispatchEvent(new Event("wsdlChange"));
        }

        [Bindable(event="wsdlChange")]
        public function get source():XML
        {
            return _source;
        }


        /**
         * [name]:[AbstractType]
         */
        [Bindable(event="wsdlChange")]
        public function get typesMap():Object
        {
            return _typesMap;
        }


        private static function getSchemaNamespacePrefix(xml:XML):String
        {
            for each (var ns:Namespace in xml.namespaceDeclarations())
                if (ns.uri == XSDNS.uri)
                    return ns.prefix;

            return "";
        }

        private function parseMessages(messagesList:XMLList):void
        {
            for each (var message:XML in messagesList)
            {
                _messages.push(String(message.@name));

                for each (var messagePart:XML in message.child(PART))
                {
                    if (String(messagePart.@name) == "parameters")
                    {
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
        public function get types():Vector.<IType>
        {
            return _types;
        }

        public function get messages():Vector.<String>
        {
            return _messages;
        }


        private function parseTypes(schema:XML):void
        {
            _types = new Vector.<IType>();
            var complexTypes:XMLList = schema.child(COMPLEX_TYPE);
            var simpleTypes:XMLList = schema.child(SIMPLE_TYPE) // enums

            for each (var simpleType:XML in simpleTypes)
            {
                var enumType:EnumType = parseEnumType(simpleType);

                if (enumType)
                {
                    _types.push(enumType);
                }
            }

            for each (var complexTypeXML:XML in complexTypes)
            {
                var complexType:ComplexType = parseComplexType(complexTypeXML);

                if (complexType && !messageTypesMap[complexType.name])
                {
                    _types.push(complexType);
                }
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
        private function parseEnumType(xmlData:XML):EnumType
        {
            var enumeration:XMLList = xmlData.child(RESTRICTION).child(ENUMERATION);
            if (enumeration.length() == 0)
                return null;

            var className:String = xmlData.@name;
            var type:EnumType = new EnumType(className);

            for each (var item:XML in enumeration)
            {
                type.values.push(item.@value);
            }

            _typesMap[className] = type;
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
        private function parseComplexType(xmlData:XML):ComplexType
        {
            if (xmlData.children().length() == 0)
                return null;

            var className:String = xmlData.@name;
            var sequence:XMLList = xmlData.child(SEQUENCE).child(ELEMENT);
            var all:XMLList = xmlData.child(ALL).child(ELEMENT);
            var extension:XMLList = xmlData.child(COMPLEX_CONTENT).child(EXTENSION);

            var complexType:ComplexType = getTypeInstance(className) as ComplexType;
            complexType.properties = getPropertiesFromXmlElements(sequence);
            complexType.properties = complexType.properties.concat(getPropertiesFromXmlElements(all));

            if (extension.length() > 0)
            {
                var extensionDef:Array = String(extension.@base).split(":");
                var extensionName:String = extensionDef[1];
                complexType.parent = getTypeInstance(extensionName);

                var extSequence:XMLList = extension.child(SEQUENCE).child(ELEMENT);
                var extAll:XMLList = extension.child(ALL).child(ELEMENT);

                complexType.properties = complexType.properties.concat(getPropertiesFromXmlElements(extSequence));
                complexType.properties = complexType.properties.concat(getPropertiesFromXmlElements(extAll));
            }

            return complexType;
        }

        /**
         * Example:
         *
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
        private function parseMapType(xmlData:XML):MapType
        {
            var mapType:MapType = new MapType();
            var elements:XMLList = xmlData.child(SEQUENCE).child(ELEMENT).child(COMPLEX_TYPE).child(SEQUENCE).child(ELEMENT);
            var keyTypeDef:Array;
            var valueTypeDef:Array;

            for each (var element:XML in elements)
            {
                if (String(element.@name) == "key")
                    keyTypeDef = String(element.@type).split(":");

                if (String(element.@name) == "value")
                    valueTypeDef = String(element.@type).split(":");
            }

            var keyType:String = keyTypeDef[1];
            var valueType:AbstractType;

            if (valueTypeDef[0] == xsnsPrefix)
            {
                valueType = new SimpleType(valueTypeDef[1]);
            }
            else
            {
                valueType = getTypeInstance(valueTypeDef[1]);
            }

            mapType.keyType = keyType;
            mapType.valueType = valueType;

            return mapType;
        }

        private function getPropertiesFromXmlElements(elementsList:XMLList):Vector.<Property>
        {
            var properties:Vector.<Property> = new Vector.<Property>();
            for each (var element:XML in elementsList)
            {
                if (notEmpty(element.@ref)) // In case of message argument types
                    continue;

                var propInfo:Property = new Property(element.@name);
                var propTypeDef:Array = String(element.@type).split(":");
                var complexContent:XMLList = element.child(COMPLEX_TYPE);

                if (complexContent.length() > 0)
                {
                    propInfo.type = parseMapType(complexContent[0]);
                }
                else if (propTypeDef[0] == xsnsPrefix)
                {
                    propInfo.type = new SimpleType(propTypeDef[1]);
                }
                else
                {
                    if (element.@maxOccurs == "unbounded")
                    {
                        propInfo.type = new CollectionType(propTypeDef[1]);
                    }
                    else
                    {
                        propInfo.type = getTypeInstance(propTypeDef[1]);
                    }
                }

                properties.push(propInfo);
            }

            return properties;
        }


        private function getTypeInstance(className:String):AbstractType
        {
            if (!_typesMap[className])
            {
                // create a ComplexType instance by default
                // SimpleType instances should be parsed first
                _typesMap[className] = new ComplexType(className);
            }

            return AbstractType(_typesMap[className]);
        }
    }
}
