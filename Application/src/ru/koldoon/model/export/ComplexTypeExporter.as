package ru.koldoon.model.export
{
    import ru.koldoon.model.Settings;
    import ru.koldoon.model.export.template.Templates;
    import ru.koldoon.model.type.CollectionType;
    import ru.koldoon.model.type.ComplexType;
    import ru.koldoon.model.type.IType;
    import ru.koldoon.model.type.Property;

    public class ComplexTypeExporter implements ITypeExporter
    {
        private static const complexTypeTemplate:String = new Templates.ComplexTypeTemplate();

        // Template Tokens
        public static const PACKAGE:String = "#PACKAGE#";
        public static const REMOTE_TYPE:String = "#REMOTE_TYPE#";
        public static const IMPORT_TAMPLATE:String = "#IMPORT_TAMPLATE#\n";

        public static const TYPE_HEADER:String = "#TYPE_HEADER#\n";
        public static const SUBTYPE_HEADER:String = "#SUBTYPE_HEADER#\n";
        public static const SUBTYPE_NAME:String = "#SUBTYPE_NAME#";

        public static const PROPERTY_TEMPLATE:String = "#PROPERTY_TEMPLATE#\n";
        public static const PROPERTY_NAME:String = "#PROPERTY_NAME#";
        public static const PROPERTY_TYPE:String = "#PROPERTY_TYPE#";

        public static const COLLECTION_TEMPLATE:String = "#COLLECTION_TEMPLATE#\n";
        public static const COLLECTION_NAME:String = "#COLLECTION_NAME#";
        public static const COLLECTION_ELEMENT_TYPE:String = "#COLLECTION_ELEMENT_TYPE#";

        public static const TYPE_NAME:String = "#TYPE_NAME#";


        private var settings:Settings = Settings.getInstance();


        public function ComplexTypeExporter()
        {
        }


        public function getTypeImplementation(type:IType):String
        {
            var prop:Property;
            var typesMap:Object = settings.typesMap;
            var typeModel:ComplexType = ComplexType(type);
            var typeImpl:String = complexTypeTemplate;

            // -----------------------------------------------------------------------------------
            // Class Header
            // -----------------------------------------------------------------------------------

            var headerTemplate:Array;
            if (typeModel.parent)
            {
                headerTemplate = typeImpl.split(TYPE_HEADER);
                typeImpl = headerTemplate[0] + headerTemplate[2];
                typeImpl = typeImpl
                        .split(SUBTYPE_HEADER).join("")
                        .split(SUBTYPE_NAME).join(typesMap[typeModel.parent.name] || typeModel.parent.name);
            }
            else
            {
                headerTemplate = typeImpl.split(SUBTYPE_HEADER);
                typeImpl = headerTemplate[0] + headerTemplate[2];
                typeImpl = typeImpl
                        .split(TYPE_HEADER).join("");
            }

            // -----------------------------------------------------------------------------------
            // Fill in properties by template
            // -----------------------------------------------------------------------------------

            var propertyTemplate:Array = typeImpl.split(PROPERTY_TEMPLATE);
            var propertiesListImpl:String = "";
            const propertyPattern:String = propertyTemplate[1];
            for each (prop in typeModel.properties)
            {
                if (!(prop.type is CollectionType))
                {
                    propertiesListImpl += propertyPattern
                            .split(PROPERTY_NAME).join(prop.name)
                            .split(PROPERTY_TYPE).join(typesMap[prop.type.name] || prop.type.name);
                }
            }
            typeImpl = propertyTemplate[0] + propertiesListImpl + propertyTemplate[2];

            // -----------------------------------------------------------------------------------
            // Fill in collection properties by template
            // -----------------------------------------------------------------------------------

            var collectionTemplate:Array = typeImpl.split(COLLECTION_TEMPLATE);
            var collectionsListImpl:String = "";
            const collectionPattern:String = collectionTemplate[1];
            for each (prop in typeModel.properties)
            {
                if (prop.type is CollectionType)
                {
                    collectionsListImpl += collectionPattern
                            .split(COLLECTION_NAME).join(prop.name)
                            .split(COLLECTION_ELEMENT_TYPE).join(prop.type.name);
                }
            }
            typeImpl = collectionTemplate[0] + collectionsListImpl + collectionTemplate[2];

            // -----------------------------------------------------------------------------------
            // Fill in type name, package and imports
            // -----------------------------------------------------------------------------------

            typeImpl = typeImpl
                    .split(TYPE_NAME).join(typesMap[typeModel.name] || typeModel.name)
                    .split(PACKAGE).join(settings.targetPackage)
                    .split(REMOTE_TYPE).join(typeModel.remoteType)
                    .split(IMPORT_TAMPLATE).join("");

            return typeImpl;
        }
    }
}
