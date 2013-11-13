package model.export
{
    import flash.display.Shape;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

    import model.ProgressEvent;

    import tools.isEmpty;

    [Event(name="complete", type="flash.events.Event")]
    [Event(name="progressMessage", type="model.ProgressEvent")]

    public class FileSystemExporter extends EventDispatcher
    {
        /**
         * Target Directory
         */
        public var target:String = "";

        /**
         * Instance of Types Exporter
         */
        public var typeExporter:ITypeExporter;

        public var types:Vector.<IExportableType>;

        public function FileSystemExporter()
        {
        }


        private var file:File = new File();
        private var fileStream:FileStream = new FileStream();
        private static const frameTicker:Shape = new Shape();

        public function getFilesStatus():void
        {
            if (isEmpty(target) || !typeExporter)
                return;

            currentTypeIndex = 0;
            frameTicker.addEventListener(Event.ENTER_FRAME, __getNextFileStatus);
        }


        private var currentTypeIndex:int = 0;

        private function __getNextFileStatus(event:Event):void
        {
            if (currentTypeIndex >= types.length)
            {
                frameTicker.removeEventListener(Event.ENTER_FRAME, __getNextFileStatus);
                dispatchEvent(new Event(Event.COMPLETE));
                return;
            }

            var currentType:IExportableType = types[currentTypeIndex];
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS_MESSAGE, "Check status " + currentType.name));
            file.nativePath = target + "\\" + currentType.name + ".as";

            if (file.exists)
            {
                fileStream.open(file, FileMode.READ);
                var fileData:String = fileStream.readUTFBytes(fileStream.bytesAvailable);

                currentType.status = (fileData == typeExporter.getTypeImplementation(currentType)) ? "" : "MOD";
                currentType.selected = false;
                fileStream.close();
            }
            else
            {
                currentType.status = "NEW";
            }

            currentTypeIndex++;
        }


        public function beginExportSelected():void
        {
            if (isEmpty(target) || !typeExporter)
                return;

            currentTypeIndex = 0;
            frameTicker.addEventListener(Event.ENTER_FRAME, __exportNextSelectedFile);
        }

        private function __exportNextSelectedFile(event:Event):void
        {
            if (currentTypeIndex >= types.length)
            {
                frameTicker.removeEventListener(Event.ENTER_FRAME, __exportNextSelectedFile);
                dispatchEvent(new Event(Event.COMPLETE));
                return;
            }

            var currentType:IExportableType = types[currentTypeIndex];
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS_MESSAGE, "Export type " + currentType.name));

            if (currentType.selected)
            {
                file.nativePath = target + "\\" + currentType.name + ".as";
                fileStream.open(file, FileMode.WRITE);
                fileStream.writeUTFBytes(typeExporter.getTypeImplementation(currentType));
                fileStream.close();
            }

            currentTypeIndex++;
        }
    }
}
