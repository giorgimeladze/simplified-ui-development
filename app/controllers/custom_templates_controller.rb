class CustomTemplatesController < ApplicationController
  before_action :set_custom_template, only: [:show, :edit, :update, :reset]

  def show
    @custom_template = CustomTemplate.for_user(current_user)
    
    respond_to do |format|
      format.html { render :show }
      format.json { render json: { template: @custom_template } }
      format.js { redirect_to custom_template_path }
      format.any { redirect_to custom_template_path }
    end
  end

  def edit
    @custom_template = CustomTemplate.for_user(current_user)
    
    respond_to do |format|
      format.html { render :edit }
      format.json { render json: { template: @custom_template } }
      format.js { redirect_to custom_template_path }
      format.any { redirect_to custom_template_path }
    end
  end

  def update
    @custom_template = CustomTemplate.for_user(current_user)
    
    if @custom_template.update(template_params)
      respond_to do |format|
        format.html { redirect_to custom_template_path, notice: 'Template updated successfully.' } 
        format.json { render json: { success: true, template: @custom_template } }
        format.js { redirect_to custom_template_path, notice: 'Template updated successfully.' }
        format.any { redirect_to custom_template_path, notice: 'Template updated successfully.' }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @custom_template.errors.full_messages }, status: :unprocessable_entity }
        format.js { redirect_to custom_template_path, alert: 'Template update failed.' }
        format.any { redirect_to custom_template_path, alert: 'Template update failed.' }
      end
    end
  end

  def reset
    @custom_template.reset_to_defaults
    
    respond_to do |format|
      format.html { redirect_to custom_template_path, notice: 'Template reset to defaults.' }
      format.json { render json: { success: true } }
      format.js { redirect_to custom_template_path, notice: 'Template reset to defaults.' }
      format.any { redirect_to custom_template_path, notice: 'Template reset to defaults.' }
    end
  end

  private

  def set_custom_template
    @custom_template = CustomTemplate.for_user(current_user)
  end

  def template_params
    params.require(:custom_template).permit(template_data: {})
  end
end
