import 'package:common/core/error/exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/model/supplier/param.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/domain/repositories/supplier_repository.dart';
import 'package:pos/presentation/supplier/info/supplier_info_view_model.dart';

class FakeSupplierRepository implements SupplierRepository {
  final Supplier? info;
  final Object? throws;
  SupplierParam? updatedInfoParam;

  FakeSupplierRepository({this.info, this.throws});

  @override
  Future<Supplier> getSupplierInfo() async {
    final error = throws;
    if (error != null) {
      throw error;
    }
    return info ?? buildSupplier('1');
  }

  @override
  Future<Supplier> updateSupplierInfo(SupplierParam param) async {
    final error = throws;
    if (error != null) {
      throw error;
    }
    updatedInfoParam = param;
    return Supplier(
        id: '1',
        name: param.name,
        address: param.address,
        phone: param.phone,
        taxId: param.taxId);
  }

  @override
  Future<Supplier> createSupplier(SupplierParam param) =>
      throw UnimplementedError();

  @override
  Future<List<Supplier>> getSuppliers() => throw UnimplementedError();

  @override
  Future<List<Supplier>> getLocalSuppliers() => throw UnimplementedError();

  @override
  Future<Supplier> getSupplierById(String supplierId) =>
      throw UnimplementedError();

  @override
  Future<Supplier?> getLocalSupplierById(String supplierId) =>
      throw UnimplementedError();

  @override
  Future<Supplier> updateSupplierById(String supplierId, SupplierParam param) =>
      throw UnimplementedError();

  @override
  Future<Supplier> removeSupplierById(String supplierId) =>
      throw UnimplementedError();
}

/// A shop with no profile yet: loads answer 404 until a save succeeds.
class _NoProfileYetRepository extends FakeSupplierRepository {
  Supplier? _saved;

  @override
  Future<Supplier> getSupplierInfo() async {
    final saved = _saved;
    if (saved == null) {
      throw const NotFoundException(
          message: 'ไม่พบข้อมูลที่ต้องการ', code: 'SY-404-002');
    }
    return saved;
  }

  @override
  Future<Supplier> updateSupplierInfo(SupplierParam param) async {
    final saved = await super.updateSupplierInfo(param);
    _saved = saved;
    return saved;
  }
}

Supplier buildSupplier(String id) {
  return Supplier(id: id, name: 'name-$id', address: '', phone: '', taxId: '');
}

SupplierParam buildParam() {
  return SupplierParam(
      name: 'ร้านยาใหม่', address: 'เชียงใหม่', phone: '053123456', taxId: '');
}

SupplierInfoViewModel buildViewModel(SupplierRepository repo) {
  return SupplierInfoViewModel(
    supplierRepo: repo,
  );
}

void main() {
  test('getSupplierInfo populates the supplier', () async {
    final vm = buildViewModel(FakeSupplierRepository(info: buildSupplier('5')));

    await vm.getSupplierInfo();

    expect(vm.state.value.supplier?.id, '5',
        reason: 'the form renders this, so it belongs in state');
  });

  test('a failed load emits an error and leaves the form empty', () async {
    final vm = buildViewModel(
      FakeSupplierRepository(
          throws: const NetworkException(message: 'offline')),
    );
    final errors = <String>[];
    vm.errors.listen(errors.add);

    await vm.getSupplierInfo();
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.value.supplier, isNull);
    expect(errors, hasLength(1));
  });

  test('no shop profile yet is not an error: the form is empty, with a hint',
      () async {
    // Arrange: pos-api answers 404 until the profile is first saved
    final vm = buildViewModel(
      FakeSupplierRepository(
          throws: const NotFoundException(
              message: 'ไม่พบข้อมูลที่ต้องการ', code: 'SY-404-002')),
    );
    final errors = <String>[];
    vm.errors.listen(errors.add);

    // Act
    await vm.getSupplierInfo();
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(errors, isEmpty);
    expect(vm.state.value.supplier, isNull);
    expect(vm.state.value.hint, 'ยังไม่มีข้อมูลร้านค้า กรอกแล้วกดบันทึก');
  });

  test('a profile that loads shows no hint', () async {
    final vm = buildViewModel(FakeSupplierRepository(info: buildSupplier('5')));

    await vm.getSupplierInfo();

    expect(vm.state.value.hint, isNull);
  });

  test('a save emits the updated record once', () async {
    final repo = FakeSupplierRepository();
    final vm = buildViewModel(repo);
    final updated = <Supplier>[];
    vm.updated.listen(updated.add);

    await vm.updateSupplierInfo(buildParam());
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.value.saving, isFalse);
    expect(updated.single.name, 'ร้านยาใหม่');
    expect(repo.updatedInfoParam?.address, 'เชียงใหม่');
  });

  test('a failed save emits an error and no outcome', () async {
    final vm = buildViewModel(
      FakeSupplierRepository(
          throws: const NetworkException(message: 'offline')),
    );
    final updated = <Supplier>[];
    final errors = <String>[];
    vm.updated.listen(updated.add);
    vm.errors.listen(errors.add);

    await vm.updateSupplierInfo(buildParam());
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.value.saving, isFalse);
    expect(updated, isEmpty);
    expect(errors, hasLength(1));
  });

  test('the outcome is delivered once, with nothing to clear', () async {
    final vm = buildViewModel(FakeSupplierRepository());
    final updated = <Supplier>[];
    vm.updated.listen(updated.add);

    await vm.updateSupplierInfo(buildParam());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(updated, hasLength(1));
  });

  test('the first profile saved takes the no-profile hint away', () async {
    // Arrange
    final vm = buildViewModel(_NoProfileYetRepository());
    await vm.getSupplierInfo();
    expect(vm.state.value.hint, noShopProfileHint);

    // Act
    await vm.updateSupplierInfo(buildParam());

    // Assert
    expect(vm.state.value.hint, isNull);
  });

  test('a later load that finds the profile takes the hint away', () async {
    // Arrange
    final repo = _NoProfileYetRepository();
    final vm = buildViewModel(repo);
    await vm.getSupplierInfo();
    await repo.updateSupplierInfo(buildParam());

    // Act
    await vm.getSupplierInfo();

    // Assert
    expect(vm.state.value.hint, isNull);
    expect(vm.state.value.supplier?.name, 'ร้านยาใหม่');
  });
}
