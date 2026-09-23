import 'package:flutter/material.dart';

class IndoorBlueDot extends StatelessWidget {

  final Offset position;

  final double heading;

  const IndoorBlueDot({
    super.key,
    required this.position,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {

    return TweenAnimationBuilder<Offset>(

      duration: const Duration(milliseconds: 1000),

      curve: Curves.linear,

      tween: Tween<Offset>(
        begin: position,
        end: position,
      ),

      builder: (context, animatedPosition, child) {
        
        return Positioned(

          left: animatedPosition.dx - 18,

          top: animatedPosition.dy - 18,

          child: child!,
        );
      },

      child: TweenAnimationBuilder<double>(

        duration: const Duration(milliseconds: 1000),

        curve: Curves.linear,

        tween: Tween<double>(
          begin: heading,
          end: heading,
        ),

        builder: (
            context,
            value,
            child,
            ) {

          return Transform.rotate(

            angle: value * 3.1415926535 / 180,

            child: child,
          );
        },

        child: Stack(

          alignment: Alignment.center,

          children: [

            /// OUTER GLOW
            Container(

              width: 36,

              height: 36,

              decoration: BoxDecoration(

                color:
                Colors.blue.withOpacity(0.18),

                shape: BoxShape.circle,
              ),
            ),

            /// MAIN BLUE DOT
            Container(

              width: 22,

              height: 22,

              decoration: BoxDecoration(

                color: Colors.blue,

                shape: BoxShape.circle,

                border: Border.all(

                  color: Colors.white,

                  width: 3,
                ),

                boxShadow: const [

                  BoxShadow(

                    color: Colors.black26,

                    blurRadius: 6,
                  ),
                ],
              ),
            ),

            /// DIRECTION POINTER
            Positioned(

              top: 1,

              child: Icon(

                Icons.navigation,

                size: 16,

                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}