require 'test/unit'
require 'parser'
require 'ast'
require 'stringio'

# Util methods to be used as Ruby mixins in test classes
module PTUtil

  def check_child(node, nth, type, value=nil)
    child = node.children[nth]
    assert_equal(type, child.ntype)
    assert_equal(value, child.value) if value
  end

  def get_generic_parser(input_str)
    input = StringIO.open(input_str)
    GenericParser.new(Scanner.new(input))
  end

  def get_parser(input_str)
    parser = Parser.new(get_generic_parser(input_str))
  end

end

class TestParser < Test::Unit::TestCase
  include PTUtil
  def test_defun
    parser = get_parser("(defun myfun (par1 par2) (+ par1 par2))")
    ast = parser.parse
    defun = ast.children[0]
    assert_equal(:defun, defun.ntype)
    assert_equal("myfun", defun.name)
    params = defun.parameters
    assert_equal(2, params.size)
    par1 = params[0]
    par2 = params[1]
    assert_equal(:var_decl, par1.ntype)
    assert_equal("par1", par1.name)
    assert_equal("par2", par2.name)
    assert_equal(1, defun.child_count)
    plus = defun.children[0]
    assert_equal(:func_call, plus.ntype)
  end

  def test_empty_param_defun
    parser = get_parser("(defun f () 2)")
    defun = parser.parse.children[0]
  end

  def test_get_defun
    parser = get_parser("(defun f1 (a) 1) (defun f2 (b) 2)")
    program = parser.parse
    assert_equal(nil, program.get_defun("f3"))
    assert_equal("f1", program.get_defun("f1").name)
    assert_equal("f2", program.get_defun("f2").name)
  end
end

class TestGenericParser < Test::Unit::TestCase
  include PTUtil
  def test_func_call
    parser = get_generic_parser("(myfunc par1 7)")
    root = parser.parse.children[0]
    assert_equal(:list, root.ntype)
    c1 = root.children[0]
    assert_equal(:id, c1.ntype)
    assert_equal("myfunc", c1.value)
    c2 = root.children[1]
    assert_equal(:id, c2.ntype)
    assert_equal("par1", c2.value)
    c3 = root.children[2]
    assert_equal(:number, c3.ntype)
    assert_equal(7, c3.value)
  end

  def test_func_definition
    parser = get_generic_parser("(defun myfun (par1 par2) (+ par1 par2))")
    root = parser.parse.children[0]
    check_child(root, 0, :id, "defun")
    check_child(root, 1, :id, "myfun")
    check_child(root, 2, :list)
    check_child(root, 3, :list)
    function_parameters = root.children[2]
    check_child(function_parameters, 0, :id, "par1")
    check_child(function_parameters, 1, :id, "par2")
    function_contents = root.children[3]
    check_child(function_contents, 0, :id, "+")
    check_child(function_contents, 1, :id, "par1")
    check_child(function_contents, 2, :id, "par2")
  end

end

