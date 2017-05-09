package ru.koldoon.model {
    [Bindable]
    public interface ISelectable {
        function get selected():Boolean;


        function set selected(value:Boolean):void;
    }
}
