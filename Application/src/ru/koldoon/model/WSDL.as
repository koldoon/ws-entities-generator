package ru.koldoon.model
{
    import flash.events.Event;
    import flash.events.EventDispatcher;

    import ru.koldoon.model.type.AbstractType;
    import ru.koldoon.model.type.CollectionType;
    import ru.koldoon.model.type.ComplextType;
    import ru.koldoon.model.type.EnumType;
    import ru.koldoon.model.type.IType;
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

            getSchemaNamespacePrefix(_source);
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


        private function getSchemaNamespacePrefix(xml:XML):void
        {
            for each (var ns:Namespace in xml.namespaceDeclarations())
                if (ns.uri == XSDNS.uri)
                    xsnsPrefix = ns.prefix;
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
                        var type:String = elementType[1];

                        messageTypesMap[type] = prefix;
                    }
                }
            }
        }

        /**
         * @see model.type.ComplextType
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

            for each (var complexType:XML in complexTypes)
            {
                var type:ComplextType = parseComplexType(complexType);

                if (type && !messageTypesMap[type.name])
                {
                    _types.push(type);
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
        private function parseComplexType(xmlData:XML):ComplextType
        {
            if (xmlData.children().length() == 0)
                return null;

            var className:String = xmlData.@name;
            var sequence:XMLList = xmlData.child(SEQUENCE).child(ELEMENT);
            var all:XMLList = xmlData.child(ALL).child(ELEMENT);
            var extension:XMLList = xmlData.child(COMPLEX_CONTENT).child(EXTENSION);

            var type:ComplextType = getTypeInstance(className) as ComplextType;
            type.properties = getPropertiesFromXmlElements(sequence);
            type.properties = type.properties.concat(getPropertiesFromXmlElements(all));

            if (extension.length() > 0)
            {
                var extensionBase:Array = String(extension.@base).split(":");
                var extensionName:String = extensionBase[1];
                type.parent = getTypeInstance(extensionName);

                var extSequence:XMLList = extension.child(SEQUENCE).child(ELEMENT);
                var extAll:XMLList = extension.child(ALL).child(ELEMENT);

                type.properties = type.properties.concat(getPropertiesFromXmlElements(extSequence));
                type.properties = type.properties.concat(getPropertiesFromXmlElements(extAll));
            }

            return type;
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

                if (propTypeDef[0] == xsnsPrefix)
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
                _typesMap[className] = new ComplextType(className);
            }

            return AbstractType(_typesMap[className]);
        }
    }
}
