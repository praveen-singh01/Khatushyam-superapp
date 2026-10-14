import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/mock/mock_models.dart';
import '../../../core/mock/mock_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_body.dart';
import '../../auth/presentation/auth_providers.dart';

enum _FeedCategory { all, miracle, kripa, sankat }

enum _SortMode { newest, oldest }

enum _LangFilter { all, hi, en }

class ChamatkarScreen extends ConsumerStatefulWidget {
  const ChamatkarScreen({super.key});

  @override
  ConsumerState<ChamatkarScreen> createState() => _ChamatkarScreenState();
}

class _ChamatkarScreenState extends ConsumerState<ChamatkarScreen> {
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  final _bookmarks = <String>{};

  _FeedCategory _category = _FeedCategory.all;
  _SortMode _sort = _SortMode.newest;
  _LangFilter _lang = _LangFilter.all;
  bool _searchOpen = false;

  static const _bookmarkKey = 'khatushyam_chamatkar_bookmarks_v1';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_bookmarkKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _bookmarks
        ..clear()
        ..addAll(raw);
    });
  }

  Future<void> _toggleBookmark(String id) async {
    setState(() {
      if (_bookmarks.contains(id)) {
        _bookmarks.remove(id);
      } else {
        _bookmarks.add(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookmarkKey, _bookmarks.toList());
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      ref.read(chamatkarListProvider.notifier).loadMore();
    }
  }

  Future<void> _compose() async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      _toast('Share karne ke liye sign in karein');
      return;
    }

    final titleController = TextEditingController();
    final storyController = TextEditingController();
    String? formError;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'अपना अनुभव लिखें',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: l10n.chamatkarTitleHint,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storyController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: l10n.chamatkarStoryHint,
                    ),
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      formError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final story = storyController.text.trim();
                      if (title.length < 3) {
                        setModalState(
                          () =>
                              formError =
                                  'Shirshak kam se kam 3 akshar ka ho',
                        );
                        return;
                      }
                      if (story.length < 20) {
                        setModalState(
                          () =>
                              formError =
                                  'Anubhav kam se kam 20 akshar ka likhein',
                        );
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: Text(l10n.chamatkarPublish),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final title = titleController.text.trim();
    final story = storyController.text.trim();
    titleController.dispose();
    storyController.dispose();
    if (submitted != true || !mounted) return;
    try {
      await ref.read(chamatkarListProvider.notifier).addPost(
        authorName: user.displayName ?? 'Bhakt',
        title: title,
        story: story,
      );
      if (mounted) _toast('Aapka anubhav share ho gaya 🙏');
    } catch (_) {
      if (mounted) _toast('Share nahi ho saka. Phir koshish karein.');
    }
  }

  Future<void> _toggleLike(ChamatkarPost post) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) {
      _toast('Like ke liye sign in karein');
      return;
    }
    try {
      await ref.read(chamatkarListProvider.notifier).toggleLike(post.id);
    } catch (_) {
      if (mounted) _toast('Like nahi ho saka');
    }
  }

  Future<void> _share(ChamatkarPost post) async {
    final text =
        '${post.title}\n\n${post.story}\n\n— ${post.authorName}\nजय श्री श्याम';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _toast('Anubhav copy ho gaya — ab share karein');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<ChamatkarPost> _filterPosts(List<ChamatkarPost> posts) {
    final query = _searchController.text.trim().toLowerCase();
    var list = posts.where((p) {
      if (_lang == _LangFilter.hi && p.language.toLowerCase() != 'hi') {
        return false;
      }
      if (_lang == _LangFilter.en && p.language.toLowerCase() != 'en') {
        return false;
      }
      if (_category != _FeedCategory.all &&
          _inferCategory(p) != _category) {
        return false;
      }
      if (query.isEmpty) return true;
      return p.title.toLowerCase().contains(query) ||
          p.story.toLowerCase().contains(query) ||
          p.authorName.toLowerCase().contains(query);
    }).toList();

    list.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _sort == _SortMode.newest ? -cmp : cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = ref.watch(chamatkarListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'अनुभव लिखें',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'चमत्कार',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'भक्तों के अनुभव — मुफ़्त',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _searchOpen = !_searchOpen),
                    icon: Icon(
                      _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => _toast('सूचनाएँ जल्द यहाँ आएंगी'),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.ink,
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'अनुभव खोजें...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            Expanded(
              child: AsyncBody(
                value: feed,
                onRetry:
                    () => ref.read(chamatkarListProvider.notifier).refresh(),
                builder: (state) {
                  final posts = _filterPosts(state.items);
                  return RefreshIndicator(
                    color: AppColors.orange,
                    onRefresh:
                        () =>
                            ref.read(chamatkarListProvider.notifier).refresh(),
                    child: ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      itemCount:
                          3 +
                          (posts.isEmpty ? 1 : posts.length) +
                          (state.loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == 0) return const _HeroBanner();
                        if (index == 1) {
                          // Category chips hidden for now.
                          // return Padding(
                          //   padding: const EdgeInsets.only(top: 16, bottom: 10),
                          //   child: _CategoryChips(
                          //     selected: _category,
                          //     onSelected:
                          //         (c) => setState(() => _category = c),
                          //   ),
                          // );
                          return const SizedBox(height: 12);
                        }
                        if (index == 2) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _SortLangRow(
                              sort: _sort,
                              lang: _lang,
                              onSort:
                                  () => setState(() {
                                    _sort =
                                        _sort == _SortMode.newest
                                            ? _SortMode.oldest
                                            : _SortMode.newest;
                                  }),
                              onLang: _pickLanguage,
                              onFilter: () => _toast('और फ़िल्टर जल्द'),
                            ),
                          );
                        }

                        final bodyStart = 3;
                        if (posts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Center(child: Text(l10n.chamatkarEmpty)),
                          );
                        }

                        final postIndex = index - bodyStart;
                        if (postIndex >= posts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.orange,
                              ),
                            ),
                          );
                        }

                        final post = posts[postIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PostCard(
                            post: post,
                            category: _inferCategory(post),
                            bookmarked: _bookmarks.contains(post.id),
                            onLike: () => _toggleLike(post),
                            onShare: () => _share(post),
                            onBookmark: () => _toggleBookmark(post.id),
                            onComment:
                                () => _toast('टिप्पणियाँ जल्द उपलब्ध होंगी'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<_LangFilter>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('सभी भाषाएँ'),
                trailing:
                    _lang == _LangFilter.all
                        ? const Icon(Icons.check, color: AppColors.orange)
                        : null,
                onTap: () => Navigator.pop(context, _LangFilter.all),
              ),
              ListTile(
                title: const Text('हिन्दी'),
                trailing:
                    _lang == _LangFilter.hi
                        ? const Icon(Icons.check, color: AppColors.orange)
                        : null,
                onTap: () => Navigator.pop(context, _LangFilter.hi),
              ),
              ListTile(
                title: const Text('English'),
                trailing:
                    _lang == _LangFilter.en
                        ? const Icon(Icons.check, color: AppColors.orange)
                        : null,
                onTap: () => Navigator.pop(context, _LangFilter.en),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _lang = picked);
  }
}

