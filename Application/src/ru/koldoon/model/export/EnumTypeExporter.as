package ru.koldoon.model.export
{
    import ru.koldoon.model.Settings;
    import ru.koldoon.model.export.template.Templates;
    import ru.koldoon.model.type.EnumType;
    import ru.koldoon.model.type.IType;

    public class EnumTypeExporter implements ITypeExporter
    {
        private static const enumTypeTemplate:String = new Templates.EnumTypeTemplate();

        // Template Tokens
        private static const VALUE_NAME:String = "#VALUE_NAME#";
        private static const TYPE_NAME:String = "#TYPE_NAME#";
        private static const VALUE_TEMPLATE:String = "#VALUE_TEMPLATE#\n";
        private static const PACKAGE:String = "#PACKAGE#";


        private var settings:Settings = Settings.getInstance();


        public function EnumTypeExporter()
        {
        }

        public function getTypeImplementation(type:IType):String
        {
            var typesMap:Object = settings.typesMap;
            var typeModel:EnumType = EnumType(type);
            var valueTemplate:Array = enumTypeTemplate.split(VALUE_TEMPLATE);

            const valuePattern:String = valueTemplate[1];
            var valueListImpl:String = "";
            for each (var value:String in typeModel.values)
            {
                valueListImpl += valuePattern
                        .split(VALUE_NAME).join(value);
            }

            var typeImpl:String = valueTemplate[0] + valueListImpl + valueTemplate[2];
            typeImpl = typeImpl
                    .split(TYPE_NAME).join(typesMap[typeModel.name] || typeModel.name)
                    .split(PACKAGE).join(settings.targetPackage);

            return typeImpl;
        }
    }
}
