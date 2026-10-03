import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

class MembersState {
  final List<AppUser> members;
  final bool loading;
  final bool failed;

  const MembersState({
    this.members = const [],
    this.loading = true,
    this.failed = false,
  });

  /// Display name for [memberId], falling back to a generic label.
  String nameOf(String memberId) {
    for (final m in members) {
      if (m.id == memberId) return m.name;
    }
    return AppStrings.unknownMember;
  }
}

/// Members assigned to the signed-in trainer, loaded once and shared by
/// the dashboard, members list and requests inbox.
class MembersCubit extends Cubit<MembersState> {
  final AuthService _auth;
  final AppUser me;

  MembersCubit({required AuthService auth, required this.me})
      : _auth = auth,
        super(const MembersState()) {
    load();
  }

  Future<void> load() async {
    emit(const MembersState());
    try {
      emit(MembersState(members: await _auth.membersOf(me.id), loading: false));
    } catch (e) {
      WtfLog.d(LogTag.auth, 'members load failed: $e');
      emit(const MembersState(loading: false, failed: true));
    }
  }
}
