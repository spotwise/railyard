
puts "Create users"
if User.count == 0
  # TODO: Remove or change test users
  User.create(:name => "Test user 1", :email => "test1@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
  User.create(:name => "Test user 2", :email => "test2@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
end