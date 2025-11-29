require 'rails_helper'

RSpec.describe CommentBlueprint do
  let(:user) { create(:user, role: :viewer) }
  let(:article) { create(:article, user: create(:user, role: :editor)) }
  let(:comment) { create(:comment, article: article, user: user) }
  let(:admin) { create(:user, role: :admin) }
  let(:other_user) { create(:user, role: :viewer) }

  describe 'base view' do
    it 'includes identifier' do
      result = CommentBlueprint.render(comment, context: { current_user: user })
      parsed = JSON.parse(result)
      
      expect(parsed['id']).to eq(comment.id)
    end

    it 'includes text, status, and user_id' do
      result = CommentBlueprint.render(comment, context: { current_user: user })
      parsed = JSON.parse(result)
      
      expect(parsed['text']).to eq(comment.text)
      expect(parsed['status']).to eq(comment.status)
      expect(parsed['user_id']).to eq(comment.user_id)
    end

    context 'rejection_feedback field' do
      before do
        comment.update!(rejection_feedback: 'Inappropriate content')
      end

      it 'includes rejection_feedback for admin' do
        result = CommentBlueprint.render(comment, context: { current_user: admin })
        parsed = JSON.parse(result)
        
        expect(parsed['rejection_feedback']).to eq('Inappropriate content')
      end

      it 'includes rejection_feedback for comment owner' do
        result = CommentBlueprint.render(comment, context: { current_user: user })
        parsed = JSON.parse(result)
        
        expect(parsed['rejection_feedback']).to eq('Inappropriate content')
      end

      it 'excludes rejection_feedback for other users' do
        result = CommentBlueprint.render(comment, context: { current_user: other_user })
        parsed = JSON.parse(result)
        
        expect(parsed['rejection_feedback']).to be_nil
      end

      it 'excludes rejection_feedback when user is nil' do
        result = CommentBlueprint.render(comment, context: { current_user: nil })
        parsed = JSON.parse(result)
        
        expect(parsed['rejection_feedback']).to be_nil
      end
    end
  end

  describe 'show view' do
    it 'includes links field' do
      result = CommentBlueprint.render(comment, view: :show, context: { current_user: user })
      parsed = JSON.parse(result)
      
      expect(parsed['links']).to be_an(Array)
    end

    it 'includes hypermedia show links' do
      allow(comment).to receive(:hypermedia_show_links).and_return([
        { rel: 'self', href: '/comments/1', title: 'Comment' }
      ])
      
      result = CommentBlueprint.render(comment, view: :show, context: { current_user: user })
      parsed = JSON.parse(result)
      
      expect(parsed['links']).to be_an(Array)
      expect(parsed['links'].first['rel']).to eq('self')
    end
  end

  describe 'index view' do
    it 'includes links field' do
      result = CommentBlueprint.render(comment, view: :index, context: { current_user: user })
      parsed = JSON.parse(result)
      
      expect(parsed['links']).to be_an(Array)
    end

    it 'includes hypermedia index links' do
      allow(comment).to receive(:hypermedia_index_links).and_return([
        { rel: 'show', href: '/comments/1', title: 'View Comment' }
      ])
      
      result = CommentBlueprint.render(comment, view: :index, context: { current_user: user })
      parsed = JSON.parse(result)
      
      expect(parsed['links']).to be_an(Array)
      expect(parsed['links'].first['rel']).to eq('show')
    end
  end
end

