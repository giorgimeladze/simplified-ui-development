# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Comment2s API', type: :request do
  
  # GET /comment2s/pending_comment2s
  path '/comment2s/pending_comment2s' do
    get 'Retrieves all pending comments' do
      tags 'Comment2s'
      produces 'application/json'
      description 'Returns all comments in "pending" state awaiting moderation. Requires moderator or admin role.'
      security [session_auth: []]

      response '200', 'pending comments found' do
        schema type: :object,
          required: %w[comments links],
          properties: {
            comments: {
              type: :array,
              items: { '$ref' => '#/components/schemas/Comment' }
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }

        let!(:user) { sign_in_user(role: :admin) }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :editor) }
        run_test!
      end
    end
  end

  # GET /comment2s/:id
  path '/comment2s/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Comment2 ID'

    get 'Retrieves a specific comment' do
      tags 'Comment2s'
      produces 'application/json'
      description 'Returns a single comment with available actions based on current state and user permissions.'

      response '200', 'comment found' do
        schema type: :object,
          required: %w[comment links],
          properties: {
            comment: {
              type: :object,
              required: %w[id text state author_id article2_id links],
              properties: {
                id: { type: :string, format: :uuid },
                text: { type: :string },
                state: { type: :string },
                author_id: { type: :integer },
                article2_id: { type: :string, format: :uuid },
                rejection_feedback: { type: :string, nullable: true },
                links: {
                  type: :array,
                  items: { '$ref' => '#/components/schemas/HypermediaLink' }
                }
              }
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }
      
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) { Comment2ReadModel.create!(id: SecureRandom.uuid, text: 'Comment', article2_id: article.id, author_id: 1, state: 'approved') }
        let(:id) { comment_record.id }
      
        run_test!
      end
      
      response '404', 'comment not found' do
        schema '$ref' => '#/components/schemas/Error'
        before do
          sign_in_user(role: :editor)
        end
  
        let(:id) { 'nonexistent-id' }
  
        run_test!
      end
    end
  end

  # GET /comment2s/:id/edit
  path '/comment2s/{id}/edit' do
    parameter name: :id, in: :path, type: :string, description: 'Comment2 ID'

    get 'Get comment edit form' do
      tags 'Comment2s'
      produces 'application/json'
      description 'Returns HTML form for editing comment. Only available for rejected comments.'
      security [session_auth: []]

      response '200', 'edit form retrieved' do
        schema type: :object,
          required: %w[comment2 links],
          properties: {
            comment2: {
              type: :object,
              required: %w[id text state author_id],
              properties: {
                id: { type: :string, format: :uuid },
                text: { type: :string },
                state: { type: :string, enum: %w[approved rejected pending deleted] },
                author_id: { type: :integer }
              }
            },
            links: {
              type: :array,
              items: { '$ref' => '#/components/schemas/HypermediaLink' }
            }
          }
      
        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: user.id,
            state: 'rejected'
          )
        end
        let(:id) { comment_record.id }
      
        run_test!
      end
      
      response '403', 'forbidden - not editable' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'approved'
          )
        end
        let(:id) { comment_record.id }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'

        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'rejected'
          )
        end
        let(:id) { comment_record.id }

        run_test!
      end
    end
  end

  # UPDATE /comment2s/:id
  path '/comment2s/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Comment2 ID'

    patch 'Update comment' do
      tags 'Comment2s'
      consumes 'application/json'
      produces 'application/json'
      description 'Update comment text. Only allowed for rejected comments. Automatically moves to pending state via event sourcing.'
      security [session_auth: []]

      parameter name: :comment2, in: :body, schema: {
        type: :object,
        properties: {
          text: { type: :string, example: 'Updated comment text' }
        },
        required: ['text']
      }

      response '200', 'comment updated' do
        schema type: :object,
          required: ['comment2_id'],
          properties: {
            comment2_id: { type: :string, format: :uuid }
          }
      
        let!(:user) { sign_in_user(role: :editor) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: user.id, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: user.id,
            state: 'rejected'
          )
        end
        let(:id) { comment_record.id }
        let(:comment2) { { comment2: { text: 'Updated comment text' } } }
      
        run_test!
      end
         
      
      response '403', 'forbidden - not editable' do
        schema '$ref' => '#/components/schemas/Error'
      
        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'approved'
          )
        end
        let(:id) { comment_record.id }
        let(:comment2) { { text: 'Trying to edit' } }

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
      
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'rejected'
          )
        end
        let(:id) { comment_record.id }
        let(:comment2) { { text: 'Updated comment text' } }
      
        run_test!
      end
    end
  end

  # POST /article2s/:article2_id/comment2s
  path '/article2s/{article2_id}/comment2s' do
    parameter name: :article2_id, in: :path, type: :string, description: 'Article2 ID'

    post 'Creates a new comment' do
      tags 'Comment2s'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a new comment in "pending" state via event sourcing. Requires authentication.'
      security [session_auth: []]

      parameter name: :comment2, in: :body, schema: {
        type: :object,
        properties: {
          text: { 
            type: :string, 
            example: 'Great article! Very informative.',
            minLength: 1,
            maxLength: 250
          }
        },
        required: ['text']
      }

      response '201', 'comment created' do
        schema type: :object,
          required: ['comment2_id'],
          properties: {
            comment2_id: { type: :string, format: :uuid }
          }

        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:article2_id) { article.id }
        let(:comment2) { { text: 'Great article!' } }
        
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:article2_id) { article.id }
        let(:comment2) { { text: 'Great article!' } }
  
        run_test!
      end

      response '404', 'article not found' do
        schema '$ref' => '#/components/schemas/Error'
  
        let!(:user) { sign_in_user(role: :viewer) }
        let(:article2_id) { 'nonexistent-id' }
        let(:comment2) { { text: 'Great article!' } }
  
        run_test!
      end
    end
  end

  # FSM Transitions
  # POST /comment2s/:id/approve
  path '/comment2s/{id}/approve' do
    parameter name: :id, in: :path, type: :string, description: 'Comment2 ID'

    post 'Approve comment (pending → approved)' do
      tags 'Comment2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment from "pending" to "approved" state via event sourcing, making it publicly visible. Requires admin role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[comment2_id],
          properties: {
            comment2_id: { type: :string, format: :uuid },
            message: { type: :string }
          }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'pending'
          )
        end
        let(:id) { comment_record.id }
        
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'pending'
          )
        end
        let(:id) { comment_record.id }
  
        run_test!
      end

      response '403', 'forbidden - insufficient permissions' do
        schema '$ref' => '#/components/schemas/Error'
  
        let!(:user) { sign_in_user(role: :editor) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'pending'
          )
        end
        let(:id) { comment_record.id }
  
        run_test!
      end

    end
  end

  # POST /comment2s/:id/reject
  path '/comment2s/{id}/reject' do
    parameter name: :id, in: :path, type: :string, description: 'Comment2 ID'

    post 'Reject comment (pending → rejected)' do
      tags 'Comment2s - FSM Transitions'
      produces 'application/json'
      consumes 'application/json'
      description 'Transitions comment from "pending" to "rejected" state with feedback via event sourcing. Requires admin role.'
      security [session_auth: []]

      parameter name: :rejection_feedback, in: :body, schema: {
        type: :object,
        properties: {
          rejection_feedback: {
            type: :string,
            example: 'Please be more constructive in your feedback.',
            description: 'Detailed feedback explaining why the comment is being rejected'
          }
        },
        required: ['rejection_feedback']
      }

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[comment2_id],
          properties: {
            comment2_id: { type: :string, format: :uuid },
            message: { type: :string }
          }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'pending'
          )
        end
        let(:id) { comment_record.id }
        let(:rejection_feedback) { { rejection_feedback: 'Please be more constructive.' } }
        
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'pending'
          )
        end
        let(:id) { comment_record.id }
        let(:rejection_feedback) { { rejection_feedback: 'Feedback' } }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        let!(:user) { sign_in_user(role: :editor) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'pending'
          )
        end
        let(:id) { comment_record.id }
        let(:rejection_feedback) { { rejection_feedback: 'Feedback' } }
  
        run_test!
      end
    end
  end

  # POST /comment2s/:id/delete
  path '/comment2s/{id}/delete' do
    parameter name: :id, in: :path, type: :string, description: 'Comment2 ID'

    post 'Soft delete comment' do
      tags 'Comment2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment to "deleted" state via event sourcing. Can be restored later. Requires comment ownership, admin, or editor role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[comment2_id],
          properties: {
            comment2_id: { type: :string, format: :uuid },
            message: { type: :string }
          }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'approved'
          )
        end
        let(:id) { comment_record.id }
        
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'approved'
          )
        end
        let(:id) { comment_record.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'approved'
          )
        end
        let(:id) { comment_record.id }
  
        run_test!
      end
    end
  end

  # POST /comment2s/:id/restore
  path '/comment2s/{id}/restore' do
    parameter name: :id, in: :path, type: :string, description: 'Comment2 ID'

    post 'Restore deleted comment' do
      tags 'Comment2s - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment from "deleted" back to "pending" state via event sourcing. Requires admin or editor role.'
      security [session_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          required: %w[comment2_id],
          properties: {
            comment2_id: { type: :string, format: :uuid },
            message: { type: :string }
          }

        let!(:user) { sign_in_user(role: :admin) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'deleted'
          )
        end
        let(:id) { comment_record.id }
        
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
  
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'deleted'
          )
        end
        let(:id) { comment_record.id }
  
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
  
        let!(:user) { sign_in_user(role: :viewer) }
        let(:article) { Article2ReadModel.create!(id: SecureRandom.uuid, title: 'Test', content: 'Content', author_id: 1, state: 'published') }
        let(:comment_record) do
          Comment2ReadModel.create!(
            id: SecureRandom.uuid,
            text: 'Comment',
            article2_id: article.id,
            author_id: 1,
            state: 'deleted'
          )
        end
        let(:id) { comment_record.id }
  
        run_test!
      end
    end
  end
end

