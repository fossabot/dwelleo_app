import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Provides the ApiResult.when extension used below.
import '../../../../core/errors/api_result.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property.dart';
import '../../domain/usecases/favorites_usecases.dart';

/// Save-state of one heart. `null` = still loading from the store.
class FavoriteToggleCubit extends Cubit<bool?> {
  final GetFavoriteIds _ids;
  final ToggleFavorite _toggle;

  FavoriteToggleCubit(this._ids, this._toggle) : super(null);

  Future<void> loadFor(int propertyId) async {
    final result = await _ids();
    if (isClosed) return;
    result.when(
      success: (ids) => emit(ids.contains(propertyId)),
      error: (_) => emit(false),
    );
  }

  /// Optimistic flip with rollback on storage failure.
  Future<void> toggle(Property property) async {
    final previous = state ?? false;
    emit(!previous);
    final result = await _toggle(property);
    if (isClosed) return;
    result.when(success: (saved) => emit(saved), error: (_) => emit(previous));
  }
}

/// The heart — usable over card images (scrim style) or in app bars.
/// Review P0 #6: save must be operable from every property surface.
class FavoriteHeart extends StatefulWidget {
  final Property property;

  /// True = circular dark scrim behind the icon (over photos).
  final bool scrim;
  final double size;

  const FavoriteHeart({
    super.key,
    required this.property,
    this.scrim = false,
    this.size = 22,
  });

  @override
  State<FavoriteHeart> createState() => _FavoriteHeartState();
}

class _FavoriteHeartState extends State<FavoriteHeart> {
  late final FavoriteToggleCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = FavoriteToggleCubit(sl<GetFavoriteIds>(), sl<ToggleFavorite>())
      ..loadFor(widget.property.id);
  }

  @override
  void didUpdateWidget(FavoriteHeart old) {
    super.didUpdateWidget(old);
    // In a scrolling list Flutter recycles this State for a new property at
    // the same slot; without this reload the heart would keep the previous
    // listing's saved-state (and toggle the wrong one).
    if (old.property.id != widget.property.id) {
      _cubit.loadFor(widget.property.id);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return BlocBuilder<FavoriteToggleCubit, bool?>(
      bloc: _cubit,
      builder: (context, saved) {
        final icon = Icon(
          (saved ?? false)
              ? Icons.favorite_rounded
              : Icons.favorite_outline_rounded,
          size: widget.size,
          color: (saved ?? false)
              ? accent
              : (widget.scrim
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant),
        );

        return Semantics(
          button: true,
          selected: saved ?? false,
          child: InkResponse(
            radius: widget.size + 8,
            onTap: () => _cubit.toggle(widget.property),
            child: widget.scrim
                ? Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: icon,
                  )
                : Padding(padding: const EdgeInsets.all(6), child: icon),
          ),
        );
      },
    );
  }
}
