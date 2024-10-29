var seed = require('seed-random');

class Tree {
  constructor(left, value, right) {
    this.left = left;
    this.value = value;
    this.right = right;
  }

  static new_tree(s) {
    let rand = seed(s)
    let tree = new Tree(null, rand(), null);
    for (let i = 0; i < 10; i++) {
      tree = Tree.insert(tree, rand());
    }
    return tree;
  }

  static insert(tree, value) {
    if (tree === null) {
      return new Tree(null, value, null);
    } else if (value < tree.value) {
      return new Tree(Tree.insert(tree.left, value), tree.value, tree.right);
    } else {
      return new Tree(tree.left, tree.value, Tree.insert(tree.right, value));
    }
  }

  *walk() {
    // TODO: Implement this function
  }
}

function same(tree1, tree2) {
  // TODO: Implement this function
}

console.log(same(Tree.new_tree('0'), Tree.new_tree('0')))
console.log(same(Tree.new_tree('0'), Tree.new_tree('1')))