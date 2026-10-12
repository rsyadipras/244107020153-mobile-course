import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'paged_posts.dart';
import 'providers.dart';

final postDetailProvider = FutureProvider.autoDispose.family<Post, int>(
  (ref, id) async {
    final cached = ref
        .read(pagedPostsProvider)
        .items
        .where((post) => post.id == id)
        .firstOrNull;
    if (cached != null) return cached;
    return ref.read(postRepositoryProvider).fetchPost(id);
  },
);
