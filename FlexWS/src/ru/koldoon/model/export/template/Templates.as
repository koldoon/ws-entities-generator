package ru.koldoon.model.export.template {
    public class Templates {
        [Embed(source="/ru/koldoon/model/export/template/EnumType.template", mimeType="application/octet-stream")]
        public static const EnumTypeTemplate:Class;

        [Embed(source="/ru/koldoon/model/export/template/EnumType2.template", mimeType="application/octet-stream")]
        public static const EnumTypeTemplate2:Class;

        [Embed(source="/ru/koldoon/model/export/template/ComplexType2.template", mimeType="application/octet-stream")]
        public static const ComplexTypeTemplate:Class;

    }
}
