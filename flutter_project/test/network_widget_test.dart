import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dima_project/Atest_lib/classes/course_model.dart';
import 'package:dima_project/Atest_lib/position_list_page.dart';
import 'package:dima_project/Atest_lib/map_page.dart';
import 'package:dima_project/Atest_lib/position_tablet_page.dart';
import 'package:dima_project/classes/position_model.dart';
import 'package:dima_project/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockNavigationObserver extends Mock implements NavigatorObserver {}
  PositionModel userPosition = PositionModel(
    latitude: '45.476713', // Politecnico di Milano
    longitude: '9.221591',
    timestamp: Timestamp.now(),
    description: 'test',
  );
    
MaterialApp app = MaterialApp(
  title: 'Community',
  initialRoute: '/',
  routes: {
    '/': (context) => ResponsiveLayout(mobileBody: PositionList(), tabletBody: PositionTablet()),
    '/map': (context) => MapScreen(userPosition: userPosition),
  },
);

void main() {
  late TestWidgetsFlutterBinding binding;

  setUp(() {
    binding = TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets("Render Screen", (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final networkTitle = find.byKey(Key("Network"));
    expect(networkTitle, findsOneWidget);

    final filter = find.byIcon(Icons.filter_alt_outlined); // course filter
    expect(filter, findsOneWidget);

    final currentUser = find.text('current user'); // current user
    expect(currentUser, findsOneWidget);
    final description = find.text('NOTES: description1');
    expect(description, findsOneWidget);
    final courseName = find.text('COURSE: course1');
    expect(courseName, findsOneWidget);

    final otherUser = find.text('firstname lastname'); // other user
    expect(otherUser, findsOneWidget);
    final noCourse = find.text('No course');
    expect(noCourse, findsAtLeastNWidgets(1));
    final noDescription = find.text('No additional notes');
    expect(noDescription, findsAtLeastNWidgets(1));

    final lastUpdate = find.textContaining('Last update:  '); // last update
    expect(lastUpdate, findsAtLeastNWidgets(3)); // position list has 3 users

    final profilePic = find.byType(CircleAvatar); // profile pic
    expect(profilePic, findsAtLeastNWidgets(3));

    final shareButton = find.byIcon(Icons.add_location_alt_outlined); // share button
    expect(shareButton, findsOneWidget);

  });

  testWidgets("Filter by course", (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final filter = find.byIcon(Icons.filter_alt_outlined);
    expect(filter, findsOneWidget);
    await tester.tap(filter); // open popup menu
    await tester.pumpAndSettle();

    final popupTitle = find.text('COURSE');
    expect(popupTitle, findsOneWidget);

    final noneText = find.text('None'); 
    expect(noneText, findsOneWidget);
    await tester.tap(noneText); // tap on None
    await tester.pumpAndSettle();

    final noCourseFound = find.text('No results found'); // no results found screen
    expect(noCourseFound, findsOneWidget);

    await tester.tap(filter); // reopen popup menu
    await tester.pumpAndSettle();

    final courseName = find.text('first');
    expect(courseName, findsOneWidget);
    await tester.tap(courseName); // tap on course
    await tester.pumpAndSettle();

  });

  testWidgets("Delete your position", (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final currentUser = find.byType(Dismissible); // current user
    expect(currentUser, findsOneWidget);
    await tester.drag(currentUser, Offset(-500, 0)); // swipe left to delete
    await tester.pumpAndSettle();

    final deleteDialog = find.byType(AlertDialog);
    expect(deleteDialog, findsOneWidget);

    final cancelButton = find.text('Cancel');
    expect(cancelButton, findsOneWidget);
    await tester.tap(cancelButton); // tap on cancel to close dialog
    await tester.pumpAndSettle();

    await tester.drag(currentUser, Offset(-500, 0)); // swipe left to delete
    await tester.pumpAndSettle();

    final deleteButton = find.text('Delete');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton); // tap on delete
    await tester.pumpAndSettle();

    final snack = find.text('Your position has been deleted'); // snack bar
    expect(snack, findsOneWidget);

  });

  testWidgets("Refresh position list", (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    //https://stackoverflow.com/questions/68357095/in-widget-tests-how-can-i-perform-a-pull-down-gesture
    await tester.fling(find.byType(ListView), const Offset(0, 400), 800);

    expect(
      tester.getSemantics(find.byType(RefreshProgressIndicator)),
      matchesSemantics(label: 'Refresh'),
    );

    await tester.pumpAndSettle();
  
  });

  testWidgets("Share position form", (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final openFormButton = find.byIcon(Icons.add_location_alt_outlined);
    expect(openFormButton, findsOneWidget);
    await tester.tap(openFormButton);
    await tester.pumpAndSettle();

    final formTitle = find.text('Share your position');
    expect(formTitle, findsOneWidget);

    final formImage = find.byKey(Key('image'));
    expect(formImage, findsAtLeastNWidgets(1));

    final myAddress = find.textContaining('YOU ARE HERE:');
    expect(myAddress, findsOneWidget);

    final descriptionField = find.byType(TextFormField);
    expect(descriptionField, findsOneWidget);
    await tester.enterText(descriptionField, 'test description'); // enter description
    var enteredText = tester.widget<TextFormField>(descriptionField).controller!.text;
    expect(enteredText, "test description"); 
    
    final courseField = find.byType(DropdownButtonFormField<CourseModel>);
    expect(courseField, findsOneWidget);
    await tester.tap(courseField); // open dropdown
    await tester.pumpAndSettle();

    final none = find.text('None').first;
    expect(none, findsOneWidget);

    final courseName = find.text('first').last;
    expect(courseName, findsOneWidget);
    await tester.tap(courseName); // tap on course
    await tester.pumpAndSettle();

    final shareButton = find.byType(ElevatedButton);
    expect(shareButton, findsOneWidget);
    // https://github.com/flutter/flutter/issues/76981
    await tester.scrollUntilVisible( // when keyboard is open, button is not visible, so scroll to find it
      shareButton,
      500.0,
      scrollable: find.descendant(
        of: find.byKey(Key('scrollableForm')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(shareButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final snack = find.text('Your current position has been saved'); // snack bar
    expect(snack, findsOneWidget);
  });

  testWidgets("Open map", (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    final userPosition = find.text('firstname lastname');
    expect(userPosition, findsOneWidget);
    await tester.tap(userPosition);
    await tester.pumpAndSettle(); // open map with user position

    final mapTitle = find.text('Check on the map');
    expect(mapTitle, findsOneWidget);

    final map = find.byType(FlutterMap);
    expect(map, findsOneWidget);

    final iconButton0 = find.byIcon(Icons.refresh_rounded);
    expect(iconButton0, findsOneWidget);
    await tester.tap(iconButton0);
    await tester.pumpAndSettle();

    final iconButton1 = find.byIcon(Icons.zoom_in);
    expect(iconButton1, findsOneWidget);
    await tester.tap(iconButton1);
    await tester.pumpAndSettle();

    final iconButton2 = find.byIcon(Icons.zoom_out);
    expect(iconButton2, findsOneWidget);
    await tester.tap(iconButton2);
    await tester.pumpAndSettle();

    final iconButton3 = find.byIcon(Icons.directions_car_rounded);
    expect(iconButton3, findsOneWidget);
    await tester.tap(iconButton3);
    await tester.pumpAndSettle();

    final iconButton4 = find.byIcon(Icons.directions_walk_rounded);
    expect(iconButton4, findsOneWidget);
    await tester.tap(iconButton4);
    await tester.pumpAndSettle();

    final iconButton5 = find.byIcon(Icons.my_location_rounded);
    expect(iconButton5, findsOneWidget);
    await tester.tap(iconButton5);
    await tester.pumpAndSettle();

  });

}
