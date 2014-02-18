package ru.koldoon.model.export
{
    import ru.koldoon.model.ISelectable;
    import ru.koldoon.model.type.IType;

    [Bindable]
    public interface IExportableType extends IType, ISelectable
    {
        function get status():String;

        function set status(value:String):void;
    }
}
