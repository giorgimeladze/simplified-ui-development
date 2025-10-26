# Simplified UI Development with FSM and HATEOAS

A Ruby on Rails application demonstrating how Finite State Machines (FSM) and HATEOAS principles can simplify UI development, reduce manual state management, and create predictable, testable UI logic.

## 🚀 Quick Start

When downloading the repository, run:

```bash
rails db:create
rails db:migrate
rails db:seed
rails s
```

Navigate to `localhost:3000`

### Test Users
- **Admin**: `giorgi@mail.example` / `123456`
- **Editor**: `editor@example.com` / `qwerty12`

---

## 📐 Architecture Overview

This project implements a state-driven UI architecture that combines FSMs with HATEOAS principles. The core idea is to centralize UI state and available actions in the domain model, making the UI a reflection of the underlying state rather than a source of truth.

### Key Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Architecture Layers                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Views (Presentation Layer)              │   │
│  │  - Renders hypermedia links via LinksRenderer       │   │
│  │  - No hardcoded state logic                          │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │            Controllers (Orchestration)               │   │
│  │  - Invokes state transitions                         │   │
│  │  - Delegates authorization to Policies               │   │
│  │  - Serves hypermedia-aware responses                 │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │         Models (Domain + State Logic)                │   │
│  │  - FSM defined with AASM gem                         │   │
│  │  - HasHypermediaLinks concern                        │   │
│  │  - Computes available actions based on state        │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │         Policies (Authorization Layer)               │   │
│  │  - Role-based permission checks                      │   │
│  │  - Each FSM event has a corresponding policy method  │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼──────────────────────────────┐   │
│  │      Configuration (YAML + HypermediaConfig)         │   │
│  │  - Declarative action definitions                    │   │
│  │  - Link templates with styling                       │   │
│  │  - Single source of truth for affordances            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

1. **Models** (`app/models/article.rb`)

2. **Policies** (`app/policies/article_policy.rb`)

3. **Controllers** (`app/controllers/articles_controller.rb`)

4. **Views** (`app/views/articles/`)

5. **Configuration** (`config/hypermedia_actions.yml`)

6. **Helpers** (`lib/links_renderer.rb`, `lib/hypermedia_config.rb`)
---

## 🔄 Article FSM: State Machine with UI Integration

### State Diagram

```
                    ┌─────────┐
                    │  DRAFT  │ (initial)
                    └────┬────┘
                         │ submit
                         ▼
                    ┌─────────┐
              ┌─────┤  REVIEW ├─────┐
              │     └─────────┘     │
              │                     │
       reject │                     │ publish
              │                     │
              ▼                     ▼
        ┌──────────┐          ┌───────────┐
        │ REJECTED │          │ PUBLISHED │◄──┐
        └────┬─────┘          └─────┬─────┘   │
             │                      │          │
             │ resubmit       make_ │          │ make_
             │                invisible        │ visible
             │                      │          │
             │                      ▼          │
             │                 ┌──────────┐   │
             │            ┌────┤ PRIVATED ├───┘
             │            │    └──────────┘
             │            │
             │ archive    │ archive
             │            │
             │            │
             ▼            ▼
        ┌─────────────────────┐
        │      ARCHIVED       │
        └─────────────────────┘



┌─────────┐         ┌─────────┐
│ PENDING │◄────────┤ DELETED │
└────┬────┘ restore └────▲────┘
     │                   │
     │ approve           │
     ▼                   │
┌─────────┐              │
│APPROVED │              │
└────┬────┘              │
     │                   │
     │                   │
     └───────────────────┘
            delete
```

### FSM Events (Transitions)

```ruby
# From app/models/article.rb
aasm column: 'status' do
  state :draft, initial: true
  state :review, :privated, :published, :rejected, :archived

  event :submit do
    transitions from: :draft, to: :review
  end

  event :reject do
    transitions from: :review, to: :rejected
  end

  event :approve_private do
    transitions from: :review, to: :privated
  end

  event :resubmit do
    transitions from: :rejected, to: :review
  end

  event :archive do
    transitions from: [:rejected, :published, :privated], to: :archived
  end

  event :publish do
    transitions from: :review, to: :published
  end

  event :make_visible do
    transitions from: :privated, to: :published
  end

  event :make_invisible do
    transitions from: :published, to: :privated
  end
end
```

