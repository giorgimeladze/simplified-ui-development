# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'End-to-End Workflows', type: :request do
  # These tests demonstrate complete user workflows as described in the thesis:
  # - FSM-driven state transitions
  # - HATEOAS hypermedia link discovery
  # - CRUD vs Event-sourced architectures
  # - Authorization and role-based access
  # - Custom templates integration

  describe 'CRUD-based Article Workflow' do
    context 'Complete article lifecycle with state transitions' do
      let!(:editor) { sign_in_user(role: :editor) }
      let!(:admin) { create(:user, role: :admin) }

      it 'creates draft article, submits for review, gets published, and archives' do
        # Step 1: Create article in draft state
        post articles_path, params: {
          article: {
            title: 'My First Article',
            content: 'This is the content of my article.'
          }
        }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:created)
        article_data = JSON.parse(response.body)['article']
        article_id = article_data['id']
        expect(article_data['status']).to eq('draft')

        # Step 2: Verify hypermedia links for draft state
        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)
        article = JSON.parse(response.body)['article']
        
        # Draft state should have 'submit' transition link
        submit_link = article['links'].find { |l| l['rel'] == 'transition:submit' }
        expect(submit_link).to be_present
        expect(submit_link['method']).to eq('POST')
        expect(submit_link['href']).to eq("/articles/#{article_id}/submit")

        # Step 3: Submit article for review (draft → review)
        post "/articles/#{article_id}/submit", headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)
        
        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        expect(article['status']).to eq('review')

        # Review state should NOT have 'submit' link anymore
        submit_link = article['links'].find { |l| l['rel'] == 'transition:submit' }
        expect(submit_link).to be_nil

        # Step 4: Admin publishes article (review → published)
        sign_out_user
        sign_in_as(admin)

        # get Article link form admin perspective
        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)
        article = JSON.parse(response.body)['article']
        publish_link = article['links'].find { |l| l['rel'] == 'transition:publish' }
        expect(publish_link).to be_present
        
        post "/articles/#{article_id}/publish", headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)

        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        expect(article['status']).to eq('published')

        # Published state should have 'archive' and 'make_invisible' links
        archive_link = article['links'].find { |l| l['rel'] == 'transition:archive' }
        expect(archive_link).to be_present

        # Step 5: Archive article (published → archived)
        post "/articles/#{article_id}/archive", headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)

        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        expect(article['status']).to eq('archived')
      end

      it 'handles rejection and resubmission workflow' do
        # Create and submit article
        post articles_path, params: {
          article: { title: 'Article to Reject', content: 'Content' }
        }, headers: { 'Accept' => 'application/json' }
        
        article_id = JSON.parse(response.body)['article']['id']
        post "/articles/#{article_id}/submit", headers: { 'Accept' => 'application/json' }

        # Admin rejects article
        sign_out_user
        sign_in_as(admin)
        
        post "/articles/#{article_id}/reject", params: {
          rejection_feedback: 'Needs more detail.'
        }, headers: { 'Accept' => 'application/json' }

        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        expect(article['status']).to eq('rejected')
        expect(article['rejection_feedback']).to eq('Needs more detail.')

        # Editor resubmits (rejected → review)
        sign_out_user
        sign_in_as(editor)
        
        resubmit_link = article['links'].find { |l| l['rel'] == 'transition:resubmit' }
        expect(resubmit_link).to be_present

        post "/articles/#{article_id}/resubmit", headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)

        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        expect(article['status']).to eq('review')
      end
    end

    context 'Hypermedia link discovery based on state and authorization' do
      let!(:editor) { sign_in_user(role: :editor) }
      let!(:other_editor) { create(:user, role: :editor) }
      let!(:admin) { create(:user, role: :admin) }

      it 'shows different links based on user role and article ownership' do
        # Editor creates article
        post articles_path, params: {
          article: { title: 'My Article', content: 'Content' }
        }, headers: { 'Accept' => 'application/json' }
        
        article_id = JSON.parse(response.body)['article']['id']
        post "/articles/#{article_id}/submit", headers: { 'Accept' => 'application/json' }

        # Owner sees resubmit link, but not publish (needs admin)
        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        publish_link = article['links'].find { |l| l['rel'] == 'transition:publish' }
        expect(publish_link).to be_nil # Editor can't publish

        # Admin sees publish link
        sign_out_user
        sign_in_as(admin)
        
        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        publish_link = article['links'].find { |l| l['rel'] == 'transition:publish' }
        expect(publish_link).to be_present

        # Other editor doesn't see owner-specific links
        sign_out_user
        sign_in_as(other_editor)
        
        get article_path(article_id), headers: { 'Accept' => 'application/json' }
        article = JSON.parse(response.body)['article']
        resubmit_link = article['links'].find { |l| l['rel'] == 'transition:resubmit' }
        expect(resubmit_link).to be_nil # Not the owner
      end
    end
  end

  describe 'CRUD-based Comment Workflow' do
    let!(:viewer) { sign_in_user(role: :viewer) }
    let!(:admin) { create(:user, role: :admin) }
    let!(:article) { create(:article, status: 'published') }

    it 'creates pending comment, gets approved, and can be deleted' do
      # Step 1: Create comment (starts in pending state)
      post article_comments_path(article), params: {
        comment: { text: 'Great article!' }
      }, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:created)
      comment_data = JSON.parse(response.body)['comment']
      comment_id = comment_data['id']
      expect(comment_data['status']).to eq('pending')

      # Step 2: Admin approves comment (pending → approved)
      sign_out_user
      sign_in_as(admin)
      
      post "/comments/#{comment_id}/approve", headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)

      get "/comments/#{comment_id}", headers: { 'Accept' => 'application/json' }
      comment = JSON.parse(response.body)['comment']
      expect(comment['status']).to eq('approved')

      # Step 3: Delete comment (approved → deleted)
      delete_link = comment['links'].find { |l| l['rel'] == 'transition:delete' }
      expect(delete_link).to be_present

      post "/comments/#{comment_id}/delete", headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)

      get "/comments/#{comment_id}", headers: { 'Accept' => 'application/json' }
      comment = JSON.parse(response.body)['comment']
      expect(comment['status']).to eq('deleted')

      # Step 4: Restore comment (deleted → pending)
      restore_link = comment['links'].find { |l| l['rel'] == 'transition:restore' }
      expect(restore_link).to be_present

      post "/comments/#{comment_id}/restore", headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)

      get "/comments/#{comment_id}", headers: { 'Accept' => 'application/json' }
      comment = JSON.parse(response.body)['comment']
      expect(comment['status']).to eq('pending')
    end

    it 'handles comment rejection and editing workflow' do
      # Create comment
      post article_comments_path(article), params: {
        comment: { text: 'Needs improvement' }
      }, headers: { 'Accept' => 'application/json' }
      
      comment_id = JSON.parse(response.body)['comment']['id']

      # Admin rejects with feedback
      sign_out_user
      sign_in_as(admin)
      
      post "/comments/#{comment_id}/reject", params: {
        rejection_feedback: 'Please be more constructive.'
      }, headers: { 'Accept' => 'application/json' }

      get "/comments/#{comment_id}", headers: { 'Accept' => 'application/json' }
      comment = JSON.parse(response.body)['comment']
      expect(comment['status']).to eq('rejected')

      # Author can edit rejected comment
      sign_out_user
      sign_in_as(viewer)
      
      get "/comments/#{comment_id}", headers: { 'Accept' => 'application/json' }
      comment = JSON.parse(response.body)['comment']
      edit_link = comment['links'].find { |l| l['rel'] == 'edit' }
      expect(edit_link).to be_present

      patch "/comments/#{comment_id}", params: {
        comment: { text: 'This is much better now!' }
      }, headers: { 'Accept' => 'application/json' }

      # Updating rejected comment automatically moves to pending
      get "/comments/#{comment_id}", headers: { 'Accept' => 'application/json' }
      comment = JSON.parse(response.body)['comment']
      expect(comment['status']).to eq('pending')
      expect(comment['text']).to eq('This is much better now!')
    end
  end

  describe 'Event-Sourced Article2 Workflow' do
    let!(:editor) { sign_in_user(role: :editor) }
    let!(:admin) { create(:user, role: :admin) }

    it 'creates article via command, transitions through states, and verifies events' do
      # Step 1: Create article via command (event sourcing)
      post article2s_path, params: {
        article2: {
          title: 'Event-Sourced Article',
          content: 'Content via event sourcing'
        }
      }, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:created)
      
      # Step 2: Get created article from read model
      # Since create returns { success: true }, we need to find it in the read model
      article2 = Article2ReadModel.find_by(title: 'Event-Sourced Article')
      expect(article2).to be_present
      expect(article2.state).to eq('draft')
      article2_id = article2.id

      # Step 3: Submit for review via command
      post "/article2s/#{article2_id}/submit", headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['article2_id']).to eq(article2_id)

      # Verify state in read model
      get "/article2s/#{article2_id}", headers: { 'Accept' => 'application/json' }
      article2 = JSON.parse(response.body)['article2']
      expect(article2['state']).to eq('review')

      sign_out_user
      sign_in_as(admin)

      # Step 4: Verify event was stored
      get '/events', headers: { 'Accept' => 'application/json' }
      events = JSON.parse(response.body)['events']
      submit_event = events.find { |e| e['event_type'] == 'Article2Submitted' }
      expect(submit_event).to be_present

      # Step 5: Admin publishes via command
      
      post "/article2s/#{article2_id}/publish", headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)

      get "/article2s/#{article2_id}", headers: { 'Accept' => 'application/json' }
      article2 = JSON.parse(response.body)['article2']
      expect(article2['state']).to eq('published')

      # Step 6: Verify published event
      get '/events', headers: { 'Accept' => 'application/json' }
      events = JSON.parse(response.body)['events']
      publish_event = events.find { |e| e['event_type'] == 'Article2Published'}
      expect(publish_event).to be_present
    end

    it 'demonstrates HAL-style embedded resources with comments' do
      # Create article
      post article2s_path, params: {
        article2: { title: 'Article with Comments', content: 'Content' }
      }, headers: { 'Accept' => 'application/json' }
      
      article2_id = Article2ReadModel.find_by(title: 'Article with Comments').id

      # Submit and publish
      post "/article2s/#{article2_id}/submit", headers: { 'Accept' => 'application/json' }
      sign_out_user
      sign_in_as(admin)
      post "/article2s/#{article2_id}/publish", headers: { 'Accept' => 'application/json' }

      # Create comment on article
      post "/article2s/#{article2_id}/comment2s", params: {
        comment2_read_model: { text: 'First comment' }
      }, headers: { 'Accept' => 'application/json' }

      # Get article with embedded comments (HAL format)
      get "/article2s/#{article2_id}", headers: { 'Accept' => 'application/json' }
      article2 = JSON.parse(response.body)['article2']
      
      expect(article2['_embedded']).to be_present
      expect(article2['_embedded']['comment2s']).to be_an(Array)
      expect(article2['_embedded']['comment2s'].first['text']).to eq('First comment')
      expect(article2['_embedded']['comment2s'].first['links']).to be_present
    end
  end

  describe 'Event-Sourced Comment2 Workflow' do
    let!(:viewer) { sign_in_user(role: :viewer) }
    let!(:admin) { create(:user, role: :admin) }
    let!(:article2) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }

    it 'creates comment via command, transitions states, and tracks events' do
      # Create comment via command
      post "/article2s/#{article2.id}/comment2s", params: {
        comment2_read_model: { text: 'Event-sourced comment' }
      }, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:created)
      comment2_id = JSON.parse(response.body)['comment2_id']

      # Verify comment in read model
      get "/comment2s/#{comment2_id}", headers: { 'Accept' => 'application/json' }
      comment2 = JSON.parse(response.body)['comment']
      expect(comment2['state']).to eq('pending')

      # Admin approves via command
      sign_out_user
      sign_in_as(admin)
      
      post "/comment2s/#{comment2_id}/approve", headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)

      get "/comment2s/#{comment2_id}", headers: { 'Accept' => 'application/json' }
      comment2 = JSON.parse(response.body)['comment']
      expect(comment2['state']).to eq('approved')

      # Verify approval event
      get '/events', headers: { 'Accept' => 'application/json' }
      events = JSON.parse(response.body)['events']
      approve_event = events.find { |e| e['event_type'] == 'Comment2Approved'}
      expect(approve_event).to be_present
    end

    it 'handles comment rejection, editing, and automatic state transition' do
      # Create comment
      post "/article2s/#{article2.id}/comment2s", params: {
        comment2_read_model: { text: 'Needs work' }
      }, headers: { 'Accept' => 'application/json' }
      
      comment2_id = JSON.parse(response.body)['comment2_id']

      # Admin rejects
      sign_out_user
      sign_in_as(admin)
      
      post "/comment2s/#{comment2_id}/reject", params: {
        rejection_feedback: 'Please improve'
      }, headers: { 'Accept' => 'application/json' }

      get "/comment2s/#{comment2_id}", headers: { 'Accept' => 'application/json' }
      comment2 = JSON.parse(response.body)['comment']
      expect(comment2['state']).to eq('rejected')

      # Author updates comment (should trigger automatic transition to pending)
      sign_out_user
      sign_in_as(viewer)
      
      patch "/comment2s/#{comment2_id}", params: {
        comment2_read_model: { text: 'Improved version' }
      }, headers: { 'Accept' => 'application/json' }

      get "/comment2s/#{comment2_id}", headers: { 'Accept' => 'application/json' }
      comment2 = JSON.parse(response.body)['comment']
      expect(comment2['state']).to eq('pending') # Automatically moved to pending
      expect(comment2['text']).to eq('Improved version')
    end
  end

  describe 'HATEOAS Hypermedia Link Discovery' do
    let!(:editor) { sign_in_user(role: :editor) }
    let!(:admin) { create(:user, role: :admin) }

    it 'discovers available actions dynamically based on current state' do
      # Create article in draft
      post articles_path, params: {
        article: { title: 'HATEOAS Test', content: 'Content' }
      }, headers: { 'Accept' => 'application/json' }
      
      article_id = JSON.parse(response.body)['article']['id']

      # Draft state links
      get article_path(article_id), headers: { 'Accept' => 'application/json' }
      article = JSON.parse(response.body)['article']
      draft_links = article['links'].map { |l| l['rel'] }
      expect(draft_links).to include('transition:submit')
      expect(draft_links).not_to include('transition:publish')

      # Submit to review
      post "/articles/#{article_id}/submit", headers: { 'Accept' => 'application/json' }
      
      get article_path(article_id), headers: { 'Accept' => 'application/json' }
      article = JSON.parse(response.body)['article']
      review_links = article['links'].map { |l| l['rel'] }
      expect(review_links).not_to include('transition:submit') # No longer available

      # Publish
      sign_out_user
      sign_in_as(admin)
      post "/articles/#{article_id}/publish", headers: { 'Accept' => 'application/json' }
      
      get article_path(article_id), headers: { 'Accept' => 'application/json' }
      article = JSON.parse(response.body)['article']
      published_links = article['links'].map { |l| l['rel'] }
      expect(published_links).to include('transition:archive')
      expect(published_links).to include('transition:make_invisible')
      expect(published_links).not_to include('transition:publish') # Already published
    end

    it 'filters links based on user authorization' do
      editor1 = sign_in_user(role: :editor)
      editor2 = create(:user, role: :editor)
      admin = create(:user, role: :admin)

      # Editor1 creates article
      post articles_path, params: {
        article: { title: 'Authorization Test', content: 'Content' }
      }, headers: { 'Accept' => 'application/json' }
      
      article_id = JSON.parse(response.body)['article']['id']
      post "/articles/#{article_id}/submit", headers: { 'Accept' => 'application/json' }

      # Editor2 (not owner) doesn't see resubmit
      sign_out_user
      sign_in_as(editor2)
      
      get article_path(article_id), headers: { 'Accept' => 'application/json' }
      article = JSON.parse(response.body)['article']
      non_owner_links = article['links'].map { |l| l['rel'] }
      expect(non_owner_links).not_to include('transition:resubmit')

      # Admin sees publish link
      sign_out_user
      sign_in_as(admin)
      
      get article_path(article_id), headers: { 'Accept' => 'application/json' }
      article = JSON.parse(response.body)['article']
      admin_links = article['links'].map { |l| l['rel'] }
      expect(admin_links).to include('transition:publish')
    end
  end

  describe 'State Transition Audit Trail' do
    let!(:editor) { sign_in_user(role: :editor) }
    let!(:admin) { create(:user, role: :admin) }

    it 'tracks all state transitions for an article' do
      # Create article
      post articles_path, params: {
        article: { title: 'Audit Trail Test', content: 'Content' }
      }, headers: { 'Accept' => 'application/json' }
      
      article_id = JSON.parse(response.body)['article']['id']

      # Submit
      post "/articles/#{article_id}/submit", headers: { 'Accept' => 'application/json' }

      # Publish
      sign_out_user
      sign_in_as(admin)

      # Get state transitions
      get "/state_transitions?resource_type=Article&resource_id=#{article_id}", 
          headers: { 'Accept' => 'application/json' }

      transitions = JSON.parse(response.body)['state_transitions']
      expect(transitions.length).to be >= 1
      
      submit_transition = transitions.find { |t| t['event'] == 'submit!' }
      expect(submit_transition).to be_present
      expect(submit_transition['from_state']).to eq('draft')
      expect(submit_transition['to_state']).to eq('review')
      expect(submit_transition['user_id']).to eq(editor.id)

      post "/articles/#{article_id}/publish", headers: { 'Accept' => 'application/json' }

      get "/state_transitions?resource_type=Article&resource_id=#{article_id}", 
          headers: { 'Accept' => 'application/json' }
      
      transitions = JSON.parse(response.body)['state_transitions']
      publish_transition = transitions.find { |t| t['event'] == 'publish!' }
      expect(publish_transition).to be_present
      expect(publish_transition['from_state']).to eq('review')
      expect(publish_transition['to_state']).to eq('published')
    end
  end

  describe 'Custom Templates Integration' do
    let!(:user) { sign_in_user(role: :editor) }

    it 'applies custom templates to hypermedia links' do
      # Set custom template
      patch '/custom_template/update_article',
      params: {
        custom_template: {
          Article: {
            submit: {
              title: 'Send for Review',
              button_classes: 'btn btn-custom'
            }
          }
        }
      },
      headers: { 'Accept' => 'application/json' }

      # Create article
      post articles_path, params: {
        article: { title: 'Template Test', content: 'Content' }
      }, headers: { 'Accept' => 'application/json' }
      
      article_id = JSON.parse(response.body)['article']['id']

      # Get article and verify custom template applied
      get article_path(article_id), headers: { 'Accept' => 'application/json' }
      article = JSON.parse(response.body)['article']

      submit_link = article['links'].find { |l| l['rel'] == 'transition:submit' }
      expect(submit_link).to be_present
      expect(submit_link['title']).to eq('Send for Review') # Custom terminology
      expect(submit_link['button_classes']).to include('btn-custom') # Custom styling
    end
  end

  describe 'Cross-Architecture Comparison' do
    let!(:editor) { sign_in_user(role: :editor) }
    let!(:admin) { create(:user, role: :admin) }

    it 'demonstrates same workflow in CRUD vs Event-Sourced architectures' do
      # CRUD-based workflow
      post articles_path, params: {
        article: { title: 'CRUD Article', content: 'Content' }
      }, headers: { 'Accept' => 'application/json' }
      
      crud_article_id = JSON.parse(response.body)['article']['id']
      post "/articles/#{crud_article_id}/submit", headers: { 'Accept' => 'application/json' }

      sign_out_user
      sign_in_as(admin)
      post "/articles/#{crud_article_id}/publish", headers: { 'Accept' => 'application/json' }

      get article_path(crud_article_id), headers: { 'Accept' => 'application/json' }
      crud_article = JSON.parse(response.body)['article']
      expect(crud_article['status']).to eq('published')

      # Event-sourced workflow
      post article2s_path, params: {
        article2: { title: 'Event-Sourced Article', content: 'Content' }
      }, headers: { 'Accept' => 'application/json' }
      
      article2_id = Article2ReadModel.find_by(title: 'Event-Sourced Article').id
      post "/article2s/#{article2_id}/submit", headers: { 'Accept' => 'application/json' }
      post "/article2s/#{article2_id}/publish", headers: { 'Accept' => 'application/json' }

      get "/article2s/#{article2_id}", headers: { 'Accept' => 'application/json' }
      event_article = JSON.parse(response.body)['article2']
      expect(event_article['state']).to eq('published')

      # Both achieve same result, but event-sourced maintains event history
      get '/events', headers: { 'Accept' => 'application/json' }
      events = JSON.parse(response.body)['events']
      expect(events.length).to be >= 2 # Created + Submitted + Published
    end
  end
end

