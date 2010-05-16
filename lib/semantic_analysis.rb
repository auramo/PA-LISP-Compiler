require 'ast'

class SemanticException < StandardError
end

# "Decorates" the tree with variable declaration block levels
# and adds associations from references to declarations

class VariableReferenceDecorator
  def initialize(program)
    @program = program
    @next_block_id = 1
    @block_id_stack = []
    @block_id_stack.push(0)
    @symbol_table = SymbolTable.new
  end

  def decorate
    handle_defuns
    handle_main
  end
  
  def handle_defuns
    @program.each_child do |defun|
      handle_defun(defun)
    end
  end

  def handle_defun(defun)
    enter_block
    decorate_declarations(defun.parameters)
    handle_block_children(defun)
    exit_block
  end

  def handle_main
    enter_block
    handle_block_children(@program.main, false)
    exit_block
  end

  def handle_block_children(blocknode, return_last=true)
    blocknode.each_child do |node|
      handle_node(node)
      unless blocknode.last_child(node) and return_last
        node.ignore_retval = true
      end
    end
  end

  def decorate_declarations(decls)
    decls.size.times do |i|
      decl = decls[i]
      decl.local_index = i
      decl.block_id = current_block_id
      @symbol_table.add_declaration(decl)
    end
  end

  def handle_node(node)
    if node.ntype == :var_ref
      handle_var_ref(node)
    else
      node.each_child do |child|
        handle_node(child)
      end
    end
  end

  def handle_var_ref(var_ref)
    name = var_ref.name
    best_match = nil
    best_match_level = 9999999 #should be larger than max stack depth
    @symbol_table.get_declarations(name).each do |decl|
      block_ids = @block_id_stack.clone
      stack_level = 1 #1 means top of stack, 2 one level down...
      while not block_ids.empty?
        block_id = block_ids.pop
        if decl.block_id == block_id && stack_level < best_match_level
          best_match = decl
          best_match_level = stack_level
          break
        end
        stack_level += 1
      end
    end
    if best_match == nil
      raise SemanticException.new("No match for #{var_ref.name} at #{var_ref.token.pos}") 
    end
    var_ref.target = best_match
  end

  def enter_block
    @block_id_stack.push(@next_block_id)
    @next_block_id += 1
    current_block_id
  end

  def exit_block
    @block_id_stack.pop
  end

  def current_block_id
    @block_id_stack.last
  end

end

class SymbolTable
  def initialize
    @table = {}
  end
  
  def add_declaration(var_decl)
    name = var_decl.name
    declarations = @table[name]
    if not declarations
      declarations = [var_decl]
      @table[name] = declarations
    else
      declarations << var_decl
    end
  end

  def get_declarations(name)
    decls = @table[name]
    if decls
      decls
    else
      []
    end
  end

end