### UI Integration

The FSM directly drives the UI by:

1. **State-based Scoping**: Only valid transitions appear as buttons
2. **Automatic Link Generation**: `HasHypermediaLinks` concern automatically generates links for valid transitions
3. **Policy Integration**: Each event is gated by a policy method (e.g., `ArticlePolicy#submit?`)
4. **No View Logic**: Views simply render the links provided by the model


## 🔗 HATEOAS Implementation Details

### Implementation in This Project

#### 1. Hypermedia Link Structure

Each link follows this structure:

```ruby
{
  rel: "transition:publish",           # Link relation (semantic meaning)
  title: "Publish",                    # Human-readable label
  method: "POST",                      # HTTP method
  href: "/articles/123/publish",       # Target URL
  button_classes: "btn btn-success",   # Styling (optional)
  confirm: "Are you sure?"             # Confirmation message (optional)
}
```

#### 2. Link Generation Flow

```
┌──────────────────────────────────────────────────────────┐
│            Link Generation Process                        │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  1. Controller requests links                             │
│     @links = @article.hypermedia_show_links(current_user) │
│                                                            │
│  2. HasHypermediaLinks concern:                           │
│     ┌─────────────────────────────────────────────┐      │
│     │ a) Iterate through FSM events                │      │
│     │ b) Check if event can fire (FSM validation)  │      │
│     │ c) Check policy authorization                │      │
│     │ d) Build link from YAML config               │      │
│     └─────────────────────────────────────────────┘      │
│                                                            │
│  3. HypermediaConfig loads action definition from YAML    │
│     - Retrieves rel, title, method, link template         │
│     - Replaces #ID placeholder with resource ID           │
│     - Includes styling and confirmation settings          │
│                                                            │
│  4. Returns array of link hashes                          │
│                                                            │
│  5. View renders links using LinksRenderer helper         │
│     - Converts link hashes to HTML buttons/links          │
│     - Applies styling from YAML or defaults               │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

**Generated Links for Article in Review State:**
```ruby
[
  {
    rel: "transition:reject",
    title: "Reject",
    method: "POST",
    href: "/articles/123/reject",
    button_classes: "btn btn-outline-danger btn-sm mx-1"
  },
  {
    rel: "transition:approve_private",
    title: "Approve Private",
    method: "POST",
    href: "/articles/123/approve_private",
    button_classes: "btn btn-outline-info btn-sm mx-1"
  },
  {
    rel: "transition:publish",
    title: "Publish",
    method: "POST",
    href: "/articles/123/publish",
    button_classes: "btn btn-outline-success btn-sm mx-1"
  }
]
```

**Rendered HTML:**
```html
<button type="submit" formaction="/articles/123/reject" formmethod="post" 
        class="btn btn-outline-danger btn-sm mx-1">Reject</button>
<button type="submit" formaction="/articles/123/approve_private" formmethod="post" 
        class="btn btn-outline-info btn-sm mx-1">Approve Private</button>
<button type="submit" formaction="/articles/123/publish" formmethod="post" 
        class="btn btn-outline-success btn-sm mx-1">Publish</button>
```

---

## 📝 YAML Configuration: Declarative Action Definitions

### Overview

All hypermedia actions are defined in a single YAML file (`config/hypermedia_actions.yml`), providing a declarative, centralized configuration for:
- Link relations and semantics
- HTTP methods and routes
- UI labels and styling
- Confirmation messages

### Configuration Structure

```yaml
# config/hypermedia_actions.yml

