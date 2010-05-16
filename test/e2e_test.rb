require 'test/unit'
require 'plc'

SEP=File::PATH_SEPARATOR
ASSEMBLE_COMMAND = "java -jar tools/jasmin.jar"
JAVA_COMMAND = "java -cp palisp-runtime/bin#{SEP}."

LARGER_TEST_PROGRAM_OUTPUT = <<EOF
(3*50)/10 should be 15. Output:
15
check for equality with 15
15 as expected
is 4 bigger than 5?
no
is 10 bigger than 9?
yes
EOF

class EndToEndTests <  Test::Unit::TestCase
  def test_app_output
    run_test("iftest1", "998")
    run_test("fctest", "3")
    run_test("fctest2", "9")
    run_test("stuff", "11")
    run_test("ortest1", "2\n1\n1\n1")
    run_test("andtest1", "2\n2\n2\n1")
    run_test("andortest1", "2\n1\n2\n1")
    run_test("lessthantest1", "1\n2")
    run_test("plusminustest1", "7")
    run_test("varreftest1", "16")
    run_test("strtest1", "hello")
    run_test("fibotest1", "55")
    run_test("sligthly_larger_test_program", LARGER_TEST_PROGRAM_OUTPUT.strip)
  end

  def run_test(name, exp_output)
    compile("testdata/#{name}.pal")
    output = `#{JAVA_COMMAND} #{name}`
    assert_equal(exp_output, output.strip)
  end

  def compile(filename)
    compiler = PaLispCompiler.new
    compiler.compile(filename)
    success = system(ASSEMBLE_COMMAND + " " + compiler.get_classname(filename) + ".j")
    flunk("assembly failed") unless success
  end

end
