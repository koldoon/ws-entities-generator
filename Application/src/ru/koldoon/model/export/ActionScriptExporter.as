package ru.koldoon.model.export
{
    import flash.utils.Dictionary;

    import ru.koldoon.model.type.ComplextType;
    import ru.koldoon.model.type.EnumType;
    import ru.koldoon.model.type.IType;
    import ru.koldoon.tools.classof;

    /**
     * Complex type exporter. Delegates concrete type export to subsequent classes;
     */
    public class ActionScriptExporter implements ITypeExporter
    {
        private var registeredTypeExporters:Dictionary = new Dictionary();

        public function ActionScriptExporter()
        {
            registeredTypeExporters[EnumType] = new EnumTypeExporter();
            registeredTypeExporters[ComplextType] = new ComplexTypeExporter();
        }


        public function getTypeImplementation(type:IType):String
        {
            if (!type)
                return "";

            var exporter:ITypeExporter = registeredTypeExporters[classof(type)];
            return exporter ? exporter.getTypeImplementation(type) : "";
        }
    }
}
