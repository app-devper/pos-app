// Package imports:
import 'package:common/config/app_config.dart';

// Project imports:
import 'languages.dart';

class LanguageTh extends Languages {
  final AppConfig config;

  LanguageTh({required this.config});

  @override
  String get appName => "Devper POS";

  @override
  String get homeTitle => config.name;

  @override
  String get productsTitle => "รายการสินค้า";

  @override
  String get productAddTitle => "เพิ่มสินค้า";

  @override
  String get productEditTitle => "แก้ไขสินค้า";

  @override
  String get productFindTitle => "ค้นหาสินค้า";

  @override
  String get changeLanguage => "เปลี่ยนภาษา";

  @override
  String get ordersTitle => "สรุปรายการ";

  @override
  String get orderSelectEndDate => "เลือกวันที่สิ้นสุด";

  @override
  String get orderSelectStartDate => "เลือกวันที่เริ่มต้น";

  @override
  String get orderDetailTitle => "รายละเอียดรายการ";

  @override
  String get orderHistoryTitle => "ประวัติรายการ";

  @override
  String get categoryTitle => "ประเภทสินค้า";

  @override
  String get categoryAddTitle => "เพิ่มประเภทสินค้า";

  @override
  String get categoryEditTitle => "แก้ไขประเภทสินค้า";

  @override
  String get changePasswordTitle => "เปลี่ยนรหัสผ่าน";

  @override
  String get userManageTitle => "จัดการผู้ใช้งาน";

  @override
  String get userAddTitle => "เพิ่มผู้ใช้งาน";

  @override
  String get userEditTitle => "แก้ไขผู้ใช้งาน";

  @override
  String get userInfoTitle => "ข้อมูลผู้ใช้งาน";

  @override
  String get customerAddTitle => "เพิ่มลูกค้า";

  @override
  String get customerEditTitle => "แก้ไขลูกค้า";

  @override
  String get customerTitle => "ข้อมูลลูกค้า";

  @override
  String get customerManageTitle => "จัดการลูกค้า";

  @override
  String get supplierInfoTitle => "ร้านของฉัน";

  @override
  String get receiveManageTitle => "รับสินค้า";

  @override
  String get receivesTitle => "รายการรับสินค้า";

  @override
  String get productsExpiredTitle => "รายการสินค้าหมดอายุ";

  @override
  String get productLotEditTitle => "แก้ไขล็อตสินค้า";

  @override
  String get stockCountsTitle => "นับสต็อก";

  @override
  String get stockCountManageTitle => "รายละเอียดการนับสต็อก";

  @override
  String get stockCountCreateTitle => "นับสต็อกใหม่";

  @override
  String get supplierAddTitle => "เพิ่มร้านค้า";

  @override
  String get supplierEditTitle => "แก้ไขร้านค้า";

  @override
  String get suppliersTitle => "จัดการร้านค้า";

  @override
  String get back => "ย้อนกลับ";

  @override
  String get clearSearch => "ล้างคำค้น";

  @override
  String get sortByBalance => "เรียงตามคงเหลือ";

  @override
  String get sortByName => "เรียงตามชื่อ";

  @override
  String get addSupplier => "เพิ่มร้านขายสินค้า";

  @override
  String get chooseProduct => "เลือกสินค้า";

  @override
  String removeCustomer(String name) => "นำลูกค้า $name ออก";

  @override
  String get moreCommands => "คำสั่งเพิ่มเติม";

  @override
  String get deleteReceive => "ลบใบรับสินค้า";

  @override
  String deleteReceiveLine(String name) => "ลบรายการ $name";

  @override
  String importedReceiveLine(String name) => "รายการ $name นำเข้าแล้ว";

  @override
  String get billReceipt => "ใบเสร็จ PDF";

  @override
  String get billReload => "โหลดบิลใหม่";

  @override
  String get billReturns => "ประวัติการคืนสินค้า";

  @override
  String get billDelete => "ลบบิล";

  @override
  String deleteBillLine(String name) => "ลบรายการ $name";

  @override
  String billLineHistory(String name) => "ประวัติการขาย $name";

  @override
  String returnBillLine(String name) => "คืนสินค้า $name";

  @override
  String oneLess(String name) => "ลดจำนวน $name";

  @override
  String oneMore(String name) => "เพิ่มจำนวน $name";

  @override
  String changeQuantity(String name) => "แก้ไขจำนวน $name";

  @override
  String allowOversell(String name) => "อนุญาตขายเกินสต็อก $name";

  @override
  String oversellAllowed(String name) => "อนุญาตขายเกินสต็อกแล้ว $name";

  @override
  String editLot(String lot) => "แก้ไขล็อต $lot";

  @override
  String lotOnHand(String lot) => "ปรับจำนวนคงเหลือ ล็อต $lot";

  @override
  String adjustLot(String lot) => "ปรับสต็อก ล็อต $lot";

  @override
  String unnumberedLot(int row, {String importDate = ''}) => importDate.isEmpty
      ? "ไม่มีเลข แถวที่ $row"
      : "ไม่มีเลข แถวที่ $row นำเข้า $importDate";

  @override
  String get saveStockCount => "บันทึกการนับสต็อก";

  @override
  String removeCountLine(String name) => "ลบรายการนับ $name";

  @override
  String get newStockCount => "เพิ่มการนับสต็อก";

  @override
  String get toggleFlash => "เปิดหรือปิดไฟแฟลช";

  @override
  String get switchCamera => "สลับกล้อง";

  @override
  String get addCategory => "เพิ่มหมวดหมู่";

  @override
  String get deleteCategory => "ลบหมวดหมู่";

  @override
  String get deleteSupplier => "ลบร้านขายสินค้า";

  @override
  String get downloadSalesCsv => "ดาวน์โหลดประวัติการขาย CSV";

  @override
  String get pickImportDate => "เลือกวันที่นำเข้า";

  @override
  String get pickExpiryDate => "เลือกวันหมดอายุ";

  @override
  String get scanBarcode => "สแกนบาร์โค้ด";

  @override
  String get saveButton => "บันทึก";

  @override
  String get addButton => "เพิ่ม";

  @override
  String get requireCustomerOrder => "ต้องระบุลูกค้าเมื่อขาย";
}
