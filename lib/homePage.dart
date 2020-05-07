import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _outputs;
  File _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  showFloatingActionButton() {
    if (_image == null) {
      return FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add_a_photo),
        tooltip: 'Open Camera',
        onPressed: _optionsDialogBox,
      );
    } else {
      return FloatingActionButton(
        backgroundColor: Colors.red,
        child: Icon(Icons.close),
        onPressed: () {
          setState(() {
            _image = null;
          });
        },
      );
    }
  }

  Future<void> _optionsDialogBox() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(10.0),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: Text(
                      'Take a Picture',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    onTap: openCamera,
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                  ),
                  GestureDetector(
                    child: Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    onTap: openGallery,
                  )
                ],
              ),
            ),
          );
        });
  }

  Future openCamera() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    Navigator.of(context).pop();

    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  Future openGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    Navigator.of(context).pop();
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/custom_model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text('ASL Recognition'))),
      body: Container(
          child: Column(
        children: <Widget>[
          SizedBox(
            height: 170,
          ),
          _loading
              ? Center(
                  child: Container(
                    alignment: Alignment.center,
                    child: Center(
                      child: Text(
                        'No image is Selected',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Roboto"),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _image == null
                            ? Center(
                                child: Container(
                                  child: Text(
                                    'No image is Selected',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Roboto"),
                                  ),
                                ),
                              )
                            : Container(
                                height: 400,
                                width: 400,
                                child: Image.file(_image),
                              ),
                        SizedBox(
                          height: 20,
                        ),
                        _image != null
                            ? Text(
                                "${_outputs[0]["label"]}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  //background: Paint()..color = Colors.white,
                                ),
                              )
                            : Container()
                      ],
                    ),
                  ),
                ),
        ],
      )),
      floatingActionButton: showFloatingActionButton(),
    );
  }
}
