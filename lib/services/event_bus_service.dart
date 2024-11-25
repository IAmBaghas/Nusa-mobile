import 'dart:async';
import '../models/post_comment.dart';
import '../models/article.dart';
import '../models/latest_article.dart';
import '../models/agenda.dart';
import 'dart:io';

class PostUpdateEvent {
  final int postId;
  final bool? isLiked;
  final int? likesCount;
  final int? commentsCount;
  final PostComment? latestComment;
  final UpdateType type;

  PostUpdateEvent({
    required this.postId,
    this.isLiked,
    this.likesCount,
    required this.commentsCount,
    this.latestComment,
    required this.type,
  });
}

class ArticleUpdateEvent {
  final List<Article> articles;
  final List<LatestArticle> latestArticles;

  ArticleUpdateEvent({
    required this.articles,
    required this.latestArticles,
  });
}

class ProfileImageUpdateEvent {
  final int userId;
  final String? profileImage;
  final String imageUrl;

  ProfileImageUpdateEvent({
    required this.userId,
    this.profileImage,
    required this.imageUrl,
  });
}

class AgendaUpdateEvent {
  final List<Agenda> agendas;

  AgendaUpdateEvent({
    required this.agendas,
  });
}

enum UpdateType { like, comment, article, profileImage }

class EventBusService {
  static final EventBusService _instance = EventBusService._internal();
  factory EventBusService() => _instance;
  EventBusService._internal();

  final _postUpdateController = StreamController<PostUpdateEvent>.broadcast();
  final _articleUpdateController =
      StreamController<ArticleUpdateEvent>.broadcast();
  final _profileImageUpdateController =
      StreamController<ProfileImageUpdateEvent>.broadcast();
  final _agendaUpdateController =
      StreamController<AgendaUpdateEvent>.broadcast();

  Stream<PostUpdateEvent> get postUpdates => _postUpdateController.stream;
  Stream<ArticleUpdateEvent> get articleUpdates =>
      _articleUpdateController.stream;
  Stream<ProfileImageUpdateEvent> get profileImageUpdates =>
      _profileImageUpdateController.stream;
  Stream<AgendaUpdateEvent> get agendaUpdates => _agendaUpdateController.stream;

  void emitPostUpdate(PostUpdateEvent event) {
    print(
        'Emitting post event: ${event.type}, postId: ${event.postId}, commentsCount: ${event.commentsCount}');
    _postUpdateController.add(event);
  }

  void emitArticleUpdate(ArticleUpdateEvent event) {
    print('Emitting article update');
    _articleUpdateController.add(event);
  }

  void emitProfileImageUpdate(ProfileImageUpdateEvent event) {
    print('Emitting profile image update for user ${event.userId}');
    _profileImageUpdateController.add(event);
  }

  void emitAgendaUpdate(AgendaUpdateEvent event) {
    print('Emitting agenda update');
    _agendaUpdateController.add(event);
  }

  String getProfileImageUrl(int userId, String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) return '';
    final baseUrl =
        Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';
    return '$baseUrl/uploads/profiles/$userId/$profileImage';
  }

  void dispose() {
    _postUpdateController.close();
    _articleUpdateController.close();
    _profileImageUpdateController.close();
    _agendaUpdateController.close();
  }
}
