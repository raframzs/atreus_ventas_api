class Rack::Attack
  throttle("registrations/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end

  throttle("login/ip", limit: 20, period: 5.minutes) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  self.throttled_responder = lambda do |_req|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Demasiadas solicitudes. Por favor espera antes de intentarlo de nuevo." }.to_json ]
    ]
  end
end
