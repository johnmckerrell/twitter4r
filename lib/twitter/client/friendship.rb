class Twitter::Client
  @@FRIENDSHIP_URIS = {
    :add => '/friendships/create',
    :remove => '/friendships/destroy',
    :show => '/friendships/show',
  }
	
  # Provides access to the Twitter Friendship API.
  # 
  # You can add and remove friends using this method.
  # 
  # <tt>action</tt> can be any of the following values:
  # * <tt>:add</tt> - to add a friend, you would use this <tt>action</tt> value
  # * <tt>:remove</tt> - to remove an existing friend from your friends list use this.
  # 
  # The <tt>value</tt> must be either the user to befriend or defriend's 
  # screen name, integer unique user ID or Twitter::User object representation.
  # 
  # Examples:
  #  screen_name = 'dictionary'
  #  client.friend(:add, 'dictionary')
  #  client.friend(:remove, 'dictionary')
  #  id = 1260061
  #  client.friend(:add, id)
  #  client.friend(:remove, id)
  #  user = Twitter::User.find(id, client)
  #  client.friend(:add, user)
  #  client.friend(:remove, user)
  def friend(action, value)
    raise ArgumentError, "Invalid friend action provided: #{action}" unless @@FRIENDSHIP_URIS.keys.member?(action)
    value = value.to_i unless value.is_a?(String)
    uri = "#{@@FRIENDSHIP_URIS[action]}.json"
    params = {}
    if value.is_a?(String)
      params["target_screen_name"] = value
    else
      params["target_id"] = value
    end
    if action == :show
      response = http_get_request(uri,params)
      JSON.parse(response.body)
    else
      response = http_post_request(uri,nil,params)
      bless_model(Twitter::User.unmarshal(response.body))
    end
  end
end
