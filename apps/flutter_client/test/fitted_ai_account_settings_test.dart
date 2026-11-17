import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/fitted_ai_account_settings.dart';

void main(){
  testWidgets('first member access never enables AI implicitly',
      (tester)async{
    final decisions=<bool>[];
    await tester.pumpWidget(MaterialApp(
      home:FittedAiAccountGate(onChoose:(value)async{
        decisions.add(value);
      }),
    ));
    expect(find.byKey(const Key('fitted-ai-first-access-title')),
      findsOneWidget);
    expect(decisions,isEmpty);
    expect(find.byKey(const Key('fitted-ai-first-access-enable')),
      findsOneWidget);
    expect(find.byKey(const Key('fitted-ai-first-access-disable')),
      findsOneWidget);
    await tester.tap(find.byKey(
      const Key('fitted-ai-first-access-disable')));
    await tester.pump();
    expect(decisions,[false]);
    expect(tester.takeException(),isNull);
  });

  testWidgets('global AI activation is explicit and opt-in',
      (tester)async{
    final decisions=<bool>[];
    await tester.pumpWidget(MaterialApp(home:FittedAiAccountGate(
      onChoose:(enabled)async=>decisions.add(enabled))));
    await tester.tap(find.byKey(
      const Key('fitted-ai-first-access-enable')));
    await tester.pump();
    expect(decisions,[true]);
    expect(tester.takeException(),isNull);
  });

  testWidgets('account settings switch saves current global preference',
      (tester)async{
    await tester.pumpWidget(MaterialApp(
      home:Builder(builder:(context)=>Scaffold(
        body:TextButton(
          onPressed:()async{
            final choice=await showDialog<bool>(context:context,
              builder:(_)=>const FittedAiAccountSettingsDialog(
                initial:false));
            if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content:Text('choice:$choice')));
          },
          child:const Text('Abrir configuración'),
        ),
      )),
    ));
    await tester.tap(find.text('Abrir configuración'));
    await tester.pumpAndSettle();
    final switcher=find.byKey(const Key('fitted-ai-account-switch'));
    expect(switcher,findsOneWidget);
    await tester.tap(switcher);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fitted-ai-settings-save')));
    await tester.pumpAndSettle();
    expect(find.text('choice:true'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
