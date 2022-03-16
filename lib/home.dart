// ignore_for_file: unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, sized_box_for_whitespace, unused_label, unnecessary_string_interpolations, unnecessary_null_comparison, unused_element, unnecessary_new, unused_field, await_only_futures, deprecated_member_use, unnecessary_brace_in_string_interps, unused_local_variable, prefer_typing_uninitialized_variables
import 'dart:convert';
import 'dart:io';

import 'package:intl/date_symbol_data_file.dart';
import 'package:inventaris_barang_smarteschool/database/firebase.dart';
import 'package:inventaris_barang_smarteschool/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventaris_barang_smarteschool/custom_color.dart';
import 'package:inventaris_barang_smarteschool/model/barang.dart';
import 'package:inventaris_barang_smarteschool/model/lokasi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventaris_barang_smarteschool/beranda_page.dart';
import 'package:inventaris_barang_smarteschool/akun_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:inventaris_barang_smarteschool/fungsi/rupiah.dart';
import 'package:intl/intl.dart';
import 'package:inventaris_barang_smarteschool/model/user.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late AnimationController controller;
  String? _token;
  User? _user;
  Barang? _barang;
  Lokasi? _lokasi;
  String? scanResult;

  int currentTab = 0;
  final List<Widget> screens = [
    BerandaPage(),
    AkunPage(),
  ];

  final _productNameController = TextEditingController();
  final _productMerkController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _productFromController = TextEditingController();
  final _specProductController = TextEditingController();
  final _priceProductController = TextEditingController();
  final _ownerProductController = TextEditingController();
  final _totalProductController = TextEditingController();
  final _goodProductController = TextEditingController();
  final badProductController = TextEditingController();
  final _locationProductController = TextEditingController();
  DateTime _productBuyDate = DateTime.now();
  final _setTimeController = TextEditingController();
  String dropdownValue = 'Milik';
  int? lokasiDropdownValue;
  File? _imageFile;
  String? imagePath;

  Future<void> fetchBarang(int barangId) async {
    final response = await http.get(
        Uri.parse('https://server-ujian.smarteschool.net/barang/$barangId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://smkn26jkt.smarteschool.id',
          'Authorization': 'Bearer $_token',
        });

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      setState(() {
        _barang = Barang.fromJson(jsonDecode(response.body)['barang']);

        if (_barang != null) {
          _showCustomDialog(context);
          _productNameController.text = _barang!.nama;
          _productMerkController.text = _barang!.merk;
          _productCodeController.text = _barang!.kodeBarang;
          _productFromController.text = _barang!.asal;
          _specProductController.text = _barang!.deskripsi;
          _priceProductController.text = _barang!.harga;
          _locationProductController.text = _barang!.mLokasiId.toString();
          _ownerProductController.text = _barang!.namaPemilik.toString();
          _totalProductController.text = _barang!.jumlah.toString();
          _goodProductController.text = _barang!.baik.toString();
          badProductController.text = _barang!.rusak.toString();
          _productBuyDate = _barang!.tahunBeli;
          // dropdownValue = _barang!.kepemilikan;
          lokasiDropdownValue = _barang!.mLokasiId;
          _setTimeController.text =
              DateFormat("EEEE, d MMMM yyyy").format(_productBuyDate);
        }
      });
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.toString())));
    }
  }

  Future<void> fetchUser() async {
    final response = await http.get(
        Uri.parse('https://server-ujian.smarteschool.net/profil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://smkn26jkt.smarteschool.id',
          'Authorization': 'Bearer $_token',
        });

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      setState(() {
        _user = User.fromJson(jsonDecode(response.body)['user']);
      });
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.toString())));
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  Future<void> updateBarang() async {
    // String? urlPhoto = await uploadFile(_imageFile!.path);
    final response = await http.put(
        Uri.parse(
            'https://server-ujian.smarteschool.net/barang/${_barang!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://smkn26jkt.smarteschool.id',
          'Authorization': 'Bearer $_token',
        },
        body:
            '{"nama": "${_productNameController.text}", "kode_barang": "${_productCodeController.text}", "merk": "${_productMerkController.text}", "tahun_beli": "${DateFormat("yyyy-MM-dd").format(_productBuyDate)}", "asal": "${_productFromController.text}", "deskripsi":"${_specProductController.text}", "harga": "${_priceProductController.text}", "jumlah": "${_totalProductController.text}", "baik": "${_goodProductController.text}", "rusak": "${badProductController.text}", "nama_pemilik": "${_ownerProductController.text}", "m_lokasi_id": "${lokasiDropdownValue}", "kepemilikan": "${dropdownValue.toLowerCase()}", "nota":"${_barang!.nota}", "foto": "${_barang!.foto}"');

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      Navigator.pop(context);
      fetchBarang(_barang!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Data Berhasil diubah"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              right: 20,
              left: 20),
        ),
      );
    } else {
      Navigator.pop(context);
      // If the server did not return a 200 OK response,
      // then throw an exception.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Anda tidak memiliki akses untuk mengedit"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: 20),
      ));
    }
  }

  List _dataLokasi = [];
  void fetchLokasi() async {
    final response = await http.get(
        Uri.parse('https://server-ujian.smarteschool.net/lokasi'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://smkn26jkt.smarteschool.id',
          'Authorization': 'Bearer $_token',
        });

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      setState(() {
        // _lokasi = Lokasi.fromJson(jsonDecode(response.body));
        var dataLokasi = jsonDecode(response.body);
        _dataLokasi = dataLokasi['lokasi']['data'];
      });
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.toString())));
    }
  }

  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = BerandaPage();

  _getToken() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    _token = sharedPreferences.getString("token");
    fetchUser();
    fetchLokasi();
  }

  _selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _productBuyDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2025),
    );
    if (selected != null && selected != _productBuyDate) {
      setState(() {
        _productBuyDate = selected;

        _setTimeController.text =
            DateFormat("EEEE, d MMMM yyyy").format(selected);
      });
    }
  }

  _getFromGallery() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  _getFromCamera() async {
    PickedFile? pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
      maxWidth: 200,
      maxHeight: 200,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // initializeDateFormatting();
  @override
  void initState() {
    _getToken();
    super.initState();
    controller = BottomSheet.createAnimationController(this);
    controller.duration = Duration(milliseconds: 500);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: bucket,
        child: currentScreen,
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: scanBarcode,
          child: SvgPicture.asset(
            "assets/images/icon-scan.svg",
            width: 40,
            height: 40,
            color: Colors.white,
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: Container(
          color: birumuda,
          child: Container(
            padding: EdgeInsets.only(top: 2.0, bottom: 2.0),
            // decoration: BoxDecoration(border: Border.all(color: Colors.blue)),

            // color: Colors.blue,
            decoration: BoxDecoration(
                color: primaryColor,
                // border: Border.all(),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25))),
            height: MediaQuery.of(context).size.height * 0.058,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Wrap(
                      spacing: 100,
                      children: [
                        MaterialButton(
                          // minWidth: 210,
                          onPressed: () {
                            setState(() {
                              currentScreen = BerandaPage();
                              currentTab = 0;
                            });
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.space_dashboard_rounded,
                                color: currentTab == 0
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                              Text(
                                "Beranda",
                                style: TextStyle(
                                  color: currentTab == 0
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                ),
                              )
                            ],
                          ),
                        ),
                        MaterialButton(
                          // minWidth: 210,
                          onPressed: () {
                            setState(() {
                              currentScreen = AkunPage();
                              currentTab = 1;
                            });
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_circle_rounded,
                                color: currentTab == 1
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                              Text(
                                "Akun",
                                style: TextStyle(
                                  color: currentTab == 1
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future scanBarcode() async {
    String scanResult;

    try {
      scanResult = await FlutterBarcodeScanner.scanBarcode(
          "#FF2680EB", "Batal", true, ScanMode.BARCODE);

      final barangId = int.tryParse(scanResult);

      if (barangId != null && barangId != -1) {
        fetchBarang(barangId);
      }
    } on PlatformException {
      scanResult = 'Failed to get platform version';
    }

    if (!mounted) return;

    setState(() => this.scanResult = scanResult);
  }

  void _showCustomDialog(BuildContext context) => showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.white,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation animation,
          Animation secondaryAnimation) {
        return Scaffold(
          body: Container(
              color: Colors.white,
              // height: 1000,
              child: SafeArea(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Container(
                            padding: EdgeInsets.only(left: 5.0),
                            height: 40,
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: Offset(0, 2), // c
                                    blurStyle: BlurStyle.normal,
                                  ),
                                ],
                                color: birumuda,
                                // border: Border.all(),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Home()),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                  Text(
                                    'Kembali',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.85,
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: Offset(0, 2), // c
                                  blurStyle: BlurStyle.normal,
                                ),
                              ],
                              color: birumuda,
                              // border: Border.all(),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 20.0),
                          child: Scrollbar(
                            child: ListView(
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Detail Informasi Barang',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 20)),
                                          // if (_user != null)
                                          _user!.role == 'admin'
                                              ? InkWell(
                                                  onTap: () => showModalBottomSheet(
                                                      transitionAnimationController:
                                                          controller,
                                                      isScrollControlled: true,
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                          30))),
                                                      context: context,
                                                      builder: (context) =>
                                                          buildSheet()),
                                                  child: Container(
                                                    width: 35,
                                                    height: 35,
                                                    decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.2),
                                                            spreadRadius: 2,
                                                            blurRadius: 2,
                                                            offset: Offset(
                                                                0, 2), // c
                                                            blurStyle: BlurStyle
                                                                .normal,
                                                          ),
                                                        ],
                                                        color: Colors.white,
                                                        // border: Border.all(),
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    30))),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.edit,
                                                        color: Colors.grey,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 35,
                                                  height: 35,
                                                  decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.2),
                                                          spreadRadius: 2,
                                                          blurRadius: 2,
                                                          offset:
                                                              Offset(0, 2), // c
                                                          blurStyle:
                                                              BlurStyle.normal,
                                                        ),
                                                      ],
                                                      color: Colors.white,
                                                      // border: Border.all(),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  30))),
                                                  child: Center(
                                                    child: IconButton(
                                                      onPressed: () {},
                                                      icon: Icon(Icons
                                                          .local_grocery_store_rounded),
                                                      color: Colors.grey,
                                                      iconSize: 20,
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                      SizedBox(height: 40),
                                      Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: _barang!.foto == null
                                              ? Image(
                                                  image: AssetImage(
                                                      "assets/images/icon v1.png"),
                                                  width: 120,
                                                  height: 120,
                                                )
                                              : Image.network(
                                                  (_barang!.foto).toString(),
                                                  width: 200,
                                                  height: 200,
                                                ),
                                        ),
                                      ),
                                      SizedBox(height: 60),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Nama Barang",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              _barang!.nama,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 5),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Merk",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              _barang!.merk,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 5),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "No. Kode Barang",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              _barang!.kodeBarang,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 5),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Asal usul",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              _barang!.asal,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 5),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Spesifikasi",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              _barang!.deskripsi,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 5),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Harga",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              CurrencyFormat.convertToIdr(
                                                  int.tryParse(_barang!.harga)),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 5),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Tanggal Beli",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              new DateFormat(
                                                      "EEEE, d MMMM yyyy")
                                                  .format(_barang!.tahunBeli),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 5),
                                      // if (_barang != null)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Kepemilikan",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15),
                                          ),
                                          Text(
                                            _barang!.kepemilikan == null
                                                ? "-"
                                                : "${_barang!.kepemilikan}",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Nama Pemilik/Peminjam",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15),
                                          ),
                                          Text(
                                            "${_barang!.namaPemilik ?? "-"}",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      if (_barang != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Lokasi",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              _barang!.lokasi,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      SizedBox(height: 50),
                                      Center(
                                        child: Table(
                                          defaultColumnWidth:
                                              FixedColumnWidth(80.0),
                                          // border: TableBorder.all(
                                          //     color: Colors.black,
                                          //     style: BorderStyle.solid,
                                          //     width: 2),
                                          children: [
                                            TableRow(children: [
                                              Column(children: [
                                                Text('Jumlah',
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.w800))
                                              ]),
                                              Column(children: [
                                                Text('Baik',
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.w800))
                                              ]),
                                              Column(children: [
                                                Text('Rusak',
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.w800))
                                              ]),
                                            ]),
                                            TableRow(children: [
                                              Column(children: [
                                                Text(
                                                  _barang!.jumlah.toString(),
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15),
                                                )
                                              ]),
                                              Column(children: [
                                                Text(
                                                  _barang!.baik.toString(),
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15),
                                                )
                                              ]),
                                              Column(children: [
                                                Text(
                                                  _barang!.rusak.toString(),
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15),
                                                )
                                              ]),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ])
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        );
      });

  Widget buildSheet() => StatefulBuilder(
        builder: (context, localSetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.96,
            padding: EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 30.0),
            child: Scrollbar(
              child: ListView(
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ubah Barang',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 20)),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close_rounded))
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () => showModalBottomSheet(
                              transitionAnimationController: controller,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(30))),
                              context: context,
                              builder: (context) => modalFoto()),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: birumuda,
                                  // border: Border.all(),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              child: Row(
                                children: [
                                  if (_barang!.foto != null)
                                    // ?
                                    Image.network(
                                      (_barang!.foto).toString(),
                                      width: 200,
                                      height: 200,
                                    ),
                                  //     Image.file(
                                  //         _imageFile!,
                                  //         width: 200,
                                  //         height: 200,
                                  //       )
                                  //     : Image(
                                  //         image: AssetImage(
                                  //             'assets/images/icon v1.png')),
                                  IconButton(
                                      onPressed: null, icon: Icon(Icons.edit))
                                ],
                              )),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Nama Barang",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _productMerkController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Merk",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _productCodeController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "No. Kode Barang",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _productFromController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Asal Usul",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _specProductController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Spesifikasi",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _priceProductController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Harga",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    onTap: () => _selectDate(context),
                    readOnly: true,
                    controller: _setTimeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Tanggal Beli",
                    ),
                  ),
                  SizedBox(height: 15),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      //background color of dropdown button
                      border: Border.all(
                        color: Colors.black38,
                      ), //border of dropdown button
                      borderRadius: BorderRadius.circular(
                          10), //border raiuds of dropdown button
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        hint: Text("Update Kepemilikan"),
                        value: dropdownValue,
                        elevation: 16,
                        // style: const TextStyle(color: Colors.deepPurple),
                        underline: Container(
                          height: 2,
                          // color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue = newValue!;
                          });
                          localSetState(() {
                            dropdownValue = newValue!;
                          });
                        },
                        items: <String>[
                          'Milik',
                          'Sewa',
                          'Pinjam',
                          'Bukan Milik'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _ownerProductController,
                    enabled: dropdownValue != "Milik",
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Nama Pemilik/Peminjam",
                    ),
                  ),
                  SizedBox(height: 15),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      //background color of dropdown button
                      border: Border.all(
                        color: Colors.black38,
                      ), //border of dropdown button
                      borderRadius: BorderRadius.circular(
                          10), //border raiuds of dropdown button
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton(
                        hint: Text("Update Lokasi"),
                        value: lokasiDropdownValue,
                        elevation: 16,
                        // style: const TextStyle(color: Colors.  ),
                        underline: Container(
                          height: 2,
                          // color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (value) {
                          setState(() {
                            lokasiDropdownValue = value as int?;
                          });
                          localSetState(() {
                            lokasiDropdownValue = value as int?;
                          });
                        },
                        items: _dataLokasi.map((item) {
                          return DropdownMenuItem(
                            child: Text(item['nama']),
                            value: item['id'],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // TextFormField(
                  //   controller: _locationProductController,
                  //   enabled: false,
                  //   decoration: InputDecoration(
                  //     // fillColor: Colors.blue[100],
                  //     // filled: true,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10.0),
                  //     ),
                  //     labelText: "Lokasi",
                  //   ),
                  // ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _totalProductController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Jumlah Total",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _goodProductController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Jumlah Baik",
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: badProductController,
                    decoration: InputDecoration(
                      // fillColor: Colors.blue[100],
                      // filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "Jumlah Rusak",
                    ),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      )),
                    ),
                    child: Text(
                      'Simpan',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => updateBarang(),
                  )
                ],
              ),
            ),
          );
        },
      );

  Widget modalFoto() => Container(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Pilh media untuk mengambil foto',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 25)),
            SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width * 1,
              child: Column(
                children: [
                  ElevatedButton.icon(
                      onPressed: () {
                        _getFromGallery();
                      },
                      icon: Icon(Icons.image_sharp),
                      label: Text("Galeri")),
                  ElevatedButton.icon(
                      onPressed: () {
                        _getFromCamera();
                      },
                      icon: Icon(Icons.camera_alt_rounded),
                      label: Text("Kamera")),
                ],
              ),
            ),
          ],
        ),
      );
}