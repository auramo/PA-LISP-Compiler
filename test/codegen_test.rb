require 'test/unit'
require 'codegen'
require 'ast'
require 'scanner'

class TestClassGenerator < Test::Unit::TestCase

  def test_get_function_codes
    program = AstNode.new(:program)

    fun1 = create_defun
    fun2 = create_defun

    otherchild = AstNode.new(:list)
    otherchild.add_child(AstNode.new(:id, Token.new(:id, nil, "println")))

    program.add_child(fun1)
    program.add_child(fun2)
    program.add_child(otherchild)
    
    classgen = ClassGenerator.new(nil, nil, nil)
    
    assert_equal(2, classgen.get_function_nodes(program).size)
    assert_equal(1, classgen.get_main_nodes(program).size)
  end
  
  def create_defun
    fun = AstNode.new(:list)
    fun.add_child(AstNode.new(:id, Token.new(:id, nil, "defun")))
    fun
  end

end

