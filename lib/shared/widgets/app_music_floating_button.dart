import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:satya_devotte_app/core/services/app_music_service.dart';

import 'package:satya_devotte_app/shared/widgets/app_music_control_button.dart';



/// Global pause/play control for background app music (mobile only).

class AppMusicFloatingButton extends StatelessWidget {

  const AppMusicFloatingButton({super.key});



  @override

  Widget build(BuildContext context) {

    if (kIsWeb) return const SizedBox.shrink();



    final music = Get.find<AppMusicService>();

    final bottomInset = MediaQuery.paddingOf(context).bottom;



    return Obx(() {

      if (!music.showFab.value) return const SizedBox.shrink();



      return Positioned(

        right: 16,

        bottom: bottomInset + 88,

        child: const AppMusicControlButton(showShadow: false),

      );

    });

  }

}


