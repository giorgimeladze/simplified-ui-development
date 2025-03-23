# README

when downloading the repository, run

* rails db:create
* rails db:migrate
* rails db:seed
* rails s
* go to localhost:3000

After this you have a user with email:giorgi@mail.example and password:123456 which is admin and editor@example.com/qwerty12 as editor


the links_renderer helper method is in 
* lib/links_renderer.rb -> 
it has default values and also accepts custom values (which I havn't implemented yet, the template for user to choose button alignments or color)

Furthermore interesting files for checking HATEOAS AND FSM
* app/controllers/articles_controller.rb.
* app/links/article_links.rb & app/links/general_links.rb
* app/models/article.rb
* app/policies/article_policy.rb
* app/views/articles have partial files that are rendered in controller
