require 'ast'
require 'scanner'

# This module has two key classes: Parser and GenericParser
# GenericParser parses the ast in terms of generic LISP structures:
# Lists and atoms. Parser picks up where GenericParser left off, and
# creates more specific structures, like Defun and VarDecl. 

class ParseException < StandardError
end

class Parser
  def initialize(gen_parser)
    @gen_parser = gen_parser
  end
  
  # Uses GenericParser to get lists and atoms, 
  # Then parses the more specific AST out of them.
  def parse
    gen_ast = @gen_parser.parse
    program_node = Program.new
    defuns = parse_defuns(gen_ast)
    defuns.each { |defun| program_node.add_child(defun) }
    main_function = parse_main(gen_ast)
    program_node.main = main_function
    program_node
  end

  def parse_defuns(ast)
    nodes = get_defun_nodes(ast)
    parsed_defuns = []
    nodes.each do |dnode|
      parsed_defuns << parse_defun(dnode)
    end
    parsed_defuns
  end

  def parse_main(ast)
    main_func = MainFunc.new
    main_nodes = get_main_nodes(ast)
    main_nodes.each do |node| 
      main_func.add_child(parse_content_node(node))
    end
    main_func
  end

  def parse_defun(funcnode)
    name_node = funcnode.children[1]
    if name_node.ntype != :id:
        error("No name for defun")
    end
    name = name_node.value
    if funcnode.child_count < 4
      error("Too few children for defun: #{funcnode.child_count}")
    end
    param_list = funcnode.children[2]
    if param_list.ntype != :list
      error("No params list defined for defun")
    end
    params = []
    param_list.each_child do |param|
      if param.ntype != :id
        error("param list contains an item with invalid type: #{param.ntype}")
      end
      params << VarDecl.new(param.value, param.token)
    end
    defun = Defun.new(name, params, funcnode.token)
    funcnode.children[3..-1].each do |node|
        defun.add_child(parse_content_node(node))
    end
    defun
  end

  #Function call or special form (if, and etc..) parsing
  def parse_call(node)
    if node.child_count < 1 or node.children[0].ntype != :id
      error("call has to have at least an id parameter")
    end
    callee = node.children[0].value
    func_call = FuncCall.new(callee, node.token)
    node.children[1..-1].each do |node|
        func_call.add_child(parse_content_node(node))
    end
    func_call
  end

  def parse_content_node(node)
    if node.ntype == :list
      parse_call(node)
    elsif node.ntype == :id
      VarRef.new(node.value, node.token)
    elsif node.ntype == :number or node.ntype == :string
      node
    else
      nil
    end
  end
    
  def get_defun_nodes(ast)
    ast.children.select do |node|
      node.ntype == :list and 
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
    raise ParseException.new(msg)
  end
end
  

class GenericParser
  def initialize(scanner)
    @scanner = scanner
    @pushed_back = nil
  end

  def parse
    program_node = AstNode.new(:program)
    sexp.each do |member|
      program_node.add_child(member)
    end
    program_node
  end

  def sexp
    token = next_token
    members = []
    while token and token.ttype != :rparen
      case token.ttype
      when :lparen
        list = AstNode.new(:list)
        if peek.ttype != :rparen
          sexp.each do |member|
            list.add_child(member)          
          end
        end
        check_token(:rparen, next_token)
        members << list
      when :number
        members << AstNode.new(:number, token)
      when :string
        members << AstNode.new(:string, token)
      when :id
        members << AstNode.new(:id, token)
      else raise ParseException.new("Expected atom or list, but got #{token.ttype}")
      end
      token = next_token
      push_back(token) if token and token.ttype == :rparen 
    end
    members
  end

  def next_token
    if @pushed_back
      retval = @pushed_back
      @pushed_back = nil
      retval
    else
      @scanner.scan
    end
  end

  def push_back(token)
    raise ParseException.new("Only one pushback token allowed!") if @pushed_back
    @pushed_back = token
  end
  
  def peek
    peekval = next_token
    push_back(peekval)
    peekval
  end

  def check_token(exp_type, token)
    raise ParseException.new("Expected #{exp_type}, but got: #{token.ttype}") unless token.ttype == exp_type
  end

end
