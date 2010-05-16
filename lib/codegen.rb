require 'parser'
require 'semantic_analysis'

# This module handles controls the code generation process. 
# It uses Parser, VariableReferenceDecorator and JvmBuilder
# instances from other classes to do it's job. 

class CodeGenException < StandardError
end

class ClassGenerator
  def initialize(parser, code_builder, classname)
    @parser = parser
    @code_builder = code_builder
    @classname = classname
    @program = nil
    init_mappings
  end

  # Map handler-methods for node types. This is done to avoid 
  # large case statements. The keys in this hash (dictionary, 
  # map in other languages) map to specific handle methods.
  def init_mappings
    @gen_methods = {
      'println' => method(:generate_println),
      '+' => method(:generate_plus),
      '-' => method(:generate_minus),
      '*' => method(:generate_multiply),
      '/' => method(:generate_divide),
      '<' => method(:generate_less_than),
      '>' => method(:generate_greater_than),
      '=' => method(:generate_equal),
      'if' => method(:generate_if),
      'or' => method(:generate_or),
      'and' => method(:generate_and),
      :number => method(:generate_number),
      :string => method(:generate_string),
      :var_ref => method(:generate_var_ref)
    }
  end

  # The key method of the whole compilation process. 
  # Retrieves the AST from parser, decorates it
  # and generates the code via JvmBuilder.
  def generate
    @program = @parser.parse
    VariableReferenceDecorator.new(@program).decorate
    @code_builder.emit_start_class(@classname)
    generate_functions(@program.children)
    generate_main(@program.main)
    @code_builder.finish
  end

  def generate_functions(func_nodes)
    func_nodes.each do |fnode|
      generate_function(fnode)
    end
  end

  def generate_function(defun)
    @code_builder.emit_start_method(defun.name, defun.parameters.size)
    defun.each_child do |node|
      generate_node(node)
    end
    @code_builder.emit_end_method
  end

  def generate_main(main_func)
    @code_builder.emit_start_main
    main_func.each_child do |mnode|
      generate_node(mnode)
    end
    @code_builder.emit_end_main
  end

  def generate_node(node)
    if node.ntype == :func_call
      searchfor = node.name
    else
      searchfor = node.ntype
    end
    method = @gen_methods[searchfor]
    if method
      method.call(node) 
    elsif node.ntype == :func_call
      generate_call(node)
    else
      error("No match for type: #{searchfor}")
    end
    if node.ignore_retval
      @code_builder.emit_pop
    end
  end

  def generate_if(node)
    if node.child_count > 3 or node.child_count < 2
      error("if form has illegal amount of children #{node.child_count}")
    end
    generate_node(node.children[0])
    @code_builder.emit_boolean_check
    #label for else or end of if body if false
    els_label = @code_builder.create_label
    end_label = @code_builder.create_label
    @code_builder.emit_eq_zero_jump_cond(els_label)
    generate_node(node.children[1])
    @code_builder.emit_goto(end_label)
    @code_builder.emit_label(els_label)
    if node.child_count == 3 #else
      generate_node(node.children[2])
    else
      @code_builder.emit_null
    end
    @code_builder.emit_label(end_label)
  end

  def generate_or(node)
    if node.child_count != 2
      error("Or requires two arguments")
    end
    generate_node(node.children[0])

    tru_label = @code_builder.create_label
    end_cond_label = @code_builder.create_label

    @code_builder.emit_boolean_check
    @code_builder.emit_gt_zero_jump_cond(tru_label)
    
    generate_node(node.children[1])
    @code_builder.emit_boolean_check
    @code_builder.emit_gt_zero_jump_cond(tru_label)
    
    @code_builder.emit_false
    @code_builder.emit_goto(end_cond_label)

    @code_builder.emit_label(tru_label)
    @code_builder.emit_true #first was true, but was eaten from stack, put it back
    @code_builder.emit_label(end_cond_label)
  end


  def generate_and(node)
    if node.child_count != 2
      error("And requires two arguments")
    end
    generate_node(node.children[0])

    fals_label = @code_builder.create_label
    end_cond_label = @code_builder.create_label

    @code_builder.emit_boolean_check
    @code_builder.emit_eq_zero_jump_cond(fals_label)
    
    generate_node(node.children[1])
    @code_builder.emit_boolean_check
    @code_builder.emit_eq_zero_jump_cond(fals_label)
    
    @code_builder.emit_true
    @code_builder.emit_goto(end_cond_label)

    @code_builder.emit_label(fals_label)
    @code_builder.emit_false
    @code_builder.emit_label(end_cond_label)
  end

  def generate_number(nnode)
    @code_builder.emit_number(nnode.value)
  end

  def generate_string(node)
    @code_builder.emit_string(node.value)
  end

  def generate_var_ref(node)
    @code_builder.emit_var_ref(node.target.local_index)
  end

  def generate_call(node)
    name = node.name
    call_target = @program.get_defun(name)
    if not call_target
      error("call target defun #{name} doesn't exist")
    end
    if call_target.param_count != node.child_count
      error("function #{name} takes " +
                                 "#{call_target.param_count}" +
                                 "arguments, not #{node.child_count}" +
                                 " as in call #{node.token.pos}")
    end
    node.each_child do |param|
      generate_node(param)
    end
    @code_builder.emit_function_call(@classname + "/" + name, node.child_count)
  end

  def generate_plus(node)
    generate_builtin_twoparam_func(node, "plus")
  end

  def generate_minus(node)
    generate_builtin_twoparam_func(node, "minus")
  end

  def generate_less_than(node)
    generate_builtin_twoparam_func(node, "lessThan")    
  end

  def generate_greater_than(node)
    generate_builtin_twoparam_func(node, "greaterThan")
  end

  def generate_equal(node)
    generate_builtin_twoparam_func(node, "equal")
  end

  def generate_multiply(node)
    generate_builtin_twoparam_func(node, "multiply")
  end

  def generate_divide(node)
    generate_builtin_twoparam_func(node, "divide")
  end

  def generate_builtin_twoparam_func(node, runtime_method)
    if node.child_count != 2
      error("#{node.name} requires two parameters, but was given #{node.child_count}")
    end
    generate_node(node.children[0])
    generate_node(node.children[1])
    @code_builder.emit_function_call("PaLispRuntime/#{runtime_method}", 2)
  end

  def generate_println(plnode)
    if plnode.child_count != 1
      error("println requires exactly one parameter")
    end
    generate_node(plnode.children[0])
    @code_builder.emit_function_call("PaLispRuntime/println", 1)
  end

  def get_function_nodes(ast)
    ast.children.select do |node|
        node.ntype == :list and 
        node.children.size >= 1 and
        node.children[0].value == "defun"
    end
  end

  def get_main_nodes(ast)
    ast.children.select do |node|
      if node.children.size >= 1 and node.children[0].value == "defun"
        false
      else
        true
      end
    end
  end

  def error(msg)
    raise CodeGenException.new(msg)
  end

end

