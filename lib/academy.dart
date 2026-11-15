import 'dart:math' as math;
import 'package:flutter/material.dart';

const purple = Color(0xff7c3aed);
const gold = Color(0xfffbbf24);
const aqua = Color(0xff22d3ee);
const midnight = Color(0xff15112d);
const success = Color(0xff22c55e);

class AcademyArt extends StatelessWidget {
  const AcademyArt({super.key, this.world = 0});
  final int world;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _AcademyPainter(world), child: const SizedBox.expand()),
  );
}

class _AcademyPainter extends CustomPainter {
  _AcademyPainter(this.world);
  final int world;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 220);
    final sky = [
      const Color(0xff4d2491), const Color(0xff23617d), const Color(0xff3a399d),
      const Color(0xff76276f), const Color(0xff353291),
    ][world % 5];
    final brush = Paint();
    const area = Rect.fromLTWH(0, 0, 400, 220);
    brush.shader = LinearGradient(
      begin: Alignment.topRight, end: Alignment.bottomLeft,
      colors: [sky, const Color(0xff17112e)],
    ).createShader(area);
    canvas.drawRect(area, brush);
    brush.shader = RadialGradient(colors: [aqua.withAlpha(105), aqua.withAlpha(0)])
        .createShader(Rect.fromCircle(center: const Offset(304, 85), radius: 96));
    canvas.drawRect(area, brush);
    brush.shader = null;
    final random = math.Random(37 + world);
    for (var i = 0; i < 46; i++) {
      brush.color = (i % 4 == 0 ? aqua : Colors.white).withAlpha(45 + random.nextInt(130));
      canvas.drawCircle(Offset(random.nextDouble() * 400, random.nextDouble() * 190),
          i % 7 == 0 ? 1.65 : .7, brush);
    }
    void polygon(List<Offset> points, Color color) {
      brush.color = color;
      canvas.drawPath(Path()..addPolygon(points, true), brush);
    }
    void ellipse(double x, double y, double w, double h, Color color) {
      brush.color = color;
      canvas.drawOval(Rect.fromCenter(center: Offset(x,y), width: w, height: h), brush);
    }
    for (final base in [const Offset(221, 68), const Offset(369, 109)]) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      polygon(const [Offset(-22,0),Offset(21,0),Offset(3,22),Offset(-11,15)], sky);
      ellipse(0, 0, 47, 9, aqua.withAlpha(154));
      canvas.restore();
    }
    polygon(const [Offset(234,133),Offset(383,123),Offset(352,173),Offset(319,206),
      Offset(283,190),Offset(258,160)], const Color(0xff37295b));
    polygon(const [Offset(236,135),Offset(297,142),Offset(319,206),Offset(277,183)], const Color(0xff6d488e));
    polygon(const [Offset(297,142),Offset(360,137),Offset(352,173),Offset(319,206)], const Color(0xff493575));
    ellipse(307, 128, 155, 31, const Color(0xff54a79a));
    ellipse(311, 122, 144, 26, const Color(0xff91dbb2));
    void tower(double x, double y, double width, double height) {
      final wall = Rect.fromLTWH(x, y, width, height);
      brush.shader = LinearGradient(colors: [Colors.white.withAlpha(240), const Color(0xff8f70cc)])
          .createShader(wall);
      canvas.drawRect(wall, brush);
      brush.shader = null;
      polygon([Offset(x-5,y+2),Offset(x+width/2,y-24),Offset(x+width+5,y+2)], const Color(0xff482374));
      polygon([Offset(x+width/2,y-24),Offset(x+width+5,y+2),Offset(x+width/2,y+2)], const Color(0xff764cbc));
      brush.color = gold;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x+width/2-2.5,y+10,5,10),
          const Radius.circular(3)), brush);
    }
    if (world == 2) {
      for (var i = 0; i < 4; i++) {
        final x = 259.0 + 25 * i;
        polygon([Offset(x-20,119),Offset(x+2,55+i*6.0),Offset(x+20,117)], const Color(0xff787bcf));
        polygon([Offset(x+2,55+i*6.0),Offset(x+20,117),Offset(x+3,119)], aqua.withAlpha(147));
      }
    } else {
      tower(281, 91, 18, 33);
      tower(302, world == 1 ? 92 : 63, 30, world == 1 ? 33 : 63);
      tower(337, 83, 21, 40);
    }
    for (var i=0;i<7;i++) {
      final x = i < 3 ? 250.0 + 9 * i : 345.0 + 6*(i-3);
      final y = i < 3 ? 126.0 - 2*i : 126.0 + (i-3)*2;
      polygon([Offset(x-6,y),Offset(x,y-19),Offset(x+7,y)], const Color(0xff1e685f));
      polygon([Offset(x,y-19),Offset(x+7,y),Offset(x,y)], const Color(0xff46b284));
    }
    final falls = Path()..moveTo(302,132)..quadraticBezierTo(327,154,304,218)
      ..lineTo(322,218)..quadraticBezierTo(339,165,315,132)..close();
    brush.shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xffc9fcff), aqua.withAlpha(5)])
      .createShader(const Rect.fromLTWH(300,132,40,88));
    canvas.drawPath(falls, brush);
    brush.shader = null;
    for (var i = 0; i < 5; i++) {
      ellipse(225 + 34.0 * i, 177 + (i % 2) * 15, 90, 16, Colors.white.withAlpha(24));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AcademyPainter oldDelegate) => oldDelegate.world != world;
}

class AcademyBanner extends StatelessWidget {
  const AcademyBanner({super.key, required this.title, required this.subtitle,
    this.world = 0, this.mascot = false, this.accessory = false});
  final String title, subtitle;
  final int world;
  final bool mascot, accessory;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Positioned.fill(child: AcademyArt(world: world)),
          Padding(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 146),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (mascot) Padding(padding: const EdgeInsets.only(bottom: 12),
                    child: Lumi(size: 62, accessory: accessory)),
                  FractionallySizedBox(widthFactor: largeText ? 1 : .62,
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: const TextStyle(color: Colors.white,
                      fontSize: 27, fontFamily: 'serif', fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  FractionallySizedBox(widthFactor: largeText ? 1 : .63,
                    alignment: Alignment.centerLeft,
                    child: Text(subtitle, style: const TextStyle(color: Color(0xfff0eaff),
                      fontWeight: FontWeight.w500))),
                ]),
            ),
          ),
        ],
      ),
    );
  }
}

class Lumi extends StatelessWidget {
  const Lumi({super.key, this.size = 88, this.accessory = false});
  final double size;
  final bool accessory;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Lumi the owl',
    image: true,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * .24),
        border: accessory ? Border.all(color: gold, width: 3) : null,
        boxShadow: [BoxShadow(color: purple.withAlpha(110), blurRadius: 22)]),
      child: ClipRRect(borderRadius: BorderRadius.circular(size * .23),
        child: Image.asset('assets/lumi.jpg', fit: BoxFit.cover, excludeFromSemantics: true)),
    ),
  );
}

class UrduText extends StatelessWidget {
  const UrduText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Text(text, textDirection: TextDirection.rtl, style: style);
}
