package ru.koldoon.view.components.autocomplete {

    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;

    import mx.collections.ArrayCollection;
    import mx.events.FlexMouseEvent;
    import mx.managers.SystemManager;

    import ru.koldoon.view.components.autocomplete.event.AutoCompleteEvent;
    import ru.koldoon.view.components.autocomplete.event.HighlightItemListEvent;

    import spark.components.PopUpAnchor;
    import spark.components.TextInput;
    import spark.components.supportClasses.SkinnableComponent;
    import spark.events.TextOperationEvent;
    import spark.utils.LabelUtil;

    [DefaultProperty("dataProvider")]
    [Event(name="select", type="ru.koldoon.view.components.autocomplete.event.AutoCompleteEvent")]

    public class AutoComplete extends SkinnableComponent {
        [SkinPart(required="true", type="spark.components.PopUpAnchor")]
        public var popUp:PopUpAnchor;

        [SkinPart(required="true", type="ru.koldoon.view.components.autocomplete.HighlightItemList")]
        public var suggestionsList:HighlightItemList;

        [SkinPart(required="true", type="spark.components.TextInput")]
        public var textInput:TextInput;


        private var _collection:ArrayCollection = new ArrayCollection();
        private var _dataProviderChanged:Boolean;
        private var _completionAccepted:Boolean;
        private var _selectedItemChanged:Boolean;
        private var _enteredText:String = "";
        private var _previouslyEnteredText:String = "";
        private var _labelField:String;
        private var _labelFunction:Function;
        private var _selectedItem:Object;
        private var _searchMode:String = SearchMode.PREFIX_SEARCH;


        public function AutoComplete() {
            super();
            this.mouseEnabled = true;
        }


        [Bindable]
        public var maxRows:Number = 6;

        [Bindable]
        public var prompt:String;

        public var requireSelection:Boolean = false;

        public var forceOpen:Boolean = true;

        [Bindable]
        public var allowValuesNotFromDataProvider:Boolean;


        [Bindable]
        public function set dataProvider(value:Object):void {
            if (value is Array) {
                _collection.source = value as Array;
            }
            else if (value is ArrayCollection) {
                _collection.source = ArrayCollection(value).source;
            }
            else {
                _collection.source = [];
            }

            _dataProviderChanged = true;
            invalidateProperties();
        }


        public function get dataProvider():Object {
            return _collection;
        }


        public function set labelField(field:String):void {
            _labelField = field;

            if (suggestionsList) {
                suggestionsList.labelField = field;
            }
        }


        public function get labelField():String {
            return _labelField;
        }


        public function set searchMode(searchMode:String):void {
            _searchMode = searchMode;
            if (suggestionsList) {
                suggestionsList.searchMode = searchMode;
            }
        }


        public function get searchMode():String {
            return _searchMode;
        }


        public function set labelFunction(func:Function):void {
            _labelFunction = func;
            if (suggestionsList) {
                suggestionsList.labelFunction = func;
            }
        }


        public function get labelFunction():Function {
            return _labelFunction;
        }


        public function get selectedItem():* {
            return _selectedItem;
        }


        public function set selectedItem(item:*):void {
            _selectedItem = item;
            _previouslyEnteredText = enteredText = returnFunction(_selectedItem);

            _selectedItemChanged = true;
            invalidateProperties();
        }


        public function filterFunction(item:Object):Boolean {
            var itemLabel:String = itemToLabel(item).toLowerCase();

            if (searchMode == SearchMode.PREFIX_SEARCH) {
                return itemLabel.substr(0, enteredText.length) == enteredText.toLowerCase();
            }
            else // infix search mode
            {
                if (itemLabel.search(enteredText.toLowerCase()) != -1) {
                    return true;
                }
            }
            return false;
        }


        public function itemToLabel(item:Object):String {
            return LabelUtil.itemToLabel(item, labelField, labelFunction);
        }


        override public function set enabled(value:Boolean):void {
            super.enabled = value;

            if (textInput) {
                textInput.enabled = value;
            }
        }


        override public function setFocus():void {
            if (textInput) {
                textInput.setFocus();
            }
        }


        protected function set enteredText(text:String):void {
            _enteredText = text;
            if (textInput) {
                textInput.text = text;
            }

            if (suggestionsList) {
                suggestionsList.lookupValue = _enteredText;
            }
        }


        protected function get enteredText():String {
            return _enteredText;
        }


        protected function acceptCompletion():void {
            if (_collection.length > 0 && suggestionsList.selectedIndex >= 0) {
                _completionAccepted = true;
                selectedItem = _collection.getItemAt(suggestionsList.selectedIndex);
                hidePopUp();
            }
            else {
                if (allowValuesNotFromDataProvider) {
                    _completionAccepted = true;
                    selectedItem = _enteredText;
                }
                else {
                    _completionAccepted = false;
                    selectedItem = null;
                    restoreEnteredTextAndHidePopUp(!_completionAccepted);
                }
            }

            var e:AutoCompleteEvent = new AutoCompleteEvent(AutoCompleteEvent.SELECT, _selectedItem);
            dispatchEvent(e);
        }


        protected function filterData():void {
            _collection.filterFunction = filterFunction;
            _collection.refresh();

            if (_collection.length == 0) {
                hidePopUp();
            }
            else if (!isDropDownOpen) {
                if (forceOpen || enteredText.length > 0) {
                    showPopUp();
                }
            }
        }


        override protected function partAdded(partName:String, instance:Object):void {
            super.partAdded(partName, instance)

            if (instance == textInput) {
                textInput.text = _enteredText;

                textInput.addEventListener(FocusEvent.FOCUS_OUT, onInputFieldFocusOut);
                textInput.addEventListener(FocusEvent.FOCUS_IN, onInputFieldFocusIn);
                textInput.addEventListener(MouseEvent.CLICK, onInputFieldFocusIn);
                textInput.addEventListener(TextOperationEvent.CHANGE, onInputFieldChange);
                textInput.addEventListener(KeyboardEvent.KEY_DOWN, onInputFieldKeyDown);
            }

            if (instance == suggestionsList) {
                suggestionsList.dataProvider = _collection;
                suggestionsList.labelField = labelField;
                suggestionsList.labelFunction = labelFunction;
                suggestionsList.searchMode = searchMode;
                suggestionsList.requireSelection = requireSelection;

                suggestionsList.addEventListener(HighlightItemListEvent.ITEM_CLICK, onListItemClick);
            }
        }


        override protected function commitProperties():void {

            if (_dataProviderChanged) {
                _dataProviderChanged = false;
                suggestionsList.dataProvider = _collection;
            }

            if (_selectedItemChanged) {
                suggestionsList.selectedIndex = _collection.getItemIndex(selectedItem);
                _selectedItemChanged = false;
            }

            // Should be last statement.
            // Don't move it up.
            super.commitProperties();
        }


        private function returnFunction(item:Object):String {
            if (item == null) {
                return "";
            }

            if (labelField) {
                return item[labelField];
            }
            else {
                return itemToLabel(item);
            }
        }


        private function onInputFieldChange(event:TextOperationEvent = null):void {
            _completionAccepted = false;
            enteredText = textInput.text;
            filterData();
        }


        private function onInputFieldKeyDown(event:KeyboardEvent):void {
            switch (event.keyCode) {
                case Keyboard.UP:
                case Keyboard.DOWN:
                case Keyboard.END:
                case Keyboard.HOME:
                case Keyboard.PAGE_UP:
                case Keyboard.PAGE_DOWN:
                    suggestionsList.focusListUponKeyboardNavigation(event);
                    break;

                case Keyboard.ENTER:
                    acceptCompletion();
                    break;

                case Keyboard.TAB:
                case Keyboard.ESCAPE:
                    restoreEnteredTextAndHidePopUp(!_completionAccepted);
                    break;
            }
        }


        private function showPopUp():void {
            popUp.displayPopUp = true;

            if (requireSelection) {
                suggestionsList.selectedIndex = 0;
            }
            else {
                suggestionsList.selectedIndex = -1;
            }

            if (suggestionsList.dataGroup) {
                suggestionsList.dataGroup.verticalScrollPosition = 0;
                suggestionsList.dataGroup.horizontalScrollPosition = 0;
            }

            popUp.popUp.addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, onMouseDownOutside);
        }


        private function restoreEnteredTextAndHidePopUp(restoreEnteredText:Boolean):void {
            if (restoreEnteredText) {
                enteredText = _previouslyEnteredText;
            }
            hidePopUp();
        }


        private function hidePopUp():void {
            popUp.popUp.removeEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, onMouseDownOutside);
            popUp.displayPopUp = false;
        }


        private function get isDropDownOpen():Boolean {
            return popUp.displayPopUp;
        }


        private function onInputFieldFocusIn(event:Event):void {
            if (forceOpen) {
                filterData();
            }

            _previouslyEnteredText = enteredText;
        }


        private function onInputFieldFocusOut(event:FocusEvent):void {
            restoreEnteredTextAndHidePopUp(!_completionAccepted);
        }


        private function onListItemClick(event:HighlightItemListEvent):void {
            acceptCompletion();
            event.stopPropagation();
        }


        private function onMouseDownOutside(event:FlexMouseEvent):void {

            var mouseDownInsideComponent:Boolean = false;
            var clickedObject:DisplayObjectContainer = event.relatedObject as DisplayObjectContainer;

            while (!(clickedObject.parent is SystemManager)) {
                if (clickedObject == this) {
                    mouseDownInsideComponent = true;
                    break;
                }

                clickedObject = clickedObject.parent;
            }

            if (!mouseDownInsideComponent) {
                restoreEnteredTextAndHidePopUp(!_completionAccepted);
            }
        }
    }
}