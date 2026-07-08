import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_response.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/support_message_model.dart';
import '../../data/repositories/support_repository.dart';

final mySupportMessagesProvider =
    FutureProvider.autoDispose<PaginatedResponse<SupportMessageModel>>(
  (ref) async {    final session = ref.watch(authControllerProvider).session;
    if (session == null) {
      throw StateError('You must be logged in to view feedback.');
    }

    return ref.watch(supportRepositoryProvider).getMyMessages();
  },
);
