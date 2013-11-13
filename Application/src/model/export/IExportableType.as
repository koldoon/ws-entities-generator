package model.export
{
    import model.ISelectable;
    import model.type.IType;

    [Bindable]
    public interface IExportableType extends IType, ISelectable
    {
        function get status():String;

        function set status(value:String):void;
    }
}
