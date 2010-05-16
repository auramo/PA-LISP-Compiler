NUM_REGEX = /\A\d+\Z/
ID_REGEX = /\A[a-zA-Z\*\/\+\-\*\/\<\>\=](\w)*\Z/

# This module contains the lexical scanner and 
# data structure classes related to scanner: tokens 
# and positions.

class EofReached < StandardError
end

class ScanException < StandardError
end

class Token
  attr_reader :ttype, :pos, :value
  def initialize(ttype, pos, value=nil)
    @ttype = ttype
    @value = value
    @pos = pos
  end
end

class Scanner
  def initialize(input)
    @input = input
    @pos = PositionTracker.new
  end
  
  # Scan the next token, returns nil when
  # EOF is reached
  def scan
    begin
      skip_garbage
      get_next_token
    rescue EofReached => eof
      return nil
    end
  end

  #Gives the next char. The next char is available in the input
  #after this (it's pushed back)
  def peek
    next_c = @input.getc
    raise EofReached.new unless next_c
    @input.ungetc(next_c)
    next_c
  end

  def nextchar
    char = @input.getc
    @pos.advance(char)
    char
  end

  def pushback(char)
    @input.ungetc(char)
    @pos.goback(char)
  end

  def get_next_token
    next_c = peek
    case next_c.chr
      when "(" then handle_lparen
      when ")" then handle_rparen
      when '"' then handle_string
      when NUM_REGEX then handle_num
      when ID_REGEX then handle_id
      else raise ScanException.new("Unexpected char " + next_c.chr)
    end
  end

  def handle_lparen
    nextchar
    Token.new(:lparen, @pos.current_pos)
  end

  def handle_rparen
    nextchar
    Token.new(:rparen, @pos.current_pos)
  end

  def handle_num
    numstr = nextchar.chr
    tokenpos = @pos.current_pos
    while Scanner.matches_number(numstr) do
      next_c = nextchar
      eof_check(next_c, "number")
      numstr += next_c.chr
    end
    pushback(next_c)
    Token.new(:number, tokenpos, Integer(numstr[0..-2]))
  end

  def handle_id
    idstr = nextchar.chr
    tokenpos = @pos.current_pos
    while Scanner.matches_id(idstr) do
      next_c = nextchar
      eof_check(next_c, "identifier")
      idstr += next_c.chr
    end
    pushback(next_c)
    Token.new(:id, tokenpos, idstr[0..-2].strip)
  end

  def handle_string
    tokenpos = @pos.current_pos
    nextchar #skip the start doublequote
    next_c = nextchar
    eof_check(next_c, "string")
    token_val = ""
    while next_c != ?" do
      token_val += next_c.chr
      next_c = nextchar
      eof_check(next_c, "string")
    end
    Token.new(:string, tokenpos, token_val)
  end

  def eof_check(char, typestr)
    raise ScanException.new("Unexpected eof in the middle of a #{typestr}") unless char
  end
  
  #Skips comments and whitespaces
  def skip_garbage
    next_c = peek
    while true
      if is_whitespace(next_c)
        skip_whitespaces
      elsif next_c == ?;
        skip_comments
      else 
        break
      end
      next_c = peek
    end
  end

  def skip_whitespaces
    next_c = nextchar_eof
    while is_whitespace(next_c) do
      next_c = nextchar_eof
    end
    pushback(next_c)
  end

  def skip_comments
    next_c = nextchar_eof
    while next_c == ?; or next_c != ?\n do
      next_c = nextchar_eof
    end
  end
  
  def is_whitespace(c)
    [?\s, ?\t, ?\r, ?\n].include?(c)
  end

  #Like nextchar, but throws EofReached when EOF reached
  def nextchar_eof
    next_c = nextchar
    raise EofReached.new unless next_c
    next_c
  end

  def Scanner.matches_number(token)
    NUM_REGEX =~ token
  end

  def Scanner.matches_id(token)
    ID_REGEX =~ token
  end

end


class Position
  attr_reader :line, :column
  def initialize(line, column)
    @line = line
    @column = column
  end
  def to_s
    "#{@line}, #{@column}"
  end
end

class PositionTracker
  attr_reader :line, :column
  def initialize
    @line = 1
    @column = 0
    @prevcolumn = nil
  end

  def current_pos
    Position.new(@line, @column)
  end

  def advance(char)
    if char == ?\n
      @line += 1
      @prevcolumn = @column
      @column = 0
    else
      @column += 1
    end
  end

  def goback(char)
    if char == ?\n
      @line -=1
      @column = @prevcolumn
    else
      @column -=1
    end
    nil
  end
end