_FeedCategory _inferCategory(ChamatkarPost post) {
  final text = '${post.title} ${post.story}'.toLowerCase();
  if (RegExp(
    r'wallet|miracle|चमत्कार|adbhut|returned|waps',
  ).hasMatch(text)) {
    return _FeedCategory.miracle;
  }
  if (RegExp(
    r'kripa|कृपा|grace|bless|स्वस्थ|shant|peace|hope',
  ).hasMatch(text)) {
    return _FeedCategory.kripa;
  }
  if (RegExp(
    r'sankat|संकट|worry|hard|crisis|trouble|bimari|बीमार',
  ).hasMatch(text)) {
    return _FeedCategory.sankat;
  }
  final bucket = post.id.hashCode.abs() % 3;
  return switch (bucket) {
    0 => _FeedCategory.miracle,
    1 => _FeedCategory.kripa,
    _ => _FeedCategory.sankat,
  };
}

({String label, IconData icon, Color color}) _categoryMeta(_FeedCategory c) {
  return switch (c) {
    _FeedCategory.all => (
      label: 'सभी अनुभव',
      icon: Icons.grid_view_rounded,
      color: AppColors.orange,
    ),
    _FeedCategory.miracle => (
      label: 'चमत्कार',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFFE67E22),
    ),
    _FeedCategory.kripa => (
      label: 'कृपा',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFE74C3C),
    ),
    _FeedCategory.sankat => (
      label: 'संकट से मुक्ति',
      icon: Icons.verified_user_rounded,
      color: const Color(0xFF27AE60),
    ),
  };
}

