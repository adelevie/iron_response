require "iron_response"

IronResponse::Responder.new do
  def is_prime?(n)
    ("1" * n =~ /^1?$|^(11+?)\1+$/) == 0 ? false : true
  end


  is_prime? params["number"]
end