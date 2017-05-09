package ru.koldoon.model {
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.FileListEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

    import ru.koldoon.tools.isEmpty;
    import ru.koldoon.tools.notEmpty;

    [Event(name="typeFound", type="ru.koldoon.model.JavaTypesParserEvent")]
    [Event(name="complete", type="flash.events.Event")]
    [Event(name="progressMessage", type="ru.koldoon.model.ProgressEvent")]

    public class JavaTypesParser extends EventDispatcher {
        private static const javaPackageRegExp:RegExp =
            /package\s+(?P<Package>(\w+\.|\w+)*);/;

        private static const xmlTypedJavaClassRegExp:RegExp =
            /@XmlType\(name\s*=\s*\"(?P<XmlType>\w+)\"\).*public\s+((abstract|final)\s+){0,1}(class|enum)\s+(?P<JavaType>\w+)\s+.*\{.*\}/;

        private static const javaClassRegExp:RegExp =
            /public\s+((abstract|final)\s+){0,1}(class|enum)\s+(?P<JavaType>\w+)\s+.*\{.*\}/;


        private var _javaRoot:String;
        private var directoriesQueue:Vector.<File> = new Vector.<File>();


        public function JavaTypesParser() {
        }


        public function set javaRoot(value:String):void {
            _javaRoot = value;
        }


        public function get javaRoot():String {
            return _javaRoot;
        }


        public function start():void {
            if (isEmpty(_javaRoot)) {
                return;
            }

            var file:File = new File(_javaRoot);

            if (!file.isDirectory) {
                throw new Error("javaRoot must be the path to directory!");
            }

            scanDirectory(file);
        }


        private function scanDirectory(directory:File):void {
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS_MESSAGE, "Scanning directory " + directory.nativePath));
            directory.addEventListener(FileListEvent.DIRECTORY_LISTING, directory_directoryListingHandler, false, 0, true);
            directory.getDirectoryListingAsync();
        }


        private function directory_directoryListingHandler(event:FileListEvent):void {
            File(event.target).removeEventListener(FileListEvent.DIRECTORY_LISTING, directory_directoryListingHandler);

            for each (var item:File in event.files) {
                if (item.isDirectory) {
                    directoriesQueue.push(item);
                }
                else {
                    checkJavaClass(item);
                }
            }

            if (directoriesQueue.length > 0) {
                var nextDirectory:File = directoriesQueue.pop();
                nextDirectory.addEventListener(FileListEvent.DIRECTORY_LISTING, directory_directoryListingHandler, false, 0, true);
                nextDirectory.getDirectoryListingAsync();
            }
            else {
                dispatchEvent(new Event(Event.COMPLETE));
            }
        }


        private function checkJavaClass(file:File):void {
            if (file.extension != "java") {
                return;
            }

            var fileStream:FileStream = new FileStream();
            fileStream.open(file, FileMode.READ);
            var classData:String = fileStream.readUTFBytes(fileStream.bytesAvailable);

            classData = classData.split("\r").join(" ").split("\n").join(" ");

            var typeName:String;
            var xmlTypedMatch:Object = xmlTypedJavaClassRegExp.exec(classData);
            if (xmlTypedMatch) {
                typeName = xmlTypedMatch.XmlType;
            }
            else {
                var javaTypeMatch:Object = javaClassRegExp.exec(classData);
                if (javaTypeMatch) {
                    typeName = javaTypeMatch.JavaType;
                }
            }

            if (notEmpty(typeName)) {
                var javaPackage:String;
                var javaPackageMatch:Object = javaPackageRegExp.exec(classData);

                if (javaPackageMatch) {
                    javaPackage = javaPackageMatch.Package;
                }

                var typeFoundEvent:JavaTypesParserEvent = new JavaTypesParserEvent(JavaTypesParserEvent.TYPE_FOUND);
                typeFoundEvent.typeName = typeName;
                typeFoundEvent.typePackage = javaPackage || "";

                dispatchEvent(typeFoundEvent);
            }
        }
    }
}
