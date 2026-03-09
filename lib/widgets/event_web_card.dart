import 'package:flutter/material.dart';

class EventWebCard extends StatelessWidget {
  const EventWebCard({
    super.key,
    required this.title,
    required this.dateText,
    required this.venueLine,
    required this.bandLine,
    required this.onTap,
    this.posterImageUrl,
  });

  final String title;
  final String dateText;
  final String venueLine;
  final String bandLine;
  final String? posterImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = (posterImageUrl ?? '').trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PosterThumb(imageUrl: hasImage ? posterImageUrl!.trim() : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (dateText.trim().isNotEmpty)
                      _MetaLine(
                        icon: Icons.calendar_today_outlined,
                        text: dateText,
                      ),
                    if (venueLine.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _MetaLine(icon: Icons.place_outlined, text: venueLine),
                    ],
                    if (bandLine.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _MetaLine(
                        icon: Icons.music_note_outlined,
                        text: bandLine,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterThumb extends StatelessWidget {
  const _PosterThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 84,
        height: 112,
        child: imageUrl == null
            ? Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Icon(Icons.image_outlined, color: Colors.grey.shade500),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey.shade500,
                    ),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
