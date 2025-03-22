user = User.create(email: Faker::Internet.email, username: 'userName', role: 'editor', password: 'qwerty12')

Article.create([
  { title: 'First Article', content: 'Content of the first article.', user_id: user.id },
  { title: 'Second Article', content: 'Content of the second article.', user_id: user.id }
])