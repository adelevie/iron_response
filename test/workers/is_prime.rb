require "iron_response"

IronResponse::Responder.new do
  def is_prime?(n)
    ("1" * n =~ /^1?$|^(11+?)\1+$/) == 0 ? false : true
  end

  result = is_prime?(params[:number])
  p result

  result
end