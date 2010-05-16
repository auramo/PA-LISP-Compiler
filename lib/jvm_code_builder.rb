
# This module handles the low-level details of 
# code generation in the Jasmin assembly format.
# It keeps track of certain specifics related to
# code generation, like the local variable count
# and max stack size for methods. 

class JvmBuilderException < StandardError
end

class JvmBuilder

  def initialize(output)
    method_reset
    @output = output
    @next_label_id = 1
  end

  def create_label
    label = "label_#{@next_label_id}"
    @next_label_id += 1
    label
  end

  def emit_start_class(name)
    write(".class public #{name}")
    write(".super java/lang/Object")
    write(".method public <init>()V")
    write("\taload_0")
    write("\tinvokespecial java/lang/Object/<init>()V")
    write("\treturn")
    write(".end method")
  end
  
  def emit_start_method(name, param_count)
    @current_method = []
    inc_locals(param_count)
    write(".method public static #{name}#{param_string(param_count)}Ljava/lang/Object;")
  end

  def emit_end_method
    write_limits
    writemb("areturn")
    writem(".end method")
    write_method_contents
  end

  def emit_start_main
    @current_method = []
    inc_locals #main has 1 argument
    write(".method public static main([Ljava/lang/String;)V")
  end

  def emit_end_main
    write_limits
    writemb("return")
    writem(".end method")
    write_method_contents
  end

  def emit_function_call(name, param_count)
    inc_stack if param_count == 0
    writemb("invokestatic #{name}#{param_string(param_count)}Ljava/lang/Object;")
  end

  def emit_number(number)
    inc_stack(3)
    inc_locals
    writemb("new java/lang/Integer")
    writemb("dup")
    writemb("ldc #{number}")
    writemb("invokespecial java/lang/Integer/<init>(I)V")
  end

  def emit_string(str)
    inc_stack
    inc_locals
    writemb('ldc "' + str + '"')
  end
    
  def emit_var_ref(local_index)
    inc_stack
    writemb("aload_#{local_index}")
  end
  
  def emit_null
    writemb("aconst_null")
  end

  def emit_true
    emit_number(1)
  end

  def emit_false
    emit_number(0)
  end

  def emit_label(label)
    writem(label + ":") #No indent for label!
  end

  def emit_pop
    writemb("pop")
  end

  def emit_eq_zero_jump_cond(els_label)
    writemb("ifeq #{els_label}")
  end

  def emit_gt_zero_jump_cond(label)
    writemb("ifgt #{label}")    
  end

  def emit_goto(goto_label)
    writemb("goto #{goto_label}")
  end

  # Boolean check not just checks that the Object is Integer with 
  # 0 or 1 as value, it also leaves that value on stack.
  def emit_boolean_check
    inc_stack
    writemb("invokestatic PaLispRuntime/checkBoolean(Ljava/lang/Object;)I")
  end

  def finish
    @output.close
  end

  def method_reset
    @current_method = nil
    @stack_limit = 0
    @locals_limit = 0
  end

  def inc_stack(inc=1)
    @stack_limit += inc
  end

  def inc_locals(inc=1)
    @locals_limit += inc
  end

  def write(line)
    @output.puts(line)
  end
  
  # Write to temporary buffer reserved for methods
  def writem(line, indent="")
    raise JvmBuilderException.new("Not in method") unless @current_method
    @current_method << indent + line
  end

  # Write to temporary buffer reserved for methods
  # b means method body (indented)
  def writemb(line)
    writem(line, "\t")
  end

  def write_limits
    write(".limit stack #{@stack_limit}")
    write(".limit locals #{@locals_limit}")
  end

  def write_method_contents
    @current_method.each do |line|
      write(line)
    end
    method_reset
  end

  def param_string(param_count)
    params = "("
    param_count.times { params += "Ljava/lang/Object;" }
    params += ")"
  end

end
