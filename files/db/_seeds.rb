
puts "Create users"
if User.count == 0
  # TODO: Remove or change test users
  User.create(:first_name => "Joe", :last_name => "Doe", :email => "test1@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
  User.create(:first_name => "Jane", :last_name => "Smith", :email => "test2@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
end