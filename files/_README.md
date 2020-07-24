
## POST CREATION SETUP

This web site was created using a template. Some typical changes will be
necessary, like changing from numerical input to dropdown boxes:

  FROM: <%= f.text_field :user_id, :class => 'text_field' %>
  TO  : <%= f.select(:user_id, User.all.map {|u| [ "%s [%s]" %
    [u.username, u.provider], u.id]}, :prompt => t('users.select_user') ) %>

  FROM: <%= f.text_field :author_id, :class => 'text_field' %>
  TO  : <%= f.select(:author_id, Author.all.map {|a| [a.name, a.id ]},
    :prompt => t('author.select_user') ) %>

