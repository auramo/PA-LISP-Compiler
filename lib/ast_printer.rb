require 'parser'
require 'ast'

# A helper class for printing out ASTs.
# Prints both the "generic" and "specific" 
# AST of a certain PA-LISP program.

def with_generic_parser(file)
  file = File.open(file)
  parser = GenericParser.new(Scanner.new(file))
  yield(parser)
  file.close
end

def print_generic_ast(file)
  with_generic_parser(file) do |parser|
    ast = parser.parse
    print_node(ast, "", true)
  end
end

def print_processed_ast(file)
  with_generic_parser(file) do |gen_parser|
    parser = Parser.new(gen_parser)
    ast = parser.parse
    print_node(ast, "", true)
  end
end

if __FILE__ == $PROGRAM_NAME
  print_generic_ast(ARGV[0])
  print_processed_ast(ARGV[0])
end
