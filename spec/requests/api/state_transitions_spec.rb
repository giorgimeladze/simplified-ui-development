# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'State Transitions API', type: :request do
  
  # GET /state_transitions
  path '/state_transitions' do
    get 'Retrieves all state transitions (audit log)' do
      tags 'State Transitions'
      produces 'application/json'
      description 'Returns a complete audit log of all FSM state transitions for articles and comments. Shows who made the transition, when, and what changed. Requires admin role.'
      security [bearer_auth: []]

      response '200', 'state transitions found' do
        schema type: :object,
          properties: {
            state_transitions: {
              type: :array,
              items: { '$ref' => '#/components/schemas/StateTransition' }
            }
          },
          example: {
            state_transitions: [
              {
                id: 1,
                transitionable_type: 'Article',
                transitionable_id: 5,
                from_state: 'draft',
                to_state: 'review',
                event: 'submit',
                user_id: 1,
                created_at: '2024-10-09T14:23:45Z',
                updated_at: '2024-10-09T14:23:45Z'
              },
              {
                id: 2,
                transitionable_type: 'Article',
                transitionable_id: 5,
                from_state: 'review',
                to_state: 'published',
                event: 'publish',
                user_id: 2,
                created_at: '2024-10-09T15:30:12Z',
                updated_at: '2024-10-09T15:30:12Z'
              },
              {
                id: 3,
                transitionable_type: 'Comment',
                transitionable_id: 12,
                from_state: 'pending',
                to_state: 'approved',
                event: 'approve',
                user_id: 2,
                created_at: '2024-10-09T16:45:33Z',
                updated_at: '2024-10-09T16:45:33Z'
              }
            ]
          }

        let!(:user) { sign_in_user(role: :admin) }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '403', 'forbidden - requires admin role' do
        schema '$ref' => '#/components/schemas/Error'

        let!(:user) { sign_in_user(role: :viewer) }
        run_test!
      end
    end
  end
end

