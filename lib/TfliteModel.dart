import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:tflite/tflite.dart';

class TfliteModel extends StatefulWidget {
  const TfliteModel({Key? key}) : super(key: key);

  @override
  _TfliteModelState createState() => _TfliteModelState();
}

class _TfliteModelState extends State<TfliteModel> {
  late File _image;
  late List _results;
  bool imageSelect = false;
  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {
    Tflite.close();
    String res;
    res = (await Tflite.loadModel(
        model: "assets/tumor/model.tflite", labels: "assets/tumor/labels.txt"))!;
    print("Models loading status: $res");
  }

  Future imageClassification(File image) async {
    final List? recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _results = recognitions!;
      _image = image;
      imageSelect = true;
      scanning = true;
    });
    Timer(const Duration(seconds: 5), () {
      setState(() {
        scanning = false;
      });
    });
  }
  bool scanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detection Tumeur"),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              (imageSelect)
                  ? Container(
                      margin: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          Center(child: Image.file(_image)),
                        scanning?  Lottie.asset("assets/scan.json"):const SizedBox(),
                        ],
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(10),
                      child:  Opacity(
                        opacity: 0.8,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/brain.png",
                                height: 100,
                                width: 100,
                              ),
                              const Text("Aucune image selectionnée", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),),
                              const Text("Cliquer sur le bouton ci-dessous pour selectionner une image", textAlign: TextAlign.center,)
                            ],
                          ),
                        ),
                      ),
                    ),
              SingleChildScrollView(
                child: Column(
                  children: (imageSelect)
                      ? _results.map((result) {
                          return scanning? const SizedBox(): Card(
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    "assets/bot.png",
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("D'après l'image reçue, il se peut que vous ${result['label'].substring(1).toString().trim().toLowerCase()=='pas de tumeur'?'n\'ayez pas de tumeur':'ayez une tumeur de type ${result['label'].substring(1).toString().toLowerCase()}'}", style: const TextStyle(fontSize: 17, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center,),
                                ),
                                // Container(
                                //   margin: EdgeInsets.all(10),
                                //   child: Text(
                                //     "${result['label']} - ${result['confidence'].toStringAsFixed(2)}",
                                //     style: const TextStyle(
                                //         color: Colors.red, fontSize: 20),
                                //   ),
                                // ),
                              ],
                            ),
                          );
                        }).toList()
                      : [],
                ),
              )
            ],
          ),
       
       const Positioned(
        bottom: 5,
        left: 25,
        child: Text("Kaka Nzuki Medi 2023", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w200, color:Colors.grey),))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        tooltip: "Pick Image",
        child: const Icon(Icons.image),
      ),
    );
  }

  Future pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    File image = File(pickedFile!.path);
    imageClassification(image);
  }
}
