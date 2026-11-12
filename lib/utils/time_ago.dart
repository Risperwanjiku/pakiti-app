String timeAgo(DateTime time) {
  final difference = DateTime.now().difference(time);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return difference.inHours == 1 ? '1 hr ago' : '${difference.inHours} hrs ago';
  }
  if (difference.inDays == 1) {
    return 'Yesterday';
  }
  return '${difference.inDays} days ago';
}