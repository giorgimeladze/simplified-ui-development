class CustomTemplatesController < ApplicationController
  before_action :set_custom_template

  # Main show page - displays all sections
  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render json: { template: @custom_template } }
      format.js { redirect_to custom_template_path }
      format.any { redirect_to custom_template_path }
    end
  end

  # Section-specific show actions
  def show_article
    @section_name = 'Article'
    @section_data = @custom_template.get_section('Article')
    
    respond_to do |format|
      format.html { render :show_section, layout: 'application' }
      format.json { render json: { template: { 'Article' => @section_data } } }
    end
  end

  def show_comment
    @section_name = 'Comment'
    @section_data = @custom_template.get_section('Comment')
    
    respond_to do |format|
      format.html { render :show_section, layout: 'application' }
      format.json { render json: { template: { 'Comment' => @section_data } } }
    end
  end

  def show_navigation
    @section_name = 'Navigation'
    @section_data = @custom_template.get_section('Navigation')
    
    respond_to do |format|
      format.html { render :show_section, layout: 'application' }
      format.json { render json: { template: { 'Navigation' => @section_data } } }
    end
  end

  def show_article2
    @section_name = 'Article2'
    @section_data = @custom_template.get_section('Article2')
    
    respond_to do |format|
      format.html { render :show_section, layout: 'application' }
      format.json { render json: { template: { 'Article2' => @section_data } } }
    end
  end

  def show_comment2
    @section_name = 'Comment2'
    @section_data = @custom_template.get_section('Comment2')
    
    respond_to do |format|
      format.html { render :show_section, layout: 'application' }
      format.json { render json: { template: { 'Comment2' => @section_data } } }
    end
  end

  # Main edit page - allows editing all sections
  def edit
    
    respond_to do |format|
      format.html { render :edit }
      format.json { render json: { template: @custom_template } }
    end
  end

  # Section-specific edit actions
  def edit_article
    @section_name = 'Article'
    @section_data = @custom_template.get_section('Article')
    
    respond_to do |format|
      format.html { render :edit_section, layout: 'application' }
      format.json { render json: { template: { 'Article' => @section_data } } }
      # format.js { redirect_to custom_template_path }
      # format.any { redirect_to custom_template_path }
    end
  end

  def edit_comment
    @section_name = 'Comment'
    @section_data = @custom_template.get_section('Comment')
    
    respond_to do |format|
      format.html { render :edit_section, layout: 'application' }
      format.json { render json: { template: { 'Comment' => @section_data } } }
    end
  end

  def edit_navigation
    @section_name = 'Navigation'
    @section_data = @custom_template.get_section('Navigation')
    
    respond_to do |format|
      format.html { render :edit_section, layout: 'application' }
      format.json { render json: { template: { 'Navigation' => @section_data } } }
    end
  end

  def edit_article2
    @section_name = 'Article2'
    @section_data = @custom_template.get_section('Article2')
    
    respond_to do |format|
      format.html { render :edit_section, layout: 'application' }
      format.json { render json: { template: { 'Article2' => @section_data } } }
    end
  end

  def edit_comment2
    @custom_template = CustomTemplate.for_user(current_user)
    @section_name = 'Comment2'
    @section_data = @custom_template.get_section('Comment2')
    
    respond_to do |format|
      format.html { render :edit_section, layout: 'application' }
      format.json { render json: { template: { 'Comment2' => @section_data } } }
    end
  end

  # Update all sections
  def update
    if @custom_template.update(template_params)
      respond_to do |format|
        format.html { redirect_to custom_template_path, notice: 'Template updated successfully.' } 
        format.json { render json: { success: true, template: @custom_template } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @custom_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # Section-specific update actions
  def update_article
    if @custom_template.update_section('Article', article_template_params[:Article])
      respond_to do |format|
        format.html { redirect_to show_article_custom_template_path, notice: 'Article customization updated successfully.' }
        format.json { render json: { success: true } }
      end
    else
      @section_name = 'Article'
      @section_data = article_template_params[:Article]
      respond_to do |format|
        format.html { render :edit_section, status: :unprocessable_entity, layout: 'application' }
        format.json { render json: { success: false, errors: @custom_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update_comment
    if @custom_template.update_section('Comment', comment_template_params[:Comment])
      respond_to do |format|
        format.html { redirect_to show_comment_custom_template_path, notice: 'Comment customization updated successfully.' }
        format.json { render json: { success: true } }
      end
    else
      @section_name = 'Comment'
      @section_data = comment_template_params[:Comment]
      respond_to do |format|
        format.html { render :edit_section, status: :unprocessable_entity, layout: 'application' }
        format.json { render json: { success: false, errors: @custom_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update_navigation
    if @custom_template.update_section('Navigation', navigation_template_params[:Navigation])
      respond_to do |format|
        format.html { redirect_to show_navigation_custom_template_path, notice: 'Navigation customization updated successfully.' }
        format.json { render json: { success: true } }
      end
    else
      @section_name = 'Navigation'
      @section_data = navigation_template_params[:Navigation]
      respond_to do |format|
        format.html { render :edit_section, status: :unprocessable_entity, layout: 'application' }
        format.json { render json: { success: false, errors: @custom_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update_article2
    if @custom_template.update_section('Article2', article2_template_params[:Article2])
      respond_to do |format|
        format.html { redirect_to show_article2_custom_template_path, notice: 'Article2 customization updated successfully.' }
        format.json { render json: { success: true } }
      end
    else
      @section_name = 'Article2'
      @section_data = article2_template_params[:Article2]
      respond_to do |format|
        format.html { render :edit_section, status: :unprocessable_entity, layout: 'application' }
        format.json { render json: { success: false, errors: @custom_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update_comment2
    if @custom_template.update_section('Comment2', comment2_template_params[:Comment2])
      respond_to do |format|
        format.html { redirect_to show_comment2_custom_template_path, notice: 'Comment2 customization updated successfully.' }
        format.json { render json: { success: true } }
      end
    else
      @section_name = 'Comment2'
      @section_data = comment2_template_params[:Comment2]
      respond_to do |format|
        format.html { render :edit_section, status: :unprocessable_entity, layout: 'application' }
        format.json { render json: { success: false, errors: @custom_template.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # Reset all sections
  def reset
    @custom_template.reset_to_defaults
    
    respond_to do |format|
      format.html { redirect_to custom_template_path, notice: 'Template reset to defaults.' }
      format.json { render json: { success: true } }
    end
  end

  # Section-specific reset actions
  def reset_article
    @custom_template.reset_section('Article')
    
    respond_to do |format|
      format.html { redirect_to show_article_custom_template_path, notice: 'Article customization reset to defaults.' }
      format.json { render json: { success: true } }
    end
  end

  def reset_comment
    @custom_template.reset_section('Comment')
    
    respond_to do |format|
      format.html { redirect_to show_comment_custom_template_path, notice: 'Comment customization reset to defaults.' }
      format.json { render json: { success: true } }
    end
  end

  def reset_navigation
    @custom_template.reset_section('Navigation')
    
    respond_to do |format|
      format.html { redirect_to show_navigation_custom_template_path, notice: 'Navigation customization reset to defaults.' }
      format.json { render json: { success: true } }
    end
  end

  def reset_article2
    @custom_template.reset_section('Article2')
    
    respond_to do |format|
      format.html { redirect_to show_article2_custom_template_path, notice: 'Article2 customization reset to defaults.' }
      format.json { render json: { success: true } }
    end
  end

  def reset_comment2
    @custom_template.reset_section('Comment2')
    
    respond_to do |format|
      format.html { redirect_to show_comment2_custom_template_path, notice: 'Comment2 customization reset to defaults.' }
      format.json { render json: { success: true } }
    end
  end

  private

  def set_custom_template
    @custom_template = CustomTemplate.for_user(current_user)
  end

  def template_params
    params.require(:custom_template).permit(template_data: {})
  end

  def article_template_params
    params.require(:custom_template).permit(Article: {})
  end

  def comment_template_params
    params.require(:custom_template).permit(Comment: {})
  end

  def navigation_template_params
    params.require(:custom_template).permit(Navigation: {})
  end

  def article2_template_params
    params.require(:custom_template).permit(Article2: {})
  end

  def comment2_template_params
    params.require(:custom_template).permit(Comment2: {})
  end
end
