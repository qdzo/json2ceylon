import com.redhat.ceylon.common.tool {
    CeylonBaseTool,
    summary,
    description,
    description__SETTER,
    argument__SETTER,
    option__SETTER
}
import java.util {
    JList = List
}

summary("generate ceylon classes from given json file")
description("ceylon json-2-ceylon file.json out_dir \"RootClassName\"")
shared class Json2CeylonTool() extends CeylonBaseTool() {

    argument__SETTER { multiplicity = "3"; }
    shared variable JList<String>? arguments = null;

    description__SETTER("Create externalizable class with embedded json parser/emitter, use `--serializable`")
    option__SETTER
    shared variable Boolean externalizable = false;

    shared actual void run() {
       if(exists v = arguments) {
           json2ceylon {
               inputFile = v.get(0).string;
               outputDir = v.get(1).string;
               clazzName = v.get(2).string;
               externalizable = externalizable;
           };
       } else {
           print("Wrong options. Try `ceylon json-2-ceylon --help` for help");
       }
    }
}
