module Kernel
  # Is self included in other?
  #
  #   5.in?(0..10)       #=> true
  #   5.in?([0,1,2,3])   #=> false
  #
  def in?(arrayish, *more)
    arrayish = more.unshift(arrayish) unless more.empty?
    arrayish.include?(self)
  end
end