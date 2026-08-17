// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../data/models.dart';
import '../data/quran_repository.dart';
import '../data/reading_position.dart';
import '../qql/qql.dart';
import '../settings/settings_controller.dart';
import '../tajwid/tajwid_style.dart';
import 'surah_title.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({
    super.key,
    required this.repository,
    required this.surah,
    required this.positions,
    this.startAtAyah,
  });

  final QuranRepository repository;
  final Surah surah;
  final ReadingPositionStore positions;

  /// Ayah to open at, when resuming. Null starts at the beginning.
  final int? startAtAyah;

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<Ayah>? _ayahs;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SurahScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Navigating pushes a fresh route, so in practice this only fires if the
    // same screen is rebuilt pointing at another surah. Without it the text
    // would stay on the old surah while the title changed.
    if (widget.surah.number != oldWidget.surah.number) {
      _load();
    }
  }

  void _load() {
    try {
      _ayahs = widget.repository.surah(widget.surah.number);
      _error = null;
    } on QqlException catch (e) {
      _ayahs = null;
      _error = e;
    }
  }

  void _onAyahInView(int ayah) =>
      widget.positions.record(widget.surah.number, ayah);

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.surah.nameEnglish),
            Text(
              '${widget.surah.ayahCount} ayahs',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          // The mode is a global setting, but flipping it is the single most
          // common thing to do while reading, so it also lives up here.
          IconButton(
            icon: Icon(
              settings.readingMode == ReadingMode.reading
                  ? Icons.translate_outlined
                  : Icons.subject_outlined,
            ),
            tooltip: settings.readingMode == ReadingMode.reading
                ? 'Show translation'
                : 'Arabic only',
            onPressed: () => settings.readingMode =
                settings.readingMode == ReadingMode.reading
                    ? ReadingMode.normal
                    : ReadingMode.reading,
          ),
        ],
      ),
      body: _body(settings),
    );
  }

  Widget _body(SettingsController settings) {
    if (_error != null) {
      return Center(child: Text('Could not load this surah.\n$_error'));
    }
    final ayahs = _ayahs!;
    final arabicStyle = settings.arabicTextStyle(context);

    // Keyed by mode so that switching modes rebuilds the scroller from
    // scratch rather than carrying a meaningless offset across two very
    // different layouts. The heading stays above both, which also keeps it
    // clear of the paragraph offsets reading mode measures against.
    final Widget page = settings.readingMode == ReadingMode.reading
        ? _ContinuousPage(
            key: const ValueKey('reading'),
            ayahs: ayahs,
            arabicStyle: arabicStyle,
            startAtAyah: widget.startAtAyah,
            onAyahInView: _onAyahInView,
          )
        : _AyahList(
            key: const ValueKey('normal'),
            ayahs: ayahs,
            arabicStyle: arabicStyle,
            startAtAyah: widget.startAtAyah,
            onAyahInView: _onAyahInView,
          );

    return Column(
      children: [
        SurahHeading(surah: widget.surah),
        Expanded(child: page),
      ],
    );
  }
}

/// Normal mode: one ayah, then its translation.
///
/// Uses a positioned list so the ayah at the top of the viewport can be read
/// off directly, and so resuming can jump to an ayah by index — neither is
/// possible with a plain lazy ListView, where items far from the viewport have
/// no known height.
class _AyahList extends StatefulWidget {
  const _AyahList({
    super.key,
    required this.ayahs,
    required this.arabicStyle,
    required this.startAtAyah,
    required this.onAyahInView,
  });

  final List<Ayah> ayahs;
  final TextStyle arabicStyle;
  final int? startAtAyah;
  final ValueChanged<int> onAyahInView;

  @override
  State<_AyahList> createState() => _AyahListState();
}

class _AyahListState extends State<_AyahList> {
  final _positions = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_report);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_report);
    super.dispose();
  }

  void _report() {
    final visible = _positions.itemPositions.value;
    if (visible.isEmpty) return;
    // The topmost item still showing: the one with the smallest leading edge
    // that has not yet scrolled off the top.
    final first = visible
        .where((p) => p.itemTrailingEdge > 0)
        .fold<ItemPosition?>(
          null,
          (best, p) => best == null || p.index < best.index ? p : best,
        );
    if (first != null) widget.onAyahInView(widget.ayahs[first.index].number);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.startAtAyah == null
        ? 0
        : widget.ayahs
            .indexWhere((a) => a.number == widget.startAtAyah)
            .clamp(0, widget.ayahs.length - 1);

    return ScrollablePositionedList.separated(
      itemPositionsListener: _positions,
      initialScrollIndex: initial,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: widget.ayahs.length,
      separatorBuilder: (_, _) => const Divider(height: 28),
      itemBuilder: (context, index) => _AyahTile(
        ayah: widget.ayahs[index],
        arabicStyle: widget.arabicStyle,
      ),
    );
  }
}

