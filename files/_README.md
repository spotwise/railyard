
## POST CREATION SETUP

This web site was created using a template. Some typical changes will be
necessary:

- Update associations in model files, note that this will also require changes to test fixtures to be able to pass tests
- Changing from numerical input to dropdown boxes (see example code below)
- Update integration specifications in /spec/requests/api/v1 and then run 'rails rswag:specs:swaggerize' to generate the documentation


    FROM: <%= f.text_field :user_id, :class => 'text_field' %>
    TO: <%= f.select(:user_id, User.all.map {|u| [ "%s [%s]" %
    [u.username, u.provider], u.id]}, :prompt => t('users.select_user') ) %>

    FROM: <%= f.text_field :author_id, :class => 'text_field' %>
    TO: <%= f.select(:author_id, Author.all.map {|a| [a.name, a.id ]},
    :prompt => t('author.select_user') ) %>
