import 'dart:io';
import 'package:path/path.dart';
import 'package:recase/recase.dart';
import 'package:yaml/yaml.dart';

void generate(List<String> args) {
  bool verbose = args.length > 0 && args.first == "v";

  String savePath = "";

  String modelName = "";
  String controllerName = "";

  const kQuitMessage = "Not proceeding with model/controller creation";

  var directory = join(Directory.current.path);
  var pubspecFile = File(join(directory, "pubspec.yaml"));
  if (!pubspecFile.existsSync()) {
    quitMessage("Pubspec file is missing, make sure you're executing this"
        " in the root directory of your flutter application");
  }

  /// get pubspec project name

  var pubspecData = pubspecFile.readAsStringSync();
  var pubspecYaml = loadYaml(pubspecData);
  var projectName = pubspecYaml["name"] ?? null;
  if (projectName == null || projectName?.isEmpty) {
    quitMessage("pubspec is missing 'name' for your project");
  }

  var breakLoop = false;
  while (!breakLoop) {
    if (controllerName.isEmpty) {
      stdout.write("Enter controller name: ");
      controllerName = stdin.readLineSync().trim();
    }

    if (modelName.isEmpty) {
      stdout.write("Enter model name: ");
      modelName = stdin.readLineSync().trim();
    }

    if(controllerName.isNotEmpty && controllerName == modelName) {
      print("Class names must be different");
      modelName = "";
      controllerName = "";
    }

    if (controllerName.isNotEmpty && modelName.isNotEmpty) {
      modelName = ReCase(modelName).pascalCase;
      controllerName = ReCase(controllerName).pascalCase;

      var confirm = confirmation(
        "Are you sure you want '$controllerName' as your controller & "
            "'$modelName' as your model class? ", kQuitMessage);

      if(!confirm) {
        modelName = "";
        controllerName = "";
      } else {
        breakLoop = true;
      }
    }
  }

  /// lets ask them where to save our templates

  breakLoop = false;
  var fullSavePath = "";
  while (!breakLoop) {
    if (savePath.isEmpty) {
      stdout.write("Enter save path (inside the lib directory): ");
      savePath = stdin.readLineSync().trim();
    }

    if (savePath.isNotEmpty) {
      fullSavePath = join(directory, "lib", savePath);
      var confirm = confirmation(
        "Are you sure you want to save your controller here '$fullSavePath'? ", kQuitMessage);
        if(!confirm) {
          savePath = "";
        } else {
          breakLoop = true;
        }
    }
  }

  final context = Context(style: Style.posix);
  final modelIncludePath = context.join(projectName, savePath, "${ReCase(modelName).snakeCase}.dart");
  final controllerIncludePath = context.join(projectName, savePath, "${ReCase(controllerName).snakeCase}.dart");

  var modelTemplateData = getModelTemplate();
  var controllerTemplateData = getControllerTemplate();

  if(modelTemplateData.isEmpty || controllerTemplateData.isEmpty) {
    quitMessage("Template error: Both template files must contain template data");
  }

  // replace template data

  modelTemplateData = modelTemplateData
    .replaceAll("MODEL_NAME", modelName)
    .replaceAll("CONTROLLER_NAME", controllerName)
    .replaceAll("CONTROLLER_PACKAGE_PATH", controllerIncludePath)
  ;

  controllerTemplateData = controllerTemplateData
    .replaceAll("MODEL_NAME", modelName)
    .replaceAll("CONTROLLER_NAME", controllerName)
    .replaceAll("MODEL_PACKAGE_PATH", modelIncludePath)
  ;

  final saveDirectory = Directory(fullSavePath);
  if(!saveDirectory.existsSync()) {
    saveDirectory.createSync(recursive: true);
  }

  final modelFile = File(join(fullSavePath, "${ReCase(modelName).snakeCase}.dart"));
  final controllerFile = File(join(fullSavePath, "${ReCase(controllerName).snakeCase}.dart"));

  modelFile.createSync();
  controllerFile.createSync();

  modelFile.writeAsStringSync(modelTemplateData);
  controllerFile.writeAsStringSync(controllerTemplateData);

  print("Boilerplate saved successfully");
}

void quitMessage(String message) {
  print(message);
  exit(0);
}

bool confirmation(String message, String quitMsg) {
  var confirmation = false;
  String confirmationText;
  while (!confirmation) {
    stdout.write("$message [y]es/[n]o/[q]uit: ");

    confirmationText = stdin.readLineSync().trim();
    switch (confirmationText) {
      case "y":
      case "yes":
        return true;
      case "n":
      case "no":
        return false;
      case "q":
        quitMessage(quitMsg);
        break;
    }
  }
  return false;
}


String getControllerTemplate() {
  return """import 'package:momentum/momentum.dart';
import 'package:MODEL_PACKAGE_PATH';

class CONTROLLER_NAME extends MomentumController<MODEL_NAME> {
  @override
  MODEL_NAME init() {
    return MODEL_NAME(
      this,
    );
  }
}""";
}

String getModelTemplate() {
  return """import 'package:momentum/momentum.dart';
import 'package:CONTROLLER_PACKAGE_PATH';

class MODEL_NAME extends MomentumModel<CONTROLLER_NAME> {
  MODEL_NAME(CONTROLLER_NAME controller) : super(controller);

  @override
  void update() {
    MODEL_NAME(
      this.controller,
    ).updateMomentum();
  }
}""";
}