import 'package:satya_devotte_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, dynamic>> getProfile() {
    return _remoteDataSource.getProfile();
  }
}
