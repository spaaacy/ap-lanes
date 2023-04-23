class Greeting {
  static String getGreeting(String? lastName) {
    var hour = DateTime.now().hour;
    final String greeting;

    if (hour <= 12) {
      greeting = 'Good Morning';
    } else if ((hour > 12) && (hour <= 16)) {
      greeting = 'Good Afternoon';
    } else if ((hour > 16) && (hour < 24)) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    if (lastName == null) {
      return greeting;
    } else {
      return "$greeting, $lastName";
    }
  }
}
