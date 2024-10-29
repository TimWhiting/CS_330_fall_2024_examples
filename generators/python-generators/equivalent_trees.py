import random

class Tree(object):
    def __init__(self, left, value, right):
        self.value = value
        self.left = left
        self.right = right
    
    def insert(self, value):
        if value < self.value:
            return Tree(self.left.insert(value) if self.left else Tree(None, value, None), self.value, self.right)
        elif value > self.value:
            return Tree(self.left, self.value, self.right.insert(value) if self.right else Tree(None, value, None))
        else:
            return self
    
    def __repr__(self):
        return "Tree(%s, %s, %s)" % (self.left, self.value, self.right)


    def walk(self):
        pass # TODO: implement this

def new_tree(seed):
    random.seed(seed)
    tree = Tree(None, random.randrange(0, 100), None)
    for i in range(10):
      tree = tree.insert(random.randrange(0, 100))
    return tree


def same(t1, t2):
    pass # TODO: implement this

print(same(new_tree(0), new_tree(0)))
print(same(new_tree(0), new_tree(1)))
