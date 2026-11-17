class Numeric
  #四舍五入，修正浮点数用
  def roundf(places)
    temp = self.to_s.length
    sprintf("%#{temp}.#{places}f", self).to_f
  end
end