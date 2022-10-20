import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spine_core/spine_core.dart';
import 'package:spine_flutter/spine_flutter.dart';

/// \see http://ru.esotericsoftware.com/spine-runtimes-guide
void main() => runApp(const MyApp());

/// All animations. Format: `model_name: defaultAnimation`.
const Map<String, String> all = <String, String>{
  // 'cauldron': 'idle',
  // 'fox': 'idle',
  // 'girl_and_whale_polygons': 'idle',
  // 'girl_and_whale_rectangles': 'idle',
  // 'owl': 'idle',
  // 'raptor': 'walk',
  // 'spineboy': 'walk',
  //'democharacter': 'HAND_WAVE',
  'democharacter2': 'idle',
};

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Spine Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  static const String pathPrefix = 'assets/';

  String name = all.keys.last;

  late Set<String> animations;
  late Set<String> skins;
  late SkeletonAnimation skeleton;

  @override
  Widget build(BuildContext context) => _buildFuture();

  Widget _buildFuture() => FutureBuilder<bool>(
        future: load(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            if (animations.isNotEmpty) {
              final String defaultAnimation = all[name]!;
              skeleton.state.setAnimation(0, defaultAnimation, true);
            }

            return _buildScreen();
          }

          return Container(
            color: Colors.red,
          );
        },
      );

  Widget _buildScreen() {
    final SkeletonRenderObjectWidget skeletonWidget =
        SkeletonRenderObjectWidget(
      skeleton: skeleton,
      animation: all[name],
      alignment: Alignment.center,
      fit: BoxFit.contain,
      playState: PlayState.playing,
      debugRendering: false,
      triangleRendering: true,
      //frameSizeMultiplier: 0.3,
    );

    final List<Widget> models = <Widget>[];
    for (final String model in all.keys) {
      models.add(
        TextButton(
          child: Text(model.toUpperCase()),
          onPressed: () async {
            name = model;
            await load();
            setState(() {
              final String defaultAnimation = all[name]!;
              skeleton.state.setAnimation(0, defaultAnimation, false);
            });
          },
        ),
      );
    }

    final List<Widget> skinsWidgget = <Widget>[];
    for (final String skin in skins) {
      skinsWidgget.add(
        TextButton(
          child: Text(skin),
          onPressed: () {
            if (skin != "skin_1") return;

            var tempSkin = skeleton.data.findSkin("skin_2");

            var newSkin = Skin("new_skin");
            Attachment? attachment = tempSkin?.getAttachment(11, "torso-blue");
            newSkin.addAttachment(11, "torso-blue", attachment!);

            skeleton.setSkin(newSkin);
          },
        ),
      );
    }

    final List<Widget> states = <Widget>[];
    for (final String animation in animations) {
      states.add(
        TextButton(
          child: Text(animation.toLowerCase()),
          onPressed: () {
            skeleton.state.setAnimation(0, animation, true);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(name)),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: Container(
              height: 400,
              child: skeletonWidget,
            ),
          ),
          // Positioned.fill(
          //   child: Wrap(
          //     runAlignment: WrapAlignment.start,
          //     children: models,
          //   ),
          // ),
          Positioned.fill(
            child: Wrap(
              runAlignment: WrapAlignment.end,
              children: states,
            ),
          ),
          Positioned.fill(
            child: Wrap(
              runAlignment: WrapAlignment.start,
              children: skinsWidgget,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> load() async {
    animations = await loadAnimations();
    skeleton = await loadSkeleton();
    skins = await loadSkins();

    return true;
  }

  Future<Set<String>> loadSkins() async {
    final String skeletonFile = '$name.json';
    final String s =
        await rootBundle.loadString('$pathPrefix$name/$skeletonFile');
    final Map<String, dynamic> data = json.decode(s);

    return ((data['skins'] ?? <String, dynamic>{}) as Map<String, dynamic>)
        .keys
        .toSet();
  }

  Future<Set<String>> loadAnimations() async {
    final String skeletonFile = '$name.json';
    final String s =
        await rootBundle.loadString('$pathPrefix$name/$skeletonFile');
    final Map<String, dynamic> data = json.decode(s);

    return ((data['animations'] ?? <String, dynamic>{}) as Map<String, dynamic>)
        .keys
        .toSet();
  }

  Future<SkeletonAnimation> loadSkeleton() async =>
      SkeletonAnimation.createWithFiles(name, pathBase: pathPrefix);
}