/// Reading mode: the whole surah set as one running page.
///
/// Ayahs are not laid out one per line — each continues from where the last
/// ended, separated only by its marker, so the text wraps like a mushaf rather
/// than a list. That means one paragraph for the entire surah, which is also
/// why this cannot be a lazy list: the line breaks depend on every ayah before
/// it.
///
/// Because it is a single paragraph there are no items to count, so the ayah
/// in view is found by asking the laid-out paragraph which character sits at
/// the top of the viewport, and mapping that back through [_ayahAt].
class _ContinuousPage extends StatefulWidget {
  const _ContinuousPage({
    super.key,
    required this.ayahs,
    required this.arabicStyle,
    required this.startAtAyah,
    required this.onAyahInView,
  });

  final List<Ayah> ayahs;
  final TextStyle arabicStyle;
  final int? startAtAyah;
  final ValueChanged<int> onAyahInView;

  @override
  State<_ContinuousPage> createState() => _ContinuousPageState();
}

class _ContinuousPageState extends State<_ContinuousPage> {
  final _scroll = ScrollController();
  final _paragraphKey = GlobalKey();

  /// Character offset in the paragraph at which each ayah starts, parallel to
  /// [_ContinuousPage.ayahs]. Rebuilt whenever the spans are.
  List<int> _ayahStarts = const [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_report);
    if (widget.startAtAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToStart());
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_report);
    _scroll.dispose();
    super.dispose();
  }

  /// Vertical padding above the paragraph, which sits between scroll-view
  /// coordinates and the paragraph's own.
  static const _topPadding = 16.0;

  RenderParagraph? get _paragraph {
    final object = _paragraphKey.currentContext?.findRenderObject();
    return object is RenderParagraph ? object : null;
  }

  void _jumpToStart() {
    final index = widget.ayahs.indexWhere((a) => a.number == widget.startAtAyah);
    final paragraph = _paragraph;
    if (index < 0 || paragraph == null || index >= _ayahStarts.length) return;

    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: _ayahStarts[index]),
      Rect.zero,
    );
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(
      (caret.dy + _topPadding).clamp(0.0, _scroll.position.maxScrollExtent),
    );
  }

  void _report() {
    final paragraph = _paragraph;
    if (paragraph == null || _ayahStarts.isEmpty) return;
    // The viewport top, in the paragraph's own coordinates. x is the right
    // edge because the text is right-to-left, so that is where a line starts.
    final localY = (_scroll.offset - _topPadding).clamp(0.0, double.infinity);
    final position = paragraph.getPositionForOffset(
      Offset(paragraph.size.width, localY),
    );
    widget.onAyahInView(_ayahAt(position.offset));
  }

  /// The ayah owning character [offset], by binary search over [_ayahStarts].
  int _ayahAt(int offset) {
    var lo = 0;
    var hi = _ayahStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_ayahStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return widget.ayahs[lo].number;
  }

  @override
  Widget build(BuildContext context) {
    final palette = TajwidPalette.of(context);
    final markerColor = Theme.of(context).colorScheme.primary;

    final spans = <InlineSpan>[];
    final starts = <int>[];
    var chars = 0;
    for (final ayah in widget.ayahs) {
      starts.add(chars);
      for (final span in tajwidSpans(ayah.arabic, palette)) {
        spans.add(span);
      }
      final marker = ayahMarkerText(ayah.number);
      spans.add(TextSpan(text: marker, style: TextStyle(color: markerColor)));
      chars += ayah.arabic.length + marker.length;
    }
    _ayahStarts = starts;

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, _topPadding, 20, 40),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: spans),
          key: _paragraphKey,
          style: widget.arabicStyle,
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}

/// Normal mode: one ayah, then its translation.
class _AyahTile extends StatelessWidget {
  const _AyahTile({required this.ayah, required this.arabicStyle});

  final Ayah ayah;
  final TextStyle arabicStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The number rides at the end of the Arabic line so it reads as part
        // of the mushaf rather than as a list bullet.
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              children: [
                ...tajwidSpans(ayah.arabic, TajwidPalette.of(context)),
                TextSpan(
                  text: ayahMarkerText(ayah.number),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            style: arabicStyle,
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${ayah.number}. ${ayah.english}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// The end-of-ayah marker.
///
/// KFGQPC HAFS draws U+0660-0669 as the ornamented medallions of a mushaf,
/// with the number already inside them, so the marker is simply the ayah
/// number in Arabic-Indic digits. Nothing has to be drawn around it: U+06DD
/// (ARABIC END OF AYAH) would add a second, empty circle beside it.
String ayahMarkerText(int number) => ' \u2009${_arabicDigits(number)} ';

String _arabicDigits(int value) => '$value'.replaceAllMapped(
      RegExp(r'\d'),
      (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)),
    );
