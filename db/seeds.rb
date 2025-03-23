user = User.create(email: 'editor@example.com', username: 'userName', role: 'editor', password: 'qwerty12')
User.create(email: 'giorgi@mail.example', username: 'GIorgi', role: 'admin', password: '123456')

Article.create([
  { title: 'First Article', content: 'Content of the first article.', user_id: user.id },
  { title: 'Second Article', content: 'Content of the second article.', user_id: user.id },
  { title: 'Third Article', content: 'Content of the third article.', user_id: user.id, status: 'published' },
  { title: 'Fourth Article', content: 'Content of the fourth article.', user_id: user.id, status: 'privated' },
  { title: 'Fifth Article', content: 'Content of the fifth article.', user_id: user.id, status: 'archived' }
])