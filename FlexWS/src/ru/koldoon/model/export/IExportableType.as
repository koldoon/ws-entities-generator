package ru.koldoon.model.export {
    import ru.koldoon.model.ISelectable;
    import ru.koldoon.model.type.IType;

    [Bindable]
    public interface IExportableType extends IType, ISelectable {
        /**
         * Shows if this type was already exported to filesystem.
         * Possible values: NEW, MOD
         */
        function get status():String;


        function set status(value:String):void;
    }
}
