package ru.koldoon.view.components.autocomplete {

    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    import ru.koldoon.view.components.autocomplete.event.HighlightItemListEvent;

    import spark.components.List;

    [Event(name="itemClick", type="ru.koldoon.view.components.autocomplete.event.HighlightItemListEvent")]
    [Event(name="lookupValueChange", type="ru.koldoon.view.components.autocomplete.event.HighlightItemListEvent")]

    public class HighlightItemList extends List {

        public var searchMode:String;


        public function HighlightItemList() {
            super();
        }


        public function set lookupValue(lookupValue:String):void {
            _lookupValue = lookupValue;
            dispatchEvent(new HighlightItemListEvent(HighlightItemListEvent.LOOKUP_VALUE_CHANGE));
        }


        public function get lookupValue():String {
            return _lookupValue;
        }


        public function focusListUponKeyboardNavigation(event:KeyboardEvent):void {
            adjustSelectionAndCaretUponNavigation(event);
        }


        override protected function item_mouseDownHandler(event:MouseEvent):void {
            super.item_mouseDownHandler(event);
            dispatchEvent(new HighlightItemListEvent(HighlightItemListEvent.ITEM_CLICK));
        }


        private var _lookupValue:String = "";

    }
}