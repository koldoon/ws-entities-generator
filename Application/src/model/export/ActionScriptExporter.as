package model.export
{
    import flash.utils.Dictionary;

    import model.type.ComplextType;
    import model.type.EnumType;
    import model.type.IType;

    import tools.classof;

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
