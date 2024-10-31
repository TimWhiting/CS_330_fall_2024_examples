import 'dart:math';

class Tree {
  Tree(this.left, this.value, this.right);
  Tree.leaf(this.value)
      : left = null,
        right = null;
  final Tree? left;
  final int value;
  final Tree? right;

  factory Tree.generate(int seed) {
    final rand = Random(seed);
    Tree tree = Tree.leaf(rand.nextInt(100));
    for (var i = 0; i < 10; i++) {
      tree = tree.insert(rand.nextInt(100));
    }
    return tree;
  }

  Tree insert(int value) {
    if (value < this.value) {
      return Tree(left == null ? Tree.leaf(value) : left!.insert(value),
          this.value, right);
    } else if (value > this.value) {
      return Tree(left, this.value,
          right == null ? Tree.leaf(value) : right!.insert(value));
    }
    return this;
  }

  @override
  String toString() {
    return 'Node($left, $value, $right)';
  }

  Iterable<int> walk() sync* {
    if (left != null) {
      // for (final lv in left!.walk()){
      //   yield lv;
      // }
      yield* left!.walk();
    }
    yield value;
    if (right != null) {
      yield* right!.walk();
    }
  }
}

bool same(Tree tree1, Tree tree2) {
  final tree2l = tree2.walk().toList();
  var length = 0;
  for (final (i, x) in tree1.walk().indexed){
    if (x != tree2l[i]) {
      return false;
    }
    length++;
  }
  return length == tree2l.length;
}

void main() {
  final tree1 = Tree.generate(42);
  final tree2 = Tree.generate(42);
  print(same(tree1, tree2));

  final tree3 = Tree.generate(43);
  print(same(tree1, tree3));
}
