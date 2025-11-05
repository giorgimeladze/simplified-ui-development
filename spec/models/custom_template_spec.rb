require 'rails_helper'

RSpec.describe CustomTemplate, type: :model do
  let(:user) { create(:user) }
  let(:template) { user.custom_template }

  describe 'associations' do
    it 'belongs to user' do
      expect(template).to respond_to(:user)
      expect(template.user).to eq(user)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of user_id' do
      new_template = CustomTemplate.new(user: user, template_data: {})
      expect(new_template).not_to be_valid
      expect(new_template.errors[:user_id]).to be_present
    end

    it 'requires template_data' do
      template = CustomTemplate.new(user: user)
      expect(template).not_to be_valid
      expect(template.errors[:template_data]).to be_present
    end
  end

  describe 'DEFAULT_TEMPLATE' do
    it 'is a frozen hash' do
      expect(CustomTemplate::DEFAULT_TEMPLATE).to be_frozen
    end

    it 'contains expected sections' do
      expect(CustomTemplate::DEFAULT_TEMPLATE.keys).to include('Article', 'Comment', 'Navigation', 'Article2', 'Comment2')
    end

    it 'contains Article actions' do
      expect(CustomTemplate::DEFAULT_TEMPLATE['Article']).to include('index', 'new', 'create', 'show', 'submit')
    end

    it 'contains Comment actions' do
      expect(CustomTemplate::DEFAULT_TEMPLATE['Comment']).to include('index', 'new', 'create', 'approve', 'reject')
    end

    it 'contains Navigation actions' do
      expect(CustomTemplate::DEFAULT_TEMPLATE['Navigation']).to include('all_articles', 'sign_in', 'sign_out')
    end
  end

  describe '.for_user' do
    context 'when template does not exist' do
      let(:new_user) { create(:user) }

      before do
        new_user.custom_template.destroy
      end

      it 'creates a new template' do
        expect {
          CustomTemplate.for_user(new_user)
        }.to change(CustomTemplate, :count).by(1)
      end

      it 'creates template with default data' do
        new_template = CustomTemplate.for_user(new_user)
        expect(new_template.template_data).to eq(CustomTemplate::DEFAULT_TEMPLATE)
      end
    end
  end

  describe '#get_customization' do
    it 'returns customization for model and action' do
      customization = template.get_customization('Article', 'index')
      expect(customization).to be_a(Hash)
      expect(customization).to include('title', 'button_classes')
    end

    it 'returns default customization when not customized' do
      customization = template.get_customization('Article', 'index')
      expect(customization['title']).to eq('All Articles')
    end

    it 'returns default when customization does not exist' do
      customization = template.get_customization('Article', 'index')
      expect(customization).to eq(CustomTemplate::DEFAULT_TEMPLATE['Article']['index'])
    end
  end

  describe '#reset_to_defaults' do
    before do
      template.update!(template_data: { 'Article' => { 'index' => { 'title' => 'Custom Title' } } })
    end

    it 'resets template_data to defaults' do
      template.reset_to_defaults
      expect(template.template_data).to eq(CustomTemplate::DEFAULT_TEMPLATE)
    end
  end

  describe '#get_section' do
    it 'returns section data' do
      section = template.get_section('Article')
      expect(section).to be_a(Hash)
      expect(section).to include('index', 'new', 'create')
    end

    it 'returns default section when not customized' do
      section = template.get_section('Article')
      expect(section).to eq(CustomTemplate::DEFAULT_TEMPLATE['Article'])
    end
  end

  describe '#update_section' do
    let(:new_section_data) do
      {
        'index' => { 'title' => 'Custom Index', 'button_classes' => 'btn-custom' }
      }
    end

    it 'updates specific section' do
      result = template.update_section('Article', new_section_data)
      expect(result).to be true
      template.reload
      expect(template.get_section('Article')['index']).to eq(new_section_data['index'])
    end

    it 'preserves other sections' do
      original_comment = template.get_section('Comment')
      template.update_section('Article', new_section_data)
      template.reload
      expect(template.get_section('Comment')).to eq(original_comment)
    end

    context 'when update fails' do
      before do
        allow(template).to receive(:update).and_return(false)
      end

      it 'returns false' do
        result = template.update_section('Article', new_section_data)
        expect(result).to be false
      end
    end
  end

  describe '#reset_section' do
    before do
      template.update_section('Article', { 'index' => { 'title' => 'Custom Title' } })
    end

    it 'resets specific section to defaults' do
      template.reset_section('Article')
      expect(template.get_section('Article')).to eq(CustomTemplate::DEFAULT_TEMPLATE['Article'])
    end

    it 'preserves other sections' do
      original_comment = template.get_section('Comment')
      template.reset_section('Article')
      template.reload
      expect(template.get_section('Comment')).to eq(original_comment)
    end
  end

  describe '.available_sections' do
    it 'returns list of available sections' do
      expect(CustomTemplate.available_sections).to eq(%w[Article Comment Navigation Article2 Comment2])
    end
  end
end

