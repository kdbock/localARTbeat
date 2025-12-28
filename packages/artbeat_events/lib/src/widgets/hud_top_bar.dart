import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


/// A shared top bar that matches the design_guide look
///
/// - Transparent background over world/glass layouts
/// - Optional back button, menu, search, profile, notifications, dev icon
/// - Uses Space Grotesk + consistent icon spacing
class HudTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showMenu;
  final bool showSearch;
  final bool showProfile;
  final bool showDeveloper;
  final Widget? rightAction;

  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final VoidCallback? onProfile;
  final VoidCallback? onDeveloper;

  const HudTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showMenu = false,
    this.showSearch = false,
    this.showProfile = false,
    this.showDeveloper = false,
    this.rightAction,
    this.onBack,
    this.onMenu,
    this.onSearch,
    this.onProfile,
    this.onDeveloper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        border: const Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // LEFT SECTION
            if (showBack)
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: onBack ?? () => Navigator.maybePop(context),
              )
            else if (showMenu)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                onPressed: onMenu,
              )
            else
              const SizedBox(width: 12),

            // TITLE (CENTERED)
            Expanded(
              child: Center(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // RIGHT SECTION
            if (rightAction != null)
              rightAction!
            else
              Row(
                children: [
                  if (showSearch)
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onSearch,
                    ),

                  if (showProfile)
                    IconButton(
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onProfile,
                    ),

                  if (showDeveloper)
                    IconButton(
                      icon: const Icon(
                        Icons.developer_mode,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onDeveloper,
                    ),

                  const SizedBox(width: 6),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
