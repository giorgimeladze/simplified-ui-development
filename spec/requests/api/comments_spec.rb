# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Comments API', type: :request do
  
  # GET /comments/pending_comments
  path '/comments/pending_comments' do
    get 'Retrieves all pending comments' do
      tags 'Comments'
      produces 'application/json'
      description 'Returns all comments in "pending" state awaiting moderation. Requires moderator or admin role.'
      security [bearer_auth: []]

      response '200', 'pending comments found' do
        schema type: :object,
          properties: {
            comments: {
              type: :array,
              items: { '$ref' => '#/components/schemas/Comment' }
            }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # GET /comments/:id
  path '/comments/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    get 'Retrieves a specific comment' do
      tags 'Comments'
      produces 'application/json'
      description 'Returns a single comment with available actions based on current state and user permissions.'

      response '200', 'comment found' do
        schema type: :object,
          properties: {
            comment: { type: :string, description: 'Rendered HTML content with hypermedia links' }
          }
        run_test!
      end

      response '404', 'comment not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # POST /articles/:article_id/comments
  path '/articles/{article_id}/comments' do
    parameter name: :article_id, in: :path, type: :integer, description: 'Article ID'

    post 'Creates a new comment' do
      tags 'Comments'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a new comment in "pending" state. Requires authentication.'
      security [bearer_auth: []]

      parameter name: :comment, in: :body, schema: {
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
          properties: {
            success: { type: :boolean, example: true },
            comment: { '$ref' => '#/components/schemas/Comment' }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '404', 'article not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: false },
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end

  # DELETE /comments/:id
  path '/comments/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    delete 'Deletes a comment' do
      tags 'Comments'
      produces 'application/json'
      description 'Permanently deletes a comment. Requires ownership or admin role.'
      security [bearer_auth: []]

      response '204', 'comment deleted' do
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '404', 'comment not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  # FSM Transitions
  # POST /comments/:id/approve
  path '/comments/{id}/approve' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Approve comment (pending → approved)' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment from "pending" to "approved" state, making it publicly visible. Requires admin role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: true },
            comment: { '$ref' => '#/components/schemas/Comment' }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden - insufficient permissions' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'invalid state transition' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: false },
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end

  # POST /comments/:id/reject
  path '/comments/{id}/reject' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Reject comment (pending → rejected)' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      consumes 'application/json'
      description 'Transitions comment from "pending" to "rejected" state with feedback. Requires admin role.'
      security [bearer_auth: []]

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
          properties: {
            success: { type: :boolean, example: true },
            comment: { '$ref' => '#/components/schemas/Comment' }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'validation error' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: false },
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end

  # POST /comments/:id/delete
  path '/comments/{id}/delete' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Soft delete comment (pending/approved → deleted)' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment to "deleted" state. Can be restored later. Requires comment ownership, admin, or editor role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: true },
            comment: { '$ref' => '#/components/schemas/Comment' }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'invalid state transition' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: false },
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end

  # POST /comments/:id/restore
  path '/comments/{id}/restore' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Restore deleted comment (deleted → pending)' do
      tags 'Comments - FSM Transitions'
      produces 'application/json'
      description 'Transitions comment from "deleted" back to "pending" state. Requires admin or editor role.'
      security [bearer_auth: []]

      response '200', 'transition successful' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: true },
            comment: { '$ref' => '#/components/schemas/Comment' }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'invalid state transition' do
        schema type: :object,
          properties: {
            success: { type: :boolean, example: false },
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end
end

