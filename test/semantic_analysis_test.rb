require 'test/unit'
require 'parser'
require 'stringio'
require 'semantic_analysis'

class TestVariableReferenceDecorator < Test::Unit::TestCase

  def test_defun_varref
    program = get_program("(defun myfun (a b) (+ (+ 1 1) (+ a b)))" + 
                          "(defun second (z) z)")
    decorator = VariableReferenceDecorator.new(program)
    decorator.decorate

    myfun = program.children[0]
    params = myfun.parameters
    a = params[0]
    b = params[1]
    assert_equal(1, a.block_id)
    assert_equal(0, a.local_index)
    assert_equal(1, b.block_id)
    assert_equal(1, b.local_index)
    aref = myfun.children[0].children[1].children[0]
    assert_equal(a, aref.target)
    bref = myfun.children[0].children[1].children[1]
    assert_equal(b, bref.target)

    second = program.children[1]
    params = second.parameters
    z = params[0]
    assert_equal(2, z.block_id)
    assert_equal(0, z.local_index)
    zref = second.children[0]
    assert_equal(z, zref.target)
    assert_equal(0, zref.target.local_index)
  end

  def get_program(input_str)
    parser = Parser.new(GenericParser.new(Scanner.new(StringIO.open(input_str))))
    parser.parse
  end

end
