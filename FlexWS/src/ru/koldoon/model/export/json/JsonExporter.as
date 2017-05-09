/**
 * @author Vadim Usoltsev
 * @version $Id$
 *          $LastChangedDate$
 *          $Author$
 *          $Date$
 *          $Rev$
 */
package ru.koldoon.model.export.json {
    import ru.koldoon.model.export.ITypeExporter;
    import ru.koldoon.model.type.AbstractType;
    import ru.koldoon.model.type.CollectionType;
    import ru.koldoon.model.type.ComplexType;
    import ru.koldoon.model.type.EnumType;
    import ru.koldoon.model.type.IType;
    import ru.koldoon.model.type.MapType;
    import ru.koldoon.model.type.Property;

    public class JsonExporter implements ITypeExporter {
        private static const SIMPLE_TYPE_DEFAULTS:Object = {
            "string":  "-",
            "decimal": "0.0",
            "int":     "0",
            "boolean": "false"
        };


        public function JsonExporter() {
        }


        public function getTypeImplementation(type:IType):String {
            if (type is ComplexType) {
                var sampleObj:Object = {};
                createProperties(sampleObj, ComplexType(type));

                return JSON.stringify(sampleObj, null, 4);
            }
            else {
                return SIMPLE_TYPE_DEFAULTS[type.name] || type.name;
            }
        }


        private function createProperties(obj:Object, type:ComplexType):void {
            if (!obj["__type"]) {
                obj["__type"] = AbstractType(type).remoteType;
            }

            for each (var property:Property in type.properties) {
                if (property.type is ComplexType) {
                    obj[property.name] = {};
                    createProperties(obj[property.name], ComplexType(property.type));
                }
                else if (property.type is EnumType) {
                    obj[property.name] = EnumType(property.type).values.join("|")
                }
                else if (property.type is CollectionType) {
                    var elementType:IType = CollectionType(property.type).elementType;
                    if (elementType is ComplexType) {
                        var sampleObject:Object = {};
                        createProperties(sampleObject, ComplexType(elementType));
                        obj[property.name] = [sampleObject];
                    }
                    else if (elementType is EnumType) {
                        obj[property.name] = [EnumType(elementType).values.join("|")];
                    }
                    else {
                        obj[property.name] = [SIMPLE_TYPE_DEFAULTS[property.type.name] || property.type.name];
                    }
                }
                else if (property.type is MapType) {
                    var mapElementType:IType = MapType(property.type).valueType;
                    if (mapElementType is ComplexType) {
                        var mapSampleObject:Object = {};
                        createProperties(mapSampleObject, ComplexType(mapElementType));
                        obj[property.name] = {"KEY": mapSampleObject};
                    }
                    else {
                        obj[property.name] = {"KEY": (SIMPLE_TYPE_DEFAULTS[property.type.name] || property.type.name)};
                    }
                }
                else {
                    obj[property.name] = SIMPLE_TYPE_DEFAULTS[property.type.name] || property.type.name;
                }
            }

            if (type.parent != null && type.parent is ComplexType) {
                createProperties(obj, ComplexType(type.parent));
            }
        }
    }
}
