import 'package:flutter/material.dart';
import 'dart:ui';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final String userName;

  /// When either callback is provided, the avatar becomes an account menu
  /// (Profile / Logout) that opens on its own tap, independent of the search
  /// [onTap]. When both are null, the avatar is a plain, non-interactive
  /// circle (backward-compatible).
  final VoidCallback? onProfile;
  final VoidCallback? onLogout;

  const SearchBarWidget({
    super.key,
    this.onTap,
    required this.userName,
    this.onProfile,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : "?";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,

        /// THIS FIXES THE BLACK TAP
        overlayColor:
        MaterialStateProperty.all(Colors.transparent),

        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,

        borderRadius: BorderRadius.circular(30),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),

          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ),

            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Colors.black54,
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      "Search here",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  _buildAvatar(scheme, initial),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar on the right of the search bar. Plain circle by default; becomes
  /// an account menu (Profile / Logout) when [onProfile] or [onLogout] is set.
  Widget _buildAvatar(ColorScheme scheme, String initial) {
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: scheme.primary,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (onProfile == null && onLogout == null) {
      return avatar;
    }

    return PopupMenuButton<String>(
      tooltip: 'Account',
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'profile') {
          onProfile?.call();
        } else if (value == 'logout') {
          onLogout?.call();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      child: avatar,
    );
  }
}