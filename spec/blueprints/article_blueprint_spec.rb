# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticleBlueprint do
  let(:user) { create(:user, role: :editor) }
  let(:article) { create(:article, user: user) }
  let(:admin) { create(:user, role: :admin) }
  let(:viewer) { create(:user, role: :viewer) }

  describe 'base view' do
    it 'includes identifier' do
      result = ArticleBlueprint.render(article, context: { current_user: user })
      parsed = JSON.parse(result)

      expect(parsed['id']).to eq(article.id)
    end

    it 'includes title, content, status, and user_id' do
      result = ArticleBlueprint.render(article, context: { current_user: user })
      parsed = JSON.parse(result)

      expect(parsed['title']).to eq(article.title)
      expect(parsed['content']).to eq(article.content)
      expect(parsed['status']).to eq(article.status)
      expect(parsed['user_id']).to eq(article.user_id)
    end

    context 'rejection_feedback field' do
      before do
        article.update!(rejection_feedback: 'Needs improvement')
      end

      it 'includes rejection_feedback for admin' do
        result = ArticleBlueprint.render(article, context: { current_user: admin })
        parsed = JSON.parse(result)

        expect(parsed['rejection_feedback']).to eq('Needs improvement')
      end

      it 'includes rejection_feedback for article owner' do
        result = ArticleBlueprint.render(article, context: { current_user: user })
        parsed = JSON.parse(result)

        expect(parsed['rejection_feedback']).to eq('Needs improvement')
      end

      it 'excludes rejection_feedback for other users' do
        result = ArticleBlueprint.render(article, context: { current_user: viewer })
        parsed = JSON.parse(result)

        expect(parsed['rejection_feedback']).to be_nil
      end

      it 'excludes rejection_feedback when user is nil' do
        result = ArticleBlueprint.render(article, context: { current_user: nil })
        parsed = JSON.parse(result)

        expect(parsed['rejection_feedback']).to be_nil
      end
    end
  end

  describe 'show view' do
    it 'includes links field' do
      result = ArticleBlueprint.render(article, view: :show, context: { current_user: user })
      parsed = JSON.parse(result)

      expect(parsed['links']).to be_an(Array)
    end

    it 'includes hypermedia show links' do
      allow(article).to receive(:hypermedia_show_links).and_return([
                                                                     { rel: 'self', href: '/articles/1',
                                                                       title: 'Article' }
                                                                   ])

      result = ArticleBlueprint.render(article, view: :show, context: { current_user: user })
      parsed = JSON.parse(result)

      expect(parsed['links']).to be_an(Array)
      expect(parsed['links'].first['rel']).to eq('self')
    end
  end

  describe 'index view' do
    it 'includes links field' do
      result = ArticleBlueprint.render(article, view: :index, context: { current_user: user })
      parsed = JSON.parse(result)

      expect(parsed['links']).to be_an(Array)
    end

    it 'includes hypermedia index links' do
      allow(article).to receive(:hypermedia_index_links).and_return([
                                                                      { rel: 'show', href: '/articles/1',
                                                                        title: 'View Article' }
                                                                    ])

      result = ArticleBlueprint.render(article, view: :index, context: { current_user: user })
      parsed = JSON.parse(result)

      expect(parsed['links']).to be_an(Array)
      expect(parsed['links'].first['rel']).to eq('show')
    end
  end
end
