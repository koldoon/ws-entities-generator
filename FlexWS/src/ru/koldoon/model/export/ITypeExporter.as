package ru.koldoon.model.export
{
    import ru.koldoon.model.type.IType;

    [Bindable]
    public interface ITypeExporter
    {
        function getTypeImplementation(type:IType):String;
    }
}
