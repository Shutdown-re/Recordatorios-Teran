import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final double elevation;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.elevation = AppTheme.appBarElevation,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: Theme.of(context).appBarTheme.titleTextStyle),
      leading: _buildLeading(context),
      actions: actions,
      backgroundColor:
          backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      shape: Theme.of(context).appBarTheme.shape,
      toolbarHeight: kToolbarHeight,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton) {
      return IconButton(
        icon: const Icon(FontAwesomeIcons.arrowLeft),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        color: AppTheme.primaryColor,
        tooltip: 'Regresar',
      );
    }

    return null;
  }
}

// AppBar con gradiente
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Gradient? gradient;
  final double height;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.gradient,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.appBarGradient,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: AppTheme.heading3.copyWith(color: AppTheme.primaryColor),
        ),
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
    );
  }
}

// AppBar con búsqueda
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onSearchClosed;
  final List<Widget>? actions;
  final bool showBackButton;

  const SearchAppBar({
    super.key,
    required this.hintText,
    required this.onSearchChanged,
    this.onSearchClosed,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(FontAwesomeIcons.arrowLeft),
              onPressed: () => Navigator.of(context).pop(),
              color: AppTheme.primaryColor,
            )
          : null,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              style: const TextStyle(color: AppTheme.textColor),
              autofocus: true,
              onChanged: widget.onSearchChanged,
            )
          : Text('Buscar', style: Theme.of(context).appBarTheme.titleTextStyle),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(FontAwesomeIcons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
            color: AppTheme.primaryColor,
          ),
        if (_isSearching)
          IconButton(
            icon: const Icon(FontAwesomeIcons.times),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                widget.onSearchChanged('');
                widget.onSearchClosed?.call();
              });
            },
            color: AppTheme.primaryColor,
          ),
        ...?widget.actions,
      ],
      backgroundColor: AppTheme.surfaceColor,
      elevation: AppTheme.appBarElevation,
    );
  }
}
