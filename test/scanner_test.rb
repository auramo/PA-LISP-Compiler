require 'scanner'
require 'test/unit'
require "stringio"

class TestScanner < Test::Unit::TestCase

  def test_whitespace_skipping
    input = StringIO.open("\t\s \n\ra")
    scanner = Scanner.new(input)
    scanner.skip_whitespaces
    assert_equal(?a, input.getc())
  end

  def test_whitespace_skipping_eof
    scanner = get_scanner(" ")
    assert_nil(scanner.scan())
  end

  def test_parens
    scanner = get_scanner("(")
    checkp_token(scanner, :lparen)
    scanner = get_scanner(")")
    checkp_token(scanner, :rparen)
  end

  def test_num
    checkp_token(get_scanner("237)"), :number, 237)
    checkp_token(get_scanner("0)"), :number, 0)
  end

  def test_id
    checkp_token(get_scanner("ab)"), :id, "ab")
    checkp_token(get_scanner("z)"), :id, "z")
  end

  def test_multiple_tokens
    scanner = get_scanner("(a 1 \r\n( z_ \t98))")
    check_token(scanner.scan, :lparen, nil, 1, 1)
    check_token(scanner.scan, :id, "a", 1, 2)
    check_token(scanner.scan, :number, 1, 1, 4)
    check_token(scanner.scan, :lparen, nil, 2, 1)
    check_token(scanner.scan, :id, "z_", 2, 3)
    check_token(scanner.scan, :number, 98)
    check_token(scanner.scan, :rparen)    
    check_token(scanner.scan, :rparen)
    assert_nil(scanner.scan)
  end

  def test_id_match
    assert(Scanner.matches_id("a"))
    assert(Scanner.matches_id("a1"))
    assert(Scanner.matches_id("a1_"))
    assert(!Scanner.matches_id("1"))
    assert(!Scanner.matches_id("_"))
  end

  def test_number_match
    assert(Scanner.matches_number("0"))
    assert(Scanner.matches_number("2311"))
    assert(!Scanner.matches_number("1."))
    assert(!Scanner.matches_number("1a"))
  end

  def checkp_token(scanner, type, value=nil)
    token = scanner.scan
    check_token(token, type, value)
  end

  def check_token(token, type, value=nil, line=nil, col=nil)
    assert_equal(type, token.ttype)
    assert_equal(value, token.value) if value
    assert_equal(line, token.pos.line) if line
    assert_equal(col, token.pos.column) if col    
  end

  def get_scanner(input_str)
    input = StringIO.open(input_str)
    Scanner.new(input)
  end
end