Article:
  # Collection-level actions
  index:
    rel: 'collection'
    title: 'All Articles'
    method: 'GET'
    link: '/articles'
    button_classes: 'btn btn-outline-primary btn-sm mx-1'
  
  new:
    rel: 'new'
    title: 'New Article'
    method: 'GET'
    link: '/articles/new'
    button_classes: 'btn btn-outline-primary btn-sm mx-1'
  
  # Resource-level actions (use #ID placeholder)
  show:
    rel: 'self'
    title: 'Show'
    method: 'GET'
    link: '/articles/#ID'
    button_classes: 'btn btn-outline-primary btn-sm mx-1'
  
  # FSM State Transition Actions
  submit:
    rel: 'transition:submit'
    title: 'Submit for Review'
    method: 'POST'
    link: '/articles/#ID/submit'
    button_classes: 'btn btn-outline-warning btn-sm mx-1'
  
  publish:
    rel: 'transition:publish'
    title: 'Publish'
    method: 'POST'
    link: '/articles/#ID/publish'
    button_classes: 'btn btn-outline-success btn-sm mx-1'
  
  # ... other transitions ...

# Global Navigation
Navigation:
  all_articles:
    rel: 'collection'
    title: 'All Articles'
    method: 'GET'
    link: '/articles'
    button_classes: 'btn btn-outline-primary btn-sm mx-1'
  
  sign_in:
    rel: 'sign-in'
    title: 'Sign In'
    method: 'GET'
    link: '/users/sign_in'
    button_classes: 'btn btn-outline-primary btn-sm mx-1'
  
  sign_out:
    rel: 'sign-out'
    title: 'Sign Out'
    method: 'DELETE'
    link: '/users/sign_out'
    button_classes: 'btn btn-outline-danger btn-sm mx-1'
```

---

## 🔍 Comparison: Traditional vs. This Approach

### Traditional Approach

```erb
<!-- View with hardcoded logic -->
<% if @article.draft? && current_user.author_of?(@article) %>
  <%= button_to "Submit", submit_article_path(@article) %>
<% end %>

<% if @article.in_review? && current_user.admin? %>
  <%= button_to "Publish", publish_article_path(@article) %>
  <%= button_to "Reject", reject_article_path(@article) %>
<% end %>
```

### This Approach (FSM + HATEOAS)

```erb
<!-- View is state-agnostic -->
<div class="actions">
  <%= render_links(@links) %>