IconData _titleIconFor(_FeedCategory c) {
  return switch (c) {
    _FeedCategory.miracle => Icons.temple_hindu_rounded,
    _FeedCategory.kripa => Icons.spa_rounded,
    _FeedCategory.sankat => Icons.shield_moon_rounded,
    _FeedCategory.all => Icons.auto_stories_rounded,
  };
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'अभी';
  if (diff.inMinutes < 60) return '${diff.inMinutes} मिनट पहले';
  if (diff.inHours < 24) return '${diff.inHours} घंटे पहले';
  return '${diff.inDays} दिन पहले';
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'बाबा के दरबार में हर प्रार्थना होती है स्वीकार',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'अपने अनुभव साझा करें और भक्ति से सबको जोड़ें',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 24,
                      child: Stack(
                        children: List.generate(3, (i) {
                          return Positioned(
                            left: i * 14.0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: [
                                AppColors.orangeSoft,
                                const Color(0xFFFFE0B2),
                                const Color(0xFFFFCC80),
                              ][i],
                              child: Text(
                                ['R', 'S', 'A'][i],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orangeDeep,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '12.5K+ भक्तों ने अपने अनुभव साझा किए',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/hero_blessing.jpg',
              width: 92,
              height: 118,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) {
                return Image.asset(
                  'assets/applogo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final _FeedCategory selected;
  final ValueChanged<_FeedCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _FeedCategory.values.map((c) {
              final meta = _categoryMeta(c);
              final active = selected == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: active ? AppColors.orange : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => onSelected(c),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? AppColors.orange : AppColors.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            meta.icon,
                            size: 15,
                            color: active ? Colors.white : AppColors.inkMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            meta.label,
                            style: TextStyle(
                              color:
                                  active ? Colors.white : AppColors.inkMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _SortLangRow extends StatelessWidget {
  const _SortLangRow({
    required this.sort,
    required this.lang,
    required this.onSort,
    required this.onLang,
    required this.onFilter,
  });

  final _SortMode sort;
  final _LangFilter lang;
  final VoidCallback onSort;
  final VoidCallback onLang;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final langLabel = switch (lang) {
      _LangFilter.all => 'सभी भाषाएँ',
      _LangFilter.hi => 'हिन्दी',
      _LangFilter.en => 'English',
    };
    final sortLabel =
        sort == _SortMode.newest ? 'नवीनतम पहले' : 'पुराने पहले';

    return Row(
      children: [
        _MiniChip(
          icon: Icons.swap_vert_rounded,
          label: sortLabel,
          onTap: onSort,
        ),
        const SizedBox(width: 8),
        _MiniChip(
          icon: Icons.public_rounded,
          label: langLabel,
          trailing: Icons.keyboard_arrow_down_rounded,
          onTap: onLang,
        ),
        const Spacer(),
        IconButton(
          onPressed: onFilter,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.tune_rounded, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.inkMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                Icon(trailing, size: 16, color: AppColors.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.category,
    required this.bookmarked,
    required this.onLike,
    required this.onShare,
    required this.onBookmark,
    required this.onComment,
  });

  final ChamatkarPost post;
  final _FeedCategory category;
  final bool bookmarked;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final initial =
        post.authorName.isNotEmpty
            ? post.authorName.characters.first.toUpperCase()
            : 'B';
    final meta = _categoryMeta(category);
    final commentCount = math.max(1, post.likeCount ~/ 3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.orangeSoft,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_timeAgo(post.createdAt)} · जय श्री श्याम 🙏',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meta.icon, size: 12, color: meta.color),
                    const SizedBox(width: 4),
                    Text(
                      meta.label,
                      style: TextStyle(
                        color: meta.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _titleIconFor(category),
                size: 18,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.story,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Action(
                icon:
                    post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                label: post.likeCount > 0 ? '${post.likeCount}' : '0',
                color: post.likedByMe ? AppColors.orange : AppColors.inkMuted,
                onTap: onLike,
              ),
              const SizedBox(width: 14),
              _Action(
                icon: Icons.chat_bubble_outline_rounded,
                label: '$commentCount',
                onTap: onComment,
              ),
              const SizedBox(width: 14),
              _Action(
                icon: Icons.ios_share_rounded,
                label: 'शेयर करें',
                onTap: onShare,
              ),
              const Spacer(),
              IconButton(
                onPressed: onBookmark,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: bookmarked ? AppColors.orange : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.inkMuted,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
