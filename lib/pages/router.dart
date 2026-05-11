import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;

  const TVBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  State<TVBottomNavigation> createState() => _TVBottomNavigationState();
}

class _TVBottomNavigationState extends State<TVBottomNavigation> {
  int _focusedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.0,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(widget.items.length, (index) {
          final bool isSelected = widget.currentIndex == index;
          final bool isFocused = _focusedIndex == index;

          return Focus(
            onKey: (node, event) {
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  widget.onTap(index);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                setState(() => _focusedIndex = index);
              }
            },
            child: GestureDetector(
              onTap: () => widget.onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                decoration: BoxDecoration(
                  border: isFocused
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2.0,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8.0),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.items[index].icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      size: 28.0,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      widget.items[index].label,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontSize: 12.0,
                        fontWeight: isFocused ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}