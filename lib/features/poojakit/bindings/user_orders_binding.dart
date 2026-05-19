import 'package:get/get.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';
import 'package:satya_devotte_app/features/poojakit/state/user_orders_controller.dart';

class UserOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserOrdersController>(
      () => UserOrdersController(Get.find<PoojaKitRepository>()),
    );
  }
}
