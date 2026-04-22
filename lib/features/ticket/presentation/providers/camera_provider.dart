import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/shared_preferences_service.dart';

final cameraServiceProvider = Provider((ref) => CameraService());

final cameraPermissionProvider = FutureProvider<bool>((ref) async {
  final cameraService = ref.watch(cameraServiceProvider);
  return await cameraService.isCameraPermissionGranted();
});

final requestCameraPermissionProvider = FutureProvider<bool>((ref) async {
  final cameraService = ref.watch(cameraServiceProvider);
  return await cameraService.requestCameraPermission();
});

final capturePhotoProvider = FutureProvider<XFile?>((ref) async {
  final cameraService = ref.watch(cameraServiceProvider);
  return await cameraService.capturePhoto();
});

final pickFromGalleryProvider = FutureProvider<XFile?>((ref) async {
  final cameraService = ref.watch(cameraServiceProvider);
  return await cameraService.pickFromGallery();
});

final savePhotoProvider = FutureProvider.family<void, XFile>((ref, photo) async {
  await SharedPreferencesService.savePhoto(photo);
});

final getSavedPhotoProvider = FutureProvider<String?>((ref) async {
  return await SharedPreferencesService.getPhoto();
});

final clearPhotoProvider = FutureProvider<void>((ref) async {
  await SharedPreferencesService.clearPhoto();
});
