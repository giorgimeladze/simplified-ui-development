# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HasHypermediaLinks, type: :model do
  # Test using Article model which includes HasHypermediaLinks
  let(:user) { create(:user, role: :editor) }
  let(:article) { create(:article, user: user) }

  describe 'included in models' do
    it 'is included in Article' do
      expect(Article.included_modules).to include(HasHypermediaLinks)
    end

    it 'is included in Comment' do
      expect(Comment.included_modules).to include(HasHypermediaLinks)
    end
  end

  describe '#hypermedia_model_name' do
    it 'returns the model class name' do
      expect(article.hypermedia_model_name).to eq('Article')
    end
  end

  describe '#hypermedia_show_links' do
    context 'when user cannot update' do
      let(:viewer) { create(:user, role: :viewer) }

      it 'does not include edit link' do
        links = article.hypermedia_show_links(viewer)
        edit_link = links.find { |l| l[:rel] == 'edit' }
        expect(edit_link).to be_nil
      end
    end
  end

  describe '#hypermedia_new_links' do
    it 'returns array with index link' do
      links = article.hypermedia_new_links(user)
      expect(links).to be_an(Array)
      expect(links.size).to eq(1)
    end

    it 'includes back to index link' do
      links = article.hypermedia_new_links(user)
      expect(links.first[:title]).to include('Articles')
    end
  end

  describe '#hypermedia_edit_links' do
    it 'returns array with show link' do
      links = article.hypermedia_edit_links(user)
      expect(links).to be_an(Array)
      expect(links.size).to eq(1)
    end

    it 'includes back to show link' do
      links = article.hypermedia_edit_links(user)
      expect(links.first[:title]).to include('Article')
    end
  end

  describe '.hypermedia_navigation_links' do
    context 'when user is signed in' do
      it 'returns navigation links' do
        links = HasHypermediaLinks.hypermedia_navigation_links(user)
        expect(links).to be_an(Array)
      end

      it 'includes sign-out link' do
        links = HasHypermediaLinks.hypermedia_navigation_links(user)
        sign_out_link = links.find { |l| l[:rel] == 'sign-out' }
        expect(sign_out_link).to be_present
      end

      it 'does not include sign-in link' do
        links = HasHypermediaLinks.hypermedia_navigation_links(user)
        sign_in_link = links.find { |l| l[:rel] == 'sign-in' }
        expect(sign_in_link).to be_nil
      end
    end

    context 'when user is nil' do
      it 'includes sign-in link' do
        links = HasHypermediaLinks.hypermedia_navigation_links(nil)
        sign_in_link = links.find { |l| l[:rel] == 'sign-in' }
        expect(sign_in_link).to be_present
      end

      it 'does not include sign-out link' do
        links = HasHypermediaLinks.hypermedia_navigation_links(nil)
        sign_out_link = links.find { |l| l[:rel] == 'sign-out' }
        expect(sign_out_link).to be_nil
      end
    end
  end

  describe '.hypermedia_general_index' do
    it 'returns new link for model' do
      links = HasHypermediaLinks.hypermedia_general_index(user, 'Article')
      expect(links).to be_an(Array)
      expect(links.size).to eq(1)
    end
  end

  describe '.hypermedia_general_show' do
    it 'returns index link for model' do
      links = HasHypermediaLinks.hypermedia_general_show(user, 'Article')
      expect(links).to be_an(Array)
      expect(links.size).to eq(1)
    end
  end

  describe 'transition links' do
    it 'includes transition links for available events' do
      article.submit! # Move to review state
      links = article.hypermedia_show_links(user)
      # Should include links for possible transitions from review state
      expect(links).to be_an(Array)
    end

    it 'only includes links for events user is authorized to perform' do
      viewer = create(:user, role: :viewer)
      article.submit!
      links = article.hypermedia_show_links(viewer)
      # Viewer should not see admin-only actions
      expect(links).to be_an(Array)
    end
  end
end
