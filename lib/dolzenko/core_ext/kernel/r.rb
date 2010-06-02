module Kernel
  def r(*args)
    raise (args.size == 1 ? args[0] : args).inspect
  end
end