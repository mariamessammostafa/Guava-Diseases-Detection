import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:mariamtest/classifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guava Diseases Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Guava Diseases Detection'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? filePath;
  String resultText = 'Select an image to classify.';

  pickImageGallery() async {
    print('picking image...');
// Pick an image.
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    print('mariam 1');
    if (image == null) return;

    var imageInstance = img.decodeImage(await image.readAsBytes());

    if (imageInstance == null) return;

    print('image picked successfully, attempting to classify...');

    setState(() {
      resultText = 'Classifying...';
    });

    final classifier = Classifier();
    var result = await classifier.predict(imageInstance);

    setState(() {
      resultText = 'Result: ${result.key} \n Accuracy ${result.value}';
    });
  }

  pickImageCamera() async {
    print('taking image....');
// take a photo.
    final image = await ImagePicker().pickImage(source: ImageSource.camera);

    print('mariam 1');
    if (image == null) return;

    var imageInstance = img.decodeImage(await image.readAsBytes());

    if (imageInstance == null) return;

    print('image taking successfully, attempting to classify...');

    setState(() {
      resultText = 'Classifying...';
    });

    final classifier = Classifier();
    var result = await classifier.predict(imageInstance);

    setState(() {
      resultText = 'Result: ${result.key} \n Accuracy ${result.value}';
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(children: [
            const SizedBox(
              height: 12,
            ),
            Card(
              elevation: 20,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 18,
                      ),
                      Container(
                        height: 280,
                        width: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/upload.jpg'),
                          ),
                        ),
                        child: filePath == null
                            ? const Text('')
                            : Image.file(
                                filePath!,
                                fit: BoxFit.fill,
                              ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(resultText,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 2,
                              color: Colors.black)),
                      const SizedBox(
                        height: 8,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          pickImageCamera();
                        },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            foregroundColor: Colors.black),
                        child: const Text(
                          "Take a Photo",
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          pickImageGallery();
                        },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            foregroundColor: Colors.black),
                        child: const Text(
                          "Pick from gallery",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
