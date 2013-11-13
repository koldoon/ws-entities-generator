package ru.koldoon.model.type
{
    public class Property
    {
        public var name:String;
        public var type:IType;

        public function Property(name:String)
        {
            this.name = name;
        }
    }
}
