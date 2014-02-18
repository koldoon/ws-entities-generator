package ru.koldoon.tools
{
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;

    public function classof(obj:Object):Class
    {
        return Class(getDefinitionByName(getQualifiedClassName(obj)));
    }
}
