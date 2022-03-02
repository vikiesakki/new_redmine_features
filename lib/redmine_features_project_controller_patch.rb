module RedmineFeaturesProjectControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      before_action :calculate_time_account, :only => [:index,:show]
    end
  end
  module InstanceMethods
    def calculate_time_account
      prjs = []
      if @project.present?
        prjs = [@project]
      else
        prjs = Project.where(status: 1)
      end
      prjs.each do |project|
        total_time = 0
        issue_ids = project.issues.pluck(:id)
        unless issue_ids.blank?
          previous_spent = project.custom_field_value(27)
          billed_time = CustomValue.where(customized_type: 'Issue', customized_id: issue_ids, custom_field_id: 18).pluck(:value).sum.to_i
          training = CustomValue.where(customized_type: 'Issue', customized_id: issue_ids, custom_field_id: 19).pluck(:value).sum.to_i
          total_spent = project.time_entries.pluck(:hours).sum.to_i
          total_time = billed_time - (training + total_spent)
          unless previous_spent.to_i == total_time
            cv = project.custom_values.detect{|c| c.custom_field_id == 27 }
            if cv.present?
              cv.value = total_time
              cv.save
            end
          end
        end
      end
    end
  end
end


unless ProjectsController.included_modules.include?(RedmineFeaturesProjectControllerPatch)
  ProjectsController.send(:include, RedmineFeaturesProjectControllerPatch)
end
