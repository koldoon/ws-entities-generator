package ru.koldoon.model.type
{
    public interface IType
    {
        function get name():String;

        function set name(value:String):void;

        function get displayName():String;

        function getDescription():String;
    }
}
