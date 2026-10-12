import 'package:flutter/material.dart';

import '../data/models/post.dart';

class PostTile extends StatelessWidget {
  const PostTile({
    required this.post,
    required this.onTap,
    this.showBody = true,
    super.key,
  });

  final Post post;
  final VoidCallback onTap;
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: showBody
          ? Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
    );
  }
}
