package model.export
{
    import model.type.IType;

    [Bindable]
    public interface ITypeExporter
    {
        function getTypeImplementation(type:IType):String;
    }
}
