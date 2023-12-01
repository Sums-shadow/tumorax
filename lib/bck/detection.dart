import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class CataractDetection extends StatefulWidget {
  const CataractDetection({Key? key}) : super(key: key);

  @override
  State<CataractDetection> createState() => _CataractDetectionState();
}

class _CataractDetectionState extends State<CataractDetection> {
  bool isWorking = false;
  List<dynamic> _currentRecognition = [];

  CameraController? cameraController;
  CameraImage? imgCamera;

  // Chargement du modele
  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model_tumor.tflite", labels: "assets/labels_tumor.txt");
  }

// Initialisation de la camera
  initCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController!.startImageStream((imageFromStream) => {
              if (!isWorking)
                {
                  isWorking = true,
                  imgCamera = imageFromStream,
                  runModelOnStreamFrames(),
                }
            });
      });
    });
  }


// Utiliser le modele sur la camera
  runModelOnStreamFrames() async {
    if (imgCamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: imgCamera!.height,
        imageWidth: imgCamera!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.1,
        asynch: true,
      );

      setState(() {
        _currentRecognition = recognitions!;
      });
      isWorking = false;
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryBlue = const Color(0xff0E061B);
    Size size = MediaQuery.of(context).size;
    var width = MediaQuery.of(context).size.width;
    var padding = 20.0;
    var labelWitdth = 150.0;
    var labelConfidence = 30.0;
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: size.height,
          child: Stack(
            children: [
              Container(
                height: size.height * .8,
                child: imgCamera == null
                    ? Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      )
                    : AspectRatio(
                        aspectRatio: cameraController!.value.aspectRatio,
                        child: CameraPreview(cameraController!),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    InkWell(
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                top: size.height * .7,
                left: 0,
                child: Container(
                  height: size.height * 0.5,
                  width: size.width,
                  padding: const EdgeInsets.symmetric(
                    vertical: 55.0,
                    horizontal: 0.0,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: ListView.builder(
                    itemCount: _currentRecognition.length,
                    itemBuilder: (context, index) {
                      if (_currentRecognition.length > index) {
                        return viewResult(padding, labelWitdth, index, width,
                            labelConfidence);
                      } else {
                        return Container();
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                  top: size.height * 0.73,
                  left: width * 0.05,
                  child: const Text(
                    "Résultats",
                    style: TextStyle(color: Colors.white, fontSize: 28),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Container viewResult(double padding, double labelWitdth, int index,
      double width, double labelConfidence) {
    return Container(
      height: 40,
      child: Row(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: padding, right: padding),
            width: labelWitdth,
            child: FittedBox(
              child: Text(
                _currentRecognition[index]['label'],
                maxLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ),
          Container(
            height: 8,
            width: width * 0.45,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              value: _currentRecognition[index]['confidence'],
            ),
          ),
          Container(
            width: labelConfidence,
            child: Text(
              (_currentRecognition[index]['confidence'] * 100)
                      .toStringAsFixed(0) +
                  '%',
              maxLines: 12,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}
