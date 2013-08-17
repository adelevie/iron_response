require "iron_response"

IronResponse::Worker.new(binding) do
  {
    "result" => params
  }
end