require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it 'has many articles' do
      expect(user).to respond_to(:articles)
      article = create(:article, user: user)
      expect(user.articles).to include(article)
    end

    it 'has many comments' do
      expect(user).to respond_to(:comments)
      article = create(:article, user: user)
      comment = create(:comment, article: article, user: user)
      expect(user.comments).to include(comment)
    end

    it 'has many article2s' do
      expect(user).to respond_to(:article2s)
    end

    it 'has many comment2s' do
      expect(user).to respond_to(:comment2s)
    end

    it 'has one custom_template' do
      expect(user).to respond_to(:custom_template)
      expect(user.custom_template).to be_present
    end
  end

  describe 'devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end
  end

  describe 'roles' do
    it 'has viewer role as default' do
      new_user = User.create!(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123'
      )
      expect(new_user.role).to eq('viewer')
    end

    it 'can be set to editor role' do
      user.update!(role: :editor)
      expect(user.role).to eq('editor')
    end

    it 'can be set to admin role' do
      user.update!(role: :admin)
      expect(user.role).to eq('admin')
    end
  end

  describe 'role methods' do
    context 'when user is admin' do
      let(:admin) { create(:user, role: :admin) }

      it 'returns true for admin?' do
        expect(admin.admin?).to be true
      end

      it 'returns false for editor?' do
        expect(admin.editor?).to be false
      end

      it 'returns false for viewer?' do
        expect(admin.viewer?).to be false
      end
    end

    context 'when user is editor' do
      let(:editor) { create(:user, role: :editor) }

      it 'returns false for admin?' do
        expect(editor.admin?).to be false
      end

      it 'returns true for editor?' do
        expect(editor.editor?).to be true
      end

      it 'returns false for viewer?' do
        expect(editor.viewer?).to be false
      end
    end

    context 'when user is viewer' do
      let(:viewer) { create(:user, role: :viewer) }

      it 'returns false for admin?' do
        expect(viewer.admin?).to be false
      end

      it 'returns false for editor?' do
        expect(viewer.editor?).to be false
      end

      it 'returns true for viewer?' do
        expect(viewer.viewer?).to be true
      end
    end
  end

  describe 'callbacks' do
    it 'creates a custom_template after user creation' do
      expect {
        User.create!(
          email: 'newuser@example.com',
          username: 'newuser',
          password: 'password123'
        )
      }.to change(CustomTemplate, :count).by(1)
    end

    it 'creates custom_template with default data' do
      new_user = User.create!(
        email: 'newuser@example.com',
        username: 'newuser',
        password: 'password123'
      )
      
      template = new_user.custom_template
      expect(template).to be_present
      expect(template.template_data).to eq(CustomTemplate::DEFAULT_TEMPLATE)
    end
  end
end
