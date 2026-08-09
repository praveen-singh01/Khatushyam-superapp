abstract final class AppRoutes {
  static const splash = '/';
  static const signIn = '/sign-in';
  static const home = '/home';
  static const story = '/story';
  static const chamatkar = '/chamatkar';
  static const posters = '/posters';
  static const paywall = '/premium';
  static const feature = '/feature/:id';

  static String featurePath(String id) => '/feature/$id';
}
