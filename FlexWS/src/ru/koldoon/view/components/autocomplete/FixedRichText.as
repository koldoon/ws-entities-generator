package ru.koldoon.view.components.autocomplete {
    import spark.components.RichText;

    /**
     * FixedRichText component  is used for HighlightListItemRenderer to provide
     * workaround for Flex 4 SDK issue https://issues.apache.org/jira/browse/FLEX-23126
     */
    public class FixedRichText extends RichText {
        public function FixedRichText() {
            super();
        }


        override protected function commitProperties():void {
            var getText:String = text;
            super.commitProperties();
        }
    }
}