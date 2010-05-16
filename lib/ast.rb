
# Contains the Node classes for both Generic and
# The more specific AST. The root class of both tree
# nodes is AstNode.

class AstNode
  attr_reader :ntype, :children, :token
  attr_accessor :ignore_retval
  def initialize(ntype, token=nil)
    @ntype = ntype
    @children = []
    @token = token
    # This attribute controls whether 
    # the return value should be popped from
    # stack or not (if true, nobody uses it -> pop)
    @ignore_retval = false
  end

  def value
    if token
      token.value
    else
      nil
    end
  end

  def add_child(child)
    @children << child
  end

  def child_count
    @children.size
  end

  def each_child
    @children.each do |child|
      yield child
    end
  end

  def last_child(node)
    node == @children.last
  end

  def to_s
    if value
      "#{@ntype}: #{value}"
    else
      @ntype
    end
  end

end

class NamedNode < AstNode
  attr_reader :name
  def initialize(type, name, token)
    super(type, token)
    @name = name
  end
  
  def value
    @name
  end
end

class BlockNode < NamedNode
  attr_accessor :block_id, :block_level
  def initialize(name, token)
    super(:defun, name, token)
    @block_id = nil
    @block_level = nil
  end
end

class Defun < NamedNode
  attr_reader :parameters
  def initialize(name, parameters, token)
    super(:defun, name, token)
    @parameters = parameters
  end

  def param_count
    @parameters.size
  end
end

class FuncCall < NamedNode
  def initialize(name, token)
    super(:func_call, name, token)
  end
end

class VarRef < NamedNode
  attr_accessor :target
  def initialize(name, token)
    super(:var_ref, name, token)
    @target = nil
  end
end

class VarDecl < NamedNode
  attr_accessor :block_id, :local_index
  def initialize(name, token)
    super(:var_decl, name, token)
    @block_id = nil
    @local_index = nil
  end
end

class MainFunc < AstNode
  def initialize
    super(:main)
  end
end

class Program < AstNode
  attr_accessor :main
  def initialize
    super(:program)
    @main = nil
  end

  def get_defun(name)
    @children.each do |defun|
      return defun if defun.name == name
    end
    return nil
  end
end

# A nice-to have util function
# for printing the AST
def print_node(node, indent, last)
  print(indent)
  if last
    print("\\-")
    indent += " "
  else
    print("|-")
    indent += "| "
  end
  puts node.to_s

  count = node.children.size
  count.times do |index|
    print_node(node.children[index], indent, index == count-1)
  end
end
