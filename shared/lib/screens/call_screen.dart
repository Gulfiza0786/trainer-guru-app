import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/call_cubit.dart';
import '../models/app_user.dart';
import '../models/room_meta.dart';
import '../services/call_service.dart';
import '../services/log_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';

/// Video call flow (spec §3D): pre-join device check → 2-tile grid call
/// with mute/video/flip/end → post-call sheet via [onEnded].
class CallScreen extends StatelessWidget {
  final AppUser me;
  final AppUser peer;
  final RoomMeta room;
  final Color roleColor;
  final LogService logService;
  final AgoraCallService callService;

  /// Invoked after the call ends and the SessionLog is written.
  final void Function(BuildContext context, CallEnded state) onEnded;

  const CallScreen({
    super.key,
    required this.me,
    required this.peer,
    required this.room,
    required this.roleColor,
    required this.logService,
    required this.callService,
    required this.onEnded,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CallCubit(call: callService, logs: logService, me: me, room: room)
            ..startDeviceCheck(),
      child: BlocConsumer<CallCubit, CallState>(
        listener: (context, state) {
          if (state is CallEnded) onEnded(context, state);
        },
        builder: (context, state) => switch (state) {
          CallIdle() || CallJoining() => const _DarkLoader(),
          final CallPreviewing s => _PreJoinView(
            state: s,
            service: callService,
          ),
          final CallInRoom s => _InCallView(
            state: s,
            service: callService,
            me: me,
            peer: peer,
            roleColor: roleColor,
          ),
          CallEnded() => const _DarkLoader(),
          CallFailed(:final message) => _FailureView(message: message),
        },
      ),
    );
  }
}

// ── Shared dark loader ────────────────────────────────────────────────────────

class _DarkLoader extends StatelessWidget {
  const _DarkLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.slate900,
      body: Center(child: CircularProgressIndicator(color: AppColors.white)),
    );
  }
}

// ── Failure view ──────────────────────────────────────────────────────────────

class _FailureView extends StatelessWidget {
  final String message;
  const _FailureView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        backgroundColor: AppColors.slate900,
        foregroundColor: AppColors.white,
        title: Text(
          AppStrings.joinCall,
          style: AppTextStyles.h2.copyWith(color: AppColors.white),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_rounded,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: Gap.s20),
              Text(
                message,
                style: AppTextStyles.body.copyWith(color: AppColors.slate300),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.s24),
              FilledButton.icon(
                onPressed: () => context.read<CallCubit>().startDeviceCheck(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pre-join device check ─────────────────────────────────────────────────────

class _PreJoinView extends StatelessWidget {
  final CallPreviewing state;
  final AgoraCallService service;

  const _PreJoinView({required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CallCubit>();
    return Scaffold(
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        title: Text(
          AppStrings.deviceCheck,
          style: AppTextStyles.h2.copyWith(color: AppColors.white),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.s16),
          child: Column(
            children: [
              // Camera preview
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: state.camOn
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: service.engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : Container(
                          color: AppColors.slate800,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.slate700,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.videocam_off_rounded,
                                  size: 36,
                                  color: AppColors.slate400,
                                ),
                              ),
                              const SizedBox(height: Gap.s12),
                              Text(
                                'Camera off',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: Gap.s20),

              Text(
                AppStrings.joinPrompt,
                style: AppTextStyles.body.copyWith(color: AppColors.slate400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.s20),

              // Toggle controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlButton(
                    icon: state.micOn
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: state.micOn ? 'Mic on' : 'Mic off',
                    active: state.micOn,
                    onTap: cubit.toggleMic,
                  ),
                  const SizedBox(width: Gap.s20),
                  _ControlButton(
                    icon: state.camOn
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: state.camOn ? 'Cam on' : 'Cam off',
                    active: state.camOn,
                    onTap: cubit.toggleCam,
                  ),
                ],
              ),
              const SizedBox(height: Gap.s20),

              ElevatedButton.icon(
                onPressed: cubit.join,
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text(AppStrings.joinCall),
              ),
              const SizedBox(height: Gap.s8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── In-call UI ────────────────────────────────────────────────────────────────

class _InCallView extends StatelessWidget {
  final CallInRoom state;
  final AgoraCallService service;
  final AppUser me;
  final AppUser peer;
  final Color roleColor;

  const _InCallView({
    required this.state,
    required this.service,
    required this.me,
    required this.peer,
    required this.roleColor,
  });

  Widget _videoTile({
    required Widget video,
    required String label,
    required bool isLocal,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          video,
          // Name label
          Positioned(
            left: Gap.s8,
            bottom: Gap.s8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: Gap.s4,
              ),
              decoration: BoxDecoration(
                color: AppColors.slate900.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.white),
              ),
            ),
          ),
          // Local "you" dot indicator
          if (isLocal)
            Positioned(
              right: Gap.s8,
              top: Gap.s8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyTile(String message) {
    return Container(
      color: AppColors.slate800,
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.slate400),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CallCubit>();
    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.s8),
          child: Stack(
            children: [
              Column(
                children: [
                  // Remote tile
                  Expanded(
                    child: _videoTile(
                      label: peer.name,
                      isLocal: false,
                      video: state.remoteUid != null
                          ? AgoraVideoView(
                              controller: VideoViewController.remote(
                                rtcEngine: service.engine,
                                canvas: VideoCanvas(uid: state.remoteUid),
                                connection: RtcConnection(
                                  channelId: cubit.room.channelId,
                                ),
                              ),
                            )
                          : _emptyTile(
                              state.peerLeft
                                  ? AppStrings.peerLeft
                                  : 'Waiting for ${peer.name}…',
                            ),
                    ),
                  ),
                  const SizedBox(height: Gap.s8),
                  // Local tile
                  Expanded(
                    child: _videoTile(
                      label: '${me.name} (you)',
                      isLocal: true,
                      video: state.camOn
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: service.engine,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : _emptyTile('Camera off'),
                    ),
                  ),
                  const SizedBox(height: Gap.s12),
                  // Controls
                  _CallControls(state: state, cubit: cubit),
                  const SizedBox(height: Gap.s8),
                ],
              ),
              // Reconnecting overlay
              if (state.reconnecting)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: AppColors.slate900.withValues(alpha: 0.75),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.white,
                            ),
                            const SizedBox(height: Gap.s16),
                            Text(
                              AppStrings.reconnecting,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Call control row ──────────────────────────────────────────────────────────

class _CallControls extends StatelessWidget {
  final CallInRoom state;
  final CallCubit cubit;

  const _CallControls({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s20,
        vertical: Gap.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.slate800.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: state.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: state.micOn ? 'Mute' : 'Unmute',
            active: state.micOn,
            onTap: cubit.toggleMic,
          ),
          _ControlButton(
            icon: state.camOn
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: state.camOn ? 'Video' : 'No video',
            active: state.camOn,
            onTap: cubit.toggleCam,
          ),
          _ControlButton(
            icon: Icons.cameraswitch_rounded,
            label: 'Flip',
            active: true,
            onTap: cubit.flipCamera,
          ),
          _ControlButton(
            icon: Icons.call_end_rounded,
            label: 'End',
            active: true,
            color: AppColors.error,
            onTap: cubit.endCall,
          ),
        ],
      ),
    );
  }
}

// ── Round control button ──────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (active ? AppColors.slate600 : AppColors.slate700);
    final fg = active || color != null ? AppColors.white : AppColors.slate400;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(
                  alpha: active && color == null ? 0.12 : 0,
                ),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: fg, size: 22),
          ),
          const SizedBox(height: Gap.s4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}
