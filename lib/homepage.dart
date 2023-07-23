import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  TextEditingController searchController = TextEditingController();
  bool isLoad = true;
  bool isLoader = false;
  List<ImageList> listOfImageValue = [];
  List<ImageList> tempArray = [];

  void downloadFromUrl(String url) async {
    setState(() => isLoader = true);
    const snackBar = SnackBar(
      content: Text('Download Successfully!'),
    );

    if (url != '') {
      var status = await Permission.storage.status;
      if (status.isGranted) {
        var response = await http.get(Uri.parse(url));
        var documentDirectory = await getApplicationDocumentsDirectory();
        var firstPath = "${documentDirectory.path}/images";
        var filePathAndName = '${documentDirectory.path}/images/pic.jpg';
        await Directory(firstPath).create(recursive: true);
        File file = File(filePathAndName);
        file.writeAsBytesSync(response.bodyBytes);
        await GallerySaver.saveImage(file.path).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      } else {
        if (!(await Permission.storage.request().isGranted)) {
          await openAppSettings();
        }
      }
    }
    setState(() => isLoader = false);
  }

  void fetchData() async {
    List<ImageList> returnValue = [];

    try {
      var url = Uri.parse('https://fakestoreapi.com/products');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List jsonResponse = jsonDecode(response.body);
        List<ListOfImage> tempReturnValue =
            jsonResponse.map((data) => ListOfImage.fromJson(data)).toList();
        returnValue = tempReturnValue.map((ListOfImage data) {
          String title = data.title ?? '';
          String image = data.image ?? '';
          return ImageList(title, image, '');
        }).toList();
      }
    } on Exception catch (e) {
      debugPrint('========= > $e');
    }

    setState(() {
      listOfImageValue = returnValue;
      tempArray = listOfImageValue;
      isLoad = false;
    });
  }

  Future<void> permissionHandler() async {
    await Permission.storage.request();
  }

  @override
  void initState() {
    permissionHandler();
    fetchData();
    super.initState();
  }

  Future<void> convertCropPath(String url, int i) async {
    if (url != '') {
      if (url != '') {
        var status = await Permission.storage.status;
        if (status.isGranted) {
          var response = await http.get(Uri.parse(url));
          var documentDirectory = await getApplicationDocumentsDirectory();
          var firstPath = "${documentDirectory.path}/images";
          var filePathAndName = '${documentDirectory.path}/images/pic.jpg';
          await Directory(firstPath).create(recursive: true);
          File file = File(filePathAndName);
          file.writeAsBytesSync(response.bodyBytes);
          cropImagePath(file.path, i);
        } else {
          if (!(await Permission.storage.request().isGranted)) {
            await openAppSettings();
          }
        }
      }
    }
  }

  Future<String> convertUrlToPath(String url) async {
    String returnPath = '';
    if (url != '') {
      var response = await http.get(Uri.parse(url));
      var documentDirectory = await getApplicationDocumentsDirectory();
      var firstPath = "${documentDirectory.path}/images";
      var filePathAndName = '${documentDirectory.path}/images/pic.jpg';
      await Directory(firstPath).create(recursive: true);
      File file = File(filePathAndName);
      file.writeAsBytesSync(response.bodyBytes);
      returnPath = file.path;
    }
    return returnPath;
  }

  Future<void> cropImagePath(String pickPath, int i) async {
    if (pickPath != '') {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickPath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
                const CroppieViewPort(width: 480, height: 480, type: 'circle'),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() => tempArray[i].filePath = croppedFile.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {},
          child: const Icon(
            Icons.menu,
            color: Colors.black,
          ),
        ),
        title: const Text(
          "Home",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      body: bodyView(),
    );
  }

  Widget bodyView() {
    if (isLoad) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          tempArray = listOfImageValue
                              .where((item) => (item.title ?? '')
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Anything...',
                        prefixIcon: IconButton(
                          iconSize: 30,
                          icon: const Icon(Icons.search),
                          onPressed: () {},
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: tempArray.length,
                          itemBuilder: (context, i) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.0),
                                  color: Colors.grey.shade50,
                                  shape: BoxShape.rectangle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.grey.shade300.withOpacity(0.6),
                                      spreadRadius: 3.0,
                                      blurRadius: 3,
                                      offset: const Offset(3.0, 3.0),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if ((tempArray[i].image ?? '') != '')
                                        SizedBox(
                                          height: 90,
                                          width: 90,
                                          child: imageView(i),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                          child: Text(
                                            tempArray[i].title ?? "",
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => downloadFromUrl(
                                            tempArray[i].image ?? ''),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.download),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => convertCropPath(
                                          tempArray[i].image ?? '',
                                          i,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.crop),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        if (isLoader) const Center(child: CircularProgressIndicator())
      ],
    );
  }

  Widget imageView(int i) {
    if (tempArray[i].filePath != '') {
      return Image.file(File(tempArray[i].filePath ?? ''));
    } else {
      return CachedNetworkImage(imageUrl: tempArray[i].image ?? '');
    }
  }
}

class ImageList {
  String? title;
  String? image;
  String? filePath;

  ImageList(this.title, this.image, this.filePath);
}

class ListOfImage {
  int? id;
  String? title;
  dynamic price;
  String? description;
  String? category;
  String? image;
  dynamic rating;

  ListOfImage(
      {this.id,
      this.title,
      this.price,
      this.description,
      this.category,
      this.image,
      this.rating});

  ListOfImage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    price = json['price'];
    description = json['description'];
    category = json['category'];
    image = json['image'];
    rating = json['rating'] != null ? Rating.fromJson(json['rating']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['price'] = price;
    data['description'] = description;
    data['category'] = category;
    data['image'] = image;
    if (rating != null) {
      data['rating'] = rating!.toJson();
    }
    return data;
  }
}

class Rating {
  dynamic rate;
  int? count;

  Rating({this.rate, this.count});

  Rating.fromJson(Map<String, dynamic> json) {
    rate = json['rate'];
    count = json['count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rate'] = rate;
    data['count'] = count;
    return data;
  }
}
