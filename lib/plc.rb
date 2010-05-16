require 'parser'
require 'codegen'
require 'jvm_code_builder'

# This module puts all the classes together and handles
# some file naming logic. It's the main entry point to
# the PA-LISP compiler.

class PaLispCompiler

  def compile(inputfilename)
    classname = get_classname(inputfilename)
    outputfilename = classname + ".j"

    inputfile = File.open(inputfilename)
    outputfile = File.open(outputfilename, "w")

    parser = Parser.new(GenericParser.new(Scanner.new(inputfile)))
    jvmBuilder = JvmBuilder.new(outputfile)
    generator = ClassGenerator.new(parser, jvmBuilder, classname)

    generator.generate
  end

  def get_classname(inputfile)
    input_no_suffix = inputfile[0,inputfile.index(".")]
    start_index = input_no_suffix.rindex(File::SEPARATOR)
    if start_index
      start_index += 1
    else
      start_index = 0
    end
    input_no_suffix[start_index..-1]
  end

end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size < 1
    puts "Usage: plc.rb <pa-lisp-sourcefile>"
    Process.exit(1)
  end
  inputfilename = ARGV[0]
  compiler = PaLispCompiler.new
  begin
    compiler.compile(inputfilename)
  rescue => ex 
    puts "#{ex.class}: #{ex.message}"
    Process.exit(1)
  end
end

