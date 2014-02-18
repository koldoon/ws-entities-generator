/**
 * @author Vadim Usoltsev
 * @version $Id$
 *          $LastChangedDate$
 *          $Author$
 *          $Date$
 *          $Rev$
 */
package ru.koldoon.model.export.json
{
    import ru.koldoon.model.export.ITypeExporter;
    import ru.koldoon.model.type.CollectionType;
    import ru.koldoon.model.type.ComplexType;
    import ru.koldoon.model.type.EnumType;
    import ru.koldoon.model.type.IType;
    import ru.koldoon.model.type.Property;

    public class JsonExporter implements ITypeExporter
    {
        public function JsonExporter()
        {
        }

        public function getTypeImplementation(type:IType):String
        {
            if (type is ComplexType)
            {
                var sampleObj:Object = { };
                createProperties(sampleObj, ComplexType(type));
                return JSON.stringify(sampleObj, null, 4);
            }

            return "";
        }


        private static function createProperties(obj:Object, type:ComplexType):void
        {
            for each (var property:Property in type.properties)
            {
                if (property.type is ComplexType)
                {
                    obj[property.name] = { };
                    createProperties(obj[property.name], ComplexType(property.type));
                }
                else if (property.type is CollectionType)
                {
                    obj[property.name] = [ property.type.name ];
                }
                else if (property.type is EnumType)
                {
                    obj[property.name] = EnumType(property.type).values.join("|")
                }
                else
                {
                    obj[property.name] = property.type.name;
                }
            }

            if (type.parent != null && type.parent is ComplexType)
            {
                createProperties(obj, ComplexType(type.parent));
            }
        }
    }
}
