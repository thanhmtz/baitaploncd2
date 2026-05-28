import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/shared/utilities/utils.dart';
import 'package:health_tracker/ui/screens/auth/about/about_contents.dart';
import 'package:health_tracker/ui/screens/auth/about/widgets/gender_picker_widget.dart';
import 'package:health_tracker/shared/constants/consts_variables.dart';
import 'package:health_tracker/ui/screens/auth/registration_screen.dart';
import 'package:health_tracker/ui/widgets/button_widget.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:numberpicker/numberpicker.dart';

class AboutYouScreen extends StatefulWidget {
  final bool fromGoogle;
  const AboutYouScreen({Key? key, this.fromGoogle = false}) : super(key: key);

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  Sex sex = Sex.male;
  int age = 18, _currentPage = 0;
  double weight = 0;
  final _controller = PageController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aboutList = getAboutContents(l10n);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: aboutList.length,
                itemBuilder: (BuildContext context, int index) {
                  final body = index == 0
                      ? GenderPicker(
                          initialValue: sex == Sex.male ? 0 : 1,
                          onChanged: (v) => setState(() => sex = v == 0 ? Sex.male : Sex.female),
                        )
                      : index == 1
                          ? NumberPicker(
                              selectedTextStyle: const TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
                              minValue: 1,
                              maxValue: 140,
                              value: age,
                              onChanged: (v) => setState(() => age = v),
                            )
                          : HorizontalPicker(
                              initialPosition: InitialPosition.start,
                              minValue: 0,
                              maxValue: 500,
                              divisions: 1000,
                              height: 150,
                              onChanged: (v) => setState(() => weight = v),
                              suffix: 'kg',
                              activeItemTextColor: Colors.red,
                            );
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 50,
                        ),
                        Text(
                          aboutList[index].title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 32),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          aboutList[index].desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 70,
                        ),
                        body,
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _currentPage == 0
                            ? const Spacer()
                            : IconButton(
                                onPressed: () {
                                  _controller.previousPage(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeIn,
                                  );
                                },
                                icon: const Icon(Icons.arrow_back)),
                        ButtonWidget(
                            color: Colors.red,
                            width: 100,
                            title: _currentPage + 1 == aboutList.length
                                ? l10n.done
                                : l10n.next,
                            func: () async {
                              if (_currentPage + 1 == aboutList.length) {
                                if (age < 1) {
                                  debugPrint('Invalid age: $age (must be > 0)');
                                  showErrorToast(context, l10n.invalidAge);
                                  return;
                                }
                                if (weight <= 0) {
                                  debugPrint('Invalid weight: $weight (must be > 0)');
                                  showErrorToast(context, l10n.invalidWeight);
                                  return;
                                }
                                debugPrint('Saving user info - sex: $sex, age: $age, weight: $weight');
                                if (widget.fromGoogle) {
                                  final uid = FirebaseAuth.instance.currentUser?.uid;
                                  if (uid != null) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .update({
                                      'sex': sex == Sex.male ? 1 : 2,
                                      'age': age,
                                      'weight': weight,
                                    });
                                  }
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                } else {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SignUpScreen()));
                                }
                              } else {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                );
                              }
                            }),
                      ]),
                )),
          ],
        ),
      ),
    );
  }
}
