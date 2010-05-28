class Twitter::Client
  @@ACCOUNT_URIS = {
    :rate_limit_status => '/account/rate_limit_status',
    :verify_credentials => '/account/verify_credentials'
  }
  
  @@RESPONSE_MODELS = {
    :rate_limit_status => Twitter::RateLimitStatus,
    :verify_credentials => Twitter::User
  }
  
  # Provides access to the Twitter rate limit status API.
  # 
  # You can find out information about your account status.  Currently the only 
  # supported type of account status is the <tt>:rate_limit_status</tt> which 
  # returns a <tt>Twitter::RateLimitStatus</tt> object.
  # 
  # Example:
  #  account_status = client.account_info
  #  puts account_status.remaining_hits
  def account_info(type = :rate_limit_status)
      response = http_get_request(@@ACCOUNT_URIS[type])
      bless_models(@@RESPONSE_MODELS[type].unmarshal(response.body))
  end

end