</div>
```

---

## 📚 Key Files Reference

### Core Implementation
- `app/models/article.rb` - FSM definition with AASM
- `app/models/concerns/has_hypermedia_links.rb` - Hypermedia link generation
- `app/policies/article_policy.rb` - Authorization rules
- `app/controllers/articles_controller.rb` - State transition orchestration
- `app/views/articles/` - State-agnostic view partials

### Configuration & Helpers
- `config/hypermedia_actions.yml` - Declarative action definitions
- `lib/hypermedia_config.rb` - YAML loader and link builder
- `lib/links_renderer.rb` - HTML rendering for hypermedia links

---

## 📡 JSON API Documentation

This application provides comprehensive JSON API responses for all models, following HATEOAS principles with embedded hypermedia links.

### Article JSON Responses

#### Article (AASM-based)
**Base Fields**: `id`, `title`, `content`, `status`, `user_id`
**Conditional Fields**: `rejection_feedback` (visible to admin or article author)

#### Article2 (Event Sourcing)
**Base Fields**: `id`, `title`, `content`, `status`, `user_id`
**Conditional Fields**: `rejection_feedback` (visible to admin or article author)

#### Example Article JSON Response
```json
{
  "id": "123",
  "title": "Sample Article",
  "content": "Article content here...",
  "status": "published",
  "user_id": "456",
  "rejection_feedback": null,
  "links": {
    "show": {
      "rel": "self",
      "method": "GET",
      "link": "/articles/123"
    },
    "edit": {
      "rel": "edit",
      "method": "GET", 
      "link": "/articles/123/edit"
    },
    "archive": {
      "rel": "transition:archive",
      "method": "POST",
      "link": "/articles/123/archive",
      "confirm": "Are you sure you want to archive this article?"
    }
  }
}
```

### Comment JSON Responses

#### Comment (AASM-based)
**Base Fields**: `id`, `text`, `status`, `user_id`
**Conditional Fields**: `rejection_feedback` (visible to admin or comment author)

#### Comment2 (Event Sourcing)
**Base Fields**: `id`, `text`, `status`, `user_id`
**Conditional Fields**: `rejection_feedback` (visible to admin or comment author)

#### Example Comment JSON Response
```json
{
  "id": "789",
  "text": "Great article!",
  "status": "approved",
  "user_id": "456",
  "rejection_feedback": null,
  "links": {
    "show": {
      "rel": "self",
      "method": "GET",
      "link": "/comments/789"
    },
    "edit": {
      "rel": "edit",
      "method": "GET",
      "link": "/comments/789/edit"
    },
    "delete": {
      "rel": "transition:delete",
      "method": "POST",
      "link": "/comments/789/delete",
      "confirm": "Delete this comment?"
    }
  }
}
```

### Collection Responses

#### Articles Index
```json
{
  "articles": [
    {
      "id": "123",
      "title": "Article 1",
      "content": "Content...",
      "status": "published",
      "user_id": "456",
      "links": { /* hypermedia links */ }
    }
  ],
  "links": {
    "all_articles": {
      "rel": "collection",
      "method": "GET",
      "link": "/articles"
    },
    "my_articles": {
      "rel": "my-articles",
      "method": "GET",
      "link": "/articles/my_articles"
    },
    "new_article": {
      "rel": "new",
      "method": "GET",
      "link": "/articles/new"
    }
  }
}
```

### State Transition Responses

#### Success Response
```json
{
  "success": true,
  "article": {
    "id": "123",
    "title": "Sample Article",
    "content": "Content...",
    "status": "review",
    "user_id": "456",
    "links": { /* updated hypermedia links */ }
  }
}
```

#### Error Response
```json
{
  "success": false,
  "errors": ["Transition not allowed from current state"]
}
```

### Event Sourcing Responses

#### Article2 with Embedded Comments
```json
{
  "article": {
    "id": "123",
    "title": "Event-Sourced Article",
    "content": "Content...",
    "status": "published",
    "user_id": "456",
    "links": { /* hypermedia links */ },
    "_embedded": {
      "comment2s": [
        {
          "id": "789",
          "text": "Comment on event-sourced article",
          "status": "approved",
          "user_id": "456",
          "links": { /* comment hypermedia links */ }
        }
      ]
    }
  }
}
```

### Hypermedia Link Structure

All JSON responses include hypermedia links following HATEOAS principles:

```json
{
  "rel": "transition:submit",
  "method": "POST",
  "link": "/articles/123/submit",
  "confirm": "Are you sure you want to submit this article?"
}
```

**Link Properties**:
- `rel`: Relationship type (e.g., `self`, `edit`, `transition:submit`)
- `method`: HTTP method (`GET`, `POST`, `PATCH`, `DELETE`)
- `link`: URL endpoint
- `confirm`: Optional confirmation message for destructive actions

### Status Codes

- `200 OK`: Successful GET requests
- `201 Created`: Successful POST requests (create)
- `422 Unprocessable Entity`: Validation errors or invalid state transitions
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions

### Authentication

All API endpoints require authentication via Devise. Include authentication headers or use session-based authentication.

---

## 📖 Theoretical Foundation

**Thesis Focus**: Simplifying UI development in Ruby on Rails by leveraging FSMs in ActiveRecord to encode UI states/transitions, combined with HATEOAS-driven hypermedia controls to adapt actions based on resource state.

---



---

## 🛠️ Technology Stack

- **Rails 7.x** - Web framework
- **AASM** - Finite state machine gem
- **Pundit** - Authorization via policies
- **SQLite** - Database (development/test)
- **RSpec** - Testing framework
- **Devise** - Authentication

---

## 📄 License

This project is part of a master's thesis at CVUT (Czech Technical University in Prague).
