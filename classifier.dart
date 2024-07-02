import 'dart:math';
import 'package:collection/collection.dart';
import 'package:mariamtest/classifierModel.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';

enum ClassifierCategory {
  diseaseFree,
  scab,
  redRust,
  stylerAndRoot,
  phytophthora
}

class Classifier {
  late ClassifierModel _model;
  late List<String> _labels;
  late var _probabilityProcessor;
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 255);
  static const String modelFile = 'assets/model.tflite';

  // Future<void> loadModel({Interpreter? interpreter}) async {
  //   try {
  //     print('loading model...');
  //     _interpreter = interpreter ??
  //         await Interpreter.fromAsset(modelFile, options: InterpreterOptions()..threads = 4);
  //     _interpreter.allocateTensors();
  //     print('model loaded');
  //   } catch (e) {
  //     print('Unable to create interpreter, $e');
  //   }
  // }

  Future<void> loadLabels() async {
    // #1
    final rawLabels = await FileUtil.loadLabels('assets/labels.txt');

    // #2
    final labels = rawLabels
        .map((label) => label.substring(label.indexOf(' ')).trim())
        .toList();

    print('----------: $labels');
    _labels = labels;
  }

  Future<void> loadModel() async {
    // #1
    final interpreter = await Interpreter.fromAsset('model.tflite');
    // final interpreter = await Interpreter.fromAsset(modelFile, options: InterpreterOptions()..threads = 4);

    // #2
    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;

    print('----------Input shape: $inputShape');
    print('----------Output shape: $outputShape');

    // // #3
    final inputType = interpreter.getInputTensor(0).type;
    final outputType = interpreter.getOutputTensor(0).type;

    print('----------Input type: $inputType');
    print('----------Output type: $outputType');

    _model = ClassifierModel(
      interpreter: interpreter,
      inputShape: inputShape,
      outputShape: outputShape,
      inputType: inputType,
      outputType: outputType,
    );

    _probabilityProcessor =
        TensorProcessorBuilder().add(postProcessNormalizeOp).build();

    print('-----------------Model loaded successfully-----------------');
  }

  // Interpreter get interpreter => _interpreter;

  // void test() {
  //   print('Test');
  //   var list = _interpreter.getInputTensor(0).shape;
  //   print(list.join(','));
  // }

  Future<MapEntry<String, double>> predict(img.Image image) async {
    loadLabels();
    await loadModel();
    print('predicting image...');
    final inputImage = _preProcessInput(image);
    print(
      'Pre-processed image: ${inputImage.width}x${image.height}, '
      'size: ${inputImage.buffer.lengthInBytes} bytes',
    );

    // #1
    final outputBuffer = TensorBuffer.createFixedSize(
      _model.outputShape,
      _model.outputType,
    );

    // #2
    _model.interpreter.run(inputImage.buffer, outputBuffer.buffer);
    print('OutputBuffer: ${outputBuffer.getDoubleList()}');

    Map<String, double> labeledProb = TensorLabel.fromList(
            _labels, _probabilityProcessor.process(outputBuffer))
        .getMapWithFloatValue();

    print('LabeledProb: $labeledProb');

    final pred = getTopProbability(labeledProb);
    print('Prediction: ${pred.key} - ${pred.value}');
    return pred;
  }

  MapEntry<String, double> getTopProbability(Map<String, double> labeledProb) {
    var pq = PriorityQueue<MapEntry<String, double>>(compare);
    pq.addAll(labeledProb.entries);

    return pq.first;
  }

  int compare(MapEntry<String, double> e1, MapEntry<String, double> e2) {
    if (e1.value > e2.value) {
      return -1;
    } else if (e1.value == e2.value) {
      return 0;
    } else {
      return 1;
    }
  }

  TensorImage _preProcessInput(img.Image image) {
    // #1
    final inputTensor = TensorImage(_model.inputType);
    inputTensor.loadImage(image);

    // #2
    final minLength = min(inputTensor.height, inputTensor.width);
    final cropOp = ResizeWithCropOrPadOp(minLength, minLength);

    // #3
    final shapeLength = _model.inputShape[1];
    final resizeOp = ResizeOp(shapeLength, shapeLength, ResizeMethod.bilinear);

    // #4
    // final normalizeOp = NormalizeOp(127.5, 127.5);

    // #5
    final imageProcessor = ImageProcessorBuilder()
        .add(cropOp)
        .add(resizeOp)
        // .add(normalizeOp)
        .build();

    imageProcessor.process(inputTensor);

    // #6
    return inputTensor;
  }
}
