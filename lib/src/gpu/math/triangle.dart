
import 'package:vector_math/vector_math.dart' as vm;


class Triangle {
  final vm.Vector2 a;
  final vm.Vector2 b;
  final vm.Vector2 c;

  Triangle(this.a, this.b, this.c);

  @override
  String toString() {
    return "triangle $a, $b, $c";
  }
}