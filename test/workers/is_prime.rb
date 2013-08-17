require "iron_response"

IronResponse::Worker.new(binding) do
  def is_prime?(n)
    ("1" * n =~ /^1?$|^(11+?)\1+$/) == 0 ? false : true
  end

  {
   result: is_prime?(params[:number])
  }
end