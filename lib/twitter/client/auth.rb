class Twitter::Client
  @@AUTHENTICATION_URIS = {
    :verify => '/account/verify_credentials',
 }
  
	# Provides access to the Twitter verify credentials API.
	# 
	# You can verify Twitter user credentials with minimal overhead using this method.
  #
  # Note that this method isn't very interesting with Twitter shutting off basic authentication.  You can still use it to 
  # determine if the OAuth::AccessToken passed to Twitter::Client.new is valid or not.
  # 
	# Example:
	#  client.authenticate?("osxisforlightweights", "l30p@rd_s^cks!")
	def authenticate?()
    verify_credentials()
	end
	
private
  def verify_credentials()
    begin
  	  response = http_get_request("#{@@AUTHENTICATION_URIS[:verify]}.json")
      true
    rescue Twitter::RESTError => ex
  		false
    end
  end
end

