// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../data/models.dart';
import '../data/quran_repository.dart';
import '../data/reading_position.dart';
import '../mushaf/mushaf_frame.dart';
import '../qql/qql.dart';
import '../settings/settings_controller.dart';
import '../tajwid/tajwid_style.dart';
import 'surah_title.dart';

/// A request to bring an ayah to the top of the view.
///
/// [seq] distinguishes two requests for the same ayah, so asking again for the
/// ayah you are already looking at still scrolls there.
@immutable
class AyahJump {
  const AyahJump(this.ayah, this.seq);

  final int ayah;
  final int seq;
}

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

  /// Where to scroll next. Seeded from the resume position, then replaced
  /// whenever the reader asks to jump.
  AyahJump? _jump;
  var _jumpSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.startAtAyah != null) {
      _jump = AyahJump(widget.startAtAyah!, _jumpSeq);
    }
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

  Future<void> _promptJump() async {
    final ayah = await showDialog<int>(
      context: context,
      builder: (_) => _JumpDialog(surah: widget.surah),
    );
    if (ayah == null || !mounted) return;
    setState(() => _jump = AyahJump(ayah, ++_jumpSeq));
  }

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
          // Dragging a scrollbar is not a gesture a phone offers, and a long
          // surah is thousands of lines, so reaching an ayah is a jump rather
          // than a scroll.
          IconButton(
            icon: const Icon(Icons.numbers),
            tooltip: 'Go to ayah',
            onPressed: _ayahs == null ? null : _promptJump,
          ),
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
    // different layouts. The heading is part of each scroller — it rolls away
    // with the text — so both modes receive it here.
    final Widget page = settings.readingMode == ReadingMode.reading
        ? _ContinuousPage(
            key: const ValueKey('reading'),
            surah: widget.surah,
            ayahs: ayahs,
            arabicStyle: arabicStyle,
            jump: _jump,
            onAyahInView: _onAyahInView,
          )
        : _AyahList(
            key: const ValueKey('normal'),
            surah: widget.surah,
            ayahs: ayahs,
            arabicStyle: arabicStyle,
            jump: _jump,
            onAyahInView: _onAyahInView,
          );

    // The page frame is fixed to the viewport like a real page border, so it
    // sits behind the scroller rather than inside it — which also keeps the
    // reading-mode paragraph measurements independent of it. The content
    // inset is what clears the rules and their breathing room.
    return Stack(
      children: [
        const Positioned.fill(child: MushafFrame()),
        Padding(
          padding: const EdgeInsets.all(MushafFrame.contentInset),
          child: page,
        ),
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
///
/// The surah heading is item 0, so it scrolls away with the text like a real
/// page; every ayah index is therefore shifted by one.
class _AyahList extends StatefulWidget {
  const _AyahList({
    super.key,
    required this.surah,
    required this.ayahs,
    required this.arabicStyle,
    required this.jump,
    required this.onAyahInView,
  });

  final Surah surah;
  final List<Ayah> ayahs;
  final TextStyle arabicStyle;
  final AyahJump? jump;
  final ValueChanged<int> onAyahInView;

  @override
  State<_AyahList> createState() => _AyahListState();
}

class _AyahListState extends State<_AyahList> {
  final _positions = ItemPositionsListener.create();
  final _scroll = ItemScrollController();

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_report);
  }

  @override
  void didUpdateWidget(_AyahList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final jump = widget.jump;
    // The initial position is handled by initialScrollIndex; this is for the
    // jumps that come afterwards.
    if (jump != null && jump.seq != oldWidget.jump?.seq && _scroll.isAttached) {
      _scroll.scrollTo(
        // +1: item 0 is the heading.
        index: _indexOf(jump.ayah) + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _indexOf(int ayah) => widget.ayahs
      .indexWhere((a) => a.number == ayah)
      .clamp(0, widget.ayahs.length - 1);

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
    if (first == null) return;
    // Item 0 is the heading; while it is the topmost thing visible, the
    // reader is at the start of the surah.
    final ayahIndex = first.index - 1;
    widget.onAyahInView(ayahIndex < 0
        ? widget.ayahs.first.number
        : widget.ayahs[ayahIndex].number);
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.separated(
      itemPositionsListener: _positions,
      itemScrollController: _scroll,
      initialScrollIndex:
          widget.jump == null ? 0 : _indexOf(widget.jump!.ayah) + 1,
      // The frame's content inset already supplies the page margins.
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      itemCount: widget.ayahs.length + 1,
      // No rule directly beneath the heading: the cartouche is rule enough.
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 8) : const _AyahSeparator(),
      itemBuilder: (context, index) => index == 0
          ? SurahHeading(surah: widget.surah)
          : _AyahTile(
              ayah: widget.ayahs[index - 1],
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
///
/// The surah heading scrolls with the text, sitting above the paragraph in the
/// same scroll view, so every paragraph offset is measured against the heading
/// height as well — see [_headingExtent].
///
/// Every line of the paragraph is underlined by a hairline rule, khata
/// (exercise-book) style; the rule positions are read off the laid-out
/// paragraph rather than assumed, because medallion lines can set taller.
class _ContinuousPage extends StatefulWidget {
  const _ContinuousPage({
    super.key,
    required this.surah,
    required this.ayahs,
    required this.arabicStyle,
    required this.jump,
    required this.onAyahInView,
  });

  final Surah surah;
  final List<Ayah> ayahs;
  final TextStyle arabicStyle;
  final AyahJump? jump;
  final ValueChanged<int> onAyahInView;

  @override
  State<_ContinuousPage> createState() => _ContinuousPageState();
}

class _ContinuousPageState extends State<_ContinuousPage> {
  final _scroll = ScrollController();
  final _paragraphKey = GlobalKey();
  final _headingKey = GlobalKey();

  /// Character offset in the paragraph at which each ayah starts, parallel to
  /// [_ContinuousPage.ayahs]. Rebuilt whenever the spans are.
  List<int> _ayahStarts = const [];

  /// The paragraph's spans, kept so [_measureLines] can re-lay them out.
  List<InlineSpan> _spans = const [];

  /// Paragraph-local y of every ruled line. Measured from layout rather than
  /// computed from the font size, because a line holding an ayah medallion is
  /// set in a different face and need not share the text's line height.
  List<double> _lineBottoms = const [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_report);
    if (widget.jump != null) {
      // The paragraph has to be laid out before an ayah has a position.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollTo(widget.jump!.ayah));
    }
  }

  @override
  void didUpdateWidget(_ContinuousPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final jump = widget.jump;
    if (jump != null && jump.seq != oldWidget.jump?.seq) {
      _scrollTo(jump.ayah, animate: true);
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

  /// The laid-out height of the surah heading above the paragraph, in
  /// scroll-content coordinates. Zero before the first frame; both callers
  /// that need it (jump and report) only run after layout.
  double get _headingExtent {
    final object = _headingKey.currentContext?.findRenderObject();
    return object is RenderBox && object.hasSize ? object.size.height : 0;
  }

  /// Read every line's bottom edge by re-laying the paragraph out with an
  /// identical [TextPainter] (RenderParagraph does not expose its line
  /// metrics). Runs after a frame because the width must be known; a width,
  /// font or size change rebuilds the page and lands here again.
  void _measureLines() {
    final paragraph = _paragraph;
    if (paragraph == null || !paragraph.hasSize || _spans.isEmpty) return;
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(children: _spans, style: widget.arabicStyle),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      textScaler: scaler,
    )..layout(maxWidth: paragraph.size.width);
    final metrics = painter.computeLineMetrics();
    painter.dispose();

    // A line's metrics say where its box ends, not where its glyphs do: the
    // box carries the leading the line height added, and deep tails (final
    // yeh, seen) overshoot it besides. So the rule is placed off the face's
    // own reach instead, in the middle of the band between one line's tails
    // and the next line's vowel marks — the strip no glyph occupies.
    final size = scaler.scale(widget.arabicStyle.fontSize ?? 28);
    final extents = arabicFontExtents(widget.arabicStyle.fontFamily ?? '');
    final ascent = extents.ascent * size;
    final descent = extents.descent * size;
    final bottoms = <double>[];
    // A single-line paragraph has no band to measure, and falls back to
    // sitting just clear of the tails.
    var drop = descent + lineAir * size / 2;
    for (var i = 0; i < metrics.length; i++) {
      final baseline = metrics[i].baseline;
      if (i + 1 < metrics.length) {
        final tails = baseline + descent;
        final marks = metrics[i + 1].baseline - ascent;
        // The last line keeps whatever drop the line above it settled on.
        drop = (tails + marks) / 2 - baseline;
      }
      bottoms.add(baseline + drop);
    }
    var changed = bottoms.length != _lineBottoms.length;
    for (var i = 0; !changed && i < bottoms.length; i++) {
      changed = bottoms[i] != _lineBottoms[i];
    }
    if (changed && mounted) setState(() => _lineBottoms = bottoms);
  }

  /// Put the line [ayah] starts on at the top of the viewport.
  void _scrollTo(int ayah, {bool animate = false}) {
    final index = widget.ayahs.indexWhere((a) => a.number == ayah);
    final paragraph = _paragraph;
    if (index < 0 || paragraph == null || index >= _ayahStarts.length) return;
    if (!_scroll.hasClients) return;

    // Where that ayah's first character sits within the paragraph; the
    // paragraph itself starts below the heading plus the top padding.
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: _ayahStarts[index]),
      Rect.zero,
    );
    final target = (caret.dy + _headingExtent + _topPadding)
        .clamp(0.0, _scroll.position.maxScrollExtent);

    if (animate) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  void _report() {
    final paragraph = _paragraph;
    if (paragraph == null || _ayahStarts.isEmpty) return;
    // The viewport top, in the paragraph's own coordinates — past the heading
    // and the top padding. x is the right edge because the text is
    // right-to-left, so that is where a line starts.
    final localY = (_scroll.offset - _headingExtent - _topPadding)
        .clamp(0.0, double.infinity);
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
    // Gilded ink for the medallions, as on a tooled page.
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
      spans.add(TextSpan(
        text: marker,
        style: TextStyle(
          fontFamily: medallionFontFamily,
          color: markerColor,
        ),
      ));
      chars += ayah.arabic.length + marker.length;
    }
    _ayahStarts = starts;
    _spans = spans;

    return SingleChildScrollView(
      controller: _scroll,
      // The frame's content inset supplies the side margins; the top value
      // stays _topPadding because the scroll math measures against it.
      padding: const EdgeInsets.fromLTRB(0, _topPadding, 0, 24),
      child: Column(
        children: [
          SurahHeading(key: _headingKey, surah: widget.surah),
          LayoutBuilder(
            builder: (context, _) {
              // The ruled lines sit at measured line positions, which only
              // exist after layout — schedule the read, the painter repaints
              // when they change.
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _measureLines());
              return Directionality(
                textDirection: TextDirection.rtl,
                // A Column hands its children loose constraints, but the
                // paragraph must span the full width or the justification has
                // nothing to stretch against.
                child: SizedBox(
                  width: double.infinity,
                  // Khata rules: a hairline under every line, like an exercise
                  // book. Painted, not a widget per line, so a long surah
                  // stays one paragraph.
                  child: CustomPaint(
                    painter: _RuledLinesPainter(
                      _lineBottoms,
                      Theme.of(context).dividerColor,
                    ),
                    child: Text.rich(
                      TextSpan(children: spans),
                      key: _paragraphKey,
                      style: widget.arabicStyle,
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Khata-style ruled lines: a hairline in the clear band under each line. The
/// positions come from the paragraph's own line metrics, so medallion lines
/// that set taller stay on the grid instead of drifting off it.
class _RuledLinesPainter extends CustomPainter {
  const _RuledLinesPainter(this.lineBottoms, this.color);

  final List<double> lineBottoms;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final y in lineBottoms) {
      if (y > size.height) break;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
  }

  @override
  bool shouldRepaint(_RuledLinesPainter old) =>
      old.lineBottoms != lineBottoms || old.color != color;
}

/// Normal mode: a full-width hairline between ayahs, like the ruled lines of
/// a paper page.
class _AyahSeparator extends StatelessWidget {
  const _AyahSeparator();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 28,
      thickness: 1,
      color: Theme.of(context).dividerColor,
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
                    fontFamily: medallionFontFamily,
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
          // Serif for the translation: the page should read as set type, not
          // as UI chrome. The family is the platform's generic serif — no
          // bundled font is needed for Latin.
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'serif',
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
///
/// The span is pinned to that face rather than the reader's chosen one,
/// because several of the bundled fonts map those digits to blank glyphs and
/// the number would simply disappear.
String ayahMarkerText(int number) => ' \u2009${_arabicDigits(number)} ';

String _arabicDigits(int value) => '$value'.replaceAllMapped(
      RegExp(r'\d'),
      (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)),
    );

/// Asks which ayah to go to.
class _JumpDialog extends StatefulWidget {
  const _JumpDialog({required this.surah});

  final Surah surah;

  @override
  State<_JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<_JumpDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final ayah = int.tryParse(_controller.text.trim());
    if (ayah == null || ayah < 1 || ayah > widget.surah.ayahCount) {
      setState(() => _error = 'Enter 1 to ${widget.surah.ayahCount}');
      return;
    }
    Navigator.of(context).pop(ayah);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Go to ayah'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          labelText: '${widget.surah.nameEnglish} · 1–${widget.surah.ayahCount}',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Go')),
      ],
    );
  }
}
