class Greeting {
  static String getGreeting() {
    var hour = DateTime.now().hour;
    final String greeting;

    if (hour <= 12) {
      greeting = 'Good Morning';
    } else if ((hour > 12) && (hour <= 16)) {
      greeting = 'Good Afternoon';
    } else if ((hour > 16) && (hour < 20)) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    // TODO: Concatenate w/ last name

    return greeting;
  }
}
