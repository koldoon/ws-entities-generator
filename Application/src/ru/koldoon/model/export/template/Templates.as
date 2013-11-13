package ru.koldoon.model.export.template
{
    public class Templates
    {
        [Embed(source="/ru/koldoon/model/export/template/EnumType.template", mimeType="application/octet-stream")]
        public static const EnumTypeTemplate:Class;

        [Embed(source="/ru/koldoon/model/export/template/ComplexType.template", mimeType="application/octet-stream")]
        public static const ComplexTypeTemplate:Class;

    }
}
