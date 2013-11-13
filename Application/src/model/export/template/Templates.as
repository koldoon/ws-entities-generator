package model.export.template
{
    public class Templates
    {
        [Embed(source="/model/export/template/EnumType.template", mimeType="application/octet-stream")]
        public static const EnumTypeTemplate:Class;

        [Embed(source="/model/export/template/ComplexType.template", mimeType="application/octet-stream")]
        public static const ComplexTypeTemplate:Class;

    }
}
